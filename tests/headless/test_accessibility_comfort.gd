extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var _failures: Array[String] = []
var _checks := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCENE.instantiate() as Node2D
	add_child(main)
	for _frame in range(5):
		await get_tree().process_frame
	_expect(main != null and main.get("settings_panel") != null, "accessibility review initializes the game settings panel")
	if main == null:
		_finish()
		return
	var settings_panel := main.get("settings_panel") as CanvasLayer
	var content_label := _find_first_label(settings_panel)
	var default_font_size := content_label.get_theme_font_size("font_size") if content_label != null else 0
	main.call("_apply_readability_mode", true)
	var readable_font_size := content_label.get_theme_font_size("font_size") if content_label != null else 0
	_expect(content_label != null and readable_font_size > default_font_size, "OpenDyslexic readability mode increases settings text size")
	main.call("_apply_readability_mode", false)
	var focus_restore_target := Button.new()
	focus_restore_target.name = "FocusRestoreTarget"
	focus_restore_target.focus_mode = Control.FOCUS_ALL
	add_child(focus_restore_target)
	focus_restore_target.grab_focus()
	await get_tree().process_frame
	_expect(get_viewport().gui_get_focus_owner() == focus_restore_target, "test starts with focus on the control to restore after closing settings")
	settings_panel.call("open")
	await get_tree().process_frame
	var focused := get_viewport().gui_get_focus_owner()
	_expect(focused != null and settings_panel.is_ancestor_of(focused), "settings can be opened with keyboard focus inside the dialog")
	_test_settings_text_contrast(settings_panel)
	var binding_buttons: Dictionary = settings_panel.get("_binding_buttons")
	var interact_binding := binding_buttons.get("interact") as Button
	settings_panel.call("_refresh_binding_button", "interact")
	_expect(interact_binding != null and interact_binding.text.contains("E") and not interact_binding.text.contains("Physical"), "settings input rows show readable key names without the Physical-key suffix")
	settings_panel.call("close")
	await get_tree().process_frame
	_expect(get_viewport().gui_get_focus_owner() == focus_restore_target, "closing settings restores keyboard or controller focus to the prior control")
	focus_restore_target.queue_free()

	main.call("_apply_visual_comfort_settings", true, true, true)
	main.set("animation_clock", 1.0)
	main.call("_process", 0.8)
	var rain := main.get("rain_overlay") as Sprite2D
	var memory_echo := main.get("window_echo") as Sprite2D
	var steam := main.get("kettle_steam") as Sprite2D
	_expect(main.get("reduced_animation_enabled") == true, "reduced-animation preference reaches the game runtime")
	_expect(rain == null or rain.frame == 0, "reduced animation holds rain on a static frame")
	_expect(memory_echo == null or memory_echo.frame == 0, "reduced animation holds memory effects on a static frame")
	_expect(steam == null or steam.frame == 0, "reduced animation holds steam on a static frame")
	var pip_glow := main.get("pip_glow") as PointLight2D
	var game: Object = main.get("game")
	if game != null:
		var story: Object = game.get("story")
		var flags: Dictionary = story.get("flags")
		flags["pip_reflection"] = true
		story.set("flags", flags)
	main.call("_process", 0.8)
	_expect(main.get("reduced_flashing_enabled") == true, "reduced-flashing preference reaches the game runtime")
	_expect(pip_glow == null or not pip_glow.visible, "reduced flashing suppresses Pip's dynamic story glow")
	var glow_energy_before := (main.get("moon_glow") as PointLight2D).energy if main.get("moon_glow") is PointLight2D else 0.0
	main.call("_process", 0.8)
	var glow_energy_after := (main.get("moon_glow") as PointLight2D).energy if main.get("moon_glow") is PointLight2D else 0.0
	_expect(is_equal_approx(glow_energy_before, glow_energy_after), "reduced flashing removes the moonlight pulse")

	main.call("_stop_audio_players")
	var audio_players: Array[Node] = main.find_children("*", "AudioStreamPlayer", true, false)
	_expect(audio_players.all(func(node: Node) -> bool: return not (node as AudioStreamPlayer).playing and (node as AudioStreamPlayer).stream == null), "accessibility review releases the audio resources it exercised")
	main.queue_free()
	for _frame in range(3):
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	_expect(not is_instance_valid(main), "accessibility review releases its runtime scene")
	_finish()

func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var found := _find_first_label(child)
		if found != null:
			return found
	return null

func _test_settings_text_contrast(settings_panel: CanvasLayer) -> void:
	var dialog := settings_panel.get("_dialog") as PanelContainer
	var panel_style := dialog.get_theme_stylebox("panel") as StyleBoxTexture if dialog != null else null
	var texture := panel_style.texture if panel_style != null else null
	var image := texture.get_image() if texture != null else null
	_expect(image != null and image.get_width() > 0 and image.get_height() > 0, "contrast audit reads the exact settings journal-panel texture")
	if image == null:
		return
	# Use the actual textured content area, excluding its painted corner ornaments.
	# Composite the nearly opaque panel over white to conservatively account for
	# any scene pixels beneath its remaining alpha.
	var brightest_luminance := 0.0
	for y in range(180, mini(1080, image.get_height()), 2):
		for x in range(240, mini(1010, image.get_width()), 2):
			var source := image.get_pixel(x, y)
			var inverse_alpha := 1.0 - source.a
			var background := Color(
				source.r * source.a + inverse_alpha,
				source.g * source.a + inverse_alpha,
				source.b * source.a + inverse_alpha,
				1.0
			)
			brightest_luminance = maxf(brightest_luminance, _relative_luminance(background))
	_expect(brightest_luminance > 0.0, "contrast audit samples the actual settings-panel content texture")
	if brightest_luminance <= 0.0:
		return
	var label_count := 0
	for node in dialog.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null or not label.visible:
			continue
		label_count += 1
		var foreground := label.get_theme_color("font_color")
		var contrast := _contrast_ratio_from_luminance(_relative_luminance(foreground), brightest_luminance)
		_expect(contrast >= 4.5, "settings label %s (#%s) keeps at least 4.5:1 contrast across the journal texture (%.2f:1)" % [label.name, foreground.to_html(false), contrast])
	_expect(label_count >= 10, "contrast audit covers the settings labels rendered in the open dialog")
	var audited_button_states := 0
	for node in dialog.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null or not button.visible:
			continue
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := button.get_theme_stylebox(state) as StyleBoxFlat
			if style == null:
				continue
			var foreground := button.get_theme_color("font_color")
			var contrast := _contrast_ratio(foreground, style.bg_color)
			_expect(contrast >= 4.5, "settings button %s %s state keeps at least 4.5:1 contrast (%.2f:1)" % [button.name, state, contrast])
			audited_button_states += 1
	_expect(audited_button_states >= 4, "contrast audit covers button text against its actual normal, hover, pressed, and focus fills")
	var audited_focus_rings := 0
	for node in dialog.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or control.focus_mode == Control.FOCUS_NONE or not control.is_visible_in_tree():
			continue
		var focus_style := control.get_theme_stylebox("focus") as StyleBoxFlat
		_expect(focus_style != null, "focusable settings control %s has an explicit visible focus-ring style" % control.name)
		if focus_style == null:
			continue
		var focus_contrast := _contrast_ratio_from_luminance(_relative_luminance(focus_style.border_color), brightest_luminance)
		_expect(focus_contrast >= 3.0, "focusable settings control %s has a focus border at least 3:1 against the textured panel (%.2f:1)" % [control.name, focus_contrast])
		_expect(focus_style.border_color.a >= 0.95 and focus_style.border_width_left >= 2, "focusable settings control %s draws an opaque, at least two-pixel focus border" % control.name)
		if control is CheckBox or control is OptionButton or control is HSlider or control is SpinBox:
			_expect(not focus_style.draw_center, "focusable settings control %s keeps its focus ring transparent over the control fill" % control.name)
		audited_focus_rings += 1
	_expect(audited_focus_rings >= 12, "contrast audit covers focus rings for checkboxes, sliders, selectors, and buttons")

func _linearize_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)

func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linearize_channel(color.r) + 0.7152 * _linearize_channel(color.g) + 0.0722 * _linearize_channel(color.b)

func _contrast_ratio_from_luminance(first: float, second: float) -> float:
	var lighter := maxf(first, second)
	var darker := minf(first, second)
	return (lighter + 0.05) / (darker + 0.05)

func _contrast_ratio(first: Color, second: Color) -> float:
	return _contrast_ratio_from_luminance(_relative_luminance(first), _relative_luminance(second))

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)

func _finish() -> void:
	if _failures.is_empty():
		print("Accessibility comfort checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Accessibility comfort checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)
