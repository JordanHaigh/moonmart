extends SceneTree

const EN_UI_PATH := "res://data/locales/en/ui.json"
const ES_UI_PATH := "res://data/locales/es/ui.json"
const SOURCE_DIALOGUE_PATH := "res://data/dialogue/story.json"
const ES_DIALOGUE_PATH := "res://data/locales/es/dialogue.json"

var _checks := 0
var _failures: Array[String] = []
var _placeholder_regex := RegEx.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_placeholder_regex.compile("\\{[^{}]+\\}|%s")
	var english_ui := _read_json(EN_UI_PATH)
	var spanish_ui := _read_json(ES_UI_PATH)
	var source_ui: Variant = english_ui.get("strings", null)
	var translated_ui: Variant = spanish_ui.get("strings", null)
	_expect(int(english_ui.get("schema_version", -1)) == 1, "English UI catalog schema is current")
	_expect(int(spanish_ui.get("schema_version", -1)) == 1, "Spanish UI catalog schema is current")
	_expect(source_ui is Dictionary and translated_ui is Dictionary, "both UI catalogs contain strings dictionaries")
	if source_ui is Dictionary and translated_ui is Dictionary:
		_assert_same_keys(source_ui, translated_ui, "UI")
		_expect(source_ui.size() == 1499, "English UI catalog contains the audited 1,499 keys")
		_assert_collectibles(source_ui, translated_ui)
		for key_value in source_ui.keys():
			var key := String(key_value)
			var source_value: Variant = source_ui[key]
			var translated_value: Variant = translated_ui.get(key, null)
			_expect(source_value is String and translated_value is String, "UI value is text: %s" % key)
			if source_value is String and translated_value is String:
				_expect(not String(translated_value).strip_edges().is_empty(), "Spanish UI value is nonempty: %s" % key)
				_assert_placeholders(String(source_value), String(translated_value), "UI %s" % key)

	var source_dialogue := _read_json(SOURCE_DIALOGUE_PATH)
	var translated_dialogue := _read_json(ES_DIALOGUE_PATH)
	for section in ["story_lines", "ordinary_lines", "conversations"]:
		var source_section: Variant = source_dialogue.get(section, null)
		var translated_section: Variant = translated_dialogue.get(section, null)
		_expect(source_section is Dictionary and translated_section is Dictionary, "dialogue section exists: %s" % section)
		if not source_section is Dictionary or not translated_section is Dictionary:
			continue
		_assert_same_keys(source_section, translated_section, section)
		if section == "story_lines":
			_expect(source_section.size() == 37, "source has all 37 story summaries")
		elif section == "ordinary_lines":
			_expect(source_section.size() == 31, "source has all 31 everyday visitor lines")
		elif section == "conversations":
			_expect(source_section.size() == 117, "source has all 117 conversations")
		if section == "conversations":
			_assert_conversations(source_section, translated_section)
		else:
			_assert_text_entries(source_section, translated_section, section)

	var source_fallback: Variant = source_dialogue.get("default_ordinary_line", null)
	var translated_fallback: Variant = translated_dialogue.get("default_ordinary_line", null)
	_expect(source_fallback is String and translated_fallback is String, "ordinary fallback line exists in both catalogs")
	if source_fallback is String and translated_fallback is String:
		_assert_placeholders(String(source_fallback), String(translated_fallback), "ordinary fallback")

	if _failures.is_empty():
		print("Localization catalog validation passed: %d checks (%d UI keys, 37 story lines, 31 ordinary lines, 117 conversations)." % [_checks, (source_ui as Dictionary).size()])
	else:
		for failure in _failures:
			push_error(failure)
		print("Localization catalog validation failed: %d of %d checks." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_expect(false, "catalog file exists: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(parsed is Dictionary, "catalog JSON parses: %s" % path)
	return parsed if parsed is Dictionary else {}

func _assert_same_keys(source: Dictionary, translated: Dictionary, label: String) -> void:
	var source_keys: Array[String] = []
	var translated_keys: Array[String] = []
	for key in source.keys():
		source_keys.append(String(key))
	for key in translated.keys():
		translated_keys.append(String(key))
	source_keys.sort()
	translated_keys.sort()
	_expect(source_keys == translated_keys, "%s IDs match exactly" % label)

func _assert_text_entries(source: Dictionary, translated: Dictionary, label: String) -> void:
	for key_value in source.keys():
		var key := String(key_value)
		var source_value: Variant = source[key]
		var translated_value: Variant = translated.get(key, null)
		_expect(source_value is String and translated_value is String, "%s entry is text: %s" % [label, key])
		if source_value is String and translated_value is String:
			_assert_placeholders(String(source_value), String(translated_value), "%s %s" % [label, key])

func _assert_conversations(source: Dictionary, translated: Dictionary) -> void:
	for id_value in source.keys():
		var conversation_id := String(id_value)
		var source_conversation: Variant = source[id_value]
		var translated_conversation: Variant = translated.get(conversation_id, null)
		_expect(source_conversation is Dictionary and translated_conversation is Dictionary, "conversation object exists: %s" % conversation_id)
		if not source_conversation is Dictionary or not translated_conversation is Dictionary:
			continue
		var source_speaker := String(source_conversation.get("speaker", ""))
		var translated_speaker := String(translated_conversation.get("speaker", ""))
		_expect(not source_speaker.is_empty() and not translated_speaker.is_empty(), "conversation has a speaker label: %s" % conversation_id)
		var source_lines: Variant = source_conversation.get("lines", null)
		var translated_lines: Variant = translated_conversation.get("lines", null)
		_expect(source_lines is Array and translated_lines is Array, "conversation lines are arrays: %s" % conversation_id)
		if not source_lines is Array or not translated_lines is Array:
			continue
		_expect(source_lines.size() == translated_lines.size(), "conversation line count is preserved: %s" % conversation_id)
		for line_index in range(mini(source_lines.size(), translated_lines.size())):
			var source_line: Variant = source_lines[line_index]
			var translated_line: Variant = translated_lines[line_index]
			_expect(source_line is String and translated_line is String, "conversation line is text: %s[%d]" % [conversation_id, line_index])
			if source_line is String and translated_line is String:
				_assert_placeholders(String(source_line), String(translated_line), "conversation %s[%d]" % [conversation_id, line_index])

func _assert_placeholders(source: String, translated: String, label: String) -> void:
	var source_matches := _placeholder_regex.search_all(source)
	var translated_matches := _placeholder_regex.search_all(translated)
	var source_tokens: Array[String] = []
	var translated_tokens: Array[String] = []
	for match in source_matches:
		source_tokens.append(match.get_string())
	for match in translated_matches:
		translated_tokens.append(match.get_string())
	_expect(source_tokens == translated_tokens, "placeholder order and count match: %s" % label)

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append("FAIL: " + message)

func _assert_collectibles(source_ui: Dictionary, translated_ui: Dictionary) -> void:
	var collectibles: Array = _read_json("res://data/collectibles.json").get("collectibles", [])
	var locations := {}
	for location in _read_json("res://data/locations.json").get("locations", []):
		locations[String(location.get("id", ""))] = location
	# These inspect or scene targets are handled by game code (shop window; noticeboard mapped to town_map; the hidden room's MemoryWall marker) rather than listed as location interactables.
	var legacy_targets := {"moonmart_milk_token": "window", "bellwether_blue_button": "town_map", "midnight_room_memory_bead": "memory_wall"}
	var seen_targets := {}
	_expect(collectibles.size() == 11, "collectible catalog holds all 11 keepsakes")
	for collectible in collectibles:
		var collectible_id := String(collectible.get("id", ""))
		for suffix in ["name", "description"]:
			var key := "collectible.%s.%s" % [collectible_id, suffix]
			_expect(source_ui.has(key) and translated_ui.has(key), "collectible text exists in both languages: %s" % key)
		var location_id := String(collectible.get("location_id", ""))
		var target_id := String(collectible.get("target_id", ""))
		_expect(locations.has(location_id) and (Array(locations.get(location_id, {}).get("interactables", [])).has(target_id) or legacy_targets.get(collectible_id, "") == target_id), "collectible target is an interactable of its location: %s" % collectible_id)
		var pair := "%s/%s" % [location_id, target_id]
		_expect(not seen_targets.has(pair), "one keepsake per inspect target: %s" % pair)
		seen_targets[pair] = true

