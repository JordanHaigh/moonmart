extends Node

const MoonmartGameScript = preload("res://scripts/core/moonmart_game.gd")
const SaveScript = preload("res://scripts/core/save_manager.gd")
const ENDING_WORLD_STATES := {
	"keeper": "sanctuary_between_worlds",
	"open_door": "mixed_community",
	"gentle_goodbye": "ordinary_shop_with_memories"
}

var _checks := 0
var _failures: Array[String] = []
var _game: MoonmartGame
var _clues: Array = []
var _locations: Array = []
var _events: Array = []
var _resolved_promises := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_clues = _read_rows("res://data/clues.json", "clues")
	_locations = _read_rows("res://data/locations.json", "locations")
	_events = _read_rows("res://data/quests.json", "story_events")
	_game = MoonmartGameScript.new()
	add_child(_game)
	await get_tree().process_frame
	_game.relationships.promise_resolved.connect(_on_promise_resolved)
	_expect(_game.shift_number == 0, "fresh game starts at shift zero")
	_expect(_game.story.completed_events.is_empty(), "fresh game has no completed story events")
	var completed_count := 0
	var safety_limit := _events.size() + 5
	while not _game.story.flags.get("final_covenant_made", false) and completed_count < safety_limit:
		if _game.shift_status != "between_shifts":
			_game.clock.tick(_game.clock.shift_minutes / _game.clock.minutes_per_real_second + 1.0)
		_expect(_game.shift_status == "between_shifts", "previous playthrough night closes through the configured clock")
		_game.begin_shift()
		var queue: Array[Dictionary] = _game.quests.queued_encounters()
		if queue.is_empty():
			_expect(false, "story queue schedules the next eligible authored encounter")
			break
		var encounter: Dictionary = queue[0]
		var event_id := String(encounter.get("quest_id", ""))
		var visitor_id := String(encounter.get("visitor", ""))
		_game.customers.tick(15.0, true)
		var customer: Dictionary = _game.customers.get_customer(visitor_id)
		_expect(not customer.is_empty(), "%s spawns its authored essential visitor" % event_id)
		if customer.is_empty():
			break
		var completed_before: int = _game.story.completed_events.size()
		_game.checkout(visitor_id)
		_expect(_game.story.completed_events.has(event_id), "%s resolves through MoonmartGame checkout" % event_id)
		_expect(_game.story.completed_events.size() > completed_before, "%s advances the story event log" % event_id)
		if _game.story.completed_events.has(event_id):
			completed_count += 1
		_collect_available_clues()
		_solve_available_investigations()
		_game.clock.tick(_game.clock.shift_minutes / _game.clock.minutes_per_real_second + 1.0)
	_expect(_game.story.flags.get("final_covenant_made", false), "essential story chain reaches the final covenant")
	_expect(completed_count == _events.size(), "full authored essential encounter chain resolves (%d/%d)" % [completed_count, _events.size()])
	var expected_promises := 0
	for event_value in _events:
		if event_value is Dictionary:
			expected_promises += (event_value as Dictionary).get("resolves_promises", []).size()
	_expect(_resolved_promises == expected_promises, "all authored promise resolutions complete without script errors (%d/%d)" % [_resolved_promises, expected_promises])
	_expect(_game.relationships.all_open_promises().is_empty(), "full campaign leaves no unresolved authored promises")
	_assert_required_story_evidence()
	var endings: Array[Dictionary] = _game.available_endings()
	_expect(endings.size() == 3, "MoonmartGame exposes all three endings after the covenant")
	var covenant_save_committed := _game.save_now()
	var covenant_payload: Dictionary = SaveScript.read_save()
	_expect(covenant_save_committed, "the completed-covenant state commits before an ending is selected")
	_expect(not covenant_payload.is_empty() and bool(covenant_payload.get("story", {}).get("flags", {}).get("final_covenant_made", false)), "the ending integration fixture saves the completed covenant before any ending is selected")
	_game.queue_free()
	await get_tree().process_frame
	_game = null
	for ending_id in ["keeper", "open_door", "gentle_goodbye"]:
		_expect(SaveScript.write_save(covenant_payload), "%s starts from the saved completed-covenant fixture" % ending_id)
		var ending_game := MoonmartGameScript.new() as MoonmartGame
		add_child(ending_game)
		await get_tree().process_frame
		_expect(ending_game.story.flags.get("final_covenant_made", false), "%s fixture reloads the essential covenant" % ending_id)
		var ending_result: Dictionary = ending_game.choose_ending(ending_id)
		_expect(bool(ending_result.get("ok", false)), "MoonmartGame selects %s through its public ending API" % ending_id)
		var expected_world_state := String(ENDING_WORLD_STATES.get(ending_id, ""))
		_expect(ending_game.world_map.ending_id == ending_id and ending_game.world_map.ending_world_state_id() == expected_world_state, "%s applies its authored post-story world state" % ending_id)
		_expect(ending_game.story.ending_epilogue().get("id", "") == ending_id, "%s exposes its matching epilogue" % ending_id)
		_expect(ending_game.travel_to("moonmart"), "%s ending can return to the shop for sandbox play" % ending_id)
		_expect(ending_game.world_map.continue_sandbox(), "%s post-ending world supports sandbox continuation" % ending_id)
		ending_game.begin_shift()
		_expect(ending_game.shift_status == "open", "%s sandbox continuation can start another shop night" % ending_id)
		_expect(ending_game.world_map.ending_id == ending_id and ending_game.world_map.ending_world_state_id() == expected_world_state, "%s sandbox night retains its selected ending world" % ending_id)
		_expect(ending_game.save_now(), "%s sandbox state commits to the save file" % ending_id)
		ending_game.queue_free()
		await get_tree().process_frame
		var restored_game := MoonmartGameScript.new() as MoonmartGame
		add_child(restored_game)
		await get_tree().process_frame
		_expect(restored_game.world_map.ending_id == ending_id, "%s ending selection survives save/load" % ending_id)
		_expect(restored_game.world_map.ending_world_state_id() == expected_world_state and restored_game.story.ending_epilogue().get("id", "") == ending_id, "%s world state and epilogue survive save/load" % ending_id)
		_expect(restored_game.world_map.continue_sandbox() and restored_game.shift_status == "open", "%s resumes the sandbox shift after save/load" % ending_id)
		restored_game.queue_free()
		await get_tree().process_frame
	_write_report(completed_count)
	if _failures.is_empty():
		print("Full story playthrough passed: %d checks, %d essential events." % [_checks, completed_count])
	else:
		for failure in _failures:
			push_error(failure)
		printerr("Full story playthrough failed: %d of %d checks; %d essential events." % [_failures.size(), _checks, completed_count])
	get_tree().quit(0 if _failures.is_empty() else 1)

func _collect_available_clues() -> void:
	var loops := 0
	var changed := true
	while changed and loops < _clues.size() + 2:
		changed = false
		loops += 1
		for clue_value in _clues:
			if not clue_value is Dictionary:
				continue
			var clue: Dictionary = clue_value
			var clue_id := String(clue.get("id", ""))
			if clue_id.is_empty() or _game.story.clues.has(clue_id) or int(clue.get("chapter", 1)) > _game.story.chapter:
				continue
			if not _requirements_met(clue.get("requires_flags", [])):
				continue
			var target := String(clue.get("target", ""))
			var location_id := _location_for_target(target)
			if not location_id.is_empty() and not _game.travel_to(location_id):
				continue
			var before: int = _game.story.clues.size()
			_game.inspect_object(target)
			if _game.story.clues.size() > before:
				changed = true

func _solve_available_investigations() -> void:
	for investigation_id in _game.story.investigation_definitions:
		if bool(_game.story.investigation_state.get(investigation_id, {}).get("completed", false)):
			continue
		var investigation: Dictionary = _game.story.investigation_definitions[investigation_id]
		for hypothesis_value in investigation.get("hypotheses", []):
			if not hypothesis_value is Dictionary:
				continue
			var hypothesis: Dictionary = hypothesis_value
			if not _game.story.investigation_hypothesis_available(hypothesis):
				continue
			var required: Array[String] = []
			var complete := true
			for clue_value in hypothesis.get("required_clues", []):
				var clue_id := String(clue_value)
				required.append(clue_id)
				if not _game.story.clues.has(clue_id):
					complete = false
					break
			if complete:
				_game.connect_clues(String(investigation_id), required)
				break

func _assert_required_story_evidence() -> void:
	for investigation_id in ["pip_identity", "whisperwood_silence", "lucien_and_ada", "wren_sister", "long_midnight", "osric_name", "midnight_platform", "miso_guardian", "lighthouse_beacon", "original_agreement", "boundary"]:
		var state: Dictionary = _game.story.investigation_state.get(String(investigation_id), {})
		_expect(bool(state.get("completed", false)), "required investigation %s is deduced before the ending" % String(investigation_id))
	var harbour_state: Dictionary = _game.story.investigation_state.get("harbour_wishes", {})
	_expect(bool(harbour_state.get("completed", false)), "optional harbour wishes case is deduced during the campaign")
	for clue_id in ["blue_glass_safe_return_token", "net_mender_recognizes_harbour_knot", "empty_boat_carries_a_wish"]:
		_expect(_game.story.clues.has(clue_id), "optional harbour case clue %s is inspected" % clue_id)
	_assert_harbour_is_optional()
	var expanded_cases := {
		"harbour_night_boats": ["net_mender_hears_oars_after_midnight", "empty_boat_hull_is_dry_at_dawn", "washed_beads_line_up_toward_open_water"],
		"whisperwood_shifting_paths": ["moonflowers_lean_toward_the_lost", "cloth_ribbons_beside_the_nests", "grove_roots_settle_into_an_arrow"],
		"unclaimed_drawer": ["unclaimed_drawer_holds_nameless_cards", "returned_envelope_names_an_unclaimed_card", "unclaimed_cards_fill_in_when_remembered"]
	}
	_expect(_game.story.investigation_definitions.size() == 15, "investigation catalog holds all 15 cases")
	for case_id in expanded_cases:
		_expect(bool(_game.story.investigation_state.get(String(case_id), {}).get("completed", false)), "expanded optional investigation %s is deduced during the campaign" % String(case_id))
		for clue_id in expanded_cases[case_id]:
			_expect(_game.story.clues.has(String(clue_id)), "expanded case clue %s is inspected" % String(clue_id))
	for location_id in ["whisperwood", "moonwater_harbour", "midnight_platform", "old_lighthouse"]:
		_expect(_game.story.is_location_unlocked(String(location_id)), "story location %s unlocks during the playthrough" % String(location_id))

func _assert_harbour_is_optional() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
	if not parsed is Dictionary:
		_expect(false, "quest data loads to verify optional ending gates")
		return
	var quest_data: Dictionary = parsed
	var story_events: Array = quest_data.get("story_events", [])
	var ending_definitions: Array = quest_data.get("endings", [])
	var harbour_flag_is_required := false
	var optional_result_flags := ["harbour_wish_remembered", "harbour_night_boats_understood", "harbour_lantern_watch_understood", "whisperwood_paths_understood", "whisperwood_ribbon_route_understood", "unclaimed_drawer_understood", "unclaimed_names_travel_home"]
	for event_value in story_events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if event.get("requires_flags", []).any(func(flag_id): return String(flag_id) in optional_result_flags):
			harbour_flag_is_required = true
	for ending_value in ending_definitions:
		if ending_value is Dictionary and String((ending_value as Dictionary).get("requires_flag", "")) in optional_result_flags:
			harbour_flag_is_required = true
	_expect(not harbour_flag_is_required, "harbour wishes result is not a main-story or ending prerequisite")

func _location_for_target(target: String) -> String:
	for location_value in _locations:
		if not location_value is Dictionary:
			continue
		var location: Dictionary = location_value
		if location.get("interactables", []).has(target):
			return String(location.get("id", ""))
	return ""

func _requirements_met(requirements: Array) -> bool:
	for flag_value in requirements:
		if not bool(_game.story.flags.get(String(flag_value), false)):
			return false
	return true

func _read_rows(path: String, key: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and parsed.get(key, []) is Array:
		return parsed[key]
	return []

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)

func _on_promise_resolved(_character_id: String, _promise_id: String, _kept: bool) -> void:
	_resolved_promises += 1

func _write_report(completed_count: int) -> void:
	var report := FileAccess.open("user://story_playthrough_report.txt", FileAccess.WRITE)
	if report != null:
		report.store_string("checks=%d\nfailures=%d\nessential_events=%d\n" % [_checks, _failures.size(), completed_count])
		for failure in _failures:
			report.store_line("FAIL: " + failure)
		report.close()
