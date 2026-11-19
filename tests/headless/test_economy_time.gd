extends Node

const InventoryScript = preload("res://scripts/systems/inventory_manager.gd")
const TimeScript = preload("res://scripts/systems/time_manager.gd")
const GameScript = preload("res://scripts/core/moonmart_game.gd")
const SaveScript = preload("res://scripts/core/save_manager.gd")

var failures: Array[String] = []
var checks := 0
var shift_end_signals := 0

func _ready() -> void:
	print("Running economy/time headless checks…")
	call_deferred("_run")

func _run() -> void:
	_test_checkout_reservations_and_refunds()
	_test_shelf_storage_capacity_and_freshness()
	_test_physical_stock_carry_and_persistence()
	_test_inventory_invariants_under_mixed_operations()
	_test_token_currency_and_crafting()
	_test_shift_timing_and_early_close()
	await _test_game_minimum_service_policy()
	await _test_missed_essential_encounter_survives_close_and_save_load()
	if failures.is_empty():
		print("Economy/time headless checks passed: %d checks." % checks)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)

func _test_checkout_reservations_and_refunds() -> void:
	var milk := _product("milk")
	_expect(not milk.is_empty(), "milk fixture exists")
	if milk.is_empty():
		return
	var inventory = InventoryScript.new()
	inventory.setup([milk], {"milk":4})
	var opening_coins: int = inventory.coins
	var unavailable_sale: Dictionary = inventory.sell({"milk":5})
	_expect(not bool(unavailable_sale.get("ok", false)), "checkout rejects quantities beyond shelf stock")
	_expect(inventory.quantity("milk") == 4 and inventory.coins == opening_coins, "rejected checkout leaves stock and currency unchanged")
	var held: Dictionary = inventory.reserve("order_a", {"milk":3}, "special_order", 2)
	_expect(bool(held.get("ok", false)), "reservation succeeds for available shelf stock")
	_expect(inventory.available_on_shelf("milk") == 1, "reservation is excluded from public shelf availability")
	var competing: Dictionary = inventory.reserve("order_b", {"milk":2})
	_expect(not bool(competing.get("ok", false)), "reservation cannot double-allocate shelf stock")
	var mismatch: Dictionary = inventory.sell({"milk":2}, "coins", "order_a")
	_expect(String(mismatch.get("reason", "")) == "reservation_mismatch", "reserved sale must match its basket")
	_expect(inventory.quantity("milk") == 4 and inventory.coins == opening_coins, "mismatched reservation sale changes nothing")
	var sale: Dictionary = inventory.sell({"milk":3}, "coins", "order_a")
	_expect(bool(sale.get("ok", false)), "reserved checkout commits")
	_expect(inventory.quantity("milk") == 1 and inventory.coins == opening_coins + 3 * inventory.price_for("milk"), "checkout commits stock and exact currency total")
	var refunded: Dictionary = inventory.refund(String(sale.get("transaction_id", "")))
	_expect(bool(refunded.get("ok", false)), "latest sale can be refunded")
	_expect(inventory.quantity("milk") == 4 and inventory.coins == opening_coins, "refund restores returned stock and currency")
	var duplicate_refund: Dictionary = inventory.refund(String(sale.get("transaction_id", "")))
	_expect(not bool(duplicate_refund.get("ok", false)), "sale cannot be refunded twice")
	_expect(inventory.quantity("milk") == 4 and inventory.coins == opening_coins, "duplicate refund leaves balances unchanged")

	var capacity_inventory = InventoryScript.new()
	capacity_inventory.setup([milk], {"milk":18})
	var capacity_sale: Dictionary = capacity_inventory.sell({"milk":2})
	_expect(bool(capacity_sale.get("ok", false)), "capacity refund fixture sale succeeds")
	var coins_after_sale: int = capacity_inventory.coins
	_expect(capacity_inventory.restock("milk", 4), "delivery fills product capacity after sale")
	var blocked_refund: Dictionary = capacity_inventory.refund(String(capacity_sale.get("transaction_id", "")))
	_expect(String(blocked_refund.get("reason", "")) == "product_capacity", "refund rejects a return that exceeds stock capacity")
	_expect(capacity_inventory.quantity("milk") == 20 and capacity_inventory.coins == coins_after_sale, "capacity-rejected refund is atomic")

func _test_shelf_storage_capacity_and_freshness() -> void:
	var milk := _product("milk")
	if milk.is_empty():
		return
	var inventory = InventoryScript.new()
	inventory.setup([milk], {"milk":16})
	_expect(inventory.shelf_quantity("milk") == inventory.shelf_capacity_for("milk"), "opening stock fills only the shelf's declared capacity")
	_expect(inventory.storage_quantity("milk") == 16 - inventory.shelf_capacity_for("milk"), "opening stock over the display limit is stored in backroom")
	_expect(not bool(inventory.restock_shelf("milk", 1).get("ok", false)), "shelf cannot be replenished beyond its capacity")
	var sale: Dictionary = inventory.sell({"milk":5})
	_expect(bool(sale.get("ok", false)), "shelf sale creates room for backroom stock")
	var replenishment: Dictionary = inventory.restock_shelf("milk", 4)
	_expect(bool(replenishment.get("ok", false)), "backroom stock can replenish shelf")
	_expect(inventory.quantity("milk") == 11 and inventory.shelf_quantity("milk") == 11 and inventory.storage_quantity("milk") == 0, "replenishment moves freshness-tracked stock without changing total")
	_expect(String(inventory.can_receive_delivery("milk", 10).get("reason", "")) == "product_capacity", "delivery is blocked at product stock capacity")
	inventory.storage_capacity = inventory.storage_used()
	_expect(String(inventory.can_receive_delivery("milk", 1).get("reason", "")) == "storage_capacity", "delivery is blocked at backroom storage capacity")

	var fresh_inventory = InventoryScript.new()
	fresh_inventory.setup([milk], {"milk":2})
	var initial_freshness := fresh_inventory.freshness_remaining("milk", "shelf")
	_expect(initial_freshness > 0, "perishable shelf lot records a positive shelf life")
	var spoiled_total := 0
	for _shift in range(initial_freshness):
		for row in fresh_inventory.age_stock_by_shift():
			if String(row.get("product_id", "")) == "milk" and String(row.get("location", "")) == "shelf":
				spoiled_total += int(row.get("quantity", 0))
	_expect(spoiled_total == 2 and fresh_inventory.quantity("milk") == 0, "perishable stock spoils at its recorded shelf-life limit")

func _test_physical_stock_carry_and_persistence() -> void:
	var milk := _product("milk")
	var tea := _product("tea")
	if milk.is_empty() or tea.is_empty():
		return
	milk["display_capacity"] = 2
	milk["stock_capacity"] = 6
	tea["display_capacity"] = 2
	tea["stock_capacity"] = 6
	var inventory = InventoryScript.new()
	inventory.setup([milk, tea], {"milk":3, "tea":1})
	var opening_total: int = inventory.quantity("milk")
	_expect(bool(inventory.sell({"milk":1}).get("ok", false)), "a shelf sale creates room for a carried item")
	var pickup: Dictionary = inventory.pick_up_from_storage("milk")
	_expect(bool(pickup.get("ok", false)) and inventory.is_carrying_stock(), "one backroom product can be picked up and carried")
	_expect(inventory.quantity("milk") == opening_total - 1 and inventory.shelf_quantity("milk") == 1 and inventory.storage_quantity("milk") == 0 and inventory.carried_quantity == 1, "pickup moves one unit into carried state without changing the remaining total")
	_expect(not bool(inventory.pick_up_from_storage("tea").get("ok", false)), "a second product cannot be picked up while the player is carrying one")
	_expect(String(inventory.place_carried_on_shelf("tea").get("reason", "")) == "different_product", "a carried product cannot be placed on a different product display")
	_expect(not bool(inventory.sell({"milk":2}).get("ok", false)), "carried stock cannot be checked out before it reaches a display")
	var carried_save: Dictionary = inventory.to_save()
	var restored = InventoryScript.new()
	restored.setup([milk, tea])
	restored.from_save(carried_save)
	_expect(restored.is_carrying_stock() and restored.carried_product_id == "milk" and restored.carried_quantity == 1, "the held product and its identity survive an inventory save/load")
	var returned: Dictionary = restored.return_carried_to_storage("milk")
	_expect(bool(returned.get("ok", false)) and not restored.is_carrying_stock() and restored.storage_quantity("milk") == 1, "a carried product can be returned to backroom storage")
	_expect(bool(restored.pick_up_from_storage("milk").get("ok", false)), "a returned product can be picked up again")
	var placed: Dictionary = restored.place_carried_on_shelf("milk")
	_expect(bool(placed.get("ok", false)) and not restored.is_carrying_stock(), "the carried item can be placed on its matching display")
	_expect(restored.quantity("milk") == opening_total - 1 and restored.shelf_quantity("milk") == 2 and restored.storage_quantity("milk") == 0, "pickup and placement conserve stock while moving it from backroom to display")

func _test_inventory_invariants_under_mixed_operations() -> void:
	var milk := _product("milk")
	var tea := _product("tea")
	if milk.is_empty() or tea.is_empty():
		return
	var inventory = InventoryScript.new()
	inventory.setup([milk, tea], {"milk":14, "tea":8})
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x4d4f4f4e
	for step in range(96):
		match step % 8:
			0:
				inventory.restock("milk", rng.randi_range(1, 3))
			1:
				inventory.restock_shelf("milk", rng.randi_range(1, 4))
			2:
				inventory.sell({"milk":rng.randi_range(1, 3), "tea":rng.randi_range(1, 2)}, "coins")
			3:
				inventory.donate("tea", rng.randi_range(1, 2))
			4:
				inventory.age_stock_by_shift()
			5:
				var allocation_id := "mixed_%d" % step
				var reservation: Dictionary = inventory.reserve(allocation_id, {"tea":1}, "invariant_test", step)
				if bool(reservation.get("ok", false)):
					if step % 16 == 5:
						inventory.sell({"tea":1}, "coins", allocation_id)
					else:
						inventory.release_reservation(allocation_id)
			6:
				var latest := inventory.latest_refundable_sale()
				if not latest.is_empty():
					inventory.refund(String(latest.get("id", "")))
			7:
				inventory.set_discount("milk", 0.8)
				inventory.clear_discount("milk")
		var invariant_holds: bool = inventory.coins >= 0 and inventory.moon_tokens >= 0 and inventory.revenue == inventory.coins_revenue + inventory.moon_tokens_revenue and inventory.storage_used() <= inventory.storage_capacity
		for product_id in ["milk", "tea"]:
			var total := inventory.quantity(product_id)
			var shelf := inventory.shelf_quantity(product_id)
			var storage := inventory.storage_quantity(product_id)
			var capacity := int(inventory.products[product_id].get("stock_capacity", 20))
			invariant_holds = invariant_holds and total == shelf + storage and total >= 0 and shelf >= 0 and storage >= 0 and total <= capacity and shelf <= inventory.shelf_capacity_for(product_id)
		_expect(invariant_holds, "inventory conservation and currency invariants hold after mixed operation %d" % step)

func _test_token_currency_and_crafting() -> void:
	var milk := _product("milk")
	if milk.is_empty():
		return
	var token_inventory = InventoryScript.new()
	token_inventory.setup([milk], {"milk":2})
	var starting_coins: int = token_inventory.coins
	var starting_tokens: int = token_inventory.moon_tokens
	var token_sale: Dictionary = token_inventory.sell({"milk":1}, "moon_tokens")
	var token_total := token_inventory.price_for("milk")
	_expect(bool(token_sale.get("ok", false)), "moon-token checkout succeeds")
	_expect(token_inventory.coins == starting_coins and token_inventory.moon_tokens == starting_tokens + token_total, "moon-token checkout updates only the selected wallet")
	_expect(token_inventory.coins_revenue == 0 and token_inventory.moon_tokens_revenue == token_total, "moon-token sale updates the matching revenue ledger")
	var token_refund: Dictionary = token_inventory.refund(String(token_sale.get("transaction_id", "")))
	_expect(bool(token_refund.get("ok", false)), "moon-token sale can be refunded")
	_expect(token_inventory.coins == starting_coins and token_inventory.moon_tokens == starting_tokens and token_inventory.revenue == 0, "moon-token refund restores wallet and total revenue")

	var tea := _product("tea")
	var brewed_tea := _product("brewed_plain_tea")
	if tea.is_empty() or brewed_tea.is_empty():
		return
	var craft_inventory = InventoryScript.new()
	craft_inventory.setup([tea, brewed_tea], {"tea":2})
	var invalid_craft: Dictionary = craft_inventory.produce("brewed_plain_tea", 1, {"tea":3}, "plain_tea")
	_expect(String(invalid_craft.get("reason", "")) == "missing_ingredients", "crafting rejects missing ingredients")
	_expect(craft_inventory.quantity("tea") == 2 and craft_inventory.quantity("brewed_plain_tea") == 0, "failed crafting consumes no ingredients or output capacity")
	var crafted: Dictionary = craft_inventory.produce("brewed_plain_tea", 1, {"tea":1}, "plain_tea")
	_expect(bool(crafted.get("ok", false)), "valid recipe production succeeds")
	_expect(craft_inventory.quantity("tea") == 1 and craft_inventory.storage_quantity("brewed_plain_tea") == 1, "crafting consumes ingredients and stores the output in the backroom")

func _test_shift_timing_and_early_close() -> void:
	var timing := JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/timing.json")) as Dictionary
	var shift = TimeScript.new()
	shift.configure(timing)
	shift.set_shift_profile(1)
	_expect(shift.active_profile == "vertical_slice", "early shifts use the vertical-slice timing profile")
	_expect(is_equal_approx(shift.minutes_per_real_second, float(timing.vertical_slice_minutes_per_real_second)), "vertical-slice pace comes from balance data")
	shift.set_shift_profile(int(timing.vertical_slice_shifts) + 1)
	_expect(shift.active_profile == "standard", "later shifts use the standard timing profile")
	_expect(is_equal_approx(shift.minutes_per_real_second, float(timing.standard_minutes_per_real_second)), "standard pace comes from balance data")
	shift.shift_time_reached.connect(_on_shift_time_reached)
	shift.start()
	_expect(not shift.is_open(), "preparation period starts before customer service")
	_expect(shift.clock_text() == "11:30 PM", "clock includes the configured preparation period")
	shift.paused = true
	shift.tick(60.0)
	_expect(is_zero_approx(shift.elapsed_minutes), "paused shift does not advance")
	shift.paused = false
	shift.tick(float(timing.preparation_minutes) / shift.minutes_per_real_second)
	_expect(shift.is_open(), "service opens after configured preparation minutes")
	shift.close_early()
	_expect(not shift.running and shift_end_signals == 1, "early close stops shift and emits one end signal")
	shift.tick(10.0)
	_expect(shift_end_signals == 1, "closed shift cannot emit another end signal")

func _test_game_minimum_service_policy() -> void:
	var game = GameScript.new()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.save_recovery_required = true
	game.shift_number = 1
	game.shift_status = "open"
	game.clock.set_shift_profile(game.shift_number)
	game.clock.start()
	var initial_elapsed := float(game.clock.elapsed_minutes)
	var minimum := float(game.minimum_service_minutes)
	var rejected: Dictionary = game.close_shift()
	_expect(not bool(rejected.get("ok", false)) and String(rejected.get("reason", "")) == "minimum_service_period", "game rejects an early close before the minimum service period")
	_expect(game.shift_status == "open" and game.clock.running, "rejected early close keeps the shift open and timer running")
	_expect(is_equal_approx(float(game.clock.elapsed_minutes), initial_elapsed), "rejected early close does not advance or alter shift time")
	_expect(float(rejected.get("remaining_minutes", -1)) == minimum, "early-close result reports the full remaining service time")
	var seconds_to_minimum := (float(game.clock.prep_minutes) + minimum) / float(game.clock.minutes_per_real_second)
	game.clock.tick(seconds_to_minimum + 0.1)
	var allowed: Dictionary = game.can_close_shift()
	_expect(bool(allowed.get("ok", false)) and int(allowed.get("served_minutes", 0)) >= ceili(minimum), "game permits closing after the configured minimum service period")
	var closed: Dictionary = game.close_shift()
	_expect(bool(closed.get("ok", false)) and not game.clock.running, "accepted early close stops the game clock")
	_expect(game.shift_status == "between_shifts", "accepted early close completes the game-level shift")
	game.queue_free()
	await get_tree().process_frame

func _test_missed_essential_encounter_survives_close_and_save_load() -> void:
	var save_paths: Array[String] = [SaveScript.SAVE_PATH, SaveScript.TEMP_PATH, SaveScript.STAGE_PATH, SaveScript.RECOVERY_PATH, SaveScript.RECOVERY_TEMP_PATH, SaveScript.RECOVERY_STAGE_PATH, SaveScript.BACKUP_PATH, SaveScript.BACKUP_TEMP_PATH, SaveScript.BACKUP_STAGE_PATH]
	for path in save_paths:
		if FileAccess.file_exists(path):
			_expect(false, "missed-encounter integration starts with isolated save paths")
			return
	var game = GameScript.new()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	_expect(not game.save_recovery_required, "fresh integration game can save its essential encounter")
	game.begin_shift()
	var scheduled: Array[Dictionary] = game.quests.queued_encounters()
	_expect(game.shift_number == 1 and not scheduled.is_empty() and String(scheduled[0].get("quest_id", "")) == "meet_agnes", "the first game-level shift schedules Agnes as an essential encounter")
	if scheduled.is_empty():
		game.queue_free()
		await get_tree().process_frame
		return
	game.quests.note_visit_missed("meet_agnes")
	var service_seconds := (float(game.clock.prep_minutes) + float(game.minimum_service_minutes)) / float(game.clock.minutes_per_real_second)
	game.clock.tick(service_seconds + 0.1)
	var close_result: Dictionary = game.close_shift()
	_expect(bool(close_result.get("ok", false)) and game.shift_status == "between_shifts", "the player can close after the minimum service while leaving the essential encounter unresolved")
	var saved_state := SaveScript.read_save()
	var saved_quests: Dictionary = saved_state.get("quests_system", {})
	var saved_queue: Array = saved_quests.get("encounter_queue", [])
	_expect(not saved_queue.is_empty() and String(saved_queue[0].get("quest_id", "")) == "meet_agnes", "the unresolved essential visitor remains queued in the committed game save")
	_expect(int(saved_quests.get("missed_visits", {}).get("meet_agnes", 0)) == 1, "the saved encounter retains its missed-visit record")
	var restored = GameScript.new()
	get_tree().root.add_child(restored)
	await get_tree().process_frame
	var restored_queue: Array[Dictionary] = restored.quests.queued_encounters()
	_expect(not restored_queue.is_empty() and String(restored_queue[0].get("quest_id", "")) == "meet_agnes", "a fresh game instance restores the missed essential encounter")
	if not restored_queue.is_empty():
		restored.begin_shift()
		var retried_queue: Array[Dictionary] = restored.quests.queued_encounters()
		_expect(restored.shift_number == 2 and not retried_queue.is_empty() and String(retried_queue[0].get("quest_id", "")) == "meet_agnes" and int(retried_queue[0].get("eligible_shift", 0)) == 2, "the missed visitor becomes eligible again on the next shift after reload")
	game.queue_free()
	restored.queue_free()
	await get_tree().process_frame
	for path in save_paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _product(product_id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/products.json"))
	if not parsed is Dictionary:
		_expect(false, "product catalog parses")
		return {}
	for row in parsed.get("products", []):
		if row is Dictionary and String(row.get("id", "")) == product_id:
			return row.duplicate(true)
	_expect(false, "product catalog contains %s" % product_id)
	return {}

func _on_shift_time_reached() -> void:
	shift_end_signals += 1

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

