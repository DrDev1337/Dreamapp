extends ScreenBase
## Stridsvyn (Epic 3). Byggs EN gång och uppdateras sedan per handling –
## det gör riktig juice möjlig: HP-bars som glider, flygande skadesiffror,
## skak på träffade fiender och röd blixt när spelaren tar skada.
## Stora enhandsknappar i portrait (US-3.2), ingen tidspress (US-3.1).

var selected_target := 0
var victory_rewards := {}
# Cachad motor-referens: Game.run.combat nollas av on_combat_victory(),
# men slutpanelen behöver fortfarande läsa slutläget.
var engine: CombatEngine = null

# Persistenta nodreferenser.
var order_label: Label
var enemy_widgets: Array = []  # {button, name_label, hp_bar, info_label}
var log_label: Label
var player_hp_bar: ProgressBar
var player_hp_label: Label
var player_mana_bar: ProgressBar
var player_mana_label: Label
var player_status_label: Label
var bottom_area: VBoxContainer
var ability_buttons := {}  # ability_id -> Button


func build() -> void:
	if engine == null:
		engine = Game.run.combat
	if engine == null:
		main.show_run.call_deferred()
		return
	# Skyddsnät (även för äldre sparfiler): se till att striden står på
	# spelarens tur innan knapparna bedöms.
	if not engine.is_over() and not engine.awaiting_player:
		engine.advance_until_player_turn()
	_build_structure()
	_refresh(false)
	if engine.is_over():
		_show_end_panel()
	if Game.should_show_tutorial("combat_intro"):
		Game.mark_tutorial_seen("combat_intro")
		(
			UIKit
			. popup(
				self,
				"Combat",
				"Combat is turn-based – take all the time you need. Tap an enemy to pick a target, then tap an ability to act."
			)
		)


func _build_structure() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(UIKit.vmargin(layout, 16))

	order_label = UIKit.body("", 15)
	order_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	layout.add_child(order_label)

	var enemies_row := HBoxContainer.new()
	enemies_row.add_theme_constant_override("separation", 8)
	enemy_widgets = []
	for i in engine.enemies.size():
		var widget := _make_enemy_widget(i)
		enemies_row.add_child(widget["button"])
		enemy_widgets.append(widget)
	layout.add_child(enemies_row)

	var log_panel := UIKit.panel(Color(0, 0, 0, 0.35))
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label = UIKit.body("", 15)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(log_label)
	layout.add_child(log_panel)

	var player_panel := UIKit.panel()
	var player_box := VBoxContainer.new()
	var player_row := HBoxContainer.new()
	player_row.add_theme_constant_override("separation", 8)
	var name_label := UIKit.body(engine.player["name"], 17)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_row.add_child(name_label)
	player_status_label = UIKit.body("", 14)
	player_status_label.add_theme_color_override("font_color", UIKit.COLOR_WARN)
	player_row.add_child(player_status_label)
	player_box.add_child(player_row)
	player_hp_bar = UIKit.bar(1, 1, UIKit.COLOR_HP)
	player_box.add_child(player_hp_bar)
	player_hp_label = UIKit.body("", 14)
	player_box.add_child(player_hp_label)
	player_mana_bar = UIKit.bar(1, 1, UIKit.COLOR_MANA, 16)
	player_box.add_child(player_mana_bar)
	player_mana_label = UIKit.body("", 14)
	player_box.add_child(player_mana_label)
	player_panel.add_child(player_box)
	layout.add_child(player_panel)

	bottom_area = VBoxContainer.new()
	bottom_area.add_theme_constant_override("separation", 10)
	layout.add_child(bottom_area)
	_build_ability_grid()


func _make_enemy_widget(index: int) -> Dictionary:
	var enemy: Dictionary = engine.enemies[index]
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 132)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon_texture: Texture2D = Icons.ENEMY.get(enemy["id"], Icons.SKULL)
	var tint: Color = Icons.ENEMY_TINT.get(enemy["id"], Color.WHITE)
	var icon := Icons.image(icon_texture, 44, tint)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var name_label := UIKit.body(String(enemy["name"]), 15)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var hp_bar := UIKit.bar(int(enemy["hp"]), int(enemy["max_hp"]), UIKit.COLOR_HP, 12)
	box.add_child(hp_bar)
	var info_label := UIKit.body("", 12)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info_label)
	button.add_child(box)
	button.pressed.connect(
		func():
			selected_target = index
			_refresh(false)
	)
	return {"button": button, "name_label": name_label, "hp_bar": hp_bar, "info_label": info_label}


func _build_ability_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	ability_buttons = {}
	for id in engine.player["ability_ids"]:
		var button := UIKit.big_button("", 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = Icons.ABILITY.get(id, null)
		button.add_theme_constant_override("icon_max_width", 36)
		button.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.9))
		button.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.3))
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(func(): _use_ability(id))
		ability_buttons[id] = button
		grid.add_child(button)
	bottom_area.add_child(grid)


## Uppdaterar hela vyn mot motorns tillstånd. animate=true tweenar bars.
func _refresh(animate: bool) -> void:
	var alive := engine.living_enemies()
	if selected_target not in alive and not alive.is_empty():
		selected_target = alive[0]

	var order_names: Array = []
	for key in engine.turn_order:
		if key is String:
			order_names.append("YOU")
		elif engine.enemies[int(key)]["hp"] > 0:
			order_names.append(String(engine.enemies[int(key)]["name"]))
	order_label.text = "Round %d   Turn: %s" % [engine.round_number, " » ".join(order_names)]

	for i in enemy_widgets.size():
		var enemy: Dictionary = engine.enemies[i]
		var widget: Dictionary = enemy_widgets[i]
		var dead: bool = enemy["hp"] <= 0
		var button: Button = widget["button"]
		button.disabled = dead
		button.modulate = Color(1, 1, 1, 0.35) if dead else Color.WHITE
		var mark := "» " if i == selected_target and not dead else ""
		var phase_mark := (
			"  [PHASE 2]" if enemy.get("is_boss", false) and int(enemy.get("phase", 1)) == 2 else ""
		)
		widget["name_label"].text = "%s%s%s" % [mark, enemy["name"], phase_mark]
		_set_bar(widget["hp_bar"], int(enemy["hp"]), int(enemy["max_hp"]), animate)
		widget["info_label"].text = (
			"%d/%d  %s" % [int(enemy["hp"]), int(enemy["max_hp"]), _status_text(enemy)]
		)

	_set_bar(player_hp_bar, int(engine.player["hp"]), int(engine.player["max_hp"]), animate)
	player_hp_label.text = "HP %d/%d" % [int(engine.player["hp"]), int(engine.player["max_hp"])]
	_set_bar(player_mana_bar, int(engine.player["mana"]), int(engine.player["max_mana"]), animate)
	player_mana_label.text = (
		"Mana %d/%d" % [int(engine.player["mana"]), int(engine.player["max_mana"])]
	)
	player_status_label.text = _status_text(engine.player)

	log_label.text = "\n".join(engine.log.slice(maxi(0, engine.log.size() - 6)))

	for id in ability_buttons:
		var ability := Abilities.get_ability(id)
		var button: Button = ability_buttons[id]
		var cooldown := int(engine.player["cooldowns"].get(id, 0))
		var cost_text := (
			"  (%d)" % int(ability["mana_cost"]) if int(ability["mana_cost"]) > 0 else ""
		)
		var text: String = "%s%s" % [ability["name"], cost_text]
		if cooldown > 0:
			text += "\nrecharge: %d turns" % cooldown
		button.text = text
		button.disabled = (
			cooldown > 0
			or int(engine.player["mana"]) < int(ability["mana_cost"])
			or not engine.awaiting_player
		)


func _set_bar(bar: ProgressBar, value: int, max_value: int, animate: bool) -> void:
	bar.max_value = max_value
	if animate:
		create_tween().tween_property(bar, "value", value, 0.3).set_ease(Tween.EASE_OUT)
	else:
		bar.value = value


func _use_ability(ability_id: String) -> void:
	var player_hp_before := int(engine.player["hp"])
	var enemy_hp_before: Array = engine.enemies.map(func(e): return int(e["hp"]))
	if not engine.player_action(ability_id, selected_target):
		return
	Game.save_game()  # autosave efter varje handling (US-11.2)

	# Juice: skadesiffror, skak och blixt utifrån vad som faktiskt hände.
	for i in engine.enemies.size():
		var diff: int = int(engine.enemies[i]["hp"]) - int(enemy_hp_before[i])
		if diff < 0:
			var button: Button = enemy_widgets[i]["button"]
			_spawn_floater(button, str(diff), UIKit.COLOR_HP)
			_shake(button)
		elif diff > 0:
			_spawn_floater(enemy_widgets[i]["button"], "+%d" % diff, Color("6fdb8f"))
	var player_diff := int(engine.player["hp"]) - player_hp_before
	if player_diff < 0:
		_spawn_floater(player_hp_bar, str(player_diff), UIKit.COLOR_HP)
		modulate = Color(1.0, 0.7, 0.7)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)

	if engine.is_over():
		if engine.result == "victory":
			victory_rewards = Game.run.on_combat_victory(Game.character)
			Game.save_game()
		_show_end_panel()
	_refresh(true)


func _spawn_floater(anchor: Control, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UIKit.FONT_BOLD)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 20
	add_child(label)
	label.position = (
		anchor.global_position - global_position + Vector2(anchor.size.x * 0.5 - 18, 6)
	)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)


func _shake(node: Control) -> void:
	var origin := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", origin.x + 7, 0.04)
	tween.tween_property(node, "position:x", origin.x - 7, 0.07)
	tween.tween_property(node, "position:x", origin.x, 0.05)


func _status_text(unit: Dictionary) -> String:
	var parts: Array = []
	for status in unit["statuses"]:
		match String(status["id"]):
			"poison":
				parts.append("poison")
			"stun":
				parts.append("stunned")
			"shield":
				parts.append("shield %d" % int(status.get("amount", 0)))
			"atk_up":
				parts.append("atk+")
			"slow":
				parts.append("slow")
			"evade":
				parts.append("evade")
	return " ".join(parts)


func _show_end_panel() -> void:
	for child in bottom_area.get_children():
		child.queue_free()
	var is_victory := engine.result == "victory"
	var panel := UIKit.panel(Color("204030") if is_victory else Color("402020"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	if is_victory:
		box.add_child(UIKit.title("VICTORY", 28))
		box.add_child(
			UIKit.body(
				(
					"+%d Essence   +%d XP"
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
			var equip_button := UIKit.big_button("Equip", 64)
			equip_button.pressed.connect(
				func():
					Game.run.equip_item(Game.character, loot)
					victory_rewards["loot"] = {}
					Game.save_game()
					_show_end_panel()
			)
			box.add_child(equip_button)
		var continue_button := UIKit.primary_button("Continue", 88)
		continue_button.pressed.connect(func(): main.after_room_cleared(victory_rewards))
		box.add_child(continue_button)
		# Onboarding-popup 2/3 (US-9.1): Essens-regeln.
		if Game.should_show_tutorial("essence_intro"):
			Game.mark_tutorial_seen("essence_intro")
			var essence_hint := (
				"Essence you gather is UNBANKED until you stay at a checkpoint. "
				+ "If you die you drop everything you carry – but the pile can be reclaimed."
			)
			UIKit.popup(self, "Essence", essence_hint)
	else:
		box.add_child(UIKit.title("YOU FELL", 28))
		var death_button := UIKit.big_button("Continue", 88)
		death_button.pressed.connect(main.player_died)
		box.add_child(death_button)
	panel.add_child(box)
	bottom_area.add_child(panel)
