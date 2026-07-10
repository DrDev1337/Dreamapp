extends ScreenBase
## Hubben (US-8.1): karaktärsvy, uppgraderingar och run-start.
## US-1.1: "Starta run" nås med max 2 tryck från appstart
## (välj karaktär -> starta run).


func build() -> void:
	var character: CharacterState = Game.character
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	add_child(UIKit.vmargin(layout))

	var class_label: String = LevelUp.AXIS_LABELS.get(character.class_identity, "Oklassad")
	layout.add_child(UIKit.title("%s" % character.character_name, 38))
	layout.add_child(
		UIKit.body(
			(
				"Nivå %d %s   ·   XP %d/%d"
				% [character.level, class_label, character.xp, character.xp_to_next()]
			),
			18
		)
	)

	var essence_panel := UIKit.panel()
	var essence_label := UIKit.body("Bankad Essens: %d" % character.banked_essence, 24)
	essence_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	essence_panel.add_child(essence_label)
	layout.add_child(essence_panel)

	# US-2.4: tydlig indikator på var din tappade Essens ligger.
	if character.has_death_pile():
		var pile: Dictionary = character.death_pile
		var pile_panel := UIKit.panel(Color("3a2a20"))
		var pile_label := (
			UIKit
			. body(
				(
					"Din tappade Essens (%d) ligger på djup %d.\nNå dit i nästa run för att hämta den – dör du igen försvinner den!"
					% [int(pile.get("essence", 0)), int(pile.get("depth", 1))]
				),
				17
			)
		)
		pile_label.add_theme_color_override("font_color", UIKit.COLOR_WARN)
		pile_panel.add_child(pile_label)
		layout.add_child(pile_panel)

	# Statvy + utrustning (US-8.1: karaktärsvy).
	var stats_panel := UIKit.panel()
	var stats_box := VBoxContainer.new()
	stats_box.add_child(
		UIKit.body(
			(
				"HP %d   Attack %d   Magi %d   Fart %d   Rustning %d   Mana %d"
				% [
					character.total_stat("max_hp"),
					character.total_stat("attack"),
					character.total_stat("magic"),
					character.total_stat("speed"),
					character.total_stat("armor"),
					character.total_stat("max_mana")
				]
			),
			17
		)
	)
	for slot in ["weapon", "armor", "trinket"]:
		stats_box.add_child(
			UIKit.body(
				"%s: %s" % [_slot_label(slot), Items.describe(character.equipment.get(slot, {}))],
				16
			)
		)
	if not character.pending_boosts.is_empty():
		stats_box.add_child(
			UIKit.body("Boosts inför nästa run: %d st" % character.pending_boosts.size(), 16)
		)
	stats_panel.add_child(stats_box)
	layout.add_child(stats_panel)

	layout.add_child(UIKit.spacer(8))
	var start_button := UIKit.primary_button("STARTA RUN", 110)
	start_button.pressed.connect(main.begin_run)
	layout.add_child(start_button)

	var shop_button := UIKit.big_button("Uppgraderingar")
	shop_button.pressed.connect(func(): main.show_shop("hub"))
	layout.add_child(shop_button)

	var switch_button := UIKit.big_button("Byt karaktär", 64)
	switch_button.pressed.connect(main.show_slots)
	layout.add_child(switch_button)

	# US-10.2: engångsköp för ad-free, synligt i hubben.
	if not Game.ads_removed:
		var iap_button := UIKit.big_button("Ta bort reklam – 49 kr (engångsköp)", 64)
		iap_button.pressed.connect(
			func():
				Ads.purchase_remove_ads()
				rebuild()
		)
		layout.add_child(iap_button)


func _slot_label(slot: String) -> String:
	match slot:
		"weapon":
			return "Vapen"
		"armor":
			return "Rustning"
		"trinket":
			return "Smycke"
	return slot
