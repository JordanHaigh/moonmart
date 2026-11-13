extends SceneTree

const QuestManager = preload("res://scripts/systems/quest_manager.gd")
const WorldManager = preload("res://scripts/systems/world_manager.gd")

var _failures := 0
var _checks := 0

func _init() -> void:
	print("Running progression suite")
	call_deferred("_run")

func _run() -> void:
	_test_essential_encounter_retries()
	_test_clue_gated_hypotheses()
	_test_story_locations_and_ending()
	if _failures == 0:
		print("Progression suite passed: %d checks." % _checks)
	else:
		printerr("Progression suite failed: %d of %d checks." % [_failures, _checks])
	var report := FileAccess.open("user://progression_test_report.txt", FileAccess.WRITE)
	if report != null:
		report.store_string("checks=%d\nfailures=%d\n" % [_checks, _failures])
		report.close()
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	printerr("FAIL: " + label)

func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}

func _test_essential_encounter_retries() -> void:
	var quest_data := _read_json("res://data/quests.json")
	var rows: Array[Dictionary] = []
	for event_value in quest_data.get("story_events", []):
		if not event_value is Dictionary:
			continue
		var row: Dictionary = event_value.duplicate(true)
		row["essential"] = true
		row["visitor_id"] = String(row.get("visitor", ""))
		row["sets_flags"] = [String(row.get("id", ""))]
		row["trigger"] = {}
		rows.append(row)
	var quests = QuestManager.new()
	quests.setup(rows)
	var first_shift: Array[Dictionary] = quests.begin_shift(1)
	_check(first_shift.size() == 1 and String(first_shift[0].get("quest_id", "")) == "meet_agnes", "first essential encounter is queued")
	quests.note_visit_missed("meet_agnes")
	var next_shift: Array[Dictionary] = quests.begin_shift(2)
	_check(next_shift.size() == 1 and String(next_shift[0].get("quest_id", "")) == "meet_agnes", "missed essential visit carries forward")
	_check(int(next_shift[0].get("eligible_shift", 0)) == 2, "carried visit becomes eligible on the new shift")
	var resolved: Dictionary = quests.resolve_essential_encounter("meet_agnes")
	_check(bool(resolved.get("ok", false)) and bool(quests.flags.get("meet_agnes", false)), "resolving the queued visit grants its story flag")
	var following: Array[Dictionary] = quests.begin_shift(2)
	_check(following.size() == 1 and String(following[0].get("quest_id", "")) == "pip_reflection", "next essential encounter unlocks after the previous one resolves")

func _test_clue_gated_hypotheses() -> void:
	var narrative_script: Script = load("res://scripts/systems/narrative_manager.gd")
	var narrative_script_valid := narrative_script != null and narrative_script.can_instantiate()
	_check(narrative_script_valid, "narrative manager script parses and can instantiate")
	if not narrative_script_valid:
		return
	var story = narrative_script.new()
	story.begin_shift(1)
	var pip_case: Dictionary = story.investigation_definitions.get("pip_identity", {})
	var old_customer: Dictionary = {}
	for hypothesis in pip_case.get("hypotheses", []):
		if String(hypothesis.get("id", "")) == "old_customer":
			old_customer = hypothesis
	_check(not old_customer.is_empty(), "Pip identity case includes the expected theory")
	_check(not story.investigation_hypothesis_available(old_customer), "theory stays hidden while its required clues are unavailable")
	story.resolve_event("meet_agnes", true)
	story.resolve_event("pip_reflection", true)
	story.resolve_event("receipt_1974", true)
	var receipt_only: Array[String] = ["receipt_dated_1974"]
	var before_photo: Dictionary = story.connect_clues("pip_identity", receipt_only)
	_check(String(before_photo.get("status", "")) == "hint", "one clue requests more evidence without solving the case")
	_check(not bool(story.flags.get("pip_past_discovered", false)), "insufficient evidence does not grant the mystery result flag")
	story.resolve_event("hidden_photograph", true)
	_check(story.investigation_hypothesis_available(old_customer), "theory unlocks once its clue source is available")
	var matching_clues: Array[String] = ["receipt_dated_1974", "photograph_matches_pip"]
	var solved: Dictionary = story.connect_clues("pip_identity", matching_clues)
	_check(String(solved.get("status", "")) == "deduced", "matching required clues resolves the theory")
	_check(bool(story.flags.get("pip_past_discovered", false)), "correct deduction grants its configured flag")

func _test_story_locations_and_ending() -> void:
	var location_data := _read_json("res://data/locations.json")
	var normalized: Array[Dictionary] = []
	for location_value in location_data.get("locations", []):
		if not location_value is Dictionary:
			continue
		var location: Dictionary = location_value.duplicate(true)
		location["essential"] = bool(location.get("essential", false))
		var unlock_flag := String(location.get("unlocks_flag", ""))
		location["requires_flags"] = [] if unlock_flag.is_empty() else [unlock_flag]
		normalized.append(location)
	var world = WorldManager.new()
	world.setup(normalized)
	_check(world.is_unlocked("moonmart"), "Moonmart is initially available")
	_check(not world.is_unlocked("whisperwood"), "story location remains gated before its event")
	world.set_story_flag("fern_arrives")
	_check(world.is_unlocked("whisperwood"), "story flag unlocks Whisperwood")
	world.set_story_flag("platform_opened")
	_check(world.travel_to("midnight_platform"), "opened platform is reachable")
	_check(not world.choose_ending("gentle_goodbye", ["final_covenant_made"], true), "ending cannot be chosen without its required covenant flag")
	world.set_story_flag("final_covenant_made")
	_check(world.choose_ending("gentle_goodbye", ["final_covenant_made"], true), "eligible ending can be chosen")
	_check(String(world.current_location) == "moonmart", "gentle ending returns the player from a closed Between location")
	_check(world.continue_sandbox(), "completed ending permits sandbox continuation")

	var narrative_script: Script = load("res://scripts/systems/narrative_manager.gd")
	var narrative_script_valid := narrative_script != null and narrative_script.can_instantiate()
	_check(narrative_script_valid, "narrative manager parses for ending checks")
	if not narrative_script_valid:
		return
	var quest_data := _read_json("res://data/quests.json")
	var endings: Array = quest_data.get("endings", [])
	var expected_world_states := {
		"keeper": {"door_open": true, "community_mixed": false},
		"open_door": {"door_open": true, "community_mixed": true},
		"gentle_goodbye": {"door_open": false, "community_mixed": false}
	}
	_check(endings.size() == 3, "authored ending data contains all three outcomes")
	var ending_ids: Array[String] = []
	for ending_value in endings:
		if not ending_value is Dictionary:
			continue
		var ending_definition: Dictionary = ending_value
		var ending_id := String(ending_definition.get("id", ""))
		ending_ids.append(ending_id)
		var narrative = narrative_script.new()
		narrative.begin_shift(1)
		_check(narrative.available_endings().is_empty(), "%s stays locked before the final covenant" % ending_id)
		narrative.flags["final_covenant_made"] = true
		var available: Array[Dictionary] = narrative.available_endings()
		_check(available.size() == 3 and _has_ending(available, ending_id), "%s unlocks when the final covenant is made" % ending_id)
		var chosen: Dictionary = narrative.choose_ending(ending_id)
		_check(bool(chosen.get("ok", false)), "narrative accepts %s" % ending_id)
		_check(String(chosen.get("world_state", "")) == String(ending_definition.get("world_state", "")), "%s selects its authored narrative world state" % ending_id)
		var epilogue: Dictionary = narrative.ending_epilogue()
		_check(String(epilogue.get("epilogue", "")) == String(ending_definition.get("epilogue", "")), "%s exposes its matching authored epilogue" % ending_id)
		var world_for_ending = WorldManager.new()
		world_for_ending.setup(normalized)
		world_for_ending.set_story_flag("final_covenant_made")
		var ending_requirements: Array[String] = ["final_covenant_made"]
		_check(world_for_ending.choose_ending(ending_id, ending_requirements, true), "world manager accepts %s" % ending_id)
		_check(world_for_ending.ending_world_state_id() == String(ending_definition.get("world_state", "")), "%s selects its matching world manager state" % ending_id)
		_check(world_for_ending.world_state() == expected_world_states.get(ending_id, {}), "%s applies its authored world-state effects" % ending_id)
		_check(world_for_ending.continue_sandbox(), "%s supports sandbox continuation" % ending_id)
		if ending_id != "gentle_goodbye":
			_check(narrative.record_ending_memories(ending_id).is_empty(), "%s does not record Gentle Goodbye memories" % ending_id)
	_check(ending_ids.has("keeper") and ending_ids.has("open_door") and ending_ids.has("gentle_goodbye"), "keeper, open door, and gentle goodbye are all authored")
	_test_gentle_goodbye_memories(narrative_script)
	_test_memories_require_gentle_ending(narrative_script)

func _has_ending(endings: Array[Dictionary], ending_id: String) -> bool:
	for ending in endings:
		if String(ending.get("id", "")) == ending_id:
			return true
	return false

func _test_gentle_goodbye_memories(narrative_script: Script) -> void:
	var memory_data := _read_json("res://data/ending_memories.json")
	var memory_definitions: Array = memory_data.get("ending_memories", [])
	var story = narrative_script.new()
	story.begin_shift(1)
	story.flags["final_covenant_made"] = true
	story.choose_ending("gentle_goodbye")
	_check(story.record_ending_memories("gentle_goodbye").is_empty(), "Gentle Goodbye starts without unsupported memories")
	_check(story.ending_memory_route("hidden_midnight_room") == "hidden_midnight_room", "unqualified hidden-room memory has no journal route")
	var hidden_flags: Array[String] = []
	var platform_flags: Array[String] = []
	for memory_value in memory_definitions:
		if not memory_value is Dictionary:
			continue
		var memory: Dictionary = memory_value
		var memory_id := String(memory.get("id", ""))
		if memory_id == "hidden_midnight_room":
			for flag_value in memory.get("requires_flags", []):
				hidden_flags.append(String(flag_value))
		elif memory_id == "midnight_platform":
			for flag_value in memory.get("requires_flags", []):
				platform_flags.append(String(flag_value))
	_check(hidden_flags == ["hidden_midnight_room_found"], "hidden room requires its discovery evidence")
	_check(platform_flags.size() == 4 and platform_flags.has("platform_opened") and platform_flags.has("passenger_manifest_read") and platform_flags.has("midnight_platform_visited") and platform_flags.has("midnight_manifest_read"), "platform memory requires platform visit and manifest inspection evidence")
	for flag_id in hidden_flags:
		story.flags[flag_id] = true
	var hidden_recorded: Array[Dictionary] = story.record_ending_memories("gentle_goodbye")
	_check(_memory_ids(hidden_recorded) == ["hidden_midnight_room"], "only the discovered hidden room qualifies without platform evidence")
	_check(story.ending_memory_route("hidden_midnight_room") == "journal_memory:hidden_midnight_room", "qualified hidden-room memory routes to its journal entry")
	for flag_index in range(platform_flags.size() - 1):
		story.flags[platform_flags[flag_index]] = true
	_check(story.record_ending_memories("gentle_goodbye").is_empty(), "platform memory remains locked until every platform and manifest condition is met")
	_check(story.ending_memory_route("midnight_platform") == "midnight_platform", "incomplete platform evidence has no journal route")
	story.flags[platform_flags.back()] = true
	var platform_recorded: Array[Dictionary] = story.record_ending_memories("gentle_goodbye")
	_check(_memory_ids(platform_recorded) == ["midnight_platform"], "inspected platform and manifest qualify the platform memory")
	_check(_memory_ids(story.ending_memories_for_journal()) == ["hidden_midnight_room", "midnight_platform"], "journal contains only the two qualified Between memories")
	_check(story.ending_memory_route("midnight_platform") == "journal_memory:midnight_platform", "qualified platform memory routes to its journal entry")
	_check(story.record_ending_memories("gentle_goodbye").is_empty(), "qualified memories are recorded only once")

func _test_memories_require_gentle_ending(narrative_script: Script) -> void:
	var story = narrative_script.new()
	story.begin_shift(1)
	story.flags["final_covenant_made"] = true
	story.choose_ending("keeper")
	story.flags["hidden_midnight_room_found"] = true
	story.flags["platform_opened"] = true
	story.flags["passenger_manifest_read"] = true
	story.flags["midnight_platform_visited"] = true
	story.flags["midnight_manifest_read"] = true
	_check(story.record_ending_memories("gentle_goodbye").is_empty(), "qualified Between memories are not recorded after choosing Keeper")
	_check(story.ending_memories_for_journal().is_empty(), "non-Gentle epilogues do not expose Gentle Goodbye journal memories")

func _memory_ids(memories: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for memory in memories:
		ids.append(String(memory.get("id", "")))
	return ids
