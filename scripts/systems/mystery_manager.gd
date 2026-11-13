class_name MoonmartMysteries
extends RefCounted

## Observation is persistent; a mistaken theory only requests another hint.
signal clue_added(clue_id: String)
signal investigation_updated(investigation_id: String, state: String)
signal deduction_made(investigation_id: String, solution_id: String, correct: bool)

var clue_definitions: Dictionary = {}
var investigations: Dictionary = {}
var discovered_clues: Array[String] = []
var pinned_clues: Array[String] = []
var states: Dictionary = {}
var flags: Dictionary = {}
var ui_text_lookup: Callable = Callable()

func setup(clue_rows: Array, investigation_rows: Array, initial_flags: Dictionary = {}) -> void:
	clue_definitions.clear()
	investigations.clear()
	states.clear()
	flags = initial_flags.duplicate(true)
	for row in clue_rows:
		if row is Dictionary and row.has("id"):
			clue_definitions[String(row.id)] = row.duplicate(true)
	for row in investigation_rows:
		if row is Dictionary and row.has("id"):
			var investigation_id := String(row.id)
			investigations[investigation_id] = row.duplicate(true)
			states[investigation_id] = {"status": "active", "attempts": 0, "solution": ""}

func add_clue(clue_id: String) -> bool:
	if clue_id.is_empty() or discovered_clues.has(clue_id):
		return false
	discovered_clues.append(clue_id)
	clue_added.emit(clue_id)
	return true

func pin_clue(clue_id: String, pinned: bool = true) -> bool:
	if not discovered_clues.has(clue_id):
		return false
	if pinned and not pinned_clues.has(clue_id):
		pinned_clues.append(clue_id)
	elif not pinned:
		pinned_clues.erase(clue_id)
	return true

func available_solutions(investigation_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not investigations.has(investigation_id):
		return result
	var state: Dictionary = states.get(investigation_id, {})
	if state.get("status") == "solved":
		return result
	for solution in investigations[investigation_id].get("solutions", []):
		if _requirements_met(solution):
			result.append(solution)
	return result

func _requirements_met(solution: Dictionary) -> bool:
	for clue_id in solution.get("all_of", []):
		if not discovered_clues.has(String(clue_id)):
			return false
	var any_of: Array = solution.get("any_of", [])
	if not any_of.is_empty() and not any_of.any(func(id): return discovered_clues.has(String(id))):
		return false
	for flag_id in solution.get("requires_flags", []):
		if not bool(flags.get(String(flag_id), false)):
			return false
	return true

func submit_deduction(investigation_id: String, solution_id: String) -> Dictionary:
	if not investigations.has(investigation_id):
		return {"ok": false, "reason": "unknown_investigation"}
	var state: Dictionary = states.get(investigation_id, {"status": "active", "attempts": 0, "solution": ""})
	if state.get("status") == "solved":
		return {"ok": true, "already_solved": true, "solution": state.get("solution", "")}
	var solution: Dictionary = {}
	for candidate in investigations[investigation_id].get("solutions", []):
		if String(candidate.get("id", "")) == solution_id:
			solution = candidate
			break
	if solution.is_empty():
		return {"ok": false, "reason": "unknown_solution"}
	var correct := _requirements_met(solution)
	state["attempts"] = int(state.get("attempts", 0)) + 1
	if correct:
		state["status"] = "solved"
		state["solution"] = solution_id
		for flag_id in solution.get("sets_flags", []):
			flags[String(flag_id)] = true
		for clue_id in solution.get("reveals_clues", []):
			add_clue(String(clue_id))
		investigation_updated.emit(investigation_id, "solved")
	else:
		state["status"] = "active"
		investigation_updated.emit(investigation_id, "active")
	states[investigation_id] = state
	deduction_made.emit(investigation_id, solution_id, correct)
	var hints: Array = investigations[investigation_id].get("hints", [])
	var hint := "Keep looking; another clue may connect these details." if hints.is_empty() else String(hints[mini(int(state["attempts"]) - 1, hints.size() - 1)])
	return {"ok": correct, "reason": "solved" if correct else "more_evidence_needed", "hint": hint, "conclusion": solution.get("conclusion", "") if correct else "", "flags": solution.get("sets_flags", []).duplicate() if correct else []}

func unresolved_investigations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for investigation_id in investigations:
		if states.get(investigation_id, {}).get("status") != "solved":
			result.append({"id": investigation_id, "title": investigations[investigation_id].get("title", investigation_id), "pinned_clues": pinned_clues.duplicate()})
	return result

func journal_lines() -> Array[String]:
	var lines: Array[String] = [_journal_text("journal.section.clues", "Clues")]
	for clue_id in discovered_clues:
		var clue: Dictionary = clue_definitions.get(clue_id, {})
		var clue_title := _journal_text("clue.%s.text" % clue_id, String(clue.get("title", clue_id.replace("_", " "))))
		var pin_label := _journal_text("journal.clue.pinned", "  · pinned") if pinned_clues.has(clue_id) else ""
		lines.append("✦ %s%s" % [clue_title, pin_label])
	for investigation_id in investigations:
		var state: Dictionary = states.get(investigation_id, {})
		var case_title := _journal_text("investigation.%s.title" % investigation_id, String(investigations[investigation_id].get("title", investigation_id)))
		var status_key := "journal.status.solved" if state.get("status") == "solved" else "journal.status.unresolved"
		var status_fallback := "solved" if state.get("status") == "solved" else "unresolved"
		lines.append("%s · %s" % [case_title, _journal_text(status_key, status_fallback)])
	return lines

func _journal_text(key: String, fallback: String) -> String:
	if ui_text_lookup.is_valid():
		var localized: Variant = ui_text_lookup.call(key, fallback)
		if localized is String and not String(localized).is_empty():
			return String(localized)
	return fallback

func export_state() -> Dictionary:
	return {"discovered_clues": discovered_clues.duplicate(), "pinned_clues": pinned_clues.duplicate(), "states": states.duplicate(true), "flags": flags.duplicate(true)}

func import_state(data: Dictionary) -> void:
	discovered_clues.assign(data.get("discovered_clues", []))
	pinned_clues.assign(data.get("pinned_clues", []))
	states = data.get("states", states).duplicate(true)
	flags = data.get("flags", flags).duplicate(true)
