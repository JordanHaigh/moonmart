class_name MoonmartInventory
extends RefCounted

## Transactional stock service. Total quantities remain available through
## `stock`/`quantity()` while shelf display and backroom storage are tracked
## independently for checkout, replenishment, capacity, and freshness.
signal stock_changed(product_id: String, total: int, shelf: int, storage: int)
signal stock_spoiled(product_id: String, quantity: int, location: String)
signal transaction_recorded(transaction: Dictionary)

var products: Dictionary = {}
var stock: Dictionary = {}
var shelf_stock: Dictionary = {}
var storage_stock: Dictionary = {}
var carried_product_id := ""
var carried_quantity := 0
var stock_lots: Dictionary = {}
var reservations: Dictionary = {}
var sales_ledger: Dictionary = {}
var price_modifiers: Dictionary = {}
var storage_capacity := 120
var coins: int = 24
var moon_tokens: int = 0
var revenue: int = 0
var coins_revenue: int = 0
var moon_tokens_revenue: int = 0
var sales_count: int = 0
var transactions: Array[Dictionary] = []
var prepared_items: Dictionary = {}
var _transaction_sequence := 0

func setup(product_rows: Array, initial_stock: Dictionary = {}) -> void:
	products.clear()
	stock.clear()
	shelf_stock.clear()
	storage_stock.clear()
	carried_product_id = ""
	carried_quantity = 0
	stock_lots.clear()
	reservations.clear()
	sales_ledger.clear()
	price_modifiers.clear()
	transactions.clear()
	_transaction_sequence = 0
	for row in product_rows:
		if row is Dictionary and row.has("id"):
			products[String(row.id)] = row.duplicate(true)
	for product_id in products:
		var amount := int(initial_stock.get(product_id, products[product_id].get("starting_stock", 0)))
		if amount < 0:
			amount = 0
		var shelf_amount := mini(amount, shelf_capacity_for(String(product_id)))
		var storage_amount := amount - shelf_amount
		stock[product_id] = amount
		shelf_stock[product_id] = shelf_amount
		storage_stock[product_id] = storage_amount
		stock_lots[product_id] = []
		_append_freshness_lot(String(product_id), shelf_amount, "shelf")
		_append_freshness_lot(String(product_id), storage_amount, "storage")
		if amount > 0:
			_record_transaction({"reason":"opening_stock", "product_id":String(product_id), "quantity":amount})

func quantity(product_id: String) -> int:
	return int(stock.get(product_id, 0))

func shelf_quantity(product_id: String) -> int:
	return int(shelf_stock.get(product_id, 0))

func storage_quantity(product_id: String) -> int:
	return int(storage_stock.get(product_id, 0))

func is_carrying_stock() -> bool:
	return not carried_product_id.is_empty() and carried_quantity > 0

func pick_up_from_storage(product_id: String) -> Dictionary:
	if not products.has(product_id):
		return {"ok":false, "reason":"unknown_product"}
	if is_carrying_stock():
		return {"ok":false, "reason":"hands_full", "product_id":carried_product_id}
	if storage_quantity(product_id) < 1:
		return {"ok":false, "reason":"insufficient_storage"}
	storage_stock[product_id] = storage_quantity(product_id) - 1
	carried_product_id = product_id
	carried_quantity = 1
	_move_freshness_lots(product_id, 1, "storage", "carried")
	_record_transaction({"reason":"stock_picked_up", "product_id":product_id, "quantity":1, "location":"carried"})
	stock_changed.emit(product_id, quantity(product_id), shelf_quantity(product_id), storage_quantity(product_id))
	return {"ok":true, "product_id":product_id, "quantity":1}

func place_carried_on_shelf(product_id: String) -> Dictionary:
	if not is_carrying_stock():
		return {"ok":false, "reason":"hands_empty"}
	if product_id != carried_product_id:
		return {"ok":false, "reason":"different_product", "carried_product_id":carried_product_id}
	if shelf_quantity(product_id) >= shelf_capacity_for(product_id):
		return {"ok":false, "reason":"shelf_capacity", "available":0}
	shelf_stock[product_id] = shelf_quantity(product_id) + carried_quantity
	_move_freshness_lots(product_id, carried_quantity, "carried", "shelf")
	var placed_quantity := carried_quantity
	carried_product_id = ""
	carried_quantity = 0
	_record_transaction({"reason":"carried_stock_placed", "product_id":product_id, "quantity":placed_quantity, "location":"shelf"})
	stock_changed.emit(product_id, quantity(product_id), shelf_quantity(product_id), storage_quantity(product_id))
	return {"ok":true, "product_id":product_id, "quantity":placed_quantity, "shelf":shelf_quantity(product_id), "storage":storage_quantity(product_id)}

func return_carried_to_storage(product_id: String) -> Dictionary:
	if not is_carrying_stock():
		return {"ok":false, "reason":"hands_empty"}
	if product_id != carried_product_id:
		return {"ok":false, "reason":"different_product", "carried_product_id":carried_product_id}
	if storage_used() + carried_quantity > storage_capacity:
		return {"ok":false, "reason":"storage_capacity"}
	storage_stock[product_id] = storage_quantity(product_id) + carried_quantity
	_move_freshness_lots(product_id, carried_quantity, "carried", "storage")
	var returned_quantity := carried_quantity
	carried_product_id = ""
	carried_quantity = 0
	_record_transaction({"reason":"carried_stock_returned", "product_id":product_id, "quantity":returned_quantity, "location":"storage"})
	stock_changed.emit(product_id, quantity(product_id), shelf_quantity(product_id), storage_quantity(product_id))
	return {"ok":true, "product_id":product_id, "quantity":returned_quantity, "storage":storage_quantity(product_id)}

func shelf_capacity_for(product_id: String) -> int:
	var product: Dictionary = products.get(product_id, {})
	return maxi(1, int(product.get("display_capacity", product.get("display_slots", 10))))

func available_on_shelf(product_id: String, reservation_id: String = "") -> int:
	var held := _reserved_quantity(product_id, reservation_id)
	return maxi(0, shelf_quantity(product_id) - held)

func available_quantity(product_id: String) -> int:
	return available_on_shelf(product_id) + storage_quantity(product_id)

func _reserved_quantity(product_id: String, except_allocation_id: String = "") -> int:
	var held := 0
	for allocation_id in reservations:
		if String(allocation_id) == except_allocation_id:
			continue
		held += int(reservations[allocation_id].get("basket", {}).get(product_id, 0))
	return held

func storage_used() -> int:
	var amount := 0
	for product_id in storage_stock:
		amount += int(storage_stock[product_id])
	return amount

func price_for(product_id: String) -> int:
	var base_price := int(products.get(product_id, {}).get("price", 0))
	return maxi(1, roundi(base_price * float(price_modifiers.get(product_id, 1.0))))

func set_discount(product_id: String, modifier: float = 0.75) -> bool:
	if not products.has(product_id):
		return false
	price_modifiers[product_id] = clampf(modifier, 0.5, 1.0)
	_record_transaction({"reason":"price_discount_set", "product_id":product_id, "modifier":price_modifiers[product_id], "quantity":0})
	return true

func clear_discount(product_id: String) -> bool:
	if not price_modifiers.has(product_id):
		return false
	price_modifiers.erase(product_id)
	_record_transaction({"reason":"price_discount_cleared", "product_id":product_id, "quantity":0})
	return true

func freshness_remaining(product_id: String, location: String = "shelf") -> int:
	var best_before := -1
	for lot in stock_lots.get(product_id, []):
		if String(lot.get("location", "")) != location:
			continue
		var shifts_left := int(lot.get("shifts_left", -1))
		if shifts_left < 0:
			continue
		best_before = shifts_left if best_before < 0 else mini(best_before, shifts_left)
	return best_before

func donate(product_id: String, amount: int = 1) -> Dictionary:
	if amount <= 0 or not products.has(product_id) or available_quantity(product_id) < amount:
		return {"ok":false, "reason":"insufficient_stock"}
	var from_shelf := mini(amount, available_on_shelf(product_id))
	var from_storage := amount - from_shelf
	if from_shelf > 0:
		_remove_stock(product_id, from_shelf, "shelf")
	if from_storage > 0:
		_remove_stock(product_id, from_storage, "storage")
	_record_transaction({"reason":"donation", "product_id":product_id, "quantity":amount})
	return {"ok":true, "product_id":product_id, "quantity":amount}

func can_receive_delivery(product_id: String, amount: int, product_capacity_bonus: int = 0) -> Dictionary:
	if amount <= 0 or not products.has(product_id):
		return {"ok":false, "reason":"invalid_delivery"}
	if bool(products[product_id].get("craft_only", false)):
		return {"ok":false, "reason":"craft_only"}
	var product_limit := int(products[product_id].get("stock_capacity", 20)) + maxi(0, product_capacity_bonus)
	if quantity(product_id) + amount > product_limit:
		return {"ok":false, "reason":"product_capacity", "capacity":product_limit}
	if storage_used() + amount > storage_capacity:
		return {"ok":false, "reason":"storage_capacity", "capacity":storage_capacity}
	return {"ok":true}

## Crafting consumes all ingredients first, then records finished goods in
## backroom storage. Capacity and ingredient checks happen before either side
## of the transaction is committed.
func can_produce(product_id: String, amount: int, ingredients: Dictionary) -> Dictionary:
	if amount <= 0 or not products.has(product_id) or not bool(products[product_id].get("craft_only", false)):
		return {"ok":false, "reason":"invalid_production"}
	var product_limit := int(products[product_id].get("stock_capacity", 20))
	if quantity(product_id) + amount > product_limit:
		return {"ok":false, "reason":"product_capacity", "capacity":product_limit}
	var storage_released := 0
	for ingredient_id in ingredients:
		var count := int(ingredients[ingredient_id])
		var id := String(ingredient_id)
		if count <= 0 or not products.has(id) or available_quantity(id) < count:
			return {"ok":false, "reason":"missing_ingredients", "product_id":id}
		storage_released += maxi(0, count - available_on_shelf(id))
	if storage_used() - storage_released + amount > storage_capacity:
		return {"ok":false, "reason":"storage_capacity", "capacity":storage_capacity}
	return {"ok":true}

func produce(product_id: String, amount: int, ingredients: Dictionary, recipe_id: String) -> Dictionary:
	var verdict := can_produce(product_id, amount, ingredients)
	if not bool(verdict.get("ok", false)):
		return verdict
	if not consume(ingredients, "craft:%s" % recipe_id):
		return {"ok":false, "reason":"missing_ingredients"}
	stock[product_id] = quantity(product_id) + amount
	storage_stock[product_id] = storage_quantity(product_id) + amount
	_append_freshness_lot(product_id, amount, "storage")
	_record_transaction({"reason":"production:%s" % recipe_id, "product_id":product_id, "quantity":amount, "recipe_id":recipe_id, "location":"storage"})
	stock_changed.emit(product_id, quantity(product_id), shelf_quantity(product_id), storage_quantity(product_id))
	return {"ok":true, "product_id":product_id, "quantity":amount, "storage":storage_quantity(product_id)}

## Purchased deliveries are put away in backroom storage; the player chooses
## when to replenish the customer-facing display.
func restock(product_id: String, amount: int, product_capacity_bonus: int = 0) -> bool:
	var verdict := can_receive_delivery(product_id, amount, product_capacity_bonus)
	if not verdict.ok:
		return false
	stock[product_id] = quantity(product_id) + amount
	storage_stock[product_id] = storage_quantity(product_id) + amount
	_append_freshness_lot(product_id, amount, "storage")
	var transaction := {"reason":"delivery_received", "product_id":product_id, "quantity":amount}
	_record_transaction(transaction)
	stock_changed.emit(product_id, quantity(product_id), shelf_quantity(product_id), storage_quantity(product_id))
	return true

func restock_shelf(product_id: String, amount: int) -> Dictionary:
	if amount <= 0 or not products.has(product_id):
		return {"ok":false, "reason":"invalid_quantity"}
	if storage_quantity(product_id) < amount:
		return {"ok":false, "reason":"insufficient_storage", "available":storage_quantity(product_id)}
	var free_slots := shelf_capacity_for(product_id) - shelf_quantity(product_id)
	if free_slots < amount:
		return {"ok":false, "reason":"shelf_capacity", "available":maxi(0, free_slots)}
	storage_stock[product_id] = storage_quantity(product_id) - amount
	shelf_stock[product_id] = shelf_quantity(product_id) + amount
	_move_freshness_lots(product_id, amount, "storage", "shelf")
	_record_transaction({"reason":"shelf_replenishment", "product_id":product_id, "quantity":amount})
	stock_changed.emit(product_id, quantity(product_id), shelf_quantity(product_id), storage_quantity(product_id))
	return {"ok":true, "product_id":product_id, "quantity":amount, "shelf":shelf_quantity(product_id), "storage":storage_quantity(product_id)}

func reserve(allocation_id: String, basket: Dictionary, reason: String = "special_order", shift_number: int = 0) -> Dictionary:
	if allocation_id.is_empty() or reservations.has(allocation_id) or basket.is_empty():
		return {"ok":false, "reason":"invalid_allocation"}
	for product_id in basket:
		var amount := int(basket[product_id])
		if amount <= 0 or not products.has(product_id) or available_on_shelf(String(product_id)) < amount:
			return {"ok":false, "reason":"insufficient_available_stock", "product_id":product_id}
	reservations[allocation_id] = {"basket":basket.duplicate(true), "reason":reason, "shift":shift_number}
	_record_transaction({"reason":"reservation:%s" % reason, "allocation_id":allocation_id, "basket":basket.duplicate(true), "quantity":1})
	return {"ok":true, "allocation_id":allocation_id}

func release_reservation(allocation_id: String) -> bool:
	if not reservations.has(allocation_id):
		return false
	var held: Dictionary = reservations[allocation_id]
	reservations.erase(allocation_id)
	_record_transaction({"reason":"reservation_released", "allocation_id":allocation_id, "basket":held.get("basket", {}).duplicate(true), "quantity":-1})
	return true

func consume(ingredients: Dictionary, reason: String) -> bool:
	for product_id in ingredients:
		var count := int(ingredients[product_id])
		var id := String(product_id)
		if count <= 0 or not products.has(id) or available_on_shelf(id) + storage_quantity(id) < count:
			return false
	for product_id in ingredients:
		var id := String(product_id)
		var remaining := int(ingredients[product_id])
		var from_shelf := mini(remaining, available_on_shelf(id))
		if from_shelf > 0:
			_remove_stock(id, from_shelf, "shelf")
			remaining -= from_shelf
		if remaining > 0:
			_remove_stock(id, remaining, "storage")
		_record_transaction({"reason":reason, "product_id":id, "quantity":-int(ingredients[product_id])})
	return true

func sell(basket: Dictionary, currency: String = "coins", reservation_id: String = "", payment_tender: String = "cash") -> Dictionary:
	var total := 0
	var held_basket: Dictionary = reservations.get(reservation_id, {}).get("basket", {})
	if not reservation_id.is_empty() and held_basket != basket:
		return {"ok":false, "reason":"reservation_mismatch"}
	for product_id in basket:
		var count := int(basket[product_id])
		if count <= 0 or not products.has(product_id) or available_on_shelf(String(product_id), reservation_id) < count:
			return {"ok":false, "reason":"out_of_stock", "product_id":product_id}
		total += price_for(String(product_id)) * count
	# Commit only after all products and any reservation have been validated.
	for product_id in basket:
		var id := String(product_id)
		var count := int(basket[product_id])
		_remove_stock(id, count, "shelf")
	if not reservation_id.is_empty():
		reservations.erase(reservation_id)
	if currency != "moon_tokens":
		currency = "coins"
	if currency == "moon_tokens":
		payment_tender = "moon_tokens"
	elif payment_tender not in ["cash", "card"]:
		payment_tender = "cash"
	coins += total if currency == "coins" else 0
	moon_tokens += total if currency == "moon_tokens" else 0
	coins_revenue += total if currency == "coins" else 0
	moon_tokens_revenue += total if currency == "moon_tokens" else 0
	revenue += total
	sales_count += 1
	_transaction_sequence += 1
	var transaction_id := "sale_%06d" % _transaction_sequence
	var sale_record := {"id":transaction_id, "reason":"sale", "basket":basket.duplicate(true), "currency":currency, "payment_tender":payment_tender, "total":total, "refunded":false}
	sales_ledger[transaction_id] = sale_record.duplicate(true)
	_record_transaction(sale_record)
	return {"ok":true, "transaction_id":transaction_id, "total":total, "currency":currency, "payment_tender":payment_tender, "basket":basket.duplicate(true)}

func refund(transaction_id: String, product_capacity_bonus: int = 0) -> Dictionary:
	if not sales_ledger.has(transaction_id):
		return {"ok":false, "reason":"unknown_sale"}
	var sale: Dictionary = sales_ledger[transaction_id]
	if bool(sale.get("refunded", false)):
		return {"ok":false, "reason":"already_refunded"}
	if String(latest_refundable_sale().get("id", "")) != transaction_id:
		return {"ok":false, "reason":"not_latest_sale"}
	var amount := int(sale.get("total", 0))
	var currency := String(sale.get("currency", "coins"))
	if (currency == "moon_tokens" and moon_tokens < amount) or (currency == "coins" and coins < amount):
		return {"ok":false, "reason":"insufficient_refund_balance", "amount":amount}
	var basket: Dictionary = sale.get("basket", {})
	# Returned goods must fit either display or storage before any value changes.
	var overflow := 0
	for product_id in basket:
		var returned := int(basket[product_id])
		var product_limit := int(products.get(String(product_id), {}).get("stock_capacity", 20)) + maxi(0, product_capacity_bonus)
		if quantity(String(product_id)) + returned > product_limit:
			return {"ok":false, "reason":"product_capacity", "product_id":product_id, "capacity":product_limit}
		var shelf_space := shelf_capacity_for(String(product_id)) - shelf_quantity(String(product_id))
		overflow += maxi(0, returned - shelf_space)
	if storage_used() + overflow > storage_capacity:
		return {"ok":false, "reason":"return_capacity"}
	for product_id in basket:
		var id := String(product_id)
		var returned := int(basket[product_id])
		var shelf_add := mini(returned, shelf_capacity_for(id) - shelf_quantity(id))
		var storage_add := returned - shelf_add
		stock[id] = quantity(id) + returned
		shelf_stock[id] = shelf_quantity(id) + shelf_add
		storage_stock[id] = storage_quantity(id) + storage_add
		_append_freshness_lot(id, shelf_add, "shelf")
		_append_freshness_lot(id, storage_add, "storage")
		stock_changed.emit(id, quantity(id), shelf_quantity(id), storage_quantity(id))
	if currency == "moon_tokens":
		moon_tokens -= amount
		moon_tokens_revenue = maxi(0, moon_tokens_revenue - amount)
	else:
		coins -= amount
		coins_revenue = maxi(0, coins_revenue - amount)
	revenue = maxi(0, revenue - amount)
	sale["refunded"] = true
	sales_ledger[transaction_id] = sale
	_record_transaction({"reason":"refund", "sale_id":transaction_id, "basket":basket.duplicate(true), "currency":currency, "payment_tender":String(sale.get("payment_tender", "moon_tokens" if currency == "moon_tokens" else "cash")), "quantity":amount})
	return {"ok":true, "transaction_id":transaction_id, "amount":amount, "currency":currency, "payment_tender":String(sale.get("payment_tender", "moon_tokens" if currency == "moon_tokens" else "cash"))}

func latest_refundable_sale() -> Dictionary:
	var latest: Dictionary = {}
	var latest_sequence := -1
	for sale_id in sales_ledger:
		var sale: Dictionary = sales_ledger[sale_id]
		if bool(sale.get("refunded", false)):
			continue
		var sequence := String(sale_id).trim_prefix("sale_").to_int()
		if sequence > latest_sequence:
			latest_sequence = sequence
			latest = sale
	return latest.duplicate(true)

func age_stock_by_shift() -> Array[Dictionary]:
	var spoiled: Array[Dictionary] = []
	for product_id in stock_lots:
		var lots: Array = stock_lots[product_id]
		for index in range(lots.size() - 1, -1, -1):
			var lot: Dictionary = lots[index]
			if int(lot.get("shifts_left", -1)) < 0:
				continue
			lot["shifts_left"] = int(lot["shifts_left"]) - 1
			if int(lot["shifts_left"]) > 0:
				continue
			var id := String(product_id)
			var amount := int(lot.get("quantity", 0))
			var location := String(lot.get("location", "shelf"))
			if amount <= 0:
				lots.remove_at(index)
				continue
			stock[id] = maxi(0, quantity(id) - amount)
			if location == "storage":
				storage_stock[id] = maxi(0, storage_quantity(id) - amount)
			elif location == "carried":
				carried_quantity = maxi(0, carried_quantity - amount)
				if carried_quantity == 0:
					carried_product_id = ""
			else:
				shelf_stock[id] = maxi(0, shelf_quantity(id) - amount)
			var row := {"product_id":id, "quantity":amount, "location":location}
			spoiled.append(row)
			_record_transaction({"reason":"spoilage", "product_id":id, "quantity":-amount, "location":location})
			stock_spoiled.emit(id, amount, location)
			stock_changed.emit(id, quantity(id), shelf_quantity(id), storage_quantity(id))
			lots.remove_at(index)
	_reconcile_reservations_after_spoilage()
	return spoiled

func _reconcile_reservations_after_spoilage() -> void:
	var held_by_product: Dictionary = {}
	for allocation_id in reservations.keys():
		var basket: Dictionary = reservations[allocation_id].get("basket", {})
		var still_fulfillable := true
		for product_id in basket:
			var available := shelf_quantity(String(product_id)) - int(held_by_product.get(product_id, 0))
			if int(basket[product_id]) > maxi(0, available):
				still_fulfillable = false
				break
		if not still_fulfillable:
			release_reservation(String(allocation_id))
			continue
		for product_id in basket:
			held_by_product[product_id] = int(held_by_product.get(product_id, 0)) + int(basket[product_id])

func clear_all_discounts() -> void:
	for product_id in price_modifiers.keys():
		clear_discount(String(product_id))

func _remove_stock(product_id: String, amount: int, location: String) -> void:
	if amount <= 0:
		return
	if location == "shelf":
		shelf_stock[product_id] = maxi(0, shelf_quantity(product_id) - amount)
	else:
		storage_stock[product_id] = maxi(0, storage_quantity(product_id) - amount)
	stock[product_id] = maxi(0, quantity(product_id) - amount)
	_remove_freshness_lots(product_id, amount, location)
	stock_changed.emit(product_id, quantity(product_id), shelf_quantity(product_id), storage_quantity(product_id))

func _append_freshness_lot(product_id: String, amount: int, location: String) -> void:
	if amount <= 0:
		return
	var life := int(products.get(product_id, {}).get("shelf_life_shifts", -1))
	if life <= 0:
		return
	if not stock_lots.has(product_id):
		stock_lots[product_id] = []
	stock_lots[product_id].append({"quantity":amount, "location":location, "shifts_left":life})

func _remove_freshness_lots(product_id: String, amount: int, location: String) -> void:
	if not stock_lots.has(product_id):
		return
	var remaining := amount
	var lots: Array = stock_lots[product_id]
	var index := 0
	while index < lots.size() and remaining > 0:
		var lot: Dictionary = lots[index]
		if String(lot.get("location", "")) != location:
			index += 1
			continue
		var taken := mini(remaining, int(lot.get("quantity", 0)))
		lot["quantity"] = int(lot.get("quantity", 0)) - taken
		remaining -= taken
		if int(lot["quantity"]) <= 0:
			lots.remove_at(index)
		else:
			index += 1

func _move_freshness_lots(product_id: String, amount: int, from_location: String, to_location: String) -> void:
	if not stock_lots.has(product_id):
		return
	var remaining := amount
	var lots: Array = stock_lots[product_id]
	var index := 0
	while index < lots.size() and remaining > 0:
		var lot: Dictionary = lots[index]
		if String(lot.get("location", "")) != from_location:
			index += 1
			continue
		var moved := mini(remaining, int(lot.get("quantity", 0)))
		lot["quantity"] = int(lot.get("quantity", 0)) - moved
		lots.append({"quantity":moved, "location":to_location, "shifts_left":int(lot.get("shifts_left", -1))})
		remaining -= moved
		if int(lot["quantity"]) <= 0:
			lots.remove_at(index)
		else:
			index += 1

func _record_transaction(row: Dictionary) -> void:
	var transaction := row.duplicate(true)
	transaction["sequence"] = transactions.size() + 1
	transaction["timestamp_unix"] = int(Time.get_unix_time_from_system())
	transactions.append(transaction)
	transaction_recorded.emit(transaction)

## Record a money movement initiated by another gameplay system through the
## same sequenced, timestamped ledger path used by stock transactions.
func record_transaction(row: Dictionary) -> void:
	if String(row.get("reason", "")).is_empty():
		return
	_record_transaction(row)

func to_save() -> Dictionary:
	var carried_item: Dictionary = {"product_id":carried_product_id, "quantity":carried_quantity} if is_carrying_stock() else {}
	return {"stock":stock.duplicate(true), "shelf_stock":shelf_stock.duplicate(true), "storage_stock":storage_stock.duplicate(true), "carried_item":carried_item, "stock_lots":stock_lots.duplicate(true), "reservations":reservations.duplicate(true), "sales_ledger":sales_ledger.duplicate(true), "price_modifiers":price_modifiers.duplicate(true), "storage_capacity":storage_capacity, "coins":coins, "moon_tokens":moon_tokens, "revenue":revenue, "coins_revenue":coins_revenue, "moon_tokens_revenue":moon_tokens_revenue, "sales_count":sales_count, "transactions":transactions.duplicate(true), "prepared_items":prepared_items.duplicate(true), "transaction_sequence":_transaction_sequence}

func from_save(data: Dictionary) -> void:
	stock = data.get("stock", stock).duplicate(true)
	carried_product_id = ""
	carried_quantity = 0
	var carried_item: Variant = data.get("carried_item", {})
	if carried_item is Dictionary:
		var saved_carried_id := String(carried_item.get("product_id", ""))
		var saved_carried_quantity := int(carried_item.get("quantity", 0))
		if products.has(saved_carried_id) and saved_carried_quantity == 1 and quantity(saved_carried_id) > 0:
			carried_product_id = saved_carried_id
			carried_quantity = saved_carried_quantity
	coins = maxi(0, int(data.get("coins", coins)))
	moon_tokens = maxi(0, int(data.get("moon_tokens", moon_tokens)))
	revenue = maxi(0, int(data.get("revenue", revenue)))
	coins_revenue = maxi(0, int(data.get("coins_revenue", revenue)))
	moon_tokens_revenue = maxi(0, int(data.get("moon_tokens_revenue", 0)))
	sales_count = maxi(0, int(data.get("sales_count", sales_count)))
	transactions.assign(data.get("transactions", []))
	prepared_items = data.get("prepared_items", {}).duplicate(true)
	reservations = data.get("reservations", {}).duplicate(true)
	sales_ledger = data.get("sales_ledger", {}).duplicate(true)
	price_modifiers = data.get("price_modifiers", {}).duplicate(true)
	storage_capacity = maxi(1, int(data.get("storage_capacity", storage_capacity)))
	var highest_sale_sequence := 0
	for sale_id in sales_ledger:
		highest_sale_sequence = maxi(highest_sale_sequence, String(sale_id).trim_prefix("sale_").to_int())
	_transaction_sequence = maxi(int(data.get("transaction_sequence", 0)), highest_sale_sequence)
	if data.has("shelf_stock") and data.has("storage_stock"):
		shelf_stock = data.shelf_stock.duplicate(true)
		storage_stock = data.storage_stock.duplicate(true)
		stock_lots = data.get("stock_lots", {}).duplicate(true)
		for product_id in products:
			if stock_lots.has(product_id):
				continue
			stock_lots[product_id] = []
			_append_freshness_lot(String(product_id), shelf_quantity(String(product_id)), "shelf")
			_append_freshness_lot(String(product_id), storage_quantity(String(product_id)), "storage")
	else:
		# Migrate existing aggregate-only saves without changing total quantities.
		shelf_stock.clear()
		storage_stock.clear()
		stock_lots.clear()
		for product_id in products:
			var amount := quantity(String(product_id))
			var shelf_amount := mini(amount, shelf_capacity_for(String(product_id)))
			shelf_stock[product_id] = shelf_amount
			storage_stock[product_id] = amount - shelf_amount
			stock_lots[product_id] = []
			_append_freshness_lot(String(product_id), shelf_amount, "shelf")
			_append_freshness_lot(String(product_id), amount - shelf_amount, "storage")
