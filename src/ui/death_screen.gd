extends ScreenBase
## Dödsskärmen (US-2.3): visar vad som tappades och var högen ligger.
## Lär ut corpse-run-mekaniken kontextuellt i stället för via popup.


func build() -> void:
	var summary: Dictionary = data.get("summary", {})
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.spacer(50))
	var skull := Icons.image(Icons.SKULL, 80, Color("d8b0b0"))
	skull.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(skull)
	layout.add_child(UIKit.title("YOU FELL", 44))
	layout.add_child(UIKit.body("The depths claimed their due.", 18))
	layout.add_child(UIKit.spacer(20))

	var panel := UIKit.panel(Color("402020"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(UIKit.body("Essence lost: %d" % int(summary.get("lost_essence", 0)), 22))
	if int(summary.get("lost_items", 0)) > 0:
		box.add_child(UIKit.body("Loot lost: %d items" % int(summary.get("lost_items", 0)), 18))
	box.add_child(
		UIKit.body(
			(
				"It all remains at depth %d. Reach it next run to take it back."
				% int(summary.get("depth", 1))
			),
			17
		)
	)
	if summary.get("replaced_old_pile", false):
		var warn := UIKit.body("Warning! Your previous unclaimed pile is lost forever.", 17)
		warn.add_theme_color_override("font_color", UIKit.COLOR_WARN)
		box.add_child(warn)
	box.add_child(UIKit.body("Your permanent upgrades and levels remain.", 16))
	panel.add_child(box)
	layout.add_child(panel)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	var hub_button := UIKit.big_button("Return to hub", 100)
	hub_button.pressed.connect(main.return_to_hub_with_ad)
	layout.add_child(hub_button)
