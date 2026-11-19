extends SceneTree

const Decorations = preload("res://scripts/systems/decoration_manager.gd")

var _checks := 0
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_bounds_and_footprints()
	_test_access_and_navigation_protection()
	_test_paths_and_collision_grid()
	_test_transient_access_and_layout_signals()
	_test_room_layout_isolation()
	if _failures.is_empty():
		print("Navigation/layout headless checks passed: %d checks." % _checks)
	else:
		for failure in _failures:
			push_error(failure)
		print("Navigation/layout headless checks failed: %d of %d." % [_failures.size(), _checks])
	quit(0 if _failures.is_empty() else 1)

func _new_manager(size: Vector2i = Vector2i(8, 6)) -> RefCounted:
	var manager = Decorations.new()
	manager.setup([
		{"id": "pot", "footprint": [1, 1], "essential": false},
		{"id": "counter", "footprint": [2, 2], "essential": false},
		{"id": "barrier", "footprint": [1, 5], "essential": false},
		{"id": "essential_counter", "footprint": [1, 1], "essential": true}
	], size)
	manager.access_points = {
		"spawn": Vector2i(0, size.y - 2),
		"exit": Vector2i(size.x - 1, size.y - 2),
		"register": Vector2i(size.x / 2, size.y - 2)
	}
	return manager

func _test_bounds_and_footprints() -> void:
	var manager = _new_manager()
	_check(manager.can_place("counter", Vector2i(0, 0)).ok, "multi-cell furniture fits inside room bounds")
	_check(not manager.can_place("counter", Vector2i(7, 5)).ok, "multi-cell furniture cannot extend beyond room bounds")
	_check(manager.can_place("pot", Vector2i(7, 5), true).ok, "one-cell rotated furniture remains in bounds")
	_check(not manager.can_place("missing", Vector2i(2, 2)).ok, "unknown furniture is rejected")
	_check(manager.place("wide", "counter", Vector2i(2, 2)), "multi-cell furniture can be placed")
	_check(not manager.can_place("pot", Vector2i(3, 3)).ok, "placed footprint cells block overlapping furniture")
	_check(manager.collision_grid().size() == 4, "collision grid contains every occupied footprint cell")

func _test_access_and_navigation_protection() -> void:
	var manager = _new_manager(Vector2i(7, 5))
	manager.access_points = {"spawn": Vector2i(0, 2), "register": Vector2i(3, 2), "exit": Vector2i(6, 2)}
	_check(manager.navigation_is_valid(), "default protected points are mutually reachable")
	_check(not manager.can_place("pot", Vector2i(3, 2)).ok, "placement cannot cover a required access point")
	_check(not manager.can_place("barrier", Vector2i(3, 0)).ok, "placement cannot sever the only route between required areas")
	_check(manager.can_place("pot", Vector2i(1, 1)).ok, "placement that preserves required routes is accepted")
	_check(manager.place("safe", "pot", Vector2i(1, 1)), "valid decoration commits")
	_check(manager.navigation_is_valid(), "committed layout preserves access between protected points")
	_check(not manager.set_access_point("exit", Vector2i(1, 1)), "access points cannot move into occupied cells")
	_check(manager.access_points.exit == Vector2i(6, 2), "rejected access-point change rolls back")

func _test_paths_and_collision_grid() -> void:
	var manager = _new_manager(Vector2i(8, 6))
	_check(manager.place("obstacle", "counter", Vector2i(3, 2)), "route obstacle is placed")
	var route: Array[Vector2i] = manager.find_path(Vector2i(1, 2), Vector2i(6, 2))
	_check(not route.is_empty(), "pathfinder routes around a placed footprint")
	_check(route.front() == Vector2i(1, 2) and route.back() == Vector2i(6, 2), "route includes requested endpoints")
	var route_avoids_furniture := true
	for cell in route:
		if manager.collision_grid().has(cell):
			route_avoids_furniture = false
	_check(route_avoids_furniture, "generated route does not cross furniture collision cells")
	var fixed := [Vector2i(2, 1)]
	var fixed_route: Array[Vector2i] = manager.find_path(Vector2i(1, 1), Vector2i(6, 1), fixed)
	_check(not fixed_route.is_empty() and not fixed_route.has(Vector2i(2, 1)), "pathfinder respects caller-supplied fixed fixtures")
	_check(manager.find_path(Vector2i(-1, 0), Vector2i(1, 1)).is_empty(), "out-of-bounds path endpoints are rejected")

func _test_transient_access_and_layout_signals() -> void:
	var manager = _new_manager(Vector2i(7, 5))
	manager.access_points = {"spawn": Vector2i(0, 2), "exit": Vector2i(6, 2)}
	manager.set_transient_access_points([Vector2i(3, 2)])
	_check(not manager.can_place("barrier", Vector2i(3, 0)).ok, "live transient actors keep their route cell accessible")
	_check(manager.place("temporary_safe", "pot", Vector2i(1, 0)), "safe placement succeeds while transient actors are protected")
	var changes: Array[Dictionary] = []
	manager.layout_changed.connect(func(layout: Dictionary): changes.append(layout))
	_check(manager.place("signal_test", "pot", Vector2i(5, 0)), "placement emits the updated layout")
	_check(changes.size() == 1 and changes[0].has("signal_test"), "layout_changed reports placed objects")
	_check(manager.move("signal_test", Vector2i(5, 3)), "furniture can move to another legal footprint")
	_check(changes.size() == 2 and changes[1]["signal_test"].origin == Vector2i(5, 3), "moving furniture emits its new layout")
	_check(manager.remove("signal_test"), "nonessential furniture can be removed")
	_check(changes.size() == 3 and not changes[2].has("signal_test"), "removal emits a layout without the object")
	_check(manager.place("fixed_test", "essential_counter", Vector2i(5, 0)), "essential furniture can be placed")
	_check(not manager.remove("fixed_test"), "essential furniture cannot be removed")

func _test_room_layout_isolation() -> void:
	var manager = _new_manager()
	_check(manager.place("shop_pot", "pot", Vector2i(3, 3)), "shop layout item is placed")
	manager.set_fixed_obstacles([Vector2i(0, 0)])
	manager.set_room("tea_corner")
	_check(manager.placed.is_empty(), "new room starts with its own empty layout")
	_check(not manager.is_fixed_obstacle(Vector2i(0, 0)), "fixed obstacles do not leak into another room")
	_check(manager.place("tea_counter", "counter", Vector2i(2, 2)), "separate room accepts its own layout")
	manager.set_room("moonmart")
	_check(manager.placed.has("shop_pot") and not manager.placed.has("tea_counter"), "returning restores the original room layout")
	_check(manager.is_fixed_obstacle(Vector2i(0, 0)), "returning restores room-specific fixed collision")
	_check(manager.navigation_is_valid(), "restored room retains a valid protected route")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append("FAIL: %s" % message)
	else:
		print("PASS: %s" % message)
