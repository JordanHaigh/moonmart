class_name MoonmartNarrative
extends RefCounted

## Narrative state is flag-driven. Shift number is stored as scheduling context,
## but it never grants or removes access to an essential story event.
signal journal_changed

const QUESTS_PATH := "res://data/quests.json"
const INVESTIGATIONS_PATH := "res://data/investigations.json"
const CLUES_PATH := "res://data/clues.json"
const LOCATIONS_PATH := "res://data/locations.json"
const ENDING_MEMORIES_PATH := "res://data/ending_memories.json"

const STAGE_NAMES := ["Stranger", "Familiar", "Friend", "Confidant", "Kindred"]

var flags: Dictionary = {}
var clues: Array[String] = []
var pinned_clues: Array[String] = []
var queued_events: Array[Dictionary] = []
var completed_events: Array[String] = []
var relationships: Dictionary = {}
var investigation_state: Dictionary = {}
var ending_memories: Dictionary = {}
var chapter: int = 1
var selected_ending := ""
var world_state := "ordinary_midnight"

var chapter_definitions: Array[Dictionary] = []
var story_events: Array[Dictionary] = []
var event_definitions: Dictionary = {}
var investigation_definitions: Dictionary = {}
var clue_definitions: Dictionary = {}
var location_definitions: Dictionary = {}
var ending_definitions: Dictionary = {}
var ending_memory_definitions: Array[Dictionary] = []
var ui_text_lookup: Callable = Callable()
var _loaded := false

func _ensure_loaded() -> void:
	if _loaded:
		return
	var quest_data := _read_json(QUESTS_PATH)
	chapter_definitions.assign(quest_data.get("chapters", []))
	story_events.assign(quest_data.get("story_events", []))
	for row in story_events:
		if row.has("id"):
			event_definitions[String(row.id)] = row
	for row in quest_data.get("endings", []):
		if row is Dictionary and row.has("id"):
			ending_definitions[String(row.id)] = row
	for row in _read_json(INVESTIGATIONS_PATH).get("investigations", []):
		if row is Dictionary and row.has("id"):
			investigation_definitions[String(row.id)] = row
	for row in _read_json(CLUES_PATH).get("clues", []):
		if row is Dictionary and row.has("id"):
			clue_definitions[String(row.id)] = row
	for row in _read_json(LOCATIONS_PATH).get("locations", []):
		if row is Dictionary and row.has("id"):
			location_definitions[String(row.id)] = row
	for row in _read_json(ENDING_MEMORIES_PATH).get("ending_memories", []):
		if row is Dictionary and row.has("id") and row.has("activity_id"):
			ending_memory_definitions.append(row.duplicate(true))
	_loaded = true

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func begin_shift(_shift_number: int) -> Array:
	# Essential visits are scheduled only by MoonmartQuests. This deprecated
	# entry point remains for older callers but must not create a second queue.
	_ensure_loaded()
	_advance_chapter()
	return []

func resolve_event(event_id: String, from_quest_queue: bool = false) -> Dictionary:
	_ensure_loaded()
	if completed_events.has(event_id) or not event_definitions.has(event_id):
		return {}
	var event: Dictionary = event_definitions[event_id]
	var queued_index := -1
	for index in range(queued_events.size() - 1, -1, -1):
		if String(queued_events[index].get("id", "")) == event_id:
			queued_index = index
			break
	if queued_index < 0 and not from_quest_queue:
		return {}
	# Recheck prerequisites in case a migrated or edited save contains stale work.
	if not _requirements_met(event.get("requires_flags", [])):
		return {}
	if queued_index >= 0:
		queued_events.remove_at(queued_index)
	completed_events.append(event_id)
	flags[event_id] = true
	for clue_id in event.get("clues", []):
		_add_clue(String(clue_id))
	var memory: Dictionary = event.get("memory", {})
	if not memory.is_empty():
		record_memory(String(memory.get("character", "")), String(memory.get("id", event_id)), String(memory.get("text", "")), String(memory.get("trait", "kindness")))
	for flag in event.get("grants_flags", []):
		flags[String(flag)] = true
	_advance_chapter()
	journal_changed.emit()
	return event.duplicate(true)

func inspect(target_id: String, shift_number: int) -> String:
	_ensure_loaded()
	for clue_id in clue_definitions:
		var clue: Dictionary = clue_definitions[clue_id]
		if bool(clue.get("hidden_perception", false)):
			continue
		if String(clue.get("target", "")) != target_id or clues.has(String(clue_id)):
			continue
		if not _requirements_met(clue.get("requires_flags", [])):
			continue
		if int(clue.get("chapter", 1)) > chapter:
			continue
		_add_clue(String(clue_id))
		var granted_flag := String(clue.get("grants_flag", ""))
		if not granted_flag.is_empty():
			flags[granted_flag] = true
		journal_changed.emit()
		return String(clue.get("text", "You notice a small detail worth remembering."))
	# Keep the original slice's inspect locations usable after loading a legacy save.
	if target_id == "register" and shift_number >= 3 and flags.get("pip_reflection", false):
		_add_clue("receipt_dated_1974")
		journal_changed.emit()
		return "An old receipt curls from the register: strawberry milk, dated 1974."
	if target_id == "back_door" and flags.get("pip_first_memory", false):
		_add_clue("door_in_the_wall")
		flags["hidden_midnight_room_found"] = true
		journal_changed.emit()
		return "Miso leads you to a little door that wasn't there before."
	return "Nothing unusual catches your eye. You can come back to this when you know more."

func connect_clues(investigation_id: String, selected_clues: Array[String]) -> Dictionary:
	_ensure_loaded()
	if not investigation_definitions.has(investigation_id):
		return {"status": "unknown_case", "message": "That investigation is not in the journal yet."}
	var investigation: Dictionary = investigation_definitions[investigation_id]
	var owned: Array[String] = []
	for clue_id in selected_clues:
		if clues.has(clue_id) and not owned.has(clue_id):
			owned.append(clue_id)
	var nearest: Dictionary = {}
	var fewest_missing := 999
	var matched: Dictionary = {}
	var matched_specificity := -1
	for hypothesis in investigation.get("hypotheses", []):
		if not investigation_hypothesis_available(hypothesis):
			continue
		var required: Array = hypothesis.get("required_clues", [])
		var missing := 0
		for clue_id in required:
			if not owned.has(String(clue_id)):
				missing += 1
		if missing == 0 and bool(hypothesis.get("conclusive", true)) and required.size() > matched_specificity:
			matched = hypothesis
			matched_specificity = required.size()
		if missing > 0 and missing < fewest_missing:
			nearest = hypothesis
			fewest_missing = missing
	var state: Dictionary = investigation_state.get(investigation_id, {"wrong_deductions": 0, "connections": []})
	state["connections"] = owned.duplicate()
	if not matched.is_empty():
		var result_flag := String(matched.get("result_flag", ""))
		var granted_flags: Array[String] = []
		if not result_flag.is_empty():
			flags[result_flag] = true
			granted_flags.append(result_flag)
		for additional_flag_value in matched.get("grants_flags", []):
			var additional_flag := String(additional_flag_value)
			if additional_flag.is_empty():
				continue
			flags[additional_flag] = true
			if not granted_flags.has(additional_flag):
				granted_flags.append(additional_flag)
		state["conclusion"] = String(matched.get("id", ""))
		state["completed"] = true
		investigation_state[investigation_id] = state
		journal_changed.emit()
		return {"status": "deduced", "hypothesis_id": matched.get("id", ""), "message": matched.get("response", "The clues fit together."), "flag": result_flag, "granted_flags": granted_flags}
	state["wrong_deductions"] = int(state.get("wrong_deductions", 0)) + 1
	investigation_state[investigation_id] = state
	var hint := String(nearest.get("response", "The clues do not quite fit yet. Keep looking; nothing has been lost."))
	if nearest.is_empty():
		hint = "That is one possibility. The journal keeps it as a question while you gather more clues."
	journal_changed.emit()
	return {"status": "hint", "hypothesis_id": nearest.get("id", ""), "message": hint, "missing_clues": _missing_for(nearest, owned)}

func investigation_hypothesis_available(hypothesis: Dictionary) -> bool:
	## Hide theories whose required clues are still chapter-locked or flag-locked.
	## Already-discovered clues stay available even if their source flag later changes.
	for clue_id_value in hypothesis.get("required_clues", []):
		var clue_id := String(clue_id_value)
		if clues.has(clue_id):
			continue
		var clue: Dictionary = clue_definitions.get(clue_id, {})
		if clue.is_empty() or int(clue.get("chapter", 1)) > chapter:
			return false
		if not _requirements_met(clue.get("requires_flags", [])):
			return false
	return true

func conclude_investigation(investigation_id: String, hypothesis_id: String) -> Dictionary:
	_ensure_loaded()
	if not investigation_definitions.has(investigation_id):
		return {"status": "unknown_case"}
	var definition: Dictionary = investigation_definitions[investigation_id]
	for hypothesis in definition.get("hypotheses", []):
		if String(hypothesis.get("id", "")) == hypothesis_id:
			var required: Array[String] = []
			for clue_id in hypothesis.get("required_clues", []):
				required.append(String(clue_id))
			return connect_clues(investigation_id, required)
	return {"status": "hint", "message": "That explanation is not on the journal page yet."}

func pin_clue(clue_id: String, pinned: bool = true) -> bool:
	if not clues.has(clue_id):
		return false
	if pinned and not pinned_clues.has(clue_id):
		pinned_clues.append(clue_id)
	elif not pinned:
		pinned_clues.erase(clue_id)
	journal_changed.emit()
	return true

func record_memory(character_id: String, memory_id: String, memory_text: String, memory_trait: String = "kindness") -> void:
	if character_id.is_empty() or memory_id.is_empty():
		return
	if not relationships.has(character_id):
		relationships[character_id] = {"stage": 0, "memories": [], "traits": {}}
	var relationship: Dictionary = relationships[character_id]
	var memories: Array = relationship.get("memories", [])
	for memory in memories:
		var existing_memory_id := String(memory.get("id", "")) if memory is Dictionary else String(memory)
		if existing_memory_id == memory_id:
			return
	memories.append({"id": memory_id, "text": memory_text, "trait": memory_trait})
	relationship["memories"] = memories
	var traits: Dictionary = relationship.get("traits", {})
	traits[memory_trait] = int(traits.get(memory_trait, 0)) + 1
	relationship["traits"] = traits
	relationships[character_id] = relationship

## The relationship manager owns progression stage; this keeps the narrative's
## richer journal-memory projection in sync without advancing bonds per line.
func set_relationship_stage(character_id: String, stage: int) -> void:
	if character_id.is_empty():
		return
	if not relationships.has(character_id):
		relationships[character_id] = {"stage": 0, "memories": [], "traits": {}}
	var relationship: Dictionary = relationships[character_id]
	relationship["stage"] = clampi(stage, 0, STAGE_NAMES.size() - 1)
	relationships[character_id] = relationship

func relationship_stage(character_id: String) -> String:
	var stage := clampi(int(relationships.get(character_id, {}).get("stage", 0)), 0, STAGE_NAMES.size() - 1)
	return STAGE_NAMES[stage]

func get_chapter_title() -> String:
	_ensure_loaded()
	for definition in chapter_definitions:
		if int(definition.get("id", 0)) == chapter:
			return String(definition.get("title", "Chapter %d" % chapter))
	return "Chapter %d" % chapter

func is_location_unlocked(location_id: String) -> bool:
	_ensure_loaded()
	if not location_definitions.has(location_id):
		return false
	var location: Dictionary = location_definitions[location_id]
	if String(location.get("unlocks", "")) == "start":
		return true
	var required_flag := String(location.get("unlocks_flag", ""))
	if not required_flag.is_empty():
		return bool(flags.get(required_flag, false))
	return int(location.get("chapter", 1)) <= chapter

func get_available_locations() -> Array[Dictionary]:
	_ensure_loaded()
	var unlocked: Array[Dictionary] = []
	for location_id in location_definitions:
		if is_location_unlocked(String(location_id)):
			unlocked.append(location_definitions[location_id])
	return unlocked

func available_endings() -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for ending_id in ending_definitions:
		var ending: Dictionary = ending_definitions[ending_id]
		if flags.get(String(ending.get("requires_flag", "final_covenant_made")), false):
			result.append(ending)
	return result

func choose_ending(ending_id: String) -> Dictionary:
	_ensure_loaded()
	if not selected_ending.is_empty():
		return {"ok": false, "reason": "ending_already_chosen"}
	if not ending_definitions.has(ending_id):
		return {"ok": false, "reason": "unknown_ending"}
	var ending: Dictionary = ending_definitions[ending_id]
	if not flags.get(String(ending.get("requires_flag", "final_covenant_made")), false):
		return {"ok": false, "reason": "story_not_ready"}
	selected_ending = ending_id
	world_state = String(ending.get("world_state", "ordinary_midnight"))
	flags["main_story_complete"] = true
	flags["ending_%s" % ending_id] = true
	flags["doorway_permanently_closed"] = ending_id == "gentle_goodbye"
	journal_changed.emit()
	return {"ok": true, "ending": ending.duplicate(true), "world_state": world_state}

## Stores only memories supported by the player's recorded story flags. The
## entries are snapshots in the save, so later content edits cannot erase them.
func record_ending_memories(ending_id: String) -> Array[Dictionary]:
	_ensure_loaded()
	if ending_id != "gentle_goodbye" or selected_ending != ending_id:
		return []
	var recorded: Array[Dictionary] = []
	for definition in ending_memory_definitions:
		var memory_id := String(definition.get("id", ""))
		if memory_id.is_empty() or ending_memories.has(memory_id):
			continue
		if not _requirements_met(definition.get("requires_flags", [])):
			continue
		var memory := {
			"id": memory_id,
			"activity_id": String(definition.get("activity_id", "")),
			"title": String(definition.get("title", _display_id(memory_id))),
			"text": String(definition.get("text", ""))
		}
		ending_memories[memory_id] = memory
		recorded.append(memory.duplicate(true))
	if not recorded.is_empty():
		journal_changed.emit()
	return recorded

func ending_memory_route(activity_id: String) -> String:
	_ensure_loaded()
	if selected_ending != "gentle_goodbye":
		return activity_id
	for definition in ending_memory_definitions:
		if String(definition.get("activity_id", "")) != activity_id:
			continue
		var memory_id := String(definition.get("id", ""))
		if ending_memories.has(memory_id):
			return "journal_memory:%s" % memory_id
	return activity_id

func ending_memories_for_journal() -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	if selected_ending != "gentle_goodbye":
		return result
	for definition in ending_memory_definitions:
		var memory_id := String(definition.get("id", ""))
		if ending_memories.has(memory_id):
			result.append(ending_memories[memory_id].duplicate(true))
	return result

func read_ending_memory(memory_id: String) -> Dictionary:
	_ensure_loaded()
	if selected_ending != "gentle_goodbye" or not ending_memories.has(memory_id):
		return {}
	return ending_memories[memory_id].duplicate(true)

func ending_epilogue() -> Dictionary:
	_ensure_loaded()
	if selected_ending.is_empty() or not ending_definitions.has(selected_ending):
		return {}
	return ending_definitions[selected_ending].duplicate(true)

func journal_text() -> String:
	_ensure_loaded()
	var chapter_title := _journal_text("story.chapter.%d.title" % chapter, get_chapter_title())
	var lines: Array[String] = [
		_journal_text("journal.title", "MIDNIGHT JOURNAL"),
		_journal_text("journal.chapter", "Chapter {chapter} · {title}").format({"chapter":str(chapter), "title":chapter_title}),
		"",
		_journal_text("journal.section.pinned_clues", "Pinned clues")
	]
	if pinned_clues.is_empty():
		lines.append(_journal_text("journal.empty.pinned", "Nothing pinned yet."))
	else:
		for clue_id in pinned_clues:
			lines.append("★ " + _clue_text(clue_id))
	lines.append("\n" + _journal_text("journal.section.clues", "Clues"))
	if clues.is_empty():
		lines.append(_journal_text("journal.empty.clues", "The night is quiet so far."))
	else:
		for clue_id in clues:
			if not pinned_clues.has(clue_id):
				lines.append("✦ " + _clue_text(clue_id))
	lines.append("\n" + _journal_text("journal.section.open_investigations", "Open investigations"))
	var open_count := 0
	for investigation_id in investigation_definitions:
		var case: Dictionary = investigation_definitions[investigation_id]
		if int(case.get("chapter", 1)) > chapter:
			continue
		var state: Dictionary = investigation_state.get(investigation_id, {})
		if state.get("completed", false):
			continue
		open_count += 1
		lines.append("· %s" % _journal_text("investigation.%s.title" % investigation_id, String(case.get("title", investigation_id))))
	if open_count == 0:
		lines.append(_journal_text("journal.empty.investigations", "No urgent questions. There is time to listen."))
	lines.append("\n" + _journal_text("journal.section.people", "People"))
	for character_id in relationships:
		var state: Dictionary = relationships[character_id]
		var memories: Array = state.get("memories", [])
		if not memories.is_empty():
			var stage_name := relationship_stage(String(character_id))
			stage_name = _journal_text("journal.relationship_stage.%s" % stage_name.to_snake_case(), stage_name)
			lines.append("· %s — %s" % [String(character_id).capitalize(), stage_name])
	if not selected_ending.is_empty():
		var ending_title := String(ending_definitions.get(selected_ending, {}).get("title", selected_ending))
		ending_title = _journal_text("journal.ending.%s.title" % selected_ending, ending_title)
		lines.append(_journal_text("journal.chosen_path", "\nChosen path: {title}").format({"title":ending_title}))
	var saved_ending_memories := ending_memories_for_journal()
	if not saved_ending_memories.is_empty():
		lines.append(_journal_text("journal.section.ending_memories", "\nGentle Goodbye · remembered places"))
		for index in range(saved_ending_memories.size()):
			var memory: Dictionary = saved_ending_memories[index]
			var memory_id := String(memory.get("id", ""))
			var memory_title := _journal_text("journal.ending_memory.%s.title" % memory_id, String(memory.get("title", "Memory")))
			var memory_text := _journal_text("journal.ending_memory.%s.text" % memory_id, String(memory.get("text", "")))
			lines.append("%d · %s" % [index + 1, memory_title])
			lines.append("  %s" % memory_text)
		lines.append(_journal_text("journal.ending_memories.read_hint", "Choose a number to read a memory again."))
	if not queued_events.is_empty():
		var next_id := String(queued_events[0].get("id", ""))
		var next_event: Dictionary = event_definitions.get(next_id, {})
		var event_title := _journal_text("story.event.%s.title" % next_id, String(next_event.get("title", _display_id(next_id))))
		lines.append("\n" + _journal_text("journal.carried_forward", "Carried forward: {title}").format({"title":event_title}))
	return "\n".join(lines)

func _journal_text(key: String, fallback: String) -> String:
	if ui_text_lookup.is_valid():
		var localized: Variant = ui_text_lookup.call(key, fallback)
		if localized is String and not String(localized).is_empty():
			return String(localized)
	return fallback

func _requirements_met(requirements: Array) -> bool:
	for requirement in requirements:
		if not bool(flags.get(String(requirement), false)):
			return false
	return true

func _advance_chapter() -> void:
	_ensure_loaded()
	var derived := 1
	for definition in chapter_definitions:
		var id := int(definition.get("id", 0))
		if id != derived:
			continue
		if id >= chapter_definitions.size():
			break
		if not _requirements_met(definition.get("completion_flags", [])):
			break
		derived += 1
	chapter = clampi(maxi(chapter, derived), 1, maxi(1, chapter_definitions.size()))

func _missing_for(hypothesis: Dictionary, owned: Array[String]) -> Array[String]:
	var missing: Array[String] = []
	for clue_id in hypothesis.get("required_clues", []):
		if not owned.has(String(clue_id)):
			missing.append(String(clue_id))
	return missing

func _add_clue(id: String) -> void:
	if id.is_empty() or clues.has(id):
		return
	clues.append(id)

func _clue_text(id: String) -> String:
	var definition: Dictionary = clue_definitions.get(id, {})
	return _journal_text("clue.%s.text" % id, String(definition.get("text", _display_id(id))))

func _display_id(value: String) -> String:
	return value.replace("_", " ").capitalize()

func to_save() -> Dictionary:
	return {
		"flags": flags.duplicate(true), "clues": clues.duplicate(), "pinned_clues": pinned_clues.duplicate(),
		"queued_events": queued_events.duplicate(true), "completed_events": completed_events.duplicate(),
		"relationships": relationships.duplicate(true), "investigation_state": investigation_state.duplicate(true),
		"ending_memories": ending_memories.duplicate(true),
		"chapter": chapter, "selected_ending": selected_ending, "world_state": world_state
	}

func from_save(data: Dictionary) -> void:
	_ensure_loaded()
	flags = data.get("flags", {}).duplicate(true)
	clues.assign(data.get("clues", []))
	pinned_clues.assign(data.get("pinned_clues", []))
	queued_events.assign(data.get("queued_events", []))
	completed_events.assign(data.get("completed_events", []))
	relationships = data.get("relationships", {}).duplicate(true)
	investigation_state = data.get("investigation_state", {}).duplicate(true)
	ending_memories = data.get("ending_memories", {}).duplicate(true)
	chapter = clampi(int(data.get("chapter", 1)), 1, maxi(1, chapter_definitions.size()))
	selected_ending = String(data.get("selected_ending", ""))
	world_state = String(data.get("world_state", "ordinary_midnight"))
	# Older saves predate ending_memories. Reconstruct only memories whose
	# prerequisite flags prove the player reached the corresponding experience.
	if ending_memories.is_empty() and selected_ending == "gentle_goodbye":
		record_ending_memories(selected_ending)
	# Migrate the first-five-night save, whose relationship memory entries were strings.
	for character_id in relationships:
		var state: Dictionary = relationships[character_id]
		var memories: Array = state.get("memories", [])
		var converted: Array[Dictionary] = []
		for memory in memories:
			if memory is Dictionary:
				converted.append(memory)
			else:
				converted.append({"id": String(memory).replace(" ", "_").to_lower(), "text": String(memory), "trait": "kindness"})
		state["memories"] = converted
		relationships[character_id] = state
	_advance_chapter()
	journal_changed.emit()
