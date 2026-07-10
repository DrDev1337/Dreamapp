extends SceneTree
## Headless-tester för kärnlogiken. Kör med:
##   godot --headless --import   (första gången, bygger klasscachen)
##   godot --headless -s tests/run_tests.gd
## Avslutar med exitkod 0 om allt passerar, annars 1.

var checks := 0
var failures := 0


func check(condition: bool, test_name: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % test_name)


func _init() -> void:
	test_balance()
	test_enemies()
	test_combat_victory_and_defeat()
	test_character_and_classing()
	test_run_generation()
	test_essence_death_and_recovery()
	test_upgrades()
	test_items()
	test_serialization()
	print("")
	if failures == 0:
		print("OK: %d/%d tester passerade." % [checks, checks])
	else:
		printerr("MISSLYCKADES: %d av %d tester föll." % [failures, checks])
	quit(1 if failures > 0 else 0)


func test_balance() -> void:
	print("Balance…")
	check(Balance.required_level_for_depth(1) == 1, "djup 1 kräver nivå 1")
	check(Balance.required_level_for_depth(3) == 1, "djup 3 kräver nivå 1")
	check(Balance.required_level_for_depth(4) == 2, "djup 4 kräver nivå 2 (US-1.3)")
	check(Balance.required_level_for_depth(8) == 4, "djup 8 kräver nivå 4")
	check(Balance.max_depth_for_level(1) == 3, "nivå 1 når djup 3")
	check(Balance.max_depth_for_level(4) == 8, "nivå 4 når djup 8")
	check(
		Balance.essence_for_enemy(3) > Balance.essence_for_enemy(1),
		"Essens skalar med djup (US-2.1)"
	)


func test_enemies() -> void:
	print("Enemies…")
	check(Enemies.CATALOG.size() >= 5, "minst 5 fiendetyper (US-3.3)")
	var behaviors := {}
	for id in Enemies.CATALOG:
		behaviors[Enemies.CATALOG[id]["behavior"]] = true
	check(behaviors.size() >= 2, "minst 2 distinkta beteenden (US-3.3)")
	var shallow := Enemies.spawn("cave_rat", 1)
	var deep := Enemies.spawn("cave_rat", 5)
	check(deep["max_hp"] > shallow["max_hp"], "fiender skalar med djup (US-1.2)")
	check(deep["essence"] > shallow["essence"], "belöningar skalar med djup (US-1.2)")


func _make_player(hp := 60, attack := 12) -> Dictionary:
	return {
		"name": "Test",
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"magic": 8,
		"speed": 5,
		"armor": 0,
		"max_mana": 20,
		"mana": 20,
		"damage_mult": 1.0,
		"ability_ids": ["basic_attack", "focus_strike"],
		"cooldowns": {},
		"statuses": [],
	}


func test_combat_victory_and_defeat() -> void:
	print("Combat…")
	var engine := CombatEngine.new()
	engine.setup(_make_player(), [Enemies.spawn("cave_rat", 1)], 42)
	engine.advance_until_player_turn()
	check(engine.awaiting_player, "motorn stannar på spelarens tur (US-3.1)")
	check(not engine.player_action("meteor", 0), "okänd/ej lärd ability nekas")
	var turns := 0
	while not engine.is_over() and turns < 20:
		engine.player_action("basic_attack", 0)
		turns += 1
	check(engine.result == "victory", "spelaren vinner mot en råtta")
	var rewards := engine.rewards()
	check(int(rewards["essence"]) > 0 and int(rewards["xp"]) > 0, "seger ger Essens och XP")

	var doomed := CombatEngine.new()
	doomed.setup(_make_player(1, 1), [Enemies.spawn("stone_golem", 5)], 7)
	var safety := 0
	while not doomed.is_over() and safety < 50:
		doomed.advance_until_player_turn()
		if doomed.awaiting_player:
			doomed.player_action("basic_attack", 0)
		safety += 1
	check(doomed.result == "defeat", "svag spelare besegras")


func test_character_and_classing() -> void:
	print("Character…")
	var character := CharacterState.new()
	check(character.ability_ids.size() == 2, "svag start: basattack + 1 ability (US-4.1)")
	var levels := character.gain_xp(Balance.xp_for_level(1))
	check(levels == 1 and character.level == 2, "XP ger level up")
	check(not character.apply_class_pick("mage"), "1 val låser inte klass")
	character.apply_class_pick("mage")
	var unlocked := character.apply_class_pick("mage")
	check(
		unlocked and character.class_identity == "mage",
		"3 val i samma riktning låser klass (US-4.2)"
	)
	check("meteor" in character.ability_ids, "signaturförmåga lärs vid klasslåsning")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var choices := LevelUp.generate_choices(character, rng)
	check(choices.size() == 3, "level up ger 3 val (US-4.2)")


func test_run_generation() -> void:
	print("RunGenerator…")
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var rooms := RunGenerator.generate(rng, 5)
	check(
		rooms.size() == Balance.RUN_ROOM_COUNT,
		"en run har %d rum (US-1.2)" % Balance.RUN_ROOM_COUNT
	)
	check(
		rooms[2]["checkpoint_after"] and rooms[5]["checkpoint_after"],
		"checkpoint efter rum 3 och 6 (US-7.1)"
	)
	check(rooms[3]["type"] == "miniboss", "miniboss i rum 4 (US-6.2)")
	check(rooms[7]["type"] == "boss", "boss i rum 8 (US-6.1)")
	check(rooms[4]["has_pile"], "dödshögen placeras på sitt djup (US-7.2)")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 999
	var other := RunGenerator.generate(rng2)
	check(other[7]["type"] == "boss", "fasta regler gäller oavsett seed")


func test_essence_death_and_recovery() -> void:
	print("Essens…")
	var character := CharacterState.new()
	character.level = 10  # inga djupgränser i det här testet
	var run := RunState.start(character, 42)
	run.current_depth = 3
	run.carried_essence = 120
	var summary := run.on_death(character)
	check(int(summary["lost_essence"]) == 120, "död tappar all buren Essens (US-2.3)")
	check(run.carried_essence == 0, "buren Essens nollas vid död")
	check(
		character.death_pile["depth"] == 3 and character.death_pile["essence"] == 120,
		"högen ligger på dödsdjupet"
	)

	# Andra döden ersätter högen permanent (US-2.5).
	var run2 := RunState.start(character, 43)
	run2.current_depth = 1
	run2.carried_essence = 30
	var summary2 := run2.on_death(character)
	check(summary2["replaced_old_pile"], "varning: gammal hög ersattes")
	check(int(character.death_pile["essence"]) == 30, "bara senaste högen finns (US-2.5)")

	# Corpse run: nå djupet och få tillbaka allt (US-2.4).
	var run3 := RunState.start(character, 44)
	check(run3.rooms[0]["has_pile"], "högen markeras i nästa run (US-2.4)")
	var event := run3.enter_next_room(character)
	check(int(event["recovered_essence"]) == 30, "hela summan returneras (US-2.4)")
	check(run3.carried_essence == 30, "återhämtad Essens bärs (osäkrad) igen")
	check(not character.has_death_pile(), "högen är tömd")

	# Banka vid checkpoint (US-2.2).
	run3.carried_essence = 50
	var banked := run3.bank_and_end(character)
	check(banked == 50 and character.banked_essence == 50, "stanna säkrar Essens till banken")

	# Djupgräns (US-1.3).
	var novice := CharacterState.new()
	var novice_run := RunState.start(novice, 45)
	novice_run.current_depth = 3
	check(not novice_run.can_go_deeper(novice), "nivå 1 stoppas efter checkpoint 1 (US-1.3)")
	check(novice_run.deeper_lock_reason(novice) != "", "tydlig indikation om varför (US-1.3)")


func test_upgrades() -> void:
	print("Upgrades…")
	check(Upgrades.PERMANENT.size() >= 5, "minst 5 permanenta uppgraderingar (US-2.6)")
	check(Upgrades.TEMPORARY.size() >= 3, "minst 3 tillfälliga boosts (US-2.6)")
	var character := CharacterState.new()
	character.banked_essence = 1000
	var hp_before := character.total_stat("max_hp")
	check(Upgrades.buy_permanent(character, "vitality"), "köp av permanent uppgradering")
	check(character.total_stat("max_hp") == hp_before + 10, "uppgraderingen ger stats")
	check(character.banked_essence == 950, "kostnaden dras från banken")
	check(
		Upgrades.permanent_cost("vitality", 1) > Upgrades.permanent_cost("vitality", 0),
		"kostnaden stiger per rank"
	)
	check(Upgrades.buy_temporary(character, "battle_luck"), "köp av boost i hubben")
	check(character.pending_boosts.size() == 1, "boosten väntar på nästa run")
	var run := RunState.start(character, 46)
	check(character.pending_boosts.is_empty(), "pending boosts förbrukas vid run-start")
	check(run.player_combat["damage_mult"] > 1.0, "boosten är aktiv i runnen")
	character.banked_essence = 0
	check(not Upgrades.buy_permanent(character, "vitality"), "köp nekas utan Essens")


func test_items() -> void:
	print("Items…")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var epic := Items.generate(rng, 3, false, "epic")
	check(epic["secured"], "episka föremål säkras direkt (designbeslut Q3)")
	var common := Items.generate(rng, 3, false, "common")
	check(not common["secured"], "vanliga föremål är osäkrade (US-5.2)")
	check(Items.RARITIES.size() == 3, "3 rariteter (US-5.1)")


func test_serialization() -> void:
	print("Serialisering (US-11.2)…")
	var character := CharacterState.new()
	character.character_name = "Saga"
	character.level = 4
	character.banked_essence = 77
	character.death_pile = {"depth": 5, "essence": 40, "loot": []}
	var restored := CharacterState.from_dict(character.to_dict())
	check(restored.character_name == "Saga" and restored.level == 4, "karaktär överlever roundtrip")
	check(
		restored.banked_essence == 77 and restored.death_pile["depth"] == 5,
		"Essens och hög överlever roundtrip"
	)

	# Run + pågående strid: exakt läge ska gå att återuppta.
	var run := RunState.start(character, 47)
	var event := run.enter_next_room(character)
	check(event["combat_started"], "rum 1 startar strid")
	run.combat.advance_until_player_turn()
	var json_payload := JSON.stringify(run.to_dict())
	var parsed = JSON.parse_string(json_payload)
	var resumed := RunState.from_dict(parsed)
	check(
		resumed.combat != null and resumed.combat.awaiting_player,
		"striden återupptas på spelarens tur"
	)
	check(
		int(resumed.combat.player["hp"]) == int(run.combat.player["hp"]),
		"spelarens HP bevaras exakt"
	)
	check(resumed.combat.enemies.size() == run.combat.enemies.size(), "fienderna bevaras")
	var acted := resumed.combat.player_action("basic_attack", 0)
	check(acted, "striden är spelbar efter resume")
