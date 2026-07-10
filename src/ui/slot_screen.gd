extends ScreenBase
## Karaktärsval (US-4.4): 3 slots, skapa nya karaktärer, börja från noll.
## Namn väljs via slumpknapp i stället för textfält – mobilwebben öppnar
## inte tangentbordet pålitligt, och en roguelite behöver inget fritext.

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
var suggested_name := ""


func build() -> void:
	if creating_slot >= 0:
		_build_name_picker()
	else:
		_build_slot_list()


func _build_slot_list() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))
	layout.add_child(UIKit.spacer(40))
	layout.add_child(UIKit.title("ESSENS", 52))
	var tagline := UIKit.body("Samla Essens. Riskera allt. Gå djupare.", 18)
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
		button = UIKit.big_button("+  Skapa karaktär", 96)
		button.pressed.connect(func(): _start_creating(slot))
	else:
		var class_label: String = LevelUp.AXIS_LABELS.get(summary["class_identity"], "Oklassad")
		var suffix := "\n– pågående run" if summary["has_active_run"] else ""
		button = UIKit.big_button(
			"%s  –  Nivå %d %s%s" % [summary["name"], summary["level"], class_label, suffix], 96
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


func _build_name_picker() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))
	layout.add_child(UIKit.spacer(60))
	layout.add_child(UIKit.title("Ny karaktär", 38))
	layout.add_child(UIKit.spacer(10))

	var name_panel := UIKit.panel()
	var name_label := UIKit.title(suggested_name, 44)
	name_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	name_panel.add_child(name_label)
	layout.add_child(name_panel)

	var reroll_button := UIKit.big_button("Slumpa nytt namn", 88)
	reroll_button.pressed.connect(
		func():
			_roll_name()
			rebuild()
	)
	layout.add_child(reroll_button)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	var create_button := UIKit.primary_button("Börja som %s" % suggested_name, 104)
	create_button.pressed.connect(
		func():
			Game.create_character(creating_slot, suggested_name)
			main.show_hub()
	)
	layout.add_child(create_button)

	var cancel_button := UIKit.big_button("Avbryt", 72)
	cancel_button.pressed.connect(
		func():
			creating_slot = -1
			rebuild()
	)
	layout.add_child(cancel_button)


func _start_creating(slot: int) -> void:
	creating_slot = slot
	_roll_name()
	rebuild()


func _roll_name() -> void:
	var previous := suggested_name
	while suggested_name == previous:
		suggested_name = NAMES[randi_range(0, NAMES.size() - 1)]


func _select(slot: int) -> void:
	if Game.select_slot(slot):
		main.resume_or_hub()


func _confirm_delete(slot: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Radera karaktär?"
	dialog.dialog_text = "All progression för karaktären försvinner permanent."
	dialog.ok_button_text = "Radera"
	dialog.cancel_button_text = "Avbryt"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(
		func():
			Game.delete_slot(slot)
			rebuild()
	)
