extends SceneTree
## Balanssimulator för party-modellen: spelar N runs genom den riktiga
## motorn med en enkel spelar-AI och skriver ut aggregerad statistik.
## Körs i CI:  godot --headless -s tools/simulate.gd
##
## AI-policy (medvetet enkel men rimlig):
##  - Strid, per hjälte: revive om någon fallit, heal om någon är låg,
##    taunt från frontraden när den är redo, annars bästa skada
##    (AoE när 2+ fiender lever); mål = healer som tänker hela, annars
##    lägst HP.
##  - Checkpoint: helar (väcker fallna) och fortsätter tills nivågrind.
##  - Level up: driver mot kompositionen tank/rogue/healer/mage/mage.
##  - Hubb: köper billigaste permanenta uppgraderingen tills råd saknas.
## "casual"-policyn efterliknar en ny spelare: bara basattack på första
## bästa mål, första level up-valet, ingen komposition.

const RUNS := 100
const FRESH_RUNS := 50
const DESIRED_AXES := ["tank", "rogue", "healer", "mage", "mage"]
# Speglar party-pickern: varje rekryt startar med en förmåga (en per axel).
const SIM_SPECS := [
	{"name": "Sim1", "ability_id": "taunt"},
	{"name": "Sim2", "ability_id": "backstab"},
	{"name": "Sim3", "ability_id": "mend"},
	{"name": "Sim4", "ability_id": "firebolt"},
	{"name": "Sim5", "ability_id": "frost_nova"},
]

var casual_mode := false
var early_outcomes: Array = []  # run-för-run för de 10 första progressionsrunsen

var outcome_counts := {}
var death_by_depth := {}
var death_room_types := {}
var essence_banked_total := 0
var level_at_milestone := {}
var piles_created := 0
var piles_recovered := 0
var fight_actions := {}  # depth -> [total_actions, fights]
var hp_lost_by_depth := {}  # depth -> [total_party_hp_lost, fights]
var downed_by_depth := {}  # depth -> [hjältar nere efter vunnen strid, fights]
var elite_stats := {"miniboss": [0, 0], "boss": [0, 0]}  # [försök, vinster]
var stuck_fights := 0


func _init() -> void:
	var party := PartyState.create(SIM_SPECS)
	for run_index in RUNS:
		var before_level := party.level
		var outcome := _play_run(party, 10_000 + run_index)
		_hub_shopping(party)
		if run_index < 10:
			early_outcomes.append(
				"run %d: %s (nivå %d->%d)" % [run_index + 1, outcome, before_level, party.level]
			)
		if run_index + 1 in [10, 25, 50, 100]:
			level_at_milestone[run_index + 1] = party.level
	_print_report(party)
	_simulate_fresh_cohort(false)
	_simulate_fresh_cohort(true)
	quit(0)


## Färska partyn utan meta-progression: mäter run 1-upplevelsen.
func _simulate_fresh_cohort(casual: bool) -> void:
	casual_mode = casual
	var depth_reached := {}
	var deaths := 0
	for i in FRESH_RUNS:
		var party := PartyState.create(SIM_SPECS)
		var outcome := _play_run(party, 50_000 + i + (100_000 if casual else 0))
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
	print("=== FÄRSKT PARTY (%d runs, %s AI) ===" % [FRESH_RUNS, label])
	print("  wipes: %d av %d" % [deaths, FRESH_RUNS])
	var depths := depth_reached.keys()
	depths.sort()
	for depth in depths:
		print("  slutdjup %d: %d" % [depth, depth_reached[depth]])


func _play_run(party: PartyState, seed_value: int) -> String:
	var run := RunState.start(party, seed_value)
	var banked_before := party.banked_essence
	var outcome := ""
	var safety := 0
	while safety < 100:
		safety += 1
		if run.is_run_complete():
			run.bank_and_end(party)
			outcome = "boss_clear"
			break
		if run.at_checkpoint():
			run.heal_at_checkpoint()
			if not run.can_go_deeper(party):
				run.bank_and_end(party)
				outcome = "gated_bank_d%d" % run.current_depth
				break
		var event := run.enter_next_room(party)
		if int(event["recovered_essence"]) > 0:
			piles_recovered += 1
		var chest: Dictionary = event.get("chest_item", {})
		if not chest.is_empty():
			_maybe_equip(party, run, chest)
			continue
		var room := run.current_room()
		var is_elite: bool = room["type"] in ["miniboss", "boss"]
		if is_elite:
			elite_stats[room["type"]][0] += 1
		var won := _play_combat(run, party)
		if not won:
			var summary := run.on_death(party)
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
	essence_banked_total += party.banked_essence - banked_before
	return outcome


func _party_hp(combat: CombatEngine) -> int:
	var total := 0
	for hero in combat.heroes:
		total += int(hero["hp"])
	return total


## Returnerar true vid seger.
func _play_combat(run: RunState, party: PartyState) -> bool:
	var combat := run.combat
	var depth := run.current_depth
	var hp_before := _party_hp(combat)
	var actions := 0
	while not combat.is_over() and actions < 400:
		if not combat.awaiting_player:
			combat.advance_until_player_turn()
			continue
		var choice := _choose_hero_action(combat)
		if not combat.player_action(choice[0], choice[1]):
			combat.player_action("basic_attack", -1)
		actions += 1
	if actions >= 400:
		stuck_fights += 1
		return false
	var bucket: Array = fight_actions.get(depth, [0, 0])
	bucket[0] += actions
	bucket[1] += 1
	fight_actions[depth] = bucket
	if combat.result == "victory":
		var lost_bucket: Array = hp_lost_by_depth.get(depth, [0, 0])
		lost_bucket[0] += hp_before - _party_hp(combat)
		lost_bucket[1] += 1
		hp_lost_by_depth[depth] = lost_bucket
		var down_bucket: Array = downed_by_depth.get(depth, [0, 0])
		down_bucket[0] += combat.downed_heroes().size()
		down_bucket[1] += 1
		downed_by_depth[depth] = down_bucket
		var rewards := run.on_combat_victory(party)
		for i in int(rewards["levels_gained"]):
			_pick_levelup(party, run)
		var loot: Dictionary = rewards.get("loot", {})
		if not loot.is_empty():
			_maybe_equip(party, run, loot)
		return true
	return false


func _usable(hero: Dictionary, id: String) -> bool:
	if id not in hero["ability_ids"]:
		return false
	if int(hero["cooldowns"].get(id, 0)) > 0:
		return false
	var ability := Abilities.get_ability(id)
	return int(hero["mana"]) >= int(ability["mana_cost"])


func _choose_hero_action(combat: CombatEngine) -> Array:
	var hero: Dictionary = combat.heroes[combat.active_hero]
	var alive := combat.living_enemies()
	if casual_mode:
		return ["basic_attack", alive[0]]
	# 1. Väck fallna kamrater.
	if _usable(hero, "resurrect") and not combat.downed_heroes().is_empty():
		return ["resurrect", -1]
	# 2. Hela när någon är låg.
	var wounded_count := 0
	var worst_fraction := 1.0
	for i in combat.living_heroes():
		var ally: Dictionary = combat.heroes[i]
		var fraction := float(ally["hp"]) / float(ally["max_hp"])
		worst_fraction = minf(worst_fraction, fraction)
		if fraction < 0.7:
			wounded_count += 1
	if worst_fraction < 0.55:
		if _usable(hero, "radiance") and wounded_count >= 3:
			return ["radiance", -1]
		if _usable(hero, "mend"):
			return ["mend", -1]
	# 3. Tanka hotet från frontraden.
	if String(hero["row"]) == "front":
		for taunt_id in ["bulwark", "taunt"]:
			if _usable(hero, taunt_id):
				return [taunt_id, -1]
	# 4. Bästa skada mot bästa mål.
	var target: int = alive[0]
	var lowest_hp := 999999
	for i in alive:
		if String(combat.enemies[i].get("intent", {}).get("kind", "")) == "heal":
			target = i
			break
		if int(combat.enemies[i]["hp"]) < lowest_hp:
			lowest_hp = int(combat.enemies[i]["hp"])
			target = i
	var best_id := "basic_attack"
	var best_score := 0.0
	for id in hero["ability_ids"]:
		if not _usable(hero, id):
			continue
		var ability := Abilities.get_ability(id)
		var kind := String(ability["kind"])
		if kind not in ["physical", "magic"]:
			continue
		var stat := float(hero["magic"] if kind == "magic" else hero["attack"])
		var multiplier := float(alive.size()) if ability["target"] == "all_enemies" else 1.0
		var score := stat * float(ability["power"]) * multiplier * float(ability.get("hits", 1))
		if score > best_score:
			best_score = score
			best_id = id
	return [best_id, target]


## Driver partyt mot kompositionen i DESIRED_AXES.
func _pick_levelup(party: PartyState, run: RunState) -> void:
	var choices := LevelUp.generate_choices(party, run.rng)
	if casual_mode:
		LevelUp.apply_choice(party, choices[0])
		return
	var best: Dictionary = choices[0]
	var best_score := -1
	for choice in choices:
		var hero_index := int(choice["hero_index"])
		var hero: Hero = party.heroes[hero_index]
		var axis := String(choice["axis"])
		var score := 0
		# Lås kompositionen först: oklassade hjältar på önskad axel går före
		# att mata redan låsta hjältar med fler stats.
		if hero.class_identity == "":
			score += 4 if axis == DESIRED_AXES[hero_index] else int(hero.axis_points.get(axis, 0))
		else:
			score += 2 if hero.class_identity == axis else 0
		if score > best_score:
			best_score = score
			best = choice
	LevelUp.apply_choice(party, best)


func _maybe_equip(party: PartyState, run: RunState, item: Dictionary) -> void:
	var hero_index := run.best_hero_for_item(party, item)
	var current: Dictionary = party.heroes[hero_index].equipment.get(String(item["slot"]), {})
	if current.is_empty() or Items.power_score(item) > Items.power_score(current):
		run.equip_item(party, item, hero_index)


func _hub_shopping(party: PartyState) -> void:
	var bought := true
	while bought:
		bought = false
		var cheapest_id := ""
		var cheapest_cost := 999999
		for id in Upgrades.PERMANENT:
			var rank := int(party.permanent_upgrades.get(id, 0))
			if rank >= int(Upgrades.PERMANENT[id]["max_rank"]):
				continue
			var cost := Upgrades.permanent_cost(id, rank)
			if cost < cheapest_cost:
				cheapest_cost = cost
				cheapest_id = id
		if cheapest_id != "" and party.banked_essence >= cheapest_cost:
			bought = Upgrades.buy_permanent(party, cheapest_id)


func _print_report(party: PartyState) -> void:
	print("=== SIMULERING: %d runs (party) ===" % RUNS)
	print("--- De 10 första runsen ---")
	for line in early_outcomes:
		print("  " + line)
	print("--- Utfall ---")
	var keys := outcome_counts.keys()
	keys.sort()
	for key in keys:
		print("  %s: %d" % [key, outcome_counts[key]])
	print("--- Wipes per djup ---")
	var depths := death_by_depth.keys()
	depths.sort()
	for depth in depths:
		print("  djup %d: %d" % [depth, death_by_depth[depth]])
	print("--- Wipes per rumstyp ---")
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
		var downs: Array = downed_by_depth.get(depth, [0, 1])
		print(
			(
				"  djup %d: %.1f handlingar/strid, %.1f party-HP förlorat, %.2f fällda hjältar/vunnen strid (%d strider)"
				% [
					depth,
					float(bucket[0]) / bucket[1],
					float(lost[0]) / maxi(1, lost[1]),
					float(downs[0]) / maxi(1, downs[1]),
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
	var classes: Array = []
	for hero in party.heroes:
		classes.append(hero.class_identity if hero.class_identity != "" else "-")
	print("  Slutnivå: %d, klasser: %s, wipes: %d" % [party.level, str(classes), party.deaths])
	print("  Uppgraderingar: %s" % str(party.permanent_upgrades))
	print("  Fastnade strider (>400 handlingar): %d" % stuck_fights)
	print("=== SLUT ===")
