class_name MoonmartEnvironmentalPuzzles
extends RefCounted

## Optional environmental puzzles. Puzzle outputs are proposals: the caller
## applies returned flags/clues to the narrative and mystery systems. This
## keeps puzzles from owning or gating essential story progression.
##
## Integration:
##   setup(config.get("puzzles", []))
##   visible_puzzles(story.flags) -> Array[Dictionary]
##   submit_answer(id, answer, story.flags) -> result Dictionary
##   export_state() / import_state(data) for save persistence
## On a solved result, apply `grants_flags` and `reveals_clues` if desired.
signal puzzle_updated(puzzle_id: String, solved: bool)

var definitions: Dictionary = {}
var states: Dictionary = {}

func setup(rows: Array) -> void:
	definitions.clear()
	for row in rows:
		if not row is Dictionary:
			continue
		var puzzle_id := String(row.get("id", ""))
		if puzzle_id.is_empty():
			continue
		definitions[puzzle_id] = row.duplicate(true)
		states[puzzle_id] = {"attempts": 0, "solved": false}

func visible_puzzles(flags: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for puzzle_id in definitions:
		var row: Dictionary = definitions[puzzle_id]
		if _requirements_met(row.get("requires_flags", []), flags):
			result.append(_with_state(String(puzzle_id), row))
	return result

func puzzle(puzzle_id: String, flags: Dictionary) -> Dictionary:
	if not definitions.has(puzzle_id):
		return {}
	var row: Dictionary = definitions[puzzle_id]
	if not _requirements_met(row.get("requires_flags", []), flags):
		return {}
	return _with_state(puzzle_id, row)

func submit_answer(puzzle_id: String, answer: String, flags: Dictionary) -> Dictionary:
	if not definitions.has(puzzle_id):
		return {"ok": false, "reason": "unknown_puzzle"}
	var definition: Dictionary = definitions[puzzle_id]
	if not _requirements_met(definition.get("requires_flags", []), flags):
		return {"ok": false, "reason": "locked", "message": "There is not enough context to read this puzzle yet."}
	var state: Dictionary = states.get(puzzle_id, {"attempts": 0, "solved": false})
	if bool(state.get("solved", false)):
		return {"ok": true, "already_solved": true, "reason": "already_solved", "message": String(definition.get("solved_message", "The pieces fit together.")), "grants_flags": definition.get("grants_flags", []).duplicate(), "reveals_clues": definition.get("reveals_clues", []).duplicate(), "reward_text": String(definition.get("reward_text", ""))}
	var normalized_answer := _normalize(answer)
	var matches := false
	for accepted in definition.get("accepted_answers", []):
		if normalized_answer == _normalize(String(accepted)):
			matches = true
			break
	state["attempts"] = int(state.get("attempts", 0)) + 1
	if matches:
		state["solved"] = true
		states[puzzle_id] = state
		puzzle_updated.emit(puzzle_id, true)
		return {"ok": true, "reason": "solved", "puzzle_id": puzzle_id, "message": String(definition.get("solved_message", "The details settle into place.")), "grants_flags": definition.get("grants_flags", []).duplicate(), "reveals_clues": definition.get("reveals_clues", []).duplicate(), "reward_text": String(definition.get("reward_text", "")), "attempts": int(state.attempts)}
	states[puzzle_id] = state
	puzzle_updated.emit(puzzle_id, false)
	var hints: Array = definition.get("hints", [])
	var hint_index := clampi(int(state.attempts) - 1, 0, maxi(0, hints.size() - 1))
	var hint := String(hints[hint_index]) if not hints.is_empty() else "No harm done. Look around and try another idea whenever you like."
	return {"ok": false, "reason": "try_again", "puzzle_id": puzzle_id, "message": hint, "attempts": int(state.attempts), "solved": false}

func is_solved(puzzle_id: String) -> bool:
	return bool(states.get(puzzle_id, {}).get("solved", false))

func export_state() -> Dictionary:
	return {"states": states.duplicate(true)}

func import_state(data: Dictionary) -> void:
	var saved: Dictionary = data.get("states", {})
	for puzzle_id in definitions:
		var state: Dictionary = saved.get(puzzle_id, {})
		states[puzzle_id] = {"attempts": maxi(0, int(state.get("attempts", 0))), "solved": bool(state.get("solved", false))}

func _requirements_met(required_flags: Array, flags: Dictionary) -> bool:
	for flag_id in required_flags:
		if not bool(flags.get(String(flag_id), false)):
			return false
	return true

func _with_state(puzzle_id: String, definition: Dictionary) -> Dictionary:
	var result := definition.duplicate(true)
	var state: Dictionary = states.get(puzzle_id, {"attempts": 0, "solved": false})
	result["attempts"] = int(state.get("attempts", 0))
	result["solved"] = bool(state.get("solved", false))
	return result

func _normalize(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	for punctuation in [".", ",", "!", "?", "'", "\"", ":", ";"]:
		normalized = normalized.replace(punctuation, "")
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	return normalized
