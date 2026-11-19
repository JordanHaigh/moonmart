class_name MoonmartRelationships
extends RefCounted

## Persistent character bonds use remembered moments and promises, not repeat gifts.
signal memory_recorded(character_id: String, memory_id: String)
signal stage_changed(character_id: String, stage: int)
signal promise_remembered(character_id: String, promise_id: String)
signal promise_resolved(character_id: String, promise_id: String, kept: bool)

const STAGE_NAMES: Array[String] = ["Stranger", "Familiar", "Friend", "Confidant", "Kindred"]

var _records: Dictionary = {}

func register_character(character_id: String) -> void:
	if character_id.is_empty() or _records.has(character_id):
		return
	_records[character_id] = {"stage": 0, "memories": [], "promises": {}, "values": {"kindness": 0, "honesty": 0, "care": 0, "listening": 0, "trust": 0, "curiosity": 0, "patience": 0, "promise": 0, "hope": 0, "respect": 0}}

func record_memory(character_id: String, memory_id: String, value_tags: Array[String] = []) -> bool:
	if character_id.is_empty() or memory_id.is_empty():
		return false
	register_character(character_id)
	var record: Dictionary = _records[character_id]
	var memories: Array = record["memories"]
	if memories.has(memory_id):
		return false
	memories.append(memory_id)
	for tag in value_tags:
		if record["values"].has(tag):
			record["values"][tag] = int(record["values"][tag]) + 1
	memory_recorded.emit(character_id, memory_id)
	return true

## Story content explicitly names the milestone that earns the next stage.
## Skipped stages are rejected so optional bond content cannot outrun its story.
func advance_stage(character_id: String, expected_stage: int) -> bool:
	register_character(character_id)
	var current := int(_records[character_id]["stage"])
	if expected_stage != current + 1 or expected_stage >= STAGE_NAMES.size():
		return false
	_records[character_id]["stage"] = expected_stage
	stage_changed.emit(character_id, expected_stage)
	return true

func stage(character_id: String) -> int:
	return int(_records.get(character_id, {}).get("stage", 0))

func stage_name(character_id: String) -> String:
	return STAGE_NAMES[clampi(stage(character_id), 0, STAGE_NAMES.size() - 1)]

func has_memory(character_id: String, memory_id: String) -> bool:
	return _records.get(character_id, {}).get("memories", []).has(memory_id)

func remember_promise(character_id: String, promise_id: String, promise: String) -> bool:
	if character_id.is_empty() or promise_id.is_empty() or promise.is_empty():
		return false
	register_character(character_id)
	var promises: Dictionary = _records[character_id]["promises"]
	if promises.has(promise_id):
		return false
	promises[promise_id] = {"text": promise, "state": "open"}
	promise_remembered.emit(character_id, promise_id)
	return true

func resolve_promise(character_id: String, promise_id: String, kept: bool) -> bool:
	if not _records.get(character_id, {}).get("promises", {}).has(promise_id):
		return false
	var promise: Dictionary = _records[character_id]["promises"][promise_id]
	if promise.get("state") != "open":
		return false
	promise["state"] = "kept" if kept else "released"
	var resolution_traits: Array[String] = []
	if kept:
		resolution_traits.append("honesty")
	record_memory(character_id, "promise:%s:%s" % [promise_id, promise.state], resolution_traits)
	promise_resolved.emit(character_id, promise_id, kept)
	return true

func open_promises(character_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for promise_id in _records.get(character_id, {}).get("promises", {}):
		var row: Dictionary = _records[character_id]["promises"][promise_id]
		if row.get("state") == "open":
			result.append({"id": promise_id, "text": row.get("text", "")})
	return result

func all_open_promises() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for character_id in _records:
		for promise in open_promises(String(character_id)):
			result.append({"character_id": String(character_id), "id": String(promise.get("id", "")), "text": String(promise.get("text", ""))})
	return result

func export_state() -> Dictionary:
	return {"records": _records.duplicate(true)}

func import_state(data: Dictionary) -> void:
	_records = data.get("records", {}).duplicate(true)
	for character_id in _records:
		var record: Dictionary = _records[character_id]
		record["stage"] = clampi(int(record.get("stage", 0)), 0, STAGE_NAMES.size() - 1)
		var normalized_memories: Array[String] = []
		for memory in record.get("memories", []):
			var memory_id := String(memory.get("id", "")) if memory is Dictionary else String(memory)
			if not memory_id.is_empty() and not normalized_memories.has(memory_id):
				normalized_memories.append(memory_id)
		record["memories"] = normalized_memories
		var normalized_promises: Dictionary = {}
		var saved_promises: Variant = record.get("promises", {})
		if saved_promises is Dictionary:
			for promise_id in saved_promises:
				var promise: Variant = saved_promises[promise_id]
				if promise is Dictionary:
					normalized_promises[String(promise_id)] = {"text": String(promise.get("text", "")), "state": String(promise.get("state", "open"))}
		record["promises"] = normalized_promises
		var values: Dictionary = record.get("values", {}).duplicate(true)
		if values.is_empty():
			values = {"kindness": 0, "honesty": 0, "care": 0, "listening": 0, "trust": 0, "curiosity": 0, "patience": 0, "promise": 0, "hope": 0, "respect": 0}
			var legacy_traits: Variant = record.get("traits", {})
			if legacy_traits is Dictionary:
				for legacy_trait in legacy_traits:
					values[String(legacy_trait)] = int(legacy_traits[legacy_trait])
		for tag in ["kindness", "honesty", "care", "listening", "trust", "curiosity", "patience", "promise", "hope", "respect"]:
			if not values.has(tag):
				values[tag] = 0
		record["values"] = values
		_records[character_id] = record
