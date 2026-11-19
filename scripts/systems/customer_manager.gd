class_name MoonmartCustomers
extends RefCounted

signal customer_arrived(customer: Dictionary)
signal customer_left(customer_id: String)
signal customer_state_changed(customer: Dictionary, previous_state: String, next_state: String)

var definitions: Dictionary = {}
var active: Array[Dictionary] = []
var queue: Array[Dictionary] = []
var seen: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var active_shift := 0
var ordinary_customer_ids: Dictionary = {}

const CUSTOMER_STATES := ["SCHEDULED", "ARRIVING", "BROWSING", "LINGERING", "CONVERSING", "QUEUING", "CHECKOUT", "LEAVING"]
const MAX_ORDINARY_VISITORS_PER_SHIFT := 2
const PACKING_PREFERENCE_IDS := ["paper", "careful", "reusable"]
const STATE_TRANSITIONS := {
	"SCHEDULED": ["ARRIVING"],
	"ARRIVING": ["BROWSING", "LEAVING"],
	"BROWSING": ["LINGERING", "CONVERSING", "QUEUING", "LEAVING"],
	"LINGERING": ["CONVERSING", "QUEUING", "LEAVING"],
	"CONVERSING": ["LINGERING", "QUEUING", "LEAVING"],
	"QUEUING": ["CHECKOUT", "LEAVING"],
	"CHECKOUT": ["QUEUING", "LEAVING"],
	"LEAVING": []
}

func setup(rows: Array, ordinary_rows: Array = []) -> void:
	definitions.clear()
	ordinary_customer_ids.clear()
	rng.randomize()
	for row in rows:
		if row is Dictionary and row.has("id"):
			definitions[String(row.id)] = row.duplicate(true)
	for row in ordinary_rows:
		if not row is Dictionary or not row.has("id"):
			continue
		var ordinary_id := String(row.id)
		if ordinary_id.is_empty() or definitions.has(ordinary_id):
			continue
		var ordinary_definition: Dictionary = row.duplicate(true)
		ordinary_definition["ordinary_visitor"] = true
		definitions[ordinary_id] = ordinary_definition
		ordinary_customer_ids[ordinary_id] = true

func start_shift(shift_number: int, story_events: Array, context: Dictionary = {}) -> void:
	active_shift = shift_number
	for previous_customer in active:
		customer_left.emit(String(previous_customer.get("id", "")))
	active.clear()
	queue.clear()
	_spawn_timer = 14.0
	var crafted_order_assigned := false
	var ordinary_visitors_queued := 0
	# Essential visitors are scheduled persistently by the story layer; ordinary
	# visits add life but never gate progression.
	for event in story_events:
		if not bool(event.get("essential", true)):
			continue
		var visitor := String(event.get("visitor", ""))
		if visitor.is_empty() or not definitions.has(visitor) or ordinary_customer_ids.has(visitor):
			continue
		var customer := _make_customer(visitor, true)
		queue.append(customer)
	for id in definitions:
		var already_queued := false
		for queued_customer in queue:
			if String(queued_customer.get("id", "")) == String(id):
				already_queued = true
				break
		if already_queued:
			continue
		var definition: Dictionary = definitions[id]
		var is_ordinary_visitor := ordinary_customer_ids.has(String(id))
		if is_ordinary_visitor and ordinary_visitors_queued >= MAX_ORDINARY_VISITORS_PER_SHIFT:
			continue
		if int(definition.get("chapter", 1)) > int(context.get("chapter", 1)):
			continue
		var schedule: Dictionary = definition.get("schedule", {})
		var preferred_days: Array = schedule.get("preferred_days", definition.get("preferred_days", []))
		var day_index := posmod(shift_number - 1, 7)
		var day_names := ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
		var preferred_today := preferred_days.has(day_names[day_index])
		var odds := 0.09 + (0.34 if preferred_today else 0.0)
		var season_id := String(context.get("season", "spring"))
		if definition.get("preferred_seasons", []).has(season_id):
			odds += 0.10
		var seasonal_products := _seasonal_favourite_products(definition, season_id, context)
		if not seasonal_products.is_empty():
			odds += 0.10
		if String(context.get("weather", "clear")) == "rain" and String(id) == "lucien":
			odds += 0.24
		var preferred_weather: Array = definition.get("weather_preferences", [])
		if preferred_weather.has(String(context.get("weather", "clear"))):
			odds += 0.16
		for favourite_id in definition.get("favourite_products", []):
			if int(context.get("stock_products", {}).get(String(favourite_id), 0)) > 0:
				odds += 0.22
				break
		odds += clampf((float(context.get("cleanliness", 82.0)) - 60.0) * 0.001, -0.04, 0.05)
		if bool(context.get("reading_nook", false)):
			odds += 0.04
		if "supernatural" in definition.get("tags", []):
			odds += float(context.get("harmony", 0)) * 0.001
			var decoration_effects: Dictionary = context.get("decoration_effects", {})
			var lantern_effect: Dictionary = decoration_effects.get("nocturnal_visitor_attraction", {})
			var lantern_bonus := 0.0
			var effect_target_tag := String(lantern_effect.get("target_tag", ""))
			var effect_weather := String(lantern_effect.get("weather", ""))
			if not lantern_effect.is_empty() and (effect_target_tag.is_empty() or definition.get("tags", []).has(effect_target_tag)) and (effect_weather.is_empty() or effect_weather == String(context.get("weather", "clear"))):
				lantern_bonus = maxf(0.0, float(lantern_effect.get("amount", 0.0)))
			var upgrade_bonus := 0.08 if bool(context.get("enchanted_lighting", false)) and String(context.get("weather", "clear")) == "clear" else 0.0
			odds += maxf(lantern_bonus, upgrade_bonus)
		odds += minf(0.12, float(context.get("relationships", {}).get(String(id), 0)) * 0.03)
		odds += minf(0.12, float(seen.get(String(id), 0)) * 0.02)
		if shift_number >= int(definition.get("minimum_shift", 1)) and rng.randf() < odds:
			var customer := _make_customer(String(id), false, context)
			if not crafted_order_assigned:
				crafted_order_assigned = _attach_crafted_order(customer, context)
			queue.append(customer)
			if is_ordinary_visitor:
				ordinary_visitors_queued += 1
	# Keep essential story visits first; shuffle only the optional regulars.
	var required: Array[Dictionary] = []
	var optional: Array[Dictionary] = []
	for customer in queue:
		if customer.get("essential", false): required.append(customer)
		else: optional.append(customer)
	for i in range(optional.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := optional[i]
		optional[i] = optional[j]
		optional[j] = swap
	queue.clear()
	queue.append_array(required)
	queue.append_array(optional)

func tick(delta: float, shift_open: bool, current_hour: int = 0) -> void:
	if not shift_open:
		return
	_advance_visitors(delta)
	_spawn_timer -= delta
	if _spawn_timer > 0.0 or queue.is_empty():
		return
	# Essential visitors remain available at any time. Optional regulars wait
	# until one of their configured overnight arrival windows.
	var next_index := -1
	for index in range(queue.size()):
		var candidate: Dictionary = queue[index]
		var preferred_hours: Array = candidate.get("preferred_hours", [])
		if bool(candidate.get("essential", false)) or preferred_hours.is_empty() or preferred_hours.has(current_hour):
			next_index = index
			break
	if next_index < 0:
		_spawn_timer = 4.0
		return
	var next: Dictionary = queue.pop_at(next_index)
	if next.get("essential", false) or active.size() < 2:
		active.append(next)
		_transition(next, "ARRIVING")
		customer_arrived.emit(next)
	else:
		# Optional visits wait their turn instead of disappearing when the shop
		# is already busy. The queue remains small and the customer can arrive
		# later in the same eligible hour.
		queue.append(next)
		_spawn_timer = 4.0
		return
	_spawn_timer = rng.randf_range(20.0, 38.0)

func _make_customer(id: String, essential: bool, context: Dictionary = {}) -> Dictionary:
	var data: Dictionary = definitions[id]
	var schedule: Dictionary = data.get("schedule", {})
	var favorites: Array = data.get("favourite_products", data.get("favorite_products", [])).duplicate()
	var basket: Dictionary = data.get("basket", {"bread": 1, "tea": 1}).duplicate(true)
	var name_pool: Array = data.get("name_pool", [])
	var customer_name: String = String(name_pool[rng.randi_range(0, name_pool.size() - 1)]) if not name_pool.is_empty() else String(data.get("name", id))
	var browse_target := String(favorites[rng.randi_range(0, favorites.size() - 1)]) if not favorites.is_empty() else String(basket.keys()[0]) if not basket.is_empty() else "shelves"
	var seasonal_options: Array[String] = []
	if not essential:
		seasonal_options = _seasonal_favourite_products(data, String(context.get("season", "spring")), context)
		if not seasonal_options.is_empty() and rng.randf() < clampf(float(data.get("seasonal_browse_chance", 0.65)), 0.0, 1.0):
			browse_target = seasonal_options[rng.randi_range(0, seasonal_options.size() - 1)]
	var demand_variant: Dictionary = {}
	if not essential and ordinary_customer_ids.has(id):
		demand_variant = _apply_optional_demand_variant(data, basket, context)
		if not demand_variant.is_empty():
			browse_target = String(demand_variant.get("product_id", browse_target))
	var tags: Array = data.get("tags", [])
	var is_regular := tags.has("regular") or essential
	var conversation_chance := clampf(float(data.get("conversation_chance", 0.18 if is_regular else 0.06)), 0.0, 1.0)
	var linger_chance := clampf(float(data.get("linger_chance", 0.20 if is_regular else 0.08)), 0.0, 1.0)
	if not essential:
		var decoration_effects: Dictionary = context.get("decoration_effects", {})
		var chair_effect: Dictionary = decoration_effects.get("reading_chair_linger", {})
		var chair_bonus := maxf(0.0, float(chair_effect.get("amount", 0.0)))
		var reading_nook_bonus := 0.06 if bool(context.get("reading_nook", false)) else 0.0
		linger_chance = clampf(linger_chance + maxf(chair_bonus, reading_nook_bonus), 0.0, 1.0)
	var patience := maxf(90.0, float(data.get("patience_seconds", 180.0)))
	var customer := {
		"id": id,
		"name": customer_name,
		"essential": essential,
		"preferred_hours": schedule.get("preferred_hours", data.get("preferred_hours", [])).duplicate(),
		"payment_currency": String(data.get("payment_currency", "coins")),
		"packing_preference": _packing_preference_for_definition(data),
		"basket": basket,
		"state": "SCHEDULED",
		"state_elapsed": 0.0,
		"visit_count": 0 if ordinary_customer_ids.has(id) else int(seen.get(id, 0)),
		"browsing_choice": {"kind": "look_for_favourite", "product_id": browse_target},
		"browse_duration": rng.randf_range(4.5, 8.0),
		"linger_duration": rng.randf_range(4.0, 10.0),
		"conversation_duration": rng.randf_range(7.0, 14.0),
		"wants_to_linger": rng.randf() < linger_chance,
		"wants_to_converse": rng.randf() < conversation_chance,
		"has_conversed": false,
		"patience_seconds": patience,
		"patience_remaining": -1.0 if essential else patience,
		"service_bonus_eligible": true
	}
	if not essential:
		customer["seasonal_favourite_products"] = seasonal_options
	if not demand_variant.is_empty():
		customer["demand_variant_id"] = String(demand_variant.get("id", ""))
	return customer

## Optional ordinary visitors can change one basket slot to match season or
## weather. The desired item must already be displayed, so this never creates
## unmet stock requests or changes an essential story basket.
func _apply_optional_demand_variant(definition: Dictionary, basket: Dictionary, context: Dictionary) -> Dictionary:
	var authored_rules: Variant = definition.get("demand_variants", [])
	if not authored_rules is Array or authored_rules.is_empty():
		return {}
	var season_id := String(context.get("season", "spring"))
	var weather_id := String(context.get("weather", "clear"))
	var displayed: Dictionary = context.get("stock_products", {})
	var eligible: Array[Dictionary] = []
	for rule in authored_rules:
		if not rule is Dictionary:
			continue
		var conditions: Dictionary = rule.get("when", {})
		var rule_season := String(conditions.get("season", ""))
		var rule_weather := String(conditions.get("weather", ""))
		if not rule_season.is_empty() and rule_season != season_id:
			continue
		if not rule_weather.is_empty() and rule_weather != weather_id:
			continue
		if rule_season.is_empty() and rule_weather.is_empty():
			continue
		var replace_id := String(rule.get("replace_product", ""))
		var product_id := String(rule.get("product_id", ""))
		var amount := int(basket.get(replace_id, 0))
		if replace_id.is_empty() or product_id.is_empty() or amount <= 0 or basket.has(product_id):
			continue
		if int(displayed.get(product_id, 0)) < amount:
			continue
		eligible.append(rule)
	if eligible.is_empty():
		return {}
	var selected: Dictionary = eligible[rng.randi_range(0, eligible.size() - 1)]
	if rng.randf() >= clampf(float(selected.get("chance", 0.65)), 0.0, 1.0):
		return {}
	var selected_replace_id := String(selected.get("replace_product", ""))
	var selected_product_id := String(selected.get("product_id", ""))
	basket[selected_product_id] = int(basket[selected_replace_id])
	basket.erase(selected_replace_id)
	return selected.duplicate(true)

func _seasonal_favourite_products(definition: Dictionary, season_id: String, context: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var seasonal_favourites: Variant = definition.get("seasonal_favourite_products", {})
	if not seasonal_favourites is Dictionary:
		return result
	var available_products: Dictionary = context.get("stock_products", {})
	for product_id in seasonal_favourites.get(season_id, []):
		var id := String(product_id)
		if not id.is_empty() and int(available_products.get(id, 0)) > 0 and not result.has(id):
			result.append(id)
	return result

func _attach_crafted_order(customer: Dictionary, context: Dictionary) -> bool:
	var definition: Dictionary = definitions.get(String(customer.get("id", "")), {})
	var options: Array = definition.get("craft_order_products", [])
	var displayed_products: Dictionary = context.get("stock_products", {})
	var available: Array[String] = []
	var basket: Dictionary = customer.get("basket", {})
	for product_id in options:
		var id := String(product_id)
		if int(displayed_products.get(id, 0)) > int(basket.get(id, 0)):
			available.append(id)
	if available.is_empty():
		return false
	var selected_id := available[rng.randi_range(0, available.size() - 1)]
	basket[selected_id] = int(basket.get(selected_id, 0)) + 1
	customer["basket"] = basket
	var choice: Dictionary = customer.get("browsing_choice", {}).duplicate(true)
	choice["product_id"] = selected_id
	customer["browsing_choice"] = choice
	return true

func _advance_visitors(delta: float) -> void:
	var leaving_ids: Array[String] = []
	for customer in active:
		var state := String(customer.get("state", "ARRIVING"))
		customer["state_elapsed"] = float(customer.get("state_elapsed", 0.0)) + delta
		if state == "QUEUING" and not bool(customer.get("essential", false)):
			var remaining_patience := float(customer.get("patience_remaining", customer.get("patience_seconds", 180.0)))
			if remaining_patience > 0.0:
				remaining_patience = maxf(0.0, remaining_patience - delta)
				customer["patience_remaining"] = remaining_patience
				if remaining_patience <= 0.0:
					# A slow checkout costs only the optional service bonus. Visitors
					# remain welcome, and essential story encounters are never timed.
					customer["service_bonus_eligible"] = false
		var elapsed := float(customer.get("state_elapsed", 0.0))
		match state:
			"ARRIVING":
				if elapsed >= 2.5:
					_transition(customer, "BROWSING")
			"BROWSING":
				if elapsed >= float(customer.get("browse_duration", 5.0)):
					if bool(customer.get("wants_to_linger", false)):
						_transition(customer, "LINGERING")
					elif bool(customer.get("wants_to_converse", false)):
						_transition(customer, "CONVERSING")
					else:
						_transition(customer, "QUEUING")
			"LINGERING":
				if elapsed >= float(customer.get("linger_duration", 6.0)):
					if bool(customer.get("wants_to_converse", false)) and not bool(customer.get("has_conversed", false)):
						_transition(customer, "CONVERSING")
					else:
						_transition(customer, "QUEUING")
			"CONVERSING":
				if elapsed >= float(customer.get("conversation_duration", 10.0)):
					customer["has_conversed"] = true
					_transition(customer, "QUEUING")
			"LEAVING":
				if elapsed >= 1.5:
					leaving_ids.append(String(customer.get("id", "")))
	for customer_id in leaving_ids:
		_remove_visit(customer_id)

func _transition(customer: Dictionary, next_state: String) -> bool:
	var previous := String(customer.get("state", "SCHEDULED"))
	if not CUSTOMER_STATES.has(next_state) or not STATE_TRANSITIONS.get(previous, []).has(next_state):
		return false
	customer["state"] = next_state
	customer["state_elapsed"] = 0.0
	customer_state_changed.emit(customer, previous, next_state)
	return true

func begin_checkout(id: String) -> bool:
	var customer := get_customer(id)
	if customer.is_empty() or not ["QUEUING", "CHECKOUT"].has(String(customer.get("state", ""))):
		return false
	if String(customer.get("state", "")) == "CHECKOUT":
		return true
	return _transition(customer, "CHECKOUT")

func begin_conversation(id: String) -> bool:
	var customer := get_customer(id)
	if customer.is_empty() or not ["BROWSING", "LINGERING"].has(String(customer.get("state", ""))):
		return false
	customer["has_conversed"] = true
	return _transition(customer, "CONVERSING")

func cancel_checkout(id: String) -> bool:
	var customer := get_customer(id)
	if customer.is_empty() or String(customer.get("state", "")) != "CHECKOUT":
		return false
	return _transition(customer, "QUEUING")

func finish_conversation(id: String) -> bool:
	var customer := get_customer(id)
	if customer.is_empty() or String(customer.get("state", "")) != "CONVERSING":
		return false
	customer["has_conversed"] = true
	return _transition(customer, "QUEUING")

func get_customer(id: String) -> Dictionary:
	for customer in active:
		if customer.id == id:
			return customer
	return {}

func complete_visit(id: String) -> void:
	var customer := get_customer(id)
	if customer.is_empty():
		return
	if String(customer.get("state", "")) != "LEAVING":
		customer["visit_outcome"] = "served"
		if _transition(customer, "LEAVING"):
			return
	_remove_visit(id)

func _remove_visit(id: String) -> void:
	for i in range(active.size() - 1, -1, -1):
		if active[i].id == id:
			active.remove_at(i)
			seen[id] = int(seen.get(id, 0)) + 1
			customer_left.emit(id)
			return

func to_save() -> Dictionary:
	return {"active": active.duplicate(true), "queue": queue.duplicate(true), "seen": seen.duplicate(true), "rng_state": rng.state, "active_shift": active_shift, "spawn_timer": _spawn_timer}

func from_save(data: Dictionary) -> void:
	active.clear()
	for row in data.get("active", []):
		if row is Dictionary and definitions.has(String(row.get("id", ""))):
			active.append(_restore_customer(row, false))
	queue.clear()
	for row in data.get("queue", []):
		if row is Dictionary and definitions.has(String(row.get("id", ""))):
			queue.append(_restore_customer(row, true))
	seen = data.get("seen", {}).duplicate(true)
	if data.has("rng_state") and int(data.rng_state) != 0: rng.state = int(data.rng_state)
	active_shift = int(data.get("active_shift", 0))
	_spawn_timer = maxf(0.0, float(data.get("spawn_timer", _spawn_timer)))

func _restore_customer(row: Dictionary, queued: bool) -> Dictionary:
	var customer := row.duplicate(true)
	var definition: Dictionary = definitions.get(String(customer.get("id", "")), {})
	var state := String(customer.get("state", "SCHEDULED" if queued else "ARRIVING"))
	if not CUSTOMER_STATES.has(state):
		state = "SCHEDULED" if queued else "ARRIVING"
	if queued:
		state = "SCHEDULED"
	elif state == "SCHEDULED":
		state = "ARRIVING"
	customer["state"] = state
	customer["state_elapsed"] = maxf(0.0, float(customer.get("state_elapsed", 0.0)))
	customer["basket"] = customer.get("basket", definitions.get(String(customer.get("id", "")), {}).get("basket", {})).duplicate(true)
	customer["packing_preference"] = _packing_preference_for_definition(definition, String(customer.get("packing_preference", "")))
	var favorites: Array = definition.get("favourite_products", definition.get("favorite_products", []))
	if not customer.has("browsing_choice"):
		var target := String(favorites[0]) if not favorites.is_empty() else (String(customer["basket"].keys()[0]) if not customer["basket"].is_empty() else "shelves")
		customer["browsing_choice"] = {"kind": "look_for_favourite", "product_id": target}
	customer["browse_duration"] = maxf(2.5, float(customer.get("browse_duration", 5.0)))
	customer["linger_duration"] = maxf(2.0, float(customer.get("linger_duration", 6.0)))
	customer["conversation_duration"] = maxf(3.0, float(customer.get("conversation_duration", 10.0)))
	customer["wants_to_linger"] = bool(customer.get("wants_to_linger", false))
	customer["wants_to_converse"] = bool(customer.get("wants_to_converse", false))
	customer["has_conversed"] = bool(customer.get("has_conversed", false))
	var patience := maxf(90.0, float(customer.get("patience_seconds", definition.get("patience_seconds", 180.0))))
	customer["patience_seconds"] = patience
	customer["patience_remaining"] = -1.0 if bool(customer.get("essential", false)) else clampf(float(customer.get("patience_remaining", patience)), 0.0, patience)
	customer["service_bonus_eligible"] = bool(customer.get("service_bonus_eligible", true))
	return customer

func _packing_preference_for_definition(definition: Dictionary, saved_preference: String = "") -> String:
	if PACKING_PREFERENCE_IDS.has(saved_preference):
		return saved_preference
	var preference := String(definition.get("packing_preference", ""))
	if PACKING_PREFERENCE_IDS.has(preference):
		return preference
	# Older content and saved visitors receive a gentle default based on the
	# existing character kind; packing never changes access to a sale or story.
	var kind := String(definition.get("kind", "human"))
	if kind in ["ghost", "forest_spirit", "witch", "between_keeper", "between_lost"]:
		return "reusable"
	return "paper"
