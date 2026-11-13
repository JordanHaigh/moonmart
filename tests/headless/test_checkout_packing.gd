extends Node

const CustomerManagerScript = preload("res://scripts/systems/customer_manager.gd")
const GameScript = preload("res://scripts/core/moonmart_game.gd")
const VALID_PACKING_PREFERENCES := ["paper", "careful", "reusable"]

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var characters_value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/characters.json"))
	var ordinary_value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/ordinary_customers.json"))
	_expect(characters_value is Dictionary and ordinary_value is Dictionary, "customer and visitor preference catalogs parse")
	if not characters_value is Dictionary or not ordinary_value is Dictionary:
		_finish()
		return
	var character_rows: Array = characters_value.get("characters", [])
	var ordinary_rows: Array = ordinary_value.get("ordinary_customers", [])
	for row in character_rows + ordinary_rows:
		_expect(row is Dictionary and VALID_PACKING_PREFERENCES.has(String(row.get("packing_preference", ""))), "every named or ordinary customer declares a supported packing preference")
	var customers = CustomerManagerScript.new()
	customers.setup(character_rows, ordinary_rows)
	var named_customer: Dictionary = customers._make_customer("agnes", true)
	var ordinary_customer: Dictionary = customers._make_customer("ordinary_garden_mender", false)
	_expect(String(named_customer.get("packing_preference", "")) == "careful", "named customer preference is propagated into the live visitor record")
	_expect(String(ordinary_customer.get("packing_preference", "")) == "reusable", "ordinary archetype preference is propagated into the live visitor record")
	customers.from_save({"active":[{"id":"pip","name":"Pip","essential":true,"state":"CHECKOUT","basket":{"strawberry_milk":1}}], "queue":[], "seen":{}})
	_expect(String(customers.active[0].get("packing_preference", "")) == "reusable", "legacy saved visitors recover their preference from current customer definitions")
	var current_preference_payload: Dictionary = customers.to_save()
	customers.from_save({"active":[{"id":"agnes","name":"Agnes","essential":false,"state":"CHECKOUT","basket":{"bread":1},"packing_preference":"reusable"}], "queue":[], "seen":{}})
	_expect(String(customers.active[0].get("packing_preference", "")) == "reusable", "a saved visitor retains a valid preference across save restoration")

	var matched_game = await _game_with_customer("packing_match", "reusable", false)
	var matched_coins := int(matched_game.inventory.coins)
	var matched_total: int = int(matched_game.inventory.price_for("milk"))
	var matched_ok: bool = matched_game.checkout_scanned("packing_match", {"milk":1}, "reusable")
	_expect(matched_ok, "matching the requested pack style completes checkout")
	_expect(int(matched_game.shop_progression.proficiency_points.get("hospitality", 0)) == 5, "matching the preference adds one direct point, the two-point preference milestone, the standard checkout point, and the first-checkout milestone")
	_expect(int(matched_game.inventory.coins) == matched_coins + matched_total, "preference bonus leaves the exact basket sale total unchanged")
	_expect(int(matched_game.inventory.revenue) == matched_total, "preference bonus does not add extra Coins to revenue")
	matched_game.queue_free()
	await get_tree().process_frame

	var mismatch_game = await _game_with_customer("packing_mismatch", "reusable", false)
	var mismatch_coins := int(mismatch_game.inventory.coins)
	var mismatch_total: int = int(mismatch_game.inventory.price_for("milk"))
	var mismatch_ok: bool = mismatch_game.checkout_scanned("packing_mismatch", {"milk":1}, "careful")
	_expect(mismatch_ok, "a different valid pack choice still completes checkout")
	_expect(int(mismatch_game.shop_progression.proficiency_points.get("hospitality", 0)) == 2, "a preference mismatch keeps standard checkout and milestone rewards without a penalty")
	_expect(int(mismatch_game.inventory.coins) == mismatch_coins + mismatch_total and int(mismatch_game.inventory.revenue) == mismatch_total, "a preference mismatch leaves sale value unchanged")
	mismatch_game.queue_free()
	await get_tree().process_frame

	var legacy_game = await _game_with_customer("packing_legacy", "paper", false)
	var legacy_ok: bool = legacy_game.checkout_scanned("packing_legacy", {"milk":1})
	_expect(legacy_ok, "legacy checkout calls with no packing argument remain valid")
	_expect(int(legacy_game.shop_progression.proficiency_points.get("hospitality", 0)) == 2, "missing packing choice keeps standard checkout and milestone rewards")
	_expect(String(legacy_game.inventory.latest_refundable_sale().get("payment_tender", "")) == "cash", "legacy Coins checkout defaults safely to cash tender")
	legacy_game.queue_free()
	await get_tree().process_frame

	var card_game = await _game_with_customer("packing_card_tender", "paper", false)
	card_game.customers.active[0]["payment_currency"] = "coins"
	var card_ok: bool = card_game.checkout_scanned("packing_card_tender", {"milk":1}, "paper", "card")
	_expect(card_ok, "explicit card tender completes a scanned Coins checkout")
	_expect(String(card_game.inventory.latest_refundable_sale().get("payment_tender", "")) == "card", "Coins transaction history records card tender")
	card_game.queue_free()
	await get_tree().process_frame

	var invalid_tender_game = await _game_with_customer("packing_invalid_tender", "paper", false)
	invalid_tender_game.customers.active[0]["payment_currency"] = "coins"
	var invalid_tender_ok: bool = invalid_tender_game.checkout_scanned("packing_invalid_tender", {"milk":1}, "paper", "moon_tokens")
	_expect(invalid_tender_ok, "invalid legacy Coins tender falls back without interrupting checkout")
	_expect(String(invalid_tender_game.inventory.latest_refundable_sale().get("payment_tender", "")) == "cash", "invalid tender cannot turn a Coins sale into a supernatural payment")
	invalid_tender_game.queue_free()
	await get_tree().process_frame

	var moon_token_game = await _game_with_customer("packing_token_tender", "paper", false)
	moon_token_game.customers.active[0]["payment_currency"] = "moon_tokens"
	var token_ok: bool = moon_token_game.checkout_scanned("packing_token_tender", {"milk":1}, "paper", "card")
	_expect(token_ok, "supernatural visitor checkout completes without a cash or card requirement")
	var token_sale: Dictionary = moon_token_game.inventory.latest_refundable_sale()
	_expect(String(token_sale.get("currency", "")) == "moon_tokens" and String(token_sale.get("payment_tender", "")) == "moon_tokens", "Moon Token settlement remains automatic despite an irrelevant tender input")
	moon_token_game.queue_free()
	await get_tree().process_frame

	var essential_game = await _game_with_customer("packing_essential", "paper", true)
	var essential_ok: bool = essential_game.checkout_scanned("packing_essential", {"milk":1})
	_expect(essential_ok, "essential visitors can complete the established checkout path without a packing choice")
	_expect(int(essential_game.inventory.revenue) == essential_game.inventory.price_for("milk"), "essential checkout still commits its normal basket sale")
	essential_game.queue_free()
	await get_tree().process_frame
	_finish()

func _game_with_customer(customer_id: String, preference: String, essential: bool) -> Variant:
	var game = GameScript.new()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.save_recovery_required = true
	game.customers.definitions[customer_id] = {"id":customer_id,"name":"Packing Test Visitor","basket":{"milk":1},"packing_preference":preference,"tags":[]}
	game.customers.active.append({"id":customer_id,"name":"Packing Test Visitor","essential":essential,"packing_preference":preference,"basket":{"milk":1},"state":"CHECKOUT","visit_count":0,"service_bonus_eligible":false})
	return game

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)

func _finish() -> void:
	if _failures.is_empty():
		print("Checkout packing checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Checkout packing checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)
