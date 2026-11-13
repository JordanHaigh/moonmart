extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const REVIEW_OUTPUT_DIR := "res://godot_task_state/localization_runtime_review_20261113_02"

var _checks := 0
var _failures: Array[String] = []
var _capture_index := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 900)
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	_expect(packed != null, "main scene loads for the Spanish runtime review")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate()
	main.set_meta("moonmart_test_language", "es")
	root.add_child(main)
	for _frame in range(40):
		await process_frame
	var game: Object = main.get("game")
	_expect(game != null and String(game.call("localization_language")) == "es", "the main scene forwards the QA locale before game catalogs load")
	if game == null:
		_finish()
		return
	var spanish_resume := String(game.call("localize_ui", "pause.button.resume", "Return to Moonmart"))
	var pause_buttons: Array = main.get("pause_buttons")
	_expect(spanish_resume == "Volver a Moonmart", "the actual runtime loads the Spanish UI catalog")
	_expect(not pause_buttons.is_empty() and (pause_buttons[0] as Button).text == spanish_resume, "initial pause controls use the loaded Spanish catalog")
	var hud := main.get("hud_layer") as CanvasLayer
	var controls_hint := hud.get_node_or_null("HudControlsHint") as Label if hud != null else null
	_expect(controls_hint != null and controls_hint.text.contains("Moverse") and controls_hint.text.contains("Ajustes"), "the gameplay HUD uses Spanish controls copy")
	_expect(String(main.call("_format_locale_number", 1.25, 1)) == "1,3", "Spanish runtime numbers use a comma decimal separator")
	_capture("hud")

	main.call("_toggle_panel", "journal")
	await process_frame
	var side_label := main.get("side_label") as Label
	var side_panel := main.get("side_panel") as Control
	var side_scroll := main.get("side_scroll") as ScrollContainer
	_expect(side_label != null and side_label.text.begins_with("DIARIO DE MEDIANOCHE"), "the journal panel uses runtime Spanish")
	_expect(side_label != null and side_label.text.split("DIARIO DE MEDIANOCHE").size() == 2, "the journal title appears once instead of repeating above its body")
	_expect(side_panel != null and side_scroll != null and _rect_inside_paper(side_scroll.get_global_rect(), side_panel.get_global_rect()), "Spanish side-panel text stays inside the illustrated parchment safe area")
	_capture("journal")
	main.call("_apply_settings_ui_scale", 0.75)
	await process_frame
	_expect(side_panel != null and side_scroll != null and _rect_inside_paper(side_scroll.get_global_rect(), side_panel.get_global_rect()), "minimum UI scale keeps Spanish journal content inside its parchment")
	_capture("journal_min_scale")
	main.call("_apply_settings_ui_scale", 1.12)
	await process_frame
	_expect(side_panel != null and side_scroll != null and _rect_inside_paper(side_scroll.get_global_rect(), side_panel.get_global_rect()), "maximum UI scale keeps Spanish journal content inside its parchment")
	_capture("journal_max_scale")
	main.call("_apply_settings_ui_scale", 1.0)
	await process_frame
	main.call("_close_side_panel")

	main.call("_toggle_panel", "inventory")
	await process_frame
	_expect(side_label != null and side_label.text.begins_with("INVENTARIO Y EXISTENCIAS"), "the inventory panel uses runtime Spanish")
	_capture("inventory")
	main.call("_close_side_panel")

	main.call("_open_map_panel")
	await process_frame
	_expect(side_label != null and side_label.text.begins_with("BELLWETHER · MAPA DEL PUEBLO"), "the town map uses runtime Spanish")
	_capture("map")
	main.call("_close_side_panel")

	main.call("_open_calendar_panel")
	await process_frame
	_expect(side_label != null and side_label.text.begins_with("BELLWETHER · CALENDARIO ESTACIONAL"), "the seasonal calendar uses runtime Spanish")
	_capture("calendar")
	main.call("_close_side_panel")

	var settings_panel := main.get("settings_panel") as Node
	if settings_panel != null and settings_panel.has_method("open"):
		settings_panel.call("open")
		for _frame in range(3):
			await process_frame
		var settings_dialog := settings_panel.find_child("SettingsJournalPanel", true, false) as Control
		var settings_title := settings_panel.find_child("SettingsTitle", true, false) as Label
		if settings_title == null:
			settings_title = _find_label_with_prefix(settings_panel, "AJUSTES  ·")
		var settings_section := _find_label_with_prefix(settings_panel, "JUEGO Y GESTIÓN")
		_expect(settings_dialog != null and settings_dialog.visible, "the localized settings dialog opens in the real main scene")
		_expect(settings_title != null, "the settings panel title uses the Spanish runtime catalog")
		_expect(settings_dialog != null and settings_section != null and settings_section.global_position.x >= settings_dialog.global_position.x + 140.0, "Spanish section headings clear the illustrated moon in the settings frame")
		if settings_dialog != null:
			_expect(_rect_inside_viewport(settings_dialog.get_global_rect()), "the Spanish settings panel remains inside the 1600x900 viewport")
		_capture("settings")
		main.call("_apply_settings_ui_scale", 0.75)
		for _frame in range(3):
			await process_frame
		_expect(settings_dialog != null and _rect_inside_viewport(settings_dialog.get_global_rect()), "minimum UI scale keeps the Spanish settings panel inside the viewport")
		_capture("settings_min_scale")
		main.call("_apply_settings_ui_scale", 1.12)
		for _frame in range(3):
			await process_frame
		_expect(settings_dialog != null and _rect_inside_viewport(settings_dialog.get_global_rect()), "maximum UI scale keeps the Spanish settings panel inside the viewport")
		_capture("settings_max_scale")
		main.call("_apply_settings_ui_scale", 1.0)
		await process_frame
		settings_panel.call("close")
	else:
		_expect(false, "the main scene exposes its settings panel")

	var dialogue_catalog: Dictionary = game.get("_dialogue")
	var story_lines: Dictionary = dialogue_catalog.get("story_lines", {})
	var restored_line := String(story_lines.get("lighthouse_restored", ""))
	_expect(not restored_line.is_empty() and restored_line != "The lighthouse is restored.", "the runtime loads the Spanish story dialogue overlay")
	_expect(story_lines.size() == 37, "the runtime story overlay contains all 37 essential event summaries")
	var longest_story_line := ""
	var longest_story_event_id := ""
	var longest_story_wrapped_lines := 0
	var story_message_label := main.get("message_label") as Label
	var story_message_panel := main.get("message_panel") as Control
	for event_id in story_lines:
		var story_text := String(story_lines[event_id])
		main.call("_on_message_changed", story_text)
		for _frame in range(2):
			await process_frame
		story_message_label = main.get("message_label") as Label
		var wrapped_lines: int = story_message_label.get_line_count() if story_message_label != null else 0
		var required_story_height := float(wrapped_lines) * story_message_label.get_line_height() if story_message_label != null else INF
		_expect(story_message_label != null and required_story_height <= story_message_label.size.y + 0.5, "Spanish story summary %s fits the production dialogue panel" % String(event_id))
		_expect(story_message_panel != null and _rect_inside_viewport(story_message_panel.get_global_rect()), "Spanish story summary %s keeps its dialogue panel on-screen" % String(event_id))
		if wrapped_lines > longest_story_wrapped_lines or (wrapped_lines == longest_story_wrapped_lines and story_text.length() > longest_story_line.length()):
			longest_story_line = story_text
			longest_story_event_id = String(event_id)
			longest_story_wrapped_lines = wrapped_lines
	if not longest_story_line.is_empty():
		main.call("_on_message_changed", longest_story_line)
		for _frame in range(3):
			await process_frame
		_capture("story_dialogue_longest")
		print("Longest Spanish story dialogue: %s, %d wrapped lines." % [longest_story_event_id, longest_story_wrapped_lines])
	main.call("_on_message_changed", restored_line)
	for _frame in range(3):
		await process_frame
	var message_label := main.get("message_label") as Label
	_expect(message_label != null and message_label.text == restored_line, "Spanish story dialogue reaches the production message panel")
	_expect(message_label != null and message_label.get_line_count() <= 4, "Spanish story dialogue fits the production message panel height")
	_capture("story_dialogue")

	if main.has_method("_stop_audio_players"):
		main.call("_stop_audio_players")
	main.queue_free()
	for _frame in range(3):
		await process_frame
	await create_timer(0.2).timeout
	_finish()

func _find_label_with_prefix(parent: Node, prefix: String) -> Label:
	for child in parent.find_children("*", "Label", true, false):
		var label := child as Label
		if label != null and label.text.begins_with(prefix):
			return label
	return null

func _rect_inside_viewport(rect: Rect2) -> bool:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	return viewport_rect.grow(-1.0).encloses(rect)

func _rect_inside_paper(content_rect: Rect2, panel_rect: Rect2) -> bool:
	var content_bounds := Rect2(panel_rect.position + Vector2(60, 70), panel_rect.size - Vector2(120, 140))
	return content_bounds.encloses(content_rect)

func _capture(name: String) -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	var texture := root.get_texture()
	if texture == null:
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_OUTPUT_DIR)) != OK:
		push_warning("Could not create Spanish runtime capture output directory")
		return
	_capture_index += 1
	var image := texture.get_image()
	if image == null or image.is_empty():
		return
	image.save_png(ProjectSettings.globalize_path("%s/%02d_%s.png" % [REVIEW_OUTPUT_DIR, _capture_index, name]))

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)

func _finish() -> void:
	if _failures.is_empty():
		print("Spanish runtime localization smoke passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Spanish runtime localization smoke failed: %d of %d checks." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)
