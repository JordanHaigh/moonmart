extends SceneTree

const SettingsManager = preload("res://scripts/systems/settings_manager.gd")
const FIXED_PATHS := [
	"user://moonmart_settings.json",
	"user://moonmart_settings.tmp",
	"user://moonmart_settings.replace"
]

var _checks := 0
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _preflight():
		quit(2)
		return
	_test_legacy_migration_and_verified_write()
	_test_future_schema_is_read_only()
	_test_malformed_primary_is_preserved()
	_test_interrupted_write_recovery()
	_test_corrupt_primary_archive_and_stage_recovery()
	_test_invalid_stage_locks_writes()
	_cleanup()
	if _failures.is_empty():
		print("Settings manager headless checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Settings manager headless checks failed: %d of %d." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)

func _preflight() -> bool:
	for path in FIXED_PATHS:
		if FileAccess.file_exists(path):
			push_error("Refusing to run settings fixtures over existing user data: %s" % path)
			return false
	var directory := DirAccess.open("user://")
	if directory == null:
		# A fresh isolated Godot profile may not have created user:// yet.
		# FileAccess checks above already confirmed that no settings artifacts exist.
		return true
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if filename.begins_with("moonmart_settings_unreadable_") and filename.ends_with(".json"):
			directory.list_dir_end()
			push_error("Refusing to run with a pre-existing settings archive in user://")
			return false
		filename = directory.get_next()
	directory.list_dir_end()
	return true

func _test_legacy_migration_and_verified_write() -> void:
	_write(SettingsManager.SETTINGS_PATH, JSON.stringify({"music_volume": 2.0, "ui_scale": 0.5, "radio_station_id": "unknown_station"}))
	var manager = SettingsManager.new()
	manager.load_settings()
	_check(is_equal_approx(float(manager.get_setting("music_volume")), 1.0), "legacy settings load and sanitize volume")
	_check(is_equal_approx(float(manager.get_setting("ui_scale")), 0.75), "legacy settings load and sanitize UI scale")
	_check(manager.get_setting("radio_station_id") == "bellwether_after_hours", "invalid legacy station falls back to a known station")
	_check(manager.set_setting("reduced_animation", true), "valid preference saves through the verified writer")
	var current := _read_dictionary(SettingsManager.SETTINGS_PATH)
	_check(int(current.get("schema_version", -1)) == SettingsManager.SCHEMA_VERSION, "legacy settings are rewritten with the current schema")
	_check(bool(current.get("settings", {}).get("reduced_animation", false)), "verified write contains the updated preference")
	_check(not FileAccess.file_exists(SettingsManager.SETTINGS_TEMP_PATH) and not FileAccess.file_exists(SettingsManager.SETTINGS_STAGE_PATH), "successful write removes staging artifacts")
	_clear_fixed()

func _test_future_schema_is_read_only() -> void:
	var original := JSON.stringify({"schema_version": SettingsManager.SCHEMA_VERSION + 1, "settings": {"music_volume": 0.25, "unrecognized_future_field": "keep"}})
	_write(SettingsManager.SETTINGS_PATH, original)
	var manager = SettingsManager.new()
	manager.load_settings()
	_check(is_equal_approx(float(manager.get_setting("music_volume")), 0.25), "known preferences remain readable from a future schema")
	_check(not manager.set_setting("music_volume", 0.9), "future-schema settings reject writes")
	_check(FileAccess.get_file_as_string(SettingsManager.SETTINGS_PATH) == original, "future-schema file remains byte-for-byte unchanged")
	_clear_fixed()

func _test_malformed_primary_is_preserved() -> void:
	var original := "not valid settings json"
	_write(SettingsManager.SETTINGS_PATH, original)
	var manager = SettingsManager.new()
	manager.load_settings()
	_check(manager.get_setting("radio_station_id") == "bellwether_after_hours", "malformed settings fall back to safe defaults for this session")
	_check(not manager.set_setting("music_volume", 0.4), "malformed settings lock preference writes")
	_check(FileAccess.get_file_as_string(SettingsManager.SETTINGS_PATH) == original, "malformed primary remains untouched without a verified recovery file")
	_clear_fixed()

func _test_interrupted_write_recovery() -> void:
	var staged := _envelope({"music_volume": 0.42, "reduced_flashing": true})
	_write(SettingsManager.SETTINGS_TEMP_PATH, JSON.stringify(staged))
	var manager = SettingsManager.new()
	manager.load_settings()
	_check(FileAccess.file_exists(SettingsManager.SETTINGS_PATH), "valid staged settings promote when the primary is missing")
	_check(is_equal_approx(float(manager.get_setting("music_volume")), 0.42), "promoted staged settings load into the manager")
	_check(bool(manager.get_setting("reduced_flashing")), "promoted staged settings retain accessibility preferences")
	_check(manager.set_setting("music_volume", 0.5), "recovered current settings remain writable")
	_clear_fixed()

func _test_corrupt_primary_archive_and_stage_recovery() -> void:
	_write(SettingsManager.SETTINGS_PATH, "corrupt primary")
	_write(SettingsManager.SETTINGS_STAGE_PATH, JSON.stringify(_envelope({"music_volume": 0.63})))
	var manager = SettingsManager.new()
	manager.load_settings()
	_check(is_equal_approx(float(manager.get_setting("music_volume")), 0.63), "verified stage restores preferences over a corrupt primary")
	_check(_has_archive_with_text("corrupt primary"), "corrupt primary is preserved in a unique archive")
	_check(manager.set_setting("music_volume", 0.7), "settings restored from a verified stage remain writable")
	_clear_fixed()
	_remove_archives()

func _test_invalid_stage_locks_writes() -> void:
	var invalid := "bad staged json"
	_write(SettingsManager.SETTINGS_TEMP_PATH, invalid)
	var manager = SettingsManager.new()
	manager.load_settings()
	_check(not manager.set_setting("music_volume", 0.35), "invalid interrupted stage locks later writes")
	_check(FileAccess.get_file_as_string(SettingsManager.SETTINGS_TEMP_PATH) == invalid, "invalid stage remains intact for diagnosis")
	_clear_fixed()

func _envelope(settings: Dictionary) -> Dictionary:
	return {"schema_version": SettingsManager.SCHEMA_VERSION, "settings": settings}

func _write(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "fixture writes to %s" % path)
		return
	file.store_string(contents)
	file.flush()
	var okay := file.get_error() == OK
	file.close()
	_check(okay, "fixture writes to %s" % path)

func _read_dictionary(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _has_archive_with_text(expected: String) -> bool:
	for _attempt in range(10):
		for filename in DirAccess.get_files_at(ProjectSettings.globalize_path("user://")):
			if filename.begins_with("moonmart_settings_unreadable_") and filename.ends_with(".json"):
				var path := "user://%s" % filename
				var contents := FileAccess.get_file_as_string(path)
				if not contents.is_empty():
					return contents == expected
		OS.delay_msec(10)
	return false

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: %s" % description)
	else:
		_failures.append(description)

func _clear_fixed() -> void:
	for path in FIXED_PATHS:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _remove_archives() -> void:
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path("user://")):
		if filename.begins_with("moonmart_settings_unreadable_") and filename.ends_with(".json"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://%s" % filename))

func _cleanup() -> void:
	_clear_fixed()
	_remove_archives()
