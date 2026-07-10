extends ScreenBase
## Checkpoint-valet (US-2.2) – spelets kärnbeslut:
## "Stanna och spendera" (säkra allt, avsluta runnen) eller
## "Fortsätt djupare" (allt osäkrat följer med och riskeras).
## Checkpointen helar (designbeslut: heal ja, respawn nej).


func build() -> void:
	var run: RunState = Game.run
	var character: CharacterState = Game.character
	run.heal_at_checkpoint()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	add_child(UIKit.vmargin(layout))

	layout.add_child(UIKit.title("⛨ Checkpoint", 36))
	layout.add_child(UIKit.body("Djup %d. Du helas till full styrka." % run.current_depth, 18))

	var essence_panel := UIKit.panel()
	var essence_label := UIKit.body("Buren Essens: %d" % run.carried_essence, 26)
	essence_label.add_theme_color_override("font_color", UIKit.COLOR_ESSENCE)
	essence_panel.add_child(essence_label)
	if not run.unsecured_items.is_empty():
		essence_panel.get_child(0).text += (
			"   •   Osäkrad loot: %d föremål" % run.unsecured_items.size()
		)
	layout.add_child(essence_panel)

	# US-2.5: varning om en obärgad hög är i fara.
	if character.has_death_pile() and not run.pile_recovered_this_run:
		var warn_panel := UIKit.panel(Color("3a2a20"))
		var warn_label := (
			UIKit
			. body(
				(
					"⚠ Du har fortfarande en obärgad Essens-hög (%d) på djup %d. Dör du ersätts den och försvinner för alltid!"
					% [
						int(character.death_pile.get("essence", 0)),
						int(character.death_pile.get("depth", 1))
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

	var shop_button := UIKit.big_button("Handla för buren Essens", 80)
	shop_button.pressed.connect(func(): main.show_shop("checkpoint"))
	layout.add_child(shop_button)

	var stay_button := UIKit.big_button(
		"✓  STANNA – säkra %d Essens och avsluta" % run.carried_essence, 104
	)
	stay_button.pressed.connect(
		func():
			var banked := Game.end_run_at_checkpoint()
			main.show_victory(banked)
	)
	layout.add_child(stay_button)

	# US-1.3: djupare segment kräver nivå – tydlig indikation.
	var lock_reason := run.deeper_lock_reason(character)
	if lock_reason != "":
		var lock_label := UIKit.body("🔒 " + lock_reason, 17)
		lock_label.add_theme_color_override("font_color", UIKit.COLOR_WARN)
		layout.add_child(lock_label)
	else:
		var deeper_button := UIKit.big_button("⬇  FORTSÄTT DJUPARE – riskera allt", 104)
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
				"Här väljer du: stanna och säkra allt du bär – eller fortsätt djupare där belöningarna är större men allt osäkrat riskeras."
			)
		)
