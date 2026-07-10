extends ScreenBase
## Level up (US-4.2): tre val som drar mot fighter, mage eller rogue.
## Efter 3 val i samma riktning låses klassidentitet + signaturförmåga.


func build() -> void:
	var character: CharacterState = Game.character
	var remaining := int(data.get("remaining", 1))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.title("LEVEL UP!  Level %d" % character.level, 36))
	layout.add_child(UIKit.body("Choose your path (%d picks left):" % remaining, 18))
	layout.add_child(
		UIKit.body(
			(
				"Fighter %d  ·  Mage %d  ·  Rogue %d   (3 picks in one path unlocks a class)"
				% [
					int(character.class_axis_points["fighter"]),
					int(character.class_axis_points["mage"]),
					int(character.class_axis_points["rogue"])
				]
			),
			15
		)
	)
	layout.add_child(UIKit.spacer(10))

	var choices := LevelUp.generate_choices(
		character, Game.run.rng if Game.run != null else RandomNumberGenerator.new()
	)
	for choice in choices:
		var button := UIKit.big_button("%s\n%s" % [choice["label"], choice["desc"]], 110)
		button.icon = Icons.CLASS_EMBLEM.get(choice["axis"], null)
		button.add_theme_constant_override("icon_max_width", 40)
		button.add_theme_color_override("icon_normal_color", UIKit.COLOR_ACCENT)
		button.pressed.connect(func(): _pick(choice, remaining))
		layout.add_child(button)


func _pick(choice: Dictionary, remaining: int) -> void:
	var unlocked := LevelUp.apply_choice(Game.character, choice)
	Game.save_game()
	if unlocked:
		var axis := String(choice["axis"])
		var signature := Abilities.get_ability(Abilities.SIGNATURE_BY_AXIS[axis])
		UIKit.popup(
			main,
			"Class unlocked: %s!" % LevelUp.AXIS_LABELS[axis],
			"You have found your path and learn the signature ability %s." % signature["name"]
		)
	if remaining > 1:
		data["remaining"] = remaining - 1
		rebuild()
	else:
		main._continue_after_levelups(data.get("boss_defeated", false))
