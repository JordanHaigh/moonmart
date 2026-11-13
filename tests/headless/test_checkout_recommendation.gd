extends Node

const GameScript = preload("res://scripts/core/moonmart_game.gd")

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var candidate_game = await _game_with_customer("recommend_candidate", ["bread", "tea"], {"milk":1}, false)
	var candidate: Dictionary = candidate_game.checkout_recommendation("recommend_candidate")
	_expect(String(candidate.get("product_id", "")) == "bread" and int(candidate.get("count", 0)) == 1, "recommendation selects a stocked favorite outside the customer's basket")
	var current_offer_valid: bool = candidate_game.checkout_recommendation_is_valid("recommend_candidate", {"bread":1})
	_expect(current_offer_valid, "the exact current offer validates · offer=%s expected={bread:1} valid=%s" % [str(candidate), str(current_offer_valid)])
	_expect(not candidate_game.checkout_recommendation_is_valid("recommend_candidate", {"tea":1}), "a different favorite cannot be substituted after the offer is shown")
	_expect(not candidate_game.checkout_recommendation_is_valid("recommend_candidate", {"bread":2}), "recommendation quantity is limited to one")
	candidate_game.queue_free()
	await get_tree().process_frame

	var accept_game = await _game_with_customer("recommend_accept", ["bread", "tea"], {"milk":1}, false)
	var accepted_offer: Dictionary = accept_game.checkout_recommendation("recommend_accept")
	var extra_items := {String(accepted_offer.get("product_id", "")):1}
	var scanned_with_extra := {"milk":1, String(accepted_offer.get("product_id", "")):1}
	var accept_coins_before := int(accept_game.inventory.coins)
	var accept_milk_before := int(accept_game.inventory.quantity("milk"))
	var accept_bread_before := int(accept_game.inventory.quantity(String(accepted_offer.get("product_id", ""))))
	var expected_accept_total := int(accept_game.inventory.price_for("milk")) + int(accept_game.inventory.price_for(String(accepted_offer.get("product_id", ""))))
	var hospitality_before_accept := int(accept_game.shop_progression.proficiency_points.get("hospitality", 0))
	var accept_ok: bool = accept_game.checkout_scanned("recommend_accept", scanned_with_extra, "careful", "card", extra_items)
	_expect(accept_ok, "an accepted recommendation completes when both original and suggested goods are scanned · offer=%s extras=%s scanned=%s customer=%s" % [str(accepted_offer), str(extra_items), str(scanned_with_extra), str(accept_game.customers.get_customer("recommend_accept"))])
	var accepted_sale: Dictionary = accept_game.inventory.latest_refundable_sale()
	_expect(accepted_sale.get("basket", {}) == scanned_with_extra, "the sale ledger atomically contains the original and recommended items · recorded=%s expected=%s" % [str(accepted_sale.get("basket", {})), str(scanned_with_extra)])
	_expect(int(accepted_sale.get("total", 0)) == expected_accept_total and int(accept_game.inventory.coins) == accept_coins_before + expected_accept_total, "recommended items use normal prices and Coins settlement · sale=%s coins=%s before=%s expected_total=%s" % [str(accepted_sale), str(accept_game.inventory.coins), str(accept_coins_before), str(expected_accept_total)])
	_expect(int(accept_game.inventory.quantity("milk")) == accept_milk_before - 1 and int(accept_game.inventory.quantity(String(accepted_offer.get("product_id", "")))) == accept_bread_before - 1, "both items leave stock in the same accepted sale · milk=%s/%s recommendation=%s/%s" % [str(accept_game.inventory.quantity("milk")), str(accept_milk_before), str(accept_game.inventory.quantity(String(accepted_offer.get("product_id", "")))), str(accept_bread_before)])
	_expect(int(accept_game.shop_progression.proficiency_points.get("hospitality", 0)) == hospitality_before_accept + 5, "a completed recommendation adds one direct point, the two-point recommendation milestone, the standard checkout point, and the first-checkout milestone · before=%s after=%s" % [str(hospitality_before_accept), str(accept_game.shop_progression.proficiency_points.get("hospitality", 0))])
	_expect(String(accepted_sale.get("payment_tender", "")) == "card", "the recommendation keeps the player's cash or card choice · recorded=%s" % String(accepted_sale.get("payment_tender", "<none>")))
	accept_game.queue_free()
	await get_tree().process_frame

	var skip_game = await _game_with_customer("recommend_skip", ["bread"], {"milk":1}, false)
	var skip_suggestion: Dictionary = skip_game.checkout_recommendation("recommend_skip")
	var skip_hospitality_before := int(skip_game.shop_progression.proficiency_points.get("hospitality", 0))
	var skip_revenue_before := int(skip_game.inventory.revenue)
	var skip_ok: bool = skip_game.checkout_scanned("recommend_skip", {"milk":1})
	_expect(not skip_suggestion.is_empty(), "skip fixture exposes an optional suggestion")
	_expect(skip_ok, "skipping a recommendation completes the original checkout")
	var skipped_sale: Dictionary = skip_game.inventory.latest_refundable_sale()
	_expect(skipped_sale.get("basket", {}) == {"milk":1} and int(skip_game.inventory.revenue) == skip_revenue_before + int(skip_game.inventory.price_for("milk")), "skipping does not alter the customer's original basket or sale total")
	_expect(int(skip_game.shop_progression.proficiency_points.get("hospitality", 0)) == skip_hospitality_before + 2, "skipping keeps the standard checkout and first-checkout milestone rewards without a recommendation penalty")
	skip_game.queue_free()
	await get_tree().process_frame

	var invalid_game = await _game_with_customer("recommend_invalid", ["bread", "tea"], {"milk":1}, false)
	var invalid_coins_before := int(invalid_game.inventory.coins)
	var invalid_sales_before := int(invalid_game.inventory.sales_count)
	var invalid_ok: bool = invalid_game.checkout_scanned("recommend_invalid", {"milk":1,"tea":1}, "paper", "moon_tokens", {"tea":1})
	_expect(not invalid_ok, "an altered recommendation is rejected rather than applied")
	_expect(int(invalid_game.inventory.sales_count) == invalid_sales_before and int(invalid_game.inventory.coins) == invalid_coins_before and int(invalid_game.inventory.moon_tokens) == 0, "invalid recommendation cannot commit stock or exploit Moon Token settlement")
	var ordinary_after_invalid: bool = invalid_game.checkout_scanned("recommend_invalid", {"milk":1})
	_expect(ordinary_after_invalid, "rejecting an invalid extra still leaves the ordinary basket available to complete")
	invalid_game.queue_free()
	await get_tree().process_frame

	var empty_stock_game = await _game_with_customer("recommend_no_stock", ["bread"], {"milk":1}, false)
	empty_stock_game.inventory.shelf_stock["bread"] = 0
	var unavailable_offer: Dictionary = empty_stock_game.checkout_recommendation("recommend_no_stock")
	_expect(unavailable_offer.is_empty(), "recommendation skips a favorite that has no shelf stock")
	var empty_stock_checkout: bool = empty_stock_game.checkout_scanned("recommend_no_stock", {"milk":1})
	_expect(empty_stock_checkout and int(empty_stock_game.inventory.latest_refundable_sale().get("total", 0)) == int(empty_stock_game.inventory.price_for("milk")), "unavailable recommendation never blocks or changes a regular sale")
	empty_stock_game.queue_free()
	await get_tree().process_frame

	var essential_game = await _game_with_customer("recommend_essential", ["bread"], {"milk":1}, true)
	var essential_offer: Dictionary = essential_game.checkout_recommendation("recommend_essential")
	var essential_sale_ok: bool = essential_game.checkout_scanned("recommend_essential", {"milk":1})
	var essential_customer_after: Dictionary = essential_game.customers.get_customer("recommend_essential")
	_expect(not essential_offer.is_empty(), "an essential visitor may receive an optional recommendation")
	_expect(essential_sale_ok and String(essential_customer_after.get("state", "")) == "LEAVING", "an essential visitor may skip the suggestion and complete the original visit · sale_ok=%s state=%s active_count=%s" % [str(essential_sale_ok), String(essential_customer_after.get("state", "<removed>")), str(essential_game.customers.active.size())])
	_expect(int(essential_game.inventory.latest_refundable_sale().get("total", 0)) == int(essential_game.inventory.price_for("milk")), "essential story access is independent of the suggested item")
	essential_game.queue_free()
	await get_tree().process_frame

	if _failures.is_empty():
		print("Checkout recommendation checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Checkout recommendation checks failed: %d of %d." % [_failures.size(), _checks])
	get_tree().quit(0 if _failures.is_empty() else 1)

func _game_with_customer(customer_id: String, favorites: Array, basket: Dictionary, essential: bool) -> Variant:
	var game = GameScript.new()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.save_recovery_required = true
	var definition := {"id":customer_id,"name":"Recommendation Test Visitor","basket":basket.duplicate(true),"favourite_products":favorites.duplicate(),"tags":[]}
	game.customers.definitions[customer_id] = definition
	game.customers.active.append({"id":customer_id,"name":"Recommendation Test Visitor","basket":basket.duplicate(true),"favourite_products":favorites.duplicate(),"essential":essential,"payment_currency":"coins","state":"CHECKOUT","visit_count":0,"service_bonus_eligible":false,"packing_preference":"paper"})
	return game

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
