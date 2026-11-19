extends Node

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_script := load("res://scripts/main.gd") as GDScript
	var main_script_parses := main_script != null and main_script.reload() == OK
	_expect(main_script_parses, "main script parses successfully")
	if not main_script_parses:
		_write_report()
		get_tree().quit(1)
		return
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene resource loads")
	if packed != null:
		var instance := packed.instantiate()
		_expect(instance is Node2D, "main scene instantiates as a 2D scene")
		get_tree().root.add_child(instance)
		for _frame in range(20):
			await get_tree().process_frame
		_expect(instance.is_inside_tree(), "main scene survives startup frames")
		for required_member in ["world", "player_body", "player", "miso", "moon_glow", "separate_lighting_layer", "window_effects_layer", "prop_effects_layer"]:
			_expect(instance.get(required_member) != null, "main scene initializes %s" % required_member)
		var interaction_binding := String(instance.call("_binding_label", "interact"))
		_expect(not interaction_binding.contains("Physical"), "key prompts omit the technical Physical-key suffix (got '%s')" % interaction_binding)
		var shop_inspect_targets: Dictionary = instance.call("_hidden_paw_reachable_inspect_targets")
		_expect(String(shop_inspect_targets.get("back_door", "")) == "back_door", "Hidden Paw uses Moonmart's real back-door inspect marker")
		_expect(String(instance.call("_location_target_id", "LostAndFound")) == "passenger_manifest", "Hidden Paw shares LostAndFound's inspect mapping instead of its separate Osric talk target")
		var guide_game: Object = instance.get("game")
		var startup_pause_buttons: Array = instance.get("pause_buttons")
		var expected_resume_label := String(guide_game.call("localize_ui", "pause.button.resume", "Return to Moonmart"))
		_expect(not startup_pause_buttons.is_empty() and (startup_pause_buttons[0] as Button).text == expected_resume_label, "pause menu uses the loaded system-language catalog when its initial controls are built")
		_test_player_position_save_resume(instance, guide_game)
		_test_save_failure_handling(instance, guide_game)
		_test_checkout_packing(instance, guide_game)
		guide_game.set("miso_hidden_paw_guidance", {"clue_id":"door_in_the_wall", "target_id":"back_door", "marker_id":"back_door", "location_id":"moonmart"})
		instance.call("_sync_hidden_paw_marker")
		var guide_marker := instance.get("hidden_paw_marker") as Label
		_expect(guide_marker != null and guide_marker.visible and guide_marker.global_position.distance_to(Vector2(1454, 542)) < 0.1, "Hidden Paw renders its pointer at the marked physical target")
		guide_game.set("miso_hidden_paw_guidance", {})
		instance.call("_sync_hidden_paw_marker")
		_expect(guide_marker != null and not guide_marker.visible, "Hidden Paw pointer hides when guidance is cleared")
		var ambient_miso := instance.get("miso") as Sprite2D
		var ambient_manager = instance.get("miso_ambient_manager")
		var ambient_clock: Object = guide_game.get("clock")
		var saved_shift_status := String(guide_game.get("shift_status"))
		var saved_clock_running := bool(ambient_clock.get("running"))
		var saved_clock_paused := bool(ambient_clock.get("paused"))
		var saved_clock_elapsed := float(ambient_clock.get("elapsed_minutes"))
		var saved_panel := String(instance.get("active_panel"))
		var saved_message_open := bool(instance.get("message_open"))
		var saved_reduced_animation := bool(instance.get("reduced_animation_enabled"))
		var saved_recovery_required := bool(guide_game.get("save_recovery_required"))
		var saved_miso_position := ambient_miso.global_position if ambient_miso != null else Vector2.ZERO
		var saved_story_flags: Dictionary = guide_game.story.flags.duplicate(true)
		var saved_coins := int(guide_game.inventory.coins)
		var saved_revenue := int(guide_game.inventory.revenue)
		guide_game.set("save_recovery_required", false)
		guide_game.set("shift_status", "open")
		ambient_clock.set("running", true)
		ambient_clock.set("paused", false)
		ambient_clock.set("elapsed_minutes", float(ambient_clock.get("prep_minutes")) + 1.0)
		instance.set("active_panel", "")
		instance.set("message_open", false)
		instance.set("reduced_animation_enabled", false)
		ambient_manager.setup([{"id":"receipt_test", "anchor":"receipt_register", "duration_seconds":5.0, "cooldown_seconds":18.0, "weight":1.0}], 90210, 0.0, 0.0, 10.0, 10.0)
		var ambient_route: Array = instance.call("_make_shop_route", ambient_miso.global_position, Vector2(1068, 616)) if ambient_miso != null else []
		_expect(not ambient_route.is_empty(), "Miso's authored register perch has a collision-safe path")
		for anchor_id_value in guide_game.miso_companion.ambient_anchors:
			var anchor_id := String(anchor_id_value)
			var anchor_position: Array = guide_game.miso_companion.ambient_anchors[anchor_id]
			var anchor_route: Array = instance.call("_make_shop_route", ambient_miso.global_position, Vector2(float(anchor_position[0]), float(anchor_position[1]))) if ambient_miso != null else []
			_expect(not anchor_route.is_empty() or (ambient_miso != null and ambient_miso.global_position.distance_to(Vector2(float(anchor_position[0]), float(anchor_position[1]))) <= 4.0), "Miso's authored %s anchor has a collision-safe path" % anchor_id)
		instance.call("_process_miso_ambient", 0.1)
		var ambient_start := ambient_miso.global_position if ambient_miso != null else Vector2.ZERO
		for _step in range(180):
			instance.call("_process_miso_ambient", 0.5)
			if not ambient_manager.waiting_for_arrival() and not ambient_manager.current_behavior().is_empty():
				break
		_expect(ambient_miso != null and ambient_miso.global_position.distance_to(ambient_start) > 5.0, "Miso walks toward an ambient anchor with its normal scene movement")
		_expect(not ambient_manager.waiting_for_arrival() and String(ambient_manager.current_behavior().get("id", "")) == "receipt_test", "the ambient behavior enters its idle perch only after reaching the target")
		var position_at_arrival := ambient_miso.global_position if ambient_miso != null else Vector2.ZERO
		var dwell_at_arrival: float = ambient_manager.active_remaining_seconds()
		instance.set("active_panel", "companion")
		instance.call("_process_miso_ambient", 2.0)
		_expect(ambient_miso != null and ambient_miso.global_position.distance_to(position_at_arrival) < 0.1 and is_equal_approx(ambient_manager.active_remaining_seconds(), dwell_at_arrival), "companion panels suspend Miso movement and behavior timers")
		instance.set("active_panel", "")
		instance.set("reduced_animation_enabled", true)
		instance.call("_process_miso_ambient", 2.0)
		_expect(ambient_miso != null and ambient_miso.global_position.distance_to(position_at_arrival) < 0.1 and is_equal_approx(ambient_manager.active_remaining_seconds(), dwell_at_arrival), "reduced animation suspends Miso movement and behavior timers")
		_expect(guide_game.story.flags == saved_story_flags and int(guide_game.inventory.coins) == saved_coins and int(guide_game.inventory.revenue) == saved_revenue, "ambient companion activity does not change story flags or shop economy")
		var vase_sprite := instance.get("miso_knockable_vase") as Sprite2D
		var vase_region: Rect2 = instance.call("_grid_region", "res://assets/raster/furniture/moonmart_counter_accessories_atlas_1280.png", 1, 2, 4, 4)
		_expect(vase_sprite != null and vase_sprite.texture.resource_path.ends_with("moonmart_counter_accessories_atlas_1280.png") and vase_sprite.region_enabled and vase_sprite.region_rect == vase_region and vase_sprite.get_meta("ambient_source_region", Vector2i(-1, -1)) == Vector2i(1, 2), "knock prop uses only the reviewed flower-bud-vase raster cell [1,2]")
		_expect(vase_sprite != null and vase_sprite.position == Vector2(1080, 482), "isolated vase sits on the checkout counter at its authored safe point")
		var vase_baseline: Transform2D = vase_sprite.transform if vase_sprite != null else Transform2D.IDENTITY
		var knock_inventory_before: Dictionary = guide_game.inventory.to_save().duplicate(true)
		var knock_decor_before: Dictionary = guide_game.decoration.export_state().duplicate(true)
		var knock_behavior := {"id":"knock_flower_vase", "anchor":"receipt_register", "requires_prop":"flower_bud_vase", "duration_seconds":2.2, "cooldown_seconds":120.0, "weight":1.0}
		instance.set("reduced_animation_enabled", false)
		ambient_miso.global_position = Vector2(1068, 616)
		ambient_manager.setup([knock_behavior], 441, 0.0, 0.0, 2.0, 2.0)
		instance.call("_process_miso_ambient", 0.1)
		for _step in range(8):
			instance.call("_process_miso_ambient", 0.1)
			if bool(instance.get("miso_vase_knock_active")):
				break
		_expect(ambient_manager.current_behavior().size() > 0 and not ambient_manager.waiting_for_arrival() and vase_sprite != null and vase_sprite.transform == vase_baseline, "Miso reaches the receipt-register approach before beginning the vase knock")
		instance.call("_process_miso_ambient", 0.15)
		_expect(vase_sprite != null and not vase_sprite.transform.is_equal_approx(vase_baseline), "arrived Miso tips the isolated vase briefly")
		instance.call("_process_miso_ambient", 1.6)
		_expect(vase_sprite != null and vase_sprite.transform == vase_baseline, "vase returns exactly to its baseline transform after the brief tip")
		instance.call("_process_miso_ambient", 0.6)
		_expect(ambient_manager.current_behavior().is_empty() and ambient_manager.cooldown_seconds("knock_flower_vase") == 120.0, "completed vase knock receives its deterministic authored cooldown")
		ambient_manager.setup([knock_behavior], 442, 0.0, 0.0, 2.0, 2.0)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.15)
		instance.set("active_panel", "companion")
		instance.call("_process_miso_ambient", 0.1)
		_expect(vase_sprite != null and vase_sprite.transform == vase_baseline and ambient_manager.current_behavior().is_empty() and ambient_manager.cooldown_seconds("knock_flower_vase") == 0.0, "opening a panel restores the exact vase transform and cancels without cooldown")
		instance.set("active_panel", "")
		ambient_manager.setup([knock_behavior], 443, 0.0, 0.0, 2.0, 2.0)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.15)
		instance.set("reduced_animation_enabled", true)
		instance.call("_process_miso_ambient", 0.1)
		_expect(vase_sprite != null and vase_sprite.transform == vase_baseline and not bool(instance.get("miso_vase_knock_active")), "reduced animation immediately restores the vase")
		instance.set("reduced_animation_enabled", false)
		ambient_manager.setup([knock_behavior], 444, 0.0, 0.0, 2.0, 2.0)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.15)
		instance.set("message_open", true)
		instance.call("_process_miso_ambient", 0.1)
		_expect(vase_sprite != null and vase_sprite.transform == vase_baseline and not bool(instance.get("miso_vase_knock_active")), "dialogue immediately restores the vase")
		instance.set("message_open", false)
		ambient_manager.setup([knock_behavior], 443, 0.0, 0.0, 2.0, 2.0)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.15)
		ambient_clock.set("paused", true)
		instance.call("_process_miso_ambient", 0.1)
		_expect(vase_sprite != null and vase_sprite.transform == vase_baseline and not bool(instance.get("miso_vase_knock_active")), "pause immediately restores the vase")
		ambient_clock.set("paused", false)
		ambient_manager.setup([knock_behavior], 445, 0.0, 0.0, 2.0, 2.0)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.1)
		instance.call("_process_miso_ambient", 0.15)
		instance.set("current_location_id", "whisperwood")
		instance.call("_process_miso_ambient", 0.1)
		_expect(vase_sprite != null and vase_sprite.transform == vase_baseline and ambient_manager.current_behavior().is_empty(), "leaving Moonmart immediately restores the vase and cancels its approach")
		instance.set("current_location_id", "moonmart")
		var unreachable_behavior: Dictionary = knock_behavior.duplicate(true)
		unreachable_behavior["anchor"] = "missing_anchor"
		ambient_manager.setup([unreachable_behavior], 447, 0.0, 0.0, 2.0, 2.0)
		instance.call("_process_miso_ambient", 0.1)
		_expect(ambient_manager.current_behavior().is_empty() and ambient_manager.cooldown_seconds("knock_flower_vase") == 0.0, "unreachable vase approach cancels without consuming a cooldown")
		_expect(guide_game.story.flags == saved_story_flags and guide_game.inventory.to_save() == knock_inventory_before and guide_game.decoration.export_state() == knock_decor_before, "vase knock leaves story, inventory, and saved decoration layout unchanged")
		ambient_manager.setup(guide_game.miso_companion.ambient_behaviors, int(guide_game.miso_companion.ambient_behavior_timing.get("seed", 74219)))
		instance.set("active_panel", saved_panel)
		instance.set("message_open", saved_message_open)
		instance.set("reduced_animation_enabled", saved_reduced_animation)
		guide_game.set("shift_status", saved_shift_status)
		guide_game.set("save_recovery_required", saved_recovery_required)
		ambient_clock.set("running", saved_clock_running)
		ambient_clock.set("paused", saved_clock_paused)
		ambient_clock.set("elapsed_minutes", saved_clock_elapsed)
		if ambient_miso != null:
			ambient_miso.global_position = saved_miso_position
			instance.set("miso_previous_position", saved_miso_position)
		var hud := instance.get("hud_layer") as CanvasLayer
		var controls_hint_label := hud.get_node_or_null("HudControlsHint") as Label if hud != null else null
		_expect(controls_hint_label != null and controls_hint_label.text.contains(interaction_binding) and controls_hint_label.text.contains("W/A/S/D"), "bottom HUD hint shows current keyboard bindings (got '%s')" % (controls_hint_label.text if controls_hint_label != null else "missing label"))
		_expect(controls_hint_label != null and controls_hint_label.autowrap_mode != TextServer.AUTOWRAP_OFF and controls_hint_label.size.y >= 44.0, "bottom HUD hint wraps longer localized and readable-mode controls copy")
		var message_panel := hud.get_node_or_null("HudMessagePanel") as Control if hud != null else null
		_expect(message_panel != null and message_panel.size.y >= 190.0, "dialogue panel has enough height for the nine-patch frame margins")
		_expect(not (instance.get("speed_label") as Control).visible, "shift pace label stays hidden during ordinary play")
		_expect(int(instance.call("_miso_animation_frame", "closed", false, 0.0, 0.0, false, 0)) == 0, "Miso uses the sleep frame between shifts")
		_expect(int(instance.call("_miso_animation_frame", "open", false, 0.0, 0.0, false, 0)) == 1, "Miso uses the seated idle pose during a shift")
		_expect(int(instance.call("_miso_animation_frame", "open", true, 0.0, 0.0, false, 0)) == 2, "Miso uses the walk pose while moving")
		_expect(int(instance.call("_miso_animation_frame", "open", false, 4.0, 4.0, false, 0)) == 4, "Miso's play pose follows the play interaction")
		_expect(int(instance.call("_miso_animation_frame", "open", false, 0.0, 4.0, false, 0)) == 5, "Miso's purr pose follows the active care purr")
		_expect(int(instance.call("_miso_animation_frame", "open", false, 0.0, 0.0, false, 20000)) == 3, "Miso's stretch pose appears during the idle cycle")
		_expect(int(instance.call("_miso_animation_frame", "open", false, 0.0, 0.0, true, 20000)) == 1, "reduced animation keeps Miso on the seated idle pose")
		var agnes_animation_probe := Sprite2D.new()
		instance.call("_update_agnes_animation", agnes_animation_probe, "CONVERSING", false)
		_expect(agnes_animation_probe.texture != null and agnes_animation_probe.texture.resource_path.ends_with("agnes_talk_pose.png") and not agnes_animation_probe.region_enabled, "Agnes uses the standalone talk pose during normal conversation")
		instance.call("_update_agnes_animation", agnes_animation_probe, "CONVERSING", true)
		var agnes_idle_region: Rect2 = instance.call("_grid_region", "res://assets/raster/characters/agnes_atlas.png", 0, 0, 4, 1)
		_expect(agnes_animation_probe.texture != null and agnes_animation_probe.texture.resource_path.ends_with("agnes_atlas.png") and agnes_animation_probe.region_enabled and agnes_animation_probe.region_rect == agnes_idle_region, "reduced animation keeps Agnes on her atlas idle frame while conversing")
		agnes_animation_probe.free()
		var location_npc_animation_probe := Sprite2D.new()
		instance.call("_update_location_npc_animation", location_npc_animation_probe, "agnes", true, 0)
		_expect(location_npc_animation_probe.texture != null and location_npc_animation_probe.texture.resource_path.ends_with("agnes_talk_pose.png") and not location_npc_animation_probe.region_enabled, "outdoor Agnes conversations use the same isolated talk pose as shop conversations")
		instance.call("_update_location_npc_animation", location_npc_animation_probe, "conductor", true, 0)
		var conductor_offer_region: Rect2 = instance.call("_grid_region", "res://assets/raster/characters/conductor_atlas.png", 2, 0, 4, 1)
		_expect(location_npc_animation_probe.texture != null and location_npc_animation_probe.texture.resource_path.ends_with("conductor_atlas.png") and location_npc_animation_probe.region_enabled and location_npc_animation_probe.region_rect == conductor_offer_region, "outdoor Conductor conversation uses the offer-ticket frame")
		instance.call("_update_location_npc_animation", location_npc_animation_probe, "wren", true, 2800)
		_expect(location_npc_animation_probe.texture != null and location_npc_animation_probe.texture.resource_path.ends_with("wren_cast_magic_pose.png") and not location_npc_animation_probe.region_enabled, "outdoor Wren conversation includes her isolated casting gesture")
		instance.set("reduced_animation_enabled", true)
		instance.call("_update_location_npc_animation", location_npc_animation_probe, "wren", true, 2800)
		var wren_talk_region: Rect2 = instance.call("_grid_region", "res://assets/raster/characters/wren_atlas.png", 3, 0, 4, 1)
		_expect(location_npc_animation_probe.texture != null and location_npc_animation_probe.texture.resource_path.ends_with("wren_atlas.png") and location_npc_animation_probe.region_enabled and location_npc_animation_probe.region_rect == wren_talk_region, "reduced animation holds Wren's static talk pose without casting")
		instance.set("reduced_animation_enabled", saved_reduced_animation)
		location_npc_animation_probe.free()
		_expect(int(instance.call("_pip_blink_frame", 100)) == 1 and int(instance.call("_pip_blink_frame", 500)) == 0 and int(instance.call("_pip_blink_frame", 3700)) == 1, "Pip blinks briefly once per 3.6-second interval")
		_expect(int(instance.call("_visitor_browse_frame", "conductor", 0, false)) == 3, "Conductor reads the passenger manifest while browsing")
		_expect(int(instance.call("_visitor_browse_frame", "elias", 0, false)) == 2, "Elias inspects the lighthouse lens while browsing")
		_expect(int(instance.call("_visitor_browse_frame", "mara", 0, false)) == 2, "Mara offers a letter while browsing")
		_expect(int(instance.call("_visitor_browse_frame", "osric", 0, false)) == 2, "Osric reads the ticket while browsing")
		_expect(int(instance.call("_visitor_browse_frame", "fern", 0, false)) == 2 and int(instance.call("_visitor_browse_frame", "lucien", 0, false)) == 2, "Fern and Lucien keep their authored plant-inspection and reading poses while browsing")
		_expect(int(instance.call("_visitor_browse_frame", "wren", 2800, false)) == 2 and int(instance.call("_visitor_browse_frame", "wren", 2800, true)) == 0, "Wren alternates her herb-inspection pose and holds the base pose with reduced animation")
		var world := instance.get("world") as Node2D
		if world != null:
			for required_layer in ["NightSkyLayer", "ExteriorParallaxLayer", "SeparateLightingLayer", "WindowEffectsLayer", "ArchitectureLayer", "BackgroundFurnitureLayer", "DepthSortedCharactersLayer", "ForegroundFurnitureLayer", "PropEffectsLayer"]:
				_expect(world.get_node_or_null(required_layer) != null, "world has Section 27 layer %s" % required_layer)
			var architecture := world.get_node_or_null("ArchitectureLayer") as CanvasItem
			var window_effects := instance.get("window_effects_layer") as CanvasItem
			var prop_effects := instance.get("prop_effects_layer") as CanvasItem
			var separate_lighting := instance.get("separate_lighting_layer") as CanvasItem
			instance.call("_apply_visual_comfort_settings", false, false, false)
			_expect(window_effects != null and not window_effects.visible, "visual-effects setting hides window VFX layer")
			_expect(prop_effects != null and not prop_effects.visible, "visual-effects setting hides prop VFX layer")
			_expect(architecture != null and architecture.visible, "disabling visual effects preserves the painted architecture plate")
			instance.call("_apply_visual_comfort_settings", true, false, false)
			instance.call("_apply_dynamic_lighting_setting", false)
			_expect(separate_lighting != null and not separate_lighting.visible, "dynamic-lighting setting hides separate lighting layer")
			instance.call("_apply_dynamic_lighting_setting", true)
			instance.call("_apply_visual_comfort_settings", false, false, false)
			instance.call("_apply_dynamic_lighting_setting", false)
			var game: Object = instance.get("game")
			var money_hud := hud.get_node_or_null("HudMoneyPanel") as Control if hud != null else null
			var controls_hint := hud.get_node_or_null("HudControlsHint") as Control if hud != null else null
			var hud_icon_names := ["HudIcon_0_0", "HudIcon_1_0", "HudIcon_2_0"]
			for icon_name in hud_icon_names:
				var icon := hud.get_node_or_null(String(icon_name)) as Control if hud != null else null
				_expect(icon != null and icon.size.x <= 40.0 and icon.size.y <= 40.0, "%s stays within its compact default HUD icon bounds" % String(icon_name))
			instance.call("_apply_settings_ui_scale", 0.75)
			await get_tree().process_frame
			var viewport_size := get_viewport().get_visible_rect().size
			var minimum_money_bounds := Rect2(money_hud.position * 0.75, money_hud.size * 0.75) if money_hud != null else Rect2()
			var minimum_hint_bounds := Rect2(controls_hint.position * 0.75, controls_hint.size * 0.75) if controls_hint != null else Rect2()
			_expect(money_hud != null and minimum_money_bounds.position.x >= -0.5 and minimum_money_bounds.end.x <= viewport_size.x + 0.5, "minimum UI scale keeps the right-edge money panel inside the viewport")
			_expect(controls_hint != null and minimum_hint_bounds.position.x >= -0.5 and minimum_hint_bounds.position.y >= -0.5 and minimum_hint_bounds.end.x <= viewport_size.x + 0.5 and minimum_hint_bounds.end.y <= viewport_size.y + 0.5, "minimum UI scale keeps the bottom controls hint inside the viewport")
			instance.call("_apply_settings_ui_scale", 1.12)
			await get_tree().process_frame
			var maximum_money_bounds := Rect2(money_hud.position * 1.12, money_hud.size * 1.12) if money_hud != null else Rect2()
			var maximum_hint_bounds := Rect2(controls_hint.position * 1.12, controls_hint.size * 1.12) if controls_hint != null else Rect2()
			_expect(money_hud != null and maximum_money_bounds.position.x >= -0.5 and maximum_money_bounds.end.x <= viewport_size.x + 0.5, "maximum UI scale keeps the right-edge money panel inside the viewport")
			_expect(controls_hint != null and maximum_hint_bounds.position.x >= -0.5 and maximum_hint_bounds.position.y >= -0.5 and maximum_hint_bounds.end.x <= viewport_size.x + 0.5 and maximum_hint_bounds.end.y <= viewport_size.y + 0.5, "maximum UI scale keeps the bottom controls hint inside the viewport")
			for icon_name in hud_icon_names:
				var icon := hud.get_node_or_null(String(icon_name)) as Control if hud != null else null
				_expect(icon != null and icon.size.x <= 45.0 and icon.size.y <= 45.0, "%s stays compact at maximum UI scale" % String(icon_name))
			instance.call("_apply_settings_ui_scale", 1.0)
			var settings_panel := instance.get("settings_panel") as CanvasLayer
			for scale_value in [0.75, 1.12]:
				instance.call("_apply_settings_ui_scale", float(scale_value))
				settings_panel.call("open")
				settings_panel.call("set_ui_scale", float(scale_value))
				await get_tree().process_frame
				var settings_dialog := settings_panel.get_node_or_null("SettingsOverlay/SettingsJournalPanel") as Control
				var settings_viewport := get_viewport().get_visible_rect().size
				var settings_bounds := Rect2(settings_dialog.position, settings_dialog.size * float(scale_value)) if settings_dialog != null else Rect2()
				_expect(settings_dialog != null and settings_bounds.position.x >= -0.5 and settings_bounds.position.y >= -0.5 and settings_bounds.end.x <= settings_viewport.x + 0.5 and settings_bounds.end.y <= settings_viewport.y + 0.5, "settings dialog at %s UI scale stays within the viewport" % str(scale_value))
				var focused_control := get_viewport().gui_get_focus_owner()
				_expect(settings_panel.is_open() and focused_control != null and settings_panel.is_ancestor_of(focused_control), "settings at %s UI scale opens with keyboard focus inside its controls" % str(scale_value))
				settings_panel.call("close")
				instance.call("_apply_settings_ui_scale", 1.0)
			instance.call("_apply_visual_comfort_settings", false, false, false)
			instance.call("_apply_dynamic_lighting_setting", false)
			instance.call("_toggle_panel", "inventory")
			await get_tree().process_frame
			var inventory_label := instance.get("side_label") as Label
			var inventory_scroll := instance.get("side_scroll") as ScrollContainer
			var inventory_manager: Object = game.get("inventory")
			var inventory_products: Dictionary = inventory_manager.get("products")
			_expect(inventory_products.size() == 150, "inventory smoke covers the full product catalog")
			_expect(inventory_label != null and inventory_label.text.split("\n").size() >= 152, "inventory panel renders every product row")
			_expect(inventory_scroll != null and inventory_scroll.get_v_scroll_bar().max_value > 0.0, "inventory rows exceed the viewport and are reachable by scrolling")
			instance.call("_close_side_panel")
			var world_map: Object = game.get("world_map")
			var unlocked_locations: Array = world_map.get("unlocked_locations")
			if not unlocked_locations.has("whisperwood"):
				unlocked_locations.append("whisperwood")
			world_map.set("unlocked_locations", unlocked_locations)
			for location_id in ["tea_corner", "reading_nook", "enchanted_greenhouse", "old_bellwether", "whisperwood", "moonwater_harbour", "old_lighthouse", "midnight_platform", "shop_backroom", "hidden_midnight_room"]:
				if not unlocked_locations.has(location_id):
					unlocked_locations.append(location_id)
			world_map.set("unlocked_locations", unlocked_locations)
			var all_map_destinations: Array = game.call("available_locations")
			_expect(all_map_destinations.size() >= 11, "map regression unlocks every optional room and all essential destinations")
			if all_map_destinations.size() > 9:
				var story_for_map: Object = game.get("story")
				var original_story_chapter := int(story_for_map.get("chapter"))
				var original_story_flags: Dictionary = story_for_map.get("flags").duplicate(true)
				var original_world_location := String(world_map.get("current_location"))
				var original_recovery_guard := bool(game.get("save_recovery_required"))
				story_for_map.set("chapter", 4)
				var temporary_story_flags: Dictionary = story_for_map.get("flags")
				temporary_story_flags["platform_opened"] = true
				temporary_story_flags["hidden_midnight_room_found"] = true
				game.set("save_recovery_required", true)
				var final_map_destinations: Array[String] = [String(all_map_destinations[all_map_destinations.size() - 2].get("id", "")), String(all_map_destinations[all_map_destinations.size() - 1].get("id", ""))]
				instance.call("_open_map_panel")
				var visible_map_ids: Array = instance.get("map_location_ids")
				_expect(int(instance.get("map_page")) == 0 and visible_map_ids.size() == 9, "map opens its first nine destinations on page one")
				var map_next_page := InputEventAction.new()
				map_next_page.action = "page_next"
				map_next_page.pressed = true
				instance.call("_unhandled_input", map_next_page)
				await get_tree().process_frame
				visible_map_ids = instance.get("map_location_ids")
				_expect(int(instance.get("map_page")) == 1 and visible_map_ids.size() == all_map_destinations.size() - 9, "page controls expose every remaining map destination")
				for final_slot in range(final_map_destinations.size()):
					var local_slot := visible_map_ids.find(final_map_destinations[final_slot])
					_expect(local_slot >= 0, "the final map page contains destination %s" % final_map_destinations[final_slot])
					if local_slot < 0:
						continue
					var select_destination := InputEventAction.new()
					select_destination.action = "ui_select_%d" % (local_slot + 1)
					select_destination.pressed = true
					instance.call("_unhandled_input", select_destination)
					await get_tree().process_frame
					_expect(String(instance.get("current_location_id")) == final_map_destinations[final_slot], "map selection travels to final-page destination %s" % final_map_destinations[final_slot])
					if final_slot < final_map_destinations.size() - 1:
						instance.call("_open_map_panel")
						var next_final_page := InputEventAction.new()
						next_final_page.action = "page_next"
						next_final_page.pressed = true
						instance.call("_unhandled_input", next_final_page)
						await get_tree().process_frame
				instance.call("_travel_to_location", "moonmart", false)
				world_map.set("current_location", original_world_location)
				story_for_map.set("chapter", original_story_chapter)
				story_for_map.set("flags", original_story_flags)
				game.set("save_recovery_required", original_recovery_guard)
			for location_id in ["tea_corner", "reading_nook", "enchanted_greenhouse", "old_bellwether", "whisperwood", "moonwater_harbour", "old_lighthouse", "midnight_platform", "shop_backroom", "hidden_midnight_room"]:
				instance.call("_travel_to_location", String(location_id), false)
				await get_tree().process_frame
				var location_scene := instance.get("current_location_scene") as Node2D
				_expect(location_scene != null, "Section 27 %s plate loads through the travel path" % String(location_id))
				if location_scene == null:
					continue
				if String(location_id) in ["old_bellwether", "whisperwood", "moonwater_harbour", "old_lighthouse", "midnight_platform"]:
					var outdoor_weather_positions: Array = instance.call("_outdoor_weather_positions", String(location_id))
					_expect(outdoor_weather_positions.size() == 4, "%s uses its own reviewed open-sky weather anchors" % String(location_id))
					for weather_position in outdoor_weather_positions:
						_expect(weather_position is Vector2 and weather_position.x >= 79.0 and weather_position.x <= 1521.0 and weather_position.y >= 55.0 and weather_position.y <= 845.0, "%s weather anchor leaves room for maximum sprite bounds and drift" % String(location_id))
					instance.call("_sync_location_weather_effects", 0)
					var outdoor_rain_sprites: Array = instance.get("location_weather_sprites")
					_expect(outdoor_rain_sprites.size() == outdoor_weather_positions.size(), "%s creates one compact rain sprite per reviewed sky anchor" % String(location_id))
					for rain_index in range(min(outdoor_rain_sprites.size(), outdoor_weather_positions.size())):
						var outdoor_rain_sprite := outdoor_rain_sprites[rain_index] as Sprite2D
						_expect(outdoor_rain_sprite != null and outdoor_rain_sprite.centered and outdoor_rain_sprite.scale.is_equal_approx(Vector2(0.15, 0.15)) and outdoor_rain_sprite.position == outdoor_weather_positions[rain_index], "%s rain cell remains compact and centered on its sky anchor" % String(location_id))
					for snow_sprite in instance.get("location_snow_sprites"):
						var snow_anchor: Vector2 = snow_sprite.get_meta("base_position", Vector2.ZERO)
						_expect(snow_anchor.y >= 55.0 and snow_anchor.y <= 845.0, "%s snowflake base position remains inside its reviewed effect pocket" % String(location_id))
					for wind_sprite in instance.get("location_wind_sprites"):
						var wind_anchor: Vector2 = wind_sprite.get_meta("base_position", Vector2.ZERO)
						_expect(wind_anchor.y >= 55.0 and wind_anchor.y <= 845.0, "%s seasonal sprite base position remains inside its reviewed effect pocket" % String(location_id))
				for layer_name in ["NightSkyLayer", "ExteriorParallaxLayer", "SeparateLightingLayer", "ArchitectureLayer", "ForegroundParallaxLayer"]:
					_expect(location_scene.get_node_or_null(String(layer_name)) is Node2D, "%s runtime supplies independent %s layer" % [String(location_id), String(layer_name)])
				var approved_backdrop := location_scene.get_node_or_null("ArchitectureLayer/Backdrop") as Sprite2D
				_expect(approved_backdrop != null and approved_backdrop.texture != null and approved_backdrop.texture.resource_path.begins_with("res://assets/raster/environment/") and approved_backdrop.visible and approved_backdrop.modulate == Color.WHITE, "%s keeps its reviewed raster environment plate intact and unmodulated on ArchitectureLayer" % String(location_id))
				var story_prop_layouts := {
					"old_bellwether": ["OldPhotographArt", 0.0],
					"hidden_midnight_room": ["PipsPhotograph", 0.0],
					"moonwater_harbour": ["ImpossibleParcel", 434.4],
					"whisperwood": ["MoonflowerKeepsake", 868.8],
					"old_lighthouse": ["KeeperLens", 1303.2],
					"midnight_platform": ["UndatedTicket", 1737.6],
				}
				if story_prop_layouts.has(String(location_id)):
					var story_prop_layout: Array = story_prop_layouts[String(location_id)]
					var matching_story_prop_sprites := location_scene.find_children(String(story_prop_layout[0]), "Sprite2D", true, false)
					var story_prop_sprite := matching_story_prop_sprites[0] as Sprite2D if not matching_story_prop_sprites.is_empty() else null
					var story_prop_region := Rect2(float(story_prop_layout[1]), 0.0, 434.4, 724.0)
					var actual_story_prop_path := story_prop_sprite.texture.resource_path if story_prop_sprite != null and story_prop_sprite.texture != null else "<missing>"
					var actual_story_prop_region := story_prop_sprite.region_rect if story_prop_sprite != null else Rect2()
					_expect(story_prop_sprite != null and story_prop_sprite.texture != null and actual_story_prop_path == "res://assets/raster/props/moonmart_story_props_atlas.png" and story_prop_sprite.region_enabled and actual_story_prop_region == story_prop_region, "%s story prop uses an exact story-atlas cell · path=%s enabled=%s region=%s expected=%s" % [String(location_id), actual_story_prop_path, str(story_prop_sprite.region_enabled if story_prop_sprite != null else false), str(actual_story_prop_region), str(story_prop_region)])
				if String(location_id) in ["reading_nook", "enchanted_greenhouse"]:
					var room_backdrop := location_scene.get_node_or_null("ArchitectureLayer/Backdrop") as Sprite2D
					_expect(room_backdrop != null and room_backdrop.texture != null and room_backdrop.texture.resource_path.begins_with("res://assets/raster/environment/moonmart_") and room_backdrop.visible and room_backdrop.modulate == Color.WHITE, "%s keeps its authored raster architecture plate visible at full color" % String(location_id))
					if String(location_id) == "enchanted_greenhouse":
						var return_door := location_scene.get_node_or_null("ArchitectureLayer/MoonmartReturnDoor") as Sprite2D
						_expect(return_door != null and return_door.texture != null and return_door.texture.resource_path == "res://assets/raster/furniture/door_states_atlas.png" and return_door.region_enabled and return_door.region_rect == Rect2(0.5, 0.5, 886, 886), "Greenhouse return door samples the inset closed-door cell without crossing atlas edges")
					var room_collision := location_scene.get_node_or_null("RoomDecorationCollisionLayer") as Node2D
					var room_player := instance.get("player_body") as CharacterBody2D
					_expect(room_collision != null and room_collision.get_child_count() > 0 and room_player != null and room_player.collision_mask == 1, "%s travel creates room fixture collision and enables player collision" % String(location_id))
					var interaction_points := location_scene.get_node_or_null("InteractionPoints") as Node2D
					var room_targets := ["ReadingChair", "ReadingShelves", "ReadingShelvesRight", "BotanicalStand"] if String(location_id) == "reading_nook" else ["PropagationShelf", "SeedlingShelf", "WateringStation", "MoonflowerTrellis"]
					for target_name in room_targets:
						_expect(interaction_points != null and interaction_points.get_node_or_null(String(target_name)) is Marker2D, "%s exposes its %s interaction marker" % [String(location_id), String(target_name)])
					var prompt_target := "ReadingChair" if String(location_id) == "reading_nook" else "WateringStation"
					var prompt_marker := location_scene.get_node_or_null("InteractionPoints/" + prompt_target) as Marker2D
					if prompt_marker != null:
						instance.set("player_position", prompt_marker.global_position)
						instance.call("_update_prompt")
						var room_prompt := instance.get("prompt_label") as Label
						var expected_prompt_action := "rest" if String(location_id) == "reading_nook" else "water"
						_expect(String(instance.get("nearby_id")) == prompt_target and room_prompt != null and room_prompt.visible and room_prompt.text.to_lower().contains(expected_prompt_action), "%s interaction marker is reachable and shows its %s prompt" % [String(location_id), expected_prompt_action])
					instance.set("player_position", Vector2(120, 785))
					instance.call("_sync_camera_and_parallax")
					await _smoke_room_camera_framing(instance, String(location_id))
				if String(location_id) == "old_bellwether":
					var exterior_layer := location_scene.get_node("ExteriorParallaxLayer") as Node2D
					var location_camera := instance.get("room_camera") as Camera2D
					instance.set("player_position", Vector2(1500, 785))
					instance.call("_sync_camera_and_parallax")
					_expect(location_camera != null and location_camera.position.x > 800.0, "exterior camera follows the player within the painted scene bounds")
					_expect(exterior_layer.position.x > 0.0 and location_camera != null and exterior_layer.position.x < location_camera.position.x - 800.0, "exterior parallax drifts at a slower rate than the foreground")
					instance.set("player_position", Vector2(120, 785))
					instance.call("_sync_camera_and_parallax")
				if String(location_id) == "midnight_platform":
					var platform_backdrop := location_scene.get_node_or_null("ArchitectureLayer/Backdrop") as Sprite2D
					var foreground_layer := location_scene.get_node_or_null("ForegroundParallaxLayer") as Node2D
					var signpost := location_scene.get_node_or_null("ForegroundParallaxLayer/ParallaxSignpost") as Sprite2D
					var location_camera := instance.get("room_camera") as Camera2D
					_expect(platform_backdrop != null and platform_backdrop.texture != null and platform_backdrop.texture.resource_path == "res://assets/raster/environment/midnight_platform.png" and platform_backdrop.visible and platform_backdrop.modulate == Color.WHITE, "Midnight Platform keeps its approved painted plate visible and unchanged in the architecture layer")
					_expect(foreground_layer != null and foreground_layer.z_index == 8 and signpost != null, "Midnight Platform has a dedicated foreground parallax layer between plate and characters")
					_expect(signpost != null and signpost.texture != null and signpost.texture.resource_path == "res://assets/raster/furniture/moonmart_midnight_platform_atlas_1280.png" and signpost.region_enabled and signpost.region_rect == Rect2(320.5, 640.5, 319, 319), "foreground parallax uses the approved platform_direction_signpost atlas cell directly")
					var backdrop_original_position := platform_backdrop.position if platform_backdrop != null else Vector2.ZERO
					# Use a 4:3 SubViewport so the camera can pan across the 16:9 platform plate.
					var platform_original_parent := instance.get_parent()
					var platform_viewport := SubViewport.new()
					platform_viewport.name = "PlatformParallaxTestViewport"
					platform_viewport.size = Vector2i(1280, 960)
					platform_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
					get_tree().root.add_child(platform_viewport)
					platform_original_parent.remove_child(instance)
					platform_viewport.add_child(instance)
					await get_tree().process_frame
					instance.set("player_position", Vector2(120, 785))
					instance.call("_sync_camera_and_parallax")
					var camera_x_before := location_camera.position.x if location_camera != null else 0.0
					var foreground_x_before := foreground_layer.position.x if foreground_layer != null else 0.0
					var signpost_screen_x_before := signpost.global_position.x - camera_x_before if signpost != null else 0.0
					instance.set("player_position", Vector2(1500, 785))
					instance.call("_sync_camera_and_parallax")
					var camera_delta := location_camera.position.x - camera_x_before if location_camera != null else 0.0
					var foreground_delta := foreground_layer.position.x - foreground_x_before if foreground_layer != null else 0.0
					var signpost_screen_x_after := signpost.global_position.x - (location_camera.position.x if location_camera != null else 0.0) if signpost != null else 0.0
					_expect(absf(camera_delta) > 20.0 and absf(foreground_delta) > 5.0 and is_equal_approx(foreground_delta / camera_delta, -0.18), "platform signpost layer follows its distinct foreground camera ratio (camera %.2f, layer %.2f)" % [camera_delta, foreground_delta])
					_expect(absf(signpost_screen_x_after - signpost_screen_x_before) > 10.0 and signf(signpost_screen_x_after - signpost_screen_x_before) == -signf(camera_delta) and is_equal_approx((signpost_screen_x_after - signpost_screen_x_before) / camera_delta, -1.18), "visible platform signpost moves faster than the plate in camera space (screen %.2f)" % (signpost_screen_x_after - signpost_screen_x_before))
					_expect(platform_backdrop != null and platform_backdrop.position == backdrop_original_position, "foreground parallax leaves the painted platform plate's transform untouched")
					var prior_visual_effects := bool(instance.get("visual_effects_enabled"))
					instance.call("_apply_visual_comfort_settings", false, bool(instance.get("reduced_animation_enabled")), bool(instance.get("reduced_flashing_enabled")))
					_expect(foreground_layer != null and foreground_layer.visible and signpost != null and signpost.is_visible_in_tree(), "foreground parallax remains visible when optional visual effects are disabled")
					instance.call("_apply_visual_comfort_settings", prior_visual_effects, bool(instance.get("reduced_animation_enabled")), bool(instance.get("reduced_flashing_enabled")))
					platform_viewport.remove_child(instance)
					platform_original_parent.add_child(instance)
					platform_viewport.queue_free()
					await get_tree().process_frame
					instance.set("player_position", Vector2(120, 785))
					instance.call("_sync_camera_and_parallax")
					var waiting_bench := location_scene.get_node_or_null("InteractionPoints/WaitingBench") as Marker2D
					_expect(waiting_bench != null, "Midnight Platform has a reachable painted waiting-bench target")
					if waiting_bench != null:
						instance.set("player_position", waiting_bench.global_position + Vector2(0, 20))
						instance.call("_update_prompt")
						_expect(String(instance.get("nearby_id")) == "WaitingBench", "player can approach and target the platform waiting bench")
						var bench_prompt := instance.get("prompt_label") as Label
						_expect(bench_prompt != null and bench_prompt.text.contains("Rest a moment") and bench_prompt.text.contains("Inspect"), "waiting-bench prompt explains both rest and inspect actions")
						instance.set("player_position", waiting_bench.global_position)
						var platform_clock_before: float = game.clock.elapsed_minutes
						instance.call("_interact_location", false)
						_expect(String(game.last_message).contains("The bench has room for two"), "waiting-bench interaction gives its rest dialogue")
						await get_tree().process_frame
						_expect(game.discovered_collectibles.has("platform_unclaimed_ticket") and String(game.last_message).contains("You found"), "using the waiting bench awards its keepsake and announces it after the rest dialogue")
						_expect(is_equal_approx(game.clock.elapsed_minutes, platform_clock_before), "resting on the platform bench does not advance shift time")
						instance.call("_dismiss_message")
					var ticket_window := location_scene.get_node_or_null("InteractionPoints/TicketWindow") as Marker2D
					_expect(ticket_window != null, "Midnight Platform exposes the painted ticket window as a target")
					if ticket_window != null:
						instance.set("player_position", ticket_window.global_position + Vector2(0, 20))
						instance.call("_update_prompt")
						_expect(String(instance.get("nearby_id")) == "TicketWindow", "player can approach and target the platform ticket window")
						var ticket_prompt := instance.get("prompt_label") as Label
						_expect(ticket_prompt != null and ticket_prompt.text.contains("Read the ticket window") and ticket_prompt.text.contains("Inspect"), "ticket-window prompt explains its localized interaction")
						var ticket_target_id := String(instance.call("_location_target_id", "TicketWindow"))
						_expect(ticket_target_id == "ticket_window", "platform ticket-window marker maps to the authored clue target")
						var story: Object = game.get("story")
						var original_chapter := int(story.get("chapter"))
						var original_clues: Array = story.get("clues").duplicate()
						var earlier_ticket_clue := "midnight_ticket_bears_wren_family_mark"
						story.set("chapter", 4)
						var story_clues: Array = story.get("clues")
						if not story_clues.has(earlier_ticket_clue):
							story_clues.append(earlier_ticket_clue)
						story.set("clues", story_clues)
						story.call("inspect", ticket_target_id, int(game.get("shift_number")))
						_expect(story.get("clues").has("ticket_names_midnight_platform"), "ticket window reveals the chapter-four Midnight Platform clue")
						story.set("chapter", original_chapter)
						story.set("clues", original_clues)
				for effect_name in ["WindowEffectsLayer", "WeatherEffectsLayer", "StoryEffectsLayer", "ForegroundEffectsLayer", "PropEffectsLayer"]:
					var effect_layer := location_scene.get_node_or_null(String(effect_name)) as CanvasItem
					_expect(effect_layer != null and not effect_layer.visible, "%s global setting hides location %s" % [String(location_id), String(effect_name)])
				var location_lighting := location_scene.get_node_or_null("SeparateLightingLayer") as CanvasItem
				var location_architecture := location_scene.get_node_or_null("ArchitectureLayer") as CanvasItem
				_expect(location_lighting != null and not location_lighting.visible, "%s dynamic-lighting setting hides location lighting" % String(location_id))
				_expect(location_architecture != null and location_architecture.visible, "%s architecture plate stays visible with effects disabled" % String(location_id))
				instance.call("set_environment_layer_enabled", "location_weather", true)
				_expect(not (location_scene.get_node("WeatherEffectsLayer") as CanvasItem).visible, "%s per-layer request cannot bypass global visual-effects setting" % String(location_id))
				instance.call("_apply_visual_comfort_settings", true, false, false)
				_expect((location_scene.get_node("WeatherEffectsLayer") as CanvasItem).visible, "%s weather layer returns when visual effects are enabled" % String(location_id))
				instance.call("_apply_visual_comfort_settings", false, false, false)
			instance.call("_travel_to_location", "moonmart", false)
			await get_tree().process_frame
		var original_parent := instance.get_parent()
		var responsive_viewport := SubViewport.new()
		responsive_viewport.size = Vector2i(1600, 900)
		responsive_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_tree().root.add_child(responsive_viewport)
		original_parent.remove_child(instance)
		responsive_viewport.add_child(instance)
		var long_dialogue_copy := "A quiet place is still a choice. The station keeps its light on for everyone who needs a pause, with no timetable attached. ".repeat(3)
		instance.call("_on_message_changed", long_dialogue_copy)
		for aspect_size in [Vector2i(1280, 960), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
			responsive_viewport.size = aspect_size
			await get_tree().process_frame
			await get_tree().process_frame
			instance.call("_apply_settings_ui_scale", 1.0)
			instance.call("_sync_camera_and_parallax")
			var aspect_viewport_size := responsive_viewport.get_visible_rect().size
			_expect(Vector2i(aspect_viewport_size) == aspect_size, "test viewport really changes to %s" % str(aspect_size))
			var aspect_scale: float = (hud as CanvasLayer).scale.x
			for control_name in ["HudShopPanel", "HudMoneyPanel", "HudControlsHint", "HudMessagePanel", "HudMessageLabel", "HudMessageHint"]:
				var aspect_control := hud.get_node_or_null(String(control_name)) as Control
				var aspect_rect := Rect2(aspect_control.position * aspect_scale, aspect_control.size * aspect_scale) if aspect_control != null else Rect2()
				_expect(aspect_control != null and aspect_rect.position.x >= -0.5 and aspect_rect.position.y >= -0.5 and aspect_rect.end.x <= aspect_viewport_size.x + 0.5 and aspect_rect.end.y <= aspect_viewport_size.y + 0.5, "%s stays inside the %s aspect-ratio viewport" % [String(control_name), str(aspect_size)])
			var aspect_message := hud.get_node_or_null("HudMessageLabel") as Label
			var aspect_message_panel := hud.get_node_or_null("HudMessagePanel") as Control
			var aspect_message_bounds := Rect2(aspect_message.position * aspect_scale, aspect_message.size * aspect_scale) if aspect_message != null else Rect2()
			var aspect_panel_bounds := Rect2(aspect_message_panel.position * aspect_scale, aspect_message_panel.size * aspect_scale) if aspect_message_panel != null else Rect2()
			_expect(aspect_message != null and aspect_message.visible and aspect_message.get_line_count() > 1 and aspect_message.get_line_count() <= 5 and aspect_message_bounds.position.x >= aspect_panel_bounds.position.x and aspect_message_bounds.end.x <= aspect_panel_bounds.end.x and aspect_message_bounds.position.y >= aspect_panel_bounds.position.y and aspect_message_bounds.end.y <= aspect_panel_bounds.end.y, "long dialogue copy wraps visibly inside its frame at %s aspect ratio" % str(aspect_size))
			var aspect_camera := instance.get("room_camera") as Camera2D
			_expect(aspect_camera != null and aspect_camera.position.x >= 0.0 and aspect_camera.position.x <= 1600.0, "shop camera frames the room at %s aspect ratio" % str(aspect_size))
			if aspect_camera != null:
				var visible_world_size := aspect_viewport_size / aspect_camera.zoom.x
				var visible_rect := Rect2(aspect_camera.position - visible_world_size * 0.5, visible_world_size)
				_expect(visible_rect.position.x >= -0.5 and visible_rect.position.y >= -0.5 and visible_rect.end.x <= 1600.5 and visible_rect.end.y <= 900.5, "camera covers only the painted room image at %s aspect ratio" % str(aspect_size))
				_expect(visible_rect.has_point(instance.get("player_position")), "shop camera keeps the player visible at %s aspect ratio" % str(aspect_size))
			if aspect_size.x < 1600:
				var shop_parallax := instance.get("exterior_parallax_layer") as Node2D
				instance.set("player_position", Vector2(1500, 750))
				instance.call("_sync_camera_and_parallax")
				_expect(aspect_camera.position.x > aspect_size.x * 0.5 and shop_parallax != null and shop_parallax.get_child_count() > 0 and shop_parallax.position.x > 0.0, "narrower shop view scrolls foreground and slowly drifts the separate painted skyline")
				instance.set("player_position", Vector2(790, 750))
				instance.call("_sync_camera_and_parallax")
			var aspect_settings: CanvasLayer = instance.get("settings_panel")
			aspect_settings.call("open")
			await get_tree().process_frame
			var aspect_dialog := aspect_settings.get_node_or_null("SettingsOverlay/SettingsJournalPanel") as Control
			var aspect_dialog_rect := Rect2(aspect_dialog.position, aspect_dialog.size) if aspect_dialog != null else Rect2()
			_expect(aspect_dialog != null and aspect_dialog_rect.position.x >= -0.5 and aspect_dialog_rect.position.y >= -0.5 and aspect_dialog_rect.end.x <= aspect_viewport_size.x + 0.5 and aspect_dialog_rect.end.y <= aspect_viewport_size.y + 0.5, "settings dialog stays inside the %s aspect-ratio viewport" % str(aspect_size))
			aspect_settings.call("close")
		instance.call("_dismiss_message")
		responsive_viewport.remove_child(instance)
		original_parent.add_child(instance)
		get_tree().root.remove_child(responsive_viewport)
		responsive_viewport.free()
		await get_tree().process_frame
		instance.call("_apply_settings_ui_scale", 1.0)
		instance.call("_sync_camera_and_parallax")
		instance.call("_stop_audio_players")
		await get_tree().create_timer(0.2).timeout
		var remaining_audio: Array[Node] = instance.find_children("*", "AudioStreamPlayer", true, false)
		_expect(remaining_audio.all(func(node: Node) -> bool: return not (node as AudioStreamPlayer).playing and (node as AudioStreamPlayer).stream == null), "main scene shutdown stops and releases audio playback resources")
		instance.queue_free()
		for _frame in range(3):
			await get_tree().process_frame
		await get_tree().create_timer(0.2).timeout
		_expect(not is_instance_valid(instance), "main scene releases its runtime nodes after smoke checks")
	_write_report()
	if _failures.is_empty():
		print("Main-scene headless startup passed.")
	else:
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)

func _smoke_room_camera_framing(instance: Node, location_id: String) -> void:
	var original_parent := instance.get_parent()
	var room_viewport := SubViewport.new()
	room_viewport.name = "%sCameraSmokeViewport" % location_id.capitalize()
	room_viewport.size = Vector2i(1600, 900)
	room_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(room_viewport)
	original_parent.remove_child(instance)
	room_viewport.add_child(instance)
	for viewport_size in [Vector2i(1280, 960), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		room_viewport.size = viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
		instance.call("_sync_camera_and_parallax")
		var actual_viewport_size := room_viewport.get_visible_rect().size
		var camera := instance.get("room_camera") as Camera2D
		var backdrop := instance.get("current_location_scene").get_node_or_null("ArchitectureLayer/Backdrop") as Sprite2D if instance.get("current_location_scene") != null else null
		var plate_size := backdrop.texture.get_size() * backdrop.global_scale if backdrop != null and backdrop.texture != null else Vector2.ZERO
		var zoom := camera.zoom.x if camera != null else 0.0
		var visible_world_size := actual_viewport_size / zoom if zoom > 0.0 else Vector2.ZERO
		var visible_rect := Rect2(camera.position - visible_world_size * 0.5, visible_world_size) if camera != null else Rect2()
		_expect(Vector2i(actual_viewport_size) == viewport_size, "%s room viewport changes to %s for camera framing" % [location_id, str(viewport_size)])
		_expect(camera != null and zoom > 0.0 and visible_rect.position.x >= -0.5 and visible_rect.position.y >= -0.5 and visible_rect.end.x <= plate_size.x + 0.5 and visible_rect.end.y <= plate_size.y + 0.5, "%s room camera frames only its painted plate at %s" % [location_id, str(viewport_size)])
		_expect(camera != null and visible_rect.has_point(instance.get("player_position")), "%s room camera keeps the player visible at %s" % [location_id, str(viewport_size)])
	room_viewport.remove_child(instance)
	original_parent.add_child(instance)
	get_tree().root.remove_child(room_viewport)
	room_viewport.free()
	await get_tree().process_frame
	instance.call("_sync_camera_and_parallax")

func _test_checkout_packing(instance: Node, game: Object) -> void:
	var original_recovery_guard := bool(game.get("save_recovery_required"))
	var original_assisted := bool(instance.get("assisted_checkout_enabled"))
	var original_panel := String(instance.get("active_panel"))
	var original_message_open := bool(instance.get("message_open"))
	var original_active_customers: Array = game.customers.active.duplicate(true)
	var original_manual_definition: Variant = game.customers.definitions.get("packing_manual_test", null)
	var original_assisted_definition: Variant = game.customers.definitions.get("packing_assisted_test", null)
	var original_transactions: int = int(game.inventory.transactions.size())
	var original_coins := int(game.inventory.coins)
	var original_tokens := int(game.inventory.moon_tokens)
	game.set("save_recovery_required", true)
	instance.set("message_open", false)
	instance.set("active_panel", "")
	instance.set("assisted_checkout_enabled", false)
	game.customers.active.clear()
	var manual_customer := {
		"id":"packing_manual_test", "name":"Mina", "essential":false,
		"state":"QUEUING", "basket":{"bread":1}, "payment_currency":"moon_tokens",
		"packing_preference":"careful", "visit_count":0,
		"favourite_products":["tea"]
	}
	game.customers.definitions["packing_manual_test"] = {"id":"packing_manual_test","basket":{"bread":1},"favourite_products":["tea"],"tags":[]}
	game.customers.active.append(manual_customer)
	instance.call("_open_checkout_panel")
	_expect(String(instance.get("checkout_phase")) == "scan", "checkout begins in the familiar scanning phase")
	_expect(int(game.inventory.available_on_shelf("tea")) > 0, "manual recommendation fixture has tea on the shelf")
	var interact_event := InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	instance.call("_unhandled_input", interact_event)
	_expect(bool(instance.call("_checkout_is_complete")) and String(instance.get("checkout_phase")) == "scan", "scanning the full basket advances to packing without committing the sale")
	var transaction_count_before_packing: int = int(game.inventory.transactions.size())
	instance.call("_unhandled_input", interact_event)
	var checkout_label := instance.get("side_label") as Label
	var recommendation_name: String = String(instance.call("_localized_product_name", "tea", "Tea"))
	var skip_copy: String = String(instance.call("_localize_ui", "checkout.recommendation.option.skip", "Skip"))
	_expect(String(instance.get("checkout_phase")) == "recommendation" and String(instance.get("checkout_recommendation_item_id")) == "tea" and String(checkout_label.text).to_lower().contains(recommendation_name.to_lower()), "manual completed scan presents the stocked favorite suggestion")
	_expect(int(instance.get("checkout_recommendation_choice_index")) == 1 and String(checkout_label.text).contains("› 2   " + skip_copy), "recommendation defaults to Skip")
	_expect(game.inventory.transactions.size() == transaction_count_before_packing, "showing a recommendation does not commit the sale")
	instance.call("_unhandled_input", interact_event)
	var preference_copy: String = String(instance.call("_localize_ui", "checkout.packing.preference.careful", "They'd like their order wrapped with care."))
	_expect(String(instance.get("checkout_phase")) == "packing" and String(checkout_label.text).contains(String(preference_copy)), "skipping the recommendation advances to packing and states the customer's preference")
	_expect(game.inventory.transactions.size() == transaction_count_before_packing, "entering packing after Skip does not commit a sale")
	var move_right_event := InputEventAction.new()
	move_right_event.action = "move_right"
	move_right_event.pressed = true
	instance.call("_unhandled_input", move_right_event)
	_expect(int(instance.get("checkout_packing_choice_index")) == 2 and String(checkout_label.text).contains("› 3"), "left and right navigate packing options without completing the sale")
	var move_left_event := InputEventAction.new()
	move_left_event.action = "move_left"
	move_left_event.pressed = true
	instance.call("_unhandled_input", move_left_event)
	_expect(int(instance.get("checkout_packing_choice_index")) == 1, "packing selection returns to the customer's requested choice")
	var wrong_pack_event := InputEventAction.new()
	wrong_pack_event.action = "ui_select_1"
	wrong_pack_event.pressed = true
	instance.call("_unhandled_input", wrong_pack_event)
	_expect(game.inventory.transactions.size() == transaction_count_before_packing + 1, "a non-preferred pack choice still completes the transaction")
	_expect(int(game.inventory.coins) == original_coins and int(game.inventory.moon_tokens) > original_tokens, "manual packed checkout preserves Moon Token settlement")
	game.customers.active.clear()
	instance.set("assisted_checkout_enabled", true)
	var assisted_customer := {
		"id":"packing_assisted_test", "name":"Ivo", "essential":false,
		"state":"QUEUING", "basket":{"bread":1}, "payment_currency":"coins",
		"packing_preference":"reusable", "visit_count":0,
		"favourite_products":["tea"]
	}
	game.customers.definitions["packing_assisted_test"] = {"id":"packing_assisted_test","basket":{"bread":1},"favourite_products":["tea"],"tags":[]}
	game.customers.active.append(assisted_customer)
	instance.call("_open_checkout_panel")
	instance.call("_unhandled_input", interact_event)
	transaction_count_before_packing = game.inventory.transactions.size()
	checkout_label = instance.get("side_label") as Label
	_expect(String(instance.get("checkout_phase")) == "recommendation" and String(instance.get("checkout_recommendation_item_id")) == "tea", "assisted Coins checkout offers the stocked favorite after scanning the original basket")
	_expect(int(instance.get("checkout_recommendation_choice_index")) == 1, "assisted recommendation also defaults to Skip")
	var move_left_recommendation_event := InputEventAction.new()
	move_left_recommendation_event.action = "move_left"
	move_left_recommendation_event.pressed = true
	instance.call("_unhandled_input", move_left_recommendation_event)
	_expect(int(instance.get("checkout_recommendation_choice_index")) == 0 and String(checkout_label.text).contains("› 1"), "left navigation selects Offer")
	var recommendation_offer_event := InputEventAction.new()
	recommendation_offer_event.action = "ui_select_1"
	recommendation_offer_event.pressed = true
	instance.call("_unhandled_input", recommendation_offer_event)
	var recommendation_target: Dictionary = {"bread":1,"tea":1}
	_expect(String(instance.get("checkout_phase")) == "packing" and bool(instance.call("_checkout_is_complete")) and instance.get("checkout_scanned") == recommendation_target, "Offer adds and assisted scanning completes the extra tea line before packing")
	_expect(instance.get("checkout_recommended_items") == {"tea":1} and game.inventory.transactions.size() == transaction_count_before_packing, "accepted offer is staged for sale but not committed before packing and payment")
	var reusable_copy: String = String(instance.call("_localize_ui", "checkout.packing.preference.reusable", "They brought a reusable cloth wrap."))
	_expect(String(instance.get("checkout_phase")) == "packing" and String(checkout_label.text).contains(String(reusable_copy)), "assisted recommendation still stops at the preference-aware packing phase")
	_expect(game.inventory.transactions.size() == transaction_count_before_packing, "assisted scanning cannot bypass order packing")
	var confirmed_pack_event := InputEventAction.new()
	confirmed_pack_event.action = "ui_select_2"
	confirmed_pack_event.pressed = true
	instance.call("_unhandled_input", confirmed_pack_event)
	_expect(game.inventory.transactions.size() == transaction_count_before_packing and String(instance.get("checkout_phase")) == "payment", "packing confirmation opens the Coins tender choice without committing early")
	var payment_label: String = String(instance.call("_localize_ui", "checkout.payment.option.card", "Card"))
	_expect(String(checkout_label.text).contains(String(payment_label)), "Coins tender panel offers the localized card payment option")
	var confirmed_tender_event := InputEventAction.new()
	confirmed_tender_event.action = "ui_select_2"
	confirmed_tender_event.pressed = true
	instance.call("_unhandled_input", confirmed_tender_event)
	_expect(game.inventory.transactions.size() == transaction_count_before_packing + 1 and int(game.inventory.coins) > original_coins, "number-key card tender completes a normal Coins sale")
	_expect(String(game.inventory.latest_refundable_sale().get("payment_tender", "")) == "card", "Coins sale records the selected card tender")
	_expect(game.inventory.latest_refundable_sale().get("basket", {}) == recommendation_target, "accepted recommended product is present in the completed Coins sale ledger")
	game.customers.active.clear()
	game.customers.active.append_array(original_active_customers)
	if original_manual_definition == null:
		game.customers.definitions.erase("packing_manual_test")
	else:
		game.customers.definitions["packing_manual_test"] = original_manual_definition
	if original_assisted_definition == null:
		game.customers.definitions.erase("packing_assisted_test")
	else:
		game.customers.definitions["packing_assisted_test"] = original_assisted_definition
	if String(instance.get("active_panel")) == "checkout":
		instance.call("_close_side_panel")
	instance.set("assisted_checkout_enabled", original_assisted)
	instance.set("active_panel", original_panel)
	instance.set("message_open", original_message_open)
	game.set("save_recovery_required", original_recovery_guard)
	game.set_paused(false)
	_expect(game.inventory.transactions.size() == original_transactions + 2, "packing smoke creates exactly the two intentional customer sales")

func _test_player_position_save_resume(instance: Node, game: Object) -> void:
	var saved_position := Vector2(1080, 742)
	var body := instance.get("player_body") as CharacterBody2D
	var original_position: Vector2 = instance.get("player_position")
	var original_body_position := body.position
	game.remember_player_position("moonmart", saved_position)
	game.save_now()
	var save_script := load("res://scripts/core/save_manager.gd")
	var payload: Dictionary = save_script.read_save()
	_expect(payload.get("player_positions", {}).get("moonmart", {}).get("x", -1.0) == saved_position.x, "mid-shift save writes the player's current room position")
	body.position = Vector2(790, 748)
	instance.set("player_position", body.position)
	game.load_state(payload)
	instance.call("_restore_player_position", "moonmart", Vector2(790, 748))
	_expect(body.position.distance_to(saved_position) < 0.1, "loading a mid-shift save restores the player to the saved position")
	game.player_positions["moonmart"] = {"x":9999.0, "y":-9999.0}
	instance.call("_restore_player_position", "moonmart", Vector2(790, 748))
	_expect(body.position == Vector2(1550, 646), "restored player positions clamp to the active room's safe bounds")
	instance.set("player_position", original_position)
	body.position = original_body_position
	game.remember_player_position("moonmart", original_position)

func _test_save_failure_handling(instance: Node, game: Object) -> void:
	var original_recovery_guard := bool(game.get("save_recovery_required"))
	var original_recovery_message := String(game.get("save_recovery_message"))
	var original_panel := String(instance.get("active_panel"))
	var original_message_open := bool(instance.get("message_open"))
	var original_paused := bool(game.clock.get("paused"))
	var side_panel := instance.get("side_panel") as Control
	var side_label := instance.get("side_label") as Control
	var speed_label := instance.get("speed_label") as Control
	var speed_slider := instance.get("speed_slider") as Control
	var original_side_panel_visible := side_panel.visible
	var original_side_label_visible := side_label.visible
	var original_speed_label_visible := speed_label.visible
	var original_speed_slider_visible := speed_slider.visible
	var original_pause_buttons_visible: Array[bool] = []
	for pause_button in instance.get("pause_buttons") as Array:
		original_pause_buttons_visible.append((pause_button as Control).visible)
	var message_label := instance.get("message_label") as Label
	var message_panel := instance.get("message_panel") as Control
	var message_hint := instance.get("message_hint_label") as Control
	var original_message_text := message_label.text
	var original_message_visible := message_label.visible
	var original_panel_visible := message_panel.visible
	var original_hint_visible := message_hint.visible
	game.set("save_recovery_required", true)
	game.set("save_recovery_message", "test recovery reason")
	instance.set("active_panel", "pause")
	var resume_result: Variant = instance.call("_save_resume_from_pause")
	_expect(resume_result == false and String(instance.get("active_panel")) == "pause", "Save and continue keeps the pause menu open if the commit is rejected")
	var expected_recovery_text := String(instance.call("_format_localized_ui", "save.recovery.message", "The existing save could not be read and remains preserved. {reason} Use the recovery button to archive it intact and begin a fresh game.", {"reason":"test recovery reason"}))
	_expect(message_panel.visible and message_label.text == expected_recovery_text, "a blocked save reopens the localized recovery guidance")
	var quit_result: Variant = instance.call("_save_quit_from_pause")
	_expect(quit_result == false and instance.is_inside_tree(), "Save and quit keeps the game open if the commit is rejected")
	game.set("save_recovery_required", false)
	game.set("save_recovery_message", "")
	game.emit_signal("save_failed")
	var expected_failure_text := String(instance.call("_localize_ui", "save.commit_failed", "Moonmart could not save your progress. Your session is still open; check available storage or folder permissions, then try again."))
	_expect(message_panel.visible and message_label.visible and message_label.text == expected_failure_text, "automatic save failures open a localized message with retry guidance")
	game.set("save_recovery_required", original_recovery_guard)
	game.set("save_recovery_message", original_recovery_message)
	instance.set("active_panel", original_panel)
	instance.set("message_open", original_message_open)
	side_panel.visible = original_side_panel_visible
	side_label.visible = original_side_label_visible
	speed_label.visible = original_speed_label_visible
	speed_slider.visible = original_speed_slider_visible
	var pause_buttons: Array = instance.get("pause_buttons")
	for index in range(mini(pause_buttons.size(), original_pause_buttons_visible.size())):
		(pause_buttons[index] as Control).visible = original_pause_buttons_visible[index]
	message_label.text = original_message_text
	message_label.visible = original_message_visible
	message_panel.visible = original_panel_visible
	message_hint.visible = original_hint_visible
	game.set_paused(original_paused)

func _write_report() -> void:
	var report := FileAccess.open("user://main_scene_test_report.txt", FileAccess.WRITE)
	if report != null:
		report.store_string("failures=%d\n%s" % [_failures.size(), "\n".join(_failures)])
		report.close()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
