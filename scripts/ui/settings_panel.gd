class_name MoonmartSettingsPanel
extends CanvasLayer

## Self-contained settings view. The owning game connects its public signals to
## the simulation, AudioServer, Control scaling, and visual effect nodes.
signal closed
signal game_speed_changed(multiplier: float)
signal assisted_checkout_changed(enabled: bool)
signal simplified_crafting_changed(enabled: bool)
signal auto_stock_changed(enabled: bool, targets: Dictionary)
signal ui_scale_changed(scale: float)
signal dyslexia_font_changed(enabled: bool)
signal reduced_animation_changed(enabled: bool)
signal reduced_flashing_changed(enabled: bool)
signal visual_effects_changed(enabled: bool, reduced_animation: bool, reduced_flashing: bool)
signal lighting_changed(enabled: bool)
signal audio_levels_changed(music: float, sfx: float)
signal mystery_hint_level_changed(level: String)
signal input_remap_changed(action: String, events: Array[InputEvent])

const SETTINGS_PANEL_TEXTURE := "res://assets/raster/ui/journal_panel.png"
const MOONMART_FONT := preload("res://assets/fonts/Nunito[wght].ttf")
const OPEN_DYSLEXIC_FONT := preload("res://assets/fonts/OpenDyslexic-Regular.otf")
const HINT_OPTIONS := ["none", "contextual", "guided"]

var settings: MoonmartSettings
var ui_text_lookup: Callable
var locale_language_lookup: Callable
var product_rows: Array[Dictionary] = []
var _root: Control
var _dialog: PanelContainer
var _stock_product: OptionButton
var _stock_target: SpinBox
var _stock_enabled: CheckBox
var _hint_option: OptionButton
var _capture_action := ""
var _binding_buttons: Dictionary = {}
var _controls: Dictionary = {}
var _readouts: Dictionary = {}
var _save_notice: Label
var _is_built := false
var _readability_enabled := false
var _ui_scale := 1.0
var _previous_focus_owner: Control

func _ready() -> void:
	set_process_unhandled_input(true)
	if settings == null:
		settings = MoonmartSettings.new()
		settings.setup()
	_build_panel()
	visible = false

func configure(settings_manager: MoonmartSettings, available_products: Array = []) -> void:
	if settings_manager != null:
		settings = settings_manager
		if not settings.setting_changed.is_connected(_on_setting_changed):
			settings.setting_changed.connect(_on_setting_changed)
	product_rows.clear()
	for product in available_products:
		if product is Dictionary:
			product_rows.append(product.duplicate(true))
	if is_inside_tree():
		if not _is_built:
			_build_panel()
		else:
			_populate_stock_products()
			_refresh_controls()

func set_products(available_products: Array) -> void:
	product_rows.clear()
	for product in available_products:
		if product is Dictionary:
			product_rows.append(product.duplicate(true))
	if _is_built:
		_populate_stock_products()

func open() -> void:
	if not _is_built:
		_build_panel()
	if not visible:
		var focus_owner := get_viewport().gui_get_focus_owner()
		_previous_focus_owner = focus_owner if focus_owner != null and not _root.is_ancestor_of(focus_owner) else null
	_refresh_controls()
	visible = true
	var first_actionable := _find_first_actionable_control(_root)
	if first_actionable != null:
		first_actionable.grab_focus()
	_emit_current_values()

func close() -> void:
	_capture_action = ""
	visible = false
	if is_instance_valid(_previous_focus_owner) and _previous_focus_owner.is_inside_tree() and _previous_focus_owner.is_visible_in_tree():
		_previous_focus_owner.grab_focus()
	_previous_focus_owner = null
	closed.emit()

func _find_first_actionable_control(node: Node) -> Control:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree() and not (control is BaseButton and (control as BaseButton).disabled):
				return control
		var nested := _find_first_actionable_control(child)
		if nested != null:
			return nested
	return null

func show_save_notice(message: String) -> void:
	if not _is_built:
		_build_panel()
	_save_notice.text = message
	_save_notice.visible = not message.is_empty()

func is_open() -> bool:
	return visible

func set_readability_mode(enabled: bool) -> void:
	_readability_enabled = enabled
	if _root != null:
		var font: Font = OPEN_DYSLEXIC_FONT if enabled else MOONMART_FONT
		_root.theme.default_font = font
		_apply_readability(_root, 1.12 if enabled else 1.0, font)

func set_ui_scale(scale_value: float) -> void:
	_ui_scale = clampf(scale_value, 0.75, 1.12)
	if _dialog != null:
		_dialog.scale = Vector2.ONE * _ui_scale
		var viewport_size := get_viewport().get_visible_rect().size
		_dialog.position = (viewport_size - _dialog.size * _ui_scale) * 0.5

func _apply_readability(node: Node, factor: float, font: Font) -> void:
	if node is Control:
		var control := node as Control
		control.add_theme_font_override("font", font)
		if node is Label or node is Button or node is LineEdit or node is OptionButton or node is SpinBox or node is CheckBox:
			var base_size := int(control.get_meta("settings_base_font_size", control.get_theme_font_size("font_size")))
			if base_size <= 0:
				base_size = 16
			control.set_meta("settings_base_font_size", base_size)
			control.add_theme_font_size_override("font_size", roundi(base_size * factor))
		if node is Label:
			control.add_theme_constant_override("line_spacing", 3 if factor > 1.0 else 0)
	for child in node.get_children():
		_apply_readability(child, factor, font)

func _build_panel() -> void:
	if _is_built:
		return
	_root = Control.new()
	var panel_theme := Theme.new()
	panel_theme.default_font = MOONMART_FONT
	_root.theme = panel_theme
	_root.name = "SettingsOverlay"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.focus_mode = Control.FOCUS_ALL
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.075, 0.06, 0.11, 0.84)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(backdrop)
	_dialog = PanelContainer.new()
	_dialog.name = "SettingsJournalPanel"
	_dialog.position = Vector2(290, 58)
	_dialog.size = Vector2(1020, 784)
	_dialog.add_theme_stylebox_override("panel", _journal_style())
	_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dialog)
	var layout := Control.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.add_child(layout)
	var header := HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 54.0
	header.custom_minimum_size.y = 54
	var title := _label(_ui("settings.title", "SETTINGS  ·  THE MIDNIGHT JOURNAL"), 25, Color("fff8ec"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := _button("Close", Vector2(112, 44), "settings.close")
	close_button.pressed.connect(close)
	header.add_child(close_button)
	layout.add_child(header)
	_save_notice = _label("", 14, Color("ffedf0"))
	_save_notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_save_notice.offset_top = 58.0
	_save_notice.offset_bottom = 78.0
	_save_notice.visible = false
	layout.add_child(_save_notice)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var scroll_host := Control.new()
	scroll_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_host.offset_top = 82.0
	scroll_host.offset_bottom = -120.0
	layout.add_child(scroll_host)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_host.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 780
	content.add_theme_constant_override("separation", 7)
	scroll.add_child(content)

	_add_section(content, "settings.section.play_shopkeeping", "PLAY & SHOPKEEPING")
	_add_slider(content, "Shift pace", "game_speed", 0.25, 3.0, 0.05, "×")
	_add_toggle(content, "Assisted checkout", "assisted_checkout", "Optional scan assistance; story rewards stay the same.")
	_add_toggle(content, "Simplified crafting", "simplified_crafting", "One selection can prepare up to three servings when ingredients allow.")
	_add_auto_stock_controls(content)

	_add_section(content, "settings.section.accessibility", "ACCESSIBILITY & VISUAL COMFORT")
	_add_slider(content, "Interface size", "ui_scale", 0.75, 1.12, 0.05, "×")
	_add_toggle(content, "OpenDyslexic font", "dyslexia_friendly_text", "Optional typeface with increased text size and line spacing.")
	_add_toggle(content, "Reduce animation", "reduced_animation", "Calms decorative motion while preserving gameplay feedback.")
	_add_toggle(content, "Reduce flashing", "reduced_flashing", "Suppresses rapid flashes and strong brightness pulses.")
	_add_toggle(content, "Environmental effects", "visual_effects_enabled", "Show weather, seasonal, and story atmosphere overlays.")
	_add_toggle(content, "Dynamic lighting", "dynamic_lighting", "Enable independent 2D light sources such as the moon halo.")

	_add_section(content, "settings.section.audio_mystery", "AUDIO & MYSTERY HELP")
	_add_slider(content, "Music volume", "music_volume", 0.0, 1.0, 0.05, "%")
	_add_slider(content, "Effects volume", "sfx_volume", 0.0, 1.0, 0.05, "%")
	_add_hint_control(content)

	_add_section(content, "settings.section.controls", "CONTROLS")
	var help := _label(_ui("settings.controls.help", "Select a control, then press a key or gamepad input. Reset restores the project binding. Numbered actions select matching choices."), 15, Color("ffe8f0"))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(help)
	for action in settings.get_rebindable_actions():
		_add_binding_row(content, String(action))

	var footer := _label(_ui("settings.footer", "Changes save automatically  ·  No setting can block story progress"), 14, Color("ffe8f0"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -106.0
	footer.offset_bottom = -74.0
	layout.add_child(footer)
	_is_built = true
	if settings != null and not settings.setting_changed.is_connected(_on_setting_changed):
		settings.setting_changed.connect(_on_setting_changed)
	_populate_stock_products()
	_refresh_controls()
	set_ui_scale(_ui_scale)
	set_readability_mode(_readability_enabled)

func _add_section(parent: VBoxContainer, key: String, text_value: String) -> void:
	var header := _label(_ui(key, text_value), 16, Color("fff0c8"))
	header.custom_minimum_size.y = 32
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var header_inset := MarginContainer.new()
	header_inset.add_theme_constant_override("margin_left", 80)
	header_inset.custom_minimum_size.y = 32
	header_inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_inset.add_child(header)
	parent.add_child(header_inset)
	var separator := HSeparator.new()
	separator.modulate = Color(0.83, 0.62, 0.72, 0.56)
	parent.add_child(separator)

func _add_toggle(parent: VBoxContainer, label_text: String, key: String, description: String) -> void:
	var row := _make_row(_ui("settings.toggle.%s.label" % key, label_text), _ui("settings.toggle.%s.description" % key, description))
	var check := CheckBox.new()
	check.custom_minimum_size = Vector2(52, 40)
	check.focus_mode = Control.FOCUS_ALL
	_apply_focus_ring(check)
	check.add_theme_color_override("font_color", Color("fff8ec"))
	check.toggled.connect(_on_toggle.bind(key))
	row.add_child(check)
	parent.add_child(row)
	_controls[key] = check

func _add_slider(parent: VBoxContainer, label_text: String, key: String, minimum: float, maximum: float, step: float, suffix: String) -> void:
	var row := _make_row(_ui("settings.slider.%s.label" % key, label_text), "")
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(300, 34)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.focus_mode = Control.FOCUS_ALL
	_apply_focus_ring(slider)
	slider.value_changed.connect(_on_slider_changed.bind(key))
	row.add_child(slider)
	var readout := _label("", 16, Color("fff8ec"))
	readout.custom_minimum_size.x = 62
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(readout)
	parent.add_child(row)
	_controls[key] = slider
	_readouts[key] = {"label":readout, "suffix":suffix}

func _add_auto_stock_controls(parent: VBoxContainer) -> void:
	var row := _make_row(_ui("settings.auto_stock.title", "Automatic stocking"), _ui("settings.auto_stock.description", "Remember minimum shelf targets for selected items."))
	_stock_enabled = CheckBox.new()
	_stock_enabled.custom_minimum_size = Vector2(52, 40)
	_stock_enabled.focus_mode = Control.FOCUS_ALL
	_apply_focus_ring(_stock_enabled)
	_stock_enabled.toggled.connect(_on_auto_stock_toggled)
	row.add_child(_stock_enabled)
	parent.add_child(row)
	var target_row := HBoxContainer.new()
	target_row.custom_minimum_size.y = 42
	var product_label := _label(_ui("settings.auto_stock.product", "Product"), 15, Color("ffe8f0"))
	product_label.custom_minimum_size.x = 130
	target_row.add_child(product_label)
	_stock_product = OptionButton.new()
	_stock_product.custom_minimum_size = Vector2(340, 38)
	_stock_product.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stock_product.focus_mode = Control.FOCUS_ALL
	_apply_focus_ring(_stock_product)
	_stock_product.item_selected.connect(_on_stock_product_selected)
	target_row.add_child(_stock_product)
	parent.add_child(target_row)
	var quantity_row := HBoxContainer.new()
	quantity_row.custom_minimum_size.y = 42
	var quantity_label := _label(_ui("settings.auto_stock.minimum_quantity", "Minimum quantity"), 15, Color("ffe8f0"))
	quantity_label.custom_minimum_size.x = 230
	quantity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quantity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_row.add_child(quantity_label)
	_stock_target = SpinBox.new()
	_stock_target.min_value = 0
	_stock_target.max_value = 999
	_stock_target.step = 1
	_stock_target.custom_minimum_size = Vector2(128, 38)
	_stock_target.focus_mode = Control.FOCUS_ALL
	_apply_focus_ring(_stock_target)
	quantity_row.add_child(_stock_target)
	var save_target := _button("Set target", Vector2(140, 38), "settings.auto_stock.set_target")
	save_target.pressed.connect(_save_auto_stock_target)
	quantity_row.add_child(save_target)
	parent.add_child(quantity_row)
	_stock_enabled.tooltip_text = _ui("settings.auto_stock.enabled_tooltip", "Switch automatic restock suggestions on or off.")
	_stock_target.tooltip_text = _ui("settings.auto_stock.target_tooltip", "Set to zero to remove this product's target.")

func _add_hint_control(parent: VBoxContainer) -> void:
	var row := _make_row(_ui("settings.mystery_help.title", "Mystery assistance"), _ui("settings.mystery_help.description", "Choose the amount of optional investigation guidance."))
	_hint_option = OptionButton.new()
	_hint_option.custom_minimum_size = Vector2(210, 40)
	_hint_option.focus_mode = Control.FOCUS_ALL
	_apply_focus_ring(_hint_option)
	for level in HINT_OPTIONS:
		_hint_option.add_item(_ui("settings.mystery_help.level.%s" % String(level), String(level).capitalize()))
		_hint_option.set_item_metadata(_hint_option.item_count - 1, String(level))
	_hint_option.item_selected.connect(_on_hint_selected)
	row.add_child(_hint_option)
	parent.add_child(row)

func _add_binding_row(parent: VBoxContainer, action: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 42
	var label := _label(_action_title(action), 15, Color("fff8ec"))
	label.name = "ActionLabel_%s" % action
	label.custom_minimum_size.x = 180
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	var bind_button := _button("", Vector2(300, 38))
	bind_button.name = "BindingButton_%s" % action
	bind_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bind_button.pressed.connect(_begin_binding.bind(action))
	row.add_child(bind_button)
	var reset_button := _button("Reset", Vector2(126, 38), "settings.controls.reset")
	reset_button.name = "ResetBinding_%s" % action
	reset_button.pressed.connect(_reset_binding.bind(action))
	row.add_child(reset_button)
	parent.add_child(row)
	_binding_buttons[action] = bind_button
	_refresh_binding_button(action)

func _make_row(title_text: String, description: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 48
	row.add_theme_constant_override("separation", 10)
	var title_column := VBoxContainer.new()
	title_column.custom_minimum_size.x = 360
	var title := _label(title_text, 17, Color("fff8ec"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_column.add_child(title)
	if not description.is_empty():
		var detail := _label(description, 12, Color("ffe8f0"))
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_column.add_child(detail)
	row.add_child(title_column)
	return row

func _spacer_label(text_value: String, min_width: float) -> Label:
	var label := _label(text_value, 14, Color("ffe8f0"))
	label.custom_minimum_size.x = min_width
	return label

func _populate_stock_products() -> void:
	if _stock_product == null:
		return
	_stock_product.clear()
	for product in product_rows:
		var id := String(product.get("id", ""))
		if id.is_empty():
			continue
		_stock_product.add_item(String(product.get("name", id)))
		_stock_product.set_item_metadata(_stock_product.item_count - 1, id)
	if _stock_product.item_count == 0:
		_stock_product.add_item(_ui("settings.auto_stock.no_products", "No products supplied"))
		_stock_product.set_item_disabled(0, true)

func _save_auto_stock_target() -> void:
	if _stock_product == null or _stock_target == null or _stock_product.item_count == 0:
		return
	var product_id := String(_stock_product.get_item_metadata(_stock_product.selected))
	if product_id.is_empty():
		return
	settings.set_auto_stock_target(product_id, int(_stock_target.value))

func _on_stock_product_selected(_index: int) -> void:
	if _stock_target != null and settings != null:
		_stock_target.set_value_no_signal(settings.get_auto_stock_target(_selected_product_id()))

func _on_auto_stock_toggled(enabled: bool) -> void:
	settings.set_auto_stock_enabled(enabled)

func _on_toggle(enabled: bool, key: String) -> void:
	settings.set_setting(key, enabled)

func _on_slider_changed(value: float, key: String) -> void:
	settings.set_setting(key, value)
	_update_slider_readout(key, value)

func _on_hint_selected(index: int) -> void:
	if index < 0 or index >= _hint_option.item_count:
		return
	var level := String(_hint_option.get_item_metadata(index))
	settings.set_setting("mystery_hint_level", level)

func _begin_binding(action: String) -> void:
	_capture_action = action
	_save_notice.visible = false
	if _binding_buttons.has(action):
		(_binding_buttons[action] as Button).text = _ui("settings.controls.press_input", "Press a key or controller input…")

func _reset_binding(action: String) -> void:
	settings.reset_input_binding(action)
	_refresh_binding_button(action)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _capture_action.is_empty():
		if event.is_action_pressed("ui_back"):
			close()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if event.is_action_pressed("ui_back") and _capture_action != "ui_back":
			var cancelled := _capture_action
			_capture_action = ""
			_refresh_binding_button(cancelled)
			get_viewport().set_input_as_handled()
			return
		if _reject_binding_conflict(key_event):
			return
		settings.set_input_binding(_capture_action, key_event)
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if not button_event.pressed:
			return
		if _reject_binding_conflict(button_event):
			return
		settings.set_input_binding(_capture_action, button_event)
	elif event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) < 0.72:
			return
		if _reject_binding_conflict(motion_event):
			return
		settings.set_input_binding(_capture_action, motion_event)
	else:
		return
	var updated_action := _capture_action
	_capture_action = ""
	_refresh_binding_button(updated_action)
	get_viewport().set_input_as_handled()

func _reject_binding_conflict(event: InputEvent) -> bool:
	if settings == null:
		return false
	for action_value in settings.get_rebindable_actions():
		var action := String(action_value)
		if action == _capture_action or not InputMap.event_is_action(event, action, true):
			continue
		var rejected_action := _capture_action
		_capture_action = ""
		_refresh_binding_button(rejected_action)
		_save_notice.text = _ui("settings.controls.binding_conflict", "That input is already assigned to %s.") % _action_title(action)
		_save_notice.visible = true
		get_viewport().set_input_as_handled()
		return true
	return false

func _on_setting_changed(key: String, _value: Variant) -> void:
	_refresh_controls()
	if key == "all":
		_emit_current_values()
		return
	if key == "input_remaps":
		for action in settings.get_rebindable_actions():
			_refresh_binding_button(String(action))
			input_remap_changed.emit(String(action), settings.get_input_bindings(String(action)))
		return
	_emit_setting_signal(key)
	if key in ["reduced_animation", "reduced_flashing"]:
		_emit_visual_effects()

func _refresh_controls() -> void:
	if settings == null:
		return
	for key in _controls:
		var control: Control = _controls[key]
		var value: Variant = settings.get_setting(String(key))
		if control is CheckBox:
			(control as CheckBox).set_pressed_no_signal(bool(value))
		elif control is HSlider:
			var slider := control as HSlider
			slider.set_value_no_signal(float(value))
			_update_slider_readout(String(key), float(value))
	if _stock_enabled != null:
		_stock_enabled.set_pressed_no_signal(bool(settings.get_setting("auto_stock", {}).get("enabled", false)))
	if _stock_product != null and _stock_product.item_count > 0:
		_stock_target.set_value_no_signal(settings.get_auto_stock_target(_selected_product_id()))
	if _hint_option != null:
		var hint_value := String(settings.get_setting("mystery_hint_level", "contextual"))
		for index in range(_hint_option.item_count):
			if String(_hint_option.get_item_metadata(index)) == hint_value:
				_hint_option.select(index)
				break
	for action in _binding_buttons:
		_refresh_binding_button(String(action))

func _selected_product_id() -> String:
	if _stock_product == null or _stock_product.item_count == 0:
		return ""
	var metadata: Variant = _stock_product.get_item_metadata(_stock_product.selected)
	return "" if metadata == null else str(metadata)

func _refresh_binding_button(action: String) -> void:
	if not _binding_buttons.has(action):
		return
	var button := _binding_buttons[action] as Button
	if action == _capture_action:
		button.text = _ui("settings.controls.press_input", "Press a key or controller input…")
		return
	var events := settings.get_input_bindings(action)
	if events.is_empty():
		events = settings.get_default_input_bindings(action)
	var labels: Array[String] = []
	for event in events:
		labels.append(_format_binding_event(event))
	button.text = "  /  ".join(labels) if not labels.is_empty() else _ui("settings.controls.unbound", "Unbound")

func _format_binding_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var label := key_event.as_text().strip_edges()
		if key_event.physical_keycode != 0:
			for suffix in [" - Physical", " (Physical)", "(Physical)"]:
				if label.ends_with(String(suffix)):
					label = label.trim_suffix(String(suffix)).strip_edges()
		return label
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		match button_event.button_index:
			0: return _ui("settings.controls.button.face_bottom", "Face bottom")
			1: return _ui("settings.controls.button.face_right", "Face right")
			2: return _ui("settings.controls.button.face_left", "Face left")
			3: return _ui("settings.controls.button.face_top", "Face top")
			4: return _ui("settings.controls.button.back", "Back")
			5: return _ui("settings.controls.button.system", "System")
			6: return _ui("settings.controls.button.menu", "Menu")
			7: return _ui("settings.controls.button.left_stick_click", "Left stick click")
			8: return _ui("settings.controls.button.right_stick_click", "Right stick click")
			9: return _ui("settings.controls.button.left_shoulder", "Left shoulder")
			10: return _ui("settings.controls.button.right_shoulder", "Right shoulder")
			11: return _ui("settings.controls.button.dpad_up", "D-pad ↑")
			12: return _ui("settings.controls.button.dpad_down", "D-pad ↓")
			13: return _ui("settings.controls.button.dpad_left", "D-pad ←")
			14: return _ui("settings.controls.button.dpad_right", "D-pad →")
		return _ui("settings.controls.button.unknown", "Button %d") % button_event.button_index
	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		match motion_event.axis:
			4: return _ui("settings.controls.axis.left_trigger", "Left trigger")
			5: return _ui("settings.controls.axis.right_trigger", "Right trigger")
		var direction := ""
		match motion_event.axis:
			0, 2: direction = "←" if motion_event.axis_value < 0.0 else "→"
			1, 3: direction = "↑" if motion_event.axis_value < 0.0 else "↓"
			_: return _ui("settings.controls.axis.unknown", "Axis %d") % motion_event.axis
		var stick := _ui("settings.controls.axis.left_stick", "Left stick") if motion_event.axis in [0, 1] else _ui("settings.controls.axis.right_stick", "Right stick")
		return "%s %s" % [stick, direction]
	return event.as_text()

func _update_slider_readout(key: String, value: float) -> void:
	if not _readouts.has(key):
		return
	var data: Dictionary = _readouts[key]
	var suffix := String(data.get("suffix", ""))
	var display := _format_locale_number(value * 100.0, 0) + "%" if suffix == "%" else (_format_locale_number(value, 2) + "×" if suffix == "×" else _format_locale_number(value, 2))
	(data["label"] as Label).text = display

func _format_locale_number(value: float, decimal_places: int) -> String:
	var formatted := ("%." + str(maxi(0, decimal_places)) + "f") % value
	var language := String(locale_language_lookup.call()) if locale_language_lookup.is_valid() else OS.get_locale_language().to_lower()
	if language.begins_with("es"):
		formatted = formatted.replace(".", ",")
	return formatted

func _emit_current_values() -> void:
	_emit_setting_signal("game_speed")
	_emit_setting_signal("assisted_checkout")
	_emit_setting_signal("simplified_crafting")
	_emit_auto_stock()
	_emit_setting_signal("ui_scale")
	_emit_setting_signal("dyslexia_friendly_text")
	_emit_setting_signal("reduced_animation")
	_emit_setting_signal("reduced_flashing")
	_emit_setting_signal("visual_effects_enabled")
	_emit_setting_signal("dynamic_lighting")
	_emit_setting_signal("music_volume")
	_emit_setting_signal("sfx_volume")
	_emit_setting_signal("mystery_hint_level")
	for action in settings.get_rebindable_actions():
		input_remap_changed.emit(String(action), settings.get_input_bindings(String(action)))

func _emit_setting_signal(key: String) -> void:
	match key:
		"game_speed": game_speed_changed.emit(float(settings.get_setting(key, 1.0)))
		"assisted_checkout": assisted_checkout_changed.emit(bool(settings.get_setting(key, false)))
		"simplified_crafting": simplified_crafting_changed.emit(bool(settings.get_setting(key, false)))
		"auto_stock": _emit_auto_stock()
		"ui_scale": ui_scale_changed.emit(float(settings.get_setting(key, 1.0)))
		"dyslexia_friendly_text": dyslexia_font_changed.emit(bool(settings.get_setting(key, false)))
		"reduced_animation": reduced_animation_changed.emit(bool(settings.get_setting(key, false)))
		"reduced_flashing": reduced_flashing_changed.emit(bool(settings.get_setting(key, false)))
		"visual_effects_enabled": _emit_visual_effects()
		"dynamic_lighting": lighting_changed.emit(bool(settings.get_setting(key, true)))
		"music_volume", "sfx_volume": audio_levels_changed.emit(float(settings.get_setting("music_volume", 0.8)), float(settings.get_setting("sfx_volume", 0.8)))
		"mystery_hint_level": mystery_hint_level_changed.emit(String(settings.get_setting(key, "contextual")))

func _emit_auto_stock() -> void:
	var config: Dictionary = settings.get_setting("auto_stock", {})
	auto_stock_changed.emit(bool(config.get("enabled", false)), config.get("targets", {}).duplicate(true))

func _emit_visual_effects() -> void:
	visual_effects_changed.emit(bool(settings.get_setting("visual_effects_enabled", true)), bool(settings.get_setting("reduced_animation", false)), bool(settings.get_setting("reduced_flashing", false)))

func _action_title(action: String) -> String:
	var fallback := action.capitalize()
	match action:
		"move_left": fallback = "Move left"
		"move_right": fallback = "Move right"
		"move_up": fallback = "Move toward"
		"move_down": fallback = "Move away"
		"interact": fallback = "Interact"
		"inspect": fallback = "Inspect"
		"run": fallback = "Run faster"
		"ledger": fallback = "Open ledger"
		"town_map": fallback = "Open town map"
		"mystery_board": fallback = "Open mystery board"
		"calendar": fallback = "Open calendar"
		"housekeeping": fallback = "Open housekeeping"
		"upgrades": fallback = "Open upgrades"
		"journal": fallback = "Open journal"
		"inventory": fallback = "Open inventory"
		"pause": fallback = "Pause menu"
		"radio": fallback = "Open radio"
		"companion": fallback = "Open companion"
		"decorate": fallback = "Open decoration mode"
		"ui_back": fallback = "Back / close"
		"ui_select_1": fallback = "Select choice 1"
		"ui_select_2": fallback = "Select choice 2"
		"ui_select_3": fallback = "Select choice 3"
		"ui_select_4": fallback = "Select choice 4"
		"ui_select_5": fallback = "Select choice 5"
		"ui_select_6": fallback = "Select choice 6"
		"ui_select_7": fallback = "Select choice 7"
		"ui_select_8": fallback = "Select choice 8"
		"ui_select_9": fallback = "Select choice 9"
		"decoration_rotate": fallback = "Rotate furniture"
		"decoration_remove": fallback = "Remove furniture"
		"mystery_pin": fallback = "Pin / unpin clue"
		"puzzle_submit": fallback = "Submit puzzle answer"
		"stock_restock": fallback = "Pick up / place one item"
		"stock_restock_all": fallback = "Fill display"
		"stock_markdown": fallback = "Mark down price"
		"stock_markdown_clear": fallback = "Clear price markdown"
		"stock_donate": fallback = "Donate stock"
		"stock_donate_all": fallback = "Donate all available stock"
		"page_previous": fallback = "Previous page"
		"page_next": fallback = "Next page"
		"ledger_refund": fallback = "Refund latest sale"
	return _ui("settings.controls.action.%s" % action, fallback)

func _ui(key: String, fallback: String) -> String:
	if ui_text_lookup.is_valid():
		var translated: Variant = ui_text_lookup.call(key, fallback)
		return String(translated) if translated is String else fallback
	return fallback

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", OPEN_DYSLEXIC_FONT if _readability_enabled else MOONMART_FONT)
	label.set_meta("settings_base_font_size", font_size)
	label.add_theme_font_size_override("font_size", roundi(font_size * (1.12 if _readability_enabled else 1.0)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("29243b"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text_value: String, size: Vector2, localization_key: String = "") -> Button:
	var button := Button.new()
	button.text = _ui(localization_key, text_value) if not localization_key.is_empty() else text_value
	button.add_theme_font_override("font", OPEN_DYSLEXIC_FONT if _readability_enabled else MOONMART_FONT)
	button.custom_minimum_size = size
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("settings_base_font_size", 16)
	button.add_theme_font_size_override("font_size", roundi(16 * (1.12 if _readability_enabled else 1.0)))
	button.add_theme_color_override("font_color", Color("fff8ec"))
	button.add_theme_stylebox_override("normal", _button_style(Color("51445f"), Color("c18b86")))
	button.add_theme_stylebox_override("hover", _button_style(Color("765a70"), Color("f1b47d")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("392f4d"), Color("ffe1a5")))
	button.add_theme_stylebox_override("focus", _button_style(Color("51445f"), Color("ffe1a5")))
	return button

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _apply_focus_ring(control: Control) -> void:
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	focus.border_color = Color("ffe1a5")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(7)
	focus.draw_center = false
	control.add_theme_stylebox_override("focus", focus)

func _journal_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(SETTINGS_PANEL_TEXTURE) as Texture2D
	style.texture_margin_left = 80
	style.texture_margin_top = 80
	style.texture_margin_right = 80
	style.texture_margin_bottom = 80
	style.content_margin_left = 105
	style.content_margin_top = 28
	style.content_margin_right = 105
	style.content_margin_bottom = 24
	return style

