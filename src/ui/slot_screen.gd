extends ScreenBase
## Party-val (US-4.4): 3 slots. Ett nytt party är fem slumpade rekryter –
## namnen rullas fram, inget tangentbord behövs på mobilwebben.

const NAMES := [
	"Ask",
	"Embla",
	"Torvald",
	"Sigrid",
	"Runa",
	"Kettil",
	"Ylva",
	"Alvar",
	"Estrid",
	"Botvid",
	"Grim",
	"Hulda",
	"Ingvar",
	"Saga",
	"Rurik",
	"Tova",
	"Vidar",
	"Frida",
	"Halvar",
	"Liv",
	"Orm",
	"Signe",
	"Sten",
	"Freja",
]

var creating_slot := -1
var suggested_specs: Array = []  # [{name, ability_id, axis}, ...]


func build() -> void:
	if creating_slot >= 0:
		_build_party_picker()
	else:
		_build_slot_list()


func _build_slot_list() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))
	layout.add_child(UIKit.spacer(40))
	var crystal := Icons.image(Icons.ESSENCE, 72, UIKit.COLOR_ESSENCE)
	crystal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(crystal)
	var game_title := UIKit.title("ESSENCE", 56)
	game_title.add_theme_color_override("font_color", Color("cfc4f5"))
	game_title.add_theme_color_override(
		"font_shadow_color",
		Color(UIKit.COLOR_ACCENT.r, UIKit.COLOR_ACCENT.g, UIKit.COLOR_ACCENT.b, 0.55)
	)
	layout.add_child(game_title)
	layout.add_child(UIKit.divider())
	var tagline := UIKit.body("Lead five nobodies into the depths.", 18)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	layout.add_child(tagline)
	layout.add_child(UIKit.spacer(30))
	for slot in Balance.CHARACTER_SLOTS:
		layout.add_child(_slot_row(slot))


func _slot_row(slot: int) -> Control:
	var summary := Game.slot_summary(slot)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var button: Button
	if summary.is_empty():
		button = UIKit.big_button("+  New party", 96)
		button.pressed.connect(func(): _start_creating(slot))
	else:
		var suffix := "\n– run in progress" if summary["has_active_run"] else ""
		button = UIKit.big_button(
			(
				"%s's party  –  Level %d, %d/%d classed%s"
				% [
					summary["name"],
					summary["level"],
					summary["classed_heroes"],
					summary["hero_count"],
					suffix
				]
			),
			96
		)
		button.pressed.connect(func(): _select(slot))
		var delete_button := UIKit.big_button("X", 96)
		delete_button.custom_minimum_size = Vector2(88, 96)
		delete_button.pressed.connect(func(): _confirm_delete(slot))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		row.add_child(delete_button)
		return row
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(button)
	return row


func _build_party_picker() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	add_child(UIKit.vmargin(layout))
	layout.add_child(UIKit.spacer(40))
	layout.add_child(UIKit.title("New party", 38))
	layout.add_child(
		UIKit.body("Five level 1 recruits, each with one starting talent to build on.", 16)
	)
	layout.add_child(UIKit.spacer(6))

	var name_panel := UIKit.panel()
	var name_box := VBoxContainer.new()
	name_box.add_theme_constant_override("separation", 8)
	for i in suggested_specs.size():
		var spec: Dictionary = suggested_specs[i]
		var ability := Abilities.get_ability(String(spec["ability_id"]))
		var row_label := UIKit.body(
			"%d. %s%s" % [i + 1, spec["name"], "   (front row)" if i < 2 else ""], 20
		)
		var talent_label := UIKit.body(
			"      knows %s – %s" % [ability["name"], ability["desc"]], 13
		)
		talent_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
		name_box.add_child(row_label)
		name_box.add_child(talent_label)
	name_panel.add_child(name_box)
	layout.add_child(name_panel)

	var reroll_button := UIKit.big_button("Reroll party", 80)
	reroll_button.pressed.connect(
		func():
			_roll_names()
			rebuild()
	)
	layout.add_child(reroll_button)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	var create_button := UIKit.primary_button("Begin the descent", 104)
	create_button.pressed.connect(
		func():
			Game.create_party(creating_slot, suggested_specs)
			main.show_hub()
	)
	layout.add_child(create_button)

	var cancel_button := UIKit.big_button("Cancel", 72)
	cancel_button.pressed.connect(
		func():
			creating_slot = -1
			rebuild()
	)
	layout.add_child(cancel_button)


func _start_creating(slot: int) -> void:
	creating_slot = slot
	_roll_names()
	rebuild()


## Rullar namn + en startförmåga per rekryt: de fyra axlarna täcks
## alltid, femte hjälten får en slumpad axel. Reroll ger nya kombon.
func _roll_names() -> void:
	var pool := NAMES.duplicate()
	pool.shuffle()
	var axes: Array = Abilities.AXES.duplicate()
	axes.append(Abilities.AXES[randi_range(0, Abilities.AXES.size() - 1)])
	axes.shuffle()
	suggested_specs = []
	for i in Balance.PARTY_SIZE:
		var axis: String = axes[i]
		var options := Abilities.abilities_for_axis(axis)
		(
			suggested_specs
			. append(
				{
					"name": pool[i],
					"axis": axis,
					"ability_id": options[randi_range(0, options.size() - 1)],
				}
			)
		)


func _select(slot: int) -> void:
	if Game.select_slot(slot):
		main.resume_or_hub()


func _confirm_delete(slot: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete party?"
	dialog.dialog_text = "All progress for this party will be lost permanently."
	dialog.ok_button_text = "Delete"
	dialog.cancel_button_text = "Cancel"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(
		func():
			Game.delete_slot(slot)
			rebuild()
	)
