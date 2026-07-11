extends ScreenBase
## Checkpoint-valet (US-2.2) – spelets kärnbeslut:
## "Stanna och spendera" (säkra allt, avsluta runnen) eller
## "Fortsätt djupare" (allt osäkrat följer med och riskeras).
## Checkpointen helar (designbeslut: heal ja, respawn nej).


func build() -> void:
	var run: RunState = Game.run
	var party: PartyState = Game.party
	run.heal_at_checkpoint()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	add_child(UIKit.vmargin(layout))

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	header.add_child(Icons.image(Icons.CAMPFIRE, 42, UIKit.COLOR_WARN))
	header.add_child(UIKit.title("CHECKPOINT", 36))
	layout.add_child(header)
	layout.add_child(
		UIKit.body(
			"Depth %d. The party is revived and healed to full strength." % run.current_depth, 18
		)
	)

	var essence_panel := UIKit.panel()
	var essence_label := UIKit.body("Carried Essence: %d" % run.carried_essence, 26)
	essence_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	if not run.unsecured_items.is_empty():
		essence_label.text += "   ·   Unbanked loot: %d items" % run.unsecured_items.size()
	essence_panel.add_child(Icons.labeled(Icons.ESSENCE, essence_label, 36, UIKit.COLOR_ESSENCE))
	layout.add_child(essence_panel)

	# US-2.5: varning om en obärgad hög är i fara.
	if party.has_death_pile() and not run.pile_recovered_this_run:
		var warn_panel := UIKit.panel(Color("3a2a20"))
		var warn_label := (
			UIKit
			. body(
				(
					"Warning! You still have an unclaimed Essence pile (%d) at depth %d. Die again and it is replaced – lost forever!"
					% [
						int(party.death_pile.get("essence", 0)),
						int(party.death_pile.get("depth", 1))
					]
				),
				16
			)
		)
		warn_label.add_theme_color_override("font_color", UIKit.COLOR_WARN)
		warn_panel.add_child(warn_label)
		layout.add_child(warn_panel)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(filler)

	var shop_button := UIKit.big_button("Spend carried Essence", 80)
	shop_button.pressed.connect(func(): main.show_shop("checkpoint"))
	layout.add_child(shop_button)

	var stay_button := UIKit.primary_button(
		"STAY – bank %d Essence and end the run" % run.carried_essence, 104
	)
	stay_button.pressed.connect(
		func():
			var banked := Game.end_run_at_checkpoint()
			main.show_victory(banked)
	)
	layout.add_child(stay_button)

	# US-1.3: djupare segment kräver nivå – tydlig indikation.
	var lock_reason := run.deeper_lock_reason(party)
	if lock_reason != "":
		var lock_label := UIKit.body("Locked: " + lock_reason, 17)
		lock_label.add_theme_color_override("font_color", UIKit.COLOR_WARN)
		layout.add_child(lock_label)
	else:
		var deeper_button := UIKit.primary_button("GO DEEPER – risk it all", 104)
		deeper_button.pressed.connect(
			func():
				Game.save_game()
				main.show_run()
		)
		layout.add_child(deeper_button)

	# Onboarding-popup 3/3 (US-9.1).
	if Game.should_show_tutorial("checkpoint_intro"):
		Game.mark_tutorial_seen("checkpoint_intro")
		(
			UIKit
			. popup(
				self,
				"Checkpoint",
				"Here you choose: stay and bank everything you carry – or push deeper where rewards are greater but everything unbanked is at risk."
			)
		)
