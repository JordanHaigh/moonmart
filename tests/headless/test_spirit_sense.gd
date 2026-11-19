extends Node

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main game scene loads for Spirit Sense gameplay coverage")
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
	game.save_recovery_required = true # Keep the test away from the player's save.
	game.shift_number = 4
	game.story.flags.clear()
	game.miso_companion.unlocked_abilities.clear()
	game.miso_companion.ability_shifts.clear()
	game.miso_spirit_sense_reaction_shifts.clear()
	game.miso_companion.sync_story_flags(game.story.flags)
	var reactions: Array[String] = []
	game.companion_reaction.connect(func(text_value: String) -> void: reactions.append(text_value))
	game.customers.customer_arrived.emit({"id":"lucien", "name":"Lucien Vale", "state":"ARRIVING"})
	_expect(reactions.is_empty(), "a disguised supernatural arrival gets no Spirit Sense reaction while the ability is locked")
	game.story.flags["pip_reflection"] = true
	game.miso_companion.sync_story_flags(game.story.flags)
	_expect(game.miso_companion.ability_available("spirit_sense"), "the authored Pip reflection milestone unlocks Spirit Sense")
	game.customers.customer_arrived.emit({"id":"fern", "name":"Fern", "state":"ARRIVING"})
	_expect(reactions.is_empty(), "an undisguised supernatural visitor does not trigger the disguise-specific reaction")
	game.customers.customer_arrived.emit({"id":"agnes", "name":"Agnes Thorne", "state":"ARRIVING"})
	_expect(reactions.is_empty(), "ordinary human visitors do not trigger Spirit Sense")
	game.customers.customer_arrived.emit({"id":"lucien", "name":"Lucien Vale", "state":"ARRIVING"})
	_expect(reactions.size() == 1 and reactions[0].contains("Lucien Vale") and reactions[0].contains("disguise"), "the qualifying disguised visitor automatically triggers a localized Miso reaction")
	var reaction_label := scene.get("miso_reaction_label") as Label
	_expect(reaction_label != null and reaction_label.visible and reaction_label.text.contains("Lucien Vale"), "the reaction appears as a static HUD toast")
	_expect(not game.miso_companion.ability_shifts.has("spirit_sense"), "automatic sensing does not spend the once-per-shift manual query")
	game.customers.customer_arrived.emit({"id":"lucien", "name":"Lucien Vale", "state":"ARRIVING"})
	_expect(reactions.size() == 1, "the same visitor does not repeat the reaction within one shift")
	var saved_payload := {"shift_number":game.shift_number, "shift_status":"between_shifts", "story":game.story.to_save(), "miso_companion":game.miso_companion.export_state(), "miso_spirit_sense_reaction_shifts":game.miso_spirit_sense_reaction_shifts.duplicate(true)}
	game.load_state(saved_payload)
	game.customers.customer_arrived.emit({"id":"lucien", "name":"Lucien Vale", "state":"ARRIVING"})
	_expect(reactions.size() == 1, "the same-shift repeat guard survives save and load")
	game.shift_number = 5
	game.customers.customer_arrived.emit({"id":"lucien", "name":"Lucien Vale", "state":"ARRIVING"})
	_expect(reactions.size() == 2, "a new shift can surface the same visitor's arrival again")
	var manual_query: Dictionary = game.use_miso_ability("spirit_sense")
	_expect(bool(manual_query.get("ok", false)), "the existing once-per-shift manual Spirit Sense query remains available after automatic reactions")
	game.set_paused(false)
	scene.call("_on_companion_reaction", "Miso listens; the disguise slips for a moment.")
	_expect(not game.clock.paused and reaction_label.visible, "the reaction toast does not pause gameplay")
	if failures.is_empty():
		print("Spirit Sense gameplay checks passed: %d checks." % checks)
	else:
		for failure in failures:
			push_error(failure)
		print("Spirit Sense gameplay checks failed: %d of %d." % [failures.size(), checks])
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
