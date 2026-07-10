extends ScreenBase
## Run-vyn (US-1.2): visar rummen, djupet, buren Essens och var din
## dödshög ligger. Härifrån går man vidare nedåt.


func build() -> void:
	var run: RunState = Game.run
	var character: CharacterState = Game.character
	var event: Dictionary = data.get("event", {})
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.title("Djup %d / %d" % [run.current_depth, run.rooms.size()], 30))

	var essence_label := UIKit.body("Buren Essens: %d  (osäkrad!)" % run.carried_essence, 22)
	essence_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	layout.add_child(essence_label)

	var hp_label := UIKit.body(
		(
			"HP %d/%d   Mana %d/%d"
			% [
				int(run.player_combat["hp"]),
				int(run.player_combat["max_hp"]),
				int(run.player_combat["mana"]),
				int(run.player_combat["max_mana"])
			]
		),
		18
	)
	layout.add_child(hp_label)

	# Kartan: en rad per rum (US-7.1). ☠ markerar dödshögen (US-2.4).
	var map_panel := UIKit.panel()
	var map_box := VBoxContainer.new()
	for room in run.rooms:
		var depth := int(room["depth"])
		var marker := (
			"▶ "
			if depth == run.current_depth + 1
			else ("✓ " if depth <= run.current_depth else "   ")
		)
		var pile_mark := (
			"  ☠ din Essens!" if room.get("has_pile", false) and character.has_death_pile() else ""
		)
		var checkpoint_mark := "  ⛨ checkpoint efter" if room.get("checkpoint_after", false) else ""
		var lock_mark := ""
		if character.level < Balance.required_level_for_depth(depth):
			lock_mark = "  🔒 nivå %d" % Balance.required_level_for_depth(depth)
		var row := UIKit.body(
			(
				"%sDjup %d – %s%s%s%s"
				% [
					marker,
					depth,
					RunGenerator.room_label(room),
					pile_mark,
					checkpoint_mark,
					lock_mark
				]
			),
			17
		)
		if depth <= run.current_depth:
			row.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
		map_box.add_child(row)
	map_panel.add_child(map_box)
	layout.add_child(map_panel)

	# Händelser från senaste rummet (kista, upphämtad hög).
	if int(event.get("recovered_essence", 0)) > 0:
		var recovered := UIKit.panel(Color("204030"))
		recovered.add_child(
			UIKit.body(
				"☠→✓ Du hämtar din tappade Essens: +%d!" % int(event["recovered_essence"]), 19
			)
		)
		layout.add_child(recovered)
	var chest_item: Dictionary = event.get("chest_item", {})
	if not chest_item.is_empty():
		layout.add_child(_chest_offer(chest_item))

	layout.add_child(UIKit.spacer(4))
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	if run.is_run_complete():
		var done_button := UIKit.big_button("Runnen är klar – till hubben", 100)
		done_button.pressed.connect(
			func():
				var banked := Game.complete_run()
				main.show_victory(banked)
		)
		layout.add_child(done_button)
	else:
		var next_room: Dictionary = run.rooms[run.current_depth]
		var descend_button := UIKit.big_button(
			(
				"⬇  Gå vidare – Djup %d: %s"
				% [int(next_room["depth"]), RunGenerator.room_label(next_room)]
			),
			100
		)
		descend_button.pressed.connect(main.descend)
		layout.add_child(descend_button)


func _chest_offer(item: Dictionary) -> Control:
	var panel := UIKit.panel(Color("2a2440"))
	var box := VBoxContainer.new()
	var name_label := UIKit.body("Kista! Du hittar: %s" % Items.describe(item), 19)
	name_label.add_theme_color_override(
		"font_color", UIKit.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	)
	box.add_child(name_label)
	var current: Dictionary = Game.character.equipment.get(item["slot"], {})
	if not current.is_empty():
		box.add_child(UIKit.body("Nuvarande: %s" % Items.describe(current), 16))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	var equip_button := UIKit.big_button("Utrusta", 70)
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_button.pressed.connect(
		func():
			Game.run.equip_item(Game.character, item)
			Game.save_game()
			main.show_run()
	)
	var skip_button := UIKit.big_button("Lämna", 70)
	skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_button.pressed.connect(func(): main.show_run())
	buttons.add_child(equip_button)
	buttons.add_child(skip_button)
	box.add_child(buttons)
	panel.add_child(box)
	return panel
