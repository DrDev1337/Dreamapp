extends ScreenBase
## Visas när en run avslutas lyckat – antingen via "stanna och spendera"
## vid checkpoint eller efter besegrad boss (US-6.1).


func build() -> void:
	var banked := int(data.get("banked", 0))
	var character: CharacterState = Game.character
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.spacer(60))
	layout.add_child(UIKit.title("RUN AVSLUTAD", 40))
	layout.add_child(UIKit.spacer(20))

	var panel := UIKit.panel(Color("204030"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var banked_label := UIKit.body("Säkrad Essens: +%d" % banked, 24)
	banked_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	box.add_child(banked_label)
	box.add_child(UIKit.body("Bankad Essens totalt: %d" % character.banked_essence, 18))
	box.add_child(
		UIKit.body(
			"Nivå %d   ·   Runs avklarade: %d" % [character.level, character.runs_completed], 16
		)
	)
	if character.bosses_defeated > 0:
		box.add_child(UIKit.body("Bossar besegrade: %d" % character.bosses_defeated, 16))
	panel.add_child(box)
	layout.add_child(panel)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	var hub_button := UIKit.big_button("Till hubben", 100)
	hub_button.pressed.connect(main.return_to_hub_with_ad)
	layout.add_child(hub_button)
