extends SceneTree
## Balanssimulator: spelar N runs genom den riktiga motorn med en enkel
## spelar-AI och skriver ut aggregerad statistik. Körs i CI:
##   godot --headless -s tools/simulate.gd
##
## AI-policy (medvetet enkel men rimlig):
##  - Strid: AoE när 2+ fiender lever, annars kraftfullaste råd-havda
##    ability; mål = healer som tänker hela, annars lägst HP.
##  - Checkpoint: fortsätter djupare om HP > 35%, annars bankar.
##  - Level up: driver mot fighter tills klass, sedan högsta axeln.
##  - Hubb: köper billigaste permanenta uppgraderingen tills råd saknas.

const RUNS := 100
const FRESH_RUNS := 50
const PREFERRED_AXIS := "fighter"

# "casual"-policyn efterliknar en ny spelare: bara basattack, första
# bästa mål, ingen healer-prioritering.
var casual_mode := false
var early_outcomes: Array = []  # run-för-run för de 10 första progressionsrunsen

var outcome_counts := {}
var death_by_depth := {}
var death_room_types := {}
var essence_banked_total := 0
var banked_by_decile := {}
var level_at_milestone := {}
var piles_created := 0
var piles_recovered := 0
var fight_actions := {}  # depth -> [total_actions, fights]
var hp_lost_by_depth := {}  # depth -> [total_lost, fights]
var elite_stats := {"miniboss": [0, 0], "boss": [0, 0]}  # [försök, vinster]
var stuck_fights := 0


func _init() -> void:
	var character := CharacterState.new()
	character.character_name = "Sim"
	for run_index in RUNS:
		var before_level := character.level
		var outcome := _play_run(character, 10_000 + run_index)
		_hub_shopping(character)
		if run_index < 10:
			early_outcomes.append(
				"run %d: %s (nivå %d->%d)" % [run_index + 1, outcome, before_level, character.level]
			)
		if run_index + 1 in [10, 25, 50, 100]:
			level_at_milestone[run_index + 1] = character.level
	_print_report(character)
	_simulate_fresh_cohort(false)
	_simulate_fresh_cohort(true)
	quit(0)


## Färska karaktärer utan meta-progression: mäter run 1-upplevelsen.
func _simulate_fresh_cohort(casual: bool) -> void:
	casual_mode = casual
	var depth_reached := {}
	var deaths := 0
	for i in FRESH_RUNS:
		var character := CharacterState.new()
		var outcome := _play_run(character, 50_000 + i + (100_000 if casual else 0))
		var depth := 0
		for part in outcome.split("_"):
			if part.begins_with("d") and part.substr(1).is_valid_int():
				depth = int(part.substr(1))
		if outcome == "boss_clear":
			depth = 8
		elif outcome.begins_with("death"):
			deaths += 1
		depth_reached[depth] = int(depth_reached.get(depth, 0)) + 1
	casual_mode = false
	var label := "CASUAL" if casual else "OPTIMAL"
	print("=== FÄRSK KARAKTÄR (%d runs, %s AI) ===" % [FRESH_RUNS, label])
	print("  döda: %d av %d" % [deaths, FRESH_RUNS])
	var depths := depth_reached.keys()
	depths.sort()
	for depth in depths:
		print("  slutdjup %d: %d" % [depth, depth_reached[depth]])


func _play_run(character: CharacterState, seed_value: int) -> String:
	var run := RunState.start(character, seed_value)
	var had_pile := character.has_death_pile()
	var banked_before := character.banked_essence
	var outcome := ""
	var safety := 0
	while safety < 100:
		safety += 1
		if run.is_run_complete():
			run.bank_and_end(character)
			outcome = "boss_clear"
			break
		if run.at_checkpoint():
			run.heal_at_checkpoint()
			if not run.can_go_deeper(character):
				run.bank_and_end(character)
				outcome = "gated_bank_d%d" % run.current_depth
				break
			var hp_frac := float(run.player_combat["hp"]) / float(run.player_combat["max_hp"])
			if hp_frac < 0.35:
				run.bank_and_end(character)
				outcome = "hp_bank_d%d" % run.current_depth
				break
		var event := run.enter_next_room(character)
		if int(event["recovered_essence"]) > 0:
			piles_recovered += 1
		var chest: Dictionary = event.get("chest_item", {})
		if not chest.is_empty():
			_maybe_equip(character, run, chest)
			continue
		var room := run.current_room()
		var is_elite: bool = room["type"] in ["miniboss", "boss"]
		if is_elite:
			elite_stats[room["type"]][0] += 1
		var won := _play_combat(run, character)
		if not won:
			var summary := run.on_death(character)
			if int(summary["lost_essence"]) > 0 or int(summary["lost_items"]) > 0:
				piles_created += 1
			death_by_depth[run.current_depth] = int(death_by_depth.get(run.current_depth, 0)) + 1
			death_room_types[room["type"]] = int(death_room_types.get(room["type"], 0)) + 1
			outcome = "death_d%d" % run.current_depth
			break
		if is_elite:
			elite_stats[room["type"]][1] += 1
	if outcome == "":
		outcome = "safety_stop"
	outcome_counts[outcome] = int(outcome_counts.get(outcome, 0)) + 1
	essence_banked_total += character.banked_essence - banked_before
	if had_pile:
		pass  # högar räknas via piles_created/piles_recovered
	return outcome


## Returnerar true vid seger.
func _play_combat(run: RunState, character: CharacterState) -> bool:
	var combat := run.combat
	var depth := run.current_depth
	var hp_before := int(combat.player["hp"])
	var actions := 0
	while not combat.is_over() and actions < 200:
		if not combat.awaiting_player:
			combat.advance_until_player_turn()
			continue
		var choice := _choose_action(combat)
		combat.player_action(choice[0], choice[1])
		actions += 1
	if actions >= 200:
		stuck_fights += 1
		return false
	var bucket: Array = fight_actions.get(depth, [0, 0])
	bucket[0] += actions
	bucket[1] += 1
	fight_actions[depth] = bucket
	if combat.result == "victory":
		var lost_bucket: Array = hp_lost_by_depth.get(depth, [0, 0])
		lost_bucket[0] += hp_before - int(combat.player["hp"])
		lost_bucket[1] += 1
		hp_lost_by_depth[depth] = lost_bucket
		var rewards := run.on_combat_victory(character)
		for i in int(rewards["levels_gained"]):
			_pick_levelup(character, run)
		var loot: Dictionary = rewards.get("loot", {})
		if not loot.is_empty():
			_maybe_equip(character, run, loot)
		return true
	return false


func _choose_action(combat: CombatEngine) -> Array:
	var alive := combat.living_enemies()
	if casual_mode:
		return ["basic_attack", alive[0]]
	var target: int = alive[0]
	var lowest_hp := 999999
	for i in alive:
		if String(combat.enemies[i].get("intent", {}).get("kind", "")) == "heal":
			target = i
			lowest_hp = -1  # healern prioriteras alltid
			break
		if int(combat.enemies[i]["hp"]) < lowest_hp:
			lowest_hp = int(combat.enemies[i]["hp"])
			target = i
	var best_id := "basic_attack"
	var best_score := 0.0
	for id in combat.player["ability_ids"]:
		var ability := Abilities.get_ability(id)
		if ability.get("kind", "") == "buff":
			continue
		if int(combat.player["cooldowns"].get(id, 0)) > 0:
			continue
		if int(combat.player["mana"]) < int(ability["mana_cost"]):
			continue
		var multiplier := float(alive.size()) if ability["target"] == "all_enemies" else 1.0
		var score := float(ability["power"]) * multiplier * float(ability.get("hits", 1))
		if score > best_score:
			best_score = score
			best_id = id
	return [best_id, target]


func _pick_levelup(character: CharacterState, run: RunState) -> void:
	var choices := LevelUp.generate_choices(character, run.rng)
	var axis := PREFERRED_AXIS
	if character.class_identity != "":
		axis = character.class_identity
	for choice in choices:
		if choice["axis"] == axis:
			LevelUp.apply_choice(character, choice)
			return
	LevelUp.apply_choice(character, choices[0])


func _maybe_equip(character: CharacterState, run: RunState, item: Dictionary) -> void:
	var current: Dictionary = character.equipment.get(item["slot"], {})
	if current.is_empty() or Items.power_score(item) > Items.power_score(current):
		run.equip_item(character, item)


func _hub_shopping(character: CharacterState) -> void:
	var bought := true
	while bought:
		bought = false
		var cheapest_id := ""
		var cheapest_cost := 999999
		for id in Upgrades.PERMANENT:
			var rank := int(character.permanent_upgrades.get(id, 0))
			if rank >= int(Upgrades.PERMANENT[id]["max_rank"]):
				continue
			var cost := Upgrades.permanent_cost(id, rank)
			if cost < cheapest_cost:
				cheapest_cost = cost
				cheapest_id = id
		if cheapest_id != "" and character.banked_essence >= cheapest_cost:
			bought = Upgrades.buy_permanent(character, cheapest_id)


func _print_report(character: CharacterState) -> void:
	print("=== SIMULERING: %d runs ===" % RUNS)
	print("--- De 10 första runsen ---")
	for line in early_outcomes:
		print("  " + line)
	print("--- Utfall ---")
	var keys := outcome_counts.keys()
	keys.sort()
	for key in keys:
		print("  %s: %d" % [key, outcome_counts[key]])
	print("--- Död per djup ---")
	var depths := death_by_depth.keys()
	depths.sort()
	for depth in depths:
		print("  djup %d: %d" % [depth, death_by_depth[depth]])
	print("--- Död per rumstyp ---")
	for room_type in death_room_types:
		print("  %s: %d" % [room_type, death_room_types[room_type]])
	print("--- Elitstrider (försök/vinster) ---")
	for kind in elite_stats:
		print("  %s: %d/%d" % [kind, elite_stats[kind][0], elite_stats[kind][1]])
	print("--- Strider ---")
	var fight_depths := fight_actions.keys()
	fight_depths.sort()
	for depth in fight_depths:
		var bucket: Array = fight_actions[depth]
		var lost: Array = hp_lost_by_depth.get(depth, [0, 1])
		print(
			(
				"  djup %d: %.1f handlingar/strid, %.1f HP förlorat/vunnen strid (%d strider)"
				% [
					depth,
					float(bucket[0]) / bucket[1],
					float(lost[0]) / maxi(1, lost[1]),
					bucket[1]
				]
			)
		)
	print("--- Ekonomi & progression ---")
	print(
		(
			"  Essens bankad totalt: %d (%.1f/run)"
			% [essence_banked_total, float(essence_banked_total) / RUNS]
		)
	)
	print("  Högar skapade: %d, återhämtade: %d" % [piles_created, piles_recovered])
	print("  Nivå vid run 10/25/50/100: %s" % str(level_at_milestone))
	print(
		(
			"  Slutnivå: %d, klass: %s, dödsfall: %d"
			% [character.level, character.class_identity, character.deaths]
		)
	)
	print("  Uppgraderingar: %s" % str(character.permanent_upgrades))
	print("  Fastnade strider (>200 handlingar): %d" % stuck_fights)
	print("=== SLUT ===")
