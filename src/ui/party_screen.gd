extends ScreenBase
## Party & Gear: inventory-hantering. Visar alla hjältars utrustning
## per slot; tryck på ett föremål för att flytta/byta det till en annan
## hjälte (samma slot – byten går alltid åt båda hållen).

const SLOTS := ["weapon", "armor", "trinket"]
const SLOT_LABELS := {"weapon": "Weapon", "armor": "Armor", "trinket": "Trinket"}


func build() -> void:
	var party: PartyState = Game.party
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.title("Party & Gear", 32))
	layout.add_child(UIKit.body("Tap an item to move it to another hero.", 15))
	layout.add_child(UIKit.divider())

	for i in party.heroes.size():
		layout.add_child(_hero_panel(party, i))

	layout.add_child(UIKit.spacer(6))
	var back_button := UIKit.big_button("Back to hub", 84)
	back_button.pressed.connect(main.show_hub)
	layout.add_child(back_button)


func _hero_panel(party: PartyState, index: int) -> Control:
	var hero: Hero = party.heroes[index]
	var panel := UIKit.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var class_label: String = LevelUp.AXIS_LABELS.get(hero.class_identity, "Recruit")
	var header := UIKit.body(
		(
			"%s – %s   ·   HP %d  Atk %d  Mag %d  Arm %d"
			% [
				hero.hero_name,
				class_label,
				hero.total_stat("max_hp", party),
				hero.total_stat("attack", party),
				hero.total_stat("magic", party),
				hero.total_stat("armor", party)
			]
		),
		15
	)
	var emblem: Texture2D = Icons.CLASS_EMBLEM.get(hero.class_identity, Icons.STAIRS)
	var tint: Color = UIKit.COLOR_ACCENT if hero.class_identity != "" else Color(1, 1, 1, 0.35)
	box.add_child(Icons.labeled(emblem, header, 24, tint))

	for slot in SLOTS:
		box.add_child(_slot_row(party, index, slot))
	panel.add_child(box)
	return panel


func _slot_row(party: PartyState, index: int, slot: String) -> Control:
	var item: Dictionary = party.heroes[index].equipment.get(slot, {})
	var button := UIKit.big_button("", 56)
	button.add_theme_font_size_override("font_size", 15)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if item.is_empty():
		button.text = "%s:  –" % SLOT_LABELS[slot]
		button.disabled = true
		button.modulate = Color(1, 1, 1, 0.6)
	else:
		button.text = "%s:  %s" % [SLOT_LABELS[slot], Items.describe(item)]
		var rarity_color: Color = UIKit.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
		button.add_theme_color_override("font_color", rarity_color)
		button.pressed.connect(func(): _open_move_menu(party, index, slot))
	return button


## Flyttmenyn: välj mottagare. Har mottagaren något i samma slot byts
## föremålen – inget försvinner någonsin.
func _open_move_menu(party: PartyState, from_index: int, slot: String) -> void:
	var item: Dictionary = party.heroes[from_index].equipment.get(slot, {})
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.z_index = 100
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := UIKit.panel(Color("2a2440"))
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(UIKit.title("Move %s" % Items.describe(item), 20))
	for i in party.heroes.size():
		if i == from_index:
			continue
		var other: Hero = party.heroes[i]
		var current: Dictionary = other.equipment.get(slot, {})
		var swap_note := (
			"  (swaps with %s)" % Items.describe(current) if not current.is_empty() else ""
		)
		var target_button := UIKit.big_button("%s%s" % [other.hero_name, swap_note], 62)
		target_button.add_theme_font_size_override("font_size", 16)
		target_button.pressed.connect(
			func():
				party.swap_equipment(from_index, i, slot)
				Game.save_game()
				dim.queue_free()
				rebuild()
		)
		box.add_child(target_button)
	var cancel_button := UIKit.big_button("Cancel", 62)
	cancel_button.pressed.connect(dim.queue_free)
	box.add_child(cancel_button)
