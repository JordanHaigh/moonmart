extends SceneTree

const GAME_SCRIPT = preload("res://scripts/core/moonmart_game.gd")
const SAVE_MANAGER = preload("res://scripts/core/save_manager.gd")
const RECIPE_DATA_PATH := "res://data/recipes.json"
const PRODUCT_DATA_PATH := "res://data/products.json"
const QUEST_DATA_PATH := "res://data/quests.json"
const STATIONS: Array[String] = ["tea", "coffee", "magical_kettle", "microwave", "sandwich", "bakery_warmer"]
const SAVE_ARTIFACTS: Array[String] = [
	"user://moonmart_save.json", "user://moonmart_save.tmp", "user://moonmart_save.replace",
	"user://moonmart_save.recovered", "user://moonmart_save.recovered.tmp", "user://moonmart_save.recovered.replace",
	"user://moonmart_save.bak", "user://moonmart_save.bak.tmp", "user://moonmart_save.bak.replace"
]

var _checks := 0
var _failures: Array[String] = []
var _game: Node

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _preflight_save_paths():
		quit(2)
		return
	var recipe_rows := _read_rows(RECIPE_DATA_PATH, "recipes")
	var product_rows := _read_rows(PRODUCT_DATA_PATH, "products")
	var product_by_id: Dictionary = {}
	for product in product_rows:
		product_by_id[String(product.get("id", ""))] = product
	var recipe_by_id: Dictionary = {}
	for recipe in recipe_rows:
		var recipe_id := String(recipe.get("id", ""))
		_check(not recipe_id.is_empty() and not recipe_by_id.has(recipe_id), "recipe id %s is present and unique" % recipe_id)
		recipe_by_id[recipe_id] = recipe
	_check(recipe_rows.size() == 50, "catalog contains all 50 authored recipes")
	_check(product_rows.size() == 150, "catalog resolves against the 150-product inventory")
	_check(STATIONS.size() == 6, "six preparation stations are declared")
	var input_totals: Dictionary = {}
	var station_counts: Dictionary = {}
	var discovery_values := ["known", "shift_2", "pip_memory"]
	for recipe in recipe_rows:
		var recipe_id := String(recipe.get("id", ""))
		var station := String(recipe.get("station", ""))
		var output_id := String(recipe.get("output_product_id", ""))
		var output_quantity := int(recipe.get("output_quantity", 0))
		var discovery := String(recipe.get("discovery", "known"))
		_check(STATIONS.has(station), "%s uses a valid station" % recipe_id)
		station_counts[station] = int(station_counts.get(station, 0)) + 1
		_check(product_by_id.has(output_id), "%s output %s exists in products" % [recipe_id, output_id])
		_check(output_quantity > 0, "%s has a positive output quantity" % recipe_id)
		if product_by_id.has(output_id):
			var output_product: Dictionary = product_by_id[output_id]
			_check(bool(output_product.get("craft_only", false)), "%s output is a craft-only product" % recipe_id)
		_check(discovery_values.has(discovery), "%s uses a supported discovery source" % recipe_id)
		var ingredients: Dictionary = recipe.get("ingredients", {})
		_check(not ingredients.is_empty(), "%s has at least one ingredient" % recipe_id)
		for ingredient_value in ingredients:
			var ingredient_id := String(ingredient_value)
			var quantity := int(ingredients[ingredient_value])
			_check(product_by_id.has(ingredient_id), "%s ingredient %s exists in products" % [recipe_id, ingredient_id])
			_check(quantity > 0, "%s ingredient %s has a positive quantity" % [recipe_id, ingredient_id])
			input_totals[ingredient_id] = int(input_totals.get(ingredient_id, 0)) + quantity
	for station in STATIONS:
		_check(int(station_counts.get(station, 0)) > 0, "station %s has recipes" % station)
	_check(station_counts.size() == STATIONS.size(), "recipes cover exactly the six declared stations")
	var quest_rows := _read_rows(QUEST_DATA_PATH, "story_events")
	var pip_memory_source := false
	for event in quest_rows:
		if String(event.get("id", "")) == "pip_first_memory":
			pip_memory_source = true
	_check(pip_memory_source, "pip_memory recipes have an authored story unlock event")

	_game = GAME_SCRIPT.new()
	root.add_child(_game)
	await process_frame
	_check(_game != null and _game.get("recipes") is Dictionary, "MoonmartGame loads the recipe book")
	if _game != null:
		_game.set("shift_number", 1)
		var story = _game.get("story")
		var base_count := 0
		for station in STATIONS:
			var available: Array = _game.call("available_recipes", station)
			for recipe in available:
				_check(String(recipe.get("station", "")) == station, "%s recipe stays within station %s" % [String(recipe.get("id", "")), station])
				_check(String(recipe.get("discovery", "known")) == "known", "%s is the only initially available discovery class" % String(recipe.get("id", "")))
			base_count += available.size()
		_check(base_count == _count_discovery(recipe_rows, "known"), "initial station views expose every and only known recipe")
		var locked_shift_recipe: Dictionary = _recipe_with_discovery(recipe_rows, "shift_2")
		if not locked_shift_recipe.is_empty():
			var locked_result: Dictionary = _game.call("experiment_recipe", String(locked_shift_recipe.get("station", "")), _integer_ingredients(locked_shift_recipe.get("ingredients", {})))
			_check(String(locked_result.get("reason", "")) == "recipe_locked", "shift-two recipe experimentation remains gated before shift two · result=%s" % str(locked_result))
		_game.set("shift_number", 2)
		var shift_two_count := 0
		for station in STATIONS:
			for recipe in _game.call("available_recipes", station):
				shift_two_count += 1
		_check(shift_two_count == _count_discovery(recipe_rows, "known"), "shift two preserves the discovered-only cookbook view")
		var story_flags: Dictionary = story.get("flags")
		story_flags["pip_first_memory"] = true
		story.set("flags", story_flags)
		var all_available: Dictionary = {}
		for station in STATIONS:
			for recipe in _game.call("available_recipes", station):
				all_available[String(recipe.get("id", ""))] = String(recipe.get("station", ""))
		_check(all_available.size() == _count_discovery(recipe_rows, "known"), "story and shift unlocks do not bypass recipe discovery")
		for recipe in recipe_rows:
			var recipe_id := String(recipe.get("id", ""))
			var station := String(recipe.get("station", ""))
			if String(recipe.get("discovery", "known")) == "known":
				_check(String(all_available.get(recipe_id, "")) == station, "%s known recipe is available at its documented station" % recipe_id)
			else:
				_check(not all_available.has(recipe_id), "%s stays out of the cookbook until discovered" % recipe_id)
			var wrong_station := STATIONS[0] if station != STATIONS[0] else STATIONS[1]
			var wrong_result: Dictionary = _game.call("craft", recipe_id, wrong_station)
			_check(not bool(wrong_result.get("ok", false)) and String(wrong_result.get("reason", "")) == "wrong_station", "%s rejects the wrong station" % recipe_id)

		var inventory = _game.get("inventory")
		inventory.set("storage_capacity", 10000)
		for recipe in recipe_rows:
			var recipe_id := String(recipe.get("id", ""))
			var station := String(recipe.get("station", ""))
			var output_id := String(recipe.get("output_product_id", ""))
			var expected_quantity := int(recipe.get("output_quantity", 0))
			inventory.call("setup", product_rows, recipe.get("ingredients", {}))
			var craft_result: Dictionary
			if String(recipe.get("discovery", "known")) == "known":
				craft_result = _game.call("craft", recipe_id, station)
			else:
				craft_result = _game.call("experiment_recipe", station, _integer_ingredients(recipe.get("ingredients", {})))
			_check(bool(craft_result.get("ok", false)), "%s prepares through its documented craft/discovery path · result=%s" % [recipe_id, str(craft_result)])
			_check(String(craft_result.get("output_product_id", craft_result.get("product_id", ""))) == output_id, "%s produces its authored product" % recipe_id)
			_check(int(craft_result.get("produced", craft_result.get("quantity", 0))) == expected_quantity, "%s produces its authored quantity" % recipe_id)
			_check(int(inventory.call("storage_quantity", output_id)) >= expected_quantity, "%s output enters backroom storage" % recipe_id)

	if _game != null and is_instance_valid(_game):
		_game.free()
	_cleanup_save_paths()
	if _failures.is_empty():
		print("Recipe catalog validation passed: %d checks, %d recipes, %d stations." % [_checks, recipe_rows.size(), STATIONS.size()])
	else:
		for failure in _failures:
			push_error(failure)
		printerr("Recipe catalog validation failed: %d of %d checks." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)

func _count_discovery(rows: Array[Dictionary], discovery: String) -> int:
	var count := 0
	for row in rows:
		if String(row.get("discovery", "known")) == discovery:
			count += 1
	return count

func _recipe_with_discovery(rows: Array[Dictionary], discovery: String) -> Dictionary:
	for row in rows:
		if String(row.get("discovery", "known")) == discovery:
			return row
	return {}

func _integer_ingredients(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for ingredient_id in source:
		result[String(ingredient_id)] = int(source[ingredient_id])
	return result

func _read_rows(path: String, key: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var rows: Array[Dictionary] = []
	if not parsed is Dictionary:
		return rows
	for row in parsed.get(key, []):
		if row is Dictionary:
			rows.append(row)
	return rows

func _preflight_save_paths() -> bool:
	for path in SAVE_ARTIFACTS:
		if FileAccess.file_exists(path):
			push_error("Refusing to run recipe fixtures over an existing user save: %s" % path)
			return false
	return true

func _cleanup_save_paths() -> void:
	for path in SAVE_ARTIFACTS:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
