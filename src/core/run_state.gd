class_name RunState
extends RefCounted
## Tillståndet för en pågående run: rum, buren Essens, osäkrad loot
## och aktiv strid. Implementerar kärnreglerna i Epic 2:
##  - Essens bärs osäkrad tills du "stannar och spenderar" vid checkpoint
##  - Vid död lämnas allt i en hög på ditt djup; bara senaste högen finns
##  - Att nå djupet i en senare run returnerar hela högen

var rooms: Array = []
var current_depth := 0  # 0 = inte inne i något rum än
var carried_essence := 0
var unsecured_items: Array = []  # utrustade denna run, tappas vid död (US-5.2)
var active_boosts: Array = []  # tillfälliga boosts som gäller denna run
var player_combat := {}  # hp/mana följer med mellan rum inom en run
var combat: CombatEngine = null
var rng := RandomNumberGenerator.new()
var pile_recovered_this_run := false
var finished := false


## Startar en ny run (US-1.1). Pending boosts aktiveras och förbrukas.
static func start(character: CharacterState, seed_value: int) -> RunState:
	var run := RunState.new()
	run.rng.seed = seed_value
	run.active_boosts = character.pending_boosts.duplicate(true)
	character.pending_boosts = []
	var pile_depth := (
		int(character.death_pile.get("depth", -1)) if character.has_death_pile() else -1
	)
	run.rooms = RunGenerator.generate(run.rng, pile_depth)
	run.player_combat = CombatEngine.build_player(character, run.active_boosts)
	for boost in run.active_boosts:
		if boost.has("start_hp_bonus"):
			run.player_combat["max_hp"] += int(boost["start_hp_bonus"])
			run.player_combat["hp"] += int(boost["start_hp_bonus"])
	return run


func current_room() -> Dictionary:
	if current_depth >= 1 and current_depth <= rooms.size():
		return rooms[current_depth - 1]
	return {}


## US-1.3: djupgräns kopplad till karaktärsnivå.
func max_reachable_depth(character: CharacterState) -> int:
	return Balance.max_depth_for_level(character.level)


func can_go_deeper(character: CharacterState) -> bool:
	if current_depth >= rooms.size():
		return false
	return character.level >= Balance.required_level_for_depth(current_depth + 1)


## Text till UI:t när djupet är låst (US-1.3: tydlig indikation).
func deeper_lock_reason(character: CharacterState) -> String:
	if current_depth >= rooms.size():
		return ""
	var required := Balance.required_level_for_depth(current_depth + 1)
	if character.level < required:
		return "Djupare ner krävs nivå %d (du är nivå %d)." % [required, character.level]
	return ""


## Går in i nästa rum. Returnerar en händelsebeskrivning till UI:t:
## {room, recovered_essence, recovered_items, chest_item, combat_started}
func enter_next_room(character: CharacterState) -> Dictionary:
	current_depth += 1
	var room := current_room()
	var event := {
		"room": room,
		"recovered_essence": 0,
		"recovered_items": [],
		"chest_item": {},
		"combat_started": false,
	}
	# US-2.4: nå din dödsplats och få tillbaka hela högen.
	if room.get("has_pile", false) and not pile_recovered_this_run and character.has_death_pile():
		var pile: Dictionary = character.death_pile
		event["recovered_essence"] = int(pile.get("essence", 0))
		carried_essence += int(pile.get("essence", 0))
		for item in pile.get("loot", []):
			event["recovered_items"].append(item)
			equip_item(character, item)
		character.death_pile = {}
		pile_recovered_this_run = true
	match String(room["type"]):
		"chest":
			var bonus_rarity := _has_boost("bonus_rarity")
			var item := Items.generate(rng, current_depth, bonus_rarity)
			event["chest_item"] = item
		_:
			var enemy_list: Array = []
			for id in room["enemy_ids"]:
				enemy_list.append(Enemies.spawn(id, current_depth))
			combat = CombatEngine.new()
			combat.setup(player_combat, enemy_list, rng.randi())
			event["combat_started"] = true
	return event


## Efter vunnen strid: Essens, XP, ev. loot-drop.
## Returnerar {essence, xp, levels_gained, loot, boss_defeated}
func on_combat_victory(character: CharacterState) -> Dictionary:
	var rewards := combat.rewards()
	var mult := character.essence_gain_multiplier()
	for boost in active_boosts:
		mult *= float(boost.get("essence_mult", 1.0))
	var essence := int(int(rewards["essence"]) * mult)
	carried_essence += essence
	var levels := character.gain_xp(int(rewards["xp"]))
	var room := current_room()
	var loot := {}
	var was_boss: bool = room["type"] == "boss"
	var was_elite: bool = was_boss or room["type"] == "miniboss"
	# US-5.1: loot från minibossar, bossar och (ibland) vanliga fiender.
	if was_elite:
		loot = Items.generate(rng, current_depth, true, "epic" if was_boss else "")
	elif rng.randf() < Balance.LOOT_DROP_CHANCE_NORMAL:
		loot = Items.generate(rng, current_depth, _has_boost("bonus_rarity"))
	if was_boss:
		character.bosses_defeated += 1
	# Spelarens hp/mana följer med till nästa rum; stridsstatusar nollas.
	player_combat = combat.player
	player_combat["statuses"] = []
	player_combat["cooldowns"] = {}
	combat = null
	return {
		"essence": essence,
		"xp": int(rewards["xp"]),
		"levels_gained": levels,
		"loot": loot,
		"boss_defeated": was_boss,
	}


## Utrustar ett föremål. Osäkrade föremål spåras separat (US-5.2).
func equip_item(character: CharacterState, item: Dictionary) -> void:
	var slot := String(item["slot"])
	character.equipment[slot] = item
	if not item.get("secured", false):
		unsecured_items = unsecured_items.filter(
			func(existing): return String(existing["slot"]) != slot
		)
		unsecured_items.append(item)


## US-2.2: "Stanna och spendera" – Essens och loot säkras, runnen avslutas.
func bank_and_end(character: CharacterState) -> int:
	var banked := carried_essence
	character.banked_essence += carried_essence
	carried_essence = 0
	for item in unsecured_items:
		item["secured"] = true
	unsecured_items = []
	character.runs_completed += 1
	finished = true
	return banked


## US-2.3 + US-2.5: vid död tappas allt till en hög; gammal hög ersätts.
func on_death(character: CharacterState) -> Dictionary:
	var lost_old_pile := character.has_death_pile() and not pile_recovered_this_run
	# Osäkrad utrustning tas av och läggs i högen.
	for item in unsecured_items:
		var slot := String(item["slot"])
		if character.equipment.get(slot, {}) == item:
			character.equipment[slot] = {}
	character.death_pile = {
		"depth": current_depth,
		"essence": carried_essence,
		"loot": unsecured_items.duplicate(true),
	}
	character.deaths += 1
	var summary := {
		"lost_essence": carried_essence,
		"lost_items": unsecured_items.size(),
		"depth": current_depth,
		"replaced_old_pile": lost_old_pile,
	}
	carried_essence = 0
	unsecured_items = []
	finished = true
	return summary


## Checkpoint helar (designbeslut, öppen fråga 2: heal ja, respawn nej).
func heal_at_checkpoint() -> void:
	player_combat["hp"] = player_combat["max_hp"]
	player_combat["mana"] = player_combat["max_mana"]


func at_checkpoint() -> bool:
	var room := current_room()
	return not room.is_empty() and room.get("checkpoint_after", false) and combat == null


func is_run_complete() -> bool:
	return current_depth >= rooms.size() and combat == null


func _has_boost(key: String) -> bool:
	for boost in active_boosts:
		if boost.get(key, false):
			return true
	return false


# --- Serialisering (US-11.2) ---


func to_dict() -> Dictionary:
	return {
		"rooms": rooms,
		"current_depth": current_depth,
		"carried_essence": carried_essence,
		"unsecured_items": unsecured_items,
		"active_boosts": active_boosts,
		"player_combat": player_combat,
		"combat": combat.to_dict() if combat != null else {},
		"rng_seed": rng.seed,
		"rng_state": rng.state,
		"pile_recovered_this_run": pile_recovered_this_run,
		"finished": finished,
	}


static func from_dict(data: Dictionary) -> RunState:
	var run := RunState.new()
	run.rooms = data["rooms"]
	run.current_depth = int(data["current_depth"])
	run.carried_essence = int(data["carried_essence"])
	run.unsecured_items = data["unsecured_items"]
	run.active_boosts = data["active_boosts"]
	run.player_combat = data["player_combat"]
	var combat_data: Dictionary = data.get("combat", {})
	if not combat_data.is_empty():
		run.combat = CombatEngine.from_dict(combat_data)
		run.player_combat = run.combat.player
	run.rng.seed = int(data["rng_seed"])
	run.rng.state = int(data["rng_state"])
	run.pile_recovered_this_run = data.get("pile_recovered_this_run", false)
	run.finished = data.get("finished", false)
	return run
