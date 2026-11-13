class_name MoonmartGame
extends Node

signal clock_updated(text: String, elapsed_minutes: float)
signal message_changed(text: String)
signal save_failed
signal journal_changed(text: String)
signal customer_changed(customer: Dictionary, arrived: bool)
signal companion_reaction(text: String)
signal customer_state_changed(customer: Dictionary, state: String)
signal money_changed(coins: int, moon_tokens: int)
signal shift_changed(shift_number: int, status: String)
signal story_event(event_id: String, visitor_name: String)
signal sale_completed(customer_name: String, total: int, currency: String)
signal environmental_puzzle_completed(puzzle_id: String, reward_text: String)
signal location_unlocked(location_id: String)
signal location_changed(location_id: String)

const InventoryScript = preload("res://scripts/systems/inventory_manager.gd")
const TimeScript = preload("res://scripts/systems/time_manager.gd")
const CustomersScript = preload("res://scripts/systems/customer_manager.gd")
const NarrativeScript = preload("res://scripts/systems/narrative_manager.gd")
const SaveScript = preload("res://scripts/core/save_manager.gd")
const RelationshipsScript = preload("res://scripts/systems/relationship_manager.gd")
const QuestsScript = preload("res://scripts/systems/quest_manager.gd")
const MysteriesScript = preload("res://scripts/systems/mystery_manager.gd")
const WorldScript = preload("res://scripts/systems/world_manager.gd")
const DecorationsScript = preload("res://scripts/systems/decoration_manager.gd")
const EventDirectorScript = preload("res://scripts/systems/event_director.gd")
const CalendarScript = preload("res://scripts/systems/calendar_manager.gd")
const ShopProgressionScript = preload("res://scripts/systems/shop_progression_manager.gd")
const MisoCompanionScript = preload("res://scripts/systems/miso_companion_manager.gd")
const MisoDreamSequenceScript = preload("res://scripts/systems/miso_dream_sequence_manager.gd")
const EnvironmentalPuzzlesScript = preload("res://scripts/systems/environmental_puzzle_manager.gd")
const COLLECTIBLES_PATH := "res://data/collectibles.json"
const PRODUCTS_PATH := "res://data/products.json"
const CHARACTERS_PATH := "res://data/characters.json"
const ORDINARY_CUSTOMERS_PATH := "res://data/ordinary_customers.json"
const RECIPES_PATH := "res://data/recipes.json"
const DIALOGUE_PATH := "res://data/dialogue/story.json"
const TIMING_PATH := "res://data/balance/timing.json"
const EVENTS_PATH := "res://data/events.json"
const QUESTS_PATH := "res://data/quests.json"
const CLUES_PATH := "res://data/clues.json"
const INVESTIGATIONS_PATH := "res://data/investigations.json"
const LOCATIONS_PATH := "res://data/locations.json"
const FURNITURE_PATH := "res://data/furniture.json"
const CALENDAR_PATH := "res://data/calendar.json"
const SHOP_PROGRESSION_PATH := "res://data/shop_progression.json"
const MISO_COMPANION_PATH := "res://data/miso_companion.json"
const ENVIRONMENTAL_PUZZLES_PATH := "res://data/environmental_puzzles.json"
const LOCALIZED_DIALOGUE_DIR := "res://data/locales"

var inventory = InventoryScript.new()
var clock = TimeScript.new()
var customers = CustomersScript.new()
var story = NarrativeScript.new()
var relationships = RelationshipsScript.new()
var quests = QuestsScript.new()
var mysteries = MysteriesScript.new()
var world_map = WorldScript.new()
var decoration = DecorationsScript.new()
var event_director = EventDirectorScript.new()
var calendar = CalendarScript.new()
var shop_progression = ShopProgressionScript.new()
var miso_companion = MisoCompanionScript.new()
var miso_dream_sequence = MisoDreamSequenceScript.new()
var miso_memory_echo_fragments: Array[Dictionary] = []
var miso_hidden_paw_guidance: Dictionary = {}
var miso_spirit_sense_reaction_shifts: Dictionary = {}
var environmental_puzzles = EnvironmentalPuzzlesScript.new()
## Catalogued keepsakes remain separate from clues and never grant story flags.
var collectible_definitions: Dictionary = {}
var discovered_collectibles: Array[String] = []
var shift_number: int = 0
var shift_status := "between_shifts"
var shift_start_revenue := 0
var last_shift_earnings := 0
var shift_start_coins_revenue := 0
var shift_start_moons_revenue := 0
var last_shift_coin_earnings := 0
var last_shift_moon_earnings := 0
var last_message := "Moonmart is quiet. Miso is asleep on the counter."
var _pending_events: Array[Dictionary] = []
var recipes: Dictionary = {}
var discovered_recipe_ids: Array[String] = []
var event_definitions: Dictionary = {}
var _dialogue: Dictionary = {}
var _ui_translations: Dictionary = {}
var _conversation_turns: Dictionary = {}
var _pending_optional_events: Array[Dictionary] = []
var anomaly_disturbances: Array[Dictionary] = []
var resolved_anomaly_investigations: Array[String] = []
var _cleaning_actions_this_shift: Dictionary = {}
var _optional_event_timer := 38.0
var minimum_service_minutes := 60.0
var save_recovery_required := false
var save_recovery_message := ""
var save_recovered_from_backup := false
var save_recovered_from_staging := false
var player_positions: Dictionary = {}
var _locale_language_override_for_testing := ""

func set_locale_language_override_for_testing(language: String) -> void:
	var normalized := language.strip_edges().to_lower()
	if normalized.length() > 3:
		return
	for character in normalized:
		if not (character >= "a" and character <= "z"):
			return
	_locale_language_override_for_testing = normalized

func localization_language() -> String:
	return _active_locale_language()

func _active_locale_language() -> String:
	return _locale_language_override_for_testing if not _locale_language_override_for_testing.is_empty() else OS.get_locale_language().to_lower()

func _ready() -> void:
	_load_content()
	clock.time_changed.connect(_on_time_changed)
	clock.shift_time_reached.connect(_on_shift_time_reached)
	customers.customer_arrived.connect(_on_customer_arrived)
	customers.customer_left.connect(_on_customer_left)
	customers.customer_state_changed.connect(_on_customer_state_changed)
	story.journal_changed.connect(_emit_journal)
	quests.quest_changed.connect(_on_quest_changed)
	mysteries.clue_added.connect(_on_system_clue_added)
	world_map.location_unlocked.connect(_on_location_unlocked)
	world_map.location_changed.connect(_on_location_changed)
	shop_progression.progression_changed.connect(_sync_shop_location_unlocks)
	var saved := SaveScript.read_save()
	if not saved.is_empty():
		load_state(saved)
	if SaveScript.has_save_problem():
		save_recovery_required = true
		save_recovery_message = SaveScript.read_error()
		last_message = "The existing save could not be read and has been preserved. Choose the recovery option to archive it and start fresh."
	elif SaveScript.read_status() == "recovered_backup":
		save_recovered_from_backup = true
		last_message = "The primary save was unavailable. Moonmart restored the last-known-good backup."
	elif SaveScript.read_status() in ["recovered_temp", "recovered_stage", "recovered_copy"]:
		save_recovered_from_staging = true
		last_message = "Moonmart restored a verified interrupted save."
	_sync_shop_location_unlocks()
	_emit_journal()

func _process(delta: float) -> void:
	clock.tick(delta)
	var overnight_hour := clampi(floori((clock.prep_minutes + clock.elapsed_minutes) / 60.0) - 1, 0, 5)
	customers.tick(delta, clock.is_open() and shift_status == "open" and not clock.paused, overnight_hour)
	if shift_status == "open" and clock.is_open() and not clock.paused and not _pending_optional_events.is_empty():
		_optional_event_timer -= delta
		if _optional_event_timer <= 0.0:
			var event: Dictionary = _pending_optional_events.pop_front()
			_deliver_optional_event(event)
			_optional_event_timer = 72.0

func _deliver_optional_event(event: Dictionary) -> void:
	var event_id := String(event.get("id", ""))
	var definition: Dictionary = event_definitions.get(event_id, {})
	if String(definition.get("kind", "")) == "anomaly":
		_record_anomaly_disturbance(event_id)
	var event_message := String(event.get("message", definition.get("message", "The shop settles into a quiet moment.")))
	var localized_message := localize_ui("event.%s.message" % event_id, event_message)
	if _anomaly_investigation_available(event_id, definition):
		var prompt_id := String(definition.get("investigation_prompt_id", ""))
		if not prompt_id.is_empty():
			localized_message += "\n\n" + localize_ui(prompt_id, "The register may have more to tell you.")
	_set_message(localized_message)
	var festival_id := String(definition.get("festival_id", ""))
	if not festival_id.is_empty():
		calendar.mark_festival_attended(festival_id, shift_number)
		shop_progression.award_milestone("attended_bellwether_festival")
		shop_progression.award_harmony(2)
		_save()
	elif String(definition.get("kind", "")) == "anomaly":
		_save()

func _record_anomaly_disturbance(event_id: String) -> bool:
	if event_id.is_empty():
		return false
	var definition: Dictionary = event_definitions.get(event_id, {})
	if not String(definition.get("investigation_target", "")).is_empty() and resolved_anomaly_investigations.has(event_id):
		return false
	for disturbance in anomaly_disturbances:
		if String(disturbance.get("event_id", "")) == event_id:
			return false
	anomaly_disturbances.append({"event_id":event_id, "shift_number":shift_number})
	return true

func _oldest_anomaly_disturbance() -> Dictionary:
	return anomaly_disturbances[0].duplicate(true) if not anomaly_disturbances.is_empty() else {}

func _anomaly_investigation_available(event_id: String, definition: Dictionary) -> bool:
	return String(definition.get("kind", "")) == "anomaly" and not String(definition.get("investigation_target", "")).is_empty() and not resolved_anomaly_investigations.has(event_id)

func investigate_optional_anomaly(target_id: String) -> Dictionary:
	for index in range(anomaly_disturbances.size()):
		var event_id := String(anomaly_disturbances[index].get("event_id", ""))
		var definition: Dictionary = event_definitions.get(event_id, {})
		if String(definition.get("investigation_target", "")) != target_id or resolved_anomaly_investigations.has(event_id):
			continue
		var result_id := String(definition.get("investigation_result_id", ""))
		if result_id.is_empty():
			continue
		var reward: Dictionary = definition.get("investigation_reward", {})
		var reward_amount := maxi(0, int(reward.get("amount", 0)))
		var currency := String(reward.get("currency", ""))
		if currency == "moon_tokens" and reward_amount > 0:
			inventory.moon_tokens += reward_amount
			inventory.record_transaction({"reason":"optional_anomaly_investigation", "event_id":event_id, "currency":currency, "quantity":reward_amount})
		resolved_anomaly_investigations.append(event_id)
		anomaly_disturbances.remove_at(index)
		shop_progression.award_milestone("resolved_optional_anomaly")
		money_changed.emit(inventory.coins, inventory.moon_tokens)
		var reward_label := ""
		if reward_amount > 0:
			reward_label = localize_ui("currency.moon_tokens", "Moon Tokens")
		var message := localize_ui(result_id, "The receipt reveals a small forgotten name. You found {amount} {currency}.").format({"amount":str(reward_amount), "currency":reward_label})
		_save()
		return {"ok":true, "event_id":event_id, "reward_amount":reward_amount, "currency":currency, "message":message}
	return {"ok":false, "reason":"no_investigable_anomaly"}

func _load_content() -> void:
	var product_rows: Array = _read_json(PRODUCTS_PATH, {}).get("products", [])
	var character_rows: Array = _read_json(CHARACTERS_PATH, {}).get("characters", [])
	var ordinary_customer_rows: Array = _read_json(ORDINARY_CUSTOMERS_PATH, {}).get("ordinary_customers", [])
	var recipe_rows: Array = _read_json(RECIPES_PATH, {}).get("recipes", [])
	var event_rows: Array = _read_json(EVENTS_PATH, {}).get("events", [])
	var story_rows: Array = _read_json(QUESTS_PATH, {}).get("story_events", [])
	var clue_rows: Array = _read_json(CLUES_PATH, {}).get("clues", [])
	var investigation_rows: Array = _read_json(INVESTIGATIONS_PATH, {}).get("investigations", [])
	var location_rows: Array = _read_json(LOCATIONS_PATH, {}).get("locations", [])
	var furniture_rows: Array = _read_json(FURNITURE_PATH, {}).get("furniture", [])
	var calendar_config := _read_json(CALENDAR_PATH, {})
	var shop_progression_config := _read_json(SHOP_PROGRESSION_PATH, {})
	var miso_companion_config := _read_json(MISO_COMPANION_PATH, {})
	miso_memory_echo_fragments.clear()
	for fragment in miso_companion_config.get("memory_echoes", []):
		if fragment is Dictionary and not String(fragment.get("id", "")).is_empty():
			miso_memory_echo_fragments.append(fragment.duplicate(true))
	var environmental_puzzle_rows: Array = _read_json(ENVIRONMENTAL_PUZZLES_PATH, {}).get("puzzles", [])
	var collectible_rows: Array = _read_json(COLLECTIBLES_PATH, {}).get("collectibles", [])
	collectible_definitions.clear()
	for collectible in collectible_rows:
		if not collectible is Dictionary:
			continue
		var collectible_id := String(collectible.get("id", ""))
		if collectible_id.is_empty() or String(collectible.get("location_id", "")).is_empty() or String(collectible.get("target_id", "")).is_empty():
			continue
		collectible_definitions[collectible_id] = collectible.duplicate(true)
	var timing_balance := _read_json(TIMING_PATH, {})
	clock.configure(timing_balance)
	minimum_service_minutes = maxf(0.0, float(timing_balance.get("initial_service_minutes", 60.0)))
	calendar.setup(calendar_config)
	shop_progression.setup(shop_progression_config)
	miso_companion.setup(miso_companion_config)
	miso_dream_sequence.setup(miso_companion_config.get("dream_sequence", {}))
	environmental_puzzles.setup(environmental_puzzle_rows)
	_dialogue = _load_dialogue_catalog()
	_ui_translations = _load_ui_catalog()
	story.ui_text_lookup = Callable(self, "localize_ui")
	mysteries.ui_text_lookup = Callable(self, "localize_ui")
	if product_rows.is_empty():
		product_rows = _fallback_products()
	if character_rows.is_empty():
		character_rows = _fallback_characters()
	inventory.setup(product_rows)
	customers.setup(character_rows, ordinary_customer_rows)
	recipes.clear()
	discovered_recipe_ids.clear()
	for recipe in recipe_rows:
		if recipe is Dictionary and recipe.has("id"):
			var recipe_id := String(recipe.id)
			recipes[recipe_id] = recipe.duplicate(true)
			if String(recipe.get("discovery", "known")) == "known" and not discovered_recipe_ids.has(recipe_id):
				discovered_recipe_ids.append(recipe_id)
	var essential_quest_rows: Array[Dictionary] = []
	for story_event in story_rows:
		if not story_event is Dictionary or not story_event.has("id"):
			continue
		var row: Dictionary = story_event.duplicate(true)
		row["essential"] = true
		row["visitor_id"] = String(row.get("visitor", ""))
		row["sets_flags"] = [String(row.id)]
		row["trigger"] = {}
		essential_quest_rows.append(row)
	quests.setup(essential_quest_rows, story.flags)
	var normalized_clues: Array[Dictionary] = []
	for clue in clue_rows:
		if not clue is Dictionary:
			continue
		var row: Dictionary = clue.duplicate(true)
		row["title"] = String(row.get("text", row.get("id", "Clue")))
		normalized_clues.append(row)
	var normalized_investigations: Array[Dictionary] = []
	for case_data in investigation_rows:
		if not case_data is Dictionary:
			continue
		var row: Dictionary = case_data.duplicate(true)
		var solutions: Array[Dictionary] = []
		for hypothesis in row.get("hypotheses", []):
			solutions.append({"id": hypothesis.get("id", ""), "text": hypothesis.get("text", ""), "all_of": hypothesis.get("required_clues", []), "conclusion": hypothesis.get("response", ""), "sets_flags": [hypothesis.get("result_flag", "")]})
		row["solutions"] = solutions
		normalized_investigations.append(row)
	mysteries.setup(normalized_clues, normalized_investigations, story.flags)
	var normalized_locations: Array[Dictionary] = []
	for location in location_rows:
		if not location is Dictionary:
			continue
		var row: Dictionary = location.duplicate(true)
		row["essential"] = bool(row.get("essential", false))
		var unlock_flag := String(row.get("unlocks_flag", ""))
		row["requires_flags"] = [] if unlock_flag.is_empty() else [unlock_flag]
		normalized_locations.append(row)
	world_map.setup(normalized_locations, story.flags)
	for character in character_rows:
		if character is Dictionary:
			relationships.register_character(String(character.get("id", "")))
	decoration.setup(furniture_rows)
	var shop_access := {
		"spawn": Vector2i(12, 8), "exit": Vector2i(22, 6), "register": Vector2i(17, 7),
		"shelf": Vector2i(3, 5), "fridge": Vector2i(7, 5), "coffee_machine": Vector2i(9, 7),
		"tea_counter": Vector2i(11, 7), "kettle": Vector2i(13, 7), "microwave": Vector2i(15, 7),
		"sandwich_station": Vector2i(17, 8), "bakery_warmer": Vector2i(19, 7),
		"journal": Vector2i(20, 5), "back_door": Vector2i(22, 3),
		"miso": Vector2i(20, 7), "cat_bed": Vector2i(21, 9)
	}
	for access_id in shop_access:
		decoration.set_access_point(String(access_id), shop_access[access_id])
	var normalized_events: Array[Dictionary] = []
	for event in event_rows:
		if not event is Dictionary:
			continue
		var row: Dictionary = event.duplicate(true)
		row["min_shift"] = int(row.get("minimum_shift", row.get("min_shift", 0)))
		event_definitions[String(row.get("id", ""))] = row
		normalized_events.append(row)
	event_director.setup(normalized_events)

func _read_json(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback

func _load_dialogue_catalog() -> Dictionary:
	var source_catalog := _read_json(DIALOGUE_PATH, {})
	var language := _active_locale_language()
	if language.is_empty() or language == "en" or language.length() > 3:
		return source_catalog
	for character in language:
		if not (character >= "a" and character <= "z"):
			return source_catalog
	var localized_path := "%s/%s/dialogue.json" % [LOCALIZED_DIALOGUE_DIR, language]
	var translated_catalog := _read_json(localized_path, {})
	if translated_catalog.is_empty():
		return source_catalog
	var merged: Variant = _merge_dialogue_translation(source_catalog, translated_catalog)
	return merged if merged is Dictionary else source_catalog

func localize_ui(key: String, fallback: String) -> String:
	var translated: Variant = _ui_translations.get(key, fallback)
	return String(translated) if translated is String and not String(translated).is_empty() else fallback

func _load_ui_catalog() -> Dictionary:
	var language := _active_locale_language()
	if language.is_empty() or language.length() > 3:
		return {}
	for character in language:
		if not (character >= "a" and character <= "z"):
			return {}
	var catalog := _read_json("%s/%s/ui.json" % [LOCALIZED_DIALOGUE_DIR, language], {})
	if int(catalog.get("schema_version", 0)) != 1:
		return {}
	var translated_strings: Variant = catalog.get("strings", {})
	if not translated_strings is Dictionary:
		return {}
	var valid_strings: Dictionary = {}
	for key in translated_strings:
		var value: Variant = translated_strings[key]
		if key is String and value is String and not String(value).is_empty():
			valid_strings[String(key)] = String(value)
	return valid_strings

func _merge_dialogue_translation(source_value: Variant, translated_value: Variant) -> Variant:
	if translated_value == null:
		return source_value
	if source_value is Dictionary:
		if not translated_value is Dictionary:
			return source_value
		var merged: Dictionary = source_value.duplicate(true)
		for key in translated_value:
			if merged.has(key):
				merged[key] = _merge_dialogue_translation(merged[key], translated_value[key])
			else:
				merged[key] = translated_value[key]
		return merged
	if source_value is Array:
		if not translated_value is Array:
			return source_value
		return translated_value.duplicate(true)
	if typeof(source_value) != typeof(translated_value):
		return source_value
	return translated_value

func begin_shift() -> void:
	if save_recovery_required:
		_set_message(localize_ui("save.recovery.begin_blocked", "The old save is preserved. Archive it before starting a fresh game."))
		return
	if shift_status == "open":
		return
	shift_number += 1
	shift_status = "open"
	miso_companion.begin_shift(shift_number)
	calendar.set_current_shift(shift_number)
	shift_start_revenue = inventory.revenue
	shift_start_coins_revenue = inventory.coins_revenue
	shift_start_moons_revenue = inventory.moon_tokens_revenue
	var essential_encounters: Array[Dictionary] = quests.begin_shift(shift_number, _story_context())
	story.queued_events.clear()
	_pending_events = _essential_event_projection(essential_encounters)
	_pending_optional_events = event_director.begin_shift(shift_number, _story_context(), 2)
	for optional_event in _pending_optional_events:
		var definition: Dictionary = event_definitions.get(String(optional_event.get("id", "")), {})
		optional_event["message"] = String(definition.get("message", "The shop settles into a quiet moment."))
	_optional_event_timer = 38.0
	var shift_context := _story_context()
	shift_context["chapter"] = story.chapter
	_cleaning_actions_this_shift.clear()
	customers.start_shift(shift_number, _pending_events, shift_context)
	clock.set_shift_profile(shift_number)
	clock.start()
	shift_changed.emit(shift_number, shift_status)
	_set_message(localize_ui("shift.message.begin", "Night {night} begins. The shop is open; take your time.").format({"night":str(shift_number)}))
	_save()

func _story_context() -> Dictionary:
	var date := calendar.date_for_shift(maxi(shift_number, 1))
	var stock_categories: Dictionary = {}
	var stocked_products: Dictionary = {}
	for product_id in inventory.products:
		var category := String(inventory.products[product_id].get("category", "everyday"))
		var quantity := inventory.available_on_shelf(String(product_id))
		if quantity > 0:
			stock_categories[category] = int(stock_categories.get(category, 0)) + quantity
			stocked_products[String(product_id)] = quantity
	var bond_levels: Dictionary = {}
	for character_id in story.relationships:
		bond_levels[String(character_id)] = relationships.stage(String(character_id))
	var ending_world := world_map.world_state()
	return {"shift": shift_number, "chapter": story.chapter, "day": String(date.get("weekday", "Monday")).to_lower(), "weather": calendar.weather_for_shift(maxi(shift_number, 1)), "season": String(date.get("season_id", "spring")), "season_day": int(date.get("season_day", 1)), "festival": calendar.festival_for_shift(maxi(shift_number, 1)), "flags": story.flags, "relationships": bond_levels, "stock_categories": stock_categories, "stock_products": stocked_products, "cleanliness": shop_progression.cleanliness, "reputation_tier": shop_progression.reputation_tier_index(), "harmony": shop_progression.harmony, "enchanted_lighting": shop_progression.has_upgrade("enchanted_lighting"), "reading_nook": shop_progression.has_upgrade("reading_nook"), "decoration_effects": decoration.active_effects(), "ending_id": world_map.ending_id, "world_state_id": world_map.ending_world_state_id(), "door_open": bool(ending_world.get("door_open", true)), "community_mixed": bool(ending_world.get("community_mixed", false))}

func can_close_shift() -> Dictionary:
	if shift_status != "open" or not clock.running:
		return {"ok":false, "reason":"shift_not_open"}
	var service_minutes := maxf(0.0, clock.elapsed_minutes - clock.prep_minutes)
	var remaining := maxf(0.0, minimum_service_minutes - service_minutes)
	if remaining > 0.0:
		return {"ok":false, "reason":"minimum_service_period", "remaining_minutes":ceili(remaining), "served_minutes":floori(service_minutes), "minimum_minutes":ceili(minimum_service_minutes)}
	return {"ok":true, "served_minutes":floori(service_minutes)}

func close_shift() -> Dictionary:
	var verdict := can_close_shift()
	if not bool(verdict.get("ok", false)):
		if verdict.get("reason", "") == "minimum_service_period":
			_set_message(localize_ui("shift.message.minimum_service", "Moonmart's promise asks for {minimum} minutes of open service first. {remaining} minute{plural} remain; unfinished stories will wait safely for another night.").format({"minimum":str(verdict.get("minimum_minutes", 60)), "remaining":str(verdict.get("remaining_minutes", 0)), "plural":"s" if int(verdict.get("remaining_minutes", 0)) != 1 else ""}))
		return verdict
	clock.close_early()
	return verdict

func set_paused(value: bool) -> void:
	clock.paused = value

func set_game_speed(multiplier: float) -> void:
	clock.speed_multiplier = clampf(multiplier, 0.25, 3.0)

func interact(target_id: String, secondary: bool = false) -> void:
	if secondary:
		_set_message(inspect_object(target_id))
		return
	if not customers.get_customer(target_id).is_empty():
		var paired_result := try_paired_conversation(target_id)
		if bool(paired_result.get("ok", false)):
			return
		customers.begin_conversation(target_id)
	var conversation_keys := {"agnes":"agnes_first", "pip":"pip_tuesday", "fern":"fern_grove", "lucien":"lucien_ada", "wren":"wren_sister", "conductor":"conductor_names", "elias":"elias_light", "mara":"mara_letters", "osric":"osric_name"}
	if conversation_keys.has(target_id):
		_set_message(talk_to_character(target_id, _conversation_for_character(target_id, String(conversation_keys[target_id]))))
		return
	# Named visitors without a dedicated opening conversation (Miriam, Hollis, Stellan, ...) still follow their authored storyline route.
	if _dialogue.get("conversation_routes", {}).has(target_id) and not customers.get_customer(target_id).is_empty():
		_set_message(talk_to_character(target_id, _conversation_for_character(target_id, "")))
		return
	match target_id:
		"register":
			if customers.active.is_empty():
				var investigation := investigate_optional_anomaly("register")
				if bool(investigation.get("ok", false)):
					_set_message(String(investigation.get("message", "The receipt settles quietly.")))
				else:
					_set_message(localize_ui("interaction.register.ready", "The register is ready. A little bell waits beside it."))
			else:
				checkout(String(customers.active[0].id))
		"shelf", "fridge":
			_set_message(_stock_message(target_id))
		"miso":
			var care_result := companion_action("pet")
			_set_message(localize_ui("companion.response.pet", String(care_result.get("message", "Miso blinks sleepily."))) if care_result.get("ok", false) else localize_ui("companion.result.already_done", "Miso has already had a little attention of that kind tonight."))
		"journal":
			_emit_journal()
		"old_grove", "tide_pool", "platform", "shop_ledger", "keeper_log", "town_map", "town_archive", "town_ledger", "passenger_manifest", "lucien_book", "post_box", "post_office", "photograph", "ticket_window", "platform_clock", "coast_view", "fresnel_lens", "lamp_room", "washed_glass", "net_mender", "empty_boat":
			_set_message(inspect_object(target_id))
		"backroom", "back_door":
			if story.flags.get("pip_first_memory", false):
				_set_message(inspect_object("back_door"))
			else:
				_set_message(localize_ui("interaction.backroom.not_ready", "The back room is still being tidied. Miso watches the doorway."))
		"window":
			_set_message(inspect_object("window"))
		"cat_bed":
			_set_message(localize_ui("interaction.cat_bed", "Miso curls up beneath the warm lamp, paws tucked in."))
		"waiting_bench":
			_set_message(localize_ui("interaction.waiting_bench", "The bench has room for two. You rest for a moment; the station clock waits with you."))
		_:
			_set_message(localize_ui("interaction.shop_quiet", "The shop hums softly around you."))

func finish_customer_conversation() -> void:
	for customer in customers.active:
		if String(customer.get("state", "")) == "CONVERSING":
			customers.finish_conversation(String(customer.get("id", "")))
			break

func talk_to_character(character_id: String, conversation_id: String) -> String:
	var conversation: Dictionary = _dialogue.get("conversations", {}).get(conversation_id, {})
	var lines: Array = conversation.get("lines", [])
	var active_customer := customers.get_customer(character_id)
	var customer_name := String(active_customer.get("name", customers.definitions.get(character_id, {}).get("name", character_id.capitalize())))
	if lines.is_empty():
		var ordinary := String(_dialogue.get("ordinary_lines", {}).get(character_id, _dialogue.get("default_ordinary_line", "%s thanks you.")))
		return ordinary if not ordinary.contains("%s") else ordinary % customer_name
	var turn := int(_conversation_turns.get(conversation_id, 0))
	if turn >= lines.size():
		var repeat_line := String(_dialogue.get("ordinary_lines", {}).get(character_id, "%s smiles beneath the warm shop lights."))
		return repeat_line if not repeat_line.contains("%s") else repeat_line % customer_name
	_conversation_turns[conversation_id] = turn + 1
	if turn == 0:
		story.record_memory(character_id, "conversation_" + conversation_id, String(lines[turn]), "listening")
		relationships.record_memory(character_id, "conversation_" + conversation_id, ["listening"])
		story.set_relationship_stage(character_id, relationships.stage(character_id))
		shop_progression.award_milestone("meaningful_conversation")
		shop_progression.award_proficiency("hospitality", 1)
		_emit_journal()
	_save()
	return "%s\n\n%s" % [conversation.get("speaker", character_id.capitalize()), String(lines[turn])]

func try_paired_conversation(target_id: String) -> Dictionary:
	if world_map.current_location != "moonmart":
		return {"ok":false, "reason":"not_in_shop"}
	var paired_catalog: Dictionary = _dialogue.get("paired_conversations", {})
	for pair_id_value in paired_catalog:
		var pair_id := String(pair_id_value)
		var pair: Variant = paired_catalog[pair_id_value]
		if not pair is Dictionary:
			continue
		var pair_data: Dictionary = pair
		var participants: Array = pair_data.get("participants", [])
		if participants.size() < 2 or not participants.has(target_id):
			continue
		var eligible := true
		for participant_value in participants:
			var participant_id := String(participant_value)
			var participant := customers.get_customer(participant_id)
			if participant.is_empty() or bool(participant.get("essential", false)) or not ["BROWSING", "LINGERING"].has(String(participant.get("state", ""))):
				eligible = false
				break
		if not eligible:
			continue
		var lines: Array = pair_data.get("lines", [])
		if lines.is_empty():
			continue
		var state_key := "paired_conversation:%s" % pair_id
		var pair_state: Dictionary = _conversation_turns.get(state_key, {})
		var cooldown_shifts := maxi(0, int(pair_data.get("cooldown_hint_shifts", 0)))
		var last_shift := int(pair_state.get("last_shift", -100000))
		if shift_number - last_shift < cooldown_shifts:
			return {"ok":false, "reason":"cooldown"}
		var turn := posmod(int(pair_state.get("turn", 0)), lines.size())
		var line_value: Variant = lines[turn]
		if not line_value is Dictionary:
			return {"ok":false, "reason":"invalid_line"}
		var line: Dictionary = line_value
		var speaker := String(line.get("speaker", target_id.capitalize()))
		var text := String(line.get("text", ""))
		if text.is_empty():
			return {"ok":false, "reason":"empty_line"}
		if not customers.begin_conversation(target_id):
			return {"ok":false, "reason":"visitor_unavailable"}
		_conversation_turns[state_key] = {"turn":turn + 1, "last_shift":shift_number}
		var message := "%s\n\n%s" % [speaker, text]
		_set_message(message)
		_save()
		return {"ok":true, "pair_id":pair_id, "turn":turn, "speaker":speaker, "text":text, "message":message}
	return {"ok":false, "reason":"no_eligible_pair"}

func _conversation_for_character(character_id: String, fallback_id: String) -> String:
	var route: Dictionary = _dialogue.get("conversation_routes", {}).get(character_id, {})
	var variants: Array = route.get("variants", [])
	for variant_value in variants:
		if not variant_value is Dictionary:
			continue
		var variant: Dictionary = variant_value
		var required_flags: Array = variant.get("requires_flags", [])
		var eligible := true
		for flag_value in required_flags:
			if not bool(story.flags.get(String(flag_value), false)):
				eligible = false
				break
		if not eligible:
			continue
		var required_stocked_products: Array = variant.get("requires_stocked_products", [])
		for product_value in required_stocked_products:
			if inventory.available_on_shelf(String(product_value)) <= 0:
				eligible = false
				break
		if not eligible:
			continue
		var conversation_id := String(variant.get("conversation_id", ""))
		var conversation: Dictionary = _dialogue.get("conversations", {}).get(conversation_id, {})
		var lines: Array = conversation.get("lines", [])
		if not lines.is_empty() and int(_conversation_turns.get(conversation_id, 0)) < lines.size():
			return conversation_id
	return fallback_id

func companion_action(action_id: String, toy_id: String = "") -> Dictionary:
	var result: Dictionary = miso_companion.interact(action_id, shift_number, toy_id)
	if bool(result.get("ok", false)):
		if action_id == "pet":
			story.flags["miso_petted"] = true
			world_map.set_story_flag("miso_petted", true)
		shop_progression.award_proficiency("attunement", 1)
		_save()
	return result

func use_miso_ability(ability_id: String, reachable_inspect_targets: Dictionary = {}) -> Dictionary:
	var context: Dictionary = {}
	var guidance: Dictionary = {}
	if ability_id == "spirit_sense":
		for customer in customers.active:
			var definition: Dictionary = customers.definitions.get(String(customer.get("id", "")), {})
			if "supernatural" in definition.get("tags", []):
				context["visitor"] = String(customer.get("name", customer.get("id", "someone")))
				break
	if ability_id == "hidden_paw":
		if not miso_companion.ability_available(ability_id):
			return miso_companion.use_ability(ability_id, shift_number, context)
		if not miso_hidden_paw_guidance.is_empty():
			return {"ok":false, "reason":"guidance_active"}
		guidance = _next_overlooked_clue(reachable_inspect_targets)
		if guidance.is_empty():
			return {"ok":false, "reason":"no_reachable_clue"}
		context["overlooked_clue_id"] = String(guidance.get("clue_id", ""))
	if ability_id == "memory_echo":
		if not miso_companion.ability_available("memory_echo"):
			return miso_companion.use_ability(ability_id, shift_number, context)
		var memory_echo: Dictionary = _next_miso_memory_echo()
		if memory_echo.is_empty():
			return {"ok":false, "reason":"nothing_to_echo"}
		context["memory_echo"] = memory_echo
	if ability_id == "guardian_purr":
		if not miso_companion.ability_available("guardian_purr"):
			return miso_companion.use_ability(ability_id, shift_number, context)
		var disturbance := _oldest_anomaly_disturbance()
		if disturbance.is_empty():
			return {"ok":false, "reason":"no_active_anomaly"}
		context["disturbance"] = disturbance
	var result: Dictionary = miso_companion.use_ability(ability_id, shift_number, context)
	if not bool(result.get("ok", false)):
		return result
	if ability_id == "hidden_paw":
		var clue_id := String(result.get("clue_id", ""))
		if not clue_id.is_empty():
			var clue: Dictionary = story.clue_definitions.get(clue_id, {})
			miso_hidden_paw_guidance = {
				"clue_id": clue_id,
				"target_id": String(guidance.get("target_id", clue.get("target", ""))),
				"marker_id": String(guidance.get("marker_id", "")),
				"location_id": world_map.current_location
			}
			result["target_id"] = String(miso_hidden_paw_guidance.target_id)
			result["marker_id"] = String(miso_hidden_paw_guidance.marker_id)
			result["message"] = "Miso pads toward a detail you might have missed."
	elif ability_id == "spirit_sense":
		if context.has("visitor"):
			result["message"] = "Miso's ears turn toward %s. The cat senses a visitor from the Between." % context.visitor
		else:
			result["message"] = "Miso listens around the shop. No hidden visitor is near just now."
	elif ability_id == "guardian_purr":
		var disturbance: Dictionary = context.get("disturbance", {})
		var anomaly_id := String(disturbance.get("event_id", ""))
		for index in range(anomaly_disturbances.size()):
			if String(anomaly_disturbances[index].get("event_id", "")) == anomaly_id:
				anomaly_disturbances.remove_at(index)
				break
		result["stabilized_anomaly_id"] = anomaly_id
		result["stabilized_anomaly_message_id"] = "event.%s.message" % anomaly_id
		shop_progression.award_harmony(2)
	elif ability_id == "memory_echo":
		var memory_echo: Dictionary = context.get("memory_echo", {})
		var memory_echo_id := String(memory_echo.get("id", ""))
		var memory_echo_flag := _miso_memory_echo_flag(memory_echo_id)
		story.flags[memory_echo_flag] = true
		result["memory_echo_id"] = memory_echo_id
		result["memory_echo_title_id"] = String(memory_echo.get("title_id", ""))
		result["memory_echo_text_id"] = String(memory_echo.get("text_id", ""))
		_emit_journal()
	_save()
	return result

func _miso_memory_echo_flag(memory_echo_id: String) -> String:
	return "miso_memory_echo_%s" % memory_echo_id

func _next_miso_memory_echo() -> Dictionary:
	for memory_echo in miso_memory_echo_fragments:
		var memory_echo_id := String(memory_echo.get("id", ""))
		if memory_echo_id.is_empty() or bool(story.flags.get(_miso_memory_echo_flag(memory_echo_id), false)):
			continue
		var requirements_met := true
		for flag_id in memory_echo.get("requires_flags", []):
			if not bool(story.flags.get(String(flag_id), false)):
				requirements_met = false
				break
		if requirements_met:
			return memory_echo.duplicate(true)
	return {}

func start_miso_dreamwalking() -> Dictionary:
	if miso_dream_sequence.active:
		return {"ok":true, "resumed":true, "beat":miso_dream_sequence.current_beat()}
	if not miso_companion.ability_available("dreamwalking"):
		return {"ok":false, "reason":"locked"}
	var ability_result: Dictionary = miso_companion.use_ability("dreamwalking", shift_number)
	if not bool(ability_result.get("ok", false)):
		return ability_result
	var result: Dictionary = miso_dream_sequence.start()
	if not bool(result.get("ok", false)):
		return result
	_save()
	return result

func choose_miso_dream_choice(choice_id: String) -> Dictionary:
	var result: Dictionary = miso_dream_sequence.choose(choice_id)
	if bool(result.get("ok", false)):
		_save()
	return result

func wake_from_miso_dream() -> Dictionary:
	var result: Dictionary = miso_dream_sequence.wake()
	if not bool(result.get("ok", false)):
		return result
	var memory_id := String(result.get("memory_id", ""))
	story.flags["miso_dreamwalking_complete"] = true
	if not memory_id.is_empty():
		story.flags["miso_dream_memory"] = memory_id
	world_map.set_story_flag("miso_dreamwalking_complete", true)
	_emit_journal()
	_save()
	return result

func _next_overlooked_clue(reachable_inspect_targets: Dictionary) -> Dictionary:
	for clue_id in story.clue_definitions:
		var clue: Dictionary = story.clue_definitions[clue_id]
		if bool(clue.get("hidden_perception", false)) or story.clues.has(String(clue_id)) or int(clue.get("chapter", 1)) > story.chapter:
			continue
		var target_id := String(clue.get("target", ""))
		if target_id.is_empty() or not reachable_inspect_targets.has(target_id):
			continue
		var ready := true
		for flag_id in clue.get("requires_flags", []):
			if not bool(story.flags.get(String(flag_id), false)):
				ready = false
				break
		if ready:
			return {"clue_id":String(clue_id), "target_id":target_id, "marker_id":String(reachable_inspect_targets[target_id])}
	return {}

func cycle_miso_sleep_spot() -> String:
	var spots: Array = miso_companion.sleep_spots.keys()
	if spots.is_empty():
		return "Miso stays curled up in the familiar bed."
	var current_index := spots.find(miso_companion.preferred_sleep_spot)
	var next_spot := String(spots[posmod(current_index + 1, spots.size())])
	miso_companion.choose_sleep_spot(next_spot)
	_save()
	return String(miso_companion.sleep_spots[next_spot].get("response", "Miso settles in a new spot."))

func inspect_object(target_id: String) -> String:
	var old_clue_count: int = story.clues.size()
	var result := story.inspect(target_id, shift_number)
	if not miso_hidden_paw_guidance.is_empty() and String(miso_hidden_paw_guidance.get("target_id", "")) == target_id:
		if story.clues.has(String(miso_hidden_paw_guidance.get("clue_id", ""))):
			miso_hidden_paw_guidance.clear()
	# The Conductor can advance these story milestones at checkout, but an
	# ending memory about the station requires inspections made there in person.
	if world_map.current_location == "midnight_platform":
		if target_id == "platform":
			story.flags["midnight_platform_visited"] = true
		elif target_id == "passenger_manifest":
			story.flags["midnight_manifest_read"] = true
	miso_companion.sync_story_flags(story.flags)
	if result.begins_with("Nothing unusual") and miso_companion.ability_available("moonlight_perception"):
		for clue_id in story.clue_definitions:
			var hidden_clue: Dictionary = story.clue_definitions[clue_id]
			if not bool(hidden_clue.get("hidden_perception", false)) or String(hidden_clue.get("target", "")) != target_id or story.clues.has(String(clue_id)):
				continue
			if int(hidden_clue.get("chapter", 1)) > story.chapter:
				continue
			var requirements_met := true
			for required_flag in hidden_clue.get("requires_flags", []):
				if not bool(story.flags.get(String(required_flag), false)):
					requirements_met = false
					break
			if requirements_met:
				story._add_clue(String(clue_id))
				var grants_flag := String(hidden_clue.get("grants_flag", ""))
				if not grants_flag.is_empty():
					story.flags[grants_flag] = true
					world_map.set_story_flag(grants_flag, true)
				result = String(hidden_clue.get("text", "The moonlight reveals a trace of old writing."))
				break
	for index in range(old_clue_count, story.clues.size()):
		var clue_id: String = String(story.clues[index])
		mysteries.add_clue(clue_id)
		shop_progression.award_milestone("noticed_first_clue")
		shop_progression.award_proficiency("observation", 1)
		shop_progression.award_harmony(1)
		if clue_id == "door_in_the_wall":
			shop_progression.award_milestone("found_hidden_detail")
	if story.clues.size() > old_clue_count:
		var discovered_clue_id := String(story.clues[story.clues.size() - 1])
		result = localize_ui("clue.%s.text" % discovered_clue_id, result)
	elif result.begins_with("Nothing unusual"):
		result = localize_ui("interaction.inspect.nothing_unusual", result)
	var collectible := discover_collectible(world_map.current_location, target_id)
	if not collectible.is_empty():
		var collectible_message := localize_ui("collectible.found", "You found {name}.")
		var collectible_name := localize_ui("collectible.%s.name" % String(collectible.get("id", "")), String(collectible.get("name", "a small keepsake")))
		result += "\n\n" + collectible_message.format({"name":collectible_name})
		_emit_journal()
	for flag_id in story.flags:
		if bool(story.flags[flag_id]) and not bool(world_map.flags.get(flag_id, false)):
			world_map.set_story_flag(String(flag_id), true)
		if bool(story.flags[flag_id]) and not bool(quests.flags.get(flag_id, false)):
			quests.flags[String(flag_id)] = true
	_save()
	return result

## Discovers at most one authored keepsake for the exact location and inspect
## target. Returns its catalog definition on first discovery and an empty
## dictionary on repeat inspections or non-collectible targets.
func discover_collectible(location_id: String, target_id: String) -> Dictionary:
	for collectible_id in collectible_definitions:
		var definition: Dictionary = collectible_definitions[collectible_id]
		if String(definition.get("location_id", "")) != location_id or String(definition.get("target_id", "")) != target_id:
			continue
		if discovered_collectibles.has(String(collectible_id)):
			return {}
		discovered_collectibles.append(String(collectible_id))
		shop_progression.award_milestone("found_first_keepsake")
		return definition.duplicate(true)
	return {}

## Reads an authored message from a placed decoration at most once per save.
## The display layer identifies the instance and presents the returned text.
func read_placed_decoration_message(instance_id: String) -> String:
	var effect := decoration.effect_for_instance(instance_id, "moon_jasmine_message")
	if effect.is_empty():
		return ""
	var save_flag := String(effect.get("save_flag", "decoration_message_moon_jasmine_read"))
	var message_id := String(effect.get("message_id", "decoration.message.moon_jasmine"))
	var repeat_message_id := String(effect.get("repeat_message_id", "decoration.message.moon_jasmine_repeat"))
	if bool(story.flags.get(save_flag, false)):
		return localize_ui(repeat_message_id, "The moon jasmine has already shared its small message. Its petals rest quietly.")
	story.flags[save_flag] = true
	_save()
	return localize_ui(message_id, "Moon jasmine petals tilt toward the window. Silver veins form a tiny line: Even a quiet light can help someone find the way home.")

func environmental_puzzle_for_target(target_id: String) -> Dictionary:
	for puzzle in environmental_puzzles.visible_puzzles(story.flags):
		if String(puzzle.get("target", "")) == target_id:
			return puzzle
	return {}

func submit_environmental_puzzle(puzzle_id: String, answer: String) -> Dictionary:
	var result: Dictionary = environmental_puzzles.submit_answer(puzzle_id, answer, story.flags)
	if not bool(result.get("ok", false)):
		if String(result.get("reason", "")) == "try_again":
			_save()
		return result
	if bool(result.get("already_solved", false)):
		return result
	shop_progression.award_milestone("solved_environmental_puzzle")
	for flag_id in result.get("grants_flags", []):
		var flag := String(flag_id)
		story.flags[flag] = true
		quests.flags[flag] = true
		mysteries.flags[flag] = true
		world_map.set_story_flag(flag, true)
	for clue_id in result.get("reveals_clues", []):
		var clue := String(clue_id)
		if not story.clues.has(clue):
			story._add_clue(clue)
			shop_progression.award_milestone("noticed_first_clue")
			shop_progression.award_proficiency("observation", 1)
			shop_progression.award_harmony(1)
		mysteries.add_clue(clue)
	quests._refresh_locked_quests()
	miso_companion.sync_story_flags(story.flags)
	var reward_text := String(result.get("reward_text", ""))
	environmental_puzzle_completed.emit(puzzle_id, reward_text)
	_emit_journal()
	_save()
	return result

func checkout_recommendation(customer_id: String) -> Dictionary:
	var customer := customers.get_customer(customer_id)
	if customer.is_empty():
		return {}
	var definition: Dictionary = customers.definitions.get(customer_id, {})
	var favorites: Array = customer.get("seasonal_favourite_products", []).duplicate()
	favorites.append_array(definition.get("favourite_products", definition.get("favorite_products", [])))
	var basket: Dictionary = customer.get("basket", {})
	for favorite_value in favorites:
		var product_id := String(favorite_value)
		if product_id.is_empty() or basket.has(product_id) or not inventory.products.has(product_id):
			continue
		if inventory.available_on_shelf(product_id) > 0:
			return {"product_id":product_id, "count":1}
	return {}

func checkout_recommendation_is_valid(customer_id: String, recommended_items: Dictionary) -> bool:
	if recommended_items.is_empty():
		return true
	if recommended_items.size() != 1:
		return false
	var offer := checkout_recommendation(customer_id)
	if offer.is_empty():
		return false
	var product_id := String(offer.get("product_id", ""))
	return recommended_items.has(product_id) and int(recommended_items[product_id]) == int(offer.get("count", 0))

func checkout(customer_id: String, packing_choice: String = "", payment_tender: String = "cash", recommended_items: Dictionary = {}) -> bool:
	var customer := customers.get_customer(customer_id)
	if customer.is_empty():
		_set_message(localize_ui("checkout.message.no_customer", "There's nobody waiting at the counter."))
		return false
	if not checkout_recommendation_is_valid(customer_id, recommended_items):
		_set_message(localize_ui("checkout.message.receipt_mismatch", "The receipt does not match the basket yet. Take another careful look."))
		return false
	var sale_basket: Dictionary = customer.get("basket", {}).duplicate(true)
	for product_id in recommended_items:
		sale_basket[String(product_id)] = int(sale_basket.get(String(product_id), 0)) + int(recommended_items[product_id])
	var payment_currency := String(customer.get("payment_currency", "coins"))
	var settled_tender := "moon_tokens" if payment_currency == "moon_tokens" else payment_tender
	var sale: Dictionary = inventory.sell(sale_basket, payment_currency, "", settled_tender)
	if not sale.get("ok", false):
		var essential_story_line := _resolve_essential_story_for_visitor(customer_id, customer)
		if not essential_story_line.is_empty():
			_set_message(localize_ui("checkout.message.stock_short_story", "{story_line}\n\nNo sale was made. {name} is happy to wait while you restock.").format({"story_line":essential_story_line, "name":String(customer.get("name", "The visitor"))}))
			_save()
		else:
			_set_message(localize_ui("checkout.message.stock_short", "You check the basket: something needs restocking. The customer smiles and waits."))
		return false
	# Patient service remains the baseline; prompt checkout adds a modest optional
	# bonus without making regular visitors or story progression missable.
	var service_bonus := 1 if not bool(customer.get("essential", false)) and bool(customer.get("service_bonus_eligible", true)) else 0
	shop_progression.award_reputation(3 + service_bonus)
	shop_progression.award_proficiency("hospitality", 1)
	var packing_preference := String(customer.get("packing_preference", "paper"))
	if packing_choice in ["paper", "careful", "reusable"] and packing_choice == packing_preference:
		# Matching a stated preference is a small optional service flourish.
		# Any other valid choice (or a legacy direct checkout) still completes
		# the exact same sale without a penalty.
		shop_progression.award_proficiency("hospitality", 1)
		shop_progression.award_milestone("honoured_packing_preference")
	if not recommended_items.is_empty():
		# The player earns this small optional flourish only when the suggested
		# favorite is actually included in the completed sale.
		shop_progression.award_proficiency("hospitality", 1)
		shop_progression.award_milestone("completed_favourite_recommendation")
	shop_progression.award_milestone("first_friendly_checkout")
	if int(customer.get("visit_count", 0)) > 0:
		shop_progression.award_milestone("remembered_regular_order")
	if String(sale.get("currency", "coins")) == "moon_tokens":
		shop_progression.award_harmony(1)
	var served_midnight_drink := false
	for product_id in sale.get("basket", {}):
		var product: Dictionary = inventory.products.get(String(product_id), {})
		if "midnight_drink" in product.get("tags", []):
			served_midnight_drink = true
			break
	if served_midnight_drink:
		shop_progression.award_milestone("served_midnight_drink")
	var saved_marked_down_perishable := false
	for product_id in sale.get("basket", {}):
		var product_key := String(product_id)
		var product: Dictionary = inventory.products.get(product_key, {})
		if inventory.price_modifiers.has(product_key) and int(product.get("shelf_life_shifts", -1)) >= 0:
			saved_marked_down_perishable = true
			break
	if saved_marked_down_perishable:
		shop_progression.award_milestone("saved_marked_down_perishables")
	var name := String(customer.get("name", "Customer"))
	var essential_story_line := _resolve_essential_story_for_visitor(customer_id, customer)
	if not essential_story_line.is_empty():
		_set_message(essential_story_line)
	else:
		_set_message(_customer_line(customer_id, name))
	sale_completed.emit(name, int(sale.total), String(sale.get("currency", "coins")))
	customers.complete_visit(customer_id)
	money_changed.emit(inventory.coins, inventory.moon_tokens)
	_emit_journal()
	_save()
	return true

func checkout_scanned(customer_id: String, scanned_items: Dictionary, packing_choice: String = "", payment_tender: String = "cash", recommended_items: Dictionary = {}) -> bool:
	var customer := customers.get_customer(customer_id)
	if customer.is_empty():
		_set_message(localize_ui("checkout.message.customer_left", "The customer has stepped away from the counter."))
		return false
	if not checkout_recommendation_is_valid(customer_id, recommended_items):
		_set_message(localize_ui("checkout.message.receipt_mismatch", "The receipt does not match the basket yet. Take another careful look."))
		return false
	var basket: Dictionary = customer.get("basket", {}).duplicate(true)
	for product_id in recommended_items:
		basket[String(product_id)] = int(basket.get(String(product_id), 0)) + int(recommended_items[product_id])
	if basket != scanned_items:
		_set_message(localize_ui("checkout.message.receipt_mismatch", "The receipt does not match the basket yet. Take another careful look."))
		return false
	return checkout(customer_id, packing_choice, payment_tender, recommended_items)

func _resolve_essential_story_for_visitor(visitor_id: String, customer: Dictionary) -> String:
	if not bool(customer.get("essential", false)):
		return ""
	var event_id := _event_for_visitor(visitor_id)
	if event_id.is_empty():
		return ""
	var event: Dictionary = story.resolve_event(event_id, true)
	if event.is_empty():
		return ""
	_sync_story_progress(event_id, event)
	story_event.emit(event_id, String(customer.get("name", "Customer")))
	return _event_line(event_id)

func order_stock(product_id: String, quantity: int = 1) -> Dictionary:
	if quantity <= 0 or not inventory.products.has(product_id):
		return {"ok": false, "reason": "invalid_order"}
	var stock_capacity_bonus := 10 if shop_progression.has_upgrade("expanded_shelf_capacity") else 0
	var capacity_check: Dictionary = inventory.can_receive_delivery(product_id, quantity, stock_capacity_bonus)
	if not capacity_check.get("ok", false):
		return {"ok":false, "reason":String(capacity_check.get("reason", "storage_capacity")), "capacity":int(capacity_check.get("capacity", 0))}
	var product: Dictionary = inventory.products[product_id]
	var unit_cost := int(product.get("purchase_cost", ceili(float(product.get("price", 0)) * 0.55)))
	var total_cost := maxi(1, unit_cost) * quantity
	if inventory.coins < total_cost:
		return {"ok": false, "reason": "not_enough_coins", "cost": total_cost}
	inventory.coins -= total_cost
	if not inventory.restock(product_id, quantity, stock_capacity_bonus):
		inventory.coins += total_cost
		return {"ok":false, "reason":"storage_capacity"}
	inventory.record_transaction({"reason":"stock_purchase", "product_id":product_id, "currency":"coins", "quantity":-total_cost, "stock_quantity":quantity, "unit_cost":unit_cost})
	money_changed.emit(inventory.coins, inventory.moon_tokens)
	shop_progression.award_reputation(1)
	shop_progression.award_proficiency("stewardship", 1)
	shop_progression.award_milestone("restocked_a_shelf")
	_save()
	return {"ok": true, "cost": total_cost, "quantity": quantity}

func restock_shelf(product_id: String, quantity: int = 1) -> Dictionary:
	var result: Dictionary = inventory.restock_shelf(product_id, quantity)
	if result.get("ok", false):
		shop_progression.award_proficiency("stewardship", 1)
		shop_progression.award_milestone("restocked_a_shelf")
		_save()
	return result

func pick_up_stock_to_carry(product_id: String) -> Dictionary:
	var result: Dictionary = inventory.pick_up_from_storage(product_id)
	if result.get("ok", false):
		_save()
	return result

func place_carried_stock_on_shelf(product_id: String) -> Dictionary:
	var result: Dictionary = inventory.place_carried_on_shelf(product_id)
	if result.get("ok", false):
		shop_progression.award_proficiency("stewardship", 1)
		shop_progression.award_milestone("restocked_a_shelf")
		_save()
	return result

func return_carried_stock_to_storage(product_id: String) -> Dictionary:
	var result: Dictionary = inventory.return_carried_to_storage(product_id)
	if result.get("ok", false):
		_save()
	return result

func reserve_stock(allocation_id: String, basket: Dictionary, reason: String = "special_order") -> Dictionary:
	var result := inventory.reserve(allocation_id, basket, reason, shift_number)
	if result.get("ok", false):
		_save()
	return result

func release_stock_reservation(allocation_id: String) -> bool:
	var released := inventory.release_reservation(allocation_id)
	if released:
		_save()
	return released

func discount_stock(product_id: String, modifier: float = 0.75) -> bool:
	var changed := inventory.set_discount(product_id, modifier)
	if changed:
		_save()
	return changed

func clear_stock_discount(product_id: String) -> bool:
	var changed := inventory.clear_discount(product_id)
	if changed:
		_save()
	return changed

func donate_stock(product_id: String, quantity: int = 1) -> Dictionary:
	var result: Dictionary = inventory.donate(product_id, quantity)
	if result.get("ok", false):
		shop_progression.award_reputation(maxi(1, int(ceil(quantity / 3.0))))
		shop_progression.award_proficiency("hospitality", 1)
		shop_progression.award_milestone("donated_surplus_stock")
		shop_progression.improve_cleanliness(0.5)
		_save()
	return result

func refund_sale(transaction_id: String) -> Dictionary:
	var stock_capacity_bonus := 10 if shop_progression.has_upgrade("expanded_shelf_capacity") else 0
	var result: Dictionary = inventory.refund(transaction_id, stock_capacity_bonus)
	if result.get("ok", false):
		money_changed.emit(inventory.coins, inventory.moon_tokens)
		_save()
	return result

func clean_shop(action_id: String) -> Dictionary:
	if not shop_progression.cleanliness_config.get("actions", {}).has(action_id):
		return {"ok": false, "reason": "unknown_action", "action_id": action_id}
	if _cleaning_actions_this_shift.has(action_id):
		return {"ok": false, "reason": "already_done", "action_id": action_id, "cleanliness": shop_progression.cleanliness}
	_cleaning_actions_this_shift[action_id] = true
	var cleanliness_bonus := float(shop_progression.proficiency_rank("stewardship"))
	var cleanliness := shop_progression.improve_cleanliness(float(shop_progression.cleanliness_config.get("actions", {}).get(action_id, 0.0)) + cleanliness_bonus)
	shop_progression.award_milestone("completed_cleaning_action")
	shop_progression.award_proficiency("stewardship", 1)
	_save()
	return {"ok": true, "action_id": action_id, "cleanliness": cleanliness}

func cleaning_action_done(action_id: String) -> bool:
	return _cleaning_actions_this_shift.has(action_id)

func available_upgrades() -> Array[Dictionary]:
	return shop_progression.available_upgrades()

func purchase_upgrade(upgrade_id: String) -> Dictionary:
	var quote: Dictionary = shop_progression.purchase_upgrade(upgrade_id)
	if not quote.get("ok", false):
		return quote
	var currency := String(quote.get("currency", "coins"))
	var cost := maxi(0, int(quote.get("cost", 0)))
	var balance: int = inventory.moon_tokens if currency == "moon_tokens" else inventory.coins
	if balance < cost:
		return {"ok": false, "reason": "not_enough_currency", "currency": currency, "cost": cost}
	if not shop_progression.commit_upgrade(upgrade_id):
		return {"ok": false, "reason": "purchase_changed"}
	if currency == "moon_tokens":
		inventory.moon_tokens -= cost
	else:
		inventory.coins -= cost
	inventory.record_transaction({"reason": "upgrade_purchase", "upgrade_id": upgrade_id, "currency": currency, "quantity": -cost})
	money_changed.emit(inventory.coins, inventory.moon_tokens)
	_save()
	return {"ok": true, "upgrade": quote.get("upgrade", {}), "currency": currency, "cost": cost}

func available_recipes(station_id: String = "kettle") -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var requested_station := _normalize_station_id(station_id)
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		if _normalize_station_id(String(recipe.get("station", "magical_kettle"))) != requested_station:
			continue
		if _recipe_discovery_gate_met(recipe) and discovered_recipe_ids.has(String(recipe_id)):
			available.append(recipe)
	return available

## Product IDs the player can currently combine to discover a recipe at this
## station. Locked recipes and already-known formulas are omitted.
func experimentable_ingredient_ids(station_id: String) -> Array[String]:
	var requested_station := _normalize_station_id(station_id)
	var ingredient_ids: Array[String] = []
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		if _normalize_station_id(String(recipe.get("station", "magical_kettle"))) != requested_station:
			continue
		if not _recipe_discovery_gate_met(recipe) or discovered_recipe_ids.has(String(recipe_id)):
			continue
		for ingredient_id in recipe.get("ingredients", {}):
			var id := String(ingredient_id)
			if not ingredient_ids.has(id):
				ingredient_ids.append(id)
	ingredient_ids.sort()
	return ingredient_ids

## Tries an exact ingredient combination at one preparation station. Unknown,
## partial, wrong-station, gated, or already-discovered trials are inspection
## only: no inventory state is touched. Only an exact, eligible recipe commits.
func experiment_recipe(station_id: String, ingredients: Dictionary) -> Dictionary:
	var requested_station := _normalize_station_id(station_id)
	if requested_station.is_empty() or ingredients.is_empty():
		return {"ok":false, "reason":"invalid_experiment"}
	for ingredient_id in ingredients:
		var amount: Variant = ingredients[ingredient_id]
		if not ingredient_id is String or not amount is int or int(amount) <= 0 or not inventory.products.has(String(ingredient_id)):
			return {"ok":false, "reason":"invalid_ingredients"}
	var exact_recipe_id := ""
	var exact_recipe: Dictionary = {}
	var other_station := ""
	var locked_exact_match := false
	var discovered_exact_match := false
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		var recipe_ingredients: Variant = recipe.get("ingredients", {})
		if not recipe_ingredients is Dictionary or not _ingredient_combinations_match(ingredients, recipe_ingredients):
			continue
		var recipe_station := _normalize_station_id(String(recipe.get("station", "magical_kettle")))
		if recipe_station == requested_station:
			if not _recipe_discovery_gate_met(recipe):
				locked_exact_match = true
				continue
			if discovered_recipe_ids.has(String(recipe_id)):
				discovered_exact_match = true
				continue
			exact_recipe_id = String(recipe_id)
			exact_recipe = recipe
			break
		if other_station.is_empty():
			other_station = recipe_station
	if exact_recipe_id.is_empty():
		if not other_station.is_empty():
			return {"ok":false, "reason":"wrong_station", "required_station":other_station}
		if discovered_exact_match:
			return {"ok":false, "reason":"already_discovered"}
		if locked_exact_match:
			return {"ok":false, "reason":"recipe_locked"}
		return {"ok":false, "reason":"unknown_combination"}
	var output_product_id := String(exact_recipe.get("output_product_id", ""))
	var output_quantity := maxi(1, int(exact_recipe.get("output_quantity", 1)))
	if output_product_id.is_empty() or not inventory.products.has(output_product_id):
		return {"ok":false, "reason":"missing_recipe_output", "recipe_id":exact_recipe_id}
	var production: Dictionary = inventory.produce(output_product_id, output_quantity, exact_recipe.get("ingredients", {}), exact_recipe_id)
	if not bool(production.get("ok", false)):
		return production
	discovered_recipe_ids.append(exact_recipe_id)
	_apply_recipe_rewards(exact_recipe)
	shop_progression.award_milestone("successful_recipe_experiment")
	_award_crafted_at_three_stations_if_earned()
	_save()
	return {"ok":true, "recipe_id":exact_recipe_id, "name":String(exact_recipe.get("name", exact_recipe_id)), "output_product_id":output_product_id, "produced":output_quantity, "storage":inventory.storage_quantity(output_product_id)}

func _ingredient_combinations_match(trial: Dictionary, recipe_ingredients: Dictionary) -> bool:
	if trial.size() != recipe_ingredients.size():
		return false
	for ingredient_id in recipe_ingredients:
		if not trial.has(ingredient_id) or int(trial[ingredient_id]) != int(recipe_ingredients[ingredient_id]):
			return false
	return true

func _recipe_discovery_gate_met(recipe: Dictionary) -> bool:
	var discovery := String(recipe.get("discovery", "known"))
	return discovery == "known" or (discovery == "shift_2" and shift_number >= 2) or (discovery == "pip_memory" and bool(story.flags.get("pip_first_memory", false)))

func _apply_recipe_rewards(recipe: Dictionary) -> void:
	shop_progression.award_milestone("first_recipe_prepared")
	shop_progression.award_proficiency("crafting", 1)
	if String(recipe.get("category", "")) == "magical" or String(recipe.get("discovery", "")) == "pip_memory":
		shop_progression.award_milestone("experimented_with_recipe")

func craft(recipe_id: String, station_id: String = "kettle") -> Dictionary:
	if not recipes.has(recipe_id):
		return {"ok": false, "reason": "unknown_recipe"}
	var recipe: Dictionary = recipes[recipe_id]
	var requested_station := _normalize_station_id(station_id)
	var recipe_station := _normalize_station_id(String(recipe.get("station", "magical_kettle")))
	if recipe_station != requested_station:
		return {"ok": false, "reason": "wrong_station", "required_station": recipe_station}
	if not available_recipes(requested_station).any(func(row): return row.get("id") == recipe_id):
		return {"ok": false, "reason": "undiscovered"}
	var output_product_id := String(recipe.get("output_product_id", ""))
	var output_quantity := maxi(1, int(recipe.get("output_quantity", 1)))
	if output_product_id.is_empty() or not inventory.products.has(output_product_id):
		return {"ok":false, "reason":"missing_recipe_output"}
	var production: Dictionary = inventory.produce(output_product_id, output_quantity, recipe.get("ingredients", {}), recipe_id)
	if not bool(production.get("ok", false)):
		return production
	if not discovered_recipe_ids.has(recipe_id):
		discovered_recipe_ids.append(recipe_id)
	_apply_recipe_rewards(recipe)
	_award_crafted_at_three_stations_if_earned()
	_save()
	return {"ok":true, "name":recipe.get("name", recipe_id), "output_product_id":output_product_id, "produced":output_quantity, "storage":inventory.storage_quantity(output_product_id)}

func _award_crafted_at_three_stations_if_earned() -> void:
	var completed_stations: Dictionary = {}
	for transaction in inventory.transactions:
		if not String(transaction.get("reason", "")).begins_with("production:"):
			continue
		var recipe_id := String(transaction.get("recipe_id", ""))
		if not recipes.has(recipe_id):
			continue
		var recipe: Dictionary = recipes[recipe_id]
		completed_stations[_normalize_station_id(String(recipe.get("station", "magical_kettle")))] = true
	if completed_stations.size() >= 3:
		shop_progression.award_milestone("crafted_at_three_stations")

func _normalize_station_id(station_id: String) -> String:
	var normalized := station_id.strip_edges().to_lower()
	if normalized in ["kettle", "magical kettle", "magical_kettle"]:
		return "magical_kettle"
	if normalized in ["coffee machine", "coffee_machine"]:
		return "coffee"
	if normalized in ["tea counter", "tea_counter"]:
		return "tea"
	if normalized in ["bakery warmer", "bakery_warmer"]:
		return "bakery_warmer"
	if normalized in ["sandwich station", "sandwich_station"]:
		return "sandwich"
	if normalized in ["microwave station", "microwave_station"]:
		return "microwave"
	return normalized

func _migrate_legacy_prepared_items() -> void:
	for recipe_id in inventory.prepared_items.keys():
		var count := int(inventory.prepared_items.get(recipe_id, 0))
		var recipe: Dictionary = recipes.get(String(recipe_id), {})
		var output_id := String(recipe.get("output_product_id", ""))
		if count <= 0 or output_id.is_empty() or not inventory.products.has(output_id):
			continue
		var migrated: Dictionary = inventory.produce(output_id, count, {}, String(recipe_id))
		if bool(migrated.get("ok", false)):
			inventory.prepared_items.erase(recipe_id)

func connect_clues(investigation_id: String, selected_clues: Array[String]) -> Dictionary:
	var result := story.connect_clues(investigation_id, selected_clues)
	var narrative_state: Dictionary = story.investigation_state.get(investigation_id, {})
	var mystery_state: Dictionary = mysteries.states.get(investigation_id, {"attempts": 0})
	mystery_state["attempts"] = int(narrative_state.get("wrong_deductions", 0)) + (1 if String(result.get("status", "")) == "deduced" else 0)
	mystery_state["status"] = "solved" if bool(narrative_state.get("completed", false)) else "active"
	mystery_state["solution"] = String(narrative_state.get("conclusion", ""))
	mysteries.states[investigation_id] = mystery_state
	if String(result.get("status", "")) == "deduced":
		shop_progression.award_milestone("connected_two_clues")
		shop_progression.award_proficiency("observation", 2)
		shop_progression.award_proficiency("attunement", 1)
		var flag_id := String(result.get("flag", ""))
		var flags_to_sync: Array[String] = []
		if not flag_id.is_empty():
			flags_to_sync.append(flag_id)
		for granted_flag_value in result.get("granted_flags", []):
			var granted_flag := String(granted_flag_value)
			if not granted_flag.is_empty() and not flags_to_sync.has(granted_flag):
				flags_to_sync.append(granted_flag)
		for synced_flag in flags_to_sync:
			mysteries.flags[synced_flag] = true
			world_map.set_story_flag(synced_flag, true)
			quests.flags[synced_flag] = true
		story._advance_chapter()
		_emit_journal()
	_save()
	return result

func pin_clue(clue_id: String, pinned: bool = true) -> bool:
	var pinned_ok := story.pin_clue(clue_id, pinned)
	if pinned_ok:
		mysteries.pin_clue(clue_id, pinned)
		_emit_journal()
		_save()
	return pinned_ok

func available_locations() -> Array[Dictionary]:
	return world_map.get_available_locations()

func travel_to(location_id: String) -> bool:
	if not story.is_location_unlocked(location_id):
		return false
	var travelled := world_map.travel_to(location_id)
	if travelled:
		_save()
	return travelled

func available_endings() -> Array[Dictionary]:
	return story.available_endings()

func choose_ending(ending_id: String) -> Dictionary:
	if not story.selected_ending.is_empty() or not world_map.ending_id.is_empty():
		return {"ok": false, "reason": "ending_already_chosen"}
	var previous_story_flags: Dictionary = story.flags.duplicate(true)
	var previous_story_world_state: String = String(story.world_state)
	var previous_world_flags: Dictionary = world_map.flags.duplicate(true)
	var previous_world_chapter_complete: bool = bool(world_map.ending_chapter_complete)
	var result: Dictionary = story.choose_ending(ending_id)
	if not result.get("ok", false):
		return result
	world_map.flags = story.flags.duplicate(true)
	if not world_map.choose_ending(ending_id, ["final_covenant_made"], true):
		story.selected_ending = ""
		story.world_state = previous_story_world_state
		story.flags = previous_story_flags
		story.journal_changed.emit()
		world_map.flags = previous_world_flags
		world_map.ending_chapter_complete = previous_world_chapter_complete
		return {"ok": false, "reason": "world_state_rejected_ending"}
	story.record_ending_memories(ending_id)
	_emit_journal()
	_save()
	return result

func essential_activity_route(activity_id: String) -> String:
	return story.ending_memory_route(activity_id)

func _event_for_visitor(visitor_id: String) -> String:
	for event in quests.queued_encounters():
		if bool(event.get("essential", true)) and event.get("visitor") == visitor_id and not story.completed_events.has(event.get("id")):
			return String(event.id)
	return ""

func _essential_event_projection(encounters: Array[Dictionary]) -> Array[Dictionary]:
	var projection: Array[Dictionary] = []
	for encounter in encounters:
		var event_id := String(encounter.get("quest_id", encounter.get("id", "")))
		if event_id.is_empty() or story.completed_events.has(event_id):
			continue
		projection.append({"id": event_id, "visitor": String(encounter.get("visitor", "")), "essential": true})
	return projection

func _sync_story_progress(event_id: String, event: Dictionary) -> void:
	quests.resolve_essential_encounter(event_id)
	quests.flags[event_id] = true
	world_map.set_story_flag(event_id, true)
	for granted_flag in event.get("grants_flags", []):
		quests.flags[String(granted_flag)] = true
		world_map.set_story_flag(String(granted_flag), true)
	var memory: Dictionary = event.get("memory", {})
	if not memory.is_empty():
		var character_id := String(memory.get("character", ""))
		var memory_id := String(memory.get("id", event_id))
		var memory_trait := String(memory.get("trait", "kindness"))
		relationships.record_memory(character_id, memory_id, [memory_trait])
		var next_stage := relationships.stage(character_id) + 1
		if next_stage < 5:
			relationships.advance_stage(character_id, next_stage)
		story.set_relationship_stage(character_id, relationships.stage(character_id))
	for promise_value in event.get("creates_promises", []):
		if not promise_value is Dictionary:
			continue
		var promise: Dictionary = promise_value
		relationships.remember_promise(String(promise.get("character", "")), String(promise.get("id", "")), String(promise.get("text", "")))
	for resolution_value in event.get("resolves_promises", []):
		if not resolution_value is Dictionary:
			continue
		var resolution: Dictionary = resolution_value
		var promise_character := String(resolution.get("character", ""))
		var promise_id := String(resolution.get("id", ""))
		var kept := bool(resolution.get("kept", true))
		if not relationships.resolve_promise(promise_character, promise_id, kept):
			continue
		var resolution_memory_id := String(resolution.get("memory_id", "promise_%s_%s" % [promise_id, "kept" if kept else "released"]))
		var resolution_text := String(resolution.get("memory", "You kept a promise that mattered." if kept else "You spoke honestly about a promise you could not keep."))
		story.record_memory(promise_character, resolution_memory_id, resolution_text, "honesty" if kept else "care")
		story.set_relationship_stage(promise_character, relationships.stage(promise_character))
		if kept:
			shop_progression.award_milestone("kept_a_kind_promise")
	for clue_id in event.get("clues", []):
		mysteries.add_clue(String(clue_id))
	miso_companion.sync_story_flags(story.flags)
	var visitor_id := String(event.get("visitor", ""))
	if visitor_id in ["pip", "fern", "conductor", "osric"]:
		shop_progression.award_milestone("helped_a_spirit")
		shop_progression.award_milestone("welcomed_between_visitor")
		shop_progression.award_proficiency("attunement", 1)
	_emit_journal()

func _event_line(event_id: String) -> String:
	return String(_dialogue.get("story_lines", {}).get(event_id, "A familiar customer shares a quiet moment with you."))

func _customer_line(id: String, name: String) -> String:
	var line := String(_dialogue.get("ordinary_lines", {}).get(id, _dialogue.get("default_ordinary_line", "%s thanks you.")))
	return line if not line.contains("%s") else line % name

func _stock_message(kind: String) -> String:
	var rows: Array[String] = []
	for id in inventory.products:
		var category := String(inventory.products[id].get("category", "everyday"))
		if (kind == "fridge" and category == "cold") or (kind == "shelf" and category != "cold"):
			var product_id := String(id)
			var product_name := localize_ui("product.%s.name" % product_id, String(inventory.products[id].get("name", id)))
			rows.append(localize_ui("stock.interaction.row", "{product} · display {shown} · backroom {stored}").format({"product":product_name, "shown":str(inventory.shelf_quantity(product_id)), "stored":str(inventory.storage_quantity(product_id))}))
	var container_key := "stock.interaction.fridge" if kind == "fridge" else "stock.interaction.shelves"
	var container_fallback := "On the fridge: {rows}" if kind == "fridge" else "On the shelves: {rows}"
	return localize_ui(container_key, container_fallback).format({"rows":", ".join(rows.slice(0, 5))})

func get_prompt(target_id: String) -> String:
	match target_id:
		"register": return localize_ui("prompt.register", "{interact}  Serve customer").format({"interact":_action_binding_label("interact")})
		"shelf": return localize_ui("prompt.shelf", "{interact}  Browse shelves").format({"interact":_action_binding_label("interact")})
		"fridge": return localize_ui("prompt.fridge", "{interact}  Check the fridge").format({"interact":_action_binding_label("interact")})
		"miso": return localize_ui("prompt.miso", "{interact}  Visit Miso · {companion}  Companion care").format({"interact":_action_binding_label("interact"), "companion":_action_binding_label("companion")})
		"journal": return localize_ui("prompt.journal", "{interact}  Read journal").format({"interact":_action_binding_label("interact")})
		"window": return localize_ui("prompt.window", "{inspect}  Look at the window").format({"inspect":_action_binding_label("inspect")})
		"back_door": return localize_ui("prompt.back_door", "{inspect}  Inspect the back door").format({"inspect":_action_binding_label("inspect")})
		"cat_bed": return localize_ui("prompt.cat_bed", "{interact}  Rest beside Miso").format({"interact":_action_binding_label("interact")})
	return localize_ui("prompt.default", "{interact}  Look").format({"interact":_action_binding_label("interact")})

func _on_time_changed(minutes: float, clock_text: String) -> void:
	clock_updated.emit(clock_text, minutes)

func _on_shift_time_reached() -> void:
	if shift_status != "open":
		return
	var spoiled_goods := inventory.age_stock_by_shift()
	inventory.clear_all_discounts()
	if shop_progression.cleanliness >= 80.0:
		shop_progression.award_milestone("completed_well_kept_shift")
	shop_progression.complete_shift()
	shift_status = "between_shifts"
	last_shift_earnings = maxi(0, inventory.revenue - shift_start_revenue)
	last_shift_coin_earnings = maxi(0, inventory.coins_revenue - shift_start_coins_revenue)
	last_shift_moon_earnings = maxi(0, inventory.moon_tokens_revenue - shift_start_moons_revenue)
	shift_changed.emit(shift_number, shift_status)
	var dawn_message := localize_ui("dawn.shift_complete", "Dawn settles over Bellwether. Night {night} is complete. Coins earned: {coins} · Moon Tokens earned: {moons}. Press {interact} to begin the next night.").format({"night":str(shift_number), "coins":str(last_shift_coin_earnings), "moons":str(last_shift_moon_earnings), "interact":_action_binding_label("interact")})
	if not spoiled_goods.is_empty():
		var spoiled_count := 0
		for row in spoiled_goods:
			spoiled_count += int(row.get("quantity", 0))
		var spoilage_key := "dawn.spoiled_goods.singular" if spoiled_count == 1 else "dawn.spoiled_goods.plural"
		var spoilage_fallback := "\n{count} perishable item went past its best-before night." if spoiled_count == 1 else "\n{count} perishable items went past their best-before night."
		dawn_message += localize_ui(spoilage_key, spoilage_fallback).format({"count":str(spoiled_count)})
	_set_message(dawn_message)
	_save()

func _on_customer_arrived(customer: Dictionary) -> void:
	customer_changed.emit(customer, true)
	_set_message(localize_ui("customer.arrived", "{name} has stepped inside.").format({"name":String(customer.get("name", "A customer"))}))
	_react_with_spirit_sense(customer)

func _react_with_spirit_sense(customer: Dictionary) -> void:
	if not miso_companion.ability_available("spirit_sense"):
		return
	var visitor_id := String(customer.get("id", ""))
	if visitor_id.is_empty():
		return
	var definition: Dictionary = customers.definitions.get(visitor_id, {})
	var tags: Array = definition.get("tags", [])
	if not tags.has("supernatural") or not tags.has("disguised"):
		return
	if int(miso_spirit_sense_reaction_shifts.get(visitor_id, -1)) == shift_number:
		return
	miso_spirit_sense_reaction_shifts[visitor_id] = shift_number
	var visitor_name := String(customer.get("name", definition.get("name", visitor_id)))
	var reaction := localize_ui("companion.response.spirit_sense.arrival", "Miso turns toward {visitor}. For a moment, the visitor's disguise slips at the edges.").format({"visitor":visitor_name})
	companion_reaction.emit(reaction)
	_save()

func _action_binding_label(action: String) -> String:
	if InputMap.has_action(action):
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		if not events.is_empty():
			return events[0].as_text()
	return action.capitalize()

func _on_customer_left(customer_id: String) -> void:
	customer_changed.emit({"id": customer_id}, false)

func _on_customer_state_changed(customer: Dictionary, _previous: String, next_state: String) -> void:
	customer_state_changed.emit(customer, next_state)

func _on_quest_changed(_quest_id: String, _state: String) -> void:
	_emit_journal()

func _on_system_clue_added(clue_id: String) -> void:
	if not story.clues.has(clue_id):
		story.clues.append(clue_id)
		story.journal_changed.emit()

func _on_location_unlocked(location_id: String) -> void:
	location_unlocked.emit(location_id)

func _sync_shop_location_unlocks() -> void:
	if shop_progression.has_upgrade("tea_corner"):
		world_map.unlock_optional("tea_corner", shop_progression.reputation)
	if shop_progression.has_upgrade("reading_nook"):
		world_map.unlock_optional("reading_nook", shop_progression.reputation)
	if shop_progression.has_upgrade("enchanted_greenhouse"):
		world_map.unlock_optional("enchanted_greenhouse", shop_progression.reputation)

func _on_location_changed(location_id: String) -> void:
	location_changed.emit(location_id)

func _set_message(text: String) -> void:
	last_message = text
	message_changed.emit(text)

func journal_text() -> String:
	var text := story.journal_text()
	var queued_encounters := quests.queued_encounters()
	if not queued_encounters.is_empty():
		var next_id := String(queued_encounters[0].get("quest_id", queued_encounters[0].get("id", "")))
		var definition: Dictionary = quests.definitions.get(next_id, {})
		var title_fallback := String(definition.get("title", next_id.replace("_", " ").capitalize()))
		var title := localize_ui("story.event.%s.title" % next_id, title_fallback)
		text += "\n\n" + localize_ui("journal.carried_forward", "Carried forward: {title}").format({"title":title})
	var open_promises := relationships.all_open_promises()
	if not open_promises.is_empty():
		text += "\n\n" + localize_ui("journal.section.open_promises", "Open promises")
		for promise in open_promises:
			var character_id := String(promise.get("character_id", ""))
			var character_name := String(customers.definitions.get(character_id, {}).get("name", character_id.capitalize()))
			var promise_id := String(promise.get("id", ""))
			var promise_text := localize_ui("journal.promise.%s.text" % promise_id, String(promise.get("text", "")))
			text += "\n· %s — %s" % [character_name, promise_text]
	var revealed_memory_echoes: Array[Dictionary] = []
	for memory_echo in miso_memory_echo_fragments:
		if bool(story.flags.get(_miso_memory_echo_flag(String(memory_echo.get("id", ""))), false)):
			revealed_memory_echoes.append(memory_echo)
	if not revealed_memory_echoes.is_empty():
		text += "\n\n" + localize_ui("journal.section.miso_memories", "Miso · remembered moments")
		for memory_echo in revealed_memory_echoes:
			text += "\n· %s" % localize_ui(String(memory_echo.get("title_id", "")), "A remembered moment")
			text += "\n  %s" % localize_ui(String(memory_echo.get("text_id", "")), "A fragment returns to Miso.")
	return text

func _emit_journal() -> void:
	journal_changed.emit(journal_text())

func save_now() -> bool:
	return _save()

func archive_problem_save_and_start_fresh() -> bool:
	if not save_recovery_required or not SaveScript.archive_problem_saves():
		return false
	save_recovery_required = false
	save_recovery_message = ""
	shift_number = 0
	shift_status = "between_shifts"
	_set_message(localize_ui("save.recovery.archived_ready", "The unreadable save was archived intact. You can begin a new Moonmart story now."))
	return true

func load_state(payload: Dictionary) -> void:
	shift_number = int(payload.get("shift_number", 0))
	shift_status = String(payload.get("shift_status", "between_shifts"))
	shift_start_revenue = int(payload.get("shift_start_revenue", inventory.revenue))
	last_shift_earnings = int(payload.get("last_shift_earnings", 0))
	shift_start_coins_revenue = int(payload.get("shift_start_coins_revenue", inventory.coins_revenue))
	shift_start_moons_revenue = int(payload.get("shift_start_moons_revenue", inventory.moon_tokens_revenue))
	player_positions = _validated_player_positions(payload.get("player_positions", {}))
	last_shift_coin_earnings = int(payload.get("last_shift_coin_earnings", 0))
	last_shift_moon_earnings = int(payload.get("last_shift_moon_earnings", 0))
	_conversation_turns = payload.get("conversation_turns", {}).duplicate(true)
	if payload.has("inventory"):
		inventory.from_save(payload.inventory)
		_migrate_legacy_prepared_items()
	if payload.has("calendar"):
		calendar.import_state(payload.calendar)
	else:
		calendar.set_current_shift(maxi(shift_number, 1))
	if not payload.has("shift_start_revenue"):
		shift_start_revenue = inventory.revenue
	if not payload.has("shift_start_coins_revenue"):
		shift_start_coins_revenue = inventory.coins_revenue
	if not payload.has("shift_start_moons_revenue"):
		shift_start_moons_revenue = inventory.moon_tokens_revenue
	if payload.has("clock"): clock.from_save(payload.clock)
	if payload.has("customers"): customers.from_save(payload.customers)
	if payload.has("story"): story.from_save(payload.story)
	miso_hidden_paw_guidance = payload.get("miso_hidden_paw_guidance", {}).duplicate(true)
	_pending_optional_events.assign(payload.get("pending_optional_events", []))
	_optional_event_timer = maxf(0.0, float(payload.get("optional_event_timer", 38.0)))
	_cleaning_actions_this_shift = payload.get("cleaning_actions_this_shift", {}).duplicate(true)
	if payload.has("relationships_system"):
		relationships.import_state(payload.relationships_system)
	else:
		relationships.import_state({"records": story.relationships})
	for character_id in story.relationships:
		story.set_relationship_stage(String(character_id), relationships.stage(String(character_id)))
	if payload.has("quests_system"):
		quests.import_state(payload.quests_system)
	else:
		quests.flags = story.flags.duplicate(true)
		for completed_id in story.completed_events:
			if quests.states.has(completed_id):
				quests.states[completed_id] = "complete"
				quests.flags[completed_id] = true
		quests._refresh_locked_quests()
	var legacy_essential_queue: Array = story.queued_events.duplicate(true)
	if legacy_essential_queue.is_empty():
		legacy_essential_queue.assign(payload.get("pending_events", []))
	var unresolved_legacy_queue: Array[Dictionary] = []
	for encounter_value in legacy_essential_queue:
		if not encounter_value is Dictionary:
			continue
		var encounter_id := String(encounter_value.get("quest_id", encounter_value.get("id", "")))
		if not encounter_id.is_empty() and not story.completed_events.has(encounter_id):
			unresolved_legacy_queue.append(encounter_value)
	if not unresolved_legacy_queue.is_empty():
		quests.restore_legacy_encounters(unresolved_legacy_queue, maxi(shift_number, 1))
	quests.reconcile_encounter_queue(story.completed_events, maxi(shift_number, 1))
	story.queued_events.clear()
	_pending_events = _essential_event_projection(quests.queued_encounters())
	if payload.has("mysteries_system"):
		mysteries.import_state(payload.mysteries_system)
	else:
		mysteries.import_state({"discovered_clues": story.clues, "pinned_clues": story.pinned_clues, "states": story.investigation_state, "flags": story.flags})
	if payload.has("world_system"):
		world_map.import_state(payload.world_system)
	else:
		world_map.flags = story.flags.duplicate(true)
		for flag_id in story.flags:
			if bool(story.flags[flag_id]):
				world_map.set_story_flag(String(flag_id), true)
	if payload.has("decorations_system"):
		decoration.import_state(payload.decorations_system)
	if payload.has("event_director"):
		event_director.import_state(payload.event_director)
	if payload.has("environmental_puzzles"):
		environmental_puzzles.import_state(payload.environmental_puzzles)
	discovered_collectibles.clear()
	for collectible_id in payload.get("discovered_collectibles", []):
		var saved_collectible_id := String(collectible_id)
		if collectible_definitions.has(saved_collectible_id) and not discovered_collectibles.has(saved_collectible_id):
			discovered_collectibles.append(saved_collectible_id)
	if payload.has("shop_progression"):
		shop_progression.import_state(payload.shop_progression)
	if payload.has("miso_companion"):
		miso_companion.import_state(payload.miso_companion)
	if payload.has("miso_dream_sequence"):
		miso_dream_sequence.import_state(payload.miso_dream_sequence)
	miso_spirit_sense_reaction_shifts = payload.get("miso_spirit_sense_reaction_shifts", {}).duplicate(true)
	anomaly_disturbances.assign(payload.get("anomaly_disturbances", []))
	resolved_anomaly_investigations.assign(payload.get("resolved_anomaly_investigations", []))
	miso_companion.sync_story_flags(story.flags)
	for flag_id in story.flags:
		if bool(story.flags[flag_id]):
			mysteries.flags[String(flag_id)] = true
	discovered_recipe_ids.clear()
	if payload.has("discovered_recipe_ids"):
		for recipe_id in payload.get("discovered_recipe_ids", []):
			var saved_recipe_id := String(recipe_id)
			if recipes.has(saved_recipe_id) and _recipe_discovery_gate_met(recipes[saved_recipe_id]) and not discovered_recipe_ids.has(saved_recipe_id):
				discovered_recipe_ids.append(saved_recipe_id)
	else:
		# Older saves used only shift/story gates as their recipe book state.
		# Preserve everything those saves could already prepare.
		for recipe_id in recipes:
			if _recipe_discovery_gate_met(recipes[recipe_id]):
				discovered_recipe_ids.append(String(recipe_id))
	for recipe_id in recipes:
		if String(recipes[recipe_id].get("discovery", "known")) == "known" and not discovered_recipe_ids.has(String(recipe_id)):
			discovered_recipe_ids.append(String(recipe_id))
	if clock.running: shift_status = "open"
	shift_changed.emit(shift_number, shift_status)
	money_changed.emit(inventory.coins, inventory.moon_tokens)
	_emit_journal()

func _save() -> bool:
	if save_recovery_required:
		return false
	var committed := SaveScript.write_save({"shift_number": shift_number, "shift_status": shift_status, "shift_start_revenue": shift_start_revenue, "last_shift_earnings": last_shift_earnings, "shift_start_coins_revenue": shift_start_coins_revenue, "shift_start_moons_revenue": shift_start_moons_revenue, "last_shift_coin_earnings": last_shift_coin_earnings, "last_shift_moon_earnings": last_shift_moon_earnings, "player_positions": player_positions.duplicate(true), "conversation_turns": _conversation_turns.duplicate(true), "cleaning_actions_this_shift": _cleaning_actions_this_shift.duplicate(true), "calendar": calendar.export_state(), "shop_progression": shop_progression.export_state(), "miso_companion": miso_companion.export_state(), "miso_dream_sequence": miso_dream_sequence.export_state(), "miso_spirit_sense_reaction_shifts": miso_spirit_sense_reaction_shifts.duplicate(true), "anomaly_disturbances": anomaly_disturbances.duplicate(true), "resolved_anomaly_investigations": resolved_anomaly_investigations.duplicate(), "miso_hidden_paw_guidance": miso_hidden_paw_guidance.duplicate(true), "discovered_collectibles": discovered_collectibles.duplicate(), "discovered_recipe_ids": discovered_recipe_ids.duplicate(), "inventory": inventory.to_save(), "clock": clock.to_save(), "customers": customers.to_save(), "story": story.to_save(), "pending_events": _pending_events.duplicate(true), "pending_optional_events": _pending_optional_events.duplicate(true), "optional_event_timer": _optional_event_timer, "relationships_system": relationships.export_state(), "quests_system": quests.export_state(), "mysteries_system": mysteries.export_state(), "world_system": world_map.export_state(), "decorations_system": decoration.export_state(), "event_director": event_director.export_state(), "environmental_puzzles": environmental_puzzles.export_state()})
	if not committed:
		save_failed.emit()
	return committed

func remember_player_position(location_id: String, position: Vector2) -> void:
	if location_id.is_empty() or not is_finite(position.x) or not is_finite(position.y):
		return
	player_positions[location_id] = {"x": position.x, "y": position.y}

func has_saved_player_position(location_id: String) -> bool:
	return player_positions.has(location_id)

func saved_player_position(location_id: String) -> Vector2:
	var value: Variant = player_positions.get(location_id, {})
	if not value is Dictionary:
		return Vector2.ZERO
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))

func _validated_player_positions(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result
	for location_id in value:
		var coordinates: Variant = value[location_id]
		if not location_id is String or String(location_id).is_empty() or not coordinates is Dictionary:
			continue
		var x: Variant = coordinates.get("x", null)
		var y: Variant = coordinates.get("y", null)
		if (not x is int and not x is float) or (not y is int and not y is float):
			continue
		if not is_finite(float(x)) or not is_finite(float(y)):
			continue
		result[String(location_id)] = {"x": float(x), "y": float(y)}
	return result

func _fallback_products() -> Array:
	return [
		{"id":"strawberry_milk","name":"Strawberry milk","price":3,"starting_stock":8,"category":"cold"},
		{"id":"milk","name":"Milk","price":2,"starting_stock":6,"category":"cold"},
		{"id":"bread","name":"Bread","price":3,"starting_stock":8,"category":"bakery"},
		{"id":"tea","name":"Tea","price":3,"starting_stock":8,"category":"everyday"},
		{"id":"biscuits","name":"Biscuits","price":2,"starting_stock":7,"category":"everyday"},
		{"id":"coffee","name":"Coffee","price":4,"starting_stock":7,"category":"everyday"}]

func _fallback_characters() -> Array:
	return [
		{"id":"agnes","name":"Agnes Thorne","basket":{"bread":1,"tea":1}},
		{"id":"pip","name":"Pip","basket":{"strawberry_milk":1}},
		{"id":"lucien","name":"Lucien Vale","basket":{"coffee":1,"biscuits":1}},
		{"id":"wren","name":"Wren Hollow","basket":{"tea":1,"biscuits":1}}]
