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

var current_screen: Control = null


func _ready() -> void:
	theme = UIKit.build_theme()
	var background := ColorRect.new()
	background.color = UIKit.COLOR_BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	show_slots()


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
		if run.combat != null and not run.combat.is_over():
			show_combat()
		elif run.at_checkpoint():
			show_checkpoint()
		else:
			show_run()
	else:
		show_hub()


# --- Spelflöde ---


func begin_run() -> void:
	Game.start_run()
	show_run()


## Spelaren trycker "Gå vidare" i run-vyn.
func descend() -> void:
	var event: Dictionary = Game.run.enter_next_room(Game.character)
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


func return_to_hub_with_ad() -> void:
	# US-10.1: interstitial endast mellan runs.
	Ads.show_interstitial_between_runs()
	show_hub()
