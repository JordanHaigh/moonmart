class_name MoonmartSave
extends RefCounted

const SAVE_PATH := "user://moonmart_save.json"
const TEMP_PATH := "user://moonmart_save.tmp"
const STAGE_PATH := "user://moonmart_save.replace"
const RECOVERY_PATH := "user://moonmart_save.recovered"
const RECOVERY_TEMP_PATH := "user://moonmart_save.recovered.tmp"
const RECOVERY_STAGE_PATH := "user://moonmart_save.recovered.replace"
const BACKUP_PATH := "user://moonmart_save.bak"
const BACKUP_TEMP_PATH := "user://moonmart_save.bak.tmp"
const BACKUP_STAGE_PATH := "user://moonmart_save.bak.replace"
const SCHEMA_VERSION := 4

## read_save() keeps its original return type. Callers can inspect these values
## to distinguish a genuinely new game from a damaged or newer save that must
## not be silently replaced.
static var _last_read_status := "not_read"
static var _last_read_error := ""

static func write_save(payload: Dictionary) -> bool:
	if _must_preserve_existing_save():
		return false
	# Preserve a verified temp candidate before the normal writer reuses TEMP_PATH.
	if _last_read_status == "recovered_temp" and not _preserve_recovered_temp():
		return false
	var encoded := JSON.stringify({"schema_version": SCHEMA_VERSION, "game": payload}, "\t")
	if not _write_text(TEMP_PATH, encoded):
		_remove_file(TEMP_PATH)
		return false
	var verified := _read_path(TEMP_PATH)
	if not bool(verified.get("ok", false)) or int(verified.get("version", -1)) != SCHEMA_VERSION:
		_remove_file(TEMP_PATH)
		return false
	if FileAccess.file_exists(SAVE_PATH):
		var current := _read_path(SAVE_PATH)
		if String(current.get("status", "")) == "future_version":
			_last_read_status = "future_version"
			_last_read_error = String(current.get("error", "The save was created by a newer game version."))
			_remove_file(TEMP_PATH)
			return false
		if bool(current.get("ok", false)):
			var existing_backup := _read_path(BACKUP_PATH)
			if String(existing_backup.get("status", "")) == "future_version":
				_last_read_status = "future_version"
				_last_read_error = "The backup save was created by a newer game version and has been preserved."
				_remove_file(TEMP_PATH)
				return false
			if not _write_text(BACKUP_TEMP_PATH, FileAccess.get_file_as_string(SAVE_PATH)):
				_remove_file(TEMP_PATH)
				_remove_file(BACKUP_TEMP_PATH)
				return false
			var verified_backup := _read_path(BACKUP_TEMP_PATH)
			if not bool(verified_backup.get("ok", false)):
				_remove_file(TEMP_PATH)
				_remove_file(BACKUP_TEMP_PATH)
				return false
			if not _replace_atomically(BACKUP_TEMP_PATH, BACKUP_PATH, BACKUP_STAGE_PATH):
				_remove_file(TEMP_PATH)
				return false
		elif _last_read_status not in ["recovered_backup", "recovered_temp", "recovered_stage", "recovered_copy"]:
			# Never replace an unreadable primary unless a verified recovery source
			# was loaded for this session.
			_last_read_status = "corrupt"
			_last_read_error = String(current.get("error", "The current save could not be read."))
			_remove_file(TEMP_PATH)
			return false
		elif not _archive_unreadable_primary():
			_remove_file(TEMP_PATH)
			return false
	if not _replace_atomically(TEMP_PATH, SAVE_PATH, STAGE_PATH):
		_remove_file(TEMP_PATH)
		return false
	_remove_file(RECOVERY_PATH)
	_last_read_status = "loaded"
	_last_read_error = ""
	return true

static func read_save() -> Dictionary:
	_last_read_status = "reading"
	_last_read_error = ""
	var primary := _read_path(SAVE_PATH)
	if String(primary.get("status", "")) == "future_version":
		_last_read_status = "future_version"
		_last_read_error = String(primary.get("error", "The save was created by a newer game version."))
		return {}
	if bool(primary.get("ok", false)):
		_last_read_status = String(primary.get("status", "loaded"))
		return primary.get("payload", {}).duplicate(true)
	var staged := _read_staged_candidate()
	if String(staged.get("status", "")) == "future_version":
		_last_read_status = "future_version"
		_last_read_error = String(staged.get("error", "A staged save was created by a newer game version."))
		return {}
	if bool(staged.get("ok", false)):
		_last_read_status = String(staged.get("status", "recovered_temp"))
		_last_read_error = String(staged.get("error", ""))
		return staged.get("payload", {}).duplicate(true)
	var backup := _read_path(BACKUP_PATH)
	if String(backup.get("status", "")) == "future_version":
		_last_read_status = "future_version"
		_last_read_error = "The backup save was created by a newer game version and has been preserved."
		return {}
	if bool(backup.get("ok", false)):
		_last_read_status = "recovered_backup"
		_last_read_error = "Primary save could not be loaded (%s); loaded the last-known-good backup." % String(primary.get("error", primary.get("status", "unknown error")))
		return backup.get("payload", {}).duplicate(true)
	var no_primary_or_backup := String(primary.get("status", "")) == "missing" and String(backup.get("status", "")) == "missing"
	if no_primary_or_backup and not _has_staged_save_artifact():
		_last_read_status = "no_save"
		return {}
	_last_read_status = "io_error" if String(primary.get("status", "")) == "io_error" or String(backup.get("status", "")) == "io_error" else "corrupt"
	_last_read_error = "Primary save: %s. Recovery staging: %s. Backup: %s." % [String(primary.get("error", primary.get("status", "unknown error"))), String(staged.get("error", staged.get("status", "no valid staged save"))), String(backup.get("error", backup.get("status", "unknown error")))]
	return {}

static func read_status() -> String:
	return _last_read_status

static func read_error() -> String:
	return _last_read_error

static func has_save_problem() -> bool:
	return _last_read_status in ["corrupt", "future_version", "io_error"]

## Keeps every unreadable/newer save under a unique archive name before the
## caller offers a clean start. No save data is deleted by this recovery path.
static func archive_problem_saves() -> bool:
	if not has_save_problem():
		return false
	var archive_id := "%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var moved: Array[Dictionary] = []
	for entry in [
		{"path": SAVE_PATH, "suffix": ".json"},
		{"path": BACKUP_PATH, "suffix": ".bak"},
		{"path": TEMP_PATH, "suffix": ".tmp"},
		{"path": STAGE_PATH, "suffix": ".replace"},
		{"path": RECOVERY_PATH, "suffix": ".recovered"},
		{"path": RECOVERY_TEMP_PATH, "suffix": ".recovered.tmp"},
		{"path": RECOVERY_STAGE_PATH, "suffix": ".recovered.replace"},
		{"path": BACKUP_TEMP_PATH, "suffix": ".bak.tmp"},
		{"path": BACKUP_STAGE_PATH, "suffix": ".bak.replace"}
	]:
		var original := String(entry.path)
		if not FileAccess.file_exists(original):
			continue
		var archived := "user://moonmart_save_archived_%s%s" % [archive_id, String(entry.suffix)]
		var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(original), ProjectSettings.globalize_path(archived))
		if error != OK:
			for prior in moved:
				DirAccess.rename_absolute(ProjectSettings.globalize_path(String(prior.archived)), ProjectSettings.globalize_path(String(prior.original)))
			_last_read_status = "corrupt"
			_last_read_error = "The previous save could not be archived; no new save was started."
			return false
		moved.append({"original": original, "archived": archived})
	_last_read_status = "no_save"
	_last_read_error = ""
	return true

static func _must_preserve_existing_save() -> bool:
	if _last_read_status not in ["corrupt", "future_version", "io_error"]:
		return false
	return _has_any_save_artifact()

static func _read_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "status": "missing", "error": "file does not exist"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "status": "io_error", "error": "could not open save file"}
	var text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return {"ok": false, "status": "io_error", "error": "failed while reading save file"}
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK or not parser.data is Dictionary:
		return {"ok": false, "status": "corrupt", "error": "invalid JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()]}
	var parsed: Dictionary = parser.data
	var version_value: Variant = parsed.get("schema_version", 0)
	if not (version_value is int or version_value is float):
		return {"ok": false, "status": "corrupt", "error": "schema_version is not numeric"}
	var version_number := float(version_value)
	if is_nan(version_number) or is_inf(version_number):
		return {"ok": false, "status": "corrupt", "error": "schema_version is not finite"}
	if version_number > SCHEMA_VERSION:
		return {"ok": false, "status": "future_version", "version": version_value, "error": "save schema %s is newer than supported schema %d" % [str(version_value), SCHEMA_VERSION]}
	if version_number < 0.0 or floorf(version_number) != version_number:
		return {"ok": false, "status": "corrupt", "error": "schema_version is invalid"}
	var version := int(version_number)
	if version > 0 and not parsed.has("game"):
		return {"ok": false, "status": "corrupt", "version": version, "error": "versioned save is missing its game payload"}
	var payload_value: Variant = parsed.get("game", parsed) if version == 0 else parsed.get("game")
	if not payload_value is Dictionary:
		return {"ok": false, "status": "corrupt", "version": version, "error": "save payload is not an object"}
	var payload: Dictionary = payload_value.duplicate(true)
	var shape_error := _validate_payload_shape(payload)
	if not shape_error.is_empty():
		return {"ok": false, "status": "corrupt", "version": version, "error": shape_error}
	if version <= 1:
		payload = _migrate_v1(payload)
	if version <= 2:
		payload = _migrate_v2(payload)
	if version <= 3:
		payload = _migrate_v3(payload)
	shape_error = _validate_payload_shape(payload)
	if not shape_error.is_empty():
		return {"ok": false, "status": "corrupt", "version": version, "error": shape_error}
	return {"ok": true, "status": "migrated" if version < SCHEMA_VERSION else "loaded", "version": version, "payload": payload, "error": ""}

static func _validate_payload_shape(payload: Dictionary) -> String:
	var issue := _validate_fields(payload, "game", ["inventory", "calendar", "clock", "customers", "story", "relationships_system", "quests_system", "mysteries_system", "world_system", "decorations_system", "event_director", "environmental_puzzles", "shop_progression", "miso_companion", "miso_spirit_sense_reaction_shifts", "miso_hidden_paw_guidance", "conversation_turns", "cleaning_actions_this_shift", "player_positions"], ["pending_events", "pending_optional_events", "anomaly_disturbances", "resolved_anomaly_investigations", "discovered_collectibles", "discovered_recipe_ids"])
	if not issue.is_empty(): return issue
	if payload.has("player_positions"):
		for location_id in payload.player_positions:
			var coordinates: Variant = payload.player_positions[location_id]
			if not location_id is String or String(location_id).is_empty() or not coordinates is Dictionary:
				return "game.player_positions entries must map location IDs to coordinate objects"
			if not coordinates.has("x") or not coordinates.has("y"):
				return "game.player_positions.%s requires x and y" % String(location_id)
			for axis in ["x", "y"]:
				var coordinate: Variant = coordinates[axis]
				if (not coordinate is int and not coordinate is float) or not is_finite(float(coordinate)):
					return "game.player_positions.%s.%s must be a finite number" % [String(location_id), axis]
	issue = _validate_array_items(payload, "discovered_collectibles", "game", "string")
	if not issue.is_empty(): return issue
	issue = _validate_array_items(payload, "discovered_recipe_ids", "game", "string")
	if not issue.is_empty(): return issue
	if payload.has("miso_hidden_paw_guidance"):
		var guidance: Variant = payload.miso_hidden_paw_guidance
		if not guidance is Dictionary:
			return "game.miso_hidden_paw_guidance must be an object"
		issue = _validate_fields(guidance, "game.miso_hidden_paw_guidance", [], [])
		if not issue.is_empty(): return issue
		if not guidance.is_empty():
			for guidance_key in ["clue_id", "target_id", "marker_id", "location_id"]:
				if not guidance.get(guidance_key, "") is String or String(guidance.get(guidance_key, "")).is_empty():
					return "game.miso_hidden_paw_guidance.%s must be nonempty text" % guidance_key
	issue = _validate_array_items(payload, "anomaly_disturbances", "game", "dictionary")
	if not issue.is_empty(): return issue
	issue = _validate_array_items(payload, "resolved_anomaly_investigations", "game", "string")
	if not issue.is_empty(): return issue
	for index in range(payload.get("anomaly_disturbances", []).size()):
		var disturbance: Dictionary = payload.anomaly_disturbances[index]
		if not disturbance.get("event_id", "") is String or String(disturbance.get("event_id", "")).is_empty():
			return "game.anomaly_disturbances[%d].event_id must be nonempty text" % index
		if not disturbance.get("shift_number", null) is int:
			return "game.anomaly_disturbances[%d].shift_number must be an integer" % index
	if payload.has("miso_spirit_sense_reaction_shifts"):
		for visitor_id in payload.miso_spirit_sense_reaction_shifts:
			if not visitor_id is String or String(visitor_id).is_empty():
				return "game.miso_spirit_sense_reaction_shifts keys must be nonempty visitor IDs"
			var shift_value: Variant = payload.miso_spirit_sense_reaction_shifts[visitor_id]
			if (not shift_value is int and not shift_value is float) or not is_finite(float(shift_value)) or floorf(float(shift_value)) != float(shift_value):
				return "game.miso_spirit_sense_reaction_shifts.%s must be an integer shift" % String(visitor_id)
			payload.miso_spirit_sense_reaction_shifts[visitor_id] = int(shift_value)
	for key in ["pending_events", "pending_optional_events"]:
		issue = _validate_array_items(payload, key, "game", "dictionary")
		if not issue.is_empty(): return issue
	if payload.has("inventory"):
		issue = _validate_fields(payload.inventory, "game.inventory", ["stock", "prepared_items", "reservations", "sales_ledger", "price_modifiers", "shelf_stock", "storage_stock", "stock_lots"], ["transactions"])
		if not issue.is_empty(): return issue
		if payload.inventory.has("carried_item") and not payload.inventory.carried_item is Dictionary:
			return "game.inventory.carried_item must be a dictionary"
		if payload.inventory.has("carried_item") and not payload.inventory.carried_item.is_empty():
			if not payload.inventory.carried_item.has("product_id"):
				return "game.inventory.carried_item.product_id is required"
			if not payload.inventory.carried_item.has("quantity"):
				return "game.inventory.carried_item.quantity is required"
			if not payload.inventory.carried_item.product_id is String or String(payload.inventory.carried_item.product_id).is_empty():
				return "game.inventory.carried_item.product_id must be nonempty text"
			var carried_quantity: Variant = payload.inventory.carried_item.quantity
			if not carried_quantity is int and not carried_quantity is float:
				return "game.inventory.carried_item.quantity must be numeric"
			if int(carried_quantity) != 1 or float(carried_quantity) != 1.0:
				return "game.inventory.carried_item.quantity must be exactly one"
		issue = _validate_array_items(payload.inventory, "transactions", "game.inventory", "dictionary")
		if not issue.is_empty(): return issue
		for map_key in ["reservations", "sales_ledger"]:
			issue = _validate_dictionary_values(payload.inventory.get(map_key, {}), "game.inventory.%s" % map_key)
			if not issue.is_empty(): return issue
			for record_id in payload.inventory.get(map_key, {}):
				var record: Dictionary = payload.inventory[map_key][record_id]
				issue = _validate_fields(record, "game.inventory.%s.%s" % [map_key, String(record_id)], ["basket"], [])
				if not issue.is_empty(): return issue
		for transaction_index in range(payload.inventory.get("transactions", []).size()):
			var transaction: Dictionary = payload.inventory.transactions[transaction_index]
			issue = _validate_fields(transaction, "game.inventory.transactions[%d]" % transaction_index, ["basket"], [])
			if not issue.is_empty(): return issue
		for product_id in payload.inventory.get("stock_lots", {}):
			var lots: Variant = payload.inventory.stock_lots[product_id]
			if not lots is Array:
				return "game.inventory.stock_lots.%s must be an array" % String(product_id)
			for index in range(lots.size()):
				if not lots[index] is Dictionary:
					return "game.inventory.stock_lots.%s[%d] must be an object" % [String(product_id), index]
	if payload.has("calendar"):
		issue = _validate_fields(payload.calendar, "game.calendar", ["attended_festivals"], [])
		if not issue.is_empty(): return issue
	if payload.has("customers"):
		issue = _validate_fields(payload.customers, "game.customers", ["seen"], ["active", "queue"])
		if not issue.is_empty(): return issue
		for list_key in ["active", "queue"]:
			issue = _validate_array_items(payload.customers, list_key, "game.customers", "dictionary")
			if not issue.is_empty(): return issue
			for row in payload.customers.get(list_key, []):
				issue = _validate_fields(row, "game.customers.%s[]" % list_key, ["basket", "browsing_choice"], [])
				if not issue.is_empty(): return issue
	if payload.has("story"):
		issue = _validate_fields(payload.story, "game.story", ["flags", "relationships", "investigation_state", "ending_memories"], ["clues", "pinned_clues", "queued_events", "completed_events"])
		if not issue.is_empty(): return issue
		for key in ["clues", "pinned_clues", "completed_events"]:
			issue = _validate_array_items(payload.story, key, "game.story", "string")
			if not issue.is_empty(): return issue
		issue = _validate_array_items(payload.story, "queued_events", "game.story", "dictionary")
		if not issue.is_empty(): return issue
		for key in ["relationships", "investigation_state", "ending_memories"]:
			issue = _validate_dictionary_values(payload.story.get(key, {}), "game.story.%s" % key)
			if not issue.is_empty(): return issue
		issue = _validate_ending_memory_snapshots(payload.story)
		if not issue.is_empty(): return issue
		for character_id in payload.story.get("relationships", {}):
			issue = _validate_fields(payload.story.relationships[character_id], "game.story.relationships.%s" % String(character_id), [], ["memories"])
			if not issue.is_empty(): return issue
			var memories: Variant = payload.story.relationships[character_id].get("memories", [])
			for memory in memories:
				if not memory is Dictionary and not memory is String:
					return "game.story.relationships.%s.memories entries must be objects or legacy strings" % String(character_id)
	if payload.has("relationships_system"):
		issue = _validate_fields(payload.relationships_system, "game.relationships_system", ["records"], [])
		if not issue.is_empty(): return issue
		for character_id in payload.relationships_system.get("records", {}):
			var record: Variant = payload.relationships_system.records[character_id]
			issue = _validate_fields(record, "game.relationships_system.records.%s" % String(character_id), ["promises", "values", "traits"], ["memories"])
			if not issue.is_empty(): return issue
	if payload.has("quests_system"):
		issue = _validate_fields(payload.quests_system, "game.quests_system", ["states", "flags", "missed_visits"], ["encounter_queue"])
		if not issue.is_empty(): return issue
		issue = _validate_array_items(payload.quests_system, "encounter_queue", "game.quests_system", "dictionary")
		if not issue.is_empty(): return issue
	if payload.has("mysteries_system"):
		issue = _validate_fields(payload.mysteries_system, "game.mysteries_system", ["states", "flags"], ["discovered_clues", "pinned_clues"])
		if not issue.is_empty(): return issue
		for key in ["discovered_clues", "pinned_clues"]:
			issue = _validate_array_items(payload.mysteries_system, key, "game.mysteries_system", "string")
			if not issue.is_empty(): return issue
		for investigation_id in payload.mysteries_system.get("states", {}):
			if not payload.mysteries_system.states[investigation_id] is Dictionary:
				return "game.mysteries_system.states.%s must be an object" % String(investigation_id)
	if payload.has("world_system"):
		issue = _validate_fields(payload.world_system, "game.world_system", ["flags"], ["unlocked_locations"])
		if not issue.is_empty(): return issue
		issue = _validate_array_items(payload.world_system, "unlocked_locations", "game.world_system", "string")
		if not issue.is_empty(): return issue
	if payload.has("decorations_system"):
		issue = _validate_fields(payload.decorations_system, "game.decorations_system", ["room_layouts", "placed", "access_points"], ["grid_size"])
		if not issue.is_empty(): return issue
		for room_id in payload.decorations_system.get("room_layouts", {}):
			var room: Variant = payload.decorations_system.room_layouts[room_id]
			issue = _validate_fields(room, "game.decorations_system.room_layouts.%s" % String(room_id), ["placed", "access_points"], ["grid_size"])
			if not issue.is_empty(): return issue
			issue = _validate_dictionary_values(room.get("placed", {}), "game.decorations_system.room_layouts.%s.placed" % String(room_id))
			if not issue.is_empty(): return issue
	if payload.has("event_director"):
		issue = _validate_fields(payload.event_director, "game.event_director", ["last_seen_shift", "use_count"], ["essential_queue", "resolved_essential"])
		if not issue.is_empty(): return issue
		for key in ["essential_queue", "resolved_essential"]:
			issue = _validate_array_items(payload.event_director, key, "game.event_director", "string")
			if not issue.is_empty(): return issue
	if payload.has("environmental_puzzles"):
		issue = _validate_fields(payload.environmental_puzzles, "game.environmental_puzzles", ["states"], [])
		if not issue.is_empty(): return issue
		for puzzle_id in payload.environmental_puzzles.get("states", {}):
			if not payload.environmental_puzzles.states[puzzle_id] is Dictionary:
				return "game.environmental_puzzles.states.%s must be an object" % String(puzzle_id)
	if payload.has("shop_progression"):
		issue = _validate_fields(payload.shop_progression, "game.shop_progression", ["proficiency_points", "awarded_milestones", "owned_upgrades"], [])
		if not issue.is_empty(): return issue
	if payload.has("miso_companion"):
		issue = _validate_fields(payload.miso_companion, "game.miso_companion", ["unlocked_abilities", "action_shifts", "ability_shifts"], [])
		if not issue.is_empty(): return issue
	return ""

static func _validate_fields(data: Variant, context: String, dictionary_fields: Array, array_fields: Array) -> String:
	if not data is Dictionary:
		return "%s must be an object" % context
	var values: Dictionary = data
	for field in dictionary_fields:
		if values.has(field) and not values[field] is Dictionary:
			return "%s.%s must be an object" % [context, String(field)]
	for field in array_fields:
		if values.has(field) and not values[field] is Array:
			return "%s.%s must be an array" % [context, String(field)]
	return ""

static func _validate_array_items(data: Dictionary, field: String, context: String, expected_type: String) -> String:
	if not data.has(field):
		return ""
	var values: Array = data[field]
	for index in range(values.size()):
		var item: Variant = values[index]
		if expected_type == "dictionary" and not item is Dictionary:
			return "%s.%s[%d] must be an object" % [context, field, index]
		if expected_type == "string" and not item is String:
			return "%s.%s[%d] must be a string" % [context, field, index]
	return ""

static func _validate_dictionary_values(data: Variant, context: String) -> String:
	if not data is Dictionary:
		return "%s must be an object" % context
	for key in data:
		if not data[key] is Dictionary:
			return "%s.%s must be an object" % [context, String(key)]
	return ""

static func _validate_ending_memory_snapshots(story: Dictionary) -> String:
	var snapshots: Variant = story.get("ending_memories", {})
	if not snapshots is Dictionary or snapshots.is_empty():
		return ""
	if String(story.get("selected_ending", "")) != "gentle_goodbye":
		return "game.story.ending_memories are only valid for the Gentle Goodbye ending"
	var source := FileAccess.open("res://data/ending_memories.json", FileAccess.READ)
	if source == null:
		return "game.story.ending_memories could not be checked against their authored definitions"
	var parsed: Variant = JSON.parse_string(source.get_as_text())
	source.close()
	if not parsed is Dictionary or not parsed.get("ending_memories", []) is Array:
		return "game.story.ending_memories could not be checked against their authored definitions"
	var definitions: Dictionary = {}
	for definition_value in parsed.get("ending_memories", []):
		if not definition_value is Dictionary:
			return "data.ending_memories contains a malformed definition"
		var definition: Dictionary = definition_value
		var definition_id := String(definition.get("id", ""))
		if definition_id.is_empty() or definitions.has(definition_id):
			return "data.ending_memories contains a missing or duplicate ID"
		definitions[definition_id] = definition
	for memory_id_value in snapshots:
		if not memory_id_value is String or not definitions.has(String(memory_id_value)):
			return "game.story.ending_memories.%s is not an authored memory" % String(memory_id_value)
		var memory_id := String(memory_id_value)
		var memory: Dictionary = snapshots[memory_id_value]
		var definition: Dictionary = definitions[memory_id]
		for field in ["id", "activity_id", "title", "text"]:
			if not memory.has(field) or not memory[field] is String or String(memory[field]).is_empty():
				return "game.story.ending_memories.%s.%s must be nonempty text" % [memory_id, field]
		if String(memory.id) != memory_id or String(memory.activity_id) != String(definition.get("activity_id", "")):
			return "game.story.ending_memories.%s does not match its authored identity" % memory_id
	return ""

static func _read_staged_candidate() -> Dictionary:
	for entry in [
		{"path": TEMP_PATH, "status": "recovered_temp", "label": "verified temporary save"},
		{"path": RECOVERY_PATH, "status": "recovered_copy", "label": "preserved verified recovery copy"},
		{"path": RECOVERY_TEMP_PATH, "status": "recovered_copy", "label": "verified recovery copy awaiting promotion"},
		{"path": RECOVERY_STAGE_PATH, "status": "recovered_copy", "label": "verified prior recovery copy"},
		{"path": STAGE_PATH, "status": "recovered_stage", "label": "verified rollback save"},
		{"path": BACKUP_TEMP_PATH, "status": "recovered_backup", "label": "verified backup candidate"},
		{"path": BACKUP_STAGE_PATH, "status": "recovered_backup", "label": "verified backup rollback save"}
	]:
		var candidate := _read_path(String(entry.path))
		if String(candidate.get("status", "")) == "future_version":
			return {"ok": false, "status": "future_version", "error": String(candidate.get("error", "A staged save was created by a newer game version."))}
		if bool(candidate.get("ok", false)):
			return {"ok": true, "status": String(entry.status), "payload": candidate.payload, "error": "The primary save was unavailable; restored the %s. The unreadable primary remains preserved until a new save succeeds." % String(entry.label)}
	return {"ok": false, "status": "no_valid_staged_save", "error": "No verified temporary or rollback save was available."}

static func _preserve_recovered_temp() -> bool:
	if not FileAccess.file_exists(TEMP_PATH):
		_last_read_status = "corrupt"
		_last_read_error = "The verified temporary recovery copy is no longer available; no new save was written."
		return false
	var source := _read_path(TEMP_PATH)
	if not bool(source.get("ok", false)):
		_last_read_status = "corrupt"
		_last_read_error = "The temporary recovery copy could not be verified again; no new save was written."
		return false
	for preserved_path in [RECOVERY_PATH, RECOVERY_TEMP_PATH, RECOVERY_STAGE_PATH]:
		if not FileAccess.file_exists(preserved_path):
			continue
		var preserved := _read_path(preserved_path)
		if String(preserved.get("status", "")) == "future_version" or not bool(preserved.get("ok", false)):
			_last_read_error = "An existing recovery artifact could not be verified or uses a newer schema; it was preserved and no new save was written."
			return false
	if not _write_text(RECOVERY_TEMP_PATH, FileAccess.get_file_as_string(TEMP_PATH)):
		_last_read_error = "The temporary recovery copy could not be preserved; no new save was written."
		return false
	var copy := _read_path(RECOVERY_TEMP_PATH)
	if not bool(copy.get("ok", false)) or int(copy.get("version", -1)) != int(source.get("version", -2)):
		_last_read_error = "The temporary recovery copy could not be verified after preservation; no new save was written."
		return false
	if not _replace_atomically(RECOVERY_TEMP_PATH, RECOVERY_PATH, RECOVERY_STAGE_PATH):
		_last_read_error = "The temporary recovery copy could not be committed; no new save was written."
		return false
	return true

static func _archive_unreadable_primary() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var archive_path := "user://moonmart_save_unreadable_%d_%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(archive_path))
	if error != OK:
		_last_read_status = "corrupt"
		_last_read_error = "The unreadable primary save could not be archived; no replacement was written."
		return false
	return true

static func _has_staged_save_artifact() -> bool:
	return FileAccess.file_exists(TEMP_PATH) or FileAccess.file_exists(STAGE_PATH) or FileAccess.file_exists(RECOVERY_PATH) or FileAccess.file_exists(RECOVERY_TEMP_PATH) or FileAccess.file_exists(RECOVERY_STAGE_PATH) or FileAccess.file_exists(BACKUP_TEMP_PATH) or FileAccess.file_exists(BACKUP_STAGE_PATH)

static func _has_any_save_artifact() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH) or FileAccess.file_exists(TEMP_PATH) or FileAccess.file_exists(STAGE_PATH) or FileAccess.file_exists(RECOVERY_PATH) or FileAccess.file_exists(RECOVERY_TEMP_PATH) or FileAccess.file_exists(RECOVERY_STAGE_PATH) or FileAccess.file_exists(BACKUP_TEMP_PATH) or FileAccess.file_exists(BACKUP_STAGE_PATH)

static func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	return write_error == OK

static func _replace_atomically(source_path: String, destination_path: String, rollback_path: String) -> bool:
	var source_absolute := ProjectSettings.globalize_path(source_path)
	var destination_absolute := ProjectSettings.globalize_path(destination_path)
	var rollback_absolute := ProjectSettings.globalize_path(rollback_path)
	var had_destination := FileAccess.file_exists(destination_path)
	if had_destination:
		_remove_file(rollback_path)
		if DirAccess.rename_absolute(destination_absolute, rollback_absolute) != OK:
			return false
	if DirAccess.rename_absolute(source_absolute, destination_absolute) != OK:
		if had_destination and FileAccess.file_exists(rollback_path):
			DirAccess.rename_absolute(rollback_absolute, destination_absolute)
		return false
	if had_destination:
		_remove_file(rollback_path)
	return true

static func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func _migrate_v0(legacy: Dictionary) -> Dictionary:
	# Early prototypes wrote the state without a version envelope. Preserve it
	# and fill newly introduced fields through the v1 migration.
	return _migrate_v1(legacy)

static func _migrate_v1(previous: Dictionary) -> Dictionary:
	var payload := previous.duplicate(true)
	var inventory: Dictionary = payload.get("inventory", {}).duplicate(true)
	inventory["transactions"] = inventory.get("transactions", [])
	inventory["prepared_items"] = inventory.get("prepared_items", {})
	payload["inventory"] = inventory
	var customers: Dictionary = payload.get("customers", {}).duplicate(true)
	customers["rng_state"] = customers.get("rng_state", 0)
	customers["active_shift"] = customers.get("active_shift", payload.get("shift_number", 0))
	customers["spawn_timer"] = customers.get("spawn_timer", 14.0)
	payload["customers"] = customers
	return payload

static func _migrate_v2(previous: Dictionary) -> Dictionary:
	var payload := previous.duplicate(true)
	payload["pending_optional_events"] = payload.get("pending_optional_events", [])
	payload["optional_event_timer"] = float(payload.get("optional_event_timer", 38.0))
	return payload

static func _migrate_v3(previous: Dictionary) -> Dictionary:
	var payload := previous.duplicate(true)
	payload["miso_companion"] = payload.get("miso_companion", {})
	payload["cleaning_actions_this_shift"] = payload.get("cleaning_actions_this_shift", {})
	return payload
