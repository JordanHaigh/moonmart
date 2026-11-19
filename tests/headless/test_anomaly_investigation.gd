extends Node

const MoonmartGameScript = preload("res://scripts/core/moonmart_game.gd")
const EventDirectorScript = preload("res://scripts/systems/event_director.gd")

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = MoonmartGameScript.new()
	add_child(game)
	await get_tree().process_frame
	_expect(game != null, "game controller initializes for optional anomaly investigation")
	game.save_recovery_required = true
	game.shift_number = 3
	game.customers.active.clear()
	game.anomaly_disturbances.clear()
	game.resolved_anomaly_investigations.clear()
	var essential_flags_before: Dictionary = game.story.flags.duplicate(true)
	var moons_before := int(game.inventory.moon_tokens)
	var transactions_before: int = int(game.inventory.transactions.size())

	game._deliver_optional_event({"id":"receipt_whispers"})
	_expect(game.anomaly_disturbances.size() == 1 and String(game.anomaly_disturbances[0].get("event_id", "")) == "receipt_whispers", "delivered receipt anomaly becomes an optional active investigation")
	_expect(String(game.last_message).contains("inspect the receipt at the register"), "event notice points to the existing register interaction")
	_expect(int(game.inventory.moon_tokens) == moons_before and game.story.flags == essential_flags_before, "ignoring the cue gives no immediate reward or story progression")
	var inspection: Dictionary = game.investigate_optional_anomaly("ticket_window")
	_expect(not bool(inspection.get("ok", false)) and String(inspection.get("reason", "")) == "no_investigable_anomaly", "the optional receipt clue only resolves at its authored register target")

	game.interact("register")
	_expect(String(game.last_message).contains("warm place to wait"), "register interaction reveals the authored receipt memory")
	_expect(int(game.inventory.moon_tokens) == moons_before + 1, "investigation grants its configured one Moon Token reward")
	_expect(game.resolved_anomaly_investigations.has("receipt_whispers") and game.anomaly_disturbances.is_empty(), "resolution is recorded and removes the disturbance from the Guardian target queue")
	_expect(game.inventory.transactions.size() == transactions_before + 1 and String(game.inventory.transactions.back().get("reason", "")) == "optional_anomaly_investigation", "optional reward is recorded in the inventory ledger")
	_expect(game.story.flags == essential_flags_before and game.story.completed_events.is_empty(), "anomaly resolution does not grant essential flags or complete story events")

	var save_payload: Dictionary = {"shift_number":game.shift_number, "shift_status":"between_shifts", "story":game.story.to_save(), "inventory":game.inventory.to_save(), "anomaly_disturbances":game.anomaly_disturbances.duplicate(true), "resolved_anomaly_investigations":game.resolved_anomaly_investigations.duplicate()}
	game.load_state(save_payload)
	_expect(game.resolved_anomaly_investigations.has("receipt_whispers") and int(game.inventory.moon_tokens) == moons_before + 1, "resolved investigation and optional reward survive save/load")
	game._deliver_optional_event({"id":"receipt_whispers"})
	_expect(game.anomaly_disturbances.is_empty() and not String(game.last_message).contains("inspect the receipt at the register"), "a later recurrence remains atmospheric after the one-time investigation")
	game.interact("register")
	_expect(int(game.inventory.moon_tokens) == moons_before + 1 and game.inventory.transactions.size() == transactions_before + 1, "repeat interaction cannot award the investigation reward twice")

	var director = EventDirectorScript.new()
	var definition: Dictionary = game.event_definitions.get("receipt_whispers", {}).duplicate(true)
	director.setup([definition])
	var first_delivery: Array[Dictionary] = director.begin_shift(3, {}, 1)
	var ignored_recurrence: Array[Dictionary] = director.begin_shift(4, {}, 1)
	_expect(first_delivery.size() == 1 and ignored_recurrence.size() == 1 and String(ignored_recurrence[0].get("id", "")) == "receipt_whispers", "unresolved anomalies can recur on later shifts when ignored")

	if failures.is_empty():
		print("Optional anomaly investigation checks passed: %d checks." % checks)
	else:
		for failure in failures:
			push_error(failure)
		print("Optional anomaly investigation checks failed: %d of %d." % [failures.size(), checks])
	game.queue_free()
	for _frame in range(4):
		await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
