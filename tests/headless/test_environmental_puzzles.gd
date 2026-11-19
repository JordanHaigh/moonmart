extends Node

const GameScript = preload("res://scripts/core/moonmart_game.gd")
const PuzzleScript = preload("res://scripts/systems/environmental_puzzle_manager.gd")
const SaveManager = preload("res://scripts/core/save_manager.gd")

const FIXED_SAVE_PATHS: Array[String] = [
	"user://moonmart_save.json",
	"user://moonmart_save.tmp",
	"user://moonmart_save.replace",
	"user://moonmart_save.recovered",
	"user://moonmart_save.recovered.tmp",
	"user://moonmart_save.recovered.replace",
	"user://moonmart_save.bak",
	"user://moonmart_save.bak.tmp",
	"user://moonmart_save.bak.replace"
]

var _checks := 0
var _failures: Array[String] = []
var _completion_count := 0
var _completed_ids: Array[String] = []
var _game: Node
var _puzzles: Array[Dictionary] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _preflight_isolated_save_paths():
		get_tree().quit(2)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/environmental_puzzles.json"))
	if not parsed is Dictionary:
		_expect(false, "environmental puzzle catalog parses as a dictionary")
	else:
		for value in parsed.get("puzzles", []):
			if value is Dictionary:
				_puzzles.append(value)
	_expect(_puzzles.size() == 7, "seven authored environmental puzzles are loaded")
	_game = GameScript.new()
	add_child(_game)
	await get_tree().process_frame
	if _game != null:
		_game.environmental_puzzle_completed.connect(_on_puzzle_completed)
		_test_fresh_targets_are_locked()
		_test_all_puzzles()
		_test_game_save_round_trip()
	if is_instance_valid(_game):
		_game.free()
	_cleanup_owned_save_paths()
	if _failures.is_empty():
		print("Environmental puzzle checks passed: %d checks, %d puzzles." % [_checks, _puzzles.size()])
	else:
		for failure in _failures:
			push_error(failure)
		printerr("Environmental puzzle checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)

func _preflight_isolated_save_paths() -> bool:
	for path in FIXED_SAVE_PATHS:
		if FileAccess.file_exists(path):
			push_error("Refusing to run environmental puzzle fixtures over existing save data: %s" % path)
			return false
	var directory := DirAccess.open("user://")
	if directory == null:
		# A fresh isolated Godot profile may not have created user:// yet.
		# FileAccess checks above already confirmed that no fixed save artifact exists.
		return true
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if filename.begins_with("moonmart_save"):
			directory.list_dir_end()
			push_error("Refusing to run environmental puzzle fixtures with pre-existing save artifacts in user://")
			return false
		filename = directory.get_next()
	directory.list_dir_end()
	return true

func _test_fresh_targets_are_locked() -> void:
	_expect(_game.environmental_puzzles.definitions.size() == _puzzles.size(), "MoonmartGame loads every puzzle definition")
	for puzzle in _puzzles:
		var puzzle_id := String(puzzle.get("id", ""))
		var target := String(puzzle.get("target", ""))
		_expect(not puzzle_id.is_empty() and not target.is_empty(), "every puzzle has an ID and target")
		_expect(_game.environmental_puzzle_for_target(target).is_empty(), "%s stays hidden until its story context is available" % puzzle_id)
	_expect(_game.environmental_puzzle_for_target("not_a_puzzle_target").is_empty(), "unknown target does not open a puzzle")

func _test_all_puzzles() -> void:
	for puzzle in _puzzles:
		var puzzle_id := String(puzzle.get("id", ""))
		var target := String(puzzle.get("target", ""))
		for required_flag in puzzle.get("requires_flags", []):
			_game.story.flags[String(required_flag)] = true
		var opened: Dictionary = _game.environmental_puzzle_for_target(target)
		_expect(String(opened.get("id", "")) == puzzle_id, "%s opens at its authored target" % puzzle_id)
		_expect(not bool(opened.get("solved", true)), "%s starts unsolved" % puzzle_id)
		var wrong_first: Dictionary = _game.submit_environmental_puzzle(puzzle_id, "not the answer")
		_expect(not bool(wrong_first.get("ok", true)) and wrong_first.get("reason") == "try_again", "%s accepts an incorrect attempt without failing the game" % puzzle_id)
		_expect(int(wrong_first.get("attempts", 0)) == 1 and String(wrong_first.get("message", "")) == String(puzzle.get("hints", [""])[0]), "%s gives its first authored hint" % puzzle_id)
		var wrong_second: Dictionary = _game.submit_environmental_puzzle(puzzle_id, "still not the answer")
		_expect(not bool(wrong_second.get("ok", true)) and int(wrong_second.get("attempts", 0)) == 2, "%s tracks a second incorrect attempt" % puzzle_id)
		var hints: Array = puzzle.get("hints", [])
		if hints.size() > 1:
			_expect(String(wrong_second.get("message", "")) == String(hints[1]), "%s advances to its second authored hint" % puzzle_id)
		var accepted: Array = puzzle.get("accepted_answers", [])
		_expect(not accepted.is_empty(), "%s has at least one accepted answer" % puzzle_id)
		if accepted.is_empty():
			continue
		var answer := String(accepted[0]).to_upper() + "!"
		var result: Dictionary = _game.submit_environmental_puzzle(puzzle_id, answer)
		_expect(bool(result.get("ok", false)) and result.get("reason") == "solved", "%s accepts a normalized authored answer" % puzzle_id)
		_expect(_game.environmental_puzzles.is_solved(puzzle_id), "%s records solved state" % puzzle_id)
		_expect(int(result.get("attempts", 0)) == 3, "%s reports attempts through its successful answer" % puzzle_id)
		_expect(_completion_count == _completed_ids.size(), "%s completion emits exactly one completion record" % puzzle_id)
		_expect(_completed_ids.count(puzzle_id) == 1, "%s completion signal fires once" % puzzle_id)
		for flag_id in puzzle.get("grants_flags", []):
			_expect(bool(_game.story.flags.get(String(flag_id), false)), "%s applies reward flag %s" % [puzzle_id, String(flag_id)])
		for clue_id in puzzle.get("reveals_clues", []):
			_expect(_game.story.clues.has(String(clue_id)), "%s reveals clue %s" % [puzzle_id, String(clue_id)])
		var emitted_before := _completion_count
		var repeated: Dictionary = _game.submit_environmental_puzzle(puzzle_id, String(accepted[0]))
		_expect(bool(repeated.get("ok", false)) and bool(repeated.get("already_solved", false)), "%s repeated answer is idempotent" % puzzle_id)
		_expect(_completion_count == emitted_before, "%s does not duplicate completion rewards" % puzzle_id)
		_expect(_completed_ids.count(puzzle_id) == 1, "%s has one persisted completion signal" % puzzle_id)
		var manager_copy = PuzzleScript.new()
		manager_copy.setup(_puzzles)
		manager_copy.import_state(_game.environmental_puzzles.export_state())
		_expect(manager_copy.is_solved(puzzle_id), "%s survives manager state export/import" % puzzle_id)
		_expect(int(manager_copy.puzzle(puzzle_id, _game.story.flags).get("attempts", 0)) == 3, "%s attempt count survives manager state export/import" % puzzle_id)

func _test_game_save_round_trip() -> void:
	var saved: Dictionary = SaveManager.read_save()
	_expect(not saved.is_empty(), "puzzle answers write a game save")
	var puzzle_state: Dictionary = saved.get("environmental_puzzles", {})
	var state_rows: Dictionary = puzzle_state.get("states", {})
	for puzzle in _puzzles:
		var puzzle_id := String(puzzle.get("id", ""))
		_expect(bool(state_rows.get(puzzle_id, {}).get("solved", false)), "%s solved state appears in the game save" % puzzle_id)
	var restored_game: Node = GameScript.new()
	add_child(restored_game)
	await get_tree().process_frame
	for puzzle in _puzzles:
		var puzzle_id := String(puzzle.get("id", ""))
		_expect(restored_game.environmental_puzzles.is_solved(puzzle_id), "%s remains solved after a fresh game loads its save" % puzzle_id)
	_expect(restored_game.story.flags.get("puzzle_harbour_safe_return_wish", false), "saved harbor puzzle reward flag is restored")
	_expect(restored_game.story.clues.has("blue_glass_safe_return_token"), "saved harbor clue reveal is restored without duplication")
	_game.free()
	_game = restored_game

func _on_puzzle_completed(puzzle_id: String, _reward_text: String) -> void:
	_completion_count += 1
	_completed_ids.append(puzzle_id)

func _cleanup_owned_save_paths() -> void:
	for path in FIXED_SAVE_PATHS:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

