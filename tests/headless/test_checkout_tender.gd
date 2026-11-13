extends Node

const GameScript = preload("res://scripts/core/moonmart_game.gd")

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var cash_game = await _game_with_customer("cash", "coins")
	var cash_ok: bool = cash_game.checkout_scanned("tender_cash", {"milk":1}, "paper")
	_expect(cash_ok, "legacy checkout remains accepted without an explicit tender")
	_expect(_latest_tender(cash_game) == "cash", "legacy Coins checkout records cash by default")
	cash_game.queue_free()
	await get_tree().process_frame

	var card_game = await _game_with_customer("card", "coins")
	var card_ok: bool = card_game.checkout_scanned("tender_card", {"milk":1}, "paper", "card")
	_expect(card_ok, "player-selected card tender completes checkout")
	_expect(_latest_tender(card_game) == "card", "Coins transaction history records the selected card tender")
	card_game.queue_free()
	await get_tree().process_frame

	var invalid_game = await _game_with_customer("invalid", "coins")
	var invalid_ok: bool = invalid_game.checkout_scanned("tender_invalid", {"milk":1}, "paper", "moon_tokens")
	_expect(invalid_ok, "invalid tender input does not strand the customer")
	_expect(_latest_tender(invalid_game) == "cash", "invalid tender safely falls back to legacy cash")
	invalid_game.queue_free()
	await get_tree().process_frame

	var token_game = await _game_with_customer("token", "moon_tokens")
	var token_ok: bool = token_game.checkout_scanned("tender_token", {"milk":1}, "paper", "card")
	_expect(token_ok, "supernatural checkout remains automatic without a tender selection")
	_expect(_latest_tender(token_game) == "moon_tokens", "Moon Token sale ignores and never records a cash or card tender")
	token_game.queue_free()
	await get_tree().process_frame

	if _failures.is_empty():
		print("Checkout tender checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Checkout tender checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)

func _game_with_customer(suffix: String, currency: String) -> Variant:
	var game = GameScript.new()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.save_recovery_required = true
	var customer_id := "tender_%s" % suffix
	game.customers.definitions[customer_id] = {"id":customer_id,"name":"Tender Test Visitor","payment_currency":currency,"basket":{"milk":1},"packing_preference":"paper","tags":[]}
	game.customers.active.append({"id":customer_id,"name":"Tender Test Visitor","payment_currency":currency,"essential":false,"packing_preference":"paper","basket":{"milk":1},"state":"CHECKOUT","visit_count":0,"service_bonus_eligible":false})
	return game

func _latest_tender(game: Object) -> String:
	return String(game.inventory.latest_refundable_sale().get("payment_tender", ""))

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
