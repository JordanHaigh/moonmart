extends RefCounted

var beats: Dictionary = {}
var start_beat_id := ""
var active := false
var ready_to_wake := false
var current_beat_id := ""
var choice_path: Array[String] = []
var ending_memory_id := ""
var last_response_id := ""

func setup(config: Dictionary) -> void:
	beats.clear()
	for row in config.get("beats", []):
		if not row is Dictionary:
			continue
		var beat_id := String(row.get("id", ""))
		if not beat_id.is_empty():
			beats[beat_id] = row.duplicate(true)
	start_beat_id = String(config.get("start_beat", ""))
	if not beats.has(start_beat_id):
		start_beat_id = String(beats.keys()[0]) if not beats.is_empty() else ""
	active = false
	ready_to_wake = false
	current_beat_id = ""
	choice_path.clear()
	ending_memory_id = ""
	last_response_id = ""

func start() -> Dictionary:
	if active:
		return {"ok":true, "resumed":true, "beat":current_beat()}
	if start_beat_id.is_empty():
		return {"ok":false, "reason":"no_dream_sequence"}
	active = true
	ready_to_wake = false
	current_beat_id = start_beat_id
	choice_path.clear()
	ending_memory_id = ""
	last_response_id = ""
	return {"ok":true, "resumed":false, "beat":current_beat()}

func choose(choice_id: String) -> Dictionary:
	if not active or ready_to_wake:
		return {"ok":false, "reason":"dream_not_accepting_choices"}
	var beat: Dictionary = current_beat()
	for choice_value in beat.get("choices", []):
		if not choice_value is Dictionary or String(choice_value.get("id", "")) != choice_id:
			continue
		var choice: Dictionary = choice_value
		var next_beat_id := String(choice.get("next_beat", ""))
		if not next_beat_id.is_empty() and not beats.has(next_beat_id):
			return {"ok":false, "reason":"missing_next_beat"}
		choice_path.append(choice_id)
		last_response_id = String(choice.get("response_id", ""))
		if bool(choice.get("ready_to_wake", false)):
			ready_to_wake = true
			ending_memory_id = String(choice.get("memory_id", ""))
			return {"ok":true, "ready_to_wake":true, "response_id":last_response_id, "memory_id":ending_memory_id, "beat":current_beat()}
		current_beat_id = next_beat_id
		return {"ok":true, "ready_to_wake":false, "response_id":last_response_id, "beat":current_beat()}
	return {"ok":false, "reason":"unknown_choice"}

func wake() -> Dictionary:
	if not active or not ready_to_wake:
		return {"ok":false, "reason":"dream_not_ready_to_wake"}
	var result := {"ok":true, "memory_id":ending_memory_id, "choice_path":choice_path.duplicate()}
	active = false
	ready_to_wake = false
	current_beat_id = ""
	choice_path.clear()
	ending_memory_id = ""
	last_response_id = ""
	return result

func current_beat() -> Dictionary:
	return beats.get(current_beat_id, {}).duplicate(true)

func export_state() -> Dictionary:
	return {
		"active":active,
		"ready_to_wake":ready_to_wake,
		"current_beat_id":current_beat_id,
		"choice_path":choice_path.duplicate(),
		"ending_memory_id":ending_memory_id,
		"last_response_id":last_response_id
	}

func import_state(data: Dictionary) -> void:
	active = bool(data.get("active", false))
	ready_to_wake = bool(data.get("ready_to_wake", false))
	current_beat_id = String(data.get("current_beat_id", ""))
	choice_path.clear()
	for choice_value in data.get("choice_path", []):
		choice_path.append(String(choice_value))
	ending_memory_id = String(data.get("ending_memory_id", ""))
	last_response_id = String(data.get("last_response_id", ""))
	if active and not beats.has(current_beat_id):
		active = false
		ready_to_wake = false
		current_beat_id = ""
		choice_path.clear()
		ending_memory_id = ""
		last_response_id = ""
	if not active:
		ready_to_wake = false
		current_beat_id = ""
