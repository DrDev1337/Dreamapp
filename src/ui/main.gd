extends Control
## Skärmrouter och spelflöde. Alla övergångar mellan skärmar går genom
## den här filen, så flödet i specen går att läsa på ett ställe:
##
##   Slots -> Hubb -> [run] Rum -> Strid -> (Level up) ->
##     boss klarad        -> Victory -> annons -> Hubb
##     checkpoint-rum     -> Checkpoint -> djupare (Rum) eller banka (Hubb)
##     annars             -> Rum
##   Död i strid -> Death -> annons -> Hubb

const SlotScreen := preload("res://src/ui/slot_screen.gd")
const HubScreen := preload("res://src/ui/hub_screen.gd")
const ShopScreen := preload("res://src/ui/shop_screen.gd")
const RunScreen := preload("res://src/ui/run_screen.gd")
const CombatScreen := preload("res://src/ui/combat_screen.gd")
const CheckpointScreen := preload("res://src/ui/checkpoint_screen.gd")
const LevelUpScreen := preload("res://src/ui/levelup_screen.gd")
const DeathScreen := preload("res://src/ui/death_screen.gd")
const VictoryScreen := preload("res://src/ui/victory_screen.gd")
const PartyScreen := preload("res://src/ui/party_screen.gd")

var current_screen: Control = null


func _ready() -> void:
	theme = UIKit.build_theme()
	_build_background()
	show_slots()


## Skiktad bakgrund helt utan bildfiler: grundfärg, ett svagt lila
## ljussken uppifrån och en mörk vinjett i kanterna.
func _build_background() -> void:
	var base := ColorRect.new()
	base.color = UIKit.COLOR_BG
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	var glow := _gradient_layer(
		Color(UIKit.COLOR_ACCENT.r, UIKit.COLOR_ACCENT.g, UIKit.COLOR_ACCENT.b, 0.14),
		Color(UIKit.COLOR_ACCENT.r, UIKit.COLOR_ACCENT.g, UIKit.COLOR_ACCENT.b, 0.0),
		Vector2(0.5, 0.1),
		Vector2(0.5, 0.85)
	)
	add_child(glow)

	var vignette := _gradient_layer(
		Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.5), Vector2(0.5, 0.45), Vector2(0.5, 1.25)
	)
	add_child(vignette)


func _gradient_layer(inner: Color, outer: Color, from: Vector2, to: Vector2) -> TextureRect:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([inner, outer])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = from
	texture.fill_to = to
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _goto(script: GDScript, data := {}) -> void:
	if current_screen != null:
		current_screen.queue_free()
	var screen: ScreenBase = script.new()
	screen.main = self
	screen.data = data
	add_child(screen)
	current_screen = screen


# --- Navigering ---


func show_slots() -> void:
	_goto(SlotScreen)


func show_hub() -> void:
	_goto(HubScreen)


func show_party() -> void:
	_goto(PartyScreen)


func show_shop(context: String) -> void:
	_goto(ShopScreen, {"context": context})


func show_run(event := {}) -> void:
	_goto(RunScreen, {"event": event})


func show_combat() -> void:
	_goto(CombatScreen)


func show_checkpoint() -> void:
	_goto(CheckpointScreen)


func show_death(summary: Dictionary) -> void:
	_goto(DeathScreen, {"summary": summary})


func show_victory(banked: int) -> void:
	_goto(VictoryScreen, {"banked": banked})


## Efter val av slot: hoppa in exakt där spelaren var (US-11.2).
func resume_or_hub() -> void:
	if Game.has_active_run():
		var run: RunState = Game.run
		if run.combat != null and run.combat.is_over():
			# Appen stängdes på slutskärmen: förlust ger döden dess pris,
			# vunnen strid utan uthämtade rewards släpps vidare till kartan.
			if run.combat.result == "defeat":
				player_died()
				return
			run.combat = null
		if run.combat != null:
			show_combat()
		elif run.at_checkpoint():
			show_checkpoint()
		else:
			show_run()
	else:
		show_hub()


# --- Spelflöde ---


func begin_run(dungeon_id: String = Dungeons.DEFAULT) -> void:
	Game.start_run(dungeon_id)
	show_run()


## Spelaren trycker "Gå vidare" i run-vyn.
func descend() -> void:
	var event: Dictionary = Game.run.enter_next_room(Game.party)
	Game.save_game()  # autosave efter rumsbyte (US-11.2)
	if event["combat_started"]:
		show_combat()
	else:
		show_run(event)


## Anropas av CombatScreen när striden är vunnen och rewards hanterats.
func after_room_cleared(rewards: Dictionary) -> void:
	var room: Dictionary = Game.run.current_room()
	var levels := int(rewards.get("levels_gained", 0))
	if levels > 0:
		_goto(
			LevelUpScreen,
			{"remaining": levels, "boss_defeated": rewards.get("boss_defeated", false)}
		)
		return
	_continue_after_levelups(rewards.get("boss_defeated", false))


## Anropas även av LevelUpScreen när alla val är gjorda.
func _continue_after_levelups(boss_defeated: bool) -> void:
	if boss_defeated or Game.run.is_run_complete():
		var banked := Game.complete_run()
		show_victory(banked)
	elif Game.run.at_checkpoint():
		show_checkpoint()
	else:
		show_run()


func player_died() -> void:
	var summary := Game.on_player_death()
	show_death(summary)


## Frivilligt avbruten run: räknas som en död – buren Essens lämnas i
## en hög på nuvarande djup, så mekaniken inte går att missbruka.
func abandon_run() -> void:
	var summary := Game.on_player_death()
	summary["abandoned"] = true
	show_death(summary)


func return_to_hub_with_ad() -> void:
	# US-10.1: interstitial endast mellan runs.
	Ads.show_interstitial_between_runs()
	show_hub()
