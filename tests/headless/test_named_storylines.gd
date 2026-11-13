extends SceneTree

const MoonmartGameScript = preload("res://scripts/core/moonmart_game.gd")

# Characters whose opening conversation is wired directly in MoonmartGame.interact();
# every other routed character must reach its storyline through the route fallback.
const DIRECT_KEYS := ["agnes", "pip", "fern", "lucien", "wren", "conductor", "elias", "mara", "osric"]

var _checks := 0
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var dialogue := _read_json("res://data/dialogue/story.json")
	var routes: Dictionary = dialogue.get("conversation_routes", {})
	var conversations: Dictionary = dialogue.get("conversations", {})
	var characters := {}
	for row in _read_json("res://data/characters.json").get("characters", []):
		characters[String(row.get("id", ""))] = true
	var routed_named := 0
	for character_id in routes:
		_expect(characters.has(character_id), "route belongs to a named character: %s" % character_id)
		for variant in routes[character_id].get("variants", []):
			_expect(conversations.has(String(variant.get("conversation_id", ""))), "route conversation exists: %s/%s" % [character_id, variant.get("conversation_id", "")])
		routed_named += 1
	_expect(routed_named == characters.size(), "all %d named characters have a storyline route" % characters.size())

	var game := MoonmartGameScript.new()
	root.add_child(game)
	await process_frame
	for character_id in routes:
		if DIRECT_KEYS.has(character_id):
			continue
		var variants: Array = routes[character_id].get("variants", [])
		var expected: Array[String] = []
		for variant in variants:
			for flag in variant.get("requires_flags", []):
				game.story.flags[String(flag)] = true
			for line in conversations[String(variant.get("conversation_id", ""))].get("lines", []):
				expected.append(String(line))
		var customer: Dictionary = game.customers.call("_make_customer", String(character_id), true, {})
		customer["state"] = "BROWSING"
		game.customers.active.append(customer)
		var seen: Array[String] = []
		for index in range(expected.size()):
			game.interact(String(character_id))
			seen.append(String(game.last_message))
		var in_order := true
		for index in range(expected.size()):
			if not seen[index].ends_with(expected[index]):
				in_order = false
		_expect(in_order, "%s plays all %d storyline lines in order through interact()" % [character_id, expected.size()])
		game.customers.active.clear()
	game.queue_free()
	if _failures.is_empty():
		print("Named storyline validation passed: %d checks." % _checks)
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		printerr("Named storyline validation failed: %d of %d checks." % [_failures.size(), _checks])
		quit(1)

func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
