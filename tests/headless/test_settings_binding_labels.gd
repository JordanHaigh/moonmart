extends SceneTree

const SETTINGS_PANEL := preload("res://scripts/ui/settings_panel.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel := SETTINGS_PANEL.new()
	var physical_key := InputEventKey.new()
	physical_key.physical_keycode = KEY_E
	var display_name := String(panel.call("_format_binding_event", physical_key))
	print("Key event as_text='%s'; normalized='%s'" % [physical_key.as_text(), display_name])
	_expect(not display_name.contains("Physical"), "physical keyboard binding removes the technical suffix")
	_expect(display_name.contains("E"), "physical keyboard binding preserves the key name")
	var joypad_button := InputEventJoypadButton.new()
	joypad_button.button_index = JOY_BUTTON_A
	var controller_label := String(panel.call("_format_binding_event", joypad_button))
	_expect(controller_label == "Face bottom" and controller_label != joypad_button.as_text(), "controller binding uses the neutral face position instead of a layout-specific Godot label")
	panel.free()
	if _failures.is_empty():
		print("Settings binding-label checks passed: 3 checks.")
	else:
		for failure in _failures:
			push_error(failure)
		print("Settings binding-label checks failed: %d." % _failures.size())
	quit(0 if _failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
