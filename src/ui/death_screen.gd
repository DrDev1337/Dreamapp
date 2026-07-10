extends ScreenBase
## Dödsskärmen (US-2.3): visar vad som tappades och var högen ligger.
## Lär ut corpse-run-mekaniken kontextuellt i stället för via popup.


func build() -> void:
	var summary: Dictionary = data.get("summary", {})
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.spacer(60))
	layout.add_child(UIKit.title("DU FÖLL", 44))
	layout.add_child(UIKit.body("Djupet krävde sitt.", 18))
	layout.add_child(UIKit.spacer(20))

	var panel := UIKit.panel(Color("402020"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(UIKit.body("Tappad Essens: %d" % int(summary.get("lost_essence", 0)), 22))
	if int(summary.get("lost_items", 0)) > 0:
		box.add_child(UIKit.body("Tappad loot: %d föremål" % int(summary.get("lost_items", 0)), 18))
	box.add_child(
		UIKit.body(
			(
				"Allt ligger kvar på djup %d. Nå dit i nästa run för att hämta tillbaka det."
				% int(summary.get("depth", 1))
			),
			17
		)
	)
	if summary.get("replaced_old_pile", false):
		var warn := UIKit.body("OBS! Din tidigare obärgade hög gick förlorad för alltid.", 17)
		warn.add_theme_color_override("font_color", UIKit.COLOR_WARN)
		box.add_child(warn)
	box.add_child(UIKit.body("Dina permanenta uppgraderingar och nivåer är kvar.", 16))
	panel.add_child(box)
	layout.add_child(panel)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	var hub_button := UIKit.big_button("Till hubben", 100)
	hub_button.pressed.connect(main.return_to_hub_with_ad)
	layout.add_child(hub_button)
