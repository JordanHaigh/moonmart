class_name MoonmartDecorations
extends RefCounted

## Grid-backed placement rejects overlaps and any layout that cuts off a required
## shop interaction, entrance, exit, or checkout lane.
signal layout_changed(layout: Dictionary)
signal placement_rejected(instance_id: String, reason: String)

var grid_size := Vector2i(24, 10)
var furniture: Dictionary = {}
var placed: Dictionary = {}
var fixed_obstacles: Dictionary = {}
var access_points: Dictionary = {"spawn": Vector2i(1, 8), "exit": Vector2i(22, 8), "register": Vector2i(17, 8)}
## Live actors become temporary protected route points while placement is open.
## This state is deliberately excluded from save data.
var transient_access_points: Array[Vector2i] = []
## Each authored room owns its own layout. The flat `placed` map remains the
## active room's working set so existing placement and collision callers stay
## compatible while room transitions swap the state beneath them.
var active_room_id := "moonmart"
var room_layouts: Dictionary = {}
var room_fixed_obstacles: Dictionary = {}

func setup(furniture_rows: Array, size: Vector2i = Vector2i(24, 10)) -> void:
	grid_size = Vector2i(maxi(1, size.x), maxi(1, size.y))
	furniture.clear()
	for row in furniture_rows:
		if row is Dictionary and row.has("id"):
			furniture[String(row.id)] = row.duplicate(true)

func set_fixed_obstacles(cells: Array) -> void:
	fixed_obstacles.clear()
	for value in cells:
		var cell: Vector2i
		if value is Vector2i:
			cell = value
		elif value is Array and value.size() >= 2:
			cell = Vector2i(int(value[0]), int(value[1]))
		else:
			continue
		if _in_bounds(cell):
			fixed_obstacles[cell] = true
	room_fixed_obstacles[active_room_id] = fixed_obstacles.duplicate(true)

## Saves the outgoing room and activates the requested room's independent
## layout. Existing saves without room keys are migrated to Moonmart on import.
func set_room(room_id: String) -> void:
	var next_room_id := room_id.strip_edges()
	if next_room_id.is_empty() or next_room_id == active_room_id:
		return
	transient_access_points.clear()
	room_layouts[active_room_id] = _export_layout()
	active_room_id = next_room_id
	var saved_obstacles: Dictionary = room_fixed_obstacles.get(active_room_id, {})
	fixed_obstacles = saved_obstacles.duplicate(true)
	if room_layouts.has(active_room_id):
		_import_layout(room_layouts[active_room_id])
	else:
		placed.clear()
		access_points = _default_access_points()
		layout_changed.emit(placed.duplicate(true))

func _default_access_points() -> Dictionary:
	return {"spawn": Vector2i(1, grid_size.y - 2), "exit": Vector2i(grid_size.x - 2, grid_size.y - 2)}

func is_fixed_obstacle(cell: Vector2i) -> bool:
	return fixed_obstacles.has(cell)

## Collision cells shared by runtime physics and route validation. Iterating the
## grid keeps the result deterministic and includes both static fixtures and
## placed furniture footprints.
func collision_grid() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			if _occupied_in(cell, placed):
				cells.append(cell)
	return cells

func set_access_point(access_id: String, cell: Vector2i) -> bool:
	if access_id.is_empty() or not _in_bounds(cell):
		return false
	var previous: Variant = access_points.get(access_id)
	access_points[access_id] = cell
	if not navigation_is_valid():
		if previous is Vector2i:
			access_points[access_id] = previous
		else:
			access_points.erase(access_id)
		return false
	return true

func set_transient_access_points(cells: Array) -> void:
	transient_access_points.clear()
	for value in cells:
		if not value is Vector2i:
			continue
		var cell: Vector2i = value
		if _in_bounds(cell) and not transient_access_points.has(cell):
			transient_access_points.append(cell)

func can_place(furniture_id: String, origin: Vector2i, rotated: bool = false, ignore_instance_id: String = "") -> Dictionary:
	if not furniture.has(furniture_id):
		return {"ok": false, "reason": "unknown_furniture"}
	var footprint := _footprint(furniture[furniture_id], rotated)
	for x in range(origin.x, origin.x + footprint.x):
		for y in range(origin.y, origin.y + footprint.y):
			var cell := Vector2i(x, y)
			if not _in_bounds(cell):
				return {"ok": false, "reason": "outside_room", "cell": cell}
			if _occupied(cell, ignore_instance_id):
				return {"ok": false, "reason": "overlap", "cell": cell}
			for access_id in access_points:
				if access_points[access_id] == cell:
					return {"ok": false, "reason": "blocks_required_interaction", "access_id": access_id, "cell": cell}
	var preview := placed.duplicate(true)
	if not ignore_instance_id.is_empty():
		preview.erase(ignore_instance_id)
	preview["__preview"] = {"furniture_id": furniture_id, "origin": origin, "rotated": rotated}
	if not _navigation_valid_for(preview):
		return {"ok": false, "reason": "blocks_navigation"}
	return {"ok": true, "footprint": footprint}

## Small decor can be visually nudged within its occupied cell without changing
## the grid origin used by collision checks or customer navigation. Offsets are
## expressed in cell units and clamped so the visual anchor stays inside that
## cell. Large and essential furniture remains grid-aligned.
func supports_free_visual_placement(furniture_id: String) -> bool:
	if not furniture.has(furniture_id):
		return false
	var definition: Dictionary = furniture[furniture_id]
	if bool(definition.get("essential", false)) or _footprint(definition, false) != Vector2i.ONE:
		return false
	if int(definition.get("display_slots", 0)) != 0 or int(definition.get("storage_capacity", 0)) != 0:
		return false
	if definition.get("lighting_attachment", null) != null:
		return false
	var states: Variant = definition.get("states", [])
	if not states is Array or states.size() != 1:
		return false
	return String(states[0]).to_lower() in ["placed", "displayed"]

func set_visual_offset(instance_id: String, offset_in_cells: Vector2) -> bool:
	if not placed.has(instance_id):
		return false
	var entry: Dictionary = placed[instance_id]
	if not supports_free_visual_placement(String(entry.get("furniture_id", ""))):
		return false
	var bounded := _read_visual_offset(offset_in_cells)
	if is_zero_approx(bounded.x) and is_zero_approx(bounded.y):
		entry.erase("visual_offset")
	else:
		# Store a JSON-safe pair; Godot Vector2 values are reconstructed on read.
		entry["visual_offset"] = [bounded.x, bounded.y]
	layout_changed.emit(placed.duplicate(true))
	return true

func visual_position_in_cells(instance_id: String) -> Vector2:
	if not placed.has(instance_id):
		return Vector2.ZERO
	var entry: Dictionary = placed[instance_id]
	var origin := _read_cell(entry.get("origin", Vector2i.ZERO))
	return Vector2(origin) + _read_visual_offset(entry.get("visual_offset", [0.0, 0.0]))

func visual_offset_in_cells(instance_id: String) -> Vector2:
	if not placed.has(instance_id):
		return Vector2.ZERO
	return _read_visual_offset(placed[instance_id].get("visual_offset", [0.0, 0.0]))

## Returns the authored gameplay effects for one placed furniture instance.
## Effects are independent of visual/effect layers and never alter their state.
func effects_for_instance(instance_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not placed.has(instance_id):
		return result
	var furniture_id := String(placed[instance_id].get("furniture_id", ""))
	var definition: Dictionary = furniture.get(furniture_id, {})
	for effect in definition.get("gameplay_effects", []):
		if effect is Dictionary and not String(effect.get("id", "")).is_empty():
			result.append(effect.duplicate(true))
	return result

func effect_for_instance(instance_id: String, effect_id: String) -> Dictionary:
	for effect in effects_for_instance(instance_id):
		if String(effect.get("id", "")) == effect_id:
			return effect
	return {}

## Aggregates passive effects from all saved shop-room layouts. Duplicate items
## of the same effect take the strongest value, preventing decor stacking.
func active_effects() -> Dictionary:
	var result: Dictionary = {}
	var room_placements: Array[Dictionary] = [{"room_id":active_room_id, "placed":placed}]
	for saved_room_id in room_layouts:
		if String(saved_room_id) == active_room_id or not room_layouts[saved_room_id] is Dictionary:
			continue
		var saved_layout: Dictionary = room_layouts[saved_room_id]
		var saved_placements: Variant = saved_layout.get("placed", {})
		if saved_placements is Dictionary:
			room_placements.append({"room_id":String(saved_room_id), "placed":saved_placements})
	for room_row in room_placements:
		var placed_room_id := String(room_row.get("room_id", active_room_id))
		var room_items: Dictionary = room_row.get("placed", {})
		for instance_id in room_items:
			var entry: Dictionary = room_items[instance_id]
			var furniture_id := String(entry.get("furniture_id", ""))
			var definition: Dictionary = furniture.get(furniture_id, {})
			for effect in definition.get("gameplay_effects", []):
				if not effect is Dictionary:
					continue
				var effect_id := String(effect.get("id", ""))
				if effect_id.is_empty():
					continue
				var aggregate: Dictionary = result.get(effect_id, effect.duplicate(true))
				aggregate["amount"] = maxf(float(aggregate.get("amount", 0.0)), float(effect.get("amount", 0.0)))
				var instances: Array = aggregate.get("instances", [])
				var instance_key := "%s:%s" % [placed_room_id, String(instance_id)]
				if not instances.has(instance_key):
					instances.append(instance_key)
				aggregate["instances"] = instances
				result[effect_id] = aggregate
	return result

func place(instance_id: String, furniture_id: String, origin: Vector2i, rotated: bool = false) -> bool:
	if instance_id.is_empty() or placed.has(instance_id):
		placement_rejected.emit(instance_id, "invalid_instance_id")
		return false
	var verdict := can_place(furniture_id, origin, rotated)
	if not verdict.ok:
		placement_rejected.emit(instance_id, String(verdict.reason))
		return false
	placed[instance_id] = {"furniture_id": furniture_id, "origin": origin, "rotated": rotated}
	layout_changed.emit(placed.duplicate(true))
	return true

func move(instance_id: String, origin: Vector2i, rotated: bool = false) -> bool:
	if not placed.has(instance_id):
		return false
	var entry: Dictionary = placed[instance_id]
	var verdict := can_place(String(entry.furniture_id), origin, rotated, instance_id)
	if not verdict.ok:
		placement_rejected.emit(instance_id, String(verdict.reason))
		return false
	entry["origin"] = origin
	entry["rotated"] = rotated
	layout_changed.emit(placed.duplicate(true))
	return true

func remove(instance_id: String) -> bool:
	if not placed.has(instance_id) or bool(furniture.get(placed[instance_id].get("furniture_id", ""), {}).get("essential", false)):
		return false
	placed.erase(instance_id)
	layout_changed.emit(placed.duplicate(true))
	return true

func navigation_is_valid() -> bool:
	return _navigation_valid_for(placed)

## Returns an orthogonal cell route around placed furniture and caller-supplied
## fixed fixtures. The path includes the start and target cells when reachable.
func find_path(start: Vector2i, target: Vector2i, fixed_blocked: Array = []) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	if not _in_bounds(start) or not _in_bounds(target):
		return route
	if start == target:
		if _cell_is_walkable(start, fixed_blocked):
			route.append(start)
		return route
	if not _cell_is_walkable(target, fixed_blocked):
		return route
	var parents: Dictionary = {}
	var visited: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var found := false
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for direction in directions:
			var next: Vector2i = current + direction
			if not _in_bounds(next) or visited.has(next):
				continue
			if not _cell_is_walkable(next, fixed_blocked):
				continue
			visited[next] = true
			parents[next] = current
			if next == target:
				found = true
				break
			queue.append(next)
		if found:
			break
	if not found:
		return route
	var cursor := target
	route.append(cursor)
	while cursor != start:
		cursor = parents[cursor]
		route.append(cursor)
	route.reverse()
	return route

func cell_is_walkable(cell: Vector2i, fixed_blocked: Array = []) -> bool:
	return _in_bounds(cell) and _cell_is_walkable(cell, fixed_blocked)

func _cell_is_walkable(cell: Vector2i, fixed_blocked: Array) -> bool:
	if fixed_blocked.has(cell) or fixed_obstacles.has(cell):
		return false
	return not _occupied_in(cell, placed)

func _navigation_valid_for(layout: Dictionary) -> bool:
	var walkable_points: Array[Vector2i] = []
	for access_id in access_points:
		var cell: Vector2i = access_points[access_id]
		if fixed_obstacles.has(cell) or _occupied_in(cell, layout):
			return false
		walkable_points.append(cell)
	for cell in transient_access_points:
		if fixed_obstacles.has(cell) or _occupied_in(cell, layout):
			return false
		walkable_points.append(cell)
	if walkable_points.size() < 2:
		return true
	var reachable := _reachable_from(walkable_points[0], layout)
	for point in walkable_points:
		if not reachable.has(point):
			return false
	return true

func _reachable_from(start: Vector2i, layout: Dictionary) -> Dictionary:
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for direction in directions:
			var next: Vector2i = current + direction
			if not _in_bounds(next) or reached.has(next) or fixed_obstacles.has(next) or _occupied_in(next, layout):
				continue
			reached[next] = true
			queue.append(next)
	return reached

func _occupied(cell: Vector2i, ignore_instance_id: String) -> bool:
	if fixed_obstacles.has(cell):
		return true
	for instance_id in placed:
		if instance_id == ignore_instance_id:
			continue
		if _entry_contains(placed[instance_id], cell):
			return true
	return false

func _occupied_in(cell: Vector2i, layout: Dictionary) -> bool:
	if fixed_obstacles.has(cell):
		return true
	for instance_id in layout:
		if _entry_contains(layout[instance_id], cell):
			return true
	return false

func _entry_contains(entry: Dictionary, cell: Vector2i) -> bool:
	var definition: Dictionary = furniture.get(String(entry.get("furniture_id", "")), {})
	if definition.is_empty():
		return false
	var origin := _read_cell(entry.get("origin", Vector2i.ZERO))
	var size := _footprint(definition, bool(entry.get("rotated", false)))
	return cell.x >= origin.x and cell.y >= origin.y and cell.x < origin.x + size.x and cell.y < origin.y + size.y

func _footprint(definition: Dictionary, rotated: bool) -> Vector2i:
	var footprint := _read_cell(definition.get("footprint", Vector2i.ONE))
	return Vector2i(footprint.y, footprint.x) if rotated else footprint

func _read_cell(raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw
	if raw is Vector2:
		return Vector2i(roundi(raw.x), roundi(raw.y))
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	if raw is Dictionary:
		return Vector2i(int(raw.get("x", 0)), int(raw.get("y", 0)))
	return Vector2i.ONE

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y

func export_state() -> Dictionary:
	room_layouts[active_room_id] = _export_layout()
	var serialized_rooms: Dictionary = {}
	for room_id in room_layouts:
		serialized_rooms[String(room_id)] = room_layouts[room_id].duplicate(true)
	return {"active_room_id": active_room_id, "room_layouts": serialized_rooms, "grid_size": [grid_size.x, grid_size.y], "placed": _export_layout().get("placed", {}), "access_points": _export_layout().get("access_points", {})}

func _export_layout() -> Dictionary:
	var serialized_placed := {}
	for instance_id in placed:
		var row: Dictionary = placed[instance_id].duplicate(true)
		var origin := _read_cell(row.get("origin", Vector2i.ZERO))
		row["origin"] = [origin.x, origin.y]
		serialized_placed[instance_id] = row
	var serialized_access := {}
	for access_id in access_points:
		var cell := _read_cell(access_points[access_id])
		serialized_access[access_id] = [cell.x, cell.y]
	return {"grid_size": [grid_size.x, grid_size.y], "placed": serialized_placed, "access_points": serialized_access}

func import_state(data: Dictionary) -> void:
	transient_access_points.clear()
	room_layouts.clear()
	room_fixed_obstacles.clear()
	if data.has("room_layouts") and data.get("room_layouts") is Dictionary:
		var saved_rooms: Dictionary = data.get("room_layouts", {})
		for room_id in saved_rooms:
			if saved_rooms[room_id] is Dictionary:
				room_layouts[String(room_id)] = saved_rooms[room_id].duplicate(true)
		active_room_id = String(data.get("active_room_id", "moonmart"))
		if not room_layouts.has(active_room_id) and (data.has("placed") or data.has("grid_size")):
			room_layouts[active_room_id] = {"grid_size": data.get("grid_size", [grid_size.x, grid_size.y]), "placed": data.get("placed", {}), "access_points": data.get("access_points", {})}
		if not room_layouts.has("moonmart") and room_layouts.is_empty():
			room_layouts["moonmart"] = {"grid_size": data.get("grid_size", [grid_size.x, grid_size.y]), "placed": data.get("placed", {}), "access_points": data.get("access_points", {})}
	else:
		# Legacy single-room save payload: retain all placed items in the retail room.
		active_room_id = "moonmart"
		room_layouts["moonmart"] = data.duplicate(true)
	_import_layout(room_layouts.get(active_room_id, {"placed": {}, "access_points": _default_access_points()}))
	room_fixed_obstacles[active_room_id] = fixed_obstacles.duplicate(true)

func _import_layout(data: Dictionary) -> void:
	var saved_size := _read_cell(data.get("grid_size", grid_size))
	grid_size = Vector2i(maxi(1, saved_size.x), maxi(1, saved_size.y))
	access_points = data.get("access_points", access_points).duplicate(true)
	for access_id in access_points:
		access_points[access_id] = _read_cell(access_points[access_id])
	placed.clear()
	var requested: Dictionary = data.get("placed", {})
	# Reload deterministically. If a saved piece now overlaps a fixed fixture or
	# blocks a protected route, move it to the nearest legal cell when possible.
	for instance_id in requested:
		var row: Dictionary = requested[instance_id]
		var origin := _read_cell(row.get("origin", Vector2i.ZERO))
		var furniture_id := String(row.get("furniture_id", ""))
		var rotated := bool(row.get("rotated", false))
		var verdict := can_place(furniture_id, origin, rotated)
		if not bool(verdict.get("ok", false)):
			var fallback_origin := Vector2i(-1, -1)
			var fallback_distance := 2147483647
			for y in range(grid_size.y):
				for x in range(grid_size.x):
					var candidate := Vector2i(x, y)
					var distance := absi(candidate.x - origin.x) + absi(candidate.y - origin.y)
					if distance >= fallback_distance:
						continue
					var candidate_verdict := can_place(furniture_id, candidate, rotated)
					if bool(candidate_verdict.get("ok", false)):
						fallback_origin = candidate
						fallback_distance = distance
			if fallback_origin.x < 0:
				continue
			origin = fallback_origin
		var normalized: Dictionary = row.duplicate(true)
		normalized["origin"] = origin
		var normalized_furniture_id := String(normalized.get("furniture_id", ""))
		if supports_free_visual_placement(normalized_furniture_id):
			var visual_offset := _read_visual_offset(normalized.get("visual_offset", [0.0, 0.0]))
			if is_zero_approx(visual_offset.x) and is_zero_approx(visual_offset.y):
				normalized.erase("visual_offset")
			else:
				normalized["visual_offset"] = [visual_offset.x, visual_offset.y]
		else:
			normalized.erase("visual_offset")
		placed[String(instance_id)] = normalized
	layout_changed.emit(placed.duplicate(true))

func _read_visual_offset(raw: Variant) -> Vector2:
	var result := Vector2.ZERO
	if raw is Vector2:
		result = raw
	elif raw is Vector2i:
		result = Vector2(raw)
	elif raw is Array and raw.size() >= 2:
		result = Vector2(float(raw[0]), float(raw[1]))
	elif raw is Dictionary:
		result = Vector2(float(raw.get("x", 0.0)), float(raw.get("y", 0.0)))
	if is_nan(result.x):
		result.x = 0.0
	if is_nan(result.y):
		result.y = 0.0
	return Vector2(clampf(result.x, -0.45, 0.45), clampf(result.y, -0.45, 0.45))
