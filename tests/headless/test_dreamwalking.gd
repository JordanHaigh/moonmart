extends Node

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main game scene loads for the Dreamwalking gameplay test")
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
	game.save_recovery_required = true # Keep this isolated headless test from touching the player's save.
	game.shift_number = 4
	game.story.flags.clear()
	game.miso_companion.sync_story_flags(game.story.flags)
	_expect(not game.miso_companion.ability_available("dreamwalking"), "fresh companion remains locked until its story milestone")
	var locked: Dictionary = game.start_miso_dreamwalking()
	_expect(not bool(locked.get("ok", false)), "Dreamwalking cannot start before the Guardian's Truth milestone")
	game.story.flags["miso_guardian_truth"] = true
	game.miso_companion.sync_story_flags(game.story.flags)
	_expect(game.miso_companion.ability_available("dreamwalking"), "Guardian's Truth unlocks Dreamwalking")
	scene.call("_open_companion_panel")
	var enter_dream_input := InputEventAction.new()
	enter_dream_input.action = "ui_select_7"
	enter_dream_input.pressed = true
	scene.call("_unhandled_input", enter_dream_input)
	_expect(String(game.miso_dream_sequence.current_beat().get("id", "")) == "lamp_room" and String(scene.get("active_panel")) == "dream", "the companion ability opens the authored dream panel at its first beat")
	_expect(game.miso_companion.ability_shifts.get("dreamwalking", 0) == 4, "starting a dream consumes the ability for this shift")
	_expect(not game.story.flags.has("miso_dreamwalking_complete"), "the optional memory is not granted on entry")
	var invalid: Dictionary = game.choose_miso_dream_choice("not_a_real_choice")
	_expect(not bool(invalid.get("ok", false)) and String(game.miso_dream_sequence.current_beat().get("id", "")) == "lamp_room", "invalid choices do not advance the sequence")
	var kettle_choice_input := InputEventAction.new()
	kettle_choice_input.action = "ui_select_2"
	kettle_choice_input.pressed = true
	scene.call("_unhandled_input", kettle_choice_input)
	_expect(String(game.miso_dream_sequence.current_beat().get("id", "")) == "ledger", "the localized second choice leads through the gameplay panel to the ledger beat")
	# Save-shaped state round-trips through the same MoonmartGame import used by normal saves.
	var saved_payload := {"shift_number":game.shift_number, "shift_status":"between_shifts", "story":game.story.to_save(), "miso_companion":game.miso_companion.export_state(), "miso_dream_sequence":game.miso_dream_sequence.export_state()}
	var resumed: Variant = game
	resumed.load_state(saved_payload)
	_expect(resumed.miso_dream_sequence.active and String(resumed.miso_dream_sequence.current_beat().get("id", "")) == "ledger", "mid-dream save resumes at the same authored beat")
	_expect(bool(resumed.start_miso_dreamwalking().get("resumed", false)), "re-entering the ability resumes an active dream without consuming it again")
	var second_choice: Dictionary = resumed.choose_miso_dream_choice("read_margin")
	_expect(bool(second_choice.get("ok", false)) and String(second_choice.get("beat", {}).get("id", "")) == "dawn", "the ledger beat offers a second distinct choice")
	var final_choice: Dictionary = resumed.choose_miso_dream_choice("keep_warmth")
	_expect(bool(final_choice.get("ok", false)) and bool(final_choice.get("ready_to_wake", false)), "the final authored beat offers a meaningful memory choice")
	_expect(not resumed.story.flags.has("miso_dreamwalking_complete"), "choosing an ending does not grant its memory before waking")
	var woke: Dictionary = resumed.wake_from_miso_dream()
	_expect(bool(woke.get("ok", false)) and String(woke.get("memory_id", "")) == "miso_dream_warmth", "waking returns the selected optional memory")
	_expect(bool(resumed.story.flags.get("miso_dreamwalking_complete", false)) and String(resumed.story.flags.get("miso_dream_memory", "")) == "miso_dream_warmth", "waking stores the optional completion and memory flags")
	_expect(not resumed.miso_dream_sequence.active and not resumed.miso_dream_sequence.wake().get("ok", false), "waking closes the dream and cannot be repeated")
	_expect(not bool(resumed.start_miso_dreamwalking().get("ok", false)), "the ability cannot restart twice in the same shift")
	_expect(resumed.story.completed_events.is_empty() and resumed.story.queued_events.is_empty(), "the optional vignette does not complete or queue essential story events")
	if failures.is_empty():
		print("Dreamwalking gameplay checks passed: %d checks." % checks)
	else:
		for failure in failures:
			push_error(failure)
		print("Dreamwalking gameplay checks failed: %d of %d." % [failures.size(), checks])
	scene.call("_stop_audio_players")
	scene.free()
	await get_tree().create_timer(0.25, true, false, true).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
