class_name MoonmartMisoCompanion
extends RefCounted

## Gentle, optional companion state for Miso. Feeding, petting, brushing and
## play can only improve comfort; no state represents illness, abandonment,
## running away or death. The caller owns any inventory cost for treats/toys.
signal mood_changed(mood_id: String)
signal happiness_changed(value: int)
signal ability_used(ability_id: String)

var happiness := 72
var mood_id := "content"
var current_shift := 0
var favorite_toy := "felt_moon"
var preferred_sleep_spot := "cat_bed"
var unlocked_abilities: Dictionary = {}
var action_shifts: Dictionary = {}
var ability_shifts: Dictionary = {}
var ability_definitions: Dictionary = {}
var action_definitions: Dictionary = {}
var toy_definitions: Dictionary = {}
var sleep_spots: Dictionary = {}
var mood_definitions: Array[Dictionary] = []
var ambient_anchors: Dictionary = {}
var ambient_behaviors: Array[Dictionary] = []
var ambient_behavior_timing: Dictionary = {}

func setup(config: Dictionary) -> void:
	ability_definitions.clear()
	for row in config.get("abilities", []):
		if row is Dictionary and not String(row.get("id", "")).is_empty():
			ability_definitions[String(row.id)] = row.duplicate(true)
	action_definitions = config.get("actions", {}).duplicate(true)
	toy_definitions = config.get("toys", {}).duplicate(true)
	sleep_spots = config.get("sleep_spots", {}).duplicate(true)
	mood_definitions.clear()
	for row in config.get("moods", []):
		if row is Dictionary:
			mood_definitions.append(row.duplicate(true))
	ambient_anchors = config.get("ambient_anchors", {}).duplicate(true)
	ambient_behaviors.clear()
	for behavior_value in config.get("ambient_behaviors", []):
		if behavior_value is Dictionary:
			ambient_behaviors.append(behavior_value.duplicate(true))
	ambient_behavior_timing = config.get("ambient_behavior_timing", {}).duplicate(true)
	favorite_toy = String(config.get("favorite_toy", favorite_toy))
	preferred_sleep_spot = String(config.get("preferred_sleep_spot", preferred_sleep_spot))
	_update_mood()

## Start a shift and clear that shift's once-per-action limits. Re-loading the
## same shift does not clear them, so a mid-shift save cannot refresh rewards.
func begin_shift(shift_number: int) -> void:
	if shift_number > current_shift:
		current_shift = shift_number
		_update_mood()

func interact(action_id: String, shift_number: int, toy_id: String = "") -> Dictionary:
	begin_shift(shift_number)
	if not action_definitions.has(action_id):
		return {"ok": false, "reason": "unknown_action"}
	if action_shifts.has(action_id) and int(action_shifts[action_id]) == shift_number:
		return {"ok": false, "reason": "already_done", "happiness": happiness, "mood": mood_id}
	var row: Dictionary = action_definitions[action_id]
	var gain := int(row.get("happiness", 0))
	var note := String(row.get("response", "Miso settles happily beside you."))
	if action_id == "play":
		var selected_toy := toy_id
		if not selected_toy.is_empty() and not toy_definitions.has(selected_toy):
			return {"ok": false, "reason": "unknown_toy"}
		if selected_toy == favorite_toy:
			gain += int(row.get("favorite_toy_bonus", 0))
			note = String(row.get("favorite_response", note))
		elif not selected_toy.is_empty():
			note = String(toy_definitions[selected_toy].get("response", note))
	action_shifts[action_id] = shift_number
	_set_happiness(happiness + gain)
	return {"ok": true, "action_id": action_id, "happiness": happiness, "gain": gain, "mood": mood_id, "message": note}

func choose_sleep_spot(spot_id: String) -> bool:
	if not sleep_spots.has(spot_id):
		return false
	preferred_sleep_spot = spot_id
	return true

## Call after story flags change. Abilities use explicit narrative flags and
## never gate essential story access.
func sync_story_flags(flags: Dictionary) -> Array[String]:
	var newly_unlocked: Array[String] = []
	for ability_id in ability_definitions:
		if bool(unlocked_abilities.get(ability_id, false)):
			continue
		var row: Dictionary = ability_definitions[ability_id]
		var required: Array = row.get("requires_flags", [])
		var ready := required.is_empty()
		if not required.is_empty():
			ready = true
			for flag_id in required:
				if not bool(flags.get(String(flag_id), false)):
					ready = false
					break
		if ready:
			unlocked_abilities[ability_id] = true
			newly_unlocked.append(String(ability_id))
	return newly_unlocked

## Returns a small, non-blocking hint/effect for an unlocked ability. Hidden
## Paw returns a discovered clue ID supplied by the caller, if one is available.
func use_ability(ability_id: String, shift_number: int, context: Dictionary = {}) -> Dictionary:
	begin_shift(shift_number)
	if not bool(unlocked_abilities.get(ability_id, false)):
		return {"ok": false, "reason": "locked"}
	if ability_shifts.has(ability_id) and int(ability_shifts[ability_id]) == shift_number:
		return {"ok": false, "reason": "already_used"}
	if not ability_definitions.has(ability_id):
		return {"ok": false, "reason": "unknown_ability"}
	var row: Dictionary = ability_definitions[ability_id]
	ability_shifts[ability_id] = shift_number
	ability_used.emit(ability_id)
	var result := {"ok": true, "ability_id": ability_id, "message": String(row.get("response", "Miso looks toward the quiet edge of the room."))}
	if ability_id == "hidden_paw":
		var clue_id := String(context.get("overlooked_clue_id", ""))
		result["clue_id"] = clue_id
		if clue_id.is_empty():
			result["message"] = String(row.get("waiting_response", result.message))
	if ability_id == "guardian_purr":
		result["stability"] = float(row.get("stability", 0.0))
	return result

func ability_available(ability_id: String) -> bool:
	return bool(unlocked_abilities.get(ability_id, false))

func _set_happiness(value: int) -> void:
	var next := clampi(value, 0, 100)
	if next == happiness:
		return
	happiness = next
	happiness_changed.emit(happiness)
	_update_mood()

func _update_mood() -> void:
	var next := "content"
	for row in mood_definitions:
		if happiness >= int(row.get("minimum_happiness", 0)):
			next = String(row.get("id", next))
	if next != mood_id:
		mood_id = next
		mood_changed.emit(mood_id)

func export_state() -> Dictionary:
	return {"happiness": happiness, "mood_id": mood_id, "current_shift": current_shift, "favorite_toy": favorite_toy, "preferred_sleep_spot": preferred_sleep_spot, "unlocked_abilities": unlocked_abilities.duplicate(true), "action_shifts": action_shifts.duplicate(true), "ability_shifts": ability_shifts.duplicate(true)}

func import_state(data: Dictionary) -> void:
	happiness = clampi(int(data.get("happiness", 72)), 0, 100)
	current_shift = maxi(0, int(data.get("current_shift", 0)))
	favorite_toy = String(data.get("favorite_toy", favorite_toy))
	preferred_sleep_spot = String(data.get("preferred_sleep_spot", preferred_sleep_spot))
	if not toy_definitions.has(favorite_toy):
		favorite_toy = String(toy_definitions.keys()[0]) if not toy_definitions.is_empty() else ""
	if not sleep_spots.has(preferred_sleep_spot):
		preferred_sleep_spot = String(sleep_spots.keys()[0]) if not sleep_spots.is_empty() else ""
	unlocked_abilities = data.get("unlocked_abilities", {}).duplicate(true)
	for ability_id in unlocked_abilities.keys():
		if not ability_definitions.has(ability_id):
			unlocked_abilities.erase(ability_id)
	action_shifts = data.get("action_shifts", {}).duplicate(true)
	ability_shifts = data.get("ability_shifts", {}).duplicate(true)
	mood_id = ""
	_update_mood()
	happiness_changed.emit(happiness)
