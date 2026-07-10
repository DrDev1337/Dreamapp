extends ScreenBase
## Stridsvyn (Epic 3): turordning överst, fiender som tryckbara mål,
## logg, spelarstatus och stora ability-knappar längst ner – spelbart
## med en hand i portrait (US-3.2). Ingen tidspress (US-3.1).

var selected_target := 0
var victory_rewards := {}
# Cachad motor-referens: Game.run.combat nollas av on_combat_victory(),
# men segerpanelen behöver fortfarande läsa slutläget.
var engine: CombatEngine = null


func build() -> void:
	if engine == null:
		engine = Game.run.combat
	var combat: CombatEngine = engine
	if combat == null:
		main.show_run.call_deferred()
		return
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(UIKit.vmargin(layout, 16))

	# Turordning (US-3.1 AC).
	var order_names: Array = []
	for key in combat.turn_order:
		if key is String:
			order_names.append("DU")
		elif combat.enemies[int(key)]["hp"] > 0:
			order_names.append(String(combat.enemies[int(key)]["name"]))
	layout.add_child(
		UIKit.body("Runda %d   Tur: %s" % [combat.round_number, " → ".join(order_names)], 15)
	)

	# Fiender – tryck för att välja mål.
	var alive := combat.living_enemies()
	if selected_target not in alive and not alive.is_empty():
		selected_target = alive[0]
	var enemies_row := HBoxContainer.new()
	enemies_row.add_theme_constant_override("separation", 8)
	for i in combat.enemies.size():
		enemies_row.add_child(_enemy_panel(combat, i))
	layout.add_child(enemies_row)

	# Stridslogg.
	var log_panel := UIKit.panel(Color(0, 0, 0, 0.35))
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_lines: Array = combat.log.slice(maxi(0, combat.log.size() - 7))
	var log_label := UIKit.body("\n".join(log_lines), 15)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(log_label)
	layout.add_child(log_panel)

	# Spelarstatus.
	var player_panel := UIKit.panel()
	var player_box := VBoxContainer.new()
	player_box.add_child(
		UIKit.body("%s   %s" % [combat.player["name"], _status_text(combat.player)], 17)
	)
	player_box.add_child(
		UIKit.bar(int(combat.player["hp"]), int(combat.player["max_hp"]), UIKit.COLOR_HP)
	)
	player_box.add_child(
		UIKit.body("HP %d/%d" % [int(combat.player["hp"]), int(combat.player["max_hp"])], 14)
	)
	player_box.add_child(
		UIKit.bar(int(combat.player["mana"]), int(combat.player["max_mana"]), UIKit.COLOR_MANA, 16)
	)
	player_box.add_child(
		UIKit.body("Mana %d/%d" % [int(combat.player["mana"]), int(combat.player["max_mana"])], 14)
	)
	player_panel.add_child(player_box)
	layout.add_child(player_panel)

	if combat.is_over():
		layout.add_child(_end_panel(combat))
	else:
		layout.add_child(_ability_grid(combat))

	# Onboarding-popup 1/3 (US-9.1).
	if Game.should_show_tutorial("combat_intro"):
		Game.mark_tutorial_seen("combat_intro")
		(
			UIKit
			. popup(
				self,
				"Strid",
				"Striderna är turbaserade – ta den tid du behöver. Tryck på en fiende för att välja mål och sedan på en förmåga för att agera."
			)
		)


func _enemy_panel(combat: CombatEngine, index: int) -> Control:
	var enemy: Dictionary = combat.enemies[index]
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 110)
	button.disabled = enemy["hp"] <= 0
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := "▶ " if index == selected_target and enemy["hp"] > 0 else ""
	var phase_mark := (
		"  [FAS 2]" if enemy.get("is_boss", false) and int(enemy.get("phase", 1)) == 2 else ""
	)
	var name_label := UIKit.body("%s%s%s" % [mark, enemy["name"], phase_mark], 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	box.add_child(UIKit.bar(int(enemy["hp"]), int(enemy["max_hp"]), UIKit.COLOR_HP, 14))
	box.add_child(
		UIKit.body("%d/%d %s" % [int(enemy["hp"]), int(enemy["max_hp"]), _status_text(enemy)], 13)
	)
	button.add_child(box)
	button.pressed.connect(
		func():
			selected_target = index
			rebuild()
	)
	return button


func _status_text(unit: Dictionary) -> String:
	var parts: Array = []
	for status in unit["statuses"]:
		match String(status["id"]):
			"poison":
				parts.append("🟢gift")
			"stun":
				parts.append("💫bedövad")
			"shield":
				parts.append("🛡%d" % int(status.get("amount", 0)))
			"atk_up":
				parts.append("⚔+")
			"slow":
				parts.append("🐌")
			"evade":
				parts.append("👻")
	return " ".join(parts)


func _ability_grid(combat: CombatEngine) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for id in combat.player["ability_ids"]:
		var ability := Abilities.get_ability(id)
		var cooldown := int(combat.player["cooldowns"].get(id, 0))
		var cost_text := (
			"  (%d mana)" % int(ability["mana_cost"]) if int(ability["mana_cost"]) > 0 else ""
		)
		var text := "%s%s" % [ability["name"], cost_text]
		if cooldown > 0:
			text += "\nladdar om: %d turer" % cooldown
		else:
			text += "\n%s" % ability["desc"]
		var button := UIKit.big_button(text, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = (
			cooldown > 0
			or int(combat.player["mana"]) < int(ability["mana_cost"])
			or not combat.awaiting_player
		)
		button.pressed.connect(func(): _use_ability(id))
		grid.add_child(button)
	return grid


func _use_ability(ability_id: String) -> void:
	var combat: CombatEngine = engine
	if combat.player_action(ability_id, selected_target):
		Game.save_game()  # autosave efter varje handling (US-11.2)
		if combat.is_over() and combat.result == "victory":
			victory_rewards = Game.run.on_combat_victory(Game.character)
			Game.save_game()
		rebuild()


func _end_panel(combat: CombatEngine) -> Control:
	var panel := UIKit.panel(Color("204030") if combat.result == "victory" else Color("402020"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	if combat.result == "victory":
		box.add_child(UIKit.title("Seger!", 28))
		box.add_child(
			UIKit.body(
				(
					"+%d Essens   +%d XP"
					% [int(victory_rewards.get("essence", 0)), int(victory_rewards.get("xp", 0))]
				),
				19
			)
		)
		var loot: Dictionary = victory_rewards.get("loot", {})
		if not loot.is_empty():
			var loot_label := UIKit.body("Loot: %s" % Items.describe(loot), 17)
			loot_label.add_theme_color_override(
				"font_color", UIKit.RARITY_COLORS.get(loot.get("rarity", "common"), Color.WHITE)
			)
			box.add_child(loot_label)
			var equip_button := UIKit.big_button("Utrusta", 64)
			equip_button.pressed.connect(
				func():
					Game.run.equip_item(Game.character, loot)
					victory_rewards["loot"] = {}
					Game.save_game()
					rebuild()
			)
			box.add_child(equip_button)
		var continue_button := UIKit.big_button("Fortsätt", 88)
		continue_button.pressed.connect(func(): main.after_room_cleared(victory_rewards))
		box.add_child(continue_button)
		# Onboarding-popup 2/3 (US-9.1): Essens-regeln.
		if Game.should_show_tutorial("essence_intro"):
			Game.mark_tutorial_seen("essence_intro")
			(
				UIKit
				. popup(
					self,
					"Essens",
					"Essens du samlar är OSÄKRAD tills du stannar vid en checkpoint. Dör du tappar du allt du bär – men högen går att hämta igen."
				)
			)
	else:
		box.add_child(UIKit.title("Du föll...", 28))
		var death_button := UIKit.big_button("Fortsätt", 88)
		death_button.pressed.connect(main.player_died)
		box.add_child(death_button)
	panel.add_child(box)
	return panel
