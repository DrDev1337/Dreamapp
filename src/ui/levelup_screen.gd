extends ScreenBase
## Party-level-up (party_design.md): välj EN uppgradering av tre,
## kopplade till tre olika hjältar. 3 val åt samma håll på samma hjälte
## låser klassidentitet + signaturförmåga.


func build() -> void:
	var party: PartyState = Game.party
	var remaining := int(data.get("remaining", 1))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.title("LEVEL UP!  Party level %d" % party.level, 34))
	layout.add_child(UIKit.body("Choose who grows (%d picks left):" % remaining, 18))
	layout.add_child(
		UIKit.body("3 picks in one path locks a hero's class and signature ability.", 14)
	)
	layout.add_child(UIKit.spacer(10))

	var choices := LevelUp.generate_choices(
		party, Game.run.rng if Game.run != null else RandomNumberGenerator.new()
	)
	for choice in choices:
		var button := UIKit.big_button("%s\n%s" % [choice["label"], choice["desc"]], 110)
		button.icon = Icons.CLASS_EMBLEM.get(choice["axis"], null)
		button.add_theme_constant_override("icon_max_width", 40)
		button.add_theme_color_override("icon_normal_color", UIKit.COLOR_ACCENT)
		button.pressed.connect(func(): _pick(choice, remaining))
		layout.add_child(button)


func _pick(choice: Dictionary, remaining: int) -> void:
	var unlocked := LevelUp.apply_choice(Game.party, choice)
	Game.save_game()
	if unlocked:
		var axis := String(choice["axis"])
		var signature := Abilities.get_ability(Abilities.SIGNATURE_BY_AXIS[axis])
		UIKit.popup(
			main,
			"%s is now a %s!" % [choice["hero_name"], LevelUp.AXIS_LABELS[axis]],
			"They have found their path and learn the signature ability %s." % signature["name"]
		)
	if remaining > 1:
		data["remaining"] = remaining - 1
		rebuild()
	else:
		main._continue_after_levelups(data.get("boss_defeated", false))
