extends ScreenBase
## Stridsvyn för party (party_design.md). Byggs EN gång och uppdateras
## per handling: fiender överst (tryckbara mål med intentioner), logg,
## hjälteraden (aktiv hjälte markerad, fallna dimmade) och den aktiva
## hjältens förmågor längst ner. Juice: glidande HP-bars, flygande
## skadesiffror, skak och röd blixt.

var selected_target := 0
var victory_rewards := {}
# Cachad motor-referens: Game.run.combat nollas av on_combat_victory().
var engine: CombatEngine = null

# Persistenta nodreferenser.
var order_label: Label
var enemy_widgets: Array = []  # {button, name_label, hp_bar, info_label, intent_*}
var hero_widgets: Array = []  # {panel, name_label, hp_bar, mana_bar, info_label}
var log_label: Label
var turn_label: Label
var bottom_area: VBoxContainer
var ability_buttons := {}  # ability_id -> Button


func build() -> void:
	if engine == null:
		engine = Game.run.combat
	if engine == null:
		main.show_run.call_deferred()
		return
	if not engine.is_over() and not engine.awaiting_player:
		engine.advance_until_player_turn()
	_build_structure()
	_refresh(false)
	if engine.is_over():
		_show_end_panel()
	if Game.should_show_tutorial("combat_intro"):
		Game.mark_tutorial_seen("combat_intro")
		var hint := (
			"Combat is turn-based – every hero acts once per round. "
			+ "Tap an enemy to pick a target, then tap an ability. "
			+ "Melee enemies can only reach your front row."
		)
		UIKit.popup(self, "Combat", hint)


func _build_structure() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	add_child(UIKit.vmargin(layout, 14))

	order_label = UIKit.body("", 14)
	order_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	layout.add_child(order_label)

	var enemies_row := HBoxContainer.new()
	enemies_row.add_theme_constant_override("separation", 6)
	enemy_widgets = []
	for i in engine.enemies.size():
		var widget := _make_enemy_widget(i)
		enemies_row.add_child(widget["button"])
		enemy_widgets.append(widget)
	layout.add_child(enemies_row)

	var log_panel := UIKit.panel(Color(0, 0, 0, 0.35))
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label = UIKit.body("", 14)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(log_label)
	layout.add_child(log_panel)

	var heroes_row := HBoxContainer.new()
	heroes_row.add_theme_constant_override("separation", 5)
	hero_widgets = []
	for i in engine.heroes.size():
		var widget := _make_hero_widget(i)
		heroes_row.add_child(widget["panel"])
		hero_widgets.append(widget)
	layout.add_child(heroes_row)

	turn_label = UIKit.body("", 17)
	turn_label.add_theme_color_override("font_color", UIKit.COLOR_ACCENT)
	layout.add_child(turn_label)

	bottom_area = VBoxContainer.new()
	bottom_area.add_theme_constant_override("separation", 8)
	layout.add_child(bottom_area)
	_build_ability_grid()


func _make_enemy_widget(index: int) -> Dictionary:
	var enemy: Dictionary = engine.enemies[index]
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 138)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	# Intentionen (US-3.4): "ikon ovanför fienden visar nästa handling".
	var intent_row := HBoxContainer.new()
	intent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	intent_row.add_theme_constant_override("separation", 4)
	var intent_icon := Icons.image(Icons.INTENT["attack"], 16)
	intent_row.add_child(intent_icon)
	var intent_label := UIKit.body("", 11)
	intent_row.add_child(intent_label)
	box.add_child(intent_row)
	var icon_texture: Texture2D = Icons.ENEMY.get(enemy["id"], Icons.SKULL)
	var tint: Color = Icons.ENEMY_TINT.get(enemy["id"], Color.WHITE)
	var icon := Icons.image(icon_texture, 38, tint)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var name_label := UIKit.body(String(enemy["name"]), 13)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var hp_bar := UIKit.bar(int(enemy["hp"]), int(enemy["max_hp"]), UIKit.COLOR_HP, 10)
	box.add_child(hp_bar)
	var info_label := UIKit.body("", 11)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info_label)
	button.add_child(box)
	button.pressed.connect(
		func():
			selected_target = index
			_refresh(false)
	)
	return {
		"button": button,
		"name_label": name_label,
		"hp_bar": hp_bar,
		"info_label": info_label,
		"intent_row": intent_row,
		"intent_icon": intent_icon,
		"intent_label": intent_label,
	}


func _make_hero_widget(index: int) -> Dictionary:
	var hero: Dictionary = engine.heroes[index]
	var panel := UIKit.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var name_label := UIKit.body(String(hero["name"]), 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var hp_bar := UIKit.bar(int(hero["hp"]), int(hero["max_hp"]), UIKit.COLOR_HP, 8)
	box.add_child(hp_bar)
	var mana_bar := UIKit.bar(int(hero["mana"]), int(hero["max_mana"]), UIKit.COLOR_MANA, 5)
	box.add_child(mana_bar)
	var info_label := UIKit.body("", 10)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info_label)
	panel.add_child(box)
	return {
		"panel": panel,
		"name_label": name_label,
		"hp_bar": hp_bar,
		"mana_bar": mana_bar,
		"info_label": info_label,
	}


func _build_ability_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	ability_buttons = {}
	# Bygg knappar för unionen av alla hjältars förmågor; per tur visas
	# bara den aktiva hjältens (resten göms i _refresh).
	var all_ids: Array = []
	for hero in engine.heroes:
		for id in hero["ability_ids"]:
			if id not in all_ids:
				all_ids.append(id)
	for id in all_ids:
		var button := UIKit.big_button("", 84)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = Icons.ABILITY.get(id, null)
		button.add_theme_constant_override("icon_max_width", 32)
		button.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.9))
		button.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.3))
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(func(): _use_ability(id))
		ability_buttons[id] = button
		grid.add_child(button)
	bottom_area.add_child(grid)


## Uppdaterar hela vyn mot motorns tillstånd. animate=true tweenar bars.
func _refresh(animate: bool) -> void:
	var alive := engine.living_enemies()
	if selected_target not in alive and not alive.is_empty():
		selected_target = alive[0]

	order_label.text = "Round %d" % engine.round_number

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
			"%d/%d %s" % [int(enemy["hp"]), int(enemy["max_hp"]), _status_text(enemy)]
		)
		var intent: Dictionary = enemy.get("intent", {})
		var intent_kind := String(intent.get("kind", ""))
		var show_intent := intent_kind != "" and not dead and not engine.is_over()
		widget["intent_row"].visible = show_intent
		if show_intent:
			var tint: Color = Icons.INTENT_TINT.get(intent_kind, Color.WHITE)
			widget["intent_icon"].texture = Icons.INTENT.get(intent_kind, Icons.INTENT["attack"])
			widget["intent_icon"].modulate = tint
			widget["intent_label"].text = String(intent.get("label", ""))
			widget["intent_label"].add_theme_color_override("font_color", tint)

	for i in hero_widgets.size():
		var hero: Dictionary = engine.heroes[i]
		var widget: Dictionary = hero_widgets[i]
		var down: bool = hero["hp"] <= 0
		var is_active: bool = i == engine.active_hero
		widget["panel"].modulate = Color(1, 1, 1, 0.35) if down else Color.WHITE
		widget["name_label"].text = ("» " if is_active else "") + String(hero["name"])
		widget["name_label"].add_theme_color_override(
			"font_color", UIKit.COLOR_ACCENT if is_active else Color("e8e4f0")
		)
		_set_bar(widget["hp_bar"], int(hero["hp"]), int(hero["max_hp"]), animate)
		_set_bar(widget["mana_bar"], int(hero["mana"]), int(hero["max_mana"]), animate)
		var row_tag := "F" if String(hero.get("row", "back")) == "front" else "B"
		widget["info_label"].text = (
			"DOWN"
			if down
			else "%s %d/%d %s" % [row_tag, int(hero["hp"]), int(hero["max_hp"]), _status_text(hero)]
		)

	log_label.text = "\n".join(engine.log.slice(maxi(0, engine.log.size() - 5)))

	var active := engine.active_hero
	if active >= 0 and not engine.is_over():
		turn_label.text = "%s's turn" % engine.heroes[active]["name"]
	else:
		turn_label.text = ""

	for id in ability_buttons:
		var button: Button = ability_buttons[id]
		if active < 0 or engine.is_over():
			button.visible = false
			continue
		var hero: Dictionary = engine.heroes[active]
		if id not in hero["ability_ids"]:
			button.visible = false
			continue
		button.visible = true
		var ability := Abilities.get_ability(id)
		var cooldown := int(hero["cooldowns"].get(id, 0))
		var cost_text := (
			"  (%d)" % int(ability["mana_cost"]) if int(ability["mana_cost"]) > 0 else ""
		)
		var text: String = "%s%s" % [ability["name"], cost_text]
		if cooldown > 0:
			text += "\nrecharge: %d turns" % cooldown
		button.text = text
		var unusable := (
			cooldown > 0
			or int(hero["mana"]) < int(ability["mana_cost"])
			or not engine.awaiting_player
		)
		if String(ability["kind"]) == "revive" and engine.downed_heroes().is_empty():
			unusable = true
		button.disabled = unusable


func _set_bar(bar: ProgressBar, value: int, max_value: int, animate: bool) -> void:
	bar.max_value = max_value
	if animate:
		create_tween().tween_property(bar, "value", value, 0.3).set_ease(Tween.EASE_OUT)
	else:
		bar.value = value


func _use_ability(ability_id: String) -> void:
	var hero_hp_before: Array = engine.heroes.map(func(h): return int(h["hp"]))
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
	var party_hurt := false
	for i in engine.heroes.size():
		var diff: int = int(engine.heroes[i]["hp"]) - int(hero_hp_before[i])
		if diff < 0:
			_spawn_floater(hero_widgets[i]["panel"], str(diff), UIKit.COLOR_HP)
			_shake(hero_widgets[i]["panel"])
			party_hurt = true
		elif diff > 0:
			_spawn_floater(hero_widgets[i]["panel"], "+%d" % diff, Color("6fdb8f"))
	if party_hurt:
		modulate = Color(1.0, 0.75, 0.75)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)

	if engine.is_over():
		if engine.result == "victory":
			victory_rewards = Game.run.on_combat_victory(Game.party)
			Game.save_game()
		_show_end_panel()
	_refresh(true)


func _spawn_floater(anchor: Control, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UIKit.FONT_BOLD)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 20
	add_child(label)
	label.position = anchor.global_position - global_position + Vector2(anchor.size.x * 0.5 - 16, 4)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)


func _shake(node: Control) -> void:
	var origin := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", origin.x + 6, 0.04)
	tween.tween_property(node, "position:x", origin.x - 6, 0.07)
	tween.tween_property(node, "position:x", origin.x, 0.05)


func _status_text(unit: Dictionary) -> String:
	var parts: Array = []
	for status in unit["statuses"]:
		match String(status["id"]):
			"poison":
				parts.append("psn")
			"stun":
				parts.append("stun")
			"shield":
				parts.append("shld%d" % int(status.get("amount", 0)))
			"atk_up":
				parts.append("atk+")
			"slow":
				parts.append("slow")
			"evade":
				parts.append("evd")
			"taunt":
				parts.append("tnt")
	return " ".join(parts)


func _show_end_panel() -> void:
	for child in bottom_area.get_children():
		child.queue_free()
	turn_label.text = ""
	var is_victory := engine.result == "victory"
	var panel := UIKit.panel(Color("204030") if is_victory else Color("402020"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	if is_victory:
		box.add_child(UIKit.title("VICTORY", 26))
		box.add_child(
			UIKit.body(
				(
					"+%d Essence   +%d XP"
					% [int(victory_rewards.get("essence", 0)), int(victory_rewards.get("xp", 0))]
				),
				18
			)
		)
		var loot: Dictionary = victory_rewards.get("loot", {})
		if not loot.is_empty():
			var hero_index: int = Game.run.best_hero_for_item(Game.party, loot)
			var hero: Hero = Game.party.heroes[hero_index]
			var loot_label := UIKit.body("Loot: %s" % Items.describe(loot), 16)
			loot_label.add_theme_color_override(
				"font_color", UIKit.RARITY_COLORS.get(loot.get("rarity", "common"), Color.WHITE)
			)
			box.add_child(loot_label)
			var equip_button := UIKit.big_button("Equip on %s" % hero.hero_name, 60)
			equip_button.pressed.connect(
				func():
					Game.run.equip_item(Game.party, loot, hero_index)
					victory_rewards["loot"] = {}
					Game.save_game()
					_show_end_panel()
			)
			box.add_child(equip_button)
		var continue_button := UIKit.primary_button("Continue", 84)
		continue_button.pressed.connect(func(): main.after_room_cleared(victory_rewards))
		box.add_child(continue_button)
		# Onboarding-popup 2/3 (US-9.1): Essens-regeln.
		if Game.should_show_tutorial("essence_intro"):
			Game.mark_tutorial_seen("essence_intro")
			var essence_hint := (
				"Essence you gather is UNBANKED until you stay at a checkpoint. "
				+ "If the whole party falls you drop everything you carry – "
				+ "but the pile can be reclaimed."
			)
			UIKit.popup(self, "Essence", essence_hint)
	else:
		box.add_child(UIKit.title("THE PARTY FELL", 26))
		var death_button := UIKit.big_button("Continue", 84)
		death_button.pressed.connect(main.player_died)
		box.add_child(death_button)
	panel.add_child(box)
	bottom_area.add_child(panel)
