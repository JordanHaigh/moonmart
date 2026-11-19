extends SceneTree

const GAME_SCRIPT = preload("res://scripts/core/moonmart_game.gd")
const ACTION_IDS: Array[String] = [
	"wipe_counter", "sweep_floor", "water_plants", "clear_cups", "refill_dispenser", "take_out_rubbish"
]
const SAVE_PATHS: Array[String] = [
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
	_game = GAME_SCRIPT.new()
	root.add_child(_game)
	await process_frame
	_game.save_recovery_required = false
	_game.shop_progression.cleanliness = 0.0
	_game.shop_progression.proficiency_points["stewardship"] = 10
	_game.begin_shift()
	_expect(int(_game.shift_number) == 1 and String(_game.shift_status) == "open", "first shift opens before housekeeping actions are tested")
	var action_values: Dictionary = _game.shop_progression.cleanliness_config.get("actions", {})
	for action_id in ACTION_IDS:
		var before_cleanliness := float(_game.shop_progression.cleanliness)
		var before_points := int(_game.shop_progression.proficiency_points.get("stewardship", 0))
		var rank_bonus := int(_game.shop_progression.proficiency_rank("stewardship"))
		var expected_gain := float(action_values.get(action_id, 0.0)) + float(rank_bonus)
		var result: Dictionary = _game.clean_shop(action_id)
		_expect(bool(result.get("ok", false)) and String(result.get("action_id", "")) == action_id, "%s completes through the game service" % action_id)
		_expect(is_equal_approx(float(result.get("cleanliness", -1.0)), before_cleanliness + expected_gain), "%s grants its configured cleanliness plus the current Stewardship rank bonus" % action_id)
		_expect(_game.cleaning_action_done(action_id), "%s is recorded as completed for this shift" % action_id)
		var points_after := int(_game.shop_progression.proficiency_points.get("stewardship", 0))
		_expect(points_after >= before_points, "%s can advance Stewardship progression" % action_id)
		var repeated: Dictionary = _game.clean_shop(action_id)
		_expect(not bool(repeated.get("ok", false)) and String(repeated.get("reason", "")) == "already_done", "%s cannot be repeated during the same shift" % action_id)
		_expect(is_equal_approx(float(_game.shop_progression.cleanliness), before_cleanliness + expected_gain) and int(_game.shop_progression.proficiency_points.get("stewardship", 0)) == points_after, "%s repeat has no cleanliness or proficiency reward" % action_id)
	var before_unknown_cleanliness := float(_game.shop_progression.cleanliness)
	var before_unknown_points := int(_game.shop_progression.proficiency_points.get("stewardship", 0))
	var unknown: Dictionary = _game.clean_shop("invented_action")
	_expect(not bool(unknown.get("ok", false)) and String(unknown.get("reason", "")) == "unknown_action", "unknown housekeeping actions are rejected")
	_expect(is_equal_approx(float(_game.shop_progression.cleanliness), before_unknown_cleanliness) and int(_game.shop_progression.proficiency_points.get("stewardship", 0)) == before_unknown_points, "unknown action leaves cleanliness and proficiency unchanged")
	_game.call("_on_shift_time_reached")
	_game.begin_shift()
	_expect(int(_game.shift_number) == 2 and String(_game.shift_status) == "open", "housekeeping test advances through the normal next-shift entry")
	for action_id in ACTION_IDS:
		_expect(not _game.cleaning_action_done(action_id), "%s resets at the next shift" % action_id)
	var refill_again: Dictionary = _game.clean_shop("refill_dispenser")
	_expect(bool(refill_again.get("ok", false)), "the dispenser can be refilled once again in a new shift")
	if _game != null and is_instance_valid(_game):
		_game.save_recovery_required = true
		_game.free()
	_cleanup_save_paths()
	if _failures.is_empty():
		print("Housekeeping gameplay checks passed: %d checks across %d actions." % [_checks, ACTION_IDS.size()])
	else:
		for failure in _failures:
			push_error(failure)
		printerr("Housekeeping gameplay checks failed: %d of %d." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)

func _preflight_save_paths() -> bool:
	for path in SAVE_PATHS:
		if FileAccess.file_exists(path):
			push_error("Refusing to run housekeeping fixtures over an existing user save: %s" % path)
			return false
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path("user://")):
		if filename.begins_with("moonmart_save_unreadable_") and filename.ends_with(".json"):
			push_error("Refusing to run with a pre-existing unreadable-save archive")
			return false
	return true

func _cleanup_save_paths() -> void:
	for path in SAVE_PATHS:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
