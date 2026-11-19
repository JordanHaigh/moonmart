extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const NarrativeManager = preload("res://scripts/systems/narrative_manager.gd")

const FIXTURE_ROOT := "user://moonmart_test_fixtures"
const FIXED_SAVE_PATHS := [
	"user://moonmart_save.json",
	"user://moonmart_save.tmp",
	"user://moonmart_save.replace",
	"user://moonmart_save.recovered",
	"user://moonmart_save.recovered.tmp",
	"user://moonmart_save.recovered.replace",
	"user://moonmart_save.bak",
	"user://moonmart_save.bak.tmp",
	"user://moonmart_save.bak.replace"
]

var _failures := 0
var _owned_paths: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _preflight_isolated_paths():
		quit(2)
		return
	_make_fixture_dir()
	_test_schema_migrations()
	_test_invalid_and_future_schemas()
	_test_atomic_save_and_backup_recovery()
	_test_backup_staging_recovery()
	_cleanup_owned_paths()
	if _failures == 0:
		print("Save manager headless checks passed.")
		await process_frame
		quit(0)
	else:
		push_error("Save manager headless checks failed: %d" % _failures)
		await process_frame
		quit(1)

func _preflight_isolated_paths() -> bool:
	for path in FIXED_SAVE_PATHS:
		if FileAccess.file_exists(path):
			push_error("Refusing to run save fixtures because user save path already exists: %s" % path)
			return false
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)):
		push_error("Refusing to overwrite an existing save test fixture directory.")
		return false
	var directory := DirAccess.open("user://")
	if directory != null:
		directory.list_dir_begin()
		var filename := directory.get_next()
		while not filename.is_empty():
			if filename.begins_with("moonmart_save_unreadable_") and filename.ends_with(".json"):
				directory.list_dir_end()
				push_error("Refusing to run with a pre-existing unreadable-save archive in the isolated user-data folder.")
				return false
			filename = directory.get_next()
		directory.list_dir_end()
	# All fixed paths were confirmed absent above, so any that SaveManager creates
	# during this isolated run belong to this test and may be removed on cleanup.
	_owned_paths.assign(FIXED_SAVE_PATHS)
	return true

func _make_fixture_dir() -> void:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT))
	_check(error == OK, "fixture directory created")

func _test_schema_migrations() -> void:
	var legacy := {
		"shift_number": 2,
		"inventory": {"stock": {}},
		"customers": {"seen": {}}
	}
	var legacy_result := _read_fixture("legacy_v0.json", JSON.stringify(legacy))
	_check(bool(legacy_result.get("ok", false)), "unversioned save migrates")
	_check(int(legacy_result.get("payload", {}).get("inventory", {}).get("transactions", []).size()) == 0, "v0 gains inventory transactions")
	_check(legacy_result.get("payload", {}).get("miso_companion", {}) is Dictionary, "v0 gains companion state")

	var v1 := _envelope(1, {"inventory": {"stock": {}}, "customers": {"seen": {}}})
	var v1_result := _read_fixture("schema_v1.json", JSON.stringify(v1))
	_check(bool(v1_result.get("ok", false)) and v1_result.get("status") == "migrated", "schema v1 migrates")
	_check(v1_result.get("payload", {}).get("customers", {}).has("spawn_timer"), "v1 gains customer schedule state")

	var v2_payload := {"inventory": {"stock": {}, "transactions": [], "prepared_items": {}}, "customers": {"seen": {}, "rng_state": 0, "active_shift": 1, "spawn_timer": 14.0}}
	var v2_result := _read_fixture("schema_v2.json", JSON.stringify(_envelope(2, v2_payload)))
	_check(bool(v2_result.get("ok", false)) and v2_result.get("payload", {}).has("pending_optional_events"), "schema v2 gains optional event state")
	_check(v2_result.get("payload", {}).has("optional_event_timer"), "schema v2 gains optional event timer")

	var v3_payload := v2_payload.duplicate(true)
	v3_payload["pending_optional_events"] = []
	v3_payload["optional_event_timer"] = 38.0
	var v3_result := _read_fixture("schema_v3.json", JSON.stringify(_envelope(3, v3_payload)))
	_check(bool(v3_result.get("ok", false)) and v3_result.get("payload", {}).has("miso_companion"), "schema v3 gains Miso state")
	_check(v3_result.get("payload", {}).has("cleaning_actions_this_shift"), "schema v3 gains shift cleaning state")

	var v4_payload: Dictionary = (v3_result.get("payload", {}) as Dictionary).duplicate(true)
	var v4_result := _read_fixture("schema_v4.json", JSON.stringify(_envelope(4, v4_payload)))
	_check(bool(v4_result.get("ok", false)) and v4_result.get("status") == "loaded", "current schema loads without migration")

func _test_invalid_and_future_schemas() -> void:
	var bad_shape := _envelope(4, {"inventory": {"stock": []}})
	var malformed_result := _read_fixture("malformed_known_field.json", JSON.stringify(bad_shape))
	_check(not bool(malformed_result.get("ok", false)) and malformed_result.get("status") == "corrupt", "malformed known nested field is rejected")

	var bad_lots := _envelope(4, {"inventory": {"stock_lots": {"tea": {"not": "an array"}}}})
	var lots_result := _read_fixture("malformed_stock_lots.json", JSON.stringify(bad_lots))
	_check(not bool(lots_result.get("ok", false)) and String(lots_result.get("error", "")).contains("stock_lots.tea"), "malformed freshness lots are rejected with field context")
	var valid_carried := _minimal_payload(0)
	valid_carried["inventory"]["carried_item"] = {"product_id":"milk", "quantity":1}
	var carried_result := _read_fixture("saved_carried_stock.json", JSON.stringify(_envelope(3, valid_carried)))
	_check(bool(carried_result.get("ok", false)) and carried_result.get("payload", {}).get("inventory", {}).get("carried_item", {}).get("product_id", "") == "milk", "a valid held stock item passes current-save validation (%s)" % String(carried_result.get("error", "")))
	var malformed_carried := _minimal_payload(0)
	malformed_carried["inventory"]["carried_item"] = {"product_id":"milk", "quantity":0}
	var malformed_carried_result := _read_fixture("malformed_carried_stock.json", JSON.stringify(_envelope(3, malformed_carried)))
	_check(not bool(malformed_carried_result.get("ok", false)) and String(malformed_carried_result.get("error", "")).contains("carried_item.quantity"), "invalid held stock quantity is rejected with field context (%s)" % String(malformed_carried_result.get("error", "")))
	var malformed_carried_shape := _minimal_payload(0)
	malformed_carried_shape["inventory"]["carried_item"] = 1
	var malformed_carried_shape_result := _read_fixture("malformed_carried_stock_shape.json", JSON.stringify(_envelope(3, malformed_carried_shape)))
	_check(not bool(malformed_carried_shape_result.get("ok", false)) and String(malformed_carried_shape_result.get("error", "")).contains("carried_item must be a dictionary"), "non-dictionary held stock state is rejected without a validation crash")
	var saved_player_positions := _minimal_payload(0)
	saved_player_positions["player_positions"] = {"moonmart":{"x":1042.5,"y":748.0}, "shop_backroom":{"x":127.0,"y":711.0}}
	var saved_positions_result := _read_fixture("saved_player_positions.json", JSON.stringify(_envelope(4, saved_player_positions)))
	_check(bool(saved_positions_result.get("ok", false)) and saved_positions_result.get("payload", {}).get("player_positions", {}).get("moonmart", {}).get("x", -1.0) == 1042.5, "per-location player positions pass current-save validation")
	var malformed_player_positions := _minimal_payload(0)
	malformed_player_positions["player_positions"] = {"moonmart":{"x":"east", "y":700}}
	var malformed_positions_result := _read_fixture("malformed_player_positions.json", JSON.stringify(_envelope(4, malformed_player_positions)))
	_check(not bool(malformed_positions_result.get("ok", false)) and String(malformed_positions_result.get("error", "")).contains("player_positions.moonmart.x"), "malformed saved player position is rejected with location and axis context")
	var valid_ending_memory_payload := _minimal_payload(0)
	valid_ending_memory_payload["story"] = {
		"flags":{"hidden_midnight_room_found":true},
		"relationships":{},
		"investigation_state":{},
		"selected_ending":"gentle_goodbye",
		"ending_memories":{"hidden_midnight_room":{
			"id":"hidden_midnight_room",
			"activity_id":"hidden_midnight_room",
			"title":"The Hidden Midnight Room",
			"text":"The doorway is closed, but its welcome remains part of Moonmart."
		}}
	}
	var valid_ending_memory_result := _read_fixture("saved_ending_memory.json", JSON.stringify(_envelope(4, valid_ending_memory_payload)))
	_check(bool(valid_ending_memory_result.get("ok", false)), "a complete ending-memory snapshot with its qualifying flag passes save validation")
	if bool(valid_ending_memory_result.get("ok", false)):
		var restored_story = NarrativeManager.new()
		restored_story.from_save(valid_ending_memory_result.payload.story)
		_check(restored_story.ending_memory_route("hidden_midnight_room") == "journal_memory:hidden_midnight_room", "a valid saved ending-memory snapshot restores its journal route")
	var unsupported_ending_memory_payload := _minimal_payload(0)
	unsupported_ending_memory_payload["story"] = {
		"flags":{"final_covenant_made":true},
		"relationships":{},
		"investigation_state":{},
		"selected_ending":"gentle_goodbye",
		"ending_memories":{"midnight_platform":{}}
	}
	var unsupported_ending_memory_result := _read_fixture("unsupported_ending_memory.json", JSON.stringify(_envelope(4, unsupported_ending_memory_payload)))
	_check(not bool(unsupported_ending_memory_result.get("ok", false)) and String(unsupported_ending_memory_result.get("error", "")).contains("ending_memories.midnight_platform"), "an empty snapshot cannot manufacture an ending-memory route")
	var routed_story = NarrativeManager.new()
	if bool(unsupported_ending_memory_result.get("ok", false)):
		routed_story.from_save(unsupported_ending_memory_result.payload.story)
	else:
		routed_story.from_save({"flags":{"final_covenant_made":true}, "selected_ending":"gentle_goodbye"})
	_check(routed_story.ending_memory_route("midnight_platform") == "midnight_platform", "rejected snapshot data never enters the imported journal route")
	var mismatched_ending_memory_payload := _minimal_payload(0)
	mismatched_ending_memory_payload["story"] = {
		"flags":{"final_covenant_made":true},
		"relationships":{},
		"investigation_state":{},
		"selected_ending":"gentle_goodbye",
		"ending_memories":{"midnight_platform":{
			"id":"hidden_midnight_room",
			"activity_id":"midnight_platform",
			"title":"The Midnight Platform",
			"text":"A snapshot whose ID does not match its saved key."
		}}
	}
	var mismatched_ending_memory_result := _read_fixture("mismatched_ending_memory.json", JSON.stringify(_envelope(4, mismatched_ending_memory_payload)))
	_check(not bool(mismatched_ending_memory_result.get("ok", false)) and String(mismatched_ending_memory_result.get("error", "")).contains("does not match its authored identity"), "snapshot fields must match the authored ending-memory identity")
	var unknown_ending_memory_payload := _minimal_payload(0)
	unknown_ending_memory_payload["story"] = {
		"flags":{"final_covenant_made":true},
		"relationships":{},
		"investigation_state":{},
		"selected_ending":"gentle_goodbye",
		"ending_memories":{"unlisted_place":{"id":"unlisted_place", "activity_id":"unlisted_place", "title":"Unlisted Place", "text":"Not authored."}}
	}
	var unknown_ending_memory_result := _read_fixture("unknown_ending_memory.json", JSON.stringify(_envelope(4, unknown_ending_memory_payload)))
	_check(not bool(unknown_ending_memory_result.get("ok", false)) and String(unknown_ending_memory_result.get("error", "")).contains("is not an authored memory"), "unknown ending-memory keys cannot create journal routes")
	var legacy_ending_memory_payload := _minimal_payload(0)
	legacy_ending_memory_payload["story"] = {"flags":{"final_covenant_made":true, "hidden_midnight_room_found":true}, "relationships":{}, "investigation_state":{}, "selected_ending":"gentle_goodbye"}
	var legacy_ending_memory_result := _read_fixture("legacy_ending_memory_flags.json", JSON.stringify(_envelope(3, legacy_ending_memory_payload)))
	_check(bool(legacy_ending_memory_result.get("ok", false)) and not legacy_ending_memory_result.payload.story.has("ending_memories"), "legacy Gentle Goodbye saves without snapshots remain loadable")
	if bool(legacy_ending_memory_result.get("ok", false)):
		var migrated_ending_story = NarrativeManager.new()
		migrated_ending_story.from_save(legacy_ending_memory_result.payload.story)
		_check(migrated_ending_story.ending_memory_route("hidden_midnight_room") == "journal_memory:hidden_midnight_room", "legacy memories still reconstruct from qualifying saved flags")

	var bad_spirit_sense := _envelope(4, {"miso_spirit_sense_reaction_shifts":{"lucien":"five"}})
	var spirit_sense_result := _read_fixture("malformed_spirit_sense_repeats.json", JSON.stringify(bad_spirit_sense))
	_check(not bool(spirit_sense_result.get("ok", false)) and String(spirit_sense_result.get("error", "")).contains("miso_spirit_sense_reaction_shifts.lucien"), "malformed saved Spirit Sense repeat guard is rejected")
	var whole_float_spirit_sense := _minimal_payload(0)
	whole_float_spirit_sense["miso_spirit_sense_reaction_shifts"] = {"lucien":12.0}
	var whole_float_spirit_sense_result := _read_fixture("integral_spirit_sense_shift.json", JSON.stringify(_envelope(4, whole_float_spirit_sense)))
	var normalized_spirit_shift: Variant = whole_float_spirit_sense_result.get("payload", {}).get("miso_spirit_sense_reaction_shifts", {}).get("lucien", null)
	_check(bool(whole_float_spirit_sense_result.get("ok", false)) and normalized_spirit_shift is int and int(normalized_spirit_shift) == 12, "integral JSON Spirit Sense shifts are normalized to integer save state")
	var fractional_spirit_sense := _minimal_payload(0)
	fractional_spirit_sense["miso_spirit_sense_reaction_shifts"] = {"lucien":12.5}
	var fractional_spirit_sense_result := _read_fixture("fractional_spirit_sense_shift.json", JSON.stringify(_envelope(4, fractional_spirit_sense)))
	_check(not bool(fractional_spirit_sense_result.get("ok", false)) and String(fractional_spirit_sense_result.get("error", "")).contains("miso_spirit_sense_reaction_shifts.lucien"), "fractional Spirit Sense shifts remain invalid")

	var bad_disturbance := _envelope(4, {"anomaly_disturbances":[{"event_id":"flicker_lights", "shift_number":"four"}]})
	var disturbance_result := _read_fixture("malformed_anomaly_disturbances.json", JSON.stringify(bad_disturbance))
	_check(not bool(disturbance_result.get("ok", false)) and String(disturbance_result.get("error", "")).contains("anomaly_disturbances[0].shift_number"), "malformed saved anomaly disturbance is rejected")
	var malformed_anomaly_resolutions := _envelope(4, {"resolved_anomaly_investigations":["receipt_whispers", 3]})
	var anomaly_resolutions_result := _read_fixture("malformed_anomaly_resolutions.json", JSON.stringify(malformed_anomaly_resolutions))
	_check(not bool(anomaly_resolutions_result.get("ok", false)) and String(anomaly_resolutions_result.get("error", "")).contains("resolved_anomaly_investigations[1]"), "malformed saved optional anomaly resolution is rejected")

	var valid_hidden_paw := _envelope(4, {"miso_hidden_paw_guidance":{"clue_id":"door_in_the_wall", "target_id":"back_door", "marker_id":"back_door", "location_id":"moonmart"}})
	var hidden_paw_result := _read_fixture("saved_hidden_paw_guidance.json", JSON.stringify(valid_hidden_paw))
	_check(bool(hidden_paw_result.get("ok", false)) and hidden_paw_result.get("payload", {}).get("miso_hidden_paw_guidance", {}).get("target_id", "") == "back_door", "saved Hidden Paw guidance round-trips through the current schema")
	var malformed_hidden_paw := _envelope(4, {"miso_hidden_paw_guidance":{"clue_id":"door_in_the_wall", "target_id":"back_door", "marker_id":9, "location_id":"moonmart"}})
	var malformed_hidden_paw_result := _read_fixture("malformed_hidden_paw_guidance.json", JSON.stringify(malformed_hidden_paw))
	_check(not bool(malformed_hidden_paw_result.get("ok", false)) and String(malformed_hidden_paw_result.get("error", "")).contains("miso_hidden_paw_guidance.marker_id"), "malformed saved Hidden Paw guidance is rejected")

	var future := _envelope(5, {"inventory": {"stock": {"tea": 3}}})
	var future_result := _read_fixture("future_schema.json", JSON.stringify(future))
	_check(not bool(future_result.get("ok", false)) and future_result.get("status") == "future_version", "future schema is preserved as unsupported")

	var nonnumeric := {"schema_version": "four", "game": {}}
	var nonnumeric_result := _read_fixture("nonnumeric_schema.json", JSON.stringify(nonnumeric))
	_check(not bool(nonnumeric_result.get("ok", false)) and nonnumeric_result.get("status") == "corrupt", "nonnumeric schema is rejected")

func _test_atomic_save_and_backup_recovery() -> void:
	var first_payload := _minimal_payload(11)
	print("START: atomic save checks")
	var first_save_ok := SaveManager.write_save(first_payload)
	print("INFO: initial write returned %s (%s)" % [str(first_save_ok), SaveManager.read_error()])
	_check(first_save_ok, "initial verified save commits")
	_check(FileAccess.file_exists(SaveManager.SAVE_PATH), "initial save exists")
	_check(SaveManager.write_save(_minimal_payload(22)), "second save commits after backup")
	var backup := SaveManager._read_path(SaveManager.BACKUP_PATH)
	_check(bool(backup.get("ok", false)) and int(backup.get("payload", {}).get("coins", -1)) == 11, "last-known-good backup contains prior state")

	_check(_write_fixture(SaveManager.SAVE_PATH, "not valid json"), "corrupt primary fixture written")
	var recovered := SaveManager.read_save()
	_check(int(recovered.get("coins", -1)) == 11 and SaveManager.read_status() == "recovered_backup", "corrupt primary recovers verified backup")
	_check(SaveManager.write_save(_minimal_payload(33)), "verified backup recovery can commit a new save")
	_check(SaveManager.read_status() == "loaded", "recovery commit returns to loaded state")
	_check(_has_unreadable_archive(), "unreadable primary is archived intact")

func _test_backup_staging_recovery() -> void:
	_cleanup_fixed_save_paths()
	_check(_write_fixture(SaveManager.BACKUP_TEMP_PATH, JSON.stringify(_envelope(4, _minimal_payload(44)))), "backup temp fixture written")
	var backup_temp_result := SaveManager.read_save()
	_check(int(backup_temp_result.get("coins", -1)) == 44 and SaveManager.read_status() == "recovered_backup", "verified backup temp is a recovery candidate")

	_cleanup_fixed_save_paths()
	_check(_write_fixture(SaveManager.BACKUP_STAGE_PATH, JSON.stringify(_envelope(4, _minimal_payload(55)))), "backup stage fixture written")
	var backup_stage_result := SaveManager.read_save()
	_check(int(backup_stage_result.get("coins", -1)) == 55 and SaveManager.read_status() == "recovered_backup", "verified backup rollback stage is a recovery candidate")

func _read_fixture(filename: String, contents: String) -> Dictionary:
	var path := "%s/%s" % [FIXTURE_ROOT, filename]
	if not _write_fixture(path, contents):
		return {"ok": false, "status": "fixture_write_failed", "error": path}
	return SaveManager._read_path(path)

func _write_fixture(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	var okay := file.get_error() == OK
	file.close()
	if okay and not _owned_paths.has(path):
		_owned_paths.append(path)
	return okay

func _minimal_payload(coins: int) -> Dictionary:
	return {"coins": coins, "inventory": {"stock": {}}, "customers": {"seen": {}}}

func _envelope(version: int, payload: Dictionary) -> Dictionary:
	return {"schema_version": version, "game": payload}

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)

func _cleanup_fixed_save_paths() -> void:
	for path in FIXED_SAVE_PATHS:
		if FileAccess.file_exists(path):
			if not _owned_paths.has(path):
				_owned_paths.append(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _has_unreadable_archive() -> bool:
	for _attempt in range(10):
		for filename in DirAccess.get_files_at(ProjectSettings.globalize_path("user://")):
			if filename.begins_with("moonmart_save_unreadable_") and filename.ends_with(".json"):
				var archive_path := "user://%s" % filename
				_owned_paths.append(archive_path)
				if FileAccess.get_file_as_string(archive_path) == "not valid json":
					return true
		OS.delay_msec(10)
	return false

func _cleanup_owned_paths() -> void:
	for path in _owned_paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT))
