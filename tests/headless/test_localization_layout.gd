extends SceneTree

const SETTINGS_SCRIPT := preload("res://scripts/systems/settings_manager.gd")
const SETTINGS_PANEL_SCRIPT := preload("res://scripts/ui/settings_panel.gd")
const SPANISH_UI_PATH := "res://data/locales/es/ui.json"

var _spanish_strings: Dictionary = {}
var _checks := 0
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPANISH_UI_PATH))
	_expect(parsed is Dictionary, "Spanish UI catalog parses for the layout smoke")
	if not parsed is Dictionary:
		_finish()
		return
	var catalog_strings: Variant = parsed.get("strings", {})
	_expect(catalog_strings is Dictionary, "Spanish UI catalog contains its string map")
	if not catalog_strings is Dictionary:
		_finish()
		return
	_spanish_strings = catalog_strings
	var settings = SETTINGS_SCRIPT.new()
	settings.setup()
	var panel = SETTINGS_PANEL_SCRIPT.new()
	panel.settings = settings
	panel.ui_text_lookup = Callable(self, "_lookup_spanish")
	root.add_child(panel)
	panel.open()
	for _frame in range(3):
		await process_frame
	var action_label := panel.find_child("ActionLabel_stock_donate_all", true, false) as Label
	_expect(action_label != null, "long Spanish action label exists in the controls list")
	if action_label != null:
		_expect(action_label.text == "Donar todas las existencias", "the settings panel uses the concise Spanish action label")
		_expect(action_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "long action names wrap instead of running into adjacent controls")
		_expect(action_label.size.x <= 181.0, "translated action names remain within their label column")
		_expect(action_label.get_line_count() <= 2, "the longest Spanish action label fits within two lines")
	for action_value in settings.get_rebindable_actions():
		var action := String(action_value)
		var localized_action_label := panel.find_child("ActionLabel_%s" % action, true, false) as Label
		_expect(localized_action_label != null, "the controls list lays out %s" % action)
		if localized_action_label != null:
			_expect(localized_action_label.size.x <= 181.0, "Spanish control label %s stays inside its label column" % action)
			_expect(localized_action_label.get_line_count() <= 2, "Spanish control label %s fits within two lines" % action)
	var reset_button := panel.find_child("ResetBinding_stock_donate_all", true, false) as Button
	_expect(reset_button != null and reset_button.text == "Restablecer", "Spanish binding reset button is present")
	_expect(reset_button != null and reset_button.size.x >= 126.0, "Spanish reset text has enough button width")
	panel.set_readability_mode(true)
	for _frame in range(3):
		await process_frame
	if action_label != null:
		var label_row := action_label.get_parent() as Control
		var readable_line_height := float(action_label.get_theme_font_size("font_size")) * float(action_label.get_line_count())
		_expect(action_label.get_line_count() <= 3, "the longest Spanish control label remains compact in readability mode")
		_expect(action_label.size.y >= readable_line_height and label_row.size.y >= action_label.size.y, "the wrapped Spanish control label has enough row height in readability mode")
	panel.close()
	panel.queue_free()
	await process_frame
	_finish()

func _lookup_spanish(key: String, fallback: String) -> String:
	var translated: Variant = _spanish_strings.get(key, fallback)
	return String(translated) if translated is String else fallback

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)

func _finish() -> void:
	if _failures.is_empty():
		print("Spanish localization layout smoke passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Spanish localization layout smoke failed: %d of %d checks." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)
