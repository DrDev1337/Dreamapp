extends ScreenBase
## Karaktärsval (US-4.4): 3 slots, skapa nya karaktärer, börja från noll.


func build() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))
	layout.add_child(UIKit.spacer(40))
	layout.add_child(UIKit.title("ESSENS", 52))
	layout.add_child(UIKit.body("Samla Essens. Riskera allt. Gå djupare.", 18))
	layout.add_child(UIKit.spacer(30))
	for slot in Balance.CHARACTER_SLOTS:
		layout.add_child(_slot_row(slot))


func _slot_row(slot: int) -> Control:
	var summary := Game.slot_summary(slot)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var button: Button
	if summary.is_empty():
		button = UIKit.big_button("Tom plats – skapa karaktär")
		button.pressed.connect(func(): _prompt_new_character(slot))
	else:
		var class_label: String = LevelUp.AXIS_LABELS.get(summary["class_identity"], "Oklassad")
		var suffix := "  ⚔ pågående run" if summary["has_active_run"] else ""
		button = UIKit.big_button(
			"%s  –  Nivå %d %s%s" % [summary["name"], summary["level"], class_label, suffix]
		)
		button.pressed.connect(func(): _select(slot))
		var delete_button := UIKit.big_button("✕")
		delete_button.custom_minimum_size = Vector2(88, 88)
		delete_button.pressed.connect(func(): _confirm_delete(slot))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		row.add_child(delete_button)
		return row
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(button)
	return row


func _select(slot: int) -> void:
	if Game.select_slot(slot):
		main.resume_or_hub()


func _prompt_new_character(slot: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Ny karaktär"
	dialog.ok_button_text = "Skapa"
	dialog.cancel_button_text = "Avbryt"
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Namn"
	name_edit.max_length = 16
	dialog.add_child(name_edit)
	dialog.register_text_enter(name_edit)
	add_child(dialog)
	dialog.popup_centered(Vector2i(480, 160))
	dialog.confirmed.connect(
		func():
			var new_name := name_edit.text.strip_edges()
			if new_name == "":
				new_name = "Vandrare"
			Game.create_character(slot, new_name)
			main.show_hub()
	)


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
