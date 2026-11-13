class_name MoonmartQuests
extends RefCounted

## Quest access is flag and dependency driven. Essential customer visits persist
## in the queue until the player resolves them; shift count is only context.
signal quest_changed(quest_id: String, state: String)
signal encounter_queued(quest_id: String, visitor_id: String)
signal objective_completed(quest_id: String, objective_id: String)

var definitions: Dictionary = {}
var states: Dictionary = {}
var flags: Dictionary = {}
var _encounter_queue: Array[Dictionary] = []
var _missed_visits: Dictionary = {}

func setup(rows: Array, initial_flags: Dictionary = {}) -> void:
	definitions.clear()
	states.clear()
	flags = initial_flags.duplicate(true)
	for row in rows:
		if not row is Dictionary or not row.has("id"):
			continue
		var quest_id := String(row.id)
		definitions[quest_id] = row.duplicate(true)
		states[quest_id] = "locked" if not is_available(quest_id) else "available"
	_refresh_locked_quests()

func is_available(quest_id: String) -> bool:
	if not definitions.has(quest_id):
		return false
	var quest: Dictionary = definitions[quest_id]
	for required_flag in quest.get("requires_flags", []):
		if not bool(flags.get(String(required_flag), false)):
			return false
	for required_quest in quest.get("requires_quests", []):
		if states.get(String(required_quest), "") != "complete":
			return false
	return true

func begin_shift(shift_number: int, context: Dictionary = {}) -> Array[Dictionary]:
	# This queue is authoritative for essential story visitors. A missed night
	# carries its encounter forward; schedule only the next eligible event after
	# the previous one has been resolved.
	for encounter in _encounter_queue:
		encounter["eligible_shift"] = shift_number
	var result := _encounter_queue.duplicate(true)
	if not _encounter_queue.is_empty():
		return result
	for quest_id in definitions:
		var quest: Dictionary = definitions[quest_id]
		if not bool(quest.get("essential", false)) or states.get(quest_id) == "complete":
			continue
		if _encounter_queue.any(func(row): return row.get("quest_id") == quest_id):
			continue
		if not is_available(quest_id) or not _trigger_matches(quest.get("trigger", {}), shift_number, context):
			continue
		var visitor_id := String(quest.get("visitor_id", ""))
		var encounter := {"id": quest_id, "quest_id": quest_id, "visitor": visitor_id, "essential": true, "eligible_shift": shift_number}
		_encounter_queue.append(encounter)
		result.append(encounter.duplicate(true))
		encounter_queued.emit(quest_id, visitor_id)
		break
	return result

## Imports the pre-quest-manager story queue from older saves. When a legacy
## narrative queue exists, it takes precedence over the older mirrored quest
## queue so only the visit that was actually scheduled remains authoritative.
func restore_legacy_encounters(rows: Array, shift_number: int) -> bool:
	var legacy_ids: Array[String] = []
	for row_value in rows:
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		if not bool(row.get("essential", true)):
			continue
		var quest_id := String(row.get("quest_id", row.get("id", "")))
		if quest_id.is_empty() or legacy_ids.has(quest_id):
			continue
		legacy_ids.append(quest_id)
	if rows.is_empty():
		return false
	_encounter_queue.clear()
	for quest_id in legacy_ids:
		if not definitions.has(quest_id) or states.get(quest_id) == "complete" or not is_available(quest_id):
			continue
		var definition: Dictionary = definitions[quest_id]
		if not bool(definition.get("essential", false)):
			continue
		var visitor_id := String(definition.get("visitor_id", definition.get("visitor", "")))
		_encounter_queue.append({"id": quest_id, "quest_id": quest_id, "visitor": visitor_id, "essential": true, "eligible_shift": shift_number})
	if not _encounter_queue.is_empty():
		_refresh_locked_quests()
	return not _encounter_queue.is_empty()

## Removes stale or invalid queue rows after loading a save. Completed story
## events can remain in queues written by older versions; leaving one at the
## head would prevent the next eligible visit from ever being scheduled.
func reconcile_encounter_queue(completed_event_ids: Array, shift_number: int) -> void:
	var reconciled: Array[Dictionary] = []
	var seen: Dictionary = {}
	for row_value in _encounter_queue:
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		var quest_id := String(row.get("quest_id", row.get("id", "")))
		if quest_id.is_empty() or seen.has(quest_id) or completed_event_ids.has(quest_id):
			continue
		if not definitions.has(quest_id) or states.get(quest_id) == "complete" or not is_available(quest_id):
			continue
		var definition: Dictionary = definitions[quest_id]
		if not bool(definition.get("essential", false)):
			continue
		var visitor_id := String(definition.get("visitor_id", definition.get("visitor", row.get("visitor", ""))))
		reconciled.append({"id": quest_id, "quest_id": quest_id, "visitor": visitor_id, "essential": true, "eligible_shift": shift_number})
		seen[quest_id] = true
	_encounter_queue = reconciled

func _trigger_matches(trigger: Dictionary, shift_number: int, context: Dictionary) -> bool:
	if trigger.has("min_shift") and shift_number < int(trigger.min_shift):
		return false
	if trigger.has("max_shift") and shift_number > int(trigger.max_shift):
		return false
	for key in trigger:
		if key == "min_shift" or key == "max_shift":
			continue
		if context.get(String(key)) != trigger[key]:
			return false
	return true

func accept(quest_id: String) -> bool:
	if not definitions.has(quest_id) or not is_available(quest_id):
		return false
	var current := String(states.get(quest_id, "available"))
	if current != "available" and current != "offered":
		return false
	states[quest_id] = "active"
	quest_changed.emit(quest_id, "active")
	return true

func mark_offered(quest_id: String) -> bool:
	if not is_available(quest_id) or states.get(quest_id) != "available":
		return false
	states[quest_id] = "offered"
	quest_changed.emit(quest_id, "offered")
	return true

func complete_objective(quest_id: String, objective_id: String) -> bool:
	if states.get(quest_id) != "active" or not definitions.has(quest_id):
		return false
	var objective_ids: Array[String] = []
	for objective in definitions[quest_id].get("objectives", []):
		objective_ids.append(String(objective.get("id", "")) if objective is Dictionary else String(objective))
	if not objective_ids.has(objective_id):
		return false
	var done: Array = states.get("%s:objectives" % quest_id, [])
	if done.has(objective_id):
		return false
	done.append(objective_id)
	states["%s:objectives" % quest_id] = done
	objective_completed.emit(quest_id, objective_id)
	if _all_objectives_done(quest_id):
		states[quest_id] = "ready_to_complete"
		quest_changed.emit(quest_id, "ready_to_complete")
	return true

func _all_objectives_done(quest_id: String) -> bool:
	var done: Array = states.get("%s:objectives" % quest_id, [])
	var objectives: Array = definitions[quest_id].get("objectives", [])
	for objective in objectives:
		var objective_id := String(objective.get("id", "")) if objective is Dictionary else String(objective)
		if not done.has(objective_id):
			return false
	return true

func complete_quest(quest_id: String) -> Dictionary:
	if not definitions.has(quest_id) or states.get(quest_id) != "ready_to_complete":
		return {"ok": false, "reason": "objectives_incomplete"}
	var quest: Dictionary = definitions[quest_id]
	states[quest_id] = "complete"
	for flag_id in quest.get("sets_flags", []):
		flags[String(flag_id)] = true
	_remove_encounter(quest_id)
	quest_changed.emit(quest_id, "complete")
	_refresh_locked_quests()
	return {"ok": true, "rewards": quest.get("rewards", {}).duplicate(true)}

func resolve_essential_encounter(quest_id: String) -> Dictionary:
	if not definitions.has(quest_id) or not bool(definitions[quest_id].get("essential", false)):
		return {"ok": false, "reason": "not_essential"}
	if not is_available(quest_id):
		return {"ok": false, "reason": "prerequisites_missing"}
	if not _encounter_queue.any(func(row): return String(row.get("quest_id", row.get("id", ""))) == quest_id):
		return {"ok": false, "reason": "encounter_not_queued"}
	var quest: Dictionary = definitions[quest_id]
	# One-step narrative encounters are resolved by their explicit story event.
	for flag_id in quest.get("sets_flags", []):
		flags[String(flag_id)] = true
	states[quest_id] = "complete"
	_remove_encounter(quest_id)
	quest_changed.emit(quest_id, "complete")
	_refresh_locked_quests()
	return {"ok": true, "rewards": quest.get("rewards", {}).duplicate(true)}

func note_visit_missed(quest_id: String) -> void:
	if not definitions.has(quest_id) or not bool(definitions[quest_id].get("essential", false)):
		return
	_missed_visits[quest_id] = int(_missed_visits.get(quest_id, 0)) + 1

func queued_encounters() -> Array[Dictionary]:
	return _encounter_queue.duplicate(true)

func _remove_encounter(quest_id: String) -> void:
	for index in range(_encounter_queue.size() - 1, -1, -1):
		if _encounter_queue[index].get("quest_id") == quest_id:
			_encounter_queue.remove_at(index)

func _refresh_locked_quests() -> void:
	var unlocked_any := true
	while unlocked_any:
		unlocked_any = false
		for quest_id in definitions:
			if states.get(quest_id) == "locked" and is_available(quest_id):
				states[quest_id] = "available"
				unlocked_any = true
				quest_changed.emit(quest_id, "available")

func export_state() -> Dictionary:
	return {"states": states.duplicate(true), "flags": flags.duplicate(true), "encounter_queue": _encounter_queue.duplicate(true), "missed_visits": _missed_visits.duplicate(true)}

func import_state(data: Dictionary) -> void:
	states = data.get("states", states).duplicate(true)
	flags = data.get("flags", flags).duplicate(true)
	_encounter_queue.assign(data.get("encounter_queue", []))
	_missed_visits = data.get("missed_visits", {}).duplicate(true)
	_refresh_locked_quests()
