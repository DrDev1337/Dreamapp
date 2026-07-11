class_name RunState
extends RefCounted
## Tillståndet för en pågående run: rum, buren Essens, osäkrad loot
## och aktiv strid. Epic 2-reglerna är oförändrade av party-pivoten:
##  - Essens bärs osäkrad tills "stanna och spendera" vid checkpoint
##  - Vid PARTYWIPE lämnas allt i en hög på nuvarande djup
##  - Att nå djupet i en senare run returnerar hela högen
## Hjältarnas HP/mana följer med mellan rum; fallna hjältar förblir
## utslagna tills en checkpoint väcker upp dem.

var rooms: Array = []
var current_depth := 0  # 0 = inte inne i något rum än
var carried_essence := 0
var unsecured_items: Array = []  # utrustade denna run, tappas vid wipe (US-5.2)
var active_boosts: Array = []
var heroes_combat: Array = []  # stridsdicts, delas med CombatEngine
var combat: CombatEngine = null
var rng := RandomNumberGenerator.new()
var pile_recovered_this_run := false
var finished := false


## Startar en ny run (US-1.1). Pending boosts aktiveras och förbrukas.
static func start(party: PartyState, seed_value: int) -> RunState:
	var run := RunState.new()
	run.rng.seed = seed_value
	run.active_boosts = party.pending_boosts.duplicate(true)
	party.pending_boosts = []
	var pile_depth := int(party.death_pile.get("depth", -1)) if party.has_death_pile() else -1
	run.rooms = RunGenerator.generate(run.rng, pile_depth)
	run.heroes_combat = []
	for i in party.heroes.size():
		var hero_combat := CombatEngine.build_hero(party.heroes[i], party, run.active_boosts, i)
		for boost in run.active_boosts:
			if boost.has("start_hp_bonus"):
				hero_combat["max_hp"] += int(boost["start_hp_bonus"])
				hero_combat["hp"] += int(boost["start_hp_bonus"])
		run.heroes_combat.append(hero_combat)
	return run


func current_room() -> Dictionary:
	if current_depth >= 1 and current_depth <= rooms.size():
		return rooms[current_depth - 1]
	return {}


## US-1.3: djupgräns kopplad till partynivå.
func max_reachable_depth(party: PartyState) -> int:
	return Balance.max_depth_for_level(party.level)


func can_go_deeper(party: PartyState) -> bool:
	if current_depth >= rooms.size():
		return false
	return party.level >= Balance.required_level_for_depth(current_depth + 1)


## Text till UI:t när djupet är låst (US-1.3: tydlig indikation).
func deeper_lock_reason(party: PartyState) -> String:
	if current_depth >= rooms.size():
		return ""
	var required := Balance.required_level_for_depth(current_depth + 1)
	if party.level < required:
		return "Party level %d required to go deeper (you are level %d)." % [required, party.level]
	return ""


## Går in i nästa rum. Returnerar en händelsebeskrivning till UI:t.
func enter_next_room(party: PartyState) -> Dictionary:
	current_depth += 1
	var room := current_room()
	var event := {
		"room": room,
		"recovered_essence": 0,
		"recovered_items": [],
		"chest_item": {},
		"combat_started": false,
	}
	# US-2.4: nå dödsplatsen och få tillbaka hela högen.
	if room.get("has_pile", false) and not pile_recovered_this_run and party.has_death_pile():
		var pile: Dictionary = party.death_pile
		event["recovered_essence"] = int(pile.get("essence", 0))
		carried_essence += int(pile.get("essence", 0))
		for item in pile.get("loot", []):
			event["recovered_items"].append(item)
			equip_item(party, item, best_hero_for_item(party, item))
		party.death_pile = {}
		pile_recovered_this_run = true
	match String(room["type"]):
		"chest":
			var bonus_rarity := _has_boost("bonus_rarity")
			event["chest_item"] = Items.generate(rng, current_depth, bonus_rarity)
		_:
			var enemy_list: Array = []
			for id in room["enemy_ids"]:
				enemy_list.append(Enemies.spawn(id, current_depth))
			combat = CombatEngine.new()
			combat.setup(heroes_combat, enemy_list, rng.randi())
			# Kör fram till första hjältens tur – snabbare fiender slår först.
			combat.advance_until_player_turn()
			event["combat_started"] = true
	return event


## Efter vunnen strid: Essens, XP, ev. loot-drop.
func on_combat_victory(party: PartyState) -> Dictionary:
	var combat_rewards := combat.rewards()
	var mult := party.essence_gain_multiplier()
	for boost in active_boosts:
		mult *= float(boost.get("essence_mult", 1.0))
	var essence := int(int(combat_rewards["essence"]) * mult)
	carried_essence += essence
	var levels := party.gain_xp(int(combat_rewards["xp"]))
	var room := current_room()
	var loot := {}
	var was_boss: bool = room["type"] == "boss"
	var was_elite: bool = was_boss or room["type"] == "miniboss"
	if was_elite:
		loot = Items.generate(rng, current_depth, true, "epic" if was_boss else "")
	elif rng.randf() < Balance.LOOT_DROP_CHANCE_NORMAL:
		loot = Items.generate(rng, current_depth, _has_boost("bonus_rarity"))
	if was_boss:
		party.bosses_defeated += 1
	# HP/mana följer med till nästa rum; stridsstatusar och cooldowns nollas.
	heroes_combat = combat.heroes
	for hero_combat in heroes_combat:
		hero_combat["statuses"] = []
		hero_combat["cooldowns"] = {}
	combat = null
	return {
		"essence": essence,
		"xp": int(combat_rewards["xp"]),
		"levels_gained": levels,
		"loot": loot,
		"boss_defeated": was_boss,
	}


## Utrustar ett föremål på en hjälte. Osäkrade föremål spåras (US-5.2).
func equip_item(party: PartyState, item: Dictionary, hero_index: int) -> void:
	if hero_index < 0 or hero_index >= party.heroes.size():
		return
	var hero: Hero = party.heroes[hero_index]
	var slot := String(item["slot"])
	hero.equipment[slot] = item
	if not item.get("secured", false):
		unsecured_items = unsecured_items.filter(
			func(existing):
				return not (
					String(existing["slot"]) == slot
					and int(existing.get("hero_index", -1)) == hero_index
				)
		)
		var tracked := item.duplicate(true)
		tracked["hero_index"] = hero_index
		unsecured_items.append(tracked)
	# Uppdatera stridsvärdena direkt om en run är igång.
	if hero_index < heroes_combat.size():
		var hero_combat: Dictionary = heroes_combat[hero_index]
		var hp_missing := int(hero_combat["max_hp"]) - int(hero_combat["hp"])
		for stat in ["max_hp", "attack", "magic", "speed", "armor", "max_mana"]:
			hero_combat[stat] = hero.total_stat(stat, party)
		hero_combat["hp"] = maxi(0, int(hero_combat["max_hp"]) - hp_missing)
		hero_combat["ability_ids"] = hero.combat_ability_ids()


## Hjälten vars slot är svagast – auto-val för återhämtad loot.
func best_hero_for_item(party: PartyState, item: Dictionary) -> int:
	var slot := String(item["slot"])
	var best := 0
	var worst_score := 999999
	for i in party.heroes.size():
		var current: Dictionary = party.heroes[i].equipment.get(slot, {})
		var score := Items.power_score(current) if not current.is_empty() else 0
		if score < worst_score:
			worst_score = score
			best = i
	return best


## US-2.2: "Stanna och spendera" – Essens och loot säkras, runnen avslutas.
func bank_and_end(party: PartyState) -> int:
	var banked := carried_essence
	party.banked_essence += carried_essence
	carried_essence = 0
	for item in unsecured_items:
		item["secured"] = true
		var hero_index := int(item.get("hero_index", -1))
		if hero_index >= 0:
			var slot := String(item["slot"])
			var equipped: Dictionary = party.heroes[hero_index].equipment.get(slot, {})
			if not equipped.is_empty():
				equipped["secured"] = true
	unsecured_items = []
	party.runs_completed += 1
	finished = true
	return banked


## US-2.3 + US-2.5: vid partywipe tappas allt till en hög; gammal hög
## ersätts – men bara om det finns något att tappa.
func on_death(party: PartyState) -> Dictionary:
	var drops_something := carried_essence > 0 or not unsecured_items.is_empty()
	var lost_old_pile := drops_something and party.has_death_pile() and not pile_recovered_this_run
	if drops_something:
		for item in unsecured_items:
			var hero_index := int(item.get("hero_index", -1))
			if hero_index >= 0:
				var slot := String(item["slot"])
				var hero: Hero = party.heroes[hero_index]
				if not hero.equipment.get(slot, {}).is_empty():
					hero.equipment[slot] = {}
		party.death_pile = {
			"depth": current_depth,
			"essence": carried_essence,
			"loot": unsecured_items.duplicate(true),
		}
	party.deaths += 1
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


## Checkpointen väcker fallna hjältar och helar alla till fullo.
func heal_at_checkpoint() -> void:
	for hero_combat in heroes_combat:
		hero_combat["hp"] = hero_combat["max_hp"]
		hero_combat["mana"] = hero_combat["max_mana"]
		hero_combat["statuses"] = []
		hero_combat["cooldowns"] = {}


func at_checkpoint() -> bool:
	var room := current_room()
	return not room.is_empty() and room.get("checkpoint_after", false) and combat == null


func is_run_complete() -> bool:
	return current_depth >= rooms.size() and combat == null


func living_heroes_count() -> int:
	var count := 0
	for hero_combat in heroes_combat:
		if int(hero_combat["hp"]) > 0:
			count += 1
	return count


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
		"heroes_combat": heroes_combat,
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
	run.heroes_combat = data["heroes_combat"]
	var combat_data: Dictionary = data.get("combat", {})
	if not combat_data.is_empty():
		run.combat = CombatEngine.from_dict(combat_data)
		run.heroes_combat = run.combat.heroes
	run.rng.seed = int(data["rng_seed"])
	run.rng.state = int(data["rng_state"])
	run.pile_recovered_this_run = data.get("pile_recovered_this_run", false)
	run.finished = data.get("finished", false)
	return run
