extends Node
## Global spelhanterare (autoload "Game"). Äger party-slots, aktiv run
## och save-systemet. Allt sparas lokalt – helt offline (US-11.1).
##
## Autosave-punkter (US-11.2): efter varje rum, vid checkpoint, vid köp,
## efter varje hjältehandling i strid samt vid wipe/run-slut.
## SAVE_VERSION 2 = party-modellen; äldre solo-saves kasseras.

const SAVE_PATH := "user://essens_save.json"
const SAVE_VERSION := 2

signal state_changed

var slots: Array = [null, null, null]  # Dictionary per slot eller null (US-4.4)
var active_slot := -1
var party: PartyState = null
var run: RunState = null
var ads_removed := false  # IAP-flagga (US-10.2), delas över alla slots
var _run_seed_counter := 0


func _ready() -> void:
	load_game()


# --- Slots och partyn (US-4.4) ---


func create_party(slot: int, hero_specs: Array) -> void:
	party = PartyState.create(hero_specs)
	active_slot = slot
	run = null
	save_game()


func select_slot(slot: int) -> bool:
	var data = slots[slot]
	if data == null:
		return false
	active_slot = slot
	party = PartyState.from_dict(data["party"])
	var run_data: Dictionary = data.get("run", {})
	run = RunState.from_dict(run_data) if not run_data.is_empty() else null
	return true


func delete_slot(slot: int) -> void:
	slots[slot] = null
	if slot == active_slot:
		active_slot = -1
		party = null
		run = null
	_write_to_disk()


func slot_summary(slot: int) -> Dictionary:
	var data = slots[slot]
	if data == null:
		return {}
	var party_data: Dictionary = data["party"]
	var classed := 0
	for hero_data in party_data.get("heroes", []):
		if String(hero_data.get("class_identity", "")) != "":
			classed += 1
	return {
		"name": party_data.get("party_name", "?"),
		"level": int(party_data.get("level", 1)),
		"hero_count": party_data.get("heroes", []).size(),
		"classed_heroes": classed,
		"has_active_run": not data.get("run", {}).is_empty(),
	}


# --- Run-livscykel ---


func has_active_run() -> bool:
	return run != null and not run.finished


func start_run(dungeon_id: String = Dungeons.DEFAULT) -> void:
	_run_seed_counter += 1
	var seed_value := int(Time.get_unix_time_from_system()) + _run_seed_counter
	run = RunState.start(party, seed_value, dungeon_id)
	save_game()


func end_run_at_checkpoint() -> int:
	var banked := run.bank_and_end(party)
	run = null
	save_game()
	return banked


func on_player_death() -> Dictionary:
	var summary := run.on_death(party)
	run = null
	save_game()
	return summary


func complete_run() -> int:
	# Runnen klarades hela vägen: allt säkras precis som vid checkpoint.
	var banked := run.bank_and_end(party)
	run = null
	save_game()
	return banked


# --- Save/load (US-11.1, US-11.2) ---


func save_game() -> void:
	if active_slot >= 0 and party != null:
		slots[active_slot] = {
			"party": party.to_dict(),
			"run": run.to_dict() if (run != null and not run.finished) else {},
		}
	_write_to_disk()
	state_changed.emit()


func _write_to_disk() -> void:
	var payload := {
		"version": SAVE_VERSION,
		"ads_removed": ads_removed,
		"slots": slots,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		push_error("Corrupt save file, starting fresh.")
		return
	ads_removed = parsed.get("ads_removed", false)
	if int(parsed.get("version", 1)) < SAVE_VERSION:
		# Solo-saves från v1 är inte kompatibla med party-modellen.
		push_warning("Old save format – starting fresh.")
		return
	var loaded_slots: Array = parsed.get("slots", [])
	for i in Balance.CHARACTER_SLOTS:
		slots[i] = loaded_slots[i] if i < loaded_slots.size() else null


# --- Onboarding (US-9.1): max 3 popups, visas en gång per party ---

const TUTORIAL_KEYS := ["combat_intro", "essence_intro", "checkpoint_intro"]


func should_show_tutorial(key: String) -> bool:
	if party == null or key not in TUTORIAL_KEYS:
		return false
	return not party.tutorial_flags.get(key, false)


func mark_tutorial_seen(key: String) -> void:
	if party != null:
		party.tutorial_flags[key] = true
		save_game()
