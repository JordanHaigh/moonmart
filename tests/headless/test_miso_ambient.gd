extends Node

const AmbientScript = preload("res://scripts/systems/miso_ambient_manager.gd")

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/miso_companion.json"))
	_expect(parsed is Dictionary, "companion config parses")
	if not parsed is Dictionary:
		_finish()
		return
	var config: Dictionary = parsed
	var anchors: Dictionary = config.get("ambient_anchors", {})
	var rows: Array = config.get("ambient_behaviors", [])
	_expect(anchors.has("cat_bed") and anchors.has("window_sill") and anchors.has("ledger_shelf"), "ambient data names all three authored resting anchors")
	_expect(anchors.has("receipt_register") and anchors.has("customer_watch"), "ambient data names the register perch and customer-watching anchor")
	_expect(rows.size() == 6, "ambient schedule contains rests, shop activities, and the optional vase knock")
	var knock_rows: Array[Dictionary] = []
	for row_value in rows:
		if row_value is Dictionary and String(row_value.get("id", "")) == "knock_flower_vase":
			knock_rows.append(row_value)
	_expect(knock_rows.size() == 1 and String(knock_rows[0].get("requires_prop", "")) == "flower_bud_vase", "vase knock schedule names the isolated flower-bud vase as its required prop")
	var manager = AmbientScript.new()
	manager.setup(rows, 7021, 0.0, 0.0, 10.0, 10.0)
	for spot in ["cat_bed", "window_sill", "ledger_shelf"]:
		var eligible: Array[Dictionary] = manager.eligible_behaviors(false, String(spot))
		_expect(eligible.any(func(row: Dictionary) -> bool: return String(row.get("requires_sleep_spot", "")) == String(spot)), "preferred resting spot %s has an eligible ambient behavior" % String(spot))
	var without_customers: Array[Dictionary] = manager.eligible_behaviors(false, "cat_bed")
	var with_customers: Array[Dictionary] = manager.eligible_behaviors(true, "cat_bed")
	_expect(not without_customers.any(func(row: Dictionary) -> bool: return String(row.get("id", "")) == "watch_customers"), "Miso does not choose to watch an empty shop")
	_expect(with_customers.any(func(row: Dictionary) -> bool: return String(row.get("id", "")) == "watch_customers"), "customer watching becomes eligible when a visitor is present")
	var unavailable_prop_manager = AmbientScript.new()
	var knock_behavior := {"id":"knock_test", "anchor":"receipt_register", "requires_prop":"flower_bud_vase", "duration_seconds":2.2, "cooldown_seconds":120.0, "weight":1.0}
	unavailable_prop_manager.setup([knock_behavior], 51, 0.0, 0.0, 10.0, 10.0)
	var absent_result: Dictionary = unavailable_prop_manager.tick(0.1, true, false, "cat_bed", false)
	_expect(String(absent_result.get("state", "")) == "no_eligible_behavior" and unavailable_prop_manager.current_behavior().is_empty(), "missing vase prevents the knock behavior from starting")
	_expect(unavailable_prop_manager.cooldown_seconds("knock_test") == 0.0, "missing vase does not consume a behavior cooldown")
	unavailable_prop_manager.setup([knock_behavior], 51, 0.0, 0.0, 10.0, 10.0)
	var present_result: Dictionary = unavailable_prop_manager.tick(0.1, true, false, "cat_bed", false, ["flower_bud_vase"])
	_expect(String(present_result.get("state", "")) == "started" and String(present_result.get("behavior", {}).get("id", "")) == "knock_test", "present vase enables deterministic knock behavior selection")
	unavailable_prop_manager.cancel_current(false)
	_expect(unavailable_prop_manager.cooldown_seconds("knock_test") == 0.0 and unavailable_prop_manager.current_behavior().is_empty(), "interrupting the prop approach restores the scheduler without a cooldown")
	var repeat_manager = AmbientScript.new()
	repeat_manager.setup(rows, 7021, 0.0, 0.0, 10.0, 10.0)
	_expect(String(manager.choose_behavior(true, "cat_bed").get("id", "")) == String(repeat_manager.choose_behavior(true, "cat_bed").get("id", "")), "seeded behavior selection is deterministic")

	var only_behavior := {"id":"test_walk", "anchor":"cat_bed", "duration_seconds":1.0, "cooldown_seconds":12.0, "weight":1.0}
	manager.setup([only_behavior], 9, 0.0, 0.0, 10.0, 10.0)
	var started: Dictionary = manager.tick(0.1, true, false, "cat_bed", false)
	_expect(String(started.get("state", "")) == "started" and manager.waiting_for_arrival(), "scheduler starts the selected behavior as a walk target")
	var arrived: Dictionary = manager.tick(0.1, true, false, "cat_bed", true)
	_expect(String(arrived.get("state", "")) == "arrived" and not manager.waiting_for_arrival(), "behavior dwells only after Miso reaches its anchor")
	var dwell_before_pause := manager.active_remaining_seconds()
	manager.tick(5.0, false, false, "cat_bed", false)
	_expect(is_equal_approx(manager.active_remaining_seconds(), dwell_before_pause), "suspended ambient behavior timers freeze during panels or reduced animation")
	manager.tick(1.1, true, false, "cat_bed", true)
	_expect(manager.active_remaining_seconds() < dwell_before_pause, "enabled behavior dwell resumes after suspension")
	_expect(manager.cooldown_seconds("test_walk") == 12.0, "completed behavior receives its configured cooldown")
	var cooldown_before_pause := manager.cooldown_seconds("test_walk")
	manager.tick(2.0, false, false, "cat_bed", false)
	_expect(is_equal_approx(manager.cooldown_seconds("test_walk"), cooldown_before_pause), "cooldown also freezes while the behavior loop is suspended")
	_finish()

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)

func _finish() -> void:
	if _failures.is_empty():
		print("Miso ambient behavior checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Miso ambient behavior checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)
