class_name MoonmartMisoAmbient
extends RefCounted

## Optional visual-only behavior scheduling for Miso. All timers are transient
## scene state; no story, inventory, or save data is changed by this manager.
var definitions: Dictionary = {}
var cooldowns: Dictionary = {}
var seed_value := 41327
var _rng := RandomNumberGenerator.new()
var _current: Dictionary = {}
var _waiting_for_arrival := false
var _active_remaining := 0.0
var _next_behavior_in := 8.0
var _interval_min := 10.0
var _interval_max := 18.0

func setup(rows: Array, seed: int = 41327, initial_wait_min: float = 8.0, initial_wait_max: float = 13.0, interval_min: float = 10.0, interval_max: float = 18.0) -> void:
	definitions.clear()
	cooldowns.clear()
	_current.clear()
	_waiting_for_arrival = false
	_active_remaining = 0.0
	seed_value = seed
	_rng.seed = seed_value
	_interval_min = maxf(1.0, interval_min)
	_interval_max = maxf(_interval_min, interval_max)
	_next_behavior_in = _rng.randf_range(maxf(0.0, initial_wait_min), maxf(initial_wait_min, initial_wait_max))
	for row_value in rows:
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		var behavior_id := String(row.get("id", ""))
		if not behavior_id.is_empty() and not String(row.get("anchor", "")).is_empty():
			definitions[behavior_id] = row.duplicate(true)

func eligible_behaviors(has_customer: bool, preferred_sleep_spot: String, available_prop_ids: Array[String] = []) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for behavior_id in definitions:
		if float(cooldowns.get(behavior_id, 0.0)) > 0.0:
			continue
		var row: Dictionary = definitions[behavior_id]
		if bool(row.get("requires_customer", false)) and not has_customer:
			continue
		var required_prop := String(row.get("requires_prop", ""))
		if not required_prop.is_empty() and not available_prop_ids.has(required_prop):
			continue
		var required_spot := String(row.get("requires_sleep_spot", ""))
		if not required_spot.is_empty() and required_spot != preferred_sleep_spot:
			continue
		rows.append(row)
	return rows

func choose_behavior(has_customer: bool, preferred_sleep_spot: String, available_prop_ids: Array[String] = []) -> Dictionary:
	var candidates := eligible_behaviors(has_customer, preferred_sleep_spot, available_prop_ids)
	var total_weight := 0.0
	for row in candidates:
		total_weight += maxf(0.0, float(row.get("weight", 1.0)))
	if total_weight <= 0.0:
		return {}
	var roll := _rng.randf_range(0.0, total_weight)
	for row in candidates:
		roll -= maxf(0.0, float(row.get("weight", 1.0)))
		if roll <= 0.0:
			return row.duplicate(true)
	return candidates.back().duplicate(true)

func tick(delta: float, enabled: bool, has_customer: bool, preferred_sleep_spot: String, at_target: bool, available_prop_ids: Array[String] = []) -> Dictionary:
	if not enabled:
		return {"state":"suspended"}
	for behavior_id in cooldowns.keys():
		cooldowns[behavior_id] = maxf(0.0, float(cooldowns[behavior_id]) - delta)
	if not _current.is_empty():
		if _waiting_for_arrival:
			if at_target:
				_waiting_for_arrival = false
				_active_remaining = maxf(0.5, float(_current.get("duration_seconds", 4.0)))
				return {"state":"arrived", "behavior":_current.duplicate(true)}
			return {"state":"moving", "behavior":_current.duplicate(true)}
		_active_remaining -= delta
		if _active_remaining <= 0.0:
			var finished_id := String(_current.get("id", ""))
			cooldowns[finished_id] = maxf(0.0, float(_current.get("cooldown_seconds", 25.0)))
			_current.clear()
			_waiting_for_arrival = false
			_next_behavior_in = _rng.randf_range(_interval_min, _interval_max)
			return {"state":"finished", "behavior_id":finished_id}
		return {"state":"dwelling", "behavior":_current.duplicate(true)}
	_next_behavior_in = maxf(0.0, _next_behavior_in - delta)
	if _next_behavior_in > 0.0:
		return {"state":"waiting"}
	_current = choose_behavior(has_customer, preferred_sleep_spot, available_prop_ids)
	if _current.is_empty():
		_next_behavior_in = 3.0
		return {"state":"no_eligible_behavior"}
	_waiting_for_arrival = true
	return {"state":"started", "behavior":_current.duplicate(true)}

func cancel_current(apply_cooldown: bool = true) -> void:
	if apply_cooldown and not _current.is_empty():
		var behavior_id := String(_current.get("id", ""))
		cooldowns[behavior_id] = maxf(0.0, float(_current.get("cooldown_seconds", 25.0)))
	_current.clear()
	_waiting_for_arrival = false
	_active_remaining = 0.0
	_next_behavior_in = _rng.randf_range(_interval_min, _interval_max)

func current_behavior() -> Dictionary:
	return _current.duplicate(true)

func waiting_for_arrival() -> bool:
	return _waiting_for_arrival

func active_remaining_seconds() -> float:
	return _active_remaining

func cooldown_seconds(behavior_id: String) -> float:
	return float(cooldowns.get(behavior_id, 0.0))
