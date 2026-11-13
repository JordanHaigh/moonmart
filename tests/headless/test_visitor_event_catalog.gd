extends SceneTree

const CUSTOMER_MANAGER := preload("res://scripts/systems/customer_manager.gd")
const CHARACTERS_PATH := "res://data/characters.json"
const ORDINARY_PATH := "res://data/ordinary_customers.json"
const EVENTS_PATH := "res://data/events.json"
const PRODUCTS_PATH := "res://data/products.json"
const QUESTS_PATH := "res://data/quests.json"
const CALENDAR_PATH := "res://data/calendar.json"

var _checks := 0
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var characters := _read_rows(CHARACTERS_PATH, "characters")
	var ordinary := _read_rows(ORDINARY_PATH, "ordinary_customers")
	var events := _read_rows(EVENTS_PATH, "events")
	var products := _read_rows(PRODUCTS_PATH, "products")
	var quests := _read_json(QUESTS_PATH)
	var calendar := _read_json(CALENDAR_PATH)
	var character_ids := _ids(characters)
	var ordinary_ids := _ids(ordinary)
	var product_ids := _ids(products)
	var event_ids := _ids(events)
	var product_categories := _string_set(products, "category")
	var seasonal_product_counts: Dictionary = {"spring":0, "summer":0, "autumn":0, "winter":0}
	var seasonal_orderable_count := 0
	for product in products:
		if bool(product.get("craft_only", false)):
			continue
		var product_seasons: Variant = product.get("seasonal_seasons", [])
		if not product_seasons is Array or product_seasons.is_empty():
			continue
		seasonal_orderable_count += 1
		for season_id in product_seasons:
			if seasonal_product_counts.has(String(season_id)):
				seasonal_product_counts[String(season_id)] = int(seasonal_product_counts[String(season_id)]) + 1
	var weekdays := _string_values(calendar.get("weekdays", []))
	for index in range(weekdays.size()):
		weekdays[index] = weekdays[index].to_lower()
	var seasons := _string_set(calendar.get("seasons", []), "id")
	var weather_values := ["clear", "rain", "fog", "wind", "snow"]
	var ending_ids := _ids(quests.get("endings", []))
	var world_states := ["ordinary_midnight"]
	for ending_value in quests.get("endings", []):
		if ending_value is Dictionary:
			world_states.append(String(ending_value.get("world_state", "")))
	var festival_ids := _string_set(calendar.get("festivals", []), "id")

	_expect(characters.size() == 25, "25 recurring named character definitions are loaded")
	_expect(ordinary.size() == 50, "50 ordinary visitor archetypes are loaded")
	_expect(events.size() == 100, "100 optional event definitions are loaded")
	_expect(_all_unique(character_ids), "named character IDs are unique")
	_expect(_all_unique(ordinary_ids), "ordinary visitor IDs are unique")
	_expect(_all_unique(event_ids), "optional event IDs are unique")
	_expect(_all_unique(product_ids), "product IDs are unique")
	_expect(seasonal_orderable_count >= 15, "at least 15 orderable products are season-tagged")
	for season_id in ["spring", "summer", "autumn", "winter"]:
		_expect(int(seasonal_product_counts.get(season_id, 0)) >= 3, "%s has at least three season-tagged orderable products" % season_id)

	for row in characters:
		var id := String(row.get("id", ""))
		_expect(not id.is_empty() and not String(row.get("name", "")).strip_edges().is_empty(), "%s has a stable ID and display name" % id)
		_expect(not String(row.get("role", "")).strip_edges().is_empty() and not String(row.get("greeting", "")).strip_edges().is_empty(), "%s has a role and greeting" % id)
		var sheet := "res://assets/raster/characters/%s_atlas.png" % id
		_expect(FileAccess.file_exists(sheet), "%s has its own raster character sheet" % id)
		_expect(_products_exist(row.get("basket", {}), product_ids), "%s basket references catalog products" % id)
		_expect(_product_array_exists(row.get("favourite_products", []), product_ids), "%s favourite products exist" % id)
		_expect(_product_array_exists(row.get("craft_order_products", []), product_ids), "%s craft-order products exist" % id)
		var schedule: Variant = row.get("schedule", null)
		_expect(schedule is Dictionary, "%s has a schedule definition" % id)
		if schedule is Dictionary:
			_expect(_values_in_set(schedule.get("preferred_days", []), weekdays), "%s schedule weekdays are valid" % id)
			_expect(_hours_valid(schedule.get("preferred_hours", [])), "%s schedule hours are valid" % id)

	for row in ordinary:
		var id := String(row.get("id", ""))
		var names: Variant = row.get("name_pool", null)
		_expect(names is Array and not names.is_empty(), "%s has a populated name pool" % id)
		if names is Array:
			for name_value in names:
				_expect(name_value is String and not String(name_value).strip_edges().is_empty(), "%s name-pool entries are readable" % id)
		_expect(not String(row.get("role", "")).strip_edges().is_empty() and not String(row.get("greeting", "")).strip_edges().is_empty(), "%s has a role and greeting" % id)
		_expect(_products_exist(row.get("basket", {}), product_ids), "%s basket references catalog products" % id)
		_expect(_product_array_exists(row.get("favourite_products", []), product_ids), "%s favourite products exist" % id)
		var schedule: Variant = row.get("schedule", null)
		_expect(schedule is Dictionary, "%s has a schedule definition" % id)
		if schedule is Dictionary:
			_expect(_values_in_set(schedule.get("preferred_days", []), weekdays), "%s schedule weekdays are valid" % id)
			_expect(_hours_valid(schedule.get("preferred_hours", [])), "%s schedule hours are valid" % id)
		_expect(_values_in_set(row.get("weather_preferences", []), weather_values), "%s weather preferences use known weather IDs" % id)
		_expect(int(row.get("chapter", 0)) >= 1 and int(row.get("minimum_shift", 0)) >= 1, "%s has valid chapter and minimum-shift gates" % id)
		_expect(float(row.get("conversation_chance", -1.0)) >= 0.0 and float(row.get("conversation_chance", 2.0)) <= 1.0, "%s conversation chance is normalized" % id)
		_expect(float(row.get("linger_chance", -1.0)) >= 0.0 and float(row.get("linger_chance", 2.0)) <= 1.0, "%s linger chance is normalized" % id)
		var demand_variants: Variant = row.get("demand_variants", [])
		if demand_variants is Array:
			for variant in demand_variants:
				_expect(variant is Dictionary, "%s demand variants are objects" % id)
				if not variant is Dictionary:
					continue
				var conditions: Variant = variant.get("when", {})
				var replace_id := String(variant.get("replace_product", ""))
				var product_id := String(variant.get("product_id", ""))
				_expect(conditions is Dictionary and (not String(conditions.get("season", "")).is_empty() or not String(conditions.get("weather", "")).is_empty()), "%s demand variant has a season or weather condition" % id)
				if conditions is Dictionary:
					_expect(String(conditions.get("season", "")).is_empty() or seasons.has(String(conditions.get("season", ""))), "%s demand variant uses a known season" % id)
					_expect(String(conditions.get("weather", "")).is_empty() or weather_values.has(String(conditions.get("weather", ""))), "%s demand variant uses a known weather" % id)
				_expect(float(variant.get("chance", -1.0)) >= 0.0 and float(variant.get("chance", 2.0)) <= 1.0, "%s demand variant chance is normalized" % id)
				_expect(product_ids.has(replace_id) and int(row.get("basket", {}).get(replace_id, 0)) > 0, "%s demand variant replaces an item in its authored basket" % id)
				_expect(product_ids.has(product_id) and not row.get("basket", {}).has(product_id), "%s demand variant adds a distinct catalog product" % id)
	var demand_variant_visitor_count := 0
	var demand_variant_seasons: Dictionary = {}
	var demand_variant_weather: Dictionary = {}
	for row in ordinary:
		var authored_variants: Variant = row.get("demand_variants", [])
		if not authored_variants is Array or authored_variants.is_empty():
			continue
		demand_variant_visitor_count += 1
		for variant in authored_variants:
			if not variant is Dictionary:
				continue
			var conditions: Dictionary = variant.get("when", {})
			var season_id := String(conditions.get("season", ""))
			var weather_id := String(conditions.get("weather", ""))
			if not season_id.is_empty(): demand_variant_seasons[season_id] = true
			if not weather_id.is_empty(): demand_variant_weather[weather_id] = true
	_expect(demand_variant_visitor_count == 8, "eight ordinary visitors have demand variants")
	_expect(demand_variant_seasons.size() == 4, "demand variants cover all four seasons")
	_expect(["rain", "fog", "wind", "snow"].all(func(weather_id): return demand_variant_weather.has(weather_id)), "demand variants cover rain, fog, wind, and snow")
	_test_demand_variant_runtime(characters, ordinary)

	var visitor_ids := character_ids + ordinary_ids
	for row in events:
		var id := String(row.get("id", ""))
		_expect(not id.is_empty() and not String(row.get("kind", "")).is_empty(), "%s has an event ID and kind" % id)
		_expect(not String(row.get("message", "")).strip_edges().is_empty(), "%s has display text" % id)
		_expect(float(row.get("weight", 0.0)) > 0.0 and int(row.get("min_shift", 1)) >= 1, "%s has a positive weight and valid shift gate" % id)
		var visitor := String(row.get("visitor", ""))
		_expect(visitor.is_empty() or visitor_ids.has(visitor), "%s visitor reference resolves" % id)
		_expect(_values_in_set(row.get("days", []), weekdays), "%s day gates use known weekdays" % id)
		_expect(_values_in_set(row.get("seasons", []), seasons), "%s season gates use known seasons" % id)
		_expect(_values_in_set(row.get("weather", []), weather_values), "%s weather gates use known weather IDs" % id)
		_expect(_values_in_set(row.get("stock_categories", []), product_categories), "%s stock gates use known product categories" % id)
		_expect(_values_in_set(row.get("requires_endings", []), ending_ids), "%s ending gates use known ending IDs" % id)
		_expect(_values_in_set(row.get("requires_world_states", []), world_states), "%s world-state gates use known IDs" % id)
		var festival_id := String(row.get("festival_id", ""))
		_expect(festival_id.is_empty() or festival_ids.has(festival_id), "%s festival reference resolves" % id)
		_expect(_string_array(row.get("requires_flags", [])) and _string_array(row.get("forbidden_flags", [])), "%s story-flag gates are string arrays" % id)

	if _failures.is_empty():
		print("Visitor/event catalog validation passed: %d checks (%d characters, %d ordinary visitors, %d events)." % [_checks, characters.size(), ordinary.size(), events.size()])
	else:
		for failure in _failures:
			push_error(failure)
		printerr("Visitor/event catalog validation failed: %d of %d checks." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)

func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _read_rows(path: String, key: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var parsed := _read_json(path)
	for value in parsed.get(key, []):
		if value is Dictionary:
			rows.append(value)
	return rows

func _ids(rows: Array) -> Array[String]:
	var result: Array[String] = []
	for row in rows:
		if row is Dictionary:
			result.append(String(row.get("id", "")))
	return result

func _all_unique(values: Array[String]) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if value.is_empty() or seen.has(value):
			return false
		seen[value] = true
	return true

func _string_set(rows: Array, key: String = "") -> Array[String]:
	var result: Array[String] = []
	for value in rows:
		var text := String(value.get(key, "")) if value is Dictionary and not key.is_empty() else String(value)
		if not text.is_empty():
			result.append(text)
	return result

func _string_values(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result

func _values_in_set(value: Variant, allowed: Array) -> bool:
	if value == null:
		return true
	if not value is Array:
		return false
	for item in value:
		if not allowed.has(String(item)):
			return false
	return true

func _string_array(value: Variant) -> bool:
	if value == null:
		return true
	if not value is Array:
		return false
	for item in value:
		if not item is String or String(item).is_empty():
			return false
	return true

func _products_exist(basket: Variant, product_ids: Array[String]) -> bool:
	if not basket is Dictionary:
		return false
	for product_id in basket:
		if not product_ids.has(String(product_id)) or int(basket[product_id]) <= 0:
			return false
	return true

func _product_array_exists(value: Variant, product_ids: Array[String]) -> bool:
	if value == null:
		return true
	if not value is Array:
		return false
	for product_id in value:
		if not product_ids.has(String(product_id)):
			return false
	return true

func _hours_valid(value: Variant) -> bool:
	if not value is Array or value.is_empty():
		return false
	for hour in value:
		if typeof(hour) not in [TYPE_INT, TYPE_FLOAT] or float(hour) < 0.0 or float(hour) > 23.0 or floorf(float(hour)) != float(hour):
			return false
	return true

func _test_demand_variant_runtime(characters: Array[Dictionary], ordinary: Array[Dictionary]) -> void:
	var selected_row: Dictionary = {}
	var selected_variant: Dictionary = {}
	for row in ordinary:
		var variants: Variant = row.get("demand_variants", [])
		if variants is Array and not variants.is_empty() and variants[0] is Dictionary:
			selected_row = row
			selected_variant = variants[0].duplicate(true)
			break
	_expect(not selected_row.is_empty() and not selected_variant.is_empty(), "runtime demand-variant fixture resolves an authored ordinary visitor")
	if selected_row.is_empty() or selected_variant.is_empty():
		return
	var replacement_id := String(selected_variant.get("replace_product", ""))
	var product_id := String(selected_variant.get("product_id", ""))
	var base_basket: Dictionary = selected_row.get("basket", {}).duplicate(true)
	var amount := int(base_basket.get(replacement_id, 0))
	selected_variant["chance"] = 1.0
	var definition: Dictionary = selected_row.duplicate(true)
	definition["demand_variants"] = [selected_variant]
	var manager = CUSTOMER_MANAGER.new()
	manager.setup(characters, [definition])
	manager.rng.seed = 33128
	var matching_basket: Dictionary = base_basket.duplicate(true)
	var matching_context := {"season":String(selected_variant.get("when", {}).get("season", "spring")), "weather":String(selected_variant.get("when", {}).get("weather", "clear")), "stock_products":{product_id:amount}}
	var applied: Dictionary = manager._apply_optional_demand_variant(definition, matching_basket, matching_context)
	_expect(String(applied.get("id", "")) == String(selected_variant.get("id", "")), "displayed variant product applies under its authored condition")
	_expect(not matching_basket.has(replacement_id) and int(matching_basket.get(product_id, 0)) == amount and matching_basket.size() == base_basket.size(), "applied demand variant swaps exactly one basket item without changing basket size")
	var unavailable_basket: Dictionary = base_basket.duplicate(true)
	var unavailable: Dictionary = manager._apply_optional_demand_variant(definition, unavailable_basket, {"season":matching_context.season, "weather":matching_context.weather, "stock_products":{}})
	_expect(unavailable.is_empty() and unavailable_basket == base_basket, "unstocked replacement leaves the original basket unchanged")
	manager.rng.seed = 33128
	var essential_customer: Dictionary = manager._make_customer(String(selected_row.get("id", "")), true, matching_context)
	_expect(essential_customer.get("basket", {}) == base_basket and not essential_customer.has("demand_variant_id"), "essential visitors keep their authored basket regardless of demand variant stock")

func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
