extends Node

const MoonmartGameScript = preload("res://scripts/core/moonmart_game.gd")

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = MoonmartGameScript.new()
	add_child(game)
	await get_tree().process_frame
	game.save_recovery_required = true # Keep the focused gameplay test from touching user:// saves.
	game.story.chapter = 1
	game.story.clues.clear()
	game.story.flags.clear()
	game.story.flags["pip_first_memory"] = true
	game.world_map.current_location = "moonmart"
	game.miso_companion.sync_story_flags(game.story.flags)
	game.shift_number = 1

	var guidance: Dictionary = game.use_miso_ability("hidden_paw", {"back_door":"back_door"})
	_expect(bool(guidance.get("ok", false)), "Hidden Paw activates for an eligible clue in the current location")
	_expect(String(guidance.get("clue_id", "")) == "door_in_the_wall", "Hidden Paw picks the reachable overlooked back-door clue")
	_expect(String(guidance.get("target_id", "")) == "back_door" and String(guidance.get("marker_id", "")) == "back_door", "guidance retains its real inspect target and marker")
	_expect(not game.story.clues.has("door_in_the_wall") and not bool(game.story.flags.get("hidden_midnight_room_found", false)), "using Hidden Paw does not claim the clue or grant its story flag")
	_expect(not game.miso_hidden_paw_guidance.is_empty(), "the in-world guide target remains active until inspection")
	var saved_guidance: Dictionary = game.miso_hidden_paw_guidance.duplicate(true)
	game.load_state({"story":game.story.to_save(), "miso_companion":game.miso_companion.export_state(), "world_system":game.world_map.export_state(), "miso_hidden_paw_guidance":saved_guidance})
	_expect(String(game.miso_hidden_paw_guidance.get("target_id", "")) == "back_door" and not game.story.clues.has("door_in_the_wall"), "saved Hidden Paw guidance resumes without awarding the clue early")

	var inspection := String(game.inspect_object("back_door"))
	_expect(not inspection.is_empty() and game.story.clues.has("door_in_the_wall"), "normal back-door inspection reveals the guided clue")
	_expect(bool(game.story.flags.get("hidden_midnight_room_found", false)), "the physical inspection grants the clue's authored story flag")
	_expect(game.miso_hidden_paw_guidance.is_empty(), "successful inspection clears the guide target")
	_expect(game.mysteries.discovered_clues.has("door_in_the_wall"), "the inspected clue is added to the mystery journal")

	game.shift_number = 2
	var no_target: Dictionary = game.use_miso_ability("hidden_paw", {})
	_expect(not bool(no_target.get("ok", false)) and String(no_target.get("reason", "")) == "no_reachable_clue", "Hidden Paw reports no usable target when the current scene has none")
	_expect(int(game.miso_companion.ability_shifts.get("hidden_paw", -1)) == 1, "a no-target attempt does not consume the ability for the shift")

	game.free()
	if _failures.is_empty():
		print("Hidden Paw gameplay checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Hidden Paw gameplay checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
