class_name MoonmartSfxManager
extends Node

## Optional short-form sound effects. Missing catalog entries or audio files are silent no-ops.
const CATALOG_PATH := "res://data/audio_sfx.json"

var _events: Dictionary = {}
var _players: Dictionary = {}
var _loaded_streams: Dictionary = {}

func _ready() -> void:
	_load_catalog()

func _exit_tree() -> void:
	for voice_pool in _players.values():
		for candidate in voice_pool:
			var player := candidate as AudioStreamPlayer
			if player != null:
				player.stop()
				player.stream = null
	_players.clear()
	_loaded_streams.clear()

func play_door_bell() -> bool:
	return play_sfx("door_bell")

func play_threshold_door_bell() -> bool:
	return play_sfx("threshold_door_bell")

func play_register_chime() -> bool:
	return play_sfx("register_chime")

func play_threshold_register_chime() -> bool:
	return play_sfx("threshold_register_chime")

func play_story_reveal() -> bool:
	return play_sfx("story_reveal")

func play_sfx(event_id: String) -> bool:
	var definition: Dictionary = _events.get(event_id, {})
	if definition.is_empty():
		return false
	var resource_path := String(definition.get("path", ""))
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
		return false
	var stream: AudioStream = _loaded_streams.get(resource_path) as AudioStream
	if stream == null:
		stream = load(resource_path) as AudioStream
		if stream == null:
			return false
		_loaded_streams[resource_path] = stream

	var voice_pool: Array = _players.get(event_id, [])
	if voice_pool.is_empty():
		voice_pool = _create_voice_pool(event_id, definition)
		if voice_pool.is_empty():
			return false
		_players[event_id] = voice_pool

	var selected_player: AudioStreamPlayer
	for candidate in voice_pool:
		var player := candidate as AudioStreamPlayer
		if player != null and not player.playing:
			selected_player = player
			break
	if selected_player == null:
		return false
	selected_player.stream = stream
	selected_player.volume_db = float(definition.get("volume_db", 0.0))
	selected_player.play()
	return true

func _load_catalog() -> void:
	if not ResourceLoader.exists(CATALOG_PATH):
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var events: Variant = parsed.get("events", {})
		if events is Dictionary:
			_events = events

func _create_voice_pool(event_id: String, definition: Dictionary) -> Array:
	var pool: Array = []
	var voice_count := clampi(int(definition.get("voices", 1)), 1, 4)
	var requested_bus := String(definition.get("bus", "SFX"))
	var bus_name := requested_bus if AudioServer.get_bus_index(requested_bus) >= 0 else "Master"
	for voice_index in range(voice_count):
		var player := AudioStreamPlayer.new()
		player.name = "SFX_%s_%d" % [event_id, voice_index + 1]
		player.bus = bus_name
		add_child(player)
		pool.append(player)
	return pool
