class_name MoonmartEventDirector
extends RefCounted

## Optional encounters are weighted by the living shop context. Essential story
## encounters live in a separate persistent queue and never depend on a roll.
signal event_scheduled(event_id: String, essential: bool)
signal event_resolved(event_id: String)

var definitions: Dictionary = {}
var seed_value: int = 19870417
var _rng := RandomNumberGenerator.new()
var _essential_queue: Array[String] = []
var _last_seen_shift: Dictionary = {}
var _use_count: Dictionary = {}
var _resolved_essential: Array[String] = []

func setup(rows: Array, seed: int = 19870417) -> void:
	definitions.clear()
	seed_value = seed
	_rng.seed = seed_value
	for row in rows:
		if row is Dictionary and row.has("id"):
			definitions[String(row.id)] = row.duplicate(true)

func queue_essential(event_id: String) -> bool:
	if not definitions.has(event_id) or _resolved_essential.has(event_id) or _essential_queue.has(event_id):
		return false
	_essential_queue.append(event_id)
	event_scheduled.emit(event_id, true)
	return true

func begin_shift(shift_number: int, context: Dictionary, optional_limit: int = 2) -> Array[Dictionary]:
	var scheduled: Array[Dictionary] = []
	# These are copied into the shift result but remain queued until explicitly resolved.
	for event_id in _essential_queue:
		scheduled.append({"id": event_id, "essential": true, "visitor": definitions[event_id].get("visitor", "")})
	var candidates: Array[Dictionary] = []
	for event_id in definitions:
		var definition: Dictionary = definitions[event_id]
		if bool(definition.get("essential", false)) or not _eligible(event_id, definition, shift_number, context):
			continue
		var weight := _weight(definition, context)
		if weight > 0.0:
			candidates.append({"id": event_id, "weight": weight})
	var festival_id := String(context.get("festival", {}).get("id", ""))
	if not festival_id.is_empty():
		for index in range(candidates.size()):
			var candidate_id := String(candidates[index].get("id", ""))
			if String(definitions[candidate_id].get("festival_id", "")) != festival_id:
				continue
			candidates.remove_at(index)
			_last_seen_shift[candidate_id] = shift_number
			_use_count[candidate_id] = int(_use_count.get(candidate_id, 0)) + 1
			scheduled.append({"id": candidate_id, "essential": false, "visitor": definitions[candidate_id].get("visitor", "")})
			event_scheduled.emit(candidate_id, false)
			break
	var already_scheduled_optional := scheduled.size() - _essential_queue.size()
	var count := mini(maxi(0, optional_limit - already_scheduled_optional), candidates.size())
	for _index in range(count):
		var selected := _weighted_pick(candidates)
		if selected.is_empty():
			break
		var event_id := String(selected.id)
		candidates = candidates.filter(func(row): return String(row.get("id")) != event_id)
		_last_seen_shift[event_id] = shift_number
		_use_count[event_id] = int(_use_count.get(event_id, 0)) + 1
		scheduled.append({"id": event_id, "essential": false, "visitor": definitions[event_id].get("visitor", "")})
		event_scheduled.emit(event_id, false)
	return scheduled

func _eligible(event_id: String, definition: Dictionary, shift_number: int, context: Dictionary) -> bool:
	if shift_number < int(definition.get("min_shift", 0)):
		return false
	var max_shift := int(definition.get("max_shift", 0))
	if max_shift > 0 and shift_number > max_shift:
		return false
	var maximum := int(definition.get("max_uses", 0))
	if maximum > 0 and int(_use_count.get(event_id, 0)) >= maximum:
		return false
	var ending_id := String(context.get("ending_id", ""))
	var required_endings: Array = definition.get("requires_endings", [])
	if not required_endings.is_empty() and not required_endings.has(ending_id):
		return false
	var required_world_states: Array = definition.get("requires_world_states", [])
	if not required_world_states.is_empty() and not required_world_states.has(String(context.get("world_state_id", "ordinary_midnight"))):
		return false
	for condition in ["community_mixed", "door_open"]:
		var requirement_key := "requires_%s" % condition
		if definition.has(requirement_key) and bool(context.get(condition, false)) != bool(definition.get(requirement_key, false)):
			return false
	for forbidden_ending in definition.get("forbidden_endings", []):
		if String(forbidden_ending) == ending_id:
			return false
	var cooldown := int(definition.get("cooldown_shifts", 0))
	if shift_number - int(_last_seen_shift.get(event_id, -100000)) <= cooldown:
		return false
	for flag_id in definition.get("requires_flags", []):
		if not context.get("flags", {}).get(String(flag_id), false):
			return false
	for flag_id in definition.get("forbidden_flags", []):
		if context.get("flags", {}).get(String(flag_id), false):
			return false
	var allowed_days: Array = definition.get("days", [])
	if not allowed_days.is_empty() and not allowed_days.has(context.get("day", "")):
		return false
	var allowed_weather: Array = definition.get("weather", [])
	if not allowed_weather.is_empty() and not allowed_weather.has(context.get("weather", "clear")):
		return false
	var allowed_seasons: Array = definition.get("seasons", [])
	if not allowed_seasons.is_empty() and not allowed_seasons.has(context.get("season", "spring")):
		return false
	var allowed_season_days: Array = definition.get("season_days", [])
	if not allowed_season_days.is_empty() and not allowed_season_days.has(int(context.get("season_day", 1))):
		return false
	var festival_id := String(definition.get("festival_id", ""))
	if not festival_id.is_empty() and String(context.get("festival", {}).get("id", "")) != festival_id:
		return false
	for category in definition.get("stock_categories", []):
		if int(context.get("stock_categories", {}).get(String(category), 0)) <= 0:
			return false
	var min_bond := int(definition.get("minimum_bond", -1))
	if min_bond >= 0 and int(context.get("relationships", {}).get(String(definition.get("visitor", "")), 0)) < min_bond:
		return false
	return true

func _weight(definition: Dictionary, context: Dictionary) -> float:
	var result := maxf(0.0, float(definition.get("weight", 1.0)))
	for rule in definition.get("weight_rules", []):
		if not rule is Dictionary:
			continue
		var key := String(rule.get("context", ""))
		var expected: Variant = rule.get("equals")
		if context.get(key) == expected:
			result *= maxf(0.0, float(rule.get("multiplier", 1.0)))
	return result

func _weighted_pick(candidates: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for candidate in candidates:
		total += float(candidate.get("weight", 0.0))
	if total <= 0.0:
		return {}
	var roll := _rng.randf_range(0.0, total)
	for candidate in candidates:
		roll -= float(candidate.get("weight", 0.0))
		if roll <= 0.0:
			return candidate
	return candidates.back()

func resolve_essential(event_id: String) -> bool:
	if not _essential_queue.has(event_id):
		return false
	_essential_queue.erase(event_id)
	_resolved_essential.append(event_id)
	event_resolved.emit(event_id)
	return true

func miss_essential(event_id: String) -> bool:
	# Intentionally leave it queued for the next eligible shift.
	return _essential_queue.has(event_id)

func optional_context_hint(context: Dictionary) -> String:
	var eligible: Array[String] = []
	for event_id in definitions:
		var definition: Dictionary = definitions[event_id]
		if not bool(definition.get("essential", false)) and _eligible(event_id, definition, int(context.get("shift", 0)), context):
			eligible.append(String(definition.get("hint", "")))
	eligible = eligible.filter(func(value): return not value.is_empty())
	return eligible[0] if not eligible.is_empty() else "The shop settles into its gentle nighttime rhythm."

func export_state() -> Dictionary:
	return {"seed": seed_value, "essential_queue": _essential_queue.duplicate(), "resolved_essential": _resolved_essential.duplicate(), "last_seen_shift": _last_seen_shift.duplicate(true), "use_count": _use_count.duplicate(true), "rng_state": _rng.state}

func import_state(data: Dictionary) -> void:
	seed_value = int(data.get("seed", seed_value))
	_rng.seed = seed_value
	_rng.state = int(data.get("rng_state", _rng.state))
	_essential_queue.assign(data.get("essential_queue", []))
	_resolved_essential.assign(data.get("resolved_essential", []))
	_last_seen_shift = data.get("last_seen_shift", {}).duplicate(true)
	_use_count = data.get("use_count", {}).duplicate(true)
