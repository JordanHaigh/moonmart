extends Node

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main game scene loads for Memory Echo gameplay coverage")
	if packed == null:
		get_tree().quit(1)
		return
	var scene := packed.instantiate()
	get_tree().root.add_child(scene)
	for _frame in range(20):
		await get_tree().process_frame
	var game: Variant = scene.get("game")
	_expect(game != null, "main scene creates the MoonmartGame controller")
	if game == null:
		get_tree().quit(1)
		return
	game.save_recovery_required = true # Prevent this test from writing to the player's save.
	game.shift_number = 4
	game.story.flags.clear()
	game.miso_companion.unlocked_abilities.clear()
	game.miso_companion.ability_shifts.clear()
	game.miso_companion.sync_story_flags(game.story.flags)
	_expect(not game.miso_companion.ability_available("memory_echo"), "Memory Echo remains locked before the manifest milestone")
	var locked: Dictionary = game.use_miso_ability("memory_echo")
	_expect(not bool(locked.get("ok", false)) and String(locked.get("reason", "")) == "locked", "locked Memory Echo has no effect")
	game.story.flags["passenger_manifest_read"] = true
	game.miso_companion.sync_story_flags(game.story.flags)
	_expect(game.miso_companion.ability_available("memory_echo"), "reading the passenger manifest unlocks Memory Echo")
	scene.call("_open_companion_panel")
	var use_echo_input := InputEventAction.new()
	use_echo_input.action = "ui_select_8"
	use_echo_input.pressed = true
	scene.call("_unhandled_input", use_echo_input)
	var first_memory_flag := "miso_memory_echo_platform_lamp"
	_expect(bool(game.story.flags.get(first_memory_flag, false)), "the gameplay button records an authored first echo separately from clue IDs")
	_expect(String(scene.get("side_label").text).contains("The platform lamp") and String(scene.get("side_label").text).contains("frightened traveler"), "the ability reveals its authored fragment in the localized companion panel")
	_expect(game.journal_text().contains("Miso · remembered moments") and game.journal_text().contains("The platform lamp"), "revealed Memory Echo text appears in the optional journal section")
	var used_shift: Dictionary = game.miso_companion.ability_shifts
	_expect(int(used_shift.get("memory_echo", 0)) == 4, "revealing a fragment consumes Memory Echo for the current shift")
	var saved_payload := {"shift_number":game.shift_number, "shift_status":"between_shifts", "story":game.story.to_save(), "miso_companion":game.miso_companion.export_state()}
	game.load_state(saved_payload)
	_expect(bool(game.story.flags.get(first_memory_flag, false)) and game.journal_text().contains("The platform lamp"), "the optional echo and its journal entry survive save/load")
	var repeat: Dictionary = game.use_miso_ability("memory_echo")
	_expect(not bool(repeat.get("ok", false)) and String(repeat.get("reason", "")) == "already_used", "the revealed memory cannot be repeated during the same shift")
	game.shift_number = 5
	var next_shift: Dictionary = game.use_miso_ability("memory_echo")
	_expect(bool(next_shift.get("ok", false)) and String(next_shift.get("memory_echo_id", "")) == "the_last_train", "the next shift can reveal a different authored fragment")
	_expect(not game.story.flags.has("miso_memory_echo"), "Memory Echo does not overwrite or conflate the existing hidden-clue ID")
	_expect(game.story.completed_events.is_empty() and game.story.queued_events.is_empty(), "optional echo memories never complete or queue essential story events")
	if failures.is_empty():
		print("Memory Echo gameplay checks passed: %d checks." % checks)
	else:
		for failure in failures:
			push_error(failure)
		print("Memory Echo gameplay checks failed: %d of %d." % [failures.size(), checks])
	scene.call("_stop_audio_players")
	scene.free()
	await get_tree().create_timer(0.25, true, false, true).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
