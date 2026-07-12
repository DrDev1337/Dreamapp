extends ScreenBase
## Visas när en run avslutas lyckat – antingen via "stanna och spendera"
## vid checkpoint eller efter besegrad boss (US-6.1).


func build() -> void:
	var banked := int(data.get("banked", 0))
	var party: PartyState = Game.party
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.spacer(50))
	var crystal := Icons.image(Icons.ESSENCE, 80, UIKit.COLOR_ESSENCE)
	crystal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(crystal)
	layout.add_child(UIKit.title("RUN COMPLETE", 40))
	layout.add_child(UIKit.spacer(20))

	var panel := UIKit.panel(Color("204030"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var banked_label := UIKit.body("Essence banked: +%d" % banked, 24)
	banked_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	box.add_child(banked_label)
	box.add_child(UIKit.body("Total banked Essence: %d" % party.banked_essence, 18))
	box.add_child(
		UIKit.body("Level %d   ·   Runs completed: %d" % [party.level, party.runs_completed], 16)
	)
	if party.bosses_defeated > 0:
		box.add_child(UIKit.body("Bosses defeated: %d" % party.bosses_defeated, 16))
	panel.add_child(box)
	layout.add_child(panel)

	# Progression: berätta när en ny dungeon just blivit nåbar.
	for id in Dungeons.ORDER:
		if party.clears_of(id) == 0 and Dungeons.is_unlocked(party, id):
			var unlock_panel := UIKit.panel(Color("2a2440"))
			var unlock_label := UIKit.body(
				"A deeper place calls: %s is open." % Dungeons.get_dungeon(id)["name"], 17
			)
			unlock_label.add_theme_color_override("font_color", UIKit.COLOR_ACCENT)
			unlock_panel.add_child(unlock_label)
			layout.add_child(unlock_panel)
			break

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	var hub_button := UIKit.big_button("Return to hub", 100)
	hub_button.pressed.connect(main.return_to_hub_with_ad)
	layout.add_child(hub_button)
