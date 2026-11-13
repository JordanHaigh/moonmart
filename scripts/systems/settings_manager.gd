class_name MoonmartSettings
extends RefCounted

## User preferences are intentionally stored separately from a story save.
signal setting_changed(key: String, value: Variant)
signal settings_loaded
signal settings_saved
signal settings_save_failed

const SETTINGS_PATH := "user://moonmart_settings.json"
const SETTINGS_TEMP_PATH := "user://moonmart_settings.tmp"
const SETTINGS_STAGE_PATH := "user://moonmart_settings.replace"
const SCHEMA_VERSION := 1
const HINT_LEVELS := ["none", "contextual", "guided"]
const RADIO_STATION_IDS := ["window_seat", "bellwether_after_hours", "harbour_hush"]
const REBINDABLE_ACTIONS := [
	"move_left", "move_right", "move_up", "move_down", "interact", "inspect", "run",
	"ledger", "town_map", "mystery_board", "calendar", "housekeeping", "upgrades", "journal", "inventory", "pause",
	"radio", "companion", "decorate", "ui_back",
	"ui_select_1", "ui_select_2", "ui_select_3", "ui_select_4", "ui_select_5", "ui_select_6", "ui_select_7", "ui_select_8", "ui_select_9",
	"decoration_rotate", "decoration_remove", "mystery_pin", "puzzle_submit",
	"stock_restock", "stock_restock_all", "stock_markdown", "stock_markdown_clear", "stock_donate", "stock_donate_all",
	"page_previous", "page_next", "ledger_refund"
]
const DEFAULTS := {
	"game_speed": 1.0,
	"assisted_checkout": false,
	"simplified_crafting": false,
	"auto_stock": {"enabled": false, "targets": {}},
	"ui_scale": 1.0,
	"dyslexia_friendly_text": false,
	"reduced_animation": false,
	"reduced_flashing": false,
	"visual_effects_enabled": true,
	"dynamic_lighting": true,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"radio_station_id": "bellwether_after_hours",
	"mystery_hint_level": "contextual",
	"input_remaps": {}
}

var values: Dictionary = {}
var _default_bindings: Dictionary = {}
var _settings_read_only := false

func setup() -> void:
	_capture_default_bindings()
	load_settings()

func load_settings() -> void:
	_capture_default_bindings()
	_settings_read_only = false
	_recover_interrupted_write()
	values = DEFAULTS.duplicate(true)
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file == null:
			_settings_read_only = true
		else:
			var parser := JSON.new()
			var parse_error := parser.parse(file.get_as_text())
			var read_error := file.get_error()
			file.close()
			var parsed: Variant = parser.data
			if parse_error != OK or read_error != OK or not parsed is Dictionary:
				_settings_read_only = true
			else:
				var versioned: bool = parsed.has("schema_version")
				if versioned:
					var schema_value: Variant = parsed.get("schema_version")
					var numeric_schema := schema_value is int or schema_value is float
					var schema_number := float(schema_value) if numeric_schema else -1.0
					var integer_schema := numeric_schema and not is_nan(schema_number) and not is_inf(schema_number) and floorf(schema_number) == schema_number
					if not integer_schema or int(schema_number) < 0 or int(schema_number) > SCHEMA_VERSION:
						# Read known preferences for this session, but never overwrite
						# fields owned by an unsupported or invalid file format.
						_settings_read_only = true
					if not parsed.get("settings", null) is Dictionary:
						_settings_read_only = true
				var raw: Variant = parsed.get("settings", parsed)
				if raw is Dictionary:
					for key in DEFAULTS:
						if raw.has(key):
							values[key] = _sanitize(key, raw[key])
				else:
					_settings_read_only = true
	_apply_input_remaps()
	settings_loaded.emit()

func _recover_interrupted_write() -> void:
	var has_primary := FileAccess.file_exists(SETTINGS_PATH)
	if has_primary and _settings_primary_is_readable_or_future():
		_lock_for_invalid_staged_settings()
		return
	if has_primary:
		if _restore_verified_candidate_over_invalid_primary():
			_lock_for_invalid_staged_settings()
			return
		_settings_read_only = true
		return
	# A process can exit after the current file is moved aside but before the
	# staged settings take its place. Prefer the fully written, verified stage;
	# if it is missing or invalid, restore the last known good file.
	if FileAccess.file_exists(SETTINGS_TEMP_PATH) and _verify_settings_file(SETTINGS_TEMP_PATH):
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(SETTINGS_TEMP_PATH), ProjectSettings.globalize_path(SETTINGS_PATH)) == OK:
			_lock_for_invalid_staged_settings()
			return
	if FileAccess.file_exists(SETTINGS_STAGE_PATH) and _verify_settings_file(SETTINGS_STAGE_PATH):
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(SETTINGS_STAGE_PATH), ProjectSettings.globalize_path(SETTINGS_PATH)) == OK:
			_lock_for_invalid_staged_settings()
			return
	# An invalid staged file is still evidence of an interrupted write. Keep it
	# untouched and prevent defaults from replacing it on the next preference edit.
	if FileAccess.file_exists(SETTINGS_TEMP_PATH) or FileAccess.file_exists(SETTINGS_STAGE_PATH):
		_settings_read_only = true

func _lock_for_invalid_staged_settings() -> void:
	for path in [SETTINGS_TEMP_PATH, SETTINGS_STAGE_PATH]:
		if FileAccess.file_exists(path) and not _verify_settings_file(path):
			_settings_read_only = true

func _restore_verified_candidate_over_invalid_primary() -> bool:
	var candidate_path := ""
	for path in [SETTINGS_TEMP_PATH, SETTINGS_STAGE_PATH]:
		if FileAccess.file_exists(path) and _verify_settings_file(path):
			candidate_path = path
			break
	if candidate_path.is_empty():
		return false
	var archive_path := "user://moonmart_settings_unreadable_%d_%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(SETTINGS_PATH), ProjectSettings.globalize_path(archive_path)) != OK:
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(candidate_path), ProjectSettings.globalize_path(SETTINGS_PATH)) != OK:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(archive_path), ProjectSettings.globalize_path(SETTINGS_PATH))
		return false
	return true

func _settings_primary_is_readable_or_future() -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return false
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	var read_error := file.get_error()
	file.close()
	if parse_error != OK or read_error != OK or not parser.data is Dictionary:
		return false
	var parsed: Dictionary = parser.data
	if not parsed.has("schema_version"):
		return true # Legacy unwrapped settings remain a supported format.
	var schema_value: Variant = parsed.get("schema_version")
	if not (schema_value is int or schema_value is float):
		return false
	var schema_number := float(schema_value)
	if is_nan(schema_number) or is_inf(schema_number) or floorf(schema_number) != schema_number:
		return false
	if int(schema_number) > SCHEMA_VERSION:
		return true # Never replace a parseable future-schema settings file.
	return parsed.get("settings") is Dictionary # Older integer schemas remain loadable and are normalized on save.

func save_settings() -> bool:
	if _settings_read_only:
		settings_save_failed.emit()
		return false
	_remove_file(SETTINGS_TEMP_PATH)
	var encoded := JSON.stringify({"schema_version": SCHEMA_VERSION, "settings": values}, "\t")
	if not _write_text(SETTINGS_TEMP_PATH, encoded):
		_remove_file(SETTINGS_TEMP_PATH)
		settings_save_failed.emit()
		return false
	if not _verify_settings_file(SETTINGS_TEMP_PATH):
		_remove_file(SETTINGS_TEMP_PATH)
		settings_save_failed.emit()
		return false
	if not _replace_atomically(SETTINGS_TEMP_PATH, SETTINGS_PATH, SETTINGS_STAGE_PATH):
		_remove_file(SETTINGS_TEMP_PATH)
		settings_save_failed.emit()
		return false
	settings_saved.emit()
	return true

func _verify_settings_file(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	var read_error := file.get_error()
	file.close()
	if parse_error != OK or read_error != OK or not parser.data is Dictionary:
		return false
	var parsed: Dictionary = parser.data
	var schema_value: Variant = parsed.get("schema_version", null)
	if not (schema_value is int or schema_value is float):
		return false
	var schema_number := float(schema_value)
	if is_nan(schema_number) or is_inf(schema_number) or floorf(schema_number) != schema_number:
		return false
	return int(schema_number) == SCHEMA_VERSION and parsed.get("settings") is Dictionary

func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	return write_error == OK

func _replace_atomically(source_path: String, destination_path: String, rollback_path: String) -> bool:
	var source_absolute := ProjectSettings.globalize_path(source_path)
	var destination_absolute := ProjectSettings.globalize_path(destination_path)
	var rollback_absolute := ProjectSettings.globalize_path(rollback_path)
	var had_destination := FileAccess.file_exists(destination_path)
	if had_destination:
		_remove_file(rollback_path)
		if DirAccess.rename_absolute(destination_absolute, rollback_absolute) != OK:
			return false
	if DirAccess.rename_absolute(source_absolute, destination_absolute) != OK:
		if had_destination and FileAccess.file_exists(rollback_path):
			DirAccess.rename_absolute(rollback_absolute, destination_absolute)
		return false
	if had_destination:
		_remove_file(rollback_path)
	return true

func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func get_setting(key: String, fallback: Variant = null) -> Variant:
	return values.get(key, fallback)

func set_setting(key: String, value: Variant, persist: bool = true) -> bool:
	if not DEFAULTS.has(key) or key == "input_remaps":
		return false
	var cleaned: Variant = _sanitize(key, value)
	if values.get(key) == cleaned:
		return true
	values[key] = cleaned
	setting_changed.emit(key, cleaned)
	if persist:
		return save_settings()
	return true

func toggle_setting(key: String, persist: bool = true) -> bool:
	if not DEFAULTS.has(key) or not (DEFAULTS[key] is bool):
		return false
	return set_setting(key, not bool(values.get(key, DEFAULTS[key])), persist)

func set_auto_stock_enabled(enabled: bool, persist: bool = true) -> bool:
	var config: Dictionary = values.get("auto_stock", {}).duplicate(true)
	config["enabled"] = enabled
	return set_setting("auto_stock", config, persist)

func set_auto_stock_target(product_id: String, quantity: int, persist: bool = true) -> bool:
	if product_id.is_empty():
		return false
	var config: Dictionary = values.get("auto_stock", {}).duplicate(true)
	var targets: Dictionary = config.get("targets", {}).duplicate(true)
	if quantity <= 0:
		targets.erase(product_id)
	else:
		targets[product_id] = clampi(quantity, 1, 999)
	config["targets"] = targets
	return set_setting("auto_stock", config, persist)

func get_auto_stock_target(product_id: String, fallback: int = 0) -> int:
	return int(values.get("auto_stock", {}).get("targets", {}).get(product_id, fallback))

func set_input_binding(action: String, event: InputEvent, persist: bool = true) -> bool:
	return set_input_bindings(action, [event], persist)

func set_input_bindings(action: String, events: Array, persist: bool = true) -> bool:
	if action.is_empty() or not InputMap.has_action(action):
		return false
	var serialized: Array[Dictionary] = []
	for event in events:
		if event is InputEvent:
			var encoded := _event_to_data(event)
			if not encoded.is_empty():
				serialized.append(encoded)
	var remaps: Dictionary = values.get("input_remaps", {}).duplicate(true)
	remaps[action] = serialized
	values["input_remaps"] = remaps
	_apply_action_bindings(action, serialized)
	setting_changed.emit("input_remaps", remaps)
	if persist:
		return save_settings()
	return true

func get_input_bindings(action: String) -> Array[InputEvent]:
	var output: Array[InputEvent] = []
	for row in values.get("input_remaps", {}).get(action, []):
		if row is Dictionary:
			var event := _event_from_data(row)
			if event != null:
				output.append(event)
	return output

func clear_input_binding(action: String, persist: bool = true) -> bool:
	if not InputMap.has_action(action):
		return false
	var remaps: Dictionary = values.get("input_remaps", {}).duplicate(true)
	remaps.erase(action)
	values["input_remaps"] = remaps
	# Removing a remap restores the action as empty; callers can explicitly
	# restore project defaults through reset_input_binding instead.
	InputMap.action_erase_events(action)
	setting_changed.emit("input_remaps", remaps)
	if persist:
		return save_settings()
	return true

func reset_input_binding(action: String, defaults: Array = [], persist: bool = true) -> bool:
	var remaps: Dictionary = values.get("input_remaps", {}).duplicate(true)
	remaps.erase(action)
	values["input_remaps"] = remaps
	if not InputMap.has_action(action):
		return false
	var restore_events := defaults if not defaults.is_empty() else get_default_input_bindings(action)
	InputMap.action_erase_events(action)
	for event in restore_events:
		if event is InputEvent:
			InputMap.action_add_event(action, event)
	setting_changed.emit("input_remaps", remaps)
	if persist:
		return save_settings()
	return true

func reset_all(persist: bool = true) -> bool:
	values = DEFAULTS.duplicate(true)
	for action in _default_bindings:
		if InputMap.has_action(String(action)):
			InputMap.action_erase_events(String(action))
			for event in _default_bindings[action]:
				InputMap.action_add_event(String(action), event)
	setting_changed.emit("all", values.duplicate(true))
	if persist:
		return save_settings()
	return true

func export_state() -> Dictionary:
	return values.duplicate(true)

func get_default_input_bindings(action: String) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	for event in _default_bindings.get(action, []):
		if event is InputEvent:
			result.append(event.duplicate() as InputEvent)
	return result

func get_rebindable_actions() -> Array[String]:
	var result: Array[String] = []
	for action in REBINDABLE_ACTIONS:
		if InputMap.has_action(String(action)):
			result.append(String(action))
	return result

func _capture_default_bindings() -> void:
	if not _default_bindings.is_empty():
		return
	for action in REBINDABLE_ACTIONS:
		if not InputMap.has_action(String(action)):
			continue
		var events: Array[InputEvent] = []
		for event in InputMap.action_get_events(String(action)):
			events.append(event.duplicate() as InputEvent)
		_default_bindings[String(action)] = events

func _sanitize(key: String, value: Variant) -> Variant:
	match key:
		"game_speed": return clampf(float(value), 0.25, 3.0)
		"assisted_checkout", "simplified_crafting", "dyslexia_friendly_text", "reduced_animation", "reduced_flashing", "visual_effects_enabled", "dynamic_lighting": return bool(value)
		"ui_scale": return clampf(float(value), 0.75, 1.12)
		"music_volume", "sfx_volume": return clampf(float(value), 0.0, 1.0)
		"radio_station_id":
			var station_id := String(value)
			return station_id if RADIO_STATION_IDS.has(station_id) else "bellwether_after_hours"
		"mystery_hint_level":
			var hint_level := String(value).to_lower()
			return hint_level if HINT_LEVELS.has(hint_level) else "contextual"
		"auto_stock":
			var raw: Dictionary = value if value is Dictionary else {}
			var target_values: Dictionary = raw.get("targets", {}) if raw.get("targets", {}) is Dictionary else {}
			var normalized_targets: Dictionary = {}
			for product_id in target_values:
				var amount := int(target_values[product_id])
				if not String(product_id).is_empty() and amount > 0:
					normalized_targets[String(product_id)] = clampi(amount, 1, 999)
			return {"enabled": bool(raw.get("enabled", false)), "targets": normalized_targets}
		"input_remaps": return value.duplicate(true) if value is Dictionary else {}
	return DEFAULTS.get(key, value)

func _apply_input_remaps() -> void:
	for action in values.get("input_remaps", {}):
		var rows: Variant = values["input_remaps"][action]
		if rows is Array:
			_apply_action_bindings(String(action), rows)

func _apply_action_bindings(action: String, rows: Array) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	for row in rows:
		if row is Dictionary:
			var event := _event_from_data(row)
			if event != null:
				InputMap.action_add_event(action, event)

func _event_to_data(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return {"type":"key", "keycode":int(key_event.keycode), "physical_keycode":int(key_event.physical_keycode), "unicode":int(key_event.unicode), "shift":key_event.shift_pressed, "ctrl":key_event.ctrl_pressed, "alt":key_event.alt_pressed, "meta":key_event.meta_pressed}
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		return {"type":"joypad_button", "button_index":button_event.button_index}
	if event is InputEventJoypadMotion:
		var axis_event := event as InputEventJoypadMotion
		return {"type":"joypad_motion", "axis":axis_event.axis, "axis_value":axis_event.axis_value}
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return {"type":"mouse_button", "button_index":mouse_event.button_index, "shift":mouse_event.shift_pressed, "ctrl":mouse_event.ctrl_pressed, "alt":mouse_event.alt_pressed, "meta":mouse_event.meta_pressed}
	return {}

func _event_from_data(data: Dictionary) -> InputEvent:
	match String(data.get("type", "")):
		"key":
			var key_event := InputEventKey.new()
			key_event.keycode = int(data.get("keycode", 0))
			key_event.physical_keycode = int(data.get("physical_keycode", 0))
			key_event.unicode = int(data.get("unicode", 0))
			key_event.shift_pressed = bool(data.get("shift", false))
			key_event.ctrl_pressed = bool(data.get("ctrl", false))
			key_event.alt_pressed = bool(data.get("alt", false))
			key_event.meta_pressed = bool(data.get("meta", false))
			return key_event
		"joypad_button":
			var button_event := InputEventJoypadButton.new()
			button_event.button_index = int(data.get("button_index", 0))
			return button_event
		"joypad_motion":
			var axis_event := InputEventJoypadMotion.new()
			axis_event.axis = int(data.get("axis", 0))
			axis_event.axis_value = clampf(float(data.get("axis_value", 0.0)), -1.0, 1.0)
			return axis_event
		"mouse_button":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = int(data.get("button_index", 1))
			mouse_event.shift_pressed = bool(data.get("shift", false))
			mouse_event.ctrl_pressed = bool(data.get("ctrl", false))
			mouse_event.alt_pressed = bool(data.get("alt", false))
			mouse_event.meta_pressed = bool(data.get("meta", false))
			return mouse_event
	return null
