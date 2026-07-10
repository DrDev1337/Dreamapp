class_name CombatEngine
extends RefCounted
## Turbaserad stridsmotor (US-3.1): full manuell kontroll, ingen tidspress.
## UI-flöde:
##   1. setup() eller from_dict()
##   2. advance_until_player_turn()  – fiender agerar, stannar på spelarens tur
##   3. player_action(ability_id, target_index)
##   4. upprepa 2-3 tills is_over()
## Hela tillståndet serialiseras via to_dict() så att en stängd app
## kan återupptas exakt där den var (US-11.2).

var player := {}
var enemies: Array = []
var round_number := 1
var turn_index := 0
var turn_order: Array = []  # t.ex. ["player", 0, 1] – index in i enemies
var awaiting_player := false
var result := ""  # "", "victory", "defeat"
var log: Array = []
var rng := RandomNumberGenerator.new()


## Bygger spelarens stridsrepresentation från karaktär + aktiva boosts.
static func build_player(character: CharacterState, boosts: Array = []) -> Dictionary:
	var damage_mult := 1.0
	for boost in boosts:
		damage_mult *= float(boost.get("damage_mult", 1.0))
	return {
		"name": character.character_name,
		"max_hp": character.total_stat("max_hp"),
		"hp": character.total_stat("max_hp"),
		"attack": character.total_stat("attack"),
		"magic": character.total_stat("magic"),
		"speed": character.total_stat("speed"),
		"armor": character.total_stat("armor"),
		"max_mana": character.total_stat("max_mana"),
		"mana": character.total_stat("max_mana"),
		"damage_mult": damage_mult,
		"ability_ids": character.combat_ability_ids(),
		"cooldowns": {},
		"statuses": [],
	}


func setup(player_data: Dictionary, enemy_list: Array, seed_value: int) -> void:
	player = player_data
	enemies = enemy_list
	rng.seed = seed_value
	round_number = 1
	_build_turn_order()
	log.append("Battle! %d enemies stand in your way." % enemies.size())


func is_over() -> bool:
	return result != ""


func living_enemies() -> Array:
	var alive: Array = []
	for i in enemies.size():
		if enemies[i]["hp"] > 0:
			alive.append(i)
	return alive


# --- Turordning (US-3.1: tydlig turordning) ---


func _build_turn_order() -> void:
	var entries: Array = []
	entries.append({"key": "player", "speed": _effective_speed(player)})
	for i in enemies.size():
		if enemies[i]["hp"] > 0:
			entries.append({"key": i, "speed": _effective_speed(enemies[i])})
	entries.sort_custom(func(a, b): return a["speed"] > b["speed"])
	turn_order = entries.map(func(e): return e["key"])
	turn_index = 0


func _effective_speed(unit: Dictionary) -> int:
	var speed := int(unit["speed"])
	for status in unit["statuses"]:
		if status["id"] == "slow":
			speed = maxi(1, speed - 2)
	return speed


## Kör fiendeturer tills det är spelarens tur eller striden är slut.
func advance_until_player_turn() -> void:
	awaiting_player = false
	while result == "":
		if turn_index >= turn_order.size():
			round_number += 1
			_build_turn_order()
			continue
		var key = turn_order[turn_index]
		if key is String and key == "player":
			if _tick_statuses_and_check(player, "You"):
				awaiting_player = true
				return
			# Spelaren var bedövad eller dog av statuseffekt.
			if player["hp"] <= 0:
				_end_combat("defeat")
				return
			turn_index += 1
			continue
		var enemy_index := int(key)
		var enemy: Dictionary = enemies[enemy_index]
		if enemy["hp"] > 0:
			if _tick_statuses_and_check(enemy, enemy["name"]):
				_enemy_act(enemy)
			if player["hp"] <= 0:
				_end_combat("defeat")
				return
			if living_enemies().is_empty():
				_end_combat("victory")
				return
		turn_index += 1


## Spelarens handling (US-3.2). Returnerar true om handlingen var giltig.
func player_action(ability_id: String, target_index: int) -> bool:
	if not awaiting_player or result != "":
		return false
	var ability := Abilities.get_ability(ability_id)
	if ability.is_empty() or ability_id not in player["ability_ids"]:
		return false
	if int(player["cooldowns"].get(ability_id, 0)) > 0:
		return false
	if player["mana"] < int(ability["mana_cost"]):
		return false
	player["mana"] = int(player["mana"]) - int(ability["mana_cost"])
	if int(ability["cooldown"]) > 0:
		player["cooldowns"][ability_id] = int(ability["cooldown"]) + 1
	_execute_ability(player, ability, target_index, true)
	# Mana-regen och cooldown-tick i slutet av spelarens tur.
	player["mana"] = mini(int(player["max_mana"]), int(player["mana"]) + Balance.PLAYER_MANA_REGEN)
	for id in player["cooldowns"].keys():
		player["cooldowns"][id] = maxi(0, int(player["cooldowns"][id]) - 1)
	awaiting_player = false
	if living_enemies().is_empty():
		_end_combat("victory")
	else:
		turn_index += 1
		advance_until_player_turn()
	return true


# --- Intern logik ---


func _execute_ability(
	user: Dictionary, ability: Dictionary, target_index: int, is_player: bool
) -> void:
	var kind: String = ability["kind"]
	if kind == "buff":
		var status: Dictionary = ability["status"].duplicate()
		user["statuses"].append(status)
		log.append("%s uses %s." % [_unit_name(user, is_player), ability["name"]])
		return
	var targets: Array = []
	if ability["target"] == "all_enemies":
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
			var damage := _compute_damage(user, enemy, ability)
			if ability.has("bonus_vs_full_hp") and enemy["hp"] == enemy["max_hp"]:
				damage = int(damage * float(ability["bonus_vs_full_hp"]))
			_deal_damage(enemy, damage, enemy["name"])
			if ability.has("status") and enemy["hp"] > 0:
				enemy["statuses"].append(ability["status"].duplicate())


func _compute_damage(attacker: Dictionary, defender: Dictionary, ability: Dictionary) -> int:
	var base: float
	if ability["kind"] == "magic":
		base = float(attacker.get("magic", attacker["attack"])) * float(ability["power"])
		base -= float(defender.get("armor", 0)) * (1.0 - Balance.MAGIC_ARMOR_PENETRATION)
	else:
		base = float(attacker["attack"]) * float(ability["power"])
		base -= float(defender.get("armor", 0))
	base *= float(attacker.get("damage_mult", 1.0))
	for status in attacker["statuses"]:
		if status["id"] == "atk_up":
			base *= float(status.get("mult", 1.5))
	# Liten variation så strider inte känns mekaniska.
	base *= rng.randf_range(0.9, 1.1)
	return maxi(Balance.MIN_DAMAGE, int(base))


func _deal_damage(target: Dictionary, amount: int, target_name: String) -> void:
	# Undanglidning negerar hela träffen.
	for i in target["statuses"].size():
		if target["statuses"][i]["id"] == "evade":
			target["statuses"].remove_at(i)
			log.append("%s evades the attack!" % target_name)
			return
	# Sköld absorberar först.
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
		log.append("%s is defeated!" % target_name)


## Tickar statuseffekter vid turstart. Returnerar false om turen ska hoppa över (stun).
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
		log.append("%s succumbs." % unit_name)
		return false
	return not stunned


func _enemy_act(enemy: Dictionary) -> void:
	# US-6.1: bossen byter fas under 50% HP.
	if enemy.get("is_boss", false) and enemy["phase"] == 1 and enemy["hp"] <= enemy["max_hp"] / 2:
		enemy["phase"] = 2
		enemy["attack"] = int(enemy["attack"] * 1.4)
		log.append("%s roars – phase 2! Its attacks grow stronger." % enemy["name"])
	match enemy["behavior"]:
		"healer":
			var wounded := _most_wounded_ally()
			if not wounded.is_empty() and wounded["hp"] < wounded["max_hp"] * 0.7:
				var heal := int(enemy.get("heal_power", 6))
				wounded["hp"] = mini(int(wounded["max_hp"]), int(wounded["hp"]) + heal)
				log.append("%s heals %s for %d HP." % [enemy["name"], wounded["name"], heal])
			else:
				_enemy_attack(enemy, 1.0)
		"tank":
			if round_number % 2 == 0:
				enemy["guard_next"] = true
				log.append("%s takes a defensive stance." % enemy["name"])
			else:
				_enemy_attack(enemy, 1.0)
		"berserker":
			var mult := 2.0 if enemy["hp"] < enemy["max_hp"] * 0.5 else 1.0
			if mult > 1.0:
				log.append("%s rages!" % enemy["name"])
			_enemy_attack(enemy, mult)
		"ranged":
			_enemy_attack(enemy, 1.0, true)
		"miniboss":
			# Vart tredje varv: tungt slag.
			if round_number % 3 == 0:
				log.append("%s raises its grave pick..." % enemy["name"])
				_enemy_attack(enemy, 1.8)
			else:
				_enemy_attack(enemy, 1.0)
		"boss":
			if enemy["phase"] == 2 and round_number % 2 == 0:
				log.append("%s lashes out in frenzy – two attacks!" % enemy["name"])
				_enemy_attack(enemy, 0.9)
				if player["hp"] > 0:
					_enemy_attack(enemy, 0.9)
			else:
				_enemy_attack(enemy, 1.0)
		_:
			_enemy_attack(enemy, 1.0)


func _enemy_attack(enemy: Dictionary, mult: float, ignore_half_armor := false) -> void:
	var base := float(enemy["attack"]) * mult
	var armor := float(player.get("armor", 0))
	if ignore_half_armor:
		armor *= 0.5
	base -= armor
	base *= rng.randf_range(0.9, 1.1)
	var damage := maxi(Balance.MIN_DAMAGE, int(base))
	log.append("%s attacks you." % enemy["name"])
	_deal_damage(player, damage, "You")


func _most_wounded_ally() -> Dictionary:
	var best := {}
	var best_missing := 0
	for i in living_enemies():
		var e: Dictionary = enemies[i]
		var missing := int(e["max_hp"]) - int(e["hp"])
		if missing > best_missing:
			best_missing = missing
			best = e
	return best


func _unit_name(unit: Dictionary, is_player: bool) -> String:
	return "You" if is_player else String(unit["name"])


func _end_combat(outcome: String) -> void:
	result = outcome
	awaiting_player = false
	if outcome == "victory":
		log.append("Victory!")
	else:
		log.append("You have fallen...")


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
		"player": player,
		"enemies": enemies,
		"round_number": round_number,
		"turn_index": turn_index,
		"turn_order": turn_order,
		"awaiting_player": awaiting_player,
		"result": result,
		"log": log.slice(maxi(0, log.size() - 20)),
		"rng_seed": rng.seed,
		"rng_state": rng.state,
	}


static func from_dict(data: Dictionary) -> CombatEngine:
	var engine := CombatEngine.new()
	engine.player = data["player"]
	engine.enemies = data["enemies"]
	engine.round_number = int(data["round_number"])
	engine.turn_index = int(data["turn_index"])
	engine.turn_order = data["turn_order"].map(func(k): return k if (k is String) else int(k))
	engine.awaiting_player = data["awaiting_player"]
	engine.result = data["result"]
	engine.log = data["log"]
	engine.rng.seed = int(data["rng_seed"])
	engine.rng.state = int(data["rng_state"])
	return engine
