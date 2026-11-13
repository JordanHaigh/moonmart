extends Node

const MisoScript = preload("res://scripts/systems/miso_companion_manager.gd")

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/miso_companion.json"))
	_expect(parsed is Dictionary, "Miso companion config parses")
	if not parsed is Dictionary:
		_finish()
		return
	var miso = MisoScript.new()
	miso.setup(parsed)
	var start_happiness := int(miso.happiness)
	var favorite_play: Dictionary = miso.interact("play", 1, "felt_moon")
	_expect(bool(favorite_play.get("ok", false)) and int(favorite_play.get("gain", 0)) == 11, "playing with Miso's favorite toy grants its authored comfort bonus")
	_expect(int(miso.happiness) == start_happiness + 11 and String(miso.mood_id) == "playful", "Miso mood updates at the configured happiness threshold")
	var repeated_play: Dictionary = miso.interact("play", 1, "paper_ribbon")
	_expect(not bool(repeated_play.get("ok", false)) and String(repeated_play.get("reason", "")) == "already_done", "reloading the same shift cannot refresh an already-used companion action")
	var next_shift_play: Dictionary = miso.interact("play", 2, "paper_ribbon")
	_expect(bool(next_shift_play.get("ok", false)) and int(next_shift_play.get("gain", 0)) == 6, "everyday companion actions refresh on the next shift without the favorite bonus")
	_expect(String(next_shift_play.get("message", "")).contains("paper ribbon"), "non-favorite toys keep their own authored response")
	_expect(miso.choose_sleep_spot("window_sill") and String(miso.preferred_sleep_spot) == "window_sill", "Miso can choose an authored sleep spot")
	_expect(not miso.choose_sleep_spot("street"), "Miso cannot select an unknown sleep spot")
	var all_abilities := ["spirit_sense", "hidden_paw", "dreamwalking", "memory_echo", "guardian_purr", "moonlight_perception"]
	for ability_id in all_abilities:
		_expect(not miso.ability_available(String(ability_id)), "%s stays locked before its story milestone" % String(ability_id))
	var locked: Dictionary = miso.use_ability("spirit_sense", 2)
	_expect(not bool(locked.get("ok", false)) and String(locked.get("reason", "")) == "locked", "a locked Miso ability has no effect")
	var flags := {"pip_reflection": true}
	var unlocked: Array[String] = miso.sync_story_flags(flags)
	_expect(unlocked == ["spirit_sense"] and miso.ability_available("spirit_sense"), "Spirit Sense unlocks only with its authored story flag")
	var first_use: Dictionary = miso.use_ability("spirit_sense", 2)
	var duplicate_use: Dictionary = miso.use_ability("spirit_sense", 2)
	_expect(bool(first_use.get("ok", false)) and not bool(duplicate_use.get("ok", false)), "unlocked companion abilities are limited to once per shift")
	flags.merge({"pip_first_memory": true, "miso_guardian_truth": true, "passenger_manifest_read": true, "boundary_stabilized": true, "lighthouse_restored": true}, true)
	var additional_unlocks: Array[String] = miso.sync_story_flags(flags)
	_expect(additional_unlocks.size() == 5 and all_abilities.all(func(id: String) -> bool: return miso.ability_available(id)), "all remaining abilities unlock through their narrative milestones")
	var hidden_paw: Dictionary = miso.use_ability("hidden_paw", 3, {"overlooked_clue_id":"miso_memory_echo"})
	_expect(String(hidden_paw.get("clue_id", "")) == "miso_memory_echo", "Hidden Paw routes its discovered clue back to the journal caller")
	var guardian_purr: Dictionary = miso.use_ability("guardian_purr", 3)
	_expect(is_equal_approx(float(guardian_purr.get("stability", 0.0)), 1.0), "Guardian's Purr supplies its configured stabilization strength")
	var saved_state: Dictionary = miso.export_state()
	var restored = MisoScript.new()
	restored.setup(parsed)
	restored.import_state(saved_state)
	_expect(int(restored.happiness) == int(miso.happiness) and String(restored.preferred_sleep_spot) == "window_sill", "Miso's comfort and sleep preference survive save/load")
	_expect(restored.ability_available("guardian_purr") and int(restored.action_shifts.get("play", 0)) == 2 and int(restored.ability_shifts.get("guardian_purr", 0)) == 3, "story abilities and per-shift action limits survive save/load")
	_expect(not restored.use_ability("guardian_purr", 3).get("ok", false), "mid-shift reload cannot repeat an already-used ability")
	_finish()

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _finish() -> void:
	if failures.is_empty():
		print("Miso companion checks passed: %d checks." % checks)
	else:
		for failure in failures:
			push_error(failure)
		print("Miso companion checks failed: %d of %d." % [failures.size(), checks])
	get_tree().quit(0 if failures.is_empty() else 1)
