extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const PROFILE_SEED := 20261113

var _output_dir := ""
var _main: Node
var _game: Object
var _customers: Object
var _clock: Object
var _frame_csv: FileAccess
var _summary_csv: FileAccess
var _phase_frames: Dictionary = {}
var _pending_frame_rows := PackedStringArray()
var _fixture_ids: Array[String] = []
var _event_csv: FileAccess
var _stall_csv: FileAccess
var _stall_threshold_ms := 33.4
const ROTATION_INTERVAL_SECONDS := 10.0
var _rotation_index := 0
var _current_phase := ""
var _current_phase_start_usec := 0
var _last_event := ""
var _last_event_usec := 0
var _pre_draw_usec := 0
var _post_draw_usec := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_output_dir = OS.get_environment("MOONMART_PROFILE_OUTPUT")
	if _output_dir.is_empty():
		push_error("Set MOONMART_PROFILE_OUTPUT to an isolated report directory.")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(_output_dir) != OK:
		push_error("Could not create profile output directory: %s" % _output_dir)
		quit(2)
		return
	var save_path := ProjectSettings.globalize_path("user://moonmart_save.json")
	if FileAccess.file_exists(save_path):
		push_error("Refusing to profile with an existing save in the isolated user-data directory: %s" % save_path)
		quit(2)
		return
	root.size = Vector2i(1600, 900)
	if DisplayServer.get_name().to_lower() != "headless":
		DisplayServer.window_set_size(Vector2i(1600, 900))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load the main game scene for profiling.")
		quit(2)
		return
	_main = packed.instantiate()
	root.add_child(_main)
	for _frame in range(90):
		await process_frame
	_game = _main.get("game")
	if _game == null:
		push_error("Main scene did not initialize MoonmartGame.")
		quit(2)
		return
	_customers = _game.get("customers")
	_clock = _game.get("clock")
	if _customers == null or _clock == null:
		push_error("Game customer manager or shift clock is unavailable.")
		quit(2)
		return
	var frames_path := _output_dir.path_join("frame_samples.csv")
	_frame_csv = FileAccess.open(frames_path, FileAccess.WRITE)
	_summary_csv = FileAccess.open(_output_dir.path_join("phase_summary.csv"), FileAccess.WRITE)
	if _frame_csv == null or _summary_csv == null:
		push_error("Could not open the profile result files.")
		quit(2)
		return
	_event_csv = FileAccess.open(_output_dir.path_join("fixture_events.csv"), FileAccess.WRITE)
	_stall_csv = FileAccess.open(_output_dir.path_join("stall_events.csv"), FileAccess.WRITE)
	if _event_csv == null or _stall_csv == null:
		push_error("Could not open the profile diagnostic files.")
		quit(2)
		return
	_stall_threshold_ms = _environment_seconds("MOONMART_PROFILE_STALL_MS", 33.4)
	_frame_csv.store_line("phase,elapsed_seconds,frame_ms,static_memory_mib,node_count,render_objects,render_primitives,process_ms,draw_ms,rest_ms")
	_event_csv.store_line("phase,elapsed_seconds,event,detail")
	_stall_csv.store_line("phase,elapsed_seconds,frame_ms,process_ms,draw_ms,rest_ms,static_memory_delta_mib,last_fixture_event,seconds_since_event")
	_game.connect("customer_state_changed", _on_profile_customer_state_changed)
	_game.connect("customer_changed", _on_profile_customer_changed)
	RenderingServer.frame_pre_draw.connect(_on_profile_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_profile_post_draw)
	_summary_csv.store_line("phase,samples,frame_median_ms,frame_p95_ms,frame_p99_ms,frame_max_ms,one_percent_low_fps")
	var warmup_seconds := _environment_seconds("MOONMART_PROFILE_WARMUP_SECONDS", 20.0)
	var baseline_seconds := _environment_seconds("MOONMART_PROFILE_BASELINE_SECONDS", 30.0)
	var active_seconds := _environment_seconds("MOONMART_PROFILE_ACTIVE_SECONDS", 90.0)
	var ui_seconds := _environment_seconds("MOONMART_PROFILE_UI_SECONDS", 15.0)
	var resumed_seconds := _environment_seconds("MOONMART_PROFILE_RESUMED_SECONDS", 30.0)
	var rainy_shift := _find_weather_shift("rain")
	if rainy_shift <= 0:
		push_error("Calendar has no deterministic rainy shift for the performance fixture.")
		quit(2)
		return
	_configure_active_shift(rainy_shift)
	_configure_effects()
	_install_visitor_fixture()
	_write_metadata()
	await _sample_phase("warmup_discarded", warmup_seconds, true, false)
	_remove_visitor_fixture()
	_release_profile_input()
	_configure_closed_baseline()
	await _sample_phase("baseline_shop", baseline_seconds, false, true)
	_configure_active_shift(rainy_shift)
	_install_visitor_fixture()
	await _sample_phase("active_rain_visitors_movement", active_seconds, true, true)
	_open_dialogue_and_journal()
	await _sample_phase("dialogue_journal_ui", ui_seconds, false, true)
	_dismiss_profile_ui()
	await _sample_phase("active_resumed", resumed_seconds, true, true)
	_release_profile_input()
	_frame_csv.close()
	_summary_csv.close()
	_event_csv.close()
	_stall_csv.close()
	_game.disconnect("customer_state_changed", _on_profile_customer_state_changed)
	_game.disconnect("customer_changed", _on_profile_customer_changed)
	RenderingServer.frame_pre_draw.disconnect(_on_profile_pre_draw)
	RenderingServer.frame_post_draw.disconnect(_on_profile_post_draw)
	var unexpected_save := FileAccess.file_exists(save_path)
	var status := "PASS" if not unexpected_save else "FAIL"
	var metadata := JSON.parse_string(FileAccess.get_file_as_string(_output_dir.path_join("metadata.json"))) as Dictionary
	metadata["status"] = status
	metadata["unexpected_save_found"] = unexpected_save
	FileAccess.open(_output_dir.path_join("metadata.json"), FileAccess.WRITE).store_string(JSON.stringify(metadata, "\t"))
	print("Gameplay profile %s: %s" % [status, _output_dir])
	if unexpected_save:
		push_error("Profile fixture wrote a save despite the no-save contract: %s" % save_path)
		quit(1)
		return
	_main.queue_free()
	for _frame in range(3):
		await process_frame
	quit(0)

func _configure_active_shift(shift_number: int) -> void:
	_game.set("shift_number", shift_number)
	_game.set("shift_status", "open")
	var calendar: Object = _game.get("calendar")
	calendar.call("set_current_shift", shift_number)
	_clock.call("set_shift_profile", shift_number)
	_clock.set("running", true)
	_clock.set("paused", false)
	_clock.set("elapsed_minutes", float(_clock.get("prep_minutes")) + 1.0)
	_clock.set("_finish_emitted", false)
	_clock.call("emit_time")
	_main.call("_on_shift_changed", shift_number, "open")
	_game.set("_pending_optional_events", [])
	_game.set("_optional_event_timer", 999999.0)
	_customers.set("_spawn_timer", 999999.0)

func _configure_closed_baseline() -> void:
	var clear_shift := _find_weather_shift("clear")
	if clear_shift <= 0:
		clear_shift = 1
	_game.set("shift_number", clear_shift)
	_game.set("shift_status", "closed")
	var calendar: Object = _game.get("calendar")
	calendar.call("set_current_shift", clear_shift)
	_clock.set("running", false)
	_clock.set("paused", false)
	_clock.set("elapsed_minutes", 0.0)
	_clock.call("emit_time")
	_main.call("_on_shift_changed", clear_shift, "closed")
	_main.set("active_panel", "")
	_main.set("message_open", false)
	_main.get("message_panel").set("visible", false)
	_customers.set("_spawn_timer", 999999.0)
	_game.set("_pending_optional_events", [])
	_game.set("_optional_event_timer", 999999.0)

func _configure_effects() -> void:
	_main.call("_apply_visual_comfort_settings", true, false, false)
	_main.call("_apply_dynamic_lighting_setting", true)
	_main.set("reduced_animation_enabled", false)
	_main.set("reduced_flashing_enabled", false)
	_main.set("environment_effect_overrides", {"rain":true, "seasonal":true, "memory":true, "steam":true})

func _install_visitor_fixture() -> void:
	_customers.get("rng").set("seed", PROFILE_SEED)
	var active: Array = _customers.get("active")
	var queue: Array = _customers.get("queue")
	active.clear()
	queue.clear()
	_fixture_ids.clear()
	var ordinary_ids: Array = _customers.get("ordinary_customer_ids").keys()
	ordinary_ids.sort()
	var ids: Array[String] = ["agnes", "lucien"]
	for index in range(mini(2, ordinary_ids.size())):
		ids.append(String(ordinary_ids[index]))
	for index in range(ids.size()):
		var visitor_id := ids[index]
		if not _customers.get("definitions").has(visitor_id):
			continue
		var is_ordinary: bool = _customers.get("ordinary_customer_ids").has(visitor_id)
		var visitor: Dictionary = _customers.call("_make_customer", visitor_id, not is_ordinary, {})
		visitor["state"] = "ARRIVING" if index % 2 == 0 else "BROWSING"
		visitor["state_elapsed"] = 0.0
		visitor["browse_duration"] = 12.0
		visitor["linger_duration"] = 15.0
		visitor["conversation_duration"] = 18.0
		active.append(visitor)
		_fixture_ids.append(visitor_id)
	for visitor in active:
		_main.call("_on_customer_changed", visitor, true, false)
		_main.call("_on_customer_state_changed", visitor, String(visitor.get("state", "ARRIVING")))
	_main.call("_sync_ambience_for_location")
	_main.call("_sync_location_weather_effects", int(_game.get("shift_number")))

# Departure then fresh arrival of one visitor, so long phases exercise arrivals and
# departures instead of measuring a static queue. In-memory only; no checkout or save.
func _rotate_visitor() -> void:
	var visitor_id: String = _fixture_ids[_rotation_index % _fixture_ids.size()]
	_rotation_index += 1
	var active: Array = _customers.get("active")
	for index in range(active.size() - 1, -1, -1):
		if String(active[index].get("id", "")) == visitor_id:
			active.remove_at(index)
	_main.call("_on_customer_changed", {"id":visitor_id}, false, false)
	var is_ordinary: bool = _customers.get("ordinary_customer_ids").has(visitor_id)
	var visitor: Dictionary = _customers.call("_make_customer", visitor_id, not is_ordinary, {})
	visitor["state"] = "ARRIVING"
	visitor["state_elapsed"] = 0.0
	visitor["browse_duration"] = 8.0
	visitor["linger_duration"] = 6.0
	visitor["conversation_duration"] = 10.0
	active.append(visitor)
	_main.call("_on_customer_changed", visitor, true, false)
	_main.call("_on_customer_state_changed", visitor, "ARRIVING")
	_record_fixture_event("rotate", visitor_id)

func _remove_visitor_fixture() -> void:
	for visitor_id in _fixture_ids:
		_main.call("_on_customer_changed", {"id":visitor_id}, false, false)
	_customers.get("active").clear()
	_customers.get("queue").clear()
	_fixture_ids.clear()

func _open_dialogue_and_journal() -> void:
	var selected_id := ""
	for visitor_id in _fixture_ids:
		var customer: Dictionary = _customers.call("get_customer", visitor_id)
		if String(customer.get("state", "")) in ["BROWSING", "LINGERING"]:
			selected_id = visitor_id
			break
	if not selected_id.is_empty():
		_customers.call("begin_conversation", selected_id)
	_main.call("_on_message_changed", "A quiet night settles over Moonmart. Visitors browse beneath the painted moonlight while rain moves across the separate window-effects layer.")
	_main.call("_toggle_panel", "journal")

func _dismiss_profile_ui() -> void:
	if bool(_main.get("message_open")):
		_main.call("_dismiss_message")
	if String(_main.get("active_panel")) == "journal":
		_main.call("_close_side_panel")

func _sample_phase(phase: String, seconds: float, move_player: bool, capture_samples: bool) -> void:
	var frame_ms: Array[float] = []
	_phase_frames[phase] = 0
	var previous_static_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / (1024.0 * 1024.0)
	var phase_start := Time.get_ticks_usec()
	_current_phase = phase
	_current_phase_start_usec = phase_start
	var previous_frame := phase_start
	var next_rotation := ROTATION_INTERVAL_SECONDS
	while float(Time.get_ticks_usec() - phase_start) / 1000000.0 < seconds:
		await process_frame
		var now := Time.get_ticks_usec()
		var elapsed := float(now - phase_start) / 1000000.0
		if move_player:
			_apply_profile_input(elapsed)
			if not _fixture_ids.is_empty() and elapsed >= next_rotation:
				next_rotation += ROTATION_INTERVAL_SECONDS
				_rotate_visitor()
		var delta_ms := float(now - previous_frame) / 1000.0
		var frame_start := previous_frame
		previous_frame = now
		_phase_frames[phase] = int(_phase_frames[phase]) + 1
		if not capture_samples:
			continue
		var static_memory_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / (1024.0 * 1024.0)
		var node_count := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var render_objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		var render_primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		# Split the interval since the previous process_frame signal into three parts:
		# process (scripts and scene processing, up to the pre-draw signal), draw (rendering and
		# buffer swap, up to the post-draw signal), and rest (frame-cap sleep, OS event pump,
		# physics step). A value of -1 means the draw signals did not arrive for that frame.
		var process_ms := -1.0
		var draw_ms := -1.0
		var rest_ms := -1.0
		if _pre_draw_usec >= frame_start and _post_draw_usec >= _pre_draw_usec and now >= _post_draw_usec:
			process_ms = float(_pre_draw_usec - frame_start) / 1000.0
			draw_ms = float(_post_draw_usec - _pre_draw_usec) / 1000.0
			rest_ms = float(now - _post_draw_usec) / 1000.0
		frame_ms.append(delta_ms)
		_pending_frame_rows.append("%s,%.6f,%.4f,%.3f,%d,%d,%d,%.4f,%.4f,%.4f" % [phase, elapsed, delta_ms, static_memory_mib, node_count, render_objects, render_primitives, process_ms, draw_ms, rest_ms])
		if delta_ms >= _stall_threshold_ms:
			var seconds_since_event := float(now - _last_event_usec) / 1000000.0 if _last_event_usec > 0 else -1.0
			_stall_csv.store_line("%s,%.6f,%.4f,%.4f,%.4f,%.4f,%.3f,%s,%.6f" % [phase, elapsed, delta_ms, process_ms, draw_ms, rest_ms, static_memory_mib - previous_static_mib, _last_event, seconds_since_event])
			_stall_csv.flush()
		previous_static_mib = static_memory_mib
	if capture_samples:
		_frame_csv.store_string("\n".join(_pending_frame_rows) + "\n")
		_pending_frame_rows.clear()
		_write_phase_summary(phase, frame_ms)

func _on_profile_customer_state_changed(customer: Dictionary, state: String) -> void:
	_record_fixture_event("customer_state", "%s:%s" % [String(customer.get("id", "")), state])

func _on_profile_customer_changed(customer: Dictionary, arrived: bool) -> void:
	_record_fixture_event("customer_arrived" if arrived else "customer_left", String(customer.get("id", "")))

func _on_profile_pre_draw() -> void:
	_pre_draw_usec = Time.get_ticks_usec()

func _on_profile_post_draw() -> void:
	_post_draw_usec = Time.get_ticks_usec()

func _record_fixture_event(event: String, detail: String) -> void:
	if _event_csv == null or _current_phase.is_empty():
		return
	_last_event_usec = Time.get_ticks_usec()
	_last_event = "%s=%s" % [event, detail]
	_event_csv.store_line("%s,%.6f,%s,%s" % [_current_phase, float(_last_event_usec - _current_phase_start_usec) / 1000000.0, event, detail])

func _write_phase_summary(phase: String, frame_ms: Array[float]) -> void:
	if frame_ms.is_empty():
		return
	var sorted_frames := frame_ms.duplicate()
	sorted_frames.sort()
	var p99_frame := _percentile(sorted_frames, 0.99)
	_summary_csv.store_line("%s,%d,%.4f,%.4f,%.4f,%.4f,%.2f" % [phase, frame_ms.size(), _percentile(sorted_frames, 0.50), _percentile(sorted_frames, 0.95), p99_frame, sorted_frames.back(), 1000.0 / maxf(p99_frame, 0.001)])

func _percentile(sorted_values: Array[float], fraction: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index := clampi(ceili(float(sorted_values.size()) * fraction) - 1, 0, sorted_values.size() - 1)
	return sorted_values[index]

func _apply_profile_input(elapsed: float) -> void:
	var direction := "move_right" if int(elapsed / 4.0) % 2 == 0 else "move_left"
	var depth_direction := "move_down" if int(elapsed / 8.0) % 2 == 0 else "move_up"
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	Input.action_press(direction)
	Input.action_press(depth_direction)

func _release_profile_input() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func _find_weather_shift(weather_id: String) -> int:
	var calendar: Object = _game.get("calendar")
	var days_per_year := int(calendar.get("days_per_year"))
	for shift_number in range(1, days_per_year * 4 + 1):
		if String(calendar.call("weather_for_shift", shift_number)) == weather_id:
			return shift_number
	return -1

func _write_metadata() -> void:
	var metadata := {
		"godot_version": Engine.get_version_info(),
		"renderer": RenderingServer.get_video_adapter_api_version(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"gpu_name": RenderingServer.get_video_adapter_name(),
		"os": OS.get_name(),
		"window_size": "1600x900",
		"vsync": "disabled; deterministic Engine.max_fps cap is 60",
		"max_fps": 60,
		"audio_driver": "system default; no dummy driver override",
		"random_seed": PROFILE_SEED,
		"main_scene": MAIN_SCENE_PATH,
		"shift": int(_game.get("shift_number")),
		"season": String(_game.get("calendar").call("current_season").get("id", "")),
		"weather": String(_game.get("calendar").call("current_weather")),
		"fixture_ids": _fixture_ids,
		"active_visitor_count": _customers.get("active").size(),
		"effect_fixture": "rainy Moonmart shift; visual effects and dynamic lighting enabled",
		"visitor_fixture": "Agnes, Lucien, and two deterministic ordinary archetypes; in-memory only",
		"save_contract": "fresh isolated user-data directory; begin_shift/save/checkout/story resolution not invoked"
	}
	FileAccess.open(_output_dir.path_join("metadata.json"), FileAccess.WRITE).store_string(JSON.stringify(metadata, "\t"))

func _environment_seconds(name: String, fallback: float) -> float:
	var value := OS.get_environment(name)
	return maxf(0.1, float(value)) if not value.is_empty() else fallback
