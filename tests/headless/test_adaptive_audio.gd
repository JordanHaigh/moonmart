extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SETTINGS_SCRIPT = preload("res://scripts/systems/settings_manager.gd")

var _main: Node2D
var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_main = MAIN_SCENE.instantiate() as Node2D
	add_child(_main)
	for _frame in range(4):
		await get_tree().process_frame
	_expect(_main != null and _main.get("game") != null, "main scene initializes the audio systems")
	if _main.get("game") != null:
		_test_weather_score_selection()
		_test_score_transition_families()
		_test_radio_location_gating_and_resume()
		_test_shop_soundscape_routing_and_lifecycle()
		_test_narrative_overlay_gating()
		_test_music_and_sfx_levels()
		await _test_radio_station_persistence()
	_stop_runtime_audio()
	_main.call("_stop_audio_players")
	await get_tree().process_frame
	var audio_restarted := false
	for audio_node in _main.find_children("*", "AudioStreamPlayer", true, false):
		var player := audio_node as AudioStreamPlayer
		audio_restarted = audio_restarted or (player != null and player.playing)
	_expect(not audio_restarted, "runtime teardown prevents the ambient purr from restarting before node release")
	_main.queue_free()
	for _frame in range(3):
		await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_expect(not is_instance_valid(_main), "audio smoke scene releases its runtime nodes")
	if _failures.is_empty():
		print("Adaptive audio checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Adaptive audio checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)

func _test_weather_score_selection() -> void:
	var game: Object = _main.get("game")
	game.set("shift_number", 1)
	game.set("shift_status", "open")
	_main.set("current_location_id", "whisperwood")
	for weather in ["rain", "fog", "wind", "snow"]:
		_force_weather(String(weather))
		var path := String(_main.call("_location_score_path"))
		_expect(path.ends_with("_%s.wav" % String(weather)), "outdoor score selects its %s mix" % String(weather))
		_expect(ResourceLoader.exists(path), "the %s score mix is present" % String(weather))
	for sheltered_location in ["shop_backroom", "tea_corner"]:
		_main.set("current_location_id", sheltered_location)
		_force_weather("rain")
		var path := String(_main.call("_location_score_path"))
		_expect(path == "res://assets/audio/radio/window_seat.wav", "%s keeps the sheltered Window Seat score" % sheltered_location)
	_main.set("current_location_id", "moonmart")
	_force_weather("rain")
	_main.call("_sync_weather_audio")
	var weather_player := _main.get("weather_ambience") as AudioStreamPlayer
	_expect(weather_player != null and weather_player.playing and weather_player.stream != null and weather_player.stream.resource_path.ends_with("moonmart_rain_window.wav"), "rain ambience starts for rainy shop weather")
	_main.call("_apply_visual_comfort_settings", false, false, false)
	_expect(weather_player != null and weather_player.playing, "weather audio continues when visual effects are disabled")
	_force_weather("clear")
	_main.call("_sync_weather_audio")
	_expect(weather_player != null and not weather_player.playing, "rain ambience stops when the selected weather clears")
	_main.call("_apply_visual_comfort_settings", true, false, false)

func _test_score_transition_families() -> void:
	_main.set("current_location_id", "whisperwood")
	_force_weather("rain")
	_main.call("_play_location_score")
	var active_path := String(_main.get("location_music_active_path"))
	_expect(active_path.ends_with("_rain.wav"), "first outdoor score starts on the selected weather mix")
	_force_weather("fog")
	_main.call("_play_location_score")
	_expect(bool(_main.get("location_music_transition_correlated")), "same-location weather variants share a synchronized music family")
	_expect(String(_main.get("location_music_target_path")).ends_with("_fog.wav"), "same-family transition targets the new weather mix")
	_main.call("_update_location_score_transition", 1.0)
	var old_player := _main.get("location_music_player") as AudioStreamPlayer
	var new_player := _main.get("location_music_transition_player") as AudioStreamPlayer
	_expect(old_player != null and new_player != null and old_player.volume_db > -80.0 and new_player.volume_db > -80.0, "same-family transition crossfades both aligned streams")
	_main.call("_update_location_score_transition", 1.0)
	_expect(String(_main.get("location_music_active_path")).ends_with("_fog.wav"), "same-family transition promotes the incoming score")
	_main.set("current_location_id", "moonwater_harbour")
	_main.call("_play_location_score")
	_expect(not bool(_main.get("location_music_transition_correlated")), "travel to another score family starts an independent phrase")
	_main.call("_update_location_score_transition", 2.0)
	_expect(String(_main.get("location_music_active_path")).contains("harbour_lighthouse"), "cross-location transition promotes the destination score")

func _test_radio_location_gating_and_resume() -> void:
	var game: Object = _main.get("game")
	var progression: Object = game.get("shop_progression")
	var owned: Dictionary = progression.get("owned_upgrades")
	owned["shop_radio"] = true
	progression.set("owned_upgrades", owned)
	_main.set("radio_station_index", 2)
	_main.set("current_location_id", "moonmart")
	_main.call("_sync_ambience_for_location")
	var radio := _main.get("radio_player") as AudioStreamPlayer
	_expect(radio != null and radio.playing, "unlocked Moonmart radio starts the selected station")
	_expect(radio != null and radio.stream != null and radio.stream.resource_path.ends_with("harbour_hush.wav"), "radio plays the selected Harbour Hush stream")
	_main.set("current_location_id", "whisperwood")
	_main.call("_sync_ambience_for_location")
	_expect(radio != null and not radio.playing, "radio stops outside Moonmart")
	_main.set("current_location_id", "moonmart")
	_main.call("_sync_ambience_for_location")
	_expect(radio != null and radio.playing and radio.stream.resource_path.ends_with("harbour_hush.wav"), "radio resumes the saved station on return to Moonmart")

func _test_music_and_sfx_levels() -> void:
	_main.call("_apply_audio_levels", 0.0, 0.5)
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	_expect(music_bus >= 0 and AudioServer.get_bus_volume_db(music_bus) <= -79.0, "zero music volume fully mutes the Music bus")
	_expect(sfx_bus >= 0 and is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), linear_to_db(0.5)), "SFX volume changes independently from music")
	_main.call("_apply_audio_levels", 0.8, 0.8)
	var fridge := _main.get("shop_detail_players").get("refrigerator") as AudioStreamPlayer
	var purr := _main.get("miso_purr_player") as AudioStreamPlayer
	_expect(fridge != null and fridge.playing and purr != null and purr.bus == "Music", "resting Miso purr follows the room-ambience Music level")
	_main.call("_apply_visual_comfort_settings", false, true, false)
	_expect(fridge != null and fridge.playing, "reduced visual effects do not disable accessibility independent soundscape")
	_main.call("_apply_visual_comfort_settings", true, false, false)

func _test_shop_soundscape_routing_and_lifecycle() -> void:
	var ambience_paths := [
		"res://assets/audio/ambience/shop/refrigerator_hum.wav",
		"res://assets/audio/ambience/shop/clock_tick.wav",
		"res://assets/audio/ambience/shop/distant_cars.wav",
		"res://assets/audio/ambience/shop/miso_purr.wav"
	]
	var effect_paths := [
		"res://assets/audio/sfx/moonmart_footstep.wav",
		"res://assets/audio/sfx/moonmart_ceramic_cup.wav"
	]
	for path in ambience_paths + effect_paths:
		_expect(ResourceLoader.exists(path), "generated shop sound asset imports: %s" % path.get_file())
	_main.set("current_location_id", "moonmart")
	var game: Object = _main.get("game")
	game.set("shift_status", "open")
	_main.call("_sync_ambience_for_location")
	var detail_players: Dictionary = _main.get("shop_detail_players")
	for detail_id in ["refrigerator", "clock", "distant_cars"]:
		var player := detail_players.get(detail_id) as AudioStreamPlayer
		_expect(player != null and player.playing and player.bus == "Music", "%s room detail loops only in Moonmart through the Music bus" % detail_id)
	var purr := _main.get("miso_purr_player") as AudioStreamPlayer
	_expect(purr == null or not purr.playing, "Miso does not purr while awake on shift")
	_main.set("miso_purr_hold_time", 4.0)
	_main.call("_sync_miso_purr")
	purr = _main.get("miso_purr_player") as AudioStreamPlayer
	_expect(purr != null and purr.playing and purr.bus == "SFX", "a successful-care purr uses SFX and respects its independent level")
	var manager: Node = _main.get("sfx_manager") as Node
	_expect(bool(manager.call("play_sfx", "ceramic_cup")), "service and craft cup effects are available")
	_main.set("footstep_cooldown", 0.0)
	_main.set("message_open", false)
	var body := _main.get("player_body") as CharacterBody2D
	body.velocity = Vector2(100, 0)
	_main.call("_process", 0.016)
	var footstep_found := false
	for player in manager.find_children("SFX_footstep_*", "AudioStreamPlayer", true, false):
		footstep_found = footstep_found or (player as AudioStreamPlayer).playing
	_expect(footstep_found, "movement triggers a restrained footstep through the SFX bus")
	_main.set("current_location_id", "whisperwood")
	_main.call("_sync_ambience_for_location")
	for detail_id in ["refrigerator", "clock", "distant_cars"]:
		var player := detail_players.get(detail_id) as AudioStreamPlayer
		_expect(player != null and not player.playing, "%s ambience stops after leaving Moonmart" % detail_id)
	_expect(purr != null and not purr.playing, "Miso purr stops after leaving Moonmart")
	_main.set("current_location_id", "moonmart")
	game.set("shift_status", "closed")
	_main.call("_sync_ambience_for_location")
	purr = _main.get("miso_purr_player") as AudioStreamPlayer
	_expect(purr != null and purr.playing and purr.bus == "Music", "Miso purr resumes under the room-ambience Music level while resting in Moonmart")

func _test_narrative_overlay_gating() -> void:
	var game: Object = _main.get("game")
	var story: Object = game.get("story")
	var flags: Dictionary = story.get("flags")
	flags["pip_reflection"] = true
	flags["boundary_stabilized"] = false
	story.set("flags", flags)
	game.world_map.set("ending_id", "")
	_main.set("current_location_id", "moonmart")
	_main.call("_sync_narrative_music", 1.0)
	var overlay := _main.get("narrative_music_player") as AudioStreamPlayer
	_expect(overlay != null and overlay.playing, "unresolved Pip reflection starts the separate narrative music overlay in Moonmart")
	for _step in range(12):
		_main.call("_sync_narrative_music", 1.0)
	_expect(overlay != null and is_equal_approx(overlay.volume_db, -18.0), "narrative music fades to its quiet target level")
	flags["boundary_stabilized"] = true
	story.set("flags", flags)
	for _step in range(12):
		_main.call("_sync_narrative_music", 1.0)
	_expect(overlay != null and not overlay.playing, "stabilizing the boundary fades and stops the narrative overlay")
	flags["boundary_stabilized"] = false
	story.set("flags", flags)
	_main.set("current_location_id", "whisperwood")
	_main.call("_sync_narrative_music", 1.0)
	_expect(overlay != null and not overlay.playing, "narrative overlay stays out of locations without an authored mix")

func _test_radio_station_persistence() -> void:
	var settings_manager: Object = _main.get("settings_manager")
	_expect(bool(settings_manager.call("set_setting", "radio_station_id", "harbour_hush")), "selected radio station saves to user settings")
	var reloaded_settings: Object = SETTINGS_SCRIPT.new()
	reloaded_settings.setup()
	_main.set("settings_manager", reloaded_settings)
	_main.set("radio_station_index", 0)
	_main.call("_apply_initial_settings")
	_expect(int(_main.get("radio_station_index")) == 2, "radio station selection restores through a fresh settings manager")

func _force_weather(weather_id: String) -> void:
	var game: Object = _main.get("game")
	var calendar: Object = game.get("calendar")
	var seasons: Array = calendar.get("seasons")
	for index in range(seasons.size()):
		var season: Dictionary = seasons[index].duplicate(true)
		season["weather_weights"] = {weather_id: 1}
		seasons[index] = season
	calendar.set("seasons", seasons)

func _stop_runtime_audio() -> void:
	var game := _main.get("game") as Node
	if game != null:
		game.set_process(false)
	for audio_node in _main.find_children("*", "AudioStreamPlayer", true, false):
		var player := audio_node as AudioStreamPlayer
		if player != null:
			player.stop()

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
