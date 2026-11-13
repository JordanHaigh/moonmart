class_name MoonmartWorld
extends RefCounted

## Location gates use story flags. Optional commercial doors may also require
## reputation, but an essential narrative room never consults reputation.
signal location_unlocked(location_id: String)
signal location_changed(location_id: String)
signal ending_chosen(ending_id: String)

const ENDINGS := ["keeper", "open_door", "gentle_goodbye"]
const ENDING_WORLDS := {
	"keeper": {"door_open": true, "community_mixed": false},
	"open_door": {"door_open": true, "community_mixed": true},
	"gentle_goodbye": {"door_open": false, "community_mixed": false}
}

var locations: Dictionary = {}
var unlocked_locations: Array[String] = ["moonmart"]
var current_location := "moonmart"
var flags: Dictionary = {}
var optional_reputation := 0
var ending_id := ""
var ending_chapter_complete := false

func setup(location_rows: Array, initial_flags: Dictionary = {}) -> void:
	locations.clear()
	unlocked_locations = ["moonmart"]
	current_location = "moonmart"
	flags = initial_flags.duplicate(true)
	for row in location_rows:
		if row is Dictionary and row.has("id"):
			locations[String(row.id)] = row.duplicate(true)
	_refresh_story_unlocks()

func _refresh_story_unlocks() -> void:
	for location_id in locations:
		var location: Dictionary = locations[location_id]
		if not bool(location.get("essential", false)):
			continue
		if unlocked_locations.has(location_id):
			continue
		var eligible := true
		for flag_id in location.get("requires_flags", []):
			if not bool(flags.get(String(flag_id), false)):
				eligible = false
				break
		if eligible:
			unlocked_locations.append(location_id)
			location_unlocked.emit(location_id)

func set_story_flag(flag_id: String, value: bool = true) -> void:
	flags[flag_id] = value
	_refresh_story_unlocks()

func unlock_optional(location_id: String, reputation: int) -> bool:
	if not locations.has(location_id) or bool(locations[location_id].get("essential", false)):
		return false
	var location: Dictionary = locations[location_id]
	if reputation < int(location.get("reputation_required", 0)):
		return false
	if _ending_closes_location(location_id):
		return false
	if not unlocked_locations.has(location_id):
		unlocked_locations.append(location_id)
		location_unlocked.emit(location_id)
	optional_reputation = maxi(optional_reputation, reputation)
	return true

func is_unlocked(location_id: String) -> bool:
	if ending_id == "gentle_goodbye" and _ending_closes_location(location_id):
		return false
	return unlocked_locations.has(location_id)

func get_available_locations() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for location_id in unlocked_locations:
		if is_unlocked(location_id) and locations.has(location_id):
			available.append(locations[location_id])
	return available

func travel_to(location_id: String) -> bool:
	if not is_unlocked(location_id):
		return false
	current_location = location_id
	location_changed.emit(location_id)
	return true

func choose_ending(candidate: String, required_flags: Array[String], final_chapter_complete: bool) -> bool:
	if ending_id != "" or not ENDINGS.has(candidate) or not final_chapter_complete:
		return false
	for flag_id in required_flags:
		if not bool(flags.get(flag_id, false)):
			return false
	ending_id = candidate
	ending_chapter_complete = true
	# Gentle Goodbye closes Between-facing locations. If the player chooses it
	# while standing in one, move them back to the shop so the active location
	# always remains reachable in the selected world state.
	if not is_unlocked(current_location):
		current_location = "moonmart"
		location_changed.emit(current_location)
	ending_chosen.emit(ending_id)
	return true

func continue_sandbox() -> bool:
	return ending_chapter_complete and ENDINGS.has(ending_id)

func world_state() -> Dictionary:
	return ENDING_WORLDS.get(ending_id, {"door_open": true, "community_mixed": false}).duplicate(true)

func ending_world_state_id() -> String:
	match ending_id:
		"keeper": return "sanctuary_between_worlds"
		"open_door": return "mixed_community"
		"gentle_goodbye": return "ordinary_shop_with_memories"
	return "ordinary_midnight"

func _ending_closes_location(location_id: String) -> bool:
	if ending_id != "gentle_goodbye":
		return false
	if not locations.has(location_id):
		return location_id in ["hidden_midnight_room", "midnight_platform", "between"]
	var location: Dictionary = locations[location_id]
	return bool(location.get("requires_open_door", false)) or String(location.get("kind", "")) == "between"

func export_state() -> Dictionary:
	return {"unlocked_locations": unlocked_locations.duplicate(), "current_location": current_location, "flags": flags.duplicate(true), "optional_reputation": optional_reputation, "ending_id": ending_id, "ending_chapter_complete": ending_chapter_complete}

func import_state(data: Dictionary) -> void:
	unlocked_locations.assign(data.get("unlocked_locations", ["moonmart"]))
	current_location = String(data.get("current_location", "moonmart"))
	flags = data.get("flags", flags).duplicate(true)
	optional_reputation = maxi(0, int(data.get("optional_reputation", 0)))
	ending_id = String(data.get("ending_id", "")) if ENDINGS.has(String(data.get("ending_id", ""))) else ""
	ending_chapter_complete = bool(data.get("ending_chapter_complete", ending_id != ""))
	_refresh_story_unlocks()
	if not unlocked_locations.has(current_location) or not is_unlocked(current_location):
		current_location = "moonmart"
