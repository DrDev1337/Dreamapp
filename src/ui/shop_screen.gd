extends ScreenBase
## Uppgraderingsbutik (US-2.6): två flikar – Permanent / Boosts.
## Används både i hubben (spenderar bankad Essens) och vid checkpoint
## (spenderar buren Essens; boosts gäller då resten av pågående run).

var context := "hub"


func build() -> void:
	context = data.get("context", "hub")
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.title("Uppgraderingar", 32))
	layout.add_child(_currency_label())

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 20)
	layout.add_child(tabs)

	var permanent_tab := _scrollable()
	permanent_tab.name = "Permanent"
	tabs.add_child(permanent_tab)
	var permanent_list: VBoxContainer = permanent_tab.get_child(0)
	for id in Upgrades.PERMANENT:
		permanent_list.add_child(_permanent_row(id))

	var boost_tab := _scrollable()
	boost_tab.name = "Denna run" if context == "checkpoint" else "Nästa run"
	tabs.add_child(boost_tab)
	var boost_list: VBoxContainer = boost_tab.get_child(0)
	for id in Upgrades.TEMPORARY:
		boost_list.add_child(_temporary_row(id))

	var back_button := UIKit.big_button("Tillbaka")
	back_button.pressed.connect(
		func():
			if context == "checkpoint":
				main.show_checkpoint()
			else:
				main.show_hub()
	)
	layout.add_child(back_button)


func _scrollable() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	return scroll


func _currency_label() -> Label:
	var amount := (
		Game.run.carried_essence if context == "checkpoint" else Game.character.banked_essence
	)
	var source := "buren" if context == "checkpoint" else "bankad"
	var label := UIKit.body("Essens (%s): %d" % [source, amount], 22)
	label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	return label


func _permanent_row(id: String) -> Control:
	var up: Dictionary = Upgrades.PERMANENT[id]
	var rank := int(Game.character.permanent_upgrades.get(id, 0))
	var maxed: bool = rank >= int(up["max_rank"])
	var cost := Upgrades.permanent_cost(id, rank)
	var text: String
	if maxed:
		text = "%s  (MAX)\n%s" % [up["name"], up["desc"]]
	else:
		text = (
			"%s  rank %d/%d  –  %d Essens\n%s"
			% [up["name"], rank, int(up["max_rank"]), cost, up["desc"]]
		)
	var button := UIKit.big_button(text, 96)
	button.disabled = maxed
	button.pressed.connect(
		func():
			var run: RunState = Game.run if context == "checkpoint" else null
			if Upgrades.buy_permanent(Game.character, id, run):
				Game.save_game()  # autosave vid köp (US-11.2)
				rebuild()
			else:
				UIKit.popup(self, "Kan inte köpa", "Du har inte tillräckligt med Essens.")
	)
	return button


func _temporary_row(id: String) -> Control:
	var boost: Dictionary = Upgrades.TEMPORARY[id]
	var button := UIKit.big_button(
		"%s  –  %d Essens\n%s" % [boost["name"], int(boost["cost"]), boost["desc"]], 96
	)
	button.pressed.connect(
		func():
			var run: RunState = Game.run if context == "checkpoint" else null
			if Upgrades.buy_temporary(Game.character, id, run, context == "checkpoint"):
				Game.save_game()
				rebuild()
			else:
				UIKit.popup(self, "Kan inte köpa", "Du har inte tillräckligt med Essens.")
	)
	return button
