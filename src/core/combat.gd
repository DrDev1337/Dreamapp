class_name CombatEngine
extends RefCounted
## Turbaserad stridsmotor för party (party_design.md): 5 hjältar mot en
## fiendegrupp. Varje levande enhet agerar en gång per runda, ordnad
## efter fart. UI-flöde:
##   1. setup() eller from_dict()
##   2. advance_until_player_turn() – stannar på nästa hjältes tur
##      (active_hero pekar ut vem)
##   3. player_action(ability_id, target_index)
##   4. upprepa tills is_over()
## Melee-fiender når bara frontraden; taunt tvingar mål. Intentioner
## planeras vid rundstart och pekar ut vilken hjälte som är målet.
## Hela tillståndet serialiseras (US-11.2).

var heroes: Array = []  # stridsdicts, index = hjälteindex i partyt
var enemies: Array = []
var round_number := 1
var turn_index := 0
var turn_order: Array = []  # [{"side": "hero"/"enemy", "index": int}, ...]
var awaiting_player := false
var active_hero := -1
var hero_acted: Array = []  # hjälteindex som förbrukat sin handling i rundan
var result := ""  # "", "victory", "defeat"
var log: Array = []
var rng := RandomNumberGenerator.new()

# Beteenden som bara når frontraden.
const MELEE_BEHAVIORS := ["melee", "tank", "berserker", "miniboss"]


## Bygger en hjältes stridsrepresentation.
static func build_hero(hero: Hero, party: PartyState, boosts: Array, index: int) -> Dictionary:
	var damage_mult := 1.0
	for boost in boosts:
		damage_mult *= float(boost.get("damage_mult", 1.0))
	return {
		"name": hero.hero_name,
		"hero_index": index,
		"row": party.hero_row(index),
		"max_hp": hero.total_stat("max_hp", party),
		"hp": hero.total_stat("max_hp", party),
		"attack": hero.total_stat("attack", party),
		"magic": hero.total_stat("magic", party),
		"speed": hero.total_stat("speed", party),
		"armor": hero.total_stat("armor", party),
		"max_mana": hero.total_stat("max_mana", party),
		"mana": hero.total_stat("max_mana", party),
		"damage_mult": damage_mult,
		"ability_ids": hero.combat_ability_ids(),
		"cooldowns": {},
		"statuses": [],
	}


func setup(hero_list: Array, enemy_list: Array, seed_value: int) -> void:
	heroes = hero_list
	enemies = enemy_list
	rng.seed = seed_value
	round_number = 1
	_build_turn_order()
	plan_intents()
	log.append("Battle! %d enemies stand in your way." % enemies.size())


func is_over() -> bool:
	return result != ""


func living_enemies() -> Array:
	var alive: Array = []
	for i in enemies.size():
		if enemies[i]["hp"] > 0:
			alive.append(i)
	return alive


func living_heroes() -> Array:
	var alive: Array = []
	for i in heroes.size():
		if heroes[i]["hp"] > 0:
			alive.append(i)
	return alive


func downed_heroes() -> Array:
	var downed: Array = []
	for i in heroes.size():
		if heroes[i]["hp"] <= 0:
			downed.append(i)
	return downed


# --- Turordning: alla levande enheter, fart avgör (US-3.1) ---


func _build_turn_order() -> void:
	hero_acted = []
	_round_start_hero_upkeep()
	var entries: Array = []
	for i in heroes.size():
		if heroes[i]["hp"] > 0:
			entries.append({"side": "hero", "index": i, "speed": _effective_speed(heroes[i])})
	for i in enemies.size():
		if enemies[i]["hp"] > 0:
			entries.append({"side": "enemy", "index": i, "speed": _effective_speed(enemies[i])})
			enemies[i]["acted"] = false
	entries.sort_custom(func(a, b): return a["speed"] > b["speed"])
	turn_order = entries.map(func(entry): return {"side": entry["side"], "index": entry["index"]})
	turn_index = 0


func _effective_speed(unit: Dictionary) -> int:
	var speed := int(unit["speed"])
	for status in unit["statuses"]:
		if status["id"] == "slow":
			speed = maxi(1, speed - 2)
	return speed


## Statuseffekter på hjältar tickar vid rundstart (gift, stun). En
## stunnad hjälte förlorar rundans handling.
func _round_start_hero_upkeep() -> void:
	for i in heroes.size():
		var hero: Dictionary = heroes[i]
		if hero["hp"] <= 0:
			continue
		if not _tick_statuses_and_check(hero, hero["name"]) and hero["hp"] > 0:
			hero_acted.append(i)


## Förvald hjälte för en partyslot: slotens ägare om möjlig, annars
## första levande hjälte som inte agerat. -1 = sloten är förbrukad.
func _default_actor(scheduled: int) -> int:
	if heroes[scheduled]["hp"] > 0 and scheduled not in hero_acted:
		return scheduled
	for i in living_heroes():
		if i not in hero_acted:
			return i
	return -1


## Spelaren byter vilken hjälte som agerar på partyts tur ("vem kör
## sin runda först" – fri ordning inom rundan).
func select_actor(index: int) -> bool:
	if not awaiting_player or index < 0 or index >= heroes.size():
		return false
	if heroes[index]["hp"] <= 0 or index in hero_acted:
		return false
	active_hero = index
	return true


## Kör tills partyt står i tur (active_hero = förval) eller striden är slut.
func advance_until_player_turn() -> void:
	awaiting_player = false
	active_hero = -1
	while result == "":
		if turn_index >= turn_order.size():
			round_number += 1
			_build_turn_order()
			plan_intents()
			if _party_wiped():
				_end_combat("defeat")
				return
			continue
		var entry: Dictionary = turn_order[turn_index]
		if String(entry["side"]) == "hero":
			var actor := _default_actor(int(entry["index"]))
			if actor >= 0:
				awaiting_player = true
				active_hero = actor
				return
			turn_index += 1
			continue
		var enemy: Dictionary = enemies[int(entry["index"])]
		if enemy["hp"] > 0:
			if _tick_statuses_and_check(enemy, enemy["name"]):
				_enemy_act(enemy)
			enemy["acted"] = true
			if _party_wiped():
				_end_combat("defeat")
				return
			if living_enemies().is_empty():
				_end_combat("victory")
				return
		turn_index += 1


## Den aktiva hjältens handling. Returnerar true om handlingen var giltig.
func player_action(ability_id: String, target_index: int) -> bool:
	if not awaiting_player or result != "" or active_hero < 0:
		return false
	var hero: Dictionary = heroes[active_hero]
	var ability := Abilities.get_ability(ability_id)
	if ability.is_empty() or ability_id not in hero["ability_ids"]:
		return false
	if int(hero["cooldowns"].get(ability_id, 0)) > 0:
		return false
	if hero["mana"] < int(ability["mana_cost"]):
		return false
	if String(ability["kind"]) == "revive" and downed_heroes().is_empty():
		return false
	hero["mana"] = int(hero["mana"]) - int(ability["mana_cost"])
	if int(ability["cooldown"]) > 0:
		hero["cooldowns"][ability_id] = int(ability["cooldown"]) + 1
	_execute_hero_ability(hero, ability, target_index)
	hero["mana"] = mini(int(hero["max_mana"]), int(hero["mana"]) + Balance.HERO_MANA_REGEN)
	for id in hero["cooldowns"].keys():
		hero["cooldowns"][id] = maxi(0, int(hero["cooldowns"][id]) - 1)
	# Handlingen kan ha ändrat läget (taunt, dödad healer-kompis) –
	# fiender som inte agerat än tänker om så intentionerna håller.
	_replan_pending_intents()
	hero_acted.append(active_hero)
	awaiting_player = false
	active_hero = -1
	if living_enemies().is_empty():
		_end_combat("victory")
	else:
		turn_index += 1
		advance_until_player_turn()
	return true


# --- Hjälteförmågor ---


func _execute_hero_ability(hero: Dictionary, ability: Dictionary, target_index: int) -> void:
	match String(ability["kind"]):
		"heal":
			_do_heal(hero, ability)
		"revive":
			_do_revive(hero, ability)
		"taunt":
			_do_taunt(hero, ability)
		"buff":
			_do_buff(hero, ability)
		"defend":
			_do_defend(hero)
		_:
			_do_attack(hero, ability, target_index)


func _do_attack(hero: Dictionary, ability: Dictionary, target_index: int) -> void:
	var targets: Array = []
	if String(ability["target"]) == "all_enemies":
		targets = living_enemies()
	else:
		if target_index < 0 or target_index >= enemies.size() or enemies[target_index]["hp"] <= 0:
			var alive := living_enemies()
			target_index = alive[0] if not alive.is_empty() else -1
		if target_index >= 0:
			targets = [target_index]
	var hits := int(ability.get("hits", 1))
	for hit in hits:
		for t in targets:
			var enemy: Dictionary = enemies[t]
			if enemy["hp"] <= 0:
				continue
			var damage := _compute_damage(hero, enemy, ability)
			if ability.has("bonus_vs_full_hp") and enemy["hp"] == enemy["max_hp"]:
				damage = int(damage * float(ability["bonus_vs_full_hp"]))
			damage = _consume_mark(enemy, damage)
			_deal_damage(enemy, damage, enemy["name"])
			# Life Drain-mönstret: en del av skadan helar användaren.
			if ability.has("leech"):
				var healed: int = (
					mini(
						int(hero["max_hp"]), int(hero["hp"]) + int(damage * float(ability["leech"]))
					)
					- int(hero["hp"])
				)
				hero["hp"] = int(hero["hp"]) + healed
				if healed > 0:
					log.append("%s drains %d HP." % [hero["name"], healed])
			if ability.has("status") and enemy["hp"] > 0:
				enemy["statuses"].append(ability["status"].duplicate())


## Marked (Hunter's Mark): förbrukas av nästa träff som då slår +75%.
func _consume_mark(enemy: Dictionary, damage: int) -> int:
	for i in enemy["statuses"].size():
		var status: Dictionary = enemy["statuses"][i]
		if status["id"] == "marked":
			enemy["statuses"].remove_at(i)
			log.append("The mark is struck true!")
			return int(damage * float(status.get("mult", 1.75)))
	return damage


## Heal går automatiskt till mest skadad levande hjälte (party_design.md).
func _do_heal(hero: Dictionary, ability: Dictionary) -> void:
	var amount := maxi(1, int(float(ability["power"]) * float(hero["magic"])))
	var targets: Array = []
	if String(ability["target"]) == "all_allies":
		targets = living_heroes()
	else:
		var most_wounded := _most_wounded_hero()
		if most_wounded >= 0:
			targets = [most_wounded]
	for i in targets:
		var ally: Dictionary = heroes[i]
		var healed: int = mini(int(ally["max_hp"]), int(ally["hp"]) + amount) - int(ally["hp"])
		ally["hp"] = int(ally["hp"]) + healed
		log.append("%s heals %s for %d HP." % [hero["name"], ally["name"], healed])


func _do_revive(hero: Dictionary, ability: Dictionary) -> void:
	var downed := downed_heroes()
	if downed.is_empty():
		return
	var ally: Dictionary = heroes[downed[0]]
	ally["hp"] = maxi(1, int(float(ally["max_hp"]) * float(ability["power"])))
	ally["statuses"] = []
	log.append("%s resurrects %s!" % [hero["name"], ally["name"]])


func _do_taunt(hero: Dictionary, ability: Dictionary) -> void:
	for i in living_enemies():
		var status: Dictionary = ability["status"].duplicate()
		status["hero_index"] = int(hero["hero_index"])
		enemies[i]["statuses"].append(status)
	if ability.has("self_status"):
		hero["statuses"].append(ability["self_status"].duplicate())
	log.append("%s taunts the enemies!" % hero["name"])


## Defend: nästa träff halveras (guard_next, samma flagga som fiendernas
## guard) och hjälten fokuserar – mana-motorn i stridsekonomin.
func _do_defend(hero: Dictionary) -> void:
	hero["guard_next"] = true
	hero["mana"] = mini(int(hero["max_mana"]), int(hero["mana"]) + Balance.DEFEND_MANA_BONUS)
	log.append("%s braces and focuses (+%d mana)." % [hero["name"], Balance.DEFEND_MANA_BONUS])


func _do_buff(hero: Dictionary, ability: Dictionary) -> void:
	# Bard-mönstret: sånger buffar hela partyt.
	if String(ability["target"]) == "all_allies":
		for i in living_heroes():
			heroes[i]["statuses"].append(ability["status"].duplicate())
		log.append("%s uses %s on the whole party!" % [hero["name"], ability["name"]])
		return
	var target := hero
	if String(ability["target"]) == "ally":
		var most_wounded := _most_wounded_hero()
		if most_wounded >= 0:
			target = heroes[most_wounded]
	target["statuses"].append(ability["status"].duplicate())
	log.append("%s uses %s on %s." % [hero["name"], ability["name"], target["name"]])


func _most_wounded_hero() -> int:
	var best := -1
	var best_missing := -1
	for i in living_heroes():
		var missing := int(heroes[i]["max_hp"]) - int(heroes[i]["hp"])
		if missing > best_missing:
			best_missing = missing
			best = i
	return best


func _compute_damage(attacker: Dictionary, defender: Dictionary, ability: Dictionary) -> int:
	var base: float
	if ability["kind"] == "magic":
		base = float(attacker.get("magic", attacker["attack"])) * float(ability["power"])
		base -= float(defender.get("armor", 0)) * (1.0 - Balance.MAGIC_ARMOR_PENETRATION)
	else:
		base = float(attacker["attack"]) * float(ability["power"])
		if not ability.get("armor_pierce", false):
			base -= float(defender.get("armor", 0))
	base *= float(attacker.get("damage_mult", 1.0))
	for status in attacker["statuses"]:
		if status["id"] == "atk_up":
			base *= float(status.get("mult", 1.5))
		elif status["id"] == "weakened":
			base *= float(status.get("mult", 0.7))
	# Exposed (combo-status): målet tar mer skada av ALLA – ordningen
	# inom rundan blir taktik (öppna med backstab, nuka sedan).
	for status in defender["statuses"]:
		if status["id"] == "exposed":
			base *= float(status.get("mult", 1.35))
	base *= rng.randf_range(0.9, 1.1)
	return maxi(Balance.MIN_DAMAGE, int(base))


func _deal_damage(target: Dictionary, amount: int, target_name: String) -> void:
	for i in target["statuses"].size():
		if target["statuses"][i]["id"] == "evade":
			target["statuses"].remove_at(i)
			log.append("%s evades the attack!" % target_name)
			return
	for status in target["statuses"]:
		if status["id"] == "shield":
			var absorbed: int = mini(amount, int(status["amount"]))
			status["amount"] = int(status["amount"]) - absorbed
			amount -= absorbed
			if absorbed > 0:
				log.append("The shield absorbs %d damage." % absorbed)
	if target.get("guard_next", false):
		amount = int(amount / 2.0)
		target["guard_next"] = false
	if amount > 0:
		target["hp"] = int(target["hp"]) - amount
		log.append("%s takes %d damage." % [target_name, amount])
	if target["hp"] <= 0:
		target["hp"] = 0
		log.append("%s goes down!" % target_name)


## Tickar statuseffekter vid turstart. Returnerar false om turen hoppar över.
func _tick_statuses_and_check(unit: Dictionary, unit_name: String) -> bool:
	var stunned := false
	var remaining: Array = []
	for status in unit["statuses"]:
		match status["id"]:
			"poison":
				unit["hp"] = int(unit["hp"]) - int(status["amount"])
				log.append("%s takes %d poison damage." % [unit_name, int(status["amount"])])
			"stun":
				stunned = true
				log.append("%s is stunned and misses a turn." % unit_name)
		status["duration"] = int(status["duration"]) - 1
		if (
			int(status["duration"]) > 0
			and not (status["id"] == "shield" and int(status.get("amount", 0)) <= 0)
		):
			remaining.append(status)
	unit["statuses"] = remaining
	if unit["hp"] <= 0:
		unit["hp"] = 0
		log.append("%s goes down!" % unit_name)
		return false
	return not stunned


func _party_wiped() -> bool:
	return living_heroes().is_empty()


# --- Intentioner (US-3.4): planeras vid rundstart, pekar ut hjältemål ---


func plan_intents() -> void:
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if enemy["hp"] <= 0:
			enemy["intent"] = {}
			continue
		enemy["intent"] = _decide_action(
			enemy, round_number + (1 if enemy.get("acted", false) else 0)
		)


## Hjältehandlingar kan ändra läget (taunt, dödade fiender) – fiender
## som inte agerat än den här rundan tänker om.
func _replan_pending_intents() -> void:
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if enemy["hp"] > 0 and not enemy.get("acted", false):
			enemy["intent"] = _decide_action(enemy, round_number)


func _decide_action(enemy: Dictionary, acting_round: int) -> Dictionary:
	for status in enemy["statuses"]:
		if status["id"] == "stun":
			return {"kind": "stunned", "label": "Stunned", "target": -1}
	var special := _special_action(enemy, acting_round)
	if not special.is_empty():
		return special
	return _attack_intent(enemy, 1.0, "attack")


func _special_action(enemy: Dictionary, acting_round: int) -> Dictionary:
	match String(enemy["behavior"]):
		"healer":
			var wounded := _most_wounded_ally()
			if not wounded.is_empty() and wounded["hp"] < wounded["max_hp"] * 0.7:
				var heal := int(enemy.get("heal_power", 6))
				return {"kind": "heal", "label": "Heal +%d" % heal, "target": -1}
		"tank":
			if acting_round % 2 == 0:
				return {"kind": "guard", "label": "Guard", "target": -1}
		"berserker":
			if enemy["hp"] < enemy["max_hp"] * 0.5:
				return _attack_intent(enemy, 2.0, "frenzy")
		"miniboss":
			if acting_round % 3 == 0:
				return _attack_intent(enemy, 1.8, "heavy")
		"boss":
			if int(enemy.get("phase", 1)) == 2 and acting_round % 2 == 0:
				return _attack_intent(enemy, 0.9, "double")
	return {}


func _attack_intent(enemy: Dictionary, mult: float, kind: String) -> Dictionary:
	var target := _pick_hero_target(enemy)
	if target < 0:
		return {"kind": kind, "label": "Attack", "target": -1}
	var est := _estimate_damage(enemy, mult, String(enemy["behavior"]) == "ranged", target)
	var target_name := String(heroes[target]["name"])
	var label: String
	match kind:
		"frenzy":
			label = "Frenzy %s ~%d" % [target_name, est]
		"heavy":
			label = "Heavy %s ~%d" % [target_name, est]
		"double":
			label = "2 hits %s ~%d" % [target_name, est]
			est *= 2
		_:
			label = "Attack %s ~%d" % [target_name, est]
	return {"kind": kind, "label": label, "target": target, "est": est}


## Melee når bara frontraden (om någon lever); taunt tvingar målet.
func _pick_hero_target(enemy: Dictionary) -> int:
	for status in enemy["statuses"]:
		if status["id"] == "taunt":
			var idx := int(status.get("hero_index", -1))
			if idx >= 0 and idx < heroes.size() and heroes[idx]["hp"] > 0:
				return idx
	var alive := living_heroes()
	if alive.is_empty():
		return -1
	if String(enemy["behavior"]) in MELEE_BEHAVIORS:
		var front: Array = alive.filter(func(i): return String(heroes[i]["row"]) == "front")
		if not front.is_empty():
			return front[rng.randi_range(0, front.size() - 1)]
	return alive[rng.randi_range(0, alive.size() - 1)]


func _estimate_damage(enemy: Dictionary, mult: float, ignore_half_armor: bool, target: int) -> int:
	var armor := float(heroes[target].get("armor", 0))
	if ignore_half_armor:
		armor *= 0.5
	var base := float(enemy["attack"]) * mult * _weakened_mult(enemy) - armor
	return maxi(Balance.MIN_DAMAGE, int(base))


## Weakened (Curse/Cutting Words): -30% skada – syns även i intenten.
func _weakened_mult(unit: Dictionary) -> float:
	var mult := 1.0
	for status in unit["statuses"]:
		if status["id"] == "weakened":
			mult *= float(status.get("mult", 0.7))
	return mult


# --- Fiendeturer ---


func _enemy_act(enemy: Dictionary) -> void:
	# US-6.1: bossen byter fas under 50% HP.
	if enemy.get("is_boss", false) and enemy["phase"] == 1 and enemy["hp"] <= enemy["max_hp"] / 2:
		enemy["phase"] = 2
		enemy["attack"] = int(enemy["attack"] * 1.4)
		log.append("%s roars – phase 2! Its attacks grow stronger." % enemy["name"])
	var intent: Dictionary = enemy.get("intent", {})
	if intent.is_empty():
		intent = _decide_action(enemy, round_number)
	enemy["intent"] = {}
	var target := int(intent.get("target", -1))
	match String(intent.get("kind", "attack")):
		"heal":
			var wounded := _most_wounded_ally()
			if not wounded.is_empty() and wounded["hp"] < wounded["max_hp"]:
				var heal := int(enemy.get("heal_power", 6))
				wounded["hp"] = mini(int(wounded["max_hp"]), int(wounded["hp"]) + heal)
				log.append("%s heals %s for %d HP." % [enemy["name"], wounded["name"], heal])
			else:
				_enemy_attack(enemy, 1.0, target)
		"guard":
			enemy["guard_next"] = true
			log.append("%s takes a defensive stance." % enemy["name"])
		"frenzy":
			log.append("%s rages!" % enemy["name"])
			_enemy_attack(enemy, 2.0, target)
		"heavy":
			log.append("%s raises its grave pick..." % enemy["name"])
			_enemy_attack(enemy, 1.8, target)
		"double":
			log.append("%s lashes out in frenzy – two attacks!" % enemy["name"])
			_enemy_attack(enemy, 0.9, target)
			if not _party_wiped():
				_enemy_attack(enemy, 0.9, -1)
		_:
			_enemy_attack(enemy, 1.0, target)


func _enemy_attack(enemy: Dictionary, mult: float, target: int) -> void:
	if target < 0 or target >= heroes.size() or heroes[target]["hp"] <= 0:
		target = _pick_hero_target(enemy)
	if target < 0:
		return
	var hero: Dictionary = heroes[target]
	var ignore_half_armor := String(enemy["behavior"]) == "ranged"
	var armor := float(hero.get("armor", 0))
	if ignore_half_armor:
		armor *= 0.5
	var base := float(enemy["attack"]) * mult * _weakened_mult(enemy) - armor
	base *= rng.randf_range(0.9, 1.1)
	var damage := maxi(Balance.MIN_DAMAGE, int(base))
	log.append("%s attacks %s." % [enemy["name"], hero["name"]])
	_deal_damage(hero, damage, hero["name"])


func _most_wounded_ally() -> Dictionary:
	var best := {}
	var best_missing := 0
	for i in living_enemies():
		var enemy: Dictionary = enemies[i]
		var missing := int(enemy["max_hp"]) - int(enemy["hp"])
		if missing > best_missing:
			best_missing = missing
			best = enemy
	return best


func _end_combat(outcome: String) -> void:
	result = outcome
	awaiting_player = false
	active_hero = -1
	if outcome == "victory":
		log.append("Victory!")
	else:
		log.append("The party has fallen...")


## Total Essens och XP från besegrade fiender.
func rewards() -> Dictionary:
	var essence := 0
	var xp := 0
	for enemy in enemies:
		if enemy["hp"] <= 0:
			essence += int(enemy["essence"])
			xp += int(enemy["xp"])
	return {"essence": essence, "xp": xp}


# --- Serialisering (US-11.2: resume mitt i strid) ---


func to_dict() -> Dictionary:
	return {
		"heroes": heroes,
		"enemies": enemies,
		"round_number": round_number,
		"turn_index": turn_index,
		"turn_order": turn_order,
		"awaiting_player": awaiting_player,
		"active_hero": active_hero,
		"hero_acted": hero_acted,
		"result": result,
		"log": log.slice(maxi(0, log.size() - 20)),
		"rng_seed": rng.seed,
		"rng_state": rng.state,
	}


static func from_dict(data: Dictionary) -> CombatEngine:
	var engine := CombatEngine.new()
	engine.heroes = data["heroes"]
	engine.enemies = data["enemies"]
	engine.round_number = int(data["round_number"])
	engine.turn_index = int(data["turn_index"])
	engine.turn_order = data["turn_order"].map(
		func(entry): return {"side": String(entry["side"]), "index": int(entry["index"])}
	)
	engine.awaiting_player = data["awaiting_player"]
	engine.active_hero = int(data.get("active_hero", -1))
	engine.hero_acted = data.get("hero_acted", []).map(func(v): return int(v))
	engine.result = data["result"]
	engine.log = data["log"]
	engine.rng.seed = int(data["rng_seed"])
	engine.rng.state = int(data["rng_state"])
	return engine
