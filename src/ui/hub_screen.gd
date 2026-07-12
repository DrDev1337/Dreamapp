extends ScreenBase
## Hubben (US-8.1): roster, dungeonval, uppgraderingar och run-start.
## US-1.1: "Start run" nås med max 2 tryck från appstart.

var selected_dungeon := ""


func build() -> void:
	var party: PartyState = Game.party
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.title("%s's party" % party.party_name, 34))
	layout.add_child(UIKit.divider())
	layout.add_child(
		UIKit.body(
			"Party level %d   ·   XP %d/%d" % [party.level, party.xp, party.xp_to_next()], 17
		)
	)

	var essence_panel := UIKit.panel()
	var essence_label := UIKit.body("Banked Essence: %d" % party.banked_essence, 22)
	essence_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	essence_panel.add_child(Icons.labeled(Icons.ESSENCE, essence_label, 30, UIKit.COLOR_ESSENCE))
	layout.add_child(essence_panel)

	# US-2.4: tydlig indikator på var den tappade Essensen ligger.
	if party.has_death_pile():
		var pile: Dictionary = party.death_pile
		var pile_panel := UIKit.panel(Color("3a2a20"))
		var pile_label := UIKit.body(
			(
				"Your lost Essence (%d) lies at depth %d in %s. Reach it to reclaim it!"
				% [
					int(pile.get("essence", 0)),
					int(pile.get("depth", 1)),
					Dungeons.get_dungeon(String(pile.get("dungeon_id", Dungeons.DEFAULT)))["name"]
				]
			),
			15
		)
		pile_label.add_theme_color_override("font_color", UIKit.COLOR_WARN)
		pile_panel.add_child(Icons.labeled(Icons.SKULL, pile_label, 28, UIKit.COLOR_WARN))
		layout.add_child(pile_panel)

	# Rostern: en rad per hjälte.
	var roster_panel := UIKit.panel()
	var roster_box := VBoxContainer.new()
	roster_box.add_theme_constant_override("separation", 6)
	for i in party.heroes.size():
		roster_box.add_child(_hero_row(party, i))
	roster_panel.add_child(roster_box)
	layout.add_child(roster_panel)

	# Dungeonval: nya, svårare dungeons låses upp av boss-kills.
	if selected_dungeon == "" or not Dungeons.is_unlocked(party, selected_dungeon):
		selected_dungeon = Dungeons.highest_unlocked(party)
	var dungeon_panel := UIKit.panel()
	var dungeon_box := VBoxContainer.new()
	dungeon_box.add_theme_constant_override("separation", 6)
	for id in Dungeons.ORDER:
		dungeon_box.add_child(_dungeon_row(party, id))
	dungeon_panel.add_child(dungeon_box)
	layout.add_child(dungeon_panel)

	layout.add_child(UIKit.spacer(4))
	var start_button := UIKit.primary_button(
		"START RUN – %s" % Dungeons.get_dungeon(selected_dungeon)["name"], 104
	)
	start_button.pressed.connect(func(): main.begin_run(selected_dungeon))
	layout.add_child(start_button)

	var shop_button := UIKit.big_button("Upgrades", 76)
	shop_button.pressed.connect(func(): main.show_shop("hub"))
	layout.add_child(shop_button)

	var switch_button := UIKit.big_button("Switch party", 60)
	switch_button.pressed.connect(main.show_slots)
	layout.add_child(switch_button)

	# US-10.2: engångsköp för ad-free, synligt i hubben.
	if not Game.ads_removed:
		var iap_button := UIKit.big_button("Remove ads – one-time purchase", 60)
		iap_button.pressed.connect(
			func():
				Ads.purchase_remove_ads()
				rebuild()
		)
		layout.add_child(iap_button)


func _dungeon_row(party: PartyState, id: String) -> Control:
	var dungeon := Dungeons.get_dungeon(id)
	var unlocked := Dungeons.is_unlocked(party, id)
	var selected: bool = id == selected_dungeon
	var button := UIKit.big_button("", 62)
	button.add_theme_font_size_override("font_size", 17)
	if unlocked:
		var clears := party.clears_of(id)
		var status := "cleared x%d" % clears if clears > 0 else String(dungeon["tagline"])
		button.text = "%s%s\n%s" % ["» " if selected else "", dungeon["name"], status]
		if selected:
			button.add_theme_color_override("font_color", UIKit.COLOR_ACCENT)
		button.pressed.connect(
			func():
				selected_dungeon = id
				rebuild()
		)
	else:
		button.text = "%s\n%s" % [dungeon["name"], Dungeons.lock_reason(party, id)]
		button.disabled = true
	return button


func _hero_row(party: PartyState, index: int) -> Control:
	var hero: Hero = party.heroes[index]
	var class_label: String = LevelUp.AXIS_LABELS.get(hero.class_identity, "Recruit")
	var row_tag := "F" if party.hero_row(index) == "front" else "B"
	var text_label := UIKit.body(
		(
			"[%s] %s – %s · HP %d · Atk %d · Mag %d"
			% [
				row_tag,
				hero.hero_name,
				class_label,
				hero.total_stat("max_hp", party),
				hero.total_stat("attack", party),
				hero.total_stat("magic", party)
			]
		),
		15
	)
	var icon: Texture2D = Icons.CLASS_EMBLEM.get(hero.class_identity, Icons.STAIRS)
	var tint: Color = UIKit.COLOR_ACCENT if hero.class_identity != "" else Color(1, 1, 1, 0.35)
	return Icons.labeled(icon, text_label, 24, tint)
