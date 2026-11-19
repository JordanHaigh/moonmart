extends Node

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main game scene loads for Guardian's Purr gameplay coverage")
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
	game.save_recovery_required = true # Keep this test from writing to the player's save.
	game.shift_number = 4
	game.story.flags.clear()
	game.miso_companion.unlocked_abilities.clear()
	game.miso_companion.ability_shifts.clear()
	game.anomaly_disturbances.clear()
	game.miso_companion.sync_story_flags(game.story.flags)
	_expect(not game.miso_companion.ability_available("guardian_purr"), "Guardian's Purr stays locked before Miso's Guardian Truth")
	var locked: Dictionary = game.use_miso_ability("guardian_purr")
	_expect(not bool(locked.get("ok", false)) and String(locked.get("reason", "")) == "locked", "a locked Guardian's Purr cannot affect disturbances")
	game.story.flags["miso_guardian_truth"] = true
	game.miso_companion.sync_story_flags(game.story.flags)
	_expect(game.miso_companion.ability_available("guardian_purr") and not game.story.flags.has("boundary_stabilized"), "Guardian Truth unlocks the ability before the ending milestone")
	var no_target: Dictionary = game.use_miso_ability("guardian_purr")
	_expect(not bool(no_target.get("ok", false)) and String(no_target.get("reason", "")) == "no_active_anomaly", "no-target use returns a clear optional result")
	_expect(not game.miso_companion.ability_shifts.has("guardian_purr"), "no-target use does not consume the once-per-shift ability")
	game._deliver_optional_event({"id":"miso_purrs"})
	_expect(game.anomaly_disturbances.is_empty(), "ordinary ambient events do not create disturbances")
	scene.call("_dismiss_message")
	scene.call("_open_companion_panel")
	var no_target_input := InputEventAction.new()
	no_target_input.action = "ui_select_9"
	no_target_input.pressed = true
	scene.call("_unhandled_input", no_target_input)
	_expect(String(scene.get("side_label").text).contains("no unsettled anomaly") and not game.miso_companion.ability_shifts.has("guardian_purr"), "the localized companion panel offers no-target feedback without spending the ability")
	game._deliver_optional_event({"id":"flicker_lights"})
	_expect(game.anomaly_disturbances.size() == 1 and String(game.anomaly_disturbances[0].get("event_id", "")) == "flicker_lights", "anomaly delivery records an unsettled disturbance")
	game._deliver_optional_event({"id":"flicker_lights"})
	_expect(game.anomaly_disturbances.size() == 1, "redelivering the same active anomaly does not duplicate its disturbance")
	game._deliver_optional_event({"id":"receipt_whispers"})
	_expect(game.anomaly_disturbances.size() == 2 and String(game._oldest_anomaly_disturbance().get("event_id", "")) == "flicker_lights", "distinct anomalies queue in delivery order")
	var harmony_before := int(game.shop_progression.harmony)
	var stabilize_input := InputEventAction.new()
	stabilize_input.action = "ui_select_9"
	stabilize_input.pressed = true
	scene.call("_unhandled_input", stabilize_input)
	_expect(game.anomaly_disturbances.size() == 1 and String(game.anomaly_disturbances[0].get("event_id", "")) == "receipt_whispers", "selecting Guardian's Purr stabilizes the oldest exact anomaly")
	_expect(game.shop_progression.harmony == harmony_before + 2 and String(scene.get("side_label").text).contains("The lights dim"), "successful stabilization keeps the harmony reward and names the changed anomaly")
	var repeat_same_shift: Dictionary = game.use_miso_ability("guardian_purr")
	_expect(not bool(repeat_same_shift.get("ok", false)) and String(repeat_same_shift.get("reason", "")) == "already_used" and game.anomaly_disturbances.size() == 1, "a second same-shift use cannot stabilize another record")
	var saved_payload := {"shift_number":game.shift_number, "shift_status":"between_shifts", "story":game.story.to_save(), "miso_companion":game.miso_companion.export_state(), "anomaly_disturbances":game.anomaly_disturbances.duplicate(true)}
	game.load_state(saved_payload)
	_expect(game.anomaly_disturbances.size() == 1 and String(game._oldest_anomaly_disturbance().get("event_id", "")) == "receipt_whispers", "unsettled anomaly records survive save and load")
	var repeat_after_load: Dictionary = game.use_miso_ability("guardian_purr")
	_expect(not bool(repeat_after_load.get("ok", false)) and String(repeat_after_load.get("reason", "")) == "already_used", "the once-per-shift limit survives save and load")
	game.shift_number = 5
	var next_shift_input := InputEventAction.new()
	next_shift_input.action = "ui_select_9"
	next_shift_input.pressed = true
	scene.call("_unhandled_input", next_shift_input)
	_expect(game.anomaly_disturbances.is_empty() and String(scene.get("side_label").text).contains("A receipt rustles"), "the next shift can stabilize the next exact anomaly")
	_expect(not game.story.flags.has("boundary_stabilized") and game.story.completed_events.is_empty() and game.story.queued_events.is_empty() and game.world_map.ending_id.is_empty(), "Guardian's Purr remains optional and never changes essential progression")
	if failures.is_empty():
		print("Guardian's Purr gameplay checks passed: %d checks." % checks)
	else:
		for failure in failures:
			push_error(failure)
		print("Guardian's Purr gameplay checks failed: %d of %d." % [failures.size(), checks])
	scene.call("_stop_audio_players")
	scene.queue_free()
	for _frame in range(4):
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
