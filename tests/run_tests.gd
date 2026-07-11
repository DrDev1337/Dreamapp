extends SceneTree
## Headless-tester för kärnlogiken (party-modellen). Kör med:
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
	test_party_targeting_and_support()
	test_enemy_intents()
	test_hero_and_classing()
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
	check(Balance.PARTY_SIZE == 5, "partyt är 5 hjältar (party_design.md)")
	check(Balance.FRONT_ROW_SIZE == 2, "frontraden är 2 hjältar")
	check(Balance.required_level_for_depth(1) == 1, "djup 1 kräver nivå 1")
	check(Balance.required_level_for_depth(3) == 1, "djup 3 kräver nivå 1")
	check(Balance.required_level_for_depth(4) == 3, "djup 4 kräver nivå 3 (US-1.3)")
	check(Balance.required_level_for_depth(8) == 5, "djup 8 kräver nivå 5")
	check(Balance.max_depth_for_level(1) == 3, "nivå 1 når djup 3")
	check(Balance.max_depth_for_level(3) == 6, "nivå 3 når djup 6")
	check(Balance.max_depth_for_level(5) == 8, "nivå 5 når djup 8")
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


## Handbyggd stridshjälte. Fallande fart (20, 19, …) ger deterministisk
## turordning i testerna: hjälte 0 agerar först, sedan 1 osv, sist fienderna.
func _make_hero(index: int, hp := 30, attack := 6, abilities := ["basic_attack"]) -> Dictionary:
	return {
		"name": "Hero%d" % index,
		"hero_index": index,
		"row": "front" if index < Balance.FRONT_ROW_SIZE else "back",
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"magic": 5,
		"speed": 20 - index,
		"armor": 0,
		"max_mana": 12,
		"mana": 12,
		"damage_mult": 1.0,
		"ability_ids": abilities.duplicate(),
		"cooldowns": {},
		"statuses": [],
	}


func _make_party_combat(hp := 30, attack := 6) -> Array:
	var list: Array = []
	for i in Balance.PARTY_SIZE:
		list.append(_make_hero(i, hp, attack))
	return list


func test_combat_victory_and_defeat() -> void:
	print("Combat…")
	var engine := CombatEngine.new()
	engine.setup(_make_party_combat(), [Enemies.spawn("cave_rat", 1)], 42)
	engine.advance_until_player_turn()
	check(engine.awaiting_player, "motorn stannar på en hjältes tur (US-3.1)")
	check(engine.active_hero == 0, "snabbaste hjälten agerar först")
	check(not engine.player_action("meteor", 0), "okänd/ej lärd ability nekas")
	var turns := 0
	while not engine.is_over() and turns < 60:
		engine.player_action("basic_attack", 0)
		turns += 1
	check(engine.result == "victory", "partyt vinner mot en råtta")
	var rewards := engine.rewards()
	check(int(rewards["essence"]) > 0 and int(rewards["xp"]) > 0, "seger ger Essens och XP")

	# Alla hjältar agerar en gång per runda ("Alla får 1 per runda").
	var round_engine := CombatEngine.new()
	round_engine.setup(_make_party_combat(), [Enemies.spawn("stone_golem", 1)], 43)
	var actors: Array = []
	for i in Balance.PARTY_SIZE:
		round_engine.advance_until_player_turn()
		actors.append(round_engine.active_hero)
		round_engine.player_action("basic_attack", 0)
		if round_engine.round_number > 1 or round_engine.is_over():
			break
	check(actors == [0, 1, 2, 3, 4], "varje hjälte agerar exakt en gång per runda")

	var doomed := CombatEngine.new()
	doomed.setup(_make_party_combat(1, 1), [Enemies.spawn("stone_golem", 5)], 7)
	var safety := 0
	while not doomed.is_over() and safety < 400:
		doomed.advance_until_player_turn()
		if doomed.awaiting_player:
			doomed.player_action("basic_attack", 0)
		safety += 1
	check(doomed.result == "defeat", "svagt party besegras – partywipe")


func test_party_targeting_and_support() -> void:
	print("Party (rader, taunt, heal, revive)…")
	# Melee-fiender når bara frontraden (party_design.md).
	var engine := CombatEngine.new()
	engine.setup(_make_party_combat(), [Enemies.spawn("cave_rat", 1)], 5)
	engine.advance_until_player_turn()
	var intent: Dictionary = engine.enemies[0]["intent"]
	check(int(intent["target"]) in [0, 1], "melee-fiende siktar på frontraden")
	check(String(intent["label"]).contains("Hero"), "intentionen namnger hjältemålet")

	# Taunt från bakre raden tvingar om fiendens mål.
	var heroes := _make_party_combat()
	heroes[3]["ability_ids"] = ["basic_attack", "taunt"]
	var taunt_engine := CombatEngine.new()
	taunt_engine.setup(heroes, [Enemies.spawn("stone_golem", 1)], 6)
	for i in 3:
		taunt_engine.advance_until_player_turn()
		taunt_engine.player_action("basic_attack", -1)
	taunt_engine.advance_until_player_turn()
	check(taunt_engine.active_hero == 3, "rätt hjälte står i tur")
	taunt_engine.player_action("taunt", -1)
	if not taunt_engine.is_over():
		var enemy: Dictionary = taunt_engine.enemies[0]
		var has_taunt := false
		for status in enemy["statuses"]:
			if status["id"] == "taunt" and int(status["hero_index"]) == 3:
				has_taunt = true
		check(has_taunt, "taunt-status pekar på användaren")
		check(int(enemy["intent"]["target"]) == 3, "fienden planerar om mot taunten")

	# Heal går automatiskt till mest skadad hjälte.
	var heal_heroes := _make_party_combat()
	heal_heroes[2]["ability_ids"] = ["basic_attack", "mend"]
	var heal_engine := CombatEngine.new()
	heal_engine.setup(heal_heroes, [Enemies.spawn("stone_golem", 1)], 8)
	heal_engine.heroes[0]["hp"] = 10
	for i in 2:
		heal_engine.advance_until_player_turn()
		heal_engine.player_action("basic_attack", -1)
	heal_engine.advance_until_player_turn()
	heal_engine.player_action("mend", -1)
	check(int(heal_engine.heroes[0]["hp"]) == 21, "mend helar mest skadade hjälten (2.2×magi)")

	# Revive: nekas utan fallen hjälte, väcker annars den första fallna.
	var revive_heroes := _make_party_combat()
	revive_heroes[0]["ability_ids"] = ["basic_attack", "resurrect"]
	var revive_engine := CombatEngine.new()
	revive_engine.setup(revive_heroes, [Enemies.spawn("stone_golem", 1)], 9)
	revive_engine.advance_until_player_turn()
	check(not revive_engine.player_action("resurrect", -1), "revive nekas utan fallen hjälte")
	revive_engine.heroes[4]["hp"] = 0
	check(revive_engine.player_action("resurrect", -1), "revive tillåts med fallen hjälte")
	check(int(revive_engine.heroes[4]["hp"]) == 15, "hjälten väcks på halv styrka")


func test_enemy_intents() -> void:
	print("Intents (US-3.4)…")
	var engine := CombatEngine.new()
	engine.setup(
		_make_party_combat(),
		[Enemies.spawn("stone_golem", 1), Enemies.spawn("cultist_healer", 1)],
		11
	)
	engine.advance_until_player_turn()
	var golem_kind := String(engine.enemies[0].get("intent", {}).get("kind", ""))
	check(golem_kind == "attack", "tank attackerar udda rundor")
	engine.round_number = 2
	engine.plan_intents()
	check(engine.enemies[0]["intent"]["kind"] == "guard", "tank planerar guard jämna rundor")
	# Skadad allierad gör att healern planerar heal.
	engine.enemies[0]["hp"] = int(engine.enemies[0]["max_hp"] * 0.3)
	engine.plan_intents()
	check(engine.enemies[1]["intent"]["kind"] == "heal", "healern planerar heal åt skadad allierad")
	# Intentionen överlever serialisering (US-11.2).
	var resumed := CombatEngine.from_dict(JSON.parse_string(JSON.stringify(engine.to_dict())))
	check(String(resumed.enemies[1]["intent"]["kind"]) == "heal", "intentioner överlever resume")


func test_hero_and_classing() -> void:
	print("Hero & classing…")
	var hero := Hero.new()
	check(hero.ability_ids == ["basic_attack"], "rekryter börjar med bara basattack (US-4.1)")
	for i in Balance.CLASS_UNLOCK_PICKS - 1:
		check(not hero.apply_class_pick("mage"), "för få val låser inte klass")
	var unlocked := hero.apply_class_pick("mage")
	check(
		unlocked and hero.class_identity == "mage",
		"%d val i samma riktning låser klass (US-4.2)" % Balance.CLASS_UNLOCK_PICKS
	)
	check("meteor" in hero.ability_ids, "signaturförmåga lärs vid klasslåsning")

	var party := PartyState.create(["Ask", "Embla", "Runa", "Grim", "Saga"])
	check(party.heroes.size() == Balance.PARTY_SIZE, "nytt party har 5 hjältar")
	check(party.hero_row(0) == "front" and party.hero_row(2) == "back", "rad 0-1 är frontrad")
	var levels := party.gain_xp(Balance.xp_for_level(1))
	check(levels == 1 and party.level == 2, "party-XP ger level up")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var choices := LevelUp.generate_choices(party, rng)
	check(choices.size() == 3, "level up ger 3 val (US-4.2)")
	var hero_indices := {}
	for choice in choices:
		hero_indices[int(choice["hero_index"])] = true
	check(hero_indices.size() == 3, "valen gäller tre olika hjältar")
	var chosen_hero: Hero = party.heroes[int(choices[0]["hero_index"])]
	var before := str(chosen_hero.bonus_stats)
	LevelUp.apply_choice(party, choices[0])
	check(str(chosen_hero.bonus_stats) != before, "valet ger hjälten stats")


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
	var party := PartyState.create(["A", "B", "C", "D", "E"])
	party.level = 10  # inga djupgränser i det här testet
	var run := RunState.start(party, 42)
	run.current_depth = 3
	run.carried_essence = 120
	var summary := run.on_death(party)
	check(int(summary["lost_essence"]) == 120, "wipe tappar all buren Essens (US-2.3)")
	check(run.carried_essence == 0, "buren Essens nollas vid wipe")
	check(
		party.death_pile["depth"] == 3 and party.death_pile["essence"] == 120,
		"högen ligger på dödsdjupet"
	)

	# Andra döden ersätter högen permanent (US-2.5).
	var run2 := RunState.start(party, 43)
	run2.current_depth = 1
	run2.carried_essence = 30
	var summary2 := run2.on_death(party)
	check(summary2["replaced_old_pile"], "varning: gammal hög ersattes")
	check(int(party.death_pile["essence"]) == 30, "bara senaste högen finns (US-2.5)")

	# Att dö/överge utan något att tappa rör inte den befintliga högen.
	var empty_run := RunState.start(party, 99)
	empty_run.current_depth = 2
	var empty_summary := empty_run.on_death(party)
	check(int(party.death_pile["essence"]) == 30, "tom wipe skriver inte över högen")
	check(not empty_summary["replaced_old_pile"], "tom wipe flaggar inte ersatt hög")

	# Corpse run: nå djupet och få tillbaka allt (US-2.4).
	var run3 := RunState.start(party, 44)
	check(run3.rooms[0]["has_pile"], "högen markeras i nästa run (US-2.4)")
	var event := run3.enter_next_room(party)
	check(int(event["recovered_essence"]) == 30, "hela summan returneras (US-2.4)")
	check(run3.carried_essence == 30, "återhämtad Essens bärs (osäkrad) igen")
	check(not party.has_death_pile(), "högen är tömd")

	# Banka vid checkpoint (US-2.2).
	run3.carried_essence = 50
	var banked := run3.bank_and_end(party)
	check(banked == 50 and party.banked_essence == 50, "stanna säkrar Essens till banken")

	# Checkpointen väcker fallna hjältar och helar alla (party_design.md).
	var camp_run := RunState.start(party, 45)
	camp_run.heroes_combat[0]["hp"] = 0
	camp_run.heroes_combat[3]["hp"] = 5
	camp_run.heal_at_checkpoint()
	check(
		int(camp_run.heroes_combat[0]["hp"]) == int(camp_run.heroes_combat[0]["max_hp"]),
		"checkpointen väcker fallna hjältar"
	)
	check(
		int(camp_run.heroes_combat[3]["hp"]) == int(camp_run.heroes_combat[3]["max_hp"]),
		"checkpointen helar till fullo"
	)

	# Djupgräns (US-1.3).
	var novice := PartyState.create(["N1", "N2", "N3", "N4", "N5"])
	var novice_run := RunState.start(novice, 46)
	novice_run.current_depth = 3
	check(not novice_run.can_go_deeper(novice), "nivå 1 stoppas efter checkpoint 1 (US-1.3)")
	check(novice_run.deeper_lock_reason(novice) != "", "tydlig indikation om varför (US-1.3)")


func test_upgrades() -> void:
	print("Upgrades…")
	check(Upgrades.PERMANENT.size() >= 5, "minst 5 permanenta uppgraderingar (US-2.6)")
	check(Upgrades.TEMPORARY.size() >= 3, "minst 3 tillfälliga boosts (US-2.6)")
	var party := PartyState.create(["A", "B", "C", "D", "E"])
	party.banked_essence = 1000
	var hp_before: int = party.heroes[0].total_stat("max_hp", party)
	check(Upgrades.buy_permanent(party, "vitality"), "köp av permanent uppgradering")
	check(
		party.heroes[0].total_stat("max_hp", party) == hp_before + 4,
		"uppgraderingen ger stats till alla hjältar"
	)
	check(party.banked_essence == 950, "kostnaden dras från banken")
	check(
		Upgrades.permanent_cost("vitality", 1) > Upgrades.permanent_cost("vitality", 0),
		"kostnaden stiger per rank"
	)
	check(Upgrades.buy_temporary(party, "battle_luck"), "köp av boost i hubben")
	check(party.pending_boosts.size() == 1, "boosten väntar på nästa run")
	var run := RunState.start(party, 47)
	check(party.pending_boosts.is_empty(), "pending boosts förbrukas vid run-start")
	check(float(run.heroes_combat[0]["damage_mult"]) > 1.0, "boosten är aktiv i runnen")
	party.banked_essence = 0
	check(not Upgrades.buy_permanent(party, "vitality"), "köp nekas utan Essens")


func test_items() -> void:
	print("Items…")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var epic := Items.generate(rng, 3, false, "epic")
	check(epic["secured"], "episka föremål säkras direkt (designbeslut Q3)")
	var common := Items.generate(rng, 3, false, "common")
	check(not common["secured"], "vanliga föremål är osäkrade (US-5.2)")
	check(Items.RARITIES.size() == 3, "3 rariteter (US-5.1)")
	# Utrustning går till hjälten med svagast slot och syns i striden.
	var party := PartyState.create(["A", "B", "C", "D", "E"])
	var run := RunState.start(party, 48)
	var best := run.best_hero_for_item(party, common)
	run.equip_item(party, common, best)
	check(
		not party.heroes[best].equipment[String(common["slot"])].is_empty(),
		"föremålet är utrustat på vald hjälte"
	)
	check(run.unsecured_items.size() == 1, "osäkrat föremål spåras för wipe-drop (US-5.2)")


func test_serialization() -> void:
	print("Serialisering (US-11.2)…")
	var party := PartyState.create(["Saga", "Grim", "Runa", "Ask", "Embla"])
	party.level = 4
	party.banked_essence = 77
	party.death_pile = {"depth": 5, "essence": 40, "loot": []}
	party.heroes[0].apply_class_pick("tank")
	party.heroes[0].apply_class_pick("tank")
	party.heroes[0].apply_class_pick("tank")
	var restored := PartyState.from_dict(JSON.parse_string(JSON.stringify(party.to_dict())))
	check(restored.party_name == "Saga" and restored.level == 4, "partyt överlever roundtrip")
	check(restored.heroes.size() == Balance.PARTY_SIZE, "alla hjältar överlever roundtrip")
	check(
		restored.heroes[0].class_identity == "tank" and "bulwark" in restored.heroes[0].ability_ids,
		"klassidentitet och signatur överlever roundtrip"
	)
	check(
		restored.banked_essence == 77 and int(restored.death_pile["depth"]) == 5,
		"Essens och hög överlever roundtrip"
	)

	# Run + pågående strid: exakt läge ska gå att återuppta.
	var run := RunState.start(party, 49)
	var event := run.enter_next_room(party)
	check(event["combat_started"], "rum 1 startar strid")
	# Regression: spelflödet måste själv köra fram till en hjältes tur –
	# annars är awaiting_player false och inga knappar fungerar i UI:t.
	check(run.combat.awaiting_player, "nytt rum står direkt på en hjältes tur")
	check(run.combat.active_hero >= 0, "en aktiv hjälte pekas ut")
	var json_payload := JSON.stringify(run.to_dict())
	var parsed = JSON.parse_string(json_payload)
	var resumed := RunState.from_dict(parsed)
	check(
		resumed.combat != null and resumed.combat.awaiting_player,
		"striden återupptas på hjältens tur"
	)
	check(resumed.combat.active_hero == run.combat.active_hero, "samma hjälte står i tur")
	check(
		int(resumed.combat.heroes[0]["hp"]) == int(run.combat.heroes[0]["hp"]),
		"hjältarnas HP bevaras exakt"
	)
	check(resumed.combat.enemies.size() == run.combat.enemies.size(), "fienderna bevaras")
	check(
		resumed.heroes_combat == resumed.combat.heroes,
		"heroes_combat delas med motorn efter resume"
	)
	var acted := resumed.combat.player_action("basic_attack", 0)
	check(acted, "striden är spelbar efter resume")
