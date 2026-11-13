extends Node2D

const GAME_SCRIPT = preload("res://scripts/core/moonmart_game.gd")
const SETTINGS_SCRIPT = preload("res://scripts/systems/settings_manager.gd")
const SETTINGS_PANEL_SCRIPT = preload("res://scripts/ui/settings_panel.gd")
const SFX_MANAGER_SCRIPT = preload("res://scripts/systems/sfx_manager.gd")
const MISO_AMBIENT_SCRIPT = preload("res://scripts/systems/miso_ambient_manager.gd")
const SHELL_PATH := "res://assets/raster/environment/moonmart_room_architecture.png"
const WINDOW_SKY_PATH := "res://assets/raster/environment/moonmart_window_sky.png"
const WINDOW_PARALLAX_PATH := "res://assets/raster/environment/bellwether_parallax.png"
const DOOR_ATLAS_PATH := "res://assets/raster/furniture/door_states_atlas.png"
const SHOP_SIGN_PATH := "res://assets/raster/furniture/moonmart_sign.png"
const ARCHITECTURE_MODULES_DATA_PATH := "res://data/architecture_modules.json"
const FURNITURE_PATH := "res://assets/raster/furniture/moonmart_furniture_atlas.png"
const PLAYER_PATH := "res://assets/raster/characters/player_atlas.png"
const PIP_PATH := "res://assets/raster/characters/pip_atlas.png"
const MISO_PATH := "res://assets/raster/characters/miso_atlas.png"
const AGNES_PATH := "res://assets/raster/characters/agnes_atlas.png"
const PREP_STATIONS_PATH := "res://assets/raster/furniture/moonmart_prep_station_atlas_1280.png"
const MOONFLOWER_PLANT_PATH := "res://assets/raster/furniture/potted_moonflower.png"
const PRODUCT_ICON_PATH := "res://assets/raster/products/moonmart_products_atlas.png"
const PRODUCT_ICON_EXTENSION_PATH := "res://assets/raster/products/moonmart_products_extension.png"
const PRODUCT_ICON_EXTENSION_2_PATH := "res://assets/raster/products/moonmart_products_extension_2.png"
const PRODUCT_ICON_EXTENSION_3_PATH := "res://assets/raster/products/moonmart_products_extension_3.png"
const PRODUCT_ICON_EXTENSION_4_PATH := "res://assets/raster/products/moonmart_product_icons_extension_4_1280.png"
const PRODUCT_ICON_EXTENSION_5_PATH := "res://assets/raster/products/moonmart_product_icons_extension_5_1280.png"
const JOURNAL_PANEL_PATH := "res://assets/raster/ui/journal_panel.png"
const PROMPT_BUBBLE_PATH := "res://assets/raster/ui/prompt_bubble.png"
const UI_ICON_PATH := "res://assets/raster/ui/ui_icons_atlas.png"
const UI_ICON_EXTENSION_PATH := "res://assets/raster/ui/ui_icons_extension.png"
const MOONMART_FONT := preload("res://assets/fonts/Nunito[wght].ttf")
const OPEN_DYSLEXIC_FONT := preload("res://assets/fonts/OpenDyslexic-Regular.otf")
const RAIN_ATLAS_PATH := "res://assets/raster/effects/rain_streaks_atlas.png"
const MEMORY_ECHO_ATLAS_PATH := "res://assets/raster/effects/memory_echo_atlas.png"
const SEASONAL_ATLAS_PATH := "res://assets/raster/effects/seasonal_atmosphere_atlas.png"
const KETTLE_STEAM_PATH := "res://assets/raster/effects/kettle_steam_atlas.png"
const NAMED_CHARACTER_SHEETS := {
	"agnes": AGNES_PATH,
	"fern": "res://assets/raster/characters/fern_atlas.png",
	"lucien": "res://assets/raster/characters/lucien_atlas.png",
	"wren": "res://assets/raster/characters/wren_atlas.png",
	"conductor": "res://assets/raster/characters/conductor_atlas.png",
	"elias": "res://assets/raster/characters/elias_atlas.png",
	"mara": "res://assets/raster/characters/mara_atlas.png",
	"osric": "res://assets/raster/characters/osric_atlas.png",
	"hollis_quince": "res://assets/raster/characters/hollis_quince_atlas.png",
	"anouk_harrow": "res://assets/raster/characters/anouk_harrow_atlas.png",
	"oda_lovell": "res://assets/raster/characters/oda_lovell_atlas.png",
	"miriam_underwood": "res://assets/raster/characters/miriam_underwood_atlas.png",
	"iona_pebble": "res://assets/raster/characters/iona_pebble_atlas.png",
	"tomas_wicks": "res://assets/raster/characters/tomas_wicks_atlas.png",
	"liora_fenwick": "res://assets/raster/characters/liora_fenwick_atlas.png",
	"nella_finch": "res://assets/raster/characters/nella_finch_atlas.png",
	"maribel_frost": "res://assets/raster/characters/maribel_frost_atlas.png",
	"aster_rowe": "res://assets/raster/characters/aster_rowe_atlas.png",
	"rowan_pike": "res://assets/raster/characters/rowan_pike_atlas.png",
	"stellan_rusk": "res://assets/raster/characters/stellan_rusk_atlas.png",
	"elowen_charter": "res://assets/raster/characters/elowen_charter_atlas.png",
	"sabine_kersey": "res://assets/raster/characters/sabine_kersey_atlas.png",
	"juniper_hale": "res://assets/raster/characters/juniper_hale_atlas.png",
	"beckett_shore": "res://assets/raster/characters/beckett_shore_atlas.png"
}
const NAMED_CHARACTER_SCALE_OVERRIDES := {
	"anouk_harrow": Vector2(0.28, 0.28),
	"oda_lovell": Vector2(0.28, 0.28),
	"miriam_underwood": Vector2(0.28, 0.28),
	"iona_pebble": Vector2(0.28, 0.28),
	"tomas_wicks": Vector2(0.28, 0.28),
	"liora_fenwick": Vector2(0.28, 0.28),
	"nella_finch": Vector2(0.28, 0.28),
	"maribel_frost": Vector2(0.28, 0.28),
	"aster_rowe": Vector2(0.28, 0.28),
	"rowan_pike": Vector2(0.28, 0.28),
	"stellan_rusk": Vector2(0.28, 0.28),
	"elowen_charter": Vector2(0.28, 0.28),
	"sabine_kersey": Vector2(0.28, 0.28),
	"juniper_hale": Vector2(0.28, 0.28),
	"beckett_shore": Vector2(0.28, 0.28)
}
const GENERIC_CUSTOMER_PATH := "res://assets/raster/characters/generic_customer_atlas.png"
const GENERIC_CUSTOMER_QUEUE_POSE_PATH := "res://assets/raster/characters/generic_customer_queue_pose.png"
const GENERIC_CUSTOMER_PURCHASE_PATH := "res://assets/raster/characters/generic_customer_purchase_atlas.png"
const AGNES_TALK_POSE_PATH := "res://assets/raster/characters/agnes_talk_pose.png"
const LUCIEN_DRINK_POSE_PATH := "res://assets/raster/characters/lucien_drink_pose.png"
const WREN_CAST_POSE_PATH := "res://assets/raster/characters/wren_cast_magic_pose.png"
const PLAYER_TALK_POSE_PATH := "res://assets/raster/characters/player_talk_pose.png"
const PRODUCT_ICON_INDEX := {
	"strawberry_milk":0, "milk":1, "soft_drink":2, "orange_juice":3,
	"bread":4, "pastry":5, "biscuits":6, "noodles":7, "coffee":8, "tea":9,
	"moonflower_tea":10, "dream_biscuits":11, "spirit_candle":12, "starlight":13,
	"sweets":14, "soap":15, "seeds":16, "notebook":17, "sandwich":18, "water":19,
	"peach_jam":20, "blackberry_jam":21, "lavender_tea_tin":22, "croissant":23,
	"star_shortbread":24, "honey_cake":25, "berry_tart":26, "pink_lemonade":27,
	"lavender_bundle":28, "moonflower_seeds":29, "moon_candle":30, "catnip_sachet":31,
	"sea_salt":32, "moonstone":33, "crescent_gift":34, "lunar_latte":35,
	"honey_oatcakes":36, "cinnamon_moon_roll":37, "blueberry_scone":38, "plum_cordial":39,
	"pear_conserve":40, "spiced_apple_cider":41, "violet_honey":42, "ginger_star_biscuits":43,
	"rosewater_soda":44, "blackberry_chocolate":45, "moon_hand_pies":46, "cloudberry_syrup":47,
	"star_crackers":48, "lemon_teacake":49, "chamomile_sachets":50, "honeycomb_drops":51,
	"illustrated_postcards":52, "pocket_compass":53, "moon_handkerchief":54, "midnight_storybook":55,
	"moon_enamel_brooch":56, "star_hairclip":57, "lavender_ribbon":58, "crescent_tea_strainer":59,
	"botanical_incense":60, "moonflower_sachet":61, "star_keyring":62, "seashell_charm":63,
	"rain_vial":64, "pressed_flower_bookmark":65, "moon_phase_calendar":66, "moon_teacup_gift":67,
	"blackberry_preserve_tin":68, "wildflower_honey_jar":69, "summer_peach_preserves":70, "midnight_cocoa_tin":71,
	"roasted_coffee_beans":72, "bergamot_tea_tin":73, "vanilla_pod_bottle":74, "cinnamon_bundle":75,
	"bread_flour_sack":76, "caster_sugar_jar":77, "cultured_butter_crock":78, "fresh_cream_bottle":79,
		"moonwater_plums":80, "golden_pear":81, "concord_grapes":82, "rye_loaf":83,
	"tomato_soup_tin":84, "wild_rice_bag":85, "oat_flakes_tin":86, "olive_oil_bottle":87,
	"maple_syrup_bottle":88, "peppercorn_jar":89, "apple_basket":90, "orange_basket":91,
	"carrot_bunch":92, "woodland_mushrooms":93, "cheddar_wheel":94, "eggs_basket":95,
	"fresh_ginger_root":96, "sliced_peaches_tin":97, "dried_figs_jar":98, "popcorn_kernels_bag":99
}

var game: MoonmartGame
var settings_manager: MoonmartSettings
var settings_panel: MoonmartSettingsPanel
var save_recovery_button: Button
var world: Node2D
var room_camera: Camera2D
var architecture_layer: Node2D
var night_sky_layer: Node2D
var exterior_parallax_layer: Node2D
var window_effects_layer: Node2D
var separate_lighting_layer: Node2D
var prop_effects_layer: Node2D
var background_furniture_layer: Node2D
var foreground_furniture_layer: Node2D
var characters_layer: Node2D
var player: Sprite2D
var player_body: CharacterBody2D
var shop_collision_root: Node2D
var pip: Sprite2D
var miso: Sprite2D
var agnes_sprite: Sprite2D
var moon_glow: PointLight2D
var pip_glow: PointLight2D
var window_sky: Sprite2D
var window_parallax: Sprite2D
var back_door_sprite: Sprite2D
var rain_overlay: Sprite2D
var window_echo: Sprite2D
var seasonal_sprites: Array[Sprite2D] = []
var active_season_visual := ""
var location_weather_sprites: Array[Sprite2D] = []
var location_snow_sprites: Array[Sprite2D] = []
var location_wind_sprites: Array[Sprite2D] = []
var location_weather_scene_id := 0
var environment_effect_overrides: Dictionary = {}
var environment_layer_overrides: Dictionary = {}
var reduced_animation_enabled := false
var reduced_flashing_enabled := false
var visual_effects_enabled := true
var dynamic_lighting_enabled := true
var ambience: AudioStreamPlayer
var shop_detail_players: Dictionary = {}
var miso_purr_player: AudioStreamPlayer
var miso_ambient_manager = MISO_AMBIENT_SCRIPT.new()
var miso_ambient_route: Array[Vector2] = []
var miso_ambient_route_index := 0
var miso_ambient_target := Vector2.ZERO
var miso_knockable_vase: Sprite2D
var miso_vase_base_transform := Transform2D.IDENTITY
var miso_vase_knock_elapsed := 0.0
var miso_vase_knock_active := false
var miso_purr_hold_time := 0.0
var miso_play_hold_time := 0.0
var footstep_cooldown := 0.0
var miso_reaction_time_remaining := 0.0
var weather_ambience: AudioStreamPlayer
var active_weather_audio := ""
var sfx_manager: MoonmartSfxManager
var radio_player: AudioStreamPlayer
var location_music_player: AudioStreamPlayer
var location_music_transition_player: AudioStreamPlayer
var location_music_transition_elapsed := 0.0
var location_music_transition_start_db := -18.0
var location_music_transition_correlated := false
var location_music_active_path := ""
var location_music_target_path := ""
var location_ambience_player: AudioStreamPlayer
var location_ambience_transition_player: AudioStreamPlayer
var location_ambience_transition_elapsed := 0.0
var location_ambience_transition_start_db := -14.0
var location_ambience_transition_target_db := -14.0
var location_ambience_transition_target_start_db := -80.0
var location_ambience_active_volume_db := -14.0
var location_ambience_active_path := ""
var location_ambience_target_path := ""
var location_ambience_fade_tween: Tween
var shop_ambience_fade_tween: Tween
var shop_ambience_target_volume_db := -13.0
var narrative_music_player: AudioStreamPlayer
var narrative_music_target_db := -80.0
var radio_station_index := 1
var created_audio_buses: Array[StringName] = []
const RADIO_STATIONS: Array[Dictionary] = [
	{"id":"window_seat", "name":"Window Seat", "detail":"Soft piano and music-box notes", "path":"res://assets/audio/radio/window_seat.wav", "volume_db":-17.5},
	{"id":"bellwether_after_hours", "name":"Bellwether After Hours", "detail":"Felt piano, plucked strings, and brushed texture", "path":"res://assets/audio/radio/bellwether_after_hours.wav", "volume_db":-16.5},
	{"id":"harbour_hush", "name":"Harbour Hush", "detail":"Warm acoustic-like plucks and brushed texture", "path":"res://assets/audio/radio/harbour_hush.wav", "volume_db":-17.0}
]
const LOCATION_MUSIC_PATHS := {
	"shop_backroom":"res://assets/audio/radio/window_seat.wav",
	"tea_corner":"res://assets/audio/radio/window_seat.wav",
	"reading_nook":"res://assets/audio/radio/window_seat.wav",
	"enchanted_greenhouse":"res://assets/audio/radio/window_seat.wav",
	"old_bellwether":"res://assets/audio/locations/old_bellwether.wav",
	"whisperwood":"res://assets/audio/locations/whisperwood.wav",
	"moonwater_harbour":"res://assets/audio/locations/harbour_lighthouse.wav",
	"old_lighthouse":"res://assets/audio/locations/harbour_lighthouse.wav",
	"midnight_platform":"res://assets/audio/locations/midnight_between.wav",
	"hidden_midnight_room":"res://assets/audio/locations/midnight_between.wav"
}
const LOCATION_AMBIENCE_PATHS := {
	"shop_backroom":"res://assets/audio/moonmart_night_loop.wav",
	"tea_corner":"res://assets/audio/moonmart_night_loop.wav",
	"reading_nook":"res://assets/audio/moonmart_night_loop.wav",
	"enchanted_greenhouse":"res://assets/audio/moonmart_night_loop.wav",
	"old_bellwether":"res://assets/audio/ambience/locations/bellwether_night.wav",
	"whisperwood":"res://assets/audio/ambience/locations/whisperwood_night.wav",
	"moonwater_harbour":"res://assets/audio/ambience/locations/moonwater_harbour.wav",
	"old_lighthouse":"res://assets/audio/ambience/locations/moonwater_harbour.wav",
	"midnight_platform":"res://assets/audio/ambience/locations/midnight_air.wav",
	"hidden_midnight_room":"res://assets/audio/ambience/locations/midnight_air.wav"
}
const NARRATIVE_MUSIC_PATH := "res://assets/audio/narrative/remembered_threshold.wav"
const MAP_PAGE_SIZE := 9
var decorative_plant: Sprite2D
var kettle_steam: Sprite2D
var craft_station_sprites: Dictionary = {}
var customer_visuals: Dictionary = {}
var customer_states: Dictionary = {}
var customer_targets: Dictionary = {}
var customer_routes: Dictionary = {}
var customer_route_indices: Dictionary = {}
var current_location_scene: Node2D
var current_location_id := "moonmart"
var map_location_ids: Array[String] = []
var map_page := 0
var mystery_case_ids: Array[String] = []
var upgrade_ids: Array[String] = []
var mystery_hypotheses: Array[Dictionary] = []
var investigation_clue_ids: Array[String] = []
var selected_investigation_id := ""
var decoration_ids: Array[String] = []
var selected_decoration_id := ""
var decoration_cursor := Vector2i(12, 8)
var decoration_cursor_offset := Vector2.ZERO
var decoration_rotated := false
var decoration_page := 0
var decoration_preview: Sprite2D
var decoration_visuals: Dictionary = {}
var decoration_lights: Dictionary = {}
var decoration_light_texture: Texture2D
var shop_return_position := Vector2(1450, 760)
var customer_id := ""
var active_location_talker_id := ""
var player_position := Vector2(790, 748)
var pip_anchor := Vector2(536, 657)
var miso_previous_position := Vector2(1278, 655)
var face_direction := 1.0
var nearby_id := ""
var animation_clock := 0.0
var player_frame := 0
var player_facing_row := 2
var player_action_frame := -1
var player_action_time_remaining := 0.0
var customer_frame := 0
var active_panel := ""
var message_open := false
var hud_layer: CanvasLayer
var clock_label: Label
var coin_label: Label
var moon_token_label: Label
var prompt_label: Label
var hidden_paw_marker: Label
var message_panel: PanelContainer
var message_label: Label
var message_hint_label: Label
var side_panel: PanelContainer
var side_scroll: ScrollContainer
var side_label: Label
var last_side_panel_text := ""
var side_panel_icon: TextureRect
var side_panel_icon_kind := ""
var puzzle_answer_input: LineEdit
var selected_product_icon: TextureRect
var pause_buttons: Array[Button] = []
var pause_previous_focus_owner: Control
var speed_slider: HSlider
var speed_label: Label
var assisted_checkout_enabled := false
var simplified_crafting_enabled := false
var auto_stock_config: Dictionary = {"enabled":false, "targets":{}}
var mystery_hint_level := "contextual"
var title_label: Label
var status_label: Label
var miso_reaction_panel: PanelContainer
var miso_reaction_label: Label
var controls_hint_label: Label
var customer_name := ""
var current_journal := ""
var current_clock := "11:30 PM"
var current_coins := 12
var current_moons := 0
var shift_status := "between_shifts"
var stocked_product_ids: Array[String] = []
var stock_page := 0
var stock_selected_slot := 0
var stock_category := "SHELF GOODS"
var stock_panel_mode := "retail_shelf"
var available_recipe_ids: Array[String] = []
var craft_experiment_ingredient_ids: Array[String] = []
var craft_experiment_selected: Dictionary = {}
var craft_page := 0
var active_craft_station_id := "magical_kettle"
var checkout_customer_id := ""
var active_environmental_puzzle_id := ""
var checkout_item_ids: Array[String] = []
var checkout_scanned: Dictionary = {}
var checkout_cursor := 0
var checkout_phase := "scan"
var checkout_packing_choice_index := 0
var checkout_tender_choice_index := 0
var checkout_recommendation_choice_index := 0
var checkout_recommendation_resolved := false
var checkout_recommended_items: Dictionary = {}
var checkout_recommendation_item_id := ""
const CHECKOUT_PACKING_CHOICES: Array[String] = ["paper", "careful", "reusable"]
const CHECKOUT_TENDER_CHOICES: Array[String] = ["cash", "card"]
const CHECKOUT_RECOMMENDATION_CHOICES: Array[String] = ["offer", "skip"]

const INTERACTION_POINTS := {
	"shelf": Vector2(195, 638), "fridge": Vector2(475, 638),
	"miso": Vector2(1325, 697), "register": Vector2(1160, 674),
	"coffee_machine": Vector2(520, 671), "tea_counter": Vector2(640, 671),
	"kettle": Vector2(760, 671), "microwave": Vector2(880, 671),
	"sandwich_station": Vector2(1000, 671), "bakery_warmer": Vector2(1180, 671),
	"window": Vector2(820, 650), "back_door": Vector2(1474, 580),
	"journal": Vector2(1350, 630), "cat_bed": Vector2(1440, 762)
}
const INTERACTION_PRIORITY_BY_ID := {
	"ReturnToMoonmart": 30, "ShopDoor": 30, "BetweenDoorway": 30, "back_door": 30,
	"register": 20, "shelf": 20, "fridge": 20, "SupplyShelves": 20, "DeliveryCrates": 20, "HandTrolley": 20
}

const CRAFT_STATION_NAMES := {
	"coffee": "COFFEE MACHINE", "tea": "TEA COUNTER", "microwave": "MICROWAVE",
	"sandwich": "SANDWICH STATION", "magical_kettle": "MAGICAL KETTLE", "bakery_warmer": "BAKERY WARMER"
}
const CRAFT_STATION_UI_IDS := {
	"coffee": "craft.station.coffee", "tea": "craft.station.tea", "microwave": "craft.station.microwave",
	"sandwich": "craft.station.sandwich", "magical_kettle": "craft.station.magical_kettle", "bakery_warmer": "craft.station.bakery_warmer"
}
const CRAFT_STATION_ACCESS_IDS := {
	"coffee_machine": "coffee", "tea_counter": "tea", "microwave": "microwave",
	"sandwich_station": "sandwich", "kettle": "magical_kettle", "bakery_warmer": "bakery_warmer"
}

const SHOP_FIXED_FURNITURE_CELLS: Array[Vector2i] = [
	Vector2i(2, 5), Vector2i(3, 5),
	Vector2i(7, 5), Vector2i(8, 5),
	Vector2i(9, 5), Vector2i(10, 5), Vector2i(11, 5),
	Vector2i(13, 6), Vector2i(14, 6),
	Vector2i(15, 6), Vector2i(16, 6),
	Vector2i(12, 6), Vector2i(20, 4), Vector2i(20, 5), Vector2i(21, 6),
	Vector2i(2, 9), Vector2i(21, 9)
]
const CLEANING_ACTION_IDS: Array[String] = ["wipe_counter", "sweep_floor", "water_plants", "clear_cups", "take_out_rubbish", "refill_dispenser"]
const CLEANING_ACTION_NAMES: Array[String] = ["Wipe the counter", "Sweep the floor", "Water the plants", "Clear the cups", "Take out the rubbish", "Refill the dispenser"]
const CORE_SHOPPER_WALK_IDS: Array[String] = ["conductor", "elias", "mara", "osric", "fern", "lucien", "wren"]
const CORE_SHOPPER_TALK_FRAMES := {"conductor": 2, "elias": 3, "mara": 3, "osric": 3, "fern": 3, "lucien": 3, "wren": 3}
const CORE_SHOPPER_BROWSE_FRAMES := {"conductor": 3, "elias": 2, "mara": 2, "osric": 2, "fern": 2, "lucien": 2}

func _ready() -> void:
	settings_manager = SETTINGS_SCRIPT.new()
	settings_manager.setup()
	# Load system-language catalogs before building text-bearing HUD and menu controls.
	game = GAME_SCRIPT.new()
	if has_meta("moonmart_test_language") and game.has_method("set_locale_language_override_for_testing"):
		game.call("set_locale_language_override_for_testing", String(get_meta("moonmart_test_language")))
	add_child(game)
	_build_world()
	_build_hud()
	_build_save_recovery_button()
	_ensure_audio_buses()
	sfx_manager = SFX_MANAGER_SCRIPT.new()
	sfx_manager.name = "MoonmartSfxManager"
	add_child(sfx_manager)
	_configure_miso_ambient()
	save_recovery_button.text = _localize_ui("save.recovery.button", "Archive old save and start fresh")
	controls_hint_label.text = _localize_ui("hud.controls_hint", "Move · interact · inspect · journal · clues · map · stock · pause  ·  Rebind controls in Settings")
	_build_settings_panel()
	game.clock_updated.connect(_on_clock_updated)
	game.message_changed.connect(_on_message_changed)
	game.save_failed.connect(_on_game_save_failed)
	game.journal_changed.connect(_on_journal_changed)
	game.customer_changed.connect(_on_customer_changed)
	game.companion_reaction.connect(_on_companion_reaction)
	game.customer_state_changed.connect(_on_customer_state_changed)
	game.money_changed.connect(_on_money_changed)
	game.shift_changed.connect(_on_shift_changed)
	game.story_event.connect(_on_story_event)
	game.sale_completed.connect(_on_sale_completed)
	settings_panel.configure(settings_manager, _settings_product_rows())
	settings_manager.settings_save_failed.connect(_on_settings_save_failed)
	settings_manager.settings_saved.connect(_on_settings_saved)
	_connect_settings_panel()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_initial_settings()
	_on_money_changed(game.inventory.coins, game.inventory.moon_tokens)
	_on_shift_changed(game.shift_number, game.shift_status)
	_on_journal_changed(game.journal_text())
	_configure_decoration_access()
	game.decoration.layout_changed.connect(_rebuild_shop_collision_bodies)
	_rebuild_shop_collision_bodies()
	_sync_decoration_visuals()
	if game.has_saved_player_position("moonmart"):
		_restore_player_position("moonmart", player_position)
	if game.world_map.current_location != "moonmart":
		_travel_to_location(game.world_map.current_location, false)
	if not game.world_map.ending_id.is_empty():
		_apply_ending_world_state(game.world_map.ending_id)
	_sync_ambience_for_location()
	clock_label.text = "☾  " + game.clock.clock_text()
	if game.save_recovery_required:
		status_label.text = _localize_ui("save.recovery.status", "Save recovery needed")
		_on_message_changed(_format_localized_ui("save.recovery.message", "The existing save could not be read and remains preserved. {reason} Use the recovery button to archive it intact and begin a fresh game.", {"reason":game.save_recovery_message}))
		save_recovery_button.visible = true
	elif game.save_recovered_from_backup:
		status_label.text = _localize_ui("save.recovery.backup_restored", "Backup save restored")
		_on_message_changed(_localize_ui("save.recovery.backup_notice", "The primary save was unavailable. Moonmart restored the last-known-good backup."))
	elif game.save_recovered_from_staging:
		status_label.text = _localize_ui("save.recovery.staged_restored", "Interrupted save restored")
		_on_message_changed(_localize_ui("save.recovery.staged_notice", "Moonmart restored a verified interrupted save. Your saved progress is available."))
	elif game.miso_dream_sequence.active:
		_open_dream_panel()
	elif game.shift_number == 0:
		_update_location_hud_caption()
		_on_message_changed(_format_localized_ui("welcome.first_night", "Welcome to Moonmart. Miso is asleep on the counter. Press {interact} to begin your first night.", {"interact":_binding_label("interact")}))
	elif game.shift_status == "open":
		for customer in game.customers.active:
			_on_customer_changed(customer, true, false)
	else:
		_on_message_changed(_format_localized_ui("welcome.next_night", "Welcome back to Moonmart. Your last night is saved. Press {interact} to begin the next one.", {"interact":_binding_label("interact")}))
	_refresh_message_hint()
	set_process(true)

func _exit_tree() -> void:
	_stop_audio_players()
	for bus_name in created_audio_buses:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index > 0:
			AudioServer.remove_bus(bus_index)
	created_audio_buses.clear()

func _stop_audio_players() -> void:
	set_process(false)
	if game != null and is_instance_valid(game):
		game.set_process(false)
	var active_audio_nodes := find_children("*", "AudioStreamPlayer", true, false)
	for audio_node in active_audio_nodes:
		var player := audio_node as AudioStreamPlayer
		if player == null:
			continue
		player.stop()
		player.stream = null
	shop_detail_players.clear()
	ambience = null
	weather_ambience = null
	location_ambience_player = null
	location_ambience_transition_player = null
	location_ambience_fade_tween = null
	shop_ambience_fade_tween = null
	location_music_player = null
	location_music_transition_player = null
	narrative_music_player = null
	radio_player = null
	miso_purr_player = null

func _build_save_recovery_button() -> void:
	save_recovery_button = Button.new()
	save_recovery_button.name = "ArchiveUnreadableSave"
	save_recovery_button.text = _localize_ui("save.recovery.button", "Archive old save and start fresh")
	save_recovery_button.position = Vector2(560, 126)
	save_recovery_button.size = Vector2(480, 54)
	save_recovery_button.add_theme_font_override("font", MOONMART_FONT)
	save_recovery_button.add_theme_font_size_override("font_size", 20)
	save_recovery_button.add_theme_color_override("font_color", Color("fff0d8"))
	save_recovery_button.add_theme_stylebox_override("normal", _style(Color("51445f"), Color("e4b189"), 2, 12))
	save_recovery_button.add_theme_stylebox_override("hover", _style(Color("765a70"), Color("ffe1a5"), 3, 12))
	save_recovery_button.visible = false
	save_recovery_button.pressed.connect(_archive_save_and_start_fresh)
	hud_layer.add_child(save_recovery_button)

func _archive_save_and_start_fresh() -> void:
	if game.archive_problem_save_and_start_fresh():
		save_recovery_button.visible = false
		status_label.text = _localize_ui("save.recovery.ready", "Ready for a fresh start")
		_on_message_changed(game.last_message)
	else:
		_on_message_changed(_localize_ui("save.recovery.archive_failed", "Moonmart could not safely archive the old save. It remains untouched; please check available storage and try again."))

func _start_ambience(initial_volume_db: float = -13.0) -> void:
	if current_location_id != "moonmart":
		return
	var stream := load("res://assets/audio/moonmart_night_loop.wav") as AudioStreamWAV
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 176400
	ambience = AudioStreamPlayer.new()
	ambience.name = "MoonmartNightAmbience"
	ambience.stream = stream
	ambience.bus = "Music"
	ambience.volume_db = initial_volume_db
	shop_ambience_target_volume_db = initial_volume_db
	add_child(ambience)
	ambience.play()
	_sync_shop_soundscape()

func _sync_shop_soundscape() -> void:
	var details := {
		"refrigerator": {"path":"res://assets/audio/ambience/shop/refrigerator_hum.wav", "volume_db":-30.0},
		"clock": {"path":"res://assets/audio/ambience/shop/clock_tick.wav", "volume_db":-35.0},
		"distant_cars": {"path":"res://assets/audio/ambience/shop/distant_cars.wav", "volume_db":-34.0}
	}
	for detail_id in details:
		var player := shop_detail_players.get(detail_id) as AudioStreamPlayer
		if current_location_id != "moonmart":
			if player != null:
				player.stop()
			continue
		var definition: Dictionary = details[detail_id]
		if player == null:
			player = AudioStreamPlayer.new()
			player.name = "MoonmartDetail_%s" % String(detail_id)
			player.bus = "Music"
			player.volume_db = float(definition.volume_db)
			add_child(player)
			shop_detail_players[detail_id] = player
		if player.stream == null:
			var stream := load(String(definition.path)) as AudioStreamWAV
			if stream == null:
				continue
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.data.size() / (4 if stream.stereo else 2))
			player.stream = stream
		if not player.playing:
			player.play()
	_sync_miso_purr()

func _sync_miso_purr() -> void:
	if current_location_id != "moonmart":
		if miso_purr_player != null:
			miso_purr_player.stop()
		return
	var resting := game != null and game.shift_status != "open"
	var should_purr := resting or miso_purr_hold_time > 0.0
	if not should_purr:
		if miso_purr_player != null:
			miso_purr_player.stop()
		return
	if miso_purr_player == null:
		miso_purr_player = AudioStreamPlayer.new()
		miso_purr_player.name = "MisoPurr"
		miso_purr_player.bus = "SFX"
		miso_purr_player.volume_db = -25.0
		add_child(miso_purr_player)
		var stream := load("res://assets/audio/ambience/shop/miso_purr.wav") as AudioStreamWAV
		if stream == null:
			return
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.data.size() / (4 if stream.stereo else 2))
		miso_purr_player.stream = stream
	if not miso_purr_player.playing:
		miso_purr_player.play()
	miso_purr_player.bus = "Music" if resting else "SFX"
	miso_purr_player.volume_db = -25.0 if resting else -27.0

func _sync_ambience_for_location() -> void:
	if current_location_id != "moonmart":
		if ambience != null and ambience.playing:
			_fade_shop_ambience_to(-80.0, true)
		if weather_ambience != null:
			weather_ambience.stop()
		active_weather_audio = ""
		if radio_player != null:
			radio_player.stop()
		_sync_shop_soundscape()
		_play_location_score()
		_play_location_ambience()
		return
	if location_music_player != null:
		location_music_player.stop()
	if location_music_transition_player != null:
		location_music_transition_player.stop()
	location_music_active_path = ""
	location_music_target_path = ""
	location_music_transition_elapsed = 0.0
	var location_ambience_is_playing := (location_ambience_player != null and location_ambience_player.playing) or (location_ambience_transition_player != null and location_ambience_transition_player.playing)
	if ambience == null:
		_start_ambience(-80.0 if location_ambience_is_playing else -13.0)
	elif not ambience.playing:
		ambience.volume_db = -80.0 if location_ambience_is_playing else -13.0
		ambience.play()
	if location_ambience_is_playing:
		_fade_location_ambience_out()
	else:
		_stop_location_ambience()
	_apply_radio_station()
	_sync_weather_audio()
	_sync_shop_soundscape()

func _play_location_ambience() -> void:
	if location_ambience_fade_tween != null and location_ambience_fade_tween.is_running():
		location_ambience_fade_tween.kill()
		location_ambience_fade_tween = null
		if location_ambience_target_path.is_empty() and location_ambience_transition_player != null and location_ambience_transition_player.playing:
			if location_ambience_transition_player.volume_db > location_ambience_player.volume_db:
				var quieter_player := location_ambience_player
				location_ambience_player = location_ambience_transition_player
				location_ambience_transition_player = quieter_player
			location_ambience_transition_player.stop()
			location_ambience_active_path = String(location_ambience_player.stream.resource_path) if location_ambience_player.stream != null else ""
			if not location_ambience_active_path.is_empty():
				location_ambience_active_volume_db = _location_ambience_base_volume_db(location_ambience_active_path)
			location_ambience_target_path = ""
			location_ambience_transition_elapsed = 0.0
	var path := String(LOCATION_AMBIENCE_PATHS.get(current_location_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		_stop_location_ambience()
		return
	if location_ambience_player == null:
		location_ambience_player = AudioStreamPlayer.new()
		location_ambience_player.name = "MoonmartLocationAmbience"
		location_ambience_player.bus = "Music"
		add_child(location_ambience_player)
	if path == location_ambience_target_path and location_ambience_transition_player != null and location_ambience_transition_player.playing:
		return
	var target_volume_db := -21.0 if path == "res://assets/audio/moonmart_night_loop.wav" else -14.0
	var transition_running := location_ambience_transition_player != null and location_ambience_transition_player.playing
	if transition_running:
		if path == location_ambience_active_path:
			var reversing_path := location_ambience_target_path
			var active_player := location_ambience_player
			location_ambience_player = location_ambience_transition_player
			location_ambience_transition_player = active_player
			location_ambience_active_path = reversing_path
			location_ambience_active_volume_db = _location_ambience_base_volume_db(reversing_path)
			location_ambience_transition_start_db = location_ambience_player.volume_db
			location_ambience_transition_target_start_db = location_ambience_transition_player.volume_db
			location_ambience_transition_target_db = target_volume_db
			location_ambience_transition_elapsed = 0.0
			location_ambience_target_path = path
			return
		if location_ambience_transition_player.volume_db > location_ambience_player.volume_db:
			var previous_target_path := location_ambience_target_path
			var quieter_player := location_ambience_player
			location_ambience_player = location_ambience_transition_player
			location_ambience_transition_player = quieter_player
			location_ambience_active_path = previous_target_path
			location_ambience_active_volume_db = _location_ambience_base_volume_db(previous_target_path)
	if path == location_ambience_active_path and location_ambience_player.playing:
		if location_ambience_transition_player != null and location_ambience_transition_player.playing:
			location_ambience_transition_player.stop()
			location_ambience_player.volume_db = location_ambience_active_volume_db
			location_ambience_target_path = ""
			location_ambience_transition_elapsed = 0.0
		elif not is_equal_approx(location_ambience_player.volume_db, location_ambience_active_volume_db):
			location_ambience_fade_tween = create_tween()
			location_ambience_fade_tween.tween_property(location_ambience_player, "volume_db", location_ambience_active_volume_db, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		_stop_location_ambience()
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	var bytes_per_frame := 4 if stream.stereo else 2
	stream.loop_end = int(stream.data.size() / bytes_per_frame)
	if not location_ambience_player.playing:
		if location_ambience_transition_player != null:
			location_ambience_transition_player.stop()
		location_ambience_player.stream = stream
		location_ambience_player.volume_db = target_volume_db
		location_ambience_player.play()
		location_ambience_active_path = path
		location_ambience_active_volume_db = target_volume_db
		location_ambience_target_path = ""
		return
	if location_ambience_transition_player == null:
		location_ambience_transition_player = AudioStreamPlayer.new()
		location_ambience_transition_player.name = "MoonmartLocationAmbienceB"
		location_ambience_transition_player.bus = "Music"
		add_child(location_ambience_transition_player)
	location_ambience_transition_player.stop()
	location_ambience_transition_player.stream = stream
	location_ambience_transition_player.volume_db = -80.0
	location_ambience_transition_player.play()
	location_ambience_transition_start_db = location_ambience_player.volume_db
	location_ambience_transition_target_db = target_volume_db
	location_ambience_transition_target_start_db = -80.0
	location_ambience_transition_elapsed = 0.0
	location_ambience_target_path = path

func _location_ambience_base_volume_db(path: String) -> float:
	return -21.0 if path == "res://assets/audio/moonmart_night_loop.wav" else -14.0

func _stop_location_ambience() -> void:
	if location_ambience_fade_tween != null and location_ambience_fade_tween.is_running():
		location_ambience_fade_tween.kill()
	location_ambience_fade_tween = null
	if location_ambience_player != null:
		location_ambience_player.stop()
	if location_ambience_transition_player != null:
		location_ambience_transition_player.stop()
	location_ambience_active_path = ""
	location_ambience_target_path = ""
	location_ambience_transition_elapsed = 0.0
	location_ambience_transition_target_start_db = -80.0

func _fade_location_ambience_out() -> void:
	if location_ambience_fade_tween != null and location_ambience_fade_tween.is_running():
		location_ambience_fade_tween.kill()
	location_ambience_target_path = ""
	location_ambience_transition_elapsed = 0.0
	location_ambience_fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var has_playing_player := false
	for player in [location_ambience_player, location_ambience_transition_player]:
		if player != null and player.playing:
			has_playing_player = true
			location_ambience_fade_tween.tween_property(player, "volume_db", -80.0, 1.5)
	if not has_playing_player:
		_stop_location_ambience()
		return
	location_ambience_fade_tween.set_parallel(false)
	location_ambience_fade_tween.tween_callback(_finish_location_ambience_fade_out)

func _finish_location_ambience_fade_out() -> void:
	location_ambience_fade_tween = null
	_stop_location_ambience()

func _fade_shop_ambience_to(target_volume_db: float, stop_when_finished: bool) -> void:
	if ambience == null:
		return
	if is_equal_approx(shop_ambience_target_volume_db, target_volume_db):
		if shop_ambience_fade_tween != null and shop_ambience_fade_tween.is_running():
			return
		if is_equal_approx(ambience.volume_db, target_volume_db):
			return
	if shop_ambience_fade_tween != null and shop_ambience_fade_tween.is_running():
		shop_ambience_fade_tween.kill()
	shop_ambience_target_volume_db = target_volume_db
	shop_ambience_fade_tween = create_tween()
	shop_ambience_fade_tween.tween_property(ambience, "volume_db", target_volume_db, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if stop_when_finished:
		shop_ambience_fade_tween.tween_callback(_stop_shop_ambience_after_travel)

func _stop_shop_ambience_after_travel() -> void:
	shop_ambience_fade_tween = null
	shop_ambience_target_volume_db = -80.0
	if current_location_id != "moonmart" and ambience != null:
		ambience.stop()

func _shop_ambience_target_db() -> float:
	if game == null or current_location_id != "moonmart" or not game.shop_progression.has_upgrade("shop_radio"):
		return -13.0
	var station: Dictionary = RADIO_STATIONS[clampi(radio_station_index, 0, RADIO_STATIONS.size() - 1)]
	var path := String(station.get("path", ""))
	return -21.0 if not path.is_empty() and ResourceLoader.exists(path) else -13.0

func _update_location_ambience_transition(delta: float) -> void:
	if location_ambience_target_path.is_empty() or location_ambience_player == null or location_ambience_transition_player == null or not location_ambience_transition_player.playing:
		return
	location_ambience_transition_elapsed += delta
	var amount := clampf(location_ambience_transition_elapsed / 2.0, 0.0, 1.0)
	var old_gain := db_to_linear(location_ambience_transition_start_db) * cos(amount * PI * 0.5)
	var target_gain := db_to_linear(location_ambience_transition_target_db)
	var new_gain := db_to_linear(location_ambience_transition_target_start_db) * (1.0 - amount) + target_gain * amount
	if location_ambience_transition_target_start_db <= -79.5:
		new_gain = target_gain * sin(amount * PI * 0.5)
	location_ambience_player.volume_db = linear_to_db(maxf(old_gain, db_to_linear(-80.0)))
	location_ambience_transition_player.volume_db = linear_to_db(maxf(new_gain, db_to_linear(-80.0)))
	if amount < 1.0:
		return
	location_ambience_player.stop()
	var finished_player := location_ambience_transition_player
	location_ambience_transition_player = location_ambience_player
	location_ambience_player = finished_player
	location_ambience_active_path = location_ambience_target_path
	location_ambience_active_volume_db = location_ambience_transition_target_db
	location_ambience_target_path = ""
	location_ambience_transition_elapsed = 0.0
	location_ambience_player.volume_db = location_ambience_active_volume_db
	location_ambience_transition_player.stop()

func _sync_weather_audio() -> void:
	var expected_weather_audio := ""
	if game != null and current_location_id == "moonmart":
		var weather_shift := maxi(game.shift_number, 1) if game.shift_status == "open" else maxi(game.shift_number + 1, 1)
		if game.calendar.weather_for_shift(weather_shift) == "rain":
			expected_weather_audio = "res://assets/audio/ambience/moonmart_rain_window.wav"
	if expected_weather_audio.is_empty():
		if weather_ambience != null:
			weather_ambience.stop()
		active_weather_audio = ""
		return
	if expected_weather_audio == active_weather_audio and weather_ambience != null and weather_ambience.playing:
		return
	active_weather_audio = expected_weather_audio
	if weather_ambience == null:
		weather_ambience = AudioStreamPlayer.new()
		weather_ambience.name = "MoonmartWeatherAmbience"
		weather_ambience.bus = "Music"
		weather_ambience.volume_db = -22.0
		add_child(weather_ambience)
	var stream := load(expected_weather_audio) as AudioStreamWAV
	if stream == null:
		weather_ambience.stop()
		active_weather_audio = ""
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	var bytes_per_frame := 4 if stream.stereo else 2
	stream.loop_end = int(stream.data.size() / bytes_per_frame)
	weather_ambience.stream = stream
	weather_ambience.play()

func _sync_narrative_music(delta: float) -> void:
	var flags: Dictionary = game.story.flags if game != null else {}
	var story_is_unresolved: bool = bool(flags.get("pip_reflection", false)) and not bool(flags.get("boundary_stabilized", false)) and game.world_map.ending_id.is_empty()
	var story_location := current_location_id in ["moonmart", "shop_backroom", "tea_corner", "reading_nook", "enchanted_greenhouse", "hidden_midnight_room", "midnight_platform"]
	var should_play: bool = story_is_unresolved and story_location and ResourceLoader.exists(NARRATIVE_MUSIC_PATH)
	narrative_music_target_db = -18.0 if should_play else -80.0
	if narrative_music_player == null:
		if not should_play:
			return
		narrative_music_player = AudioStreamPlayer.new()
		narrative_music_player.name = "MoonmartNarrativeMusic"
		narrative_music_player.bus = "Music"
		narrative_music_player.volume_db = -80.0
		add_child(narrative_music_player)
	if should_play and not narrative_music_player.playing:
		var stream := load(NARRATIVE_MUSIC_PATH) as AudioStreamWAV
		if stream == null:
			return
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		var bytes_per_frame := 4 if stream.stereo else 2
		stream.loop_end = int(stream.data.size() / bytes_per_frame)
		narrative_music_player.stream = stream
		narrative_music_player.play()
	if narrative_music_player.playing:
		narrative_music_player.volume_db = move_toward(narrative_music_player.volume_db, narrative_music_target_db, delta * 8.0)
		if not should_play and narrative_music_player.volume_db <= -79.5:
			narrative_music_player.stop()

func _location_score_path() -> String:
	var base_path := String(LOCATION_MUSIC_PATHS.get(current_location_id, ""))
	if base_path.is_empty() or current_location_id in ["shop_backroom", "tea_corner"] or game == null:
		return base_path
	var weather_shift := maxi(game.shift_number, 1) if game.shift_status == "open" else maxi(game.shift_number + 1, 1)
	var weather := game.calendar.weather_for_shift(weather_shift)
	if weather not in ["rain", "fog", "wind", "snow"]:
		return base_path
	var variant_path := base_path.trim_suffix(".wav") + "_" + weather + ".wav"
	return variant_path if ResourceLoader.exists(variant_path) else base_path

func _new_location_score_player(node_name: String) -> AudioStreamPlayer:
	var player_node := AudioStreamPlayer.new()
	player_node.name = node_name
	player_node.bus = "Music"
	add_child(player_node)
	return player_node

func _location_score_family(path: String) -> String:
	var family := path.get_file().trim_suffix(".wav")
	for weather in ["rain", "fog", "wind", "snow"]:
		var suffix := "_" + String(weather)
		if family.ends_with(suffix):
			return family.trim_suffix(suffix)
	return family

func _play_location_score() -> void:
	var path := _location_score_path()
	if path.is_empty() or not ResourceLoader.exists(path):
		if location_music_player != null:
			location_music_player.stop()
		if location_music_transition_player != null:
			location_music_transition_player.stop()
		location_music_active_path = ""
		location_music_target_path = ""
		return
	if path == location_music_target_path and location_music_transition_player != null and location_music_transition_player.playing:
		return
	if path == location_music_active_path and location_music_player != null and location_music_player.playing:
		if location_music_transition_player != null and location_music_transition_player.playing:
			location_music_transition_player.stop()
			location_music_player.volume_db = -18.0
			location_music_target_path = ""
			location_music_transition_elapsed = 0.0
		return
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	var bytes_per_frame := 4 if stream.stereo else 2
	stream.loop_end = int(stream.data.size() / bytes_per_frame)
	if location_music_player == null:
		location_music_player = _new_location_score_player("MoonmartLocationScoreA")
	if not location_music_player.playing:
		if location_music_transition_player != null:
			location_music_transition_player.stop()
		location_music_player.stream = stream
		location_music_player.volume_db = -18.0
		location_music_player.play()
		location_music_active_path = path
		location_music_target_path = ""
		return
	if location_music_transition_player == null:
		location_music_transition_player = _new_location_score_player("MoonmartLocationScoreB")
	location_music_transition_player.stop()
	location_music_transition_player.stream = stream
	location_music_transition_player.volume_db = -80.0
	location_music_transition_correlated = _location_score_family(location_music_active_path) == _location_score_family(path)
	var transition_start := location_music_player.get_playback_position() if location_music_transition_correlated else 0.0
	location_music_transition_player.play(transition_start)
	location_music_transition_elapsed = 0.0
	location_music_transition_start_db = location_music_player.volume_db
	location_music_target_path = path

func _update_location_score_transition(delta: float) -> void:
	if location_music_player == null or location_music_transition_player == null or not location_music_transition_player.playing:
		return
	location_music_transition_elapsed += delta
	var amount := clampf(location_music_transition_elapsed / 2.0, 0.0, 1.0)
	var old_weight := 1.0 - amount if location_music_transition_correlated else cos(amount * PI * 0.5)
	var new_weight := amount if location_music_transition_correlated else sin(amount * PI * 0.5)
	var old_gain := db_to_linear(location_music_transition_start_db) * old_weight
	var new_gain := db_to_linear(-18.0) * new_weight
	location_music_player.volume_db = linear_to_db(maxf(old_gain, db_to_linear(-80.0)))
	location_music_transition_player.volume_db = linear_to_db(maxf(new_gain, db_to_linear(-80.0)))
	if amount < 1.0:
		return
	location_music_player.stop()
	var finished_player := location_music_transition_player
	location_music_transition_player = location_music_player
	location_music_player = finished_player
	location_music_player.volume_db = -18.0
	location_music_active_path = location_music_target_path
	location_music_target_path = ""
	location_music_transition_elapsed = 0.0
	location_music_transition_player.stop()

func _ensure_radio_player() -> void:
	if radio_player != null:
		return
	radio_player = AudioStreamPlayer.new()
	radio_player.name = "MoonmartRadioStation"
	radio_player.bus = "Music"
	radio_player.volume_db = -80.0
	add_child(radio_player)

func _apply_radio_station() -> void:
	if game == null:
		return
	_fade_shop_ambience_to(_shop_ambience_target_db(), false)
	if current_location_id != "moonmart" or not game.shop_progression.has_upgrade("shop_radio"):
		if radio_player != null:
			radio_player.stop()
		return
	_ensure_radio_player()
	var station: Dictionary = RADIO_STATIONS[clampi(radio_station_index, 0, RADIO_STATIONS.size() - 1)]
	var path := String(station.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		_fade_shop_ambience_to(-13.0, false)
		radio_player.stop()
		return
	if radio_player.stream != null and radio_player.stream.resource_path == path and radio_player.playing:
		return
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		_fade_shop_ambience_to(-13.0, false)
		radio_player.stop()
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	var bytes_per_frame := 4 if stream.stereo else 2
	stream.loop_end = int(stream.data.size() / bytes_per_frame)
	radio_player.stream = stream
	radio_player.volume_db = float(station.get("volume_db", -18.0))
	radio_player.play()

func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var bus_index := AudioServer.get_bus_count() - 1
		var bus_id := StringName(bus_name)
		AudioServer.set_bus_name(bus_index, bus_id)
		AudioServer.set_bus_send(bus_index, &"Master")
		created_audio_buses.append(bus_id)

func _build_settings_panel() -> void:
	settings_panel = SETTINGS_PANEL_SCRIPT.new()
	settings_panel.name = "MoonmartSettingsPanel"
	settings_panel.ui_text_lookup = Callable(self, "_localize_ui")
	settings_panel.locale_language_lookup = Callable(self, "_localization_language")
	add_child(settings_panel)

func _localize_ui(key: String, fallback: String) -> String:
	return game.localize_ui(key, fallback) if game != null else fallback

func _localization_language() -> String:
	return game.localization_language() if game != null else OS.get_locale_language().to_lower()

func _localized_product_name(product_id: String, fallback_name: String = "") -> String:
	var source_name := fallback_name
	if source_name.is_empty():
		source_name = String(game.inventory.products.get(product_id, {}).get("name", product_id)) if game != null else product_id
	return _localize_ui("product.%s.name" % product_id, source_name)

func _localized_recipe_name(recipe_id: String, fallback_name: String = "") -> String:
	var source_name := fallback_name
	if source_name.is_empty():
		source_name = String(game.recipes.get(recipe_id, {}).get("name", recipe_id)) if game != null else recipe_id
	return _localize_ui("recipe.%s.name" % recipe_id, source_name)

func _format_localized_ui(key: String, fallback: String, values: Dictionary = {}) -> String:
	return _localize_ui(key, fallback).format(values)

func _settings_product_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if game == null:
		return rows
	for product_id in game.inventory.products:
		var product: Dictionary = game.inventory.products[product_id].duplicate(true)
		product["id"] = String(product_id)
		product["name"] = _localized_product_name(String(product_id), String(product.get("name", product_id)))
		rows.append(product)
	return rows

func _connect_settings_panel() -> void:
	settings_panel.game_speed_changed.connect(_apply_settings_game_speed)
	settings_panel.assisted_checkout_changed.connect(func(enabled: bool) -> void: assisted_checkout_enabled = enabled)
	settings_panel.simplified_crafting_changed.connect(func(enabled: bool) -> void: simplified_crafting_enabled = enabled)
	settings_panel.auto_stock_changed.connect(func(enabled: bool, targets: Dictionary) -> void: auto_stock_config = {"enabled":enabled, "targets":targets.duplicate(true)})
	settings_panel.ui_scale_changed.connect(_apply_settings_ui_scale)
	settings_panel.dyslexia_font_changed.connect(_apply_readability_mode)
	settings_panel.visual_effects_changed.connect(_apply_visual_comfort_settings)
	settings_panel.lighting_changed.connect(_apply_dynamic_lighting_setting)
	settings_panel.audio_levels_changed.connect(_apply_audio_levels)
	settings_panel.mystery_hint_level_changed.connect(func(level: String) -> void: mystery_hint_level = level)
	settings_panel.input_remap_changed.connect(_refresh_message_hint)

func _refresh_message_hint(_action: String = "", _events: Array[InputEvent] = []) -> void:
	if message_hint_label != null:
		message_hint_label.text = _format_localized_ui("hud.message_continue", "{interact}  Continue", {"interact":_binding_label("interact")})
	if controls_hint_label != null:
		controls_hint_label.text = _format_localized_ui("hud.controls_hint", "Move {up}/{left}/{down}/{right} · Interact {interact} · Inspect {inspect} · Journal {journal} · Clues {clues} · Map {map} · Inventory {inventory} · Pause {pause} · Rebind in Settings", {
			"up":_binding_label("move_up"),
			"left":_binding_label("move_left"),
			"down":_binding_label("move_down"),
			"right":_binding_label("move_right"),
			"interact":_binding_label("interact"),
			"inspect":_binding_label("inspect"),
			"journal":_binding_label("journal"),
			"clues":_binding_label("mystery_board"),
			"map":_binding_label("town_map"),
			"inventory":_binding_label("inventory"),
			"pause":_binding_label("pause")
		})

func _apply_initial_settings() -> void:
	_apply_settings_game_speed(float(settings_manager.get_setting("game_speed", 1.0)))
	assisted_checkout_enabled = bool(settings_manager.get_setting("assisted_checkout", false))
	simplified_crafting_enabled = bool(settings_manager.get_setting("simplified_crafting", false))
	auto_stock_config = settings_manager.get_setting("auto_stock", {"enabled":false, "targets":{}}).duplicate(true)
	_apply_settings_ui_scale(float(settings_manager.get_setting("ui_scale", 1.0)))
	_apply_readability_mode(bool(settings_manager.get_setting("dyslexia_friendly_text", false)))
	_apply_visual_comfort_settings(bool(settings_manager.get_setting("visual_effects_enabled", true)), bool(settings_manager.get_setting("reduced_animation", false)), bool(settings_manager.get_setting("reduced_flashing", false)))
	_apply_dynamic_lighting_setting(bool(settings_manager.get_setting("dynamic_lighting", true)))
	_apply_audio_levels(float(settings_manager.get_setting("music_volume", 0.8)), float(settings_manager.get_setting("sfx_volume", 0.8)))
	var saved_station_id := String(settings_manager.get_setting("radio_station_id", "bellwether_after_hours"))
	for index in range(RADIO_STATIONS.size()):
		if String(RADIO_STATIONS[index].get("id", "")) == saved_station_id:
			radio_station_index = index
			break
	mystery_hint_level = String(settings_manager.get_setting("mystery_hint_level", "contextual"))

func _apply_settings_game_speed(multiplier: float) -> void:
	if game != null:
		game.set_game_speed(multiplier)
	if speed_slider != null:
		speed_slider.set_value_no_signal(clampf(multiplier, speed_slider.min_value, speed_slider.max_value))
	if speed_label != null:
		speed_label.text = _format_localized_ui("hud.shift_pace", "Shift pace · ×{pace}", {"pace":_format_locale_number(multiplier, 1)})

func _format_locale_number(value: float, decimal_places: int) -> String:
	var formatted := ("%." + str(maxi(0, decimal_places)) + "f") % value
	if _localization_language().begins_with("es"):
		formatted = formatted.replace(".", ",")
	return formatted

func _apply_settings_ui_scale(scale_value: float) -> void:
	var scale_factor := clampf(scale_value, 0.75, 1.12)
	if hud_layer != null:
		hud_layer.scale = Vector2.ONE * scale_factor
		var viewport_size := get_viewport().get_visible_rect().size
		if not hud_layer.has_meta("moonmart_reference_viewport_size"):
			hud_layer.set_meta("moonmart_reference_viewport_size", viewport_size)
		var reference_viewport: Vector2 = hud_layer.get_meta("moonmart_reference_viewport_size")
		var logical_viewport := viewport_size / scale_factor
		for child in hud_layer.get_children():
			if not child is Control:
				continue
			var control := child as Control
			if not control.has_meta("moonmart_ui_base_position"):
				control.set_meta("moonmart_ui_base_position", control.position)
			if not control.has_meta("moonmart_ui_base_size"):
				control.set_meta("moonmart_ui_base_size", control.size)
			if not control.has_meta("moonmart_ui_scale_anchor"):
				var rect_center := control.position + control.size * 0.5
				var anchor_x := 0.0 if rect_center.x < viewport_size.x * 0.31 else (viewport_size.x if rect_center.x > viewport_size.x * 0.66 else viewport_size.x * 0.5)
				var anchor_y := 0.0 if rect_center.y < viewport_size.y * 0.18 else (viewport_size.y if rect_center.y > viewport_size.y * 0.76 else viewport_size.y * 0.5)
				control.set_meta("moonmart_ui_scale_anchor", Vector2(anchor_x, anchor_y))
			var base_position: Vector2 = control.get_meta("moonmart_ui_base_position")
			var anchor: Vector2 = control.get_meta("moonmart_ui_scale_anchor")
			var base_size: Vector2 = control.get_meta("moonmart_ui_base_size")
			var anchor_ratio := Vector2(anchor.x / maxf(reference_viewport.x, 1.0), anchor.y / maxf(reference_viewport.y, 1.0))
			var resized_anchor := anchor_ratio * viewport_size
			control.size = base_size
			if control.name == "HudControlsHint":
				control.size.x = minf(base_size.x, logical_viewport.x - 24.0)
				control.position = Vector2((logical_viewport.x - control.size.x) * 0.5, base_position.y + resized_anchor.y / scale_factor - anchor.y)
			else:
				control.position = base_position + resized_anchor / scale_factor - anchor
	if settings_panel != null:
		settings_panel.call("set_ui_scale", scale_value)

func _on_viewport_size_changed() -> void:
	if settings_manager == null:
		return
	_apply_settings_ui_scale(float(settings_manager.get_setting("ui_scale", 1.0)))

func _apply_readability_mode(enabled: bool) -> void:
	var factor := 1.12 if enabled else 1.0
	var font: Font = OPEN_DYSLEXIC_FONT if enabled else MOONMART_FONT
	if hud_layer != null:
		_apply_label_readability(hud_layer, factor, font)
	if settings_panel != null:
		settings_panel.call("set_readability_mode", enabled)

func _apply_label_readability(node: Node, factor: float, font: Font) -> void:
	if node is Control:
		var control := node as Control
		control.add_theme_font_override("font", font)
		if node is Label or node is Button or node is LineEdit or node is OptionButton or node is SpinBox or node is CheckBox:
			var base_size := int(control.get_meta("moonmart_base_font_size", control.get_theme_font_size("font_size")))
			if base_size <= 0:
				base_size = 16
			control.set_meta("moonmart_base_font_size", base_size)
			control.add_theme_font_size_override("font_size", roundi(base_size * factor))
		if node is Label:
			control.add_theme_constant_override("line_spacing", 3 if factor > 1.0 else 0)
	for child in node.get_children():
		_apply_label_readability(child, factor, font)

func _apply_visual_comfort_settings(enabled: bool, reduced_animation: bool, reduced_flashing: bool) -> void:
	reduced_animation_enabled = reduced_animation
	reduced_flashing_enabled = reduced_flashing
	visual_effects_enabled = enabled
	_apply_environment_layer_visibility("window_effects", window_effects_layer)
	_apply_environment_layer_visibility("prop_effects", prop_effects_layer)
	if current_location_scene != null:
		for layer_name in ["WindowEffectsLayer", "WeatherEffectsLayer", "StoryEffectsLayer", "ForegroundEffectsLayer", "PropEffectsLayer"]:
			var effect_layer := current_location_scene.get_node_or_null(String(layer_name)) as Node2D
			if effect_layer != null:
				_apply_environment_layer_visibility(_location_layer_setting_name(String(layer_name)), effect_layer)

func _apply_dynamic_lighting_setting(enabled: bool) -> void:
	dynamic_lighting_enabled = enabled
	_apply_environment_layer_visibility("lighting", separate_lighting_layer)
	if current_location_scene != null:
		var location_lighting := current_location_scene.get_node_or_null("SeparateLightingLayer") as Node2D
		if location_lighting != null:
			_apply_environment_layer_visibility("location_lighting", location_lighting)

func _location_layer_setting_name(layer_name: String) -> String:
	match layer_name:
		"NightSkyLayer": return "location_night_sky"
		"ExteriorParallaxLayer": return "location_exterior_parallax"
		"WindowEffectsLayer": return "location_window_effects"
		"WeatherEffectsLayer": return "location_weather"
		"StoryEffectsLayer": return "location_story"
		"ForegroundEffectsLayer": return "location_foreground_effects"
		"PropEffectsLayer": return "location_prop_effects"
	return layer_name

func _apply_environment_layer_visibility(layer_name: String, layer: Node2D) -> void:
	if layer == null:
		return
	var setting_allows_visibility := true
	if layer_name in ["lighting", "location_lighting"]:
		setting_allows_visibility = dynamic_lighting_enabled
	elif layer_name in ["window_effects", "prop_effects", "location_window_effects", "location_weather", "location_story", "location_foreground_effects", "location_prop_effects"]:
		setting_allows_visibility = visual_effects_enabled
	var requested_visibility := bool(environment_layer_overrides.get(layer_name, true))
	layer.visible = requested_visibility and setting_allows_visibility

func _apply_audio_levels(music: float, sfx: float) -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, -80.0 if music <= 0.001 else linear_to_db(music))
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, -80.0 if sfx <= 0.001 else linear_to_db(sfx))

func _on_settings_save_failed() -> void:
	if settings_panel != null:
		settings_panel.show_save_notice(_localize_ui("settings.save_failed", "Settings were not saved. The file may use a newer format or the user data folder may not be writable."))

func _on_game_save_failed() -> void:
	_show_save_failure_notice()

func _show_save_failure_notice() -> void:
	if game.save_recovery_required:
		_on_message_changed(_format_localized_ui("save.recovery.message", "The existing save could not be read and remains preserved. {reason} Use the recovery button to archive it intact and begin a fresh game.", {"reason":game.save_recovery_message}))
	else:
		_on_message_changed(_localize_ui("save.commit_failed", "Moonmart could not save your progress. Your session is still open; check available storage or folder permissions, then try again."))

func _on_settings_saved() -> void:
	if settings_panel != null:
		settings_panel.show_save_notice("")

func _build_world() -> void:
	world = Node2D.new()
	world.name = "ShopFloor"
	add_child(world)
	room_camera = Camera2D.new()
	room_camera.name = "RoomCamera"
	room_camera.position = Vector2(800, 450)
	room_camera.enabled = true
	room_camera.limit_left = 0
	room_camera.limit_top = 0
	room_camera.limit_right = 1600
	room_camera.limit_bottom = 900
	room_camera.position_smoothing_enabled = true
	room_camera.position_smoothing_speed = 5.0
	add_child(room_camera)
	# Named layers make the Section 27 draw order explicit and keep VFX editable.
	night_sky_layer = _make_world_layer("NightSkyLayer", -4)
	exterior_parallax_layer = _make_world_layer("ExteriorParallaxLayer", -3)
	separate_lighting_layer = _make_world_layer("SeparateLightingLayer", -2)
	window_effects_layer = _make_world_layer("WindowEffectsLayer", -1)
	architecture_layer = _make_world_layer("ArchitectureLayer", 0)
	background_furniture_layer = _make_world_layer("BackgroundFurnitureLayer", 0)
	characters_layer = _make_world_layer("DepthSortedCharactersLayer", 0)
	foreground_furniture_layer = _make_world_layer("ForegroundFurnitureLayer", 0)
	prop_effects_layer = _make_world_layer("PropEffectsLayer", 20)
	shop_collision_root = Node2D.new()
	shop_collision_root.name = "ShopFixtureCollisionGrid"
	world.add_child(shop_collision_root)
	var shell := Sprite2D.new()
	shell.texture = load(SHELL_PATH) as Texture2D
	shell.centered = false
	shell.position = Vector2.ZERO
	shell.scale = Vector2(1600.0 / shell.texture.get_width(), 900.0 / shell.texture.get_height())
	shell.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	architecture_layer.add_child(shell)
	# Architecture overlays are catalogued separately. The alpha is clean, but
	# this room already has finished frames, signage, and trim; use these modules
	# only in a location composed around them.
	# Restore the center mullion as a raster slice from the same painted frame.
	var center_muntin := _atlas_sprite(shell.texture, Rect2(984, 106, 24, 324), shell.scale, Vector2(996, 268) * shell.scale, "WindowCenterMuntin", architecture_layer)
	center_muntin.z_index = 0
	# Exterior artwork and window effects remain independent from the architecture plate.
	var sky_texture := load(WINDOW_SKY_PATH) as Texture2D
	window_sky = _atlas_sprite(sky_texture, Rect2(Vector2.ZERO, Vector2(sky_texture.get_width(), sky_texture.get_height())), Vector2(0.44, 0.44), Vector2(730, 252), "NightSky", night_sky_layer)
	window_sky.z_index = -3
	var parallax_texture := load(WINDOW_PARALLAX_PATH) as Texture2D
	window_parallax = _atlas_sprite(parallax_texture, Rect2(Vector2.ZERO, Vector2(parallax_texture.get_width(), parallax_texture.get_height())), Vector2(0.44, 0.44), Vector2(730, 252), "BellwetherParallax", exterior_parallax_layer)
	window_parallax.z_index = -2
	# Dynamic halo is a separate Light2D. The room image contains no rays, particles, or light pools.
	moon_glow = PointLight2D.new()
	moon_glow.name = "MoonGlowLight"
	moon_glow.texture = _make_soft_light_texture()
	moon_glow.position = Vector2(770, 254)
	moon_glow.energy = 0.28
	moon_glow.color = Color(0.72, 0.70, 1.0)
	moon_glow.texture_scale = 1.2
	moon_glow.z_index = -2
	moon_glow.range_z_min = -3
	moon_glow.range_z_max = -2
	separate_lighting_layer.add_child(moon_glow)
	rain_overlay = _atlas_sprite(load(RAIN_ATLAS_PATH) as Texture2D, _grid_region(RAIN_ATLAS_PATH, 0, 0, 4, 1), Vector2(1.72, 0.43), Vector2(730, 252), "RainOnWindow", window_effects_layer)
	rain_overlay.z_index = -1
	rain_overlay.modulate = Color(0.82, 0.83, 0.98, 0.68)
	rain_overlay.visible = false
	window_echo = _atlas_sprite(load(MEMORY_ECHO_ATLAS_PATH) as Texture2D, _grid_region(MEMORY_ECHO_ATLAS_PATH, 0, 0, 4, 1), Vector2(1.72, 0.43), Vector2(730, 252), "WindowMemoryEcho", window_effects_layer)
	window_echo.z_index = -1
	window_echo.modulate = Color(0.88, 0.74, 0.93, 0.18)
	window_echo.visible = false
	var seasonal_sprite := _atlas_sprite(load(SEASONAL_ATLAS_PATH) as Texture2D, _grid_region(SEASONAL_ATLAS_PATH, 0, 0, 4, 1), Vector2(1.72, 0.43), Vector2(730, 252), "SeasonalAtmosphere", window_effects_layer)
	seasonal_sprite.z_index = -1
	seasonal_sprite.modulate = Color(1.0, 0.91, 0.82, 0.54)
	seasonal_sprites.append(seasonal_sprite)
	_add_furniture(Vector2(112, 480), _grid_region(FURNITURE_PATH, 0, 0, 4, 2), Vector2(0.78, 0.86), "Shelves")
	_add_furniture(Vector2(378, 470), _grid_region(FURNITURE_PATH, 1, 0, 4, 2), Vector2(0.78, 0.86), "Fridge")
	_add_furniture(Vector2(700, 536), _grid_region(FURNITURE_PATH, 3, 0, 4, 2), Vector2(0.77, 0.78), "Pastry case")
	var station_fixtures: Array[Dictionary] = [
		{"access_id":"coffee_machine", "station_id":"coffee", "name":"CoffeeBrewerStation", "cell":Vector2i(0, 0), "position":Vector2(520, 395)},
		{"access_id":"tea_counter", "station_id":"tea", "name":"TeaSteepingCounter", "cell":Vector2i(1, 0), "position":Vector2(640, 395)},
		{"access_id":"kettle", "station_id":"magical_kettle", "name":"MagicalKettleStation", "cell":Vector2i(1, 1), "position":Vector2(760, 395)},
		{"access_id":"microwave", "station_id":"microwave", "name":"MicrowaveStation", "cell":Vector2i(2, 0), "position":Vector2(880, 395)},
		{"access_id":"sandwich_station", "station_id":"sandwich", "name":"SandwichPreparationBoard", "cell":Vector2i(3, 0), "position":Vector2(1000, 395)},
		{"access_id":"bakery_warmer", "station_id":"bakery_warmer", "name":"BakeryWarmerStation", "cell":Vector2i(0, 1), "position":Vector2(1180, 395)}
	]
	var station_texture := load(PREP_STATIONS_PATH) as Texture2D
	for index in range(station_fixtures.size()):
		var fixture: Dictionary = station_fixtures[index]
		var cell: Vector2i = fixture.get("cell", Vector2i.ZERO)
		var fixture_position: Vector2 = fixture.get("position", Vector2.ZERO)
		var fixture_station_id := String(fixture.get("station_id", ""))
		var sprite := _atlas_sprite(station_texture, Rect2(cell.x * 320, cell.y * 320, 320, 320), Vector2(0.26, 0.26), fixture_position, String(fixture.get("name", "PreparationStation")), foreground_furniture_layer)
		sprite.z_index = 25 + int(fixture_position.y / 100.0)
		sprite.set_meta("station_id", fixture_station_id)
		sprite.set_meta("draw_layer", "furniture_foreground")
		craft_station_sprites[fixture_station_id] = sprite
	kettle_steam = _grid_sprite(KETTLE_STEAM_PATH, 0, 0, 4, 1, Vector2(0.25, 0.25), Vector2(810, 420), "KettleSteamVFX", prop_effects_layer)
	kettle_steam.z_index = 40
	kettle_steam.visible = false
	_add_furniture(Vector2(1025, 540), _grid_region(FURNITURE_PATH, 2, 0, 4, 2), Vector2(0.94, 0.91), "Checkout counter")
	# A separate approved counter accessory can be animated without altering the
	# painted checkout furniture atlas or baking movement into environment art.
	miso_knockable_vase = _atlas_sprite(
		load("res://assets/raster/furniture/moonmart_counter_accessories_atlas_1280.png") as Texture2D,
		_grid_region("res://assets/raster/furniture/moonmart_counter_accessories_atlas_1280.png", 1, 2, 4, 4),
		Vector2(0.39, 0.39), Vector2(1080, 482), "MisoKnockableFlowerBudVase", foreground_furniture_layer
	)
	miso_knockable_vase.z_index = 34
	miso_knockable_vase.set_meta("ambient_source_region", Vector2i(1, 2))
	var moonflower_texture := load(MOONFLOWER_PLANT_PATH) as Texture2D
	decorative_plant = _atlas_sprite(moonflower_texture, Rect2(Vector2.ZERO, Vector2(moonflower_texture.get_width(), moonflower_texture.get_height())), Vector2(0.18, 0.18), Vector2(1390, 566), "Potted moonflower", foreground_furniture_layer)
	decorative_plant.set_meta("draw_layer", "furniture_foreground")
	decorative_plant.z_index = 30
	_add_furniture(Vector2(844, 663), _grid_region(FURNITURE_PATH, 2, 1, 4, 2), Vector2(0.58, 0.62), "Reading chair")
	_add_furniture(Vector2(1450, 650), _grid_region(FURNITURE_PATH, 1, 1, 4, 2), Vector2(0.48, 0.54), "Moon lantern")
	_add_furniture(Vector2(190, 777), _grid_region(FURNITURE_PATH, 0, 1, 4, 2), Vector2(0.43, 0.46), "Flower pot")
	_add_furniture(Vector2(1460, 772), _grid_region(FURNITURE_PATH, 0, 1, 4, 2), Vector2(0.42, 0.44), "Flower pot")
	# Painted plaque and live text remain separate, so the lettering stays crisp and editable.
	var sign_texture := load(SHOP_SIGN_PATH) as Texture2D
	var sign := _atlas_sprite(sign_texture, Rect2(Vector2.ZERO, Vector2(sign_texture.get_width(), sign_texture.get_height())), Vector2(0.15, 0.15), Vector2(1260, 347), "MoonmartSign", architecture_layer)
	sign.z_index = 8
	var sign_text := _label("Moonmart  ☾", 26, Color("fff0d8"), Vector2(1120, 327), Vector2(280, 40))
	sign_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_text.z_index = 9
	architecture_layer.add_child(sign_text)
	back_door_sprite = _atlas_sprite(load(DOOR_ATLAS_PATH) as Texture2D, _grid_region(DOOR_ATLAS_PATH, 0, 0, 2, 1), Vector2(0.24, 0.24), Vector2(1515, 541), "BackRoomDoor", architecture_layer)
	back_door_sprite.z_index = 10
	player_body = CharacterBody2D.new()
	player_body.name = "ShopPlayerBody"
	player_body.position = player_position
	player_body.collision_layer = 2
	player_body.collision_mask = 1
	player_body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var player_collision := CollisionShape2D.new()
	player_collision.name = "PlayerCollisionShape"
	var player_capsule := CapsuleShape2D.new()
	player_capsule.radius = 11.0
	player_capsule.height = 30.0
	player_collision.shape = player_capsule
	player_collision.position = Vector2(0, 10)
	player_body.add_child(player_collision)
	characters_layer.add_child(player_body)
	player = _grid_sprite(PLAYER_PATH, 0, 0, 8, 4, Vector2(0.72, 0.72), Vector2.ZERO, "Player", player_body)
	player.z_index = 25
	pip = _grid_sprite(PIP_PATH, 0, 0, 4, 1, Vector2(0.30, 0.30), Vector2(536, 657), "Pip", characters_layer)
	pip.z_index = 26
	pip.visible = false
	# Pip's story glow is a separate accessibility-controlled light, never a glow atlas frame.
	pip_glow = PointLight2D.new()
	pip_glow.name = "PipStoryGlowLight"
	pip_glow.texture = _make_soft_light_texture()
	pip_glow.energy = 0.34
	pip_glow.color = Color(0.88, 0.76, 1.0)
	pip_glow.texture_scale = 0.38
	pip_glow.range_z_min = 26
	pip_glow.range_z_max = 26
	pip_glow.visible = false
	separate_lighting_layer.add_child(pip_glow)
	miso = _grid_sprite(MISO_PATH, 0, 0, 6, 1, Vector2(0.34, 0.34), Vector2(1278, 655), "Miso", characters_layer)
	miso.z_index = 29
	agnes_sprite = _grid_sprite(AGNES_PATH, 0, 0, 4, 1, Vector2(0.32, 0.32), Vector2(1120, 635), "Agnes", characters_layer)
	agnes_sprite.z_index = 20
	agnes_sprite.visible = false
	# Interactable signposts are deliberately invisible; the contextual prompt is the affordance.
	world.queue_redraw()

func _make_world_layer(layer_name: String, draw_order: int) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.z_as_relative = false
	layer.z_index = draw_order
	world.add_child(layer)
	return layer

func _add_architecture_modules(room_id: String) -> void:
	if architecture_layer == null:
		return
	var file := FileAccess.open(ARCHITECTURE_MODULES_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var catalog: Variant = JSON.parse_string(file.get_as_text())
	if not catalog is Dictionary:
		return
	var atlas_data: Dictionary = catalog.get("atlas", {})
	var atlas_path := String(atlas_data.get("path", ""))
	var columns := maxi(1, int(atlas_data.get("columns", 1)))
	var rows := maxi(1, int(atlas_data.get("rows", 1)))
	var texture := load(atlas_path) as Texture2D
	if texture == null:
		return
	var modules_by_id: Dictionary = {}
	for module in catalog.get("modules", []):
		if module is Dictionary and module.has("id"):
			modules_by_id[String(module.id)] = module
	var placements: Array = catalog.get("placements", {}).get(room_id, [])
	for placement in placements:
		if not placement is Dictionary:
			continue
		var module_id := String(placement.get("module_id", ""))
		var module: Dictionary = modules_by_id.get(module_id, {})
		var cell: Array = module.get("atlas_cell", [])
		var raw_position: Array = placement.get("position", [])
		var raw_scale: Array = placement.get("scale", [1.0, 1.0])
		if module.is_empty() or cell.size() < 2 or raw_position.size() < 2 or raw_scale.size() < 2:
			continue
		var sprite := _atlas_sprite(
			texture,
			_grid_region(atlas_path, int(cell[0]), int(cell[1]), columns, rows),
			Vector2(float(raw_scale[0]), float(raw_scale[1])),
			Vector2(float(raw_position[0]), float(raw_position[1])),
			"ArchitectureModule_" + module_id,
			architecture_layer
		)
		sprite.z_index = int(placement.get("z_index", 1))

func set_environment_layer_enabled(layer_name: String, enabled: bool) -> void:
	environment_layer_overrides[layer_name] = enabled
	var layers: Dictionary = {
		"night_sky": night_sky_layer,
		"exterior_parallax": exterior_parallax_layer,
		"window_effects": window_effects_layer,
		"lighting": separate_lighting_layer,
		"architecture": architecture_layer,
		"background_furniture": background_furniture_layer,
		"characters": characters_layer,
		"foreground_furniture": foreground_furniture_layer,
		"prop_effects": prop_effects_layer
	}
	if current_location_scene != null:
		layers["location_night_sky"] = current_location_scene.get_node_or_null("NightSkyLayer")
		layers["location_exterior_parallax"] = current_location_scene.get_node_or_null("ExteriorParallaxLayer")
		layers["location_lighting"] = current_location_scene.get_node_or_null("SeparateLightingLayer")
		layers["location_window_effects"] = current_location_scene.get_node_or_null("WindowEffectsLayer")
		layers["location_weather"] = current_location_scene.get_node_or_null("WeatherEffectsLayer")
		layers["location_story"] = current_location_scene.get_node_or_null("StoryEffectsLayer")
		layers["location_foreground_parallax"] = current_location_scene.get_node_or_null("ForegroundParallaxLayer")
		layers["location_foreground_effects"] = current_location_scene.get_node_or_null("ForegroundEffectsLayer")
		layers["location_prop_effects"] = current_location_scene.get_node_or_null("PropEffectsLayer")
	var layer: Variant = layers.get(layer_name)
	if layer is Node2D:
		_apply_environment_layer_visibility(layer_name, layer as Node2D)

func _ensure_location_effect_layers(location_scene: Node2D) -> void:
	var layer_specs := {
		"NightSkyLayer": -40,
		"ExteriorParallaxLayer": -30,
		"SeparateLightingLayer": -20,
		"WindowEffectsLayer": -10,
		"ArchitectureLayer": 0,
		"BackgroundFurnitureLayer": 5,
		"ForegroundParallaxLayer": 8,
		"DepthSortedCharactersLayer": 10,
		"RoomDecorationLayer": 10,
		"WeatherEffectsLayer": 2,
		"StoryEffectsLayer": 20,
		"ForegroundFurnitureLayer": 50,
		"PropEffectsLayer": 60,
		"ForegroundEffectsLayer": 65,
		"HUDDialogueLayer": 70
	}
	for layer_name in layer_specs:
		var layer := location_scene.get_node_or_null(String(layer_name)) as Node2D
		if layer == null:
			layer = Node2D.new()
			layer.name = String(layer_name)
			location_scene.add_child(layer)
		layer.z_as_relative = false
		layer.z_index = int(layer_specs[layer_name])
		if layer_name in ["NightSkyLayer", "ExteriorParallaxLayer"]:
			_apply_environment_layer_visibility(_location_layer_setting_name(String(layer_name)), layer)
		elif layer_name == "SeparateLightingLayer":
			_apply_environment_layer_visibility("location_lighting", layer)
		elif layer_name == "ForegroundParallaxLayer":
			_apply_environment_layer_visibility("location_foreground_parallax", layer)
		elif layer_name in ["WindowEffectsLayer", "WeatherEffectsLayer", "StoryEffectsLayer", "ForegroundEffectsLayer", "PropEffectsLayer"]:
			_apply_environment_layer_visibility(_location_layer_setting_name(String(layer_name)), layer)
		else:
			layer.visible = true
	var architecture := location_scene.get_node("ArchitectureLayer") as Node2D
	var background_furniture := location_scene.get_node("BackgroundFurnitureLayer") as Node2D
	var depth_characters := location_scene.get_node("DepthSortedCharactersLayer") as Node2D
	var backdrop := location_scene.get_node_or_null("Backdrop")
	if backdrop != null and backdrop.get_parent() == location_scene:
		backdrop.owner = null
		location_scene.remove_child(backdrop)
		architecture.add_child(backdrop)
	var npc_cast := location_scene.get_node_or_null("NPCs")
	if npc_cast != null and npc_cast.get_parent() == location_scene:
		npc_cast.owner = null
		location_scene.remove_child(npc_cast)
		depth_characters.add_child(npc_cast)
	for child in location_scene.get_children():
		if child is Sprite2D and child.get_parent() == location_scene:
			child.owner = null
			location_scene.remove_child(child)
			if child.name in ["UndatedTicket", "ImpossibleParcel", "KeeperLens", "MoonflowerKeepsake"]:
				depth_characters.add_child(child)
				child.z_index = 25 + int(child.position.y / 100.0)
			else:
				background_furniture.add_child(child)

func _outdoor_weather_positions(location_id: String) -> Array[Vector2]:
	# These coordinates stay in the visually open upper sky of each opaque plate.
	# Keep the effects compact; they cannot be occluded by painted foreground art.
	match location_id:
		"old_bellwether":
			return [Vector2(1475, 60), Vector2(1490, 60), Vector2(1505, 60), Vector2(1520, 60)]
		"whisperwood":
			return [Vector2(900, 220), Vector2(930, 220), Vector2(960, 220), Vector2(990, 220)]
		"moonwater_harbour":
			return [Vector2(700, 60), Vector2(800, 60), Vector2(900, 60), Vector2(1000, 60)]
		"old_lighthouse":
			return [Vector2(300, 60), Vector2(500, 60), Vector2(600, 60), Vector2(700, 60)]
		"midnight_platform":
			return [Vector2(1210, 60), Vector2(1240, 60), Vector2(1270, 60), Vector2(1300, 60)]
	return []

func _sync_location_weather_effects(weather_shift: int) -> void:
	if current_location_scene == null or current_location_id not in ["old_bellwether", "whisperwood", "moonwater_harbour", "old_lighthouse", "midnight_platform", "tea_corner"]:
		location_weather_sprites.clear()
		location_snow_sprites.clear()
		location_wind_sprites.clear()
		location_weather_scene_id = 0
		return
	var scene_id := current_location_scene.get_instance_id()
	if scene_id != location_weather_scene_id:
		location_weather_sprites.clear()
		location_snow_sprites.clear()
		location_wind_sprites.clear()
		location_weather_scene_id = scene_id
		var is_tea_corner := current_location_id == "tea_corner"
		var weather_layer_name := "WindowEffectsLayer" if is_tea_corner else "WeatherEffectsLayer"
		var weather_layer := current_location_scene.get_node_or_null(weather_layer_name) as Node2D
		if weather_layer != null:
			var outdoor_weather_positions := _outdoor_weather_positions(current_location_id)
			var texture := load(RAIN_ATLAS_PATH) as Texture2D
			if texture != null:
				var rain_positions: Array[Vector2] = []
				if is_tea_corner:
					for pane_center in [Vector2(822, 215), Vector2(931, 215), Vector2(1025, 215), Vector2(1117, 215), Vector2(822, 300), Vector2(931, 300), Vector2(1025, 300), Vector2(1115, 300), Vector2(822, 390), Vector2(931, 390), Vector2(1025, 390), Vector2(1115, 390)]:
						rain_positions.append(pane_center)
				else:
					rain_positions = outdoor_weather_positions.duplicate()
				for tile_index in range(rain_positions.size()):
					var sprite := _atlas_sprite(
						texture,
						_grid_region(RAIN_ATLAS_PATH, tile_index % 4, 0, 4, 1),
						Vector2(0.18, 0.18) if is_tea_corner else Vector2(0.15, 0.15),
						rain_positions[tile_index],
						("WindowRain_%02d" if is_tea_corner else "OutdoorRain_%02d") % tile_index,
						weather_layer
					)
					sprite.centered = true
					sprite.modulate = Color(0.82, 0.84, 0.98, 0.16)
					location_weather_sprites.append(sprite)
			var seasonal_texture := load(SEASONAL_ATLAS_PATH) as Texture2D
			if seasonal_texture != null:
				var snow_regions: Array[Rect2] = [
					Rect2(1945, 95, 135, 140),
					Rect2(1702, 250, 135, 135),
					Rect2(1944, 450, 135, 145)
				]
				var snow_positions: Array[Vector2] = [
					Vector2(150, 110), Vector2(385, 350), Vector2(650, 180), Vector2(900, 520),
					Vector2(1180, 260), Vector2(1420, 130), Vector2(540, 720), Vector2(1080, 780)
				]
				if is_tea_corner:
					snow_positions = [Vector2(822, 215), Vector2(931, 215), Vector2(1025, 215), Vector2(1117, 215), Vector2(822, 300), Vector2(931, 300), Vector2(1025, 300), Vector2(1115, 300)]
				else:
					snow_positions = outdoor_weather_positions.duplicate()
				for index in range(snow_positions.size()):
					var sprite := _atlas_sprite(
						seasonal_texture,
						snow_regions[index % snow_regions.size()],
						Vector2(0.40, 0.40),
						snow_positions[index],
						"OutdoorSnowflake_%02d" % index,
						weather_layer
					)
					sprite.modulate = Color(0.88, 0.90, 1.0, 0.62)
					sprite.set_meta("base_position", snow_positions[index])
					sprite.visible = false
					location_snow_sprites.append(sprite)
				var spring_petal_regions: Array[Rect2] = [
					Rect2(70, 70, 150, 125), Rect2(318, 205, 110, 82), Rect2(92, 325, 98, 68),
					Rect2(292, 440, 150, 98), Rect2(128, 568, 96, 75)
				]
				var summer_mote_regions: Array[Rect2] = [
					Rect2(926, 124, 26, 28), Rect2(674, 231, 25, 28), Rect2(832, 328, 28, 29),
					Rect2(930, 490, 31, 32), Rect2(665, 590, 30, 30)
				]
				var autumn_leaf_regions: Array[Rect2] = [
					Rect2(1130, 330, 185, 100), Rect2(1203, 555, 125, 115)
				]
				var winter_flake_regions: Array[Rect2] = [
					Rect2(1945, 95, 135, 140), Rect2(1702, 250, 135, 135),
					Rect2(1944, 450, 135, 145)
				]
				var seasonal_wind_regions: Dictionary = {
					"spring": spring_petal_regions,
					"summer": summer_mote_regions,
					"autumn": autumn_leaf_regions,
					"winter": winter_flake_regions
				}
				var seasonal_wind_positions: Dictionary = {
					"spring": outdoor_weather_positions.duplicate(),
					"summer": outdoor_weather_positions.duplicate(),
					"autumn": outdoor_weather_positions.duplicate(),
					"winter": outdoor_weather_positions.duplicate()
				}
				if is_tea_corner:
					var pane_centers: Array[Vector2] = [Vector2(822, 215), Vector2(931, 215), Vector2(1025, 215), Vector2(1117, 215), Vector2(822, 300), Vector2(931, 300), Vector2(1025, 300), Vector2(1115, 300), Vector2(822, 390), Vector2(931, 390), Vector2(1025, 390), Vector2(1115, 390)]
					for wind_season_variant in ["spring", "summer", "autumn", "winter"]:
						seasonal_wind_positions[wind_season_variant] = pane_centers.duplicate()
				else:
					# Opaque district plates have no foreground cutouts, so keep changing
					# weather in the reviewed open-sky pockets instead of washing across art.
					for wind_season_variant in ["spring", "summer", "autumn", "winter"]:
						seasonal_wind_positions[wind_season_variant] = outdoor_weather_positions.duplicate()
				for wind_season_variant in ["spring", "summer", "autumn", "winter"]:
					var regions: Array = seasonal_wind_regions[wind_season_variant]
					var positions: Array = seasonal_wind_positions[wind_season_variant]
					for index in range(positions.size()):
						var variant_scale := 0.40
						var variant_tint := Color(1.0, 0.92, 0.82, 0.76)
						match wind_season_variant:
							"spring":
								variant_scale = 0.40
								variant_tint = Color(1.0, 0.90, 0.94, 0.72)
							"summer":
								variant_scale = 0.90
								variant_tint = Color(1.0, 0.92, 0.72, 0.52)
							"winter":
								variant_scale = 0.30
								variant_tint = Color(0.88, 0.90, 1.0, 0.52)
						var sprite := _atlas_sprite(
							seasonal_texture,
							regions[index % regions.size()],
							Vector2(variant_scale, variant_scale),
							positions[index],
							"SeasonalWind_%s_%02d" % [wind_season_variant.capitalize(), index],
							weather_layer
						)
						sprite.modulate = variant_tint
						sprite.set_meta("wind_season", wind_season_variant)
						sprite.set_meta("base_position", positions[index])
						sprite.set_meta("base_rotation", 0.0)
						sprite.visible = false
						location_wind_sprites.append(sprite)
	var weather := game.calendar.weather_for_shift(weather_shift) if game != null else "clear"
	var raining := weather == "rain"
	var snowing := weather == "snow"
	var weather_date: Dictionary = game.calendar.date_for_shift(weather_shift) if game != null else {}
	var windy_season := String(weather_date.get("season_id", ""))
	var animation_frame := 0 if reduced_animation_enabled else int(Time.get_ticks_msec() / 250) % 4
	for index in range(location_weather_sprites.size()):
		var sprite := location_weather_sprites[index]
		if not is_instance_valid(sprite):
			continue
		sprite.visible = raining
		if raining:
			_set_grid_frame(sprite, RAIN_ATLAS_PATH, (animation_frame + index) % 4, 0, 4, 1)
	var elapsed_seconds := float(Time.get_ticks_msec()) / 1000.0
	for index in range(location_snow_sprites.size()):
		var sprite := location_snow_sprites[index]
		if not is_instance_valid(sprite):
			continue
		sprite.visible = snowing
		if snowing and not reduced_animation_enabled:
			var base_position: Vector2 = sprite.get_meta("base_position", sprite.position)
			var phase := float(index) * 0.83
			if current_location_id == "tea_corner":
				sprite.position = Vector2(base_position.x + sin(elapsed_seconds * 0.55 + phase) * 14.0, fposmod(base_position.y + elapsed_seconds * 34.0, 940.0) - 20.0)
			else:
				sprite.position = Vector2(base_position.x + sin(elapsed_seconds * 0.55 + phase) * 8.0, base_position.y + cos(elapsed_seconds * 0.68 + phase) * 6.0)
		else:
			sprite.position = sprite.get_meta("base_position", sprite.position)
			sprite.rotation = 0.0
	for index in range(location_wind_sprites.size()):
		var sprite := location_wind_sprites[index]
		if not is_instance_valid(sprite):
			continue
		var season_matches_wind := weather == "wind" and String(sprite.get_meta("wind_season", "")) == windy_season
		sprite.visible = season_matches_wind
		if season_matches_wind and not reduced_animation_enabled:
			var base_position: Vector2 = sprite.get_meta("base_position", sprite.position)
			var phase := float(index) * 0.91
			var drift_x := 42.0
			var drift_y := 14.0
			var turn_amount := 0.11
			match windy_season:
				"spring":
					drift_x = 34.0
					drift_y = 12.0
					turn_amount = 0.24
				"summer":
					drift_x = 15.0
					drift_y = 22.0
					turn_amount = 0.0
				"winter":
					drift_x = 28.0
					drift_y = 8.0
					turn_amount = 0.06
			sprite.position = Vector2(base_position.x + sin(elapsed_seconds * 0.52 + phase) * drift_x, base_position.y + cos(elapsed_seconds * 0.68 + phase) * drift_y)
			sprite.rotation = sin(elapsed_seconds * 0.62 + phase) * turn_amount
		else:
			sprite.position = sprite.get_meta("base_position", sprite.position)
			sprite.rotation = float(sprite.get_meta("base_rotation", 0.0))

func set_window_effect_enabled(effect_name: String, enabled: bool) -> void:
	environment_effect_overrides[effect_name] = enabled
	var effective_visibility := enabled and visual_effects_enabled
	match effect_name:
		"rain":
			rain_overlay.visible = effective_visibility
		"memory":
			window_echo.visible = effective_visibility
		"seasonal":
			for seasonal_sprite in seasonal_sprites:
				seasonal_sprite.visible = effective_visibility
		"steam":
			kettle_steam.visible = effective_visibility

func _add_furniture(at: Vector2, rect: Rect2, scale_value: Vector2, node_name: String) -> Sprite2D:
	var atlas_rect := rect
	var cell := atlas_rect.size
	var atlas_scale := scale_value * Vector2(256.0 / cell.x, 256.0 / cell.y)
	var layer_name := "furniture_background" if node_name in ["Shelves", "Fridge", "Pastry case"] else "furniture_foreground"
	var parent_layer := background_furniture_layer if layer_name == "furniture_background" else foreground_furniture_layer
	var sprite := _atlas_sprite(load(FURNITURE_PATH) as Texture2D, atlas_rect, atlas_scale, at, node_name, parent_layer)
	sprite.set_meta("draw_layer", layer_name)
	sprite.z_index = 6 if layer_name == "furniture_background" else 25 + int(at.y / 100.0)
	return sprite

func _grid_region(path: String, column: int, row: int, columns: int, rows: int) -> Rect2:
	var texture := load(path) as Texture2D
	var cell := Vector2(texture.get_width() / float(columns), texture.get_height() / float(rows))
	# Half-pixel inset protects adjacent atlas cells from linear-filter edge bleed.
	return Rect2(column * cell.x + 0.5, row * cell.y + 0.5, cell.x - 1.0, cell.y - 1.0)

func _grid_sprite(path: String, column: int, row: int, columns: int, rows: int, scale_value: Vector2, at: Vector2, node_name: String, parent_layer: Node2D = null) -> Sprite2D:
	var sprite := _atlas_sprite(load(path) as Texture2D, _grid_region(path, column, row, columns, rows), scale_value, at, node_name, parent_layer)
	sprite.set_meta("atlas_columns", columns)
	sprite.set_meta("atlas_rows", rows)
	return sprite

func _make_soft_light_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
	gradient.colors = PackedColorArray([Color(0.75, 0.69, 1.0, 0.42), Color(0.62, 0.58, 1.0, 0.16), Color(0.5, 0.48, 0.9, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture

func _atlas_sprite(texture: Texture2D, region: Rect2, scale_value: Vector2, at: Vector2, node_name: String, parent_layer: Node2D = null) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = at
	sprite.scale = scale_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	(parent_layer if parent_layer != null else world).add_child(sprite)
	return sprite

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUDDialogueLayer"
	add_child(hud_layer)
	var top := _panel(Vector2(26, 24), Vector2(464, 108), Color(0.15, 0.14, 0.25, 0.91), Color("c18b86"), 2)
	top.name = "HudShopPanel"
	hud_layer.add_child(top)
	title_label = _label("MOONMART  ☾", 27, Color("fff0d8"), Vector2(48, 31), Vector2(270, 37))
	hud_layer.add_child(title_label)
	status_label = _label("Night 1 · Monday", 17, Color("e6c4d1"), Vector2(50, 73), Vector2(420, 28))
	hud_layer.add_child(status_label)
	miso_reaction_panel = _panel(Vector2(26, 140), Vector2(464, 62), Color(0.15, 0.14, 0.25, 0.94), Color("c18b86"), 2)
	miso_reaction_panel.name = "HudMisoReactionPanel"
	miso_reaction_panel.visible = false
	hud_layer.add_child(miso_reaction_panel)
	miso_reaction_label = _label("", 16, Color("fff0d8"), Vector2(42, 148), Vector2(432, 46))
	miso_reaction_label.name = "HudMisoReaction"
	miso_reaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	miso_reaction_label.add_theme_color_override("font_shadow_color", Color("29243b"))
	miso_reaction_label.add_theme_constant_override("shadow_offset_x", 1)
	miso_reaction_label.add_theme_constant_override("shadow_offset_y", 1)
	miso_reaction_label.visible = false
	hud_layer.add_child(miso_reaction_label)
	clock_label = _label("☾  11:30 PM", 21, Color("fff0d8"), Vector2(325, 31), Vector2(148, 37))
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(clock_label)
	_add_hud_icon(0, 0, Vector2(294, 35), Vector2(28, 28))
	var money := _panel(Vector2(1225, 28), Vector2(345, 62), Color(0.15, 0.14, 0.25, 0.91), Color("c18b86"), 2)
	money.name = "HudMoneyPanel"
	hud_layer.add_child(money)
	_add_hud_icon(1, 0, Vector2(1260, 39), Vector2(38, 38))
	coin_label = _label("12", 20, Color("fff0d8"), Vector2(1300, 44), Vector2(70, 34))
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_layer.add_child(coin_label)
	_add_hud_icon(2, 0, Vector2(1402, 39), Vector2(38, 38))
	moon_token_label = _label("0", 20, Color("fff0d8"), Vector2(1444, 44), Vector2(70, 34))
	moon_token_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_layer.add_child(moon_token_label)
	controls_hint_label = _label("", 16, Color("f9e7d1"), Vector2(70, 837), Vector2(1460, 48))
	controls_hint_label.name = "HudControlsHint"
	controls_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint_label.add_theme_color_override("font_shadow_color", Color("29243b"))
	controls_hint_label.add_theme_constant_override("shadow_offset_x", 1)
	controls_hint_label.add_theme_constant_override("shadow_offset_y", 1)
	hud_layer.add_child(controls_hint_label)
	prompt_label = _label("", 19, Color("fff0d8"), Vector2(630, 789), Vector2(340, 46))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var prompt_art := TextureRect.new()
	prompt_art.texture = load(PROMPT_BUBBLE_PATH) as Texture2D
	prompt_art.position = Vector2(610, 782)
	prompt_art.size = Vector2(380, 60)
	prompt_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prompt_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prompt_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(prompt_art)
	prompt_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hud_layer.add_child(prompt_label)
	message_panel = _panel(Vector2(300, 625), Vector2(1000, 200), Color(0.16, 0.14, 0.25, 0.97), Color("e3b28f"), 3)
	message_panel.name = "HudMessagePanel"
	message_panel.add_theme_stylebox_override("panel", _style(Color(0.16, 0.14, 0.25, 0.97), Color("e3b28f"), 3, 16))
	hud_layer.add_child(message_panel)
	message_label = _label("", 20, Color("fff0d8"), Vector2(326, 650), Vector2(948, 112))
	message_label.name = "HudMessageLabel"
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_layer.add_child(message_label)
	message_hint_label = _label("Continue", 15, Color("e9bd99"), Vector2(1090, 780), Vector2(190, 24))
	message_hint_label.name = "HudMessageHint"
	message_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(message_hint_label)
	message_panel.visible = false
	message_label.visible = false
	message_hint_label.visible = false
	side_panel = _panel(Vector2(1060, 120), Vector2(500, 650), Color(0.13, 0.12, 0.22, 0.97), Color("c18b86"), 2)
	side_panel.add_theme_stylebox_override("panel", _raster_panel_style())
	hud_layer.add_child(side_panel)
	side_scroll = ScrollContainer.new()
	side_scroll.name = "SidePanelScroll"
	side_scroll.position = Vector2(1130, 190)
	side_scroll.size = Vector2(350, 490)
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	side_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_layer.add_child(side_scroll)
	side_label = _label("", 19, Color("fff0d8"), Vector2.ZERO, Vector2(330, 490))
	side_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_label.custom_minimum_size = Vector2(330, 0)
	side_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.add_child(side_label)
	side_panel_icon = TextureRect.new()
	side_panel_icon.name = "SidePanelContextIcon"
	side_panel_icon.position = Vector2(1524, 122)
	side_panel_icon.size = Vector2(28, 28)
	side_panel_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	side_panel_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	side_panel_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_panel_icon.visible = false
	hud_layer.add_child(side_panel_icon)
	puzzle_answer_input = LineEdit.new()
	puzzle_answer_input.name = "EnvironmentalPuzzleAnswer"
	puzzle_answer_input.add_theme_font_override("font", MOONMART_FONT)
	puzzle_answer_input.position = Vector2(1090, 690)
	puzzle_answer_input.size = Vector2(440, 42)
	puzzle_answer_input.placeholder_text = "Write what the clues suggest…"
	puzzle_answer_input.add_theme_stylebox_override("normal", _style(Color("211d32"), Color("d5a980"), 2, 8))
	puzzle_answer_input.add_theme_stylebox_override("focus", _style(Color("211d32"), Color("fff0d8"), 2, 8))
	puzzle_answer_input.add_theme_color_override("font_color", Color("fff0d8"))
	puzzle_answer_input.add_theme_color_override("font_placeholder_color", Color("c8b3c4"))
	puzzle_answer_input.add_theme_font_size_override("font_size", 18)
	puzzle_answer_input.visible = false
	hud_layer.add_child(puzzle_answer_input)
	selected_product_icon = TextureRect.new()
	selected_product_icon.name = "SelectedProductIcon"
	selected_product_icon.position = Vector2(1450, 657)
	selected_product_icon.size = Vector2(80, 80)
	selected_product_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selected_product_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	selected_product_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_product_icon.visible = false
	hud_layer.add_child(selected_product_icon)
	side_panel.visible = false
	side_label.visible = false
	var resume_button := _pause_button(_localize_ui("pause.button.resume", "Return to Moonmart"), Vector2(1125, 365))
	resume_button.pressed.connect(_resume_from_pause)
	var save_button := _pause_button(_localize_ui("pause.button.save_continue", "Save and continue"), Vector2(1125, 425))
	save_button.pressed.connect(_save_resume_from_pause)
	var close_button := _pause_button(_localize_ui("pause.button.close_shift", "Close this shift"), Vector2(1125, 485))
	close_button.pressed.connect(_close_shift_from_pause)
	var save_quit_button := _pause_button(_localize_ui("pause.button.save_quit", "Save and quit"), Vector2(1125, 545))
	save_quit_button.pressed.connect(_save_quit_from_pause)
	var settings_button := _pause_button(_localize_ui("pause.button.settings", "Settings and accessibility"), Vector2(1125, 595))
	settings_button.pressed.connect(_open_settings_from_pause)
	speed_label = _label("Shift pace · ×1.0", 16, Color("e6c4d1"), Vector2(1125, 656), Vector2(360, 28))
	hud_layer.add_child(speed_label)
	speed_slider = HSlider.new()
	speed_slider.position = Vector2(1125, 686)
	speed_slider.size = Vector2(360, 34)
	speed_slider.min_value = 0.25
	speed_slider.max_value = 3.0
	speed_slider.step = 0.05
	speed_slider.value = 1.0
	speed_slider.value_changed.connect(_on_speed_changed)
	speed_slider.visible = false
	speed_label.visible = false
	hud_layer.add_child(speed_slider)

func _miso_animation_frame(shift_status_value: String, is_moving: bool, play_hold: float, purr_hold: float, reduced_animation: bool, ticks_msec: int) -> int:
	if is_moving:
		return 2
	if shift_status_value != "open":
		return 0
	if play_hold > 0.0:
		return 4
	if purr_hold > 0.0:
		return 5
	if not reduced_animation and posmod(int(ticks_msec / 4000), 6) == 5:
		return 3
	return 1

func _update_agnes_animation(visual: Sprite2D, state: String, reduced_animation: bool) -> void:
	if state == "CONVERSING" and not reduced_animation:
		_set_single_sprite_frame(visual, AGNES_TALK_POSE_PATH)
		return
	var agnes_frame := 0
	if not reduced_animation:
		match state:
			"ARRIVING":
				var arrival_route: Array = customer_routes.get("agnes", [])
				agnes_frame = 2 if int(customer_route_indices.get("agnes", 0)) < arrival_route.size() else 1
			"QUEUING", "CHECKOUT":
				agnes_frame = 3
			"LEAVING":
				agnes_frame = 2
	_set_grid_frame(visual, AGNES_PATH, agnes_frame, 0, 4, 1)

func _update_location_npc_animation(visual: Sprite2D, npc_id: String, is_talking: bool, ticks_msec: int) -> void:
	if not is_talking:
		var idle_art := String(NAMED_CHARACTER_SHEETS.get(npc_id, GENERIC_CUSTOMER_PATH))
		_set_grid_frame(visual, idle_art, 0, 0, 4, 1)
		return
	if npc_id == "agnes":
		_update_agnes_animation(visual, "CONVERSING", reduced_animation_enabled)
		return
	if npc_id == "wren" and not reduced_animation_enabled and posmod(int(ticks_msec / 1400), 4) == 2:
		_set_single_sprite_frame(visual, WREN_CAST_POSE_PATH)
		return
	var talk_art := String(NAMED_CHARACTER_SHEETS.get(npc_id, GENERIC_CUSTOMER_PATH))
	var talk_frame := int(CORE_SHOPPER_TALK_FRAMES.get(npc_id, 3))
	_set_grid_frame(visual, talk_art, talk_frame % 4, 0, 4, 1)

func _pip_blink_frame(ticks_msec: int) -> int:
	return 1 if posmod(ticks_msec, 3600) < 140 else 0

func _visitor_browse_frame(visitor_id: String, ticks_msec: int, reduced_animation: bool) -> int:
	if visitor_id == "wren":
		return 2 if not reduced_animation and posmod(int(ticks_msec / 1400), 4) == 2 else 0
	if CORE_SHOPPER_BROWSE_FRAMES.has(visitor_id):
		return int(CORE_SHOPPER_BROWSE_FRAMES[visitor_id])
	if not NAMED_CHARACTER_SHEETS.has(visitor_id):
		return 2
	return 0

func _process(delta: float) -> void:
	if side_label != null and side_scroll != null and side_label.text != last_side_panel_text:
		last_side_panel_text = side_label.text
		side_scroll.scroll_vertical = 0
	_refresh_side_panel_icon()
	_update_location_score_transition(delta)
	_update_location_ambience_transition(delta)
	_sync_weather_audio()
	_sync_narrative_music(delta)
	footstep_cooldown = maxf(0.0, footstep_cooldown - delta)
	miso_purr_hold_time = maxf(0.0, miso_purr_hold_time - delta)
	miso_play_hold_time = maxf(0.0, miso_play_hold_time - delta)
	if miso_reaction_time_remaining > 0.0 and not message_open:
		miso_reaction_time_remaining = maxf(0.0, miso_reaction_time_remaining - delta)
		if miso_reaction_time_remaining <= 0.0:
			miso_reaction_panel.visible = false
			miso_reaction_label.visible = false
	_sync_miso_purr()
	_sync_hidden_paw_marker()
	var is_walking := not message_open and active_panel.is_empty() and player_body != null and player_body.velocity.length() > 1.0
	if is_walking and footstep_cooldown <= 0.0 and sfx_manager != null:
		sfx_manager.play_sfx("footstep")
		footstep_cooldown = 0.52
	if player_action_time_remaining > 0.0:
		player_action_time_remaining = maxf(0.0, player_action_time_remaining - delta)
		if player_action_time_remaining <= 0.0:
			player_action_frame = -1
	if Input.is_action_pressed("move_up"):
		player_facing_row = 3
	elif Input.is_action_pressed("move_down"):
		player_facing_row = 2
	elif Input.is_action_pressed("move_left"):
		player_facing_row = 0
	elif Input.is_action_pressed("move_right"):
		player_facing_row = 1
	animation_clock += delta
	if animation_clock > (0.72 if reduced_animation_enabled else 0.22):
		animation_clock = 0.0
		var player_is_moving := Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")
		if player_is_moving:
			player_frame = 3 if game.inventory.is_carrying_stock() else (1 if player_frame != 1 else 2)
		elif message_open:
			player_frame = 5
		elif player_action_time_remaining > 0.0 and player_action_frame >= 0:
			player_frame = player_action_frame
		elif game.inventory.is_carrying_stock():
			player_frame = 3
		elif active_panel == "checkout":
			player_frame = 6
		elif active_panel == "craft" or not _craft_station_for_access_id(nearby_id).is_empty():
			player_frame = 7
		elif not active_panel.is_empty():
			player_frame = 4
		else:
			player_frame = 0
		if message_open:
			player.scale = Vector2(0.30, 0.30)
			_set_single_sprite_frame(player, PLAYER_TALK_POSE_PATH)
		else:
			player.scale = Vector2(0.72, 0.72)
			_set_grid_frame(player, PLAYER_PATH, player_frame, player_facing_row, 8, 4)
		player.flip_h = face_direction < 0.0 and player_facing_row in [2, 3]
		var miso_is_moving := miso.position.distance_to(miso_previous_position) > 0.6
		var miso_frame := _miso_animation_frame(shift_status, miso_is_moving, miso_play_hold_time, miso_purr_hold_time, reduced_animation_enabled, Time.get_ticks_msec())
		_set_grid_frame(miso, MISO_PATH, miso_frame, 0, 6, 1)
		var rain_frame := 0 if reduced_animation_enabled else int(Time.get_ticks_msec() / 250) % 4
		var echo_frame := 0 if reduced_animation_enabled else int(Time.get_ticks_msec() / 520) % 4
		var steam_frame := 0 if reduced_animation_enabled else int(Time.get_ticks_msec() / 380) % 4
		_set_grid_frame(rain_overlay, RAIN_ATLAS_PATH, rain_frame, 0, 4, 1)
		_set_grid_frame(window_echo, MEMORY_ECHO_ATLAS_PATH, echo_frame, 0, 4, 1)
		_set_grid_frame(kettle_steam, KETTLE_STEAM_PATH, steam_frame, 0, 4, 1)
		for visitor_id in customer_visuals:
			var visual: Sprite2D = customer_visuals[visitor_id]
			var state := String(customer_states.get(visitor_id, "ARRIVING"))
			if visitor_id == "pip":
				var pip_frame := 0
				if not reduced_animation_enabled:
					pip_frame = 2 if state in ["CONVERSING", "LINGERING"] else _pip_blink_frame(Time.get_ticks_msec())
				if game != null and game.story.flags.get("pip_reflection", false):
					pip_frame = 3
				_set_grid_frame(visual, PIP_PATH, pip_frame, 0, 4, 1)
			elif visitor_id == "agnes":
				_update_agnes_animation(visual, state, reduced_animation_enabled)
			else:
				var visitor_id_string := String(visitor_id)
				var visitor_frame := 0
				if state in ["CONVERSING", "CHECKOUT"] and NAMED_CHARACTER_SHEETS.has(visitor_id_string):
					visitor_frame = int(CORE_SHOPPER_TALK_FRAMES.get(visitor_id_string, 3))
				elif state in ["ARRIVING", "LEAVING"]:
					if not reduced_animation_enabled and NAMED_CHARACTER_SHEETS.has(visitor_id_string) and not CORE_SHOPPER_WALK_IDS.has(visitor_id_string):
						# Recent townsperson sheets have two documented walk cells.
						visitor_frame = int(Time.get_ticks_msec() / 450) % 2 + 1
					else:
						# Core role atlases and the generic atlas have one clean walk cell.
						visitor_frame = 1
				elif state == "BROWSING":
					visitor_frame = _visitor_browse_frame(visitor_id_string, Time.get_ticks_msec(), reduced_animation_enabled)
				var art_path := String(NAMED_CHARACTER_SHEETS.get(visitor_id_string, GENERIC_CUSTOMER_PATH))
				if not reduced_animation_enabled and visitor_id == "lucien" and state == "LINGERING":
					_set_single_sprite_frame(visual, LUCIEN_DRINK_POSE_PATH)
				elif not reduced_animation_enabled and visitor_id == "wren" and state == "CONVERSING" and posmod(int(Time.get_ticks_msec() / 1400), 4) == 2:
					_set_single_sprite_frame(visual, WREN_CAST_POSE_PATH)
				elif not NAMED_CHARACTER_SHEETS.has(String(visitor_id)) and state == "CHECKOUT":
					var purchase_frame := 3 if reduced_animation_enabled else posmod(int(Time.get_ticks_msec() / 260), 4)
					_set_grid_frame(visual, GENERIC_CUSTOMER_PURCHASE_PATH, purchase_frame, 0, 4, 1)
				elif not reduced_animation_enabled and state == "QUEUING" and not NAMED_CHARACTER_SHEETS.has(String(visitor_id)):
					_set_single_sprite_frame(visual, GENERIC_CUSTOMER_QUEUE_POSE_PATH)
				else:
					_set_grid_frame(visual, art_path, visitor_frame % 4, 0, 4, 1)
		var glow_pulse := 0.0 if reduced_flashing_enabled else 0.06 * sin(Time.get_ticks_msec() / 1800.0)
		var keeper_light := 0.12 if game != null and game.world_map.ending_id == "keeper" else 0.0
		moon_glow.energy = 0.25 + glow_pulse + (0.12 if game != null and game.shop_progression.has_upgrade("enchanted_lighting") else 0.0) + keeper_light
		if pip_glow != null:
			var pip_story_glow: bool = game != null and bool(game.story.flags.get("pip_reflection", false)) and pip.visible
			pip_glow.visible = pip_story_glow and visual_effects_enabled and dynamic_lighting_enabled and not reduced_flashing_enabled
			pip_glow.position = separate_lighting_layer.to_local(pip.global_position) if pip != null else Vector2.ZERO
	if game != null:
		_process_miso_ambient(delta)
		miso_previous_position = miso.position
		for visitor_id in customer_targets:
			if not customer_visuals.has(visitor_id) or visitor_id == "pip":
				continue
			var visitor_visual: Sprite2D = customer_visuals[visitor_id]
			var target_position: Vector2 = customer_targets[visitor_id]
			_advance_customer_route(visitor_id, visitor_visual, target_position, delta)
			visitor_visual.z_index = 25 + int(visitor_visual.position.y / 100.0)
		if active_panel == "decorate":
			_refresh_decoration_transient_access()
		kettle_steam.visible = visual_effects_enabled and active_panel == "craft" and active_craft_station_id == "magical_kettle" and current_location_id == "moonmart" and bool(environment_effect_overrides.get("steam", true))
		var weather_shift := maxi(game.shift_number, 1) if game.shift_status == "open" else maxi(game.shift_number + 1, 1)
		_sync_location_weather_effects(weather_shift)
		rain_overlay.visible = visual_effects_enabled and current_location_id == "moonmart" and game.calendar.weather_for_shift(weather_shift) == "rain" and bool(environment_effect_overrides.get("rain", true))
		var ending_id: String = String(game.world_map.ending_id)
		var ending_memory: bool = ending_id in ["open_door", "gentle_goodbye"]
		window_echo.visible = visual_effects_enabled and current_location_id == "moonmart" and (ending_memory or game.story.flags.get("pip_reflection", false) or game.story.flags.get("shop_photograph_changes_at_midnight", false)) and bool(environment_effect_overrides.get("memory", true))
		window_echo.modulate = Color("ddc8f2", 0.15) if ending_id == "open_door" else (Color("d9c8e5", 0.11) if ending_id == "gentle_goodbye" else Color(0.88, 0.74, 0.93, 0.18))
		var season_id := String(game.calendar.date_for_shift(weather_shift).get("season_id", "spring"))
		if season_id != active_season_visual:
			var season_column := int({"spring":0, "summer":1, "autumn":2, "winter":3}.get(season_id, 0))
			for seasonal_sprite in seasonal_sprites:
				_set_grid_frame(seasonal_sprite, SEASONAL_ATLAS_PATH, season_column, 0, 4, 1)
			active_season_visual = season_id
		for seasonal_sprite in seasonal_sprites:
			seasonal_sprite.visible = visual_effects_enabled and current_location_id == "moonmart" and bool(environment_effect_overrides.get("seasonal", true))
		if current_location_scene != null:
			var npc_root := current_location_scene.get_node_or_null("NPCs")
			if npc_root != null:
				for npc in npc_root.get_children():
					if npc is Sprite2D:
						var npc_id := String(npc.name).to_lower()
						var npc_is_talking := message_open and npc_id == active_location_talker_id
						_update_location_npc_animation(npc, npc_id, npc_is_talking, Time.get_ticks_msec())
						npc.z_index = 25 + int(npc.position.y / 100.0)
	decorative_plant.rotation = 0.0 if reduced_animation_enabled else 0.012 * sin(Time.get_ticks_msec() / 1700.0)
	if pip.visible:
		pip.position.y = pip_anchor.y if reduced_animation_enabled else pip_anchor.y + 5.0 * sin(Time.get_ticks_msec() / 520.0)
	_update_prompt()

func _physics_process(_delta: float) -> void:
	_update_player()

func _trigger_player_action(frame: int) -> void:
	player_action_frame = frame
	player_action_time_remaining = 0.48 if not reduced_animation_enabled else 0.90
	if player == null or message_open:
		return
	player.scale = Vector2(0.72, 0.72)
	_set_grid_frame(player, PLAYER_PATH, frame, player_facing_row, 8, 4)
	player.flip_h = face_direction < 0.0 and player_facing_row in [2, 3]
	_sync_camera_and_parallax()

func _sync_camera_and_parallax() -> void:
	if room_camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var background_size := Vector2(1600, 900)
	var backdrop: Sprite2D
	var parallax_layer := exterior_parallax_layer
	var foreground_parallax_layer: Node2D
	if current_location_scene != null:
		backdrop = current_location_scene.get_node_or_null("ArchitectureLayer/Backdrop") as Sprite2D
		if backdrop == null:
			backdrop = current_location_scene.get_node_or_null("Backdrop") as Sprite2D
		parallax_layer = current_location_scene.get_node_or_null("ExteriorParallaxLayer") as Node2D
		if current_location_id == "midnight_platform":
			foreground_parallax_layer = current_location_scene.get_node_or_null("ForegroundParallaxLayer") as Node2D
	if backdrop != null and backdrop.texture != null:
		background_size = backdrop.texture.get_size() * backdrop.global_scale
	var cover_zoom := maxf(viewport_size.x / maxf(background_size.x, 1.0), viewport_size.y / maxf(background_size.y, 1.0))
	room_camera.zoom = Vector2.ONE * maxf(cover_zoom, 0.01)
	var visible_world_size := viewport_size / room_camera.zoom.x
	var half_view := visible_world_size * 0.5
	var horizontal_overflow := maxf(0.0, viewport_size.x - background_size.x)
	var vertical_overflow := maxf(0.0, viewport_size.y - background_size.y)
	room_camera.limit_left = 0
	room_camera.limit_top = 0
	room_camera.limit_right = maxi(ceili(background_size.x), ceili(viewport_size.x))
	room_camera.limit_bottom = maxi(ceili(background_size.y), ceili(viewport_size.y))
	var camera_x := background_size.x * 0.5 if half_view.x > background_size.x * 0.5 else clampf(player_position.x, half_view.x, background_size.x - half_view.x)
	var camera_y := background_size.y * 0.5 if half_view.y > background_size.y * 0.5 else clampf(player_position.y, half_view.y, background_size.y - half_view.y)
	room_camera.position = Vector2(camera_x, camera_y)
	if parallax_layer != null:
		parallax_layer.position.x = (camera_x - background_size.x * 0.5) * 0.35
	if foreground_parallax_layer != null:
		# Counter-drift the foreground prop so it crosses the view slightly faster than the plate.
		foreground_parallax_layer.position.x = (camera_x - background_size.x * 0.5) * -0.18

func _update_player() -> void:
	if message_open or not active_panel.is_empty():
		return
	var velocity := Vector2.ZERO
	velocity.x = Input.get_axis("move_left", "move_right")
	velocity.y = Input.get_axis("move_up", "move_down")
	if velocity.length() > 1.0:
		velocity = velocity.normalized()
	var speed := 230.0 if not Input.is_action_pressed("run") else 340.0
	player_body.collision_mask = 1 if current_location_scene == null or current_location_id in ["shop_backroom", "reading_nook", "enchanted_greenhouse"] else 0
	player_body.velocity = velocity * speed
	player_body.move_and_slide()
	player_position = _clamp_player_position(player_body.position, current_location_id)
	player_body.position = player_position
	game.remember_player_position(current_location_id, player_position)
	_sync_camera_and_parallax()
	if velocity.x != 0:
		face_direction = signf(velocity.x)
	player.position = Vector2.ZERO
	player.flip_h = face_direction < 0.0 and player_facing_row in [2, 3]
	player.z_index = 25 + int(player_position.y / 100)

func _rebuild_shop_collision_bodies(_layout: Dictionary = {}) -> void:
	if shop_collision_root == null or game == null or game.decoration == null:
		return
	var collision_parent: Node2D = shop_collision_root
	if current_location_id in ["shop_backroom", "reading_nook", "enchanted_greenhouse"] and current_location_scene != null:
		var room_collision := current_location_scene.get_node_or_null("RoomDecorationCollisionLayer") as Node2D
		if room_collision != null:
			collision_parent = room_collision
	for child in collision_parent.get_children():
		child.free()
	var grid_size: Vector2i = game.decoration.grid_size
	var cell_size := Vector2(1600.0 / float(grid_size.x), 400.0 / float(grid_size.y))
	for cell in game.decoration.collision_grid():
		var fixture := StaticBody2D.new()
		fixture.name = "FixtureCell_%d_%d" % [cell.x, cell.y]
		fixture.position = _shop_cell_center(cell)
		fixture.collision_layer = 1
		fixture.collision_mask = 0
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = cell_size
		shape_node.shape = shape
		fixture.add_child(shape_node)
		collision_parent.add_child(fixture)

func _shop_cell_for_point(point: Vector2) -> Vector2i:
	var grid_size: Vector2i = game.decoration.grid_size
	var cell_width := 1600.0 / float(grid_size.x)
	var cell_height := 400.0 / float(grid_size.y)
	return Vector2i(clampi(floori(point.x / cell_width), 0, grid_size.x - 1), clampi(floori((point.y - 400.0) / cell_height), 0, grid_size.y - 1))

func _shop_cell_center(cell: Vector2i) -> Vector2:
	var grid_size: Vector2i = game.decoration.grid_size
	var cell_width := 1600.0 / float(grid_size.x)
	var cell_height := 400.0 / float(grid_size.y)
	return Vector2((float(cell.x) + 0.5) * cell_width, 400.0 + (float(cell.y) + 0.5) * cell_height)

func _shop_point_is_walkable(point: Vector2) -> bool:
	return game.decoration.cell_is_walkable(_shop_cell_for_point(point))

func _make_shop_route(start_position: Vector2, target_position: Vector2) -> Array[Vector2]:
	var route: Array[Vector2] = []
	var start_cell := _shop_cell_for_point(start_position)
	var target_cell := _shop_cell_for_point(target_position)
	var cell_route := game.decoration.find_path(start_cell, target_cell)
	if cell_route.is_empty():
		var closest_route: Array[Vector2i] = []
		var closest_distance := 2147483647
		for y in range(game.decoration.grid_size.y):
			for x in range(game.decoration.grid_size.x):
				var candidate := Vector2i(x, y)
				var distance := absi(candidate.x - target_cell.x) + absi(candidate.y - target_cell.y)
				if distance >= closest_distance or not game.decoration.cell_is_walkable(candidate):
					continue
				var candidate_route := game.decoration.find_path(start_cell, candidate)
				if not candidate_route.is_empty():
					closest_route = candidate_route
					closest_distance = distance
		cell_route = closest_route
	if cell_route.is_empty():
		return route
	for index in range(1, cell_route.size()):
		route.append(_shop_cell_center(cell_route[index]))
	if cell_route.back() == target_cell:
		route.append(target_position)
	else:
		route.append(_shop_cell_center(cell_route.back()))
	return route

func _advance_customer_route(customer_id: String, visual: Sprite2D, _target_position: Vector2, delta: float) -> void:
	var route: Array = customer_routes.get(customer_id, [])
	if route.is_empty():
		return
	var index := int(customer_route_indices.get(customer_id, 0))
	while index < route.size() and visual.position.distance_to(route[index]) <= 4.0:
		index += 1
	customer_route_indices[customer_id] = index
	if index < route.size():
		visual.position = visual.position.move_toward(route[index], 110.0 * delta)

func _set_grid_frame(sprite: Sprite2D, path: String, column: int, row: int, columns: int, rows: int) -> void:
	if sprite == null:
		return
	sprite.texture = load(path) as Texture2D
	sprite.region_enabled = true
	sprite.region_rect = _grid_region(path, column, row, columns, rows)

func _set_single_sprite_frame(sprite: Sprite2D, path: String) -> void:
	if sprite == null:
		return
	sprite.texture = load(path) as Texture2D
	sprite.region_enabled = false

func _update_prompt() -> void:
	nearby_id = ""
	var best_distance := 88.0
	var best_facing_match := false
	var best_priority := -1
	var target_candidates: Array[Dictionary] = []
	var points := _interaction_positions()
	for target_id_value in points.keys():
		var target_id := String(target_id_value)
		if not _interaction_target_is_available(target_id):
			continue
		var target_position: Vector2 = points[target_id_value]
		var distance := player_position.distance_to(target_position)
		if distance > 88.0:
			continue
		var facing_match := _interaction_target_matches_facing(target_position - player_position)
		var priority := _interaction_target_priority(target_id)
		best_distance = minf(best_distance, distance)
		target_candidates.append({"id":target_id, "distance":distance, "facing_match":facing_match, "priority":priority})
	for candidate in target_candidates:
		if float(candidate.distance) > best_distance + 0.01:
			continue
		var candidate_id := String(candidate.id)
		var facing_match := bool(candidate.facing_match)
		var priority := int(candidate.priority)
		var preferred := nearby_id.is_empty() or (facing_match and not best_facing_match)
		if not nearby_id.is_empty() and facing_match == best_facing_match:
			preferred = priority > best_priority or (priority == best_priority and candidate_id < nearby_id)
		if preferred:
			best_facing_match = facing_match
			best_priority = priority
			nearby_id = candidate_id
	if message_open or not active_panel.is_empty():
		prompt_label.visible = false
	else:
		prompt_label.visible = not nearby_id.is_empty()
		if nearby_id.begins_with("decoration:"):
			prompt_label.text = _format_localized_ui("prompt.decoration.hidden_message", "{interact}  Read the flower's hidden note", {"interact":_binding_label("interact")})
		elif current_location_scene != null:
			if nearby_id in ["ReturnToMoonmart", "ShopDoor", "BetweenDoorway"]:
				prompt_label.text = _format_localized_ui("prompt.return_to_moonmart", "{interact}  Return to Moonmart", {"interact":_binding_label("interact")})
			elif current_location_id == "midnight_platform" and nearby_id == "WaitingBench":
				prompt_label.text = _format_localized_ui("prompt.waiting_bench", "{interact}  Rest a moment   ·   {inspect}  Inspect", {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
			elif current_location_id == "midnight_platform" and nearby_id == "TicketWindow":
				prompt_label.text = _format_localized_ui("prompt.platform_ticket_window", "{interact}  Read the ticket window   ·   {inspect}  Inspect", {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
			elif current_location_id == "reading_nook" and nearby_id in ["ReadingChair", "ReadingShelves", "ReadingShelvesRight", "BotanicalStand"]:
				var reading_prompt_key := "prompt.reading_nook_chair.message" if nearby_id == "ReadingChair" else "prompt.reading_nook_shelves.message"
				prompt_label.text = _format_localized_ui(reading_prompt_key, "{interact}  Read   ·   {inspect}  Rest / inspect", {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
			elif current_location_id == "enchanted_greenhouse" and nearby_id in ["PropagationShelf", "SeedlingShelf", "WateringStation"]:
				prompt_label.text = _format_localized_ui("prompt.greenhouse_plants.message", "{interact}  Water plants   ·   {inspect}  Inspect", {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
			elif current_location_id == "enchanted_greenhouse" and nearby_id == "MoonflowerTrellis":
				prompt_label.text = _format_localized_ui("prompt.greenhouse_trellis.message", "{interact}  Read the plant tag   ·   {inspect}  Inspect", {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
			elif nearby_id in ["TownNoticeboard", "WashedGlass", "NetMender", "EmptyBoat"]:
				var outdoor_prompts := {
					"TownNoticeboard":["prompt.town_noticeboard", "Read town map"],
					"WashedGlass":["prompt.washed_glass", "Examine sea glass"],
					"NetMender":["prompt.net_mender", "Examine harbour net"],
					"EmptyBoat":["prompt.empty_boat", "Examine empty boat"]
				}
				var outdoor_prompt: Array = outdoor_prompts.get(nearby_id, ["prompt.inspect", "Inspect"])
				prompt_label.text = _format_localized_ui(String(outdoor_prompt[0]), "{interact}  %s   ·   {inspect}  Inspect" % String(outdoor_prompt[1]), {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
			elif current_location_id == "shop_backroom":
				var backroom_prompts := {
					"SupplyShelves":["prompt.backroom.supply_shelves", "Move stock to displays"],
					"DeliveryCrates":["prompt.backroom.delivery_crates", "Order deliveries to storage"],
					"HandTrolley":["prompt.backroom.hand_trolley", "Replenish a display"]
				}
				var backroom_prompt: Array = backroom_prompts.get(nearby_id, ["prompt.location.interact", "Talk / interact"])
				prompt_label.text = _format_localized_ui(String(backroom_prompt[0]), "{interact}  %s   ·   {inspect}  Inspect" % String(backroom_prompt[1]), {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
			else:
				prompt_label.text = _format_localized_ui("prompt.location.interact", "{interact}  Talk / interact   ·   {inspect}  Inspect", {"interact":_binding_label("interact"), "inspect":_binding_label("inspect")})
		elif nearby_id.begins_with("customer:"):
			var visitor_id := nearby_id.trim_prefix("customer:")
			var visitor: Dictionary = game.customers.get_customer(visitor_id)
			var browsing: Dictionary = visitor.get("browsing_choice", {})
			var browse_product := String(browsing.get("product_id", ""))
			var product_name := _localized_product_name(browse_product, "the shelves")
			if visitor.get("state", "") in ["BROWSING", "LINGERING"]:
				prompt_label.text = _format_localized_ui("prompt.customer.browse", "{interact}  Talk with {name} · looking for {product}", {"interact":_binding_label("interact"), "name":String(visitor.get("name", "your visitor")), "product":product_name})
			else:
				prompt_label.text = _format_localized_ui("prompt.customer.greet", "{interact}  Say hello to {name}", {"interact":_binding_label("interact"), "name":String(visitor.get("name", "your visitor"))})
		elif not _craft_station_for_access_id(nearby_id).is_empty():
			var station_id := _craft_station_for_access_id(nearby_id)
			var station_name := _localize_ui(String(CRAFT_STATION_UI_IDS.get(station_id, "craft.station.default")), String(CRAFT_STATION_NAMES.get(station_id, "PREPARATION STATION"))).to_lower()
			prompt_label.text = _format_localized_ui("prompt.craft_station", "{interact}  Prepare at {station}", {"interact":_binding_label("interact"), "station":station_name})
		else:
			prompt_label.text = game.get_prompt(nearby_id) if not nearby_id.is_empty() else ""
		var guidance: Dictionary = game.miso_hidden_paw_guidance if game != null else {}
		if prompt_label.visible and not guidance.is_empty() and String(guidance.get("location_id", "")) == current_location_id and String(guidance.get("marker_id", "")) == nearby_id:
			prompt_label.text = _format_localized_ui("companion.response.ability.hidden_paw.inspect_here", "↓ Miso is waiting here · {inspect} Inspect", {"inspect":_binding_label("inspect")})

func _interaction_target_is_available(target_id: String) -> bool:
	if target_id.begins_with("customer:"):
		if game == null:
			return false
		var customer: Dictionary = game.customers.get_customer(target_id.trim_prefix("customer:"))
		return not customer.is_empty() and String(customer.get("state", "")) not in ["LEAVING", "DESPAWNED"]
	if target_id.begins_with("decoration:"):
		if game == null:
			return false
		return not game.decoration.effect_for_instance(target_id.trim_prefix("decoration:"), "moon_jasmine_message").is_empty()
	return true

func _interaction_target_matches_facing(target_delta: Vector2) -> bool:
	if target_delta.length() <= 0.01:
		return true
	var facing_vector := Vector2.ZERO
	match player_facing_row:
		0: facing_vector = Vector2.LEFT
		1: facing_vector = Vector2.RIGHT
		2: facing_vector = Vector2(face_direction, 1.0)
		3: facing_vector = Vector2(face_direction, -1.0)
	return target_delta.normalized().dot(facing_vector.normalized()) > 0.0

func _interaction_target_priority(target_id: String) -> int:
	if INTERACTION_PRIORITY_BY_ID.has(target_id):
		return int(INTERACTION_PRIORITY_BY_ID[target_id])
	if target_id.begins_with("customer:"):
		return 15
	if target_id.begins_with("decoration:"):
		return 5
	return 10

func _configure_miso_ambient(seed_override: int = -1, initial_wait_override: float = -1.0) -> void:
	if game == null:
		return
	var timing: Dictionary = game.miso_companion.ambient_behavior_timing
	var seed_value := int(timing.get("seed", 74219)) if seed_override < 0 else seed_override
	var initial_min := float(timing.get("initial_wait_min", 8.0))
	var initial_max := float(timing.get("initial_wait_max", 14.0))
	if initial_wait_override >= 0.0:
		initial_min = initial_wait_override
		initial_max = initial_wait_override
	miso_ambient_manager.setup(
		game.miso_companion.ambient_behaviors,
		seed_value,
		initial_min,
		initial_max,
		float(timing.get("interval_min", 10.0)),
		float(timing.get("interval_max", 18.0))
	)

func _process_miso_ambient(delta: float) -> void:
	if game == null or miso == null or current_location_scene != null or current_location_id != "moonmart":
		_interrupt_miso_vase_knock_if_active()
		return
	var unblocked: bool = active_panel.is_empty() and not message_open and not game.clock.paused
	var should_run_ambient: bool = unblocked and game.shift_status == "open" and game.clock.running and game.clock.is_open() and not reduced_animation_enabled and not game.save_recovery_required
	if not should_run_ambient:
		_interrupt_miso_vase_knock_if_active()
		# Between shifts, Miso returns to the selected bed after all player UI closes.
		if unblocked and game.shift_status != "open" and not reduced_animation_enabled:
			_move_miso_to_preferred_sleep_spot(delta)
		return
	_advance_miso_ambient_route(delta)
	var has_customer := false
	for customer in game.customers.active:
		if String(customer.get("state", "")) != "LEAVING":
			has_customer = true
			break
	if String(miso_ambient_manager.current_behavior().get("id", "")) == "knock_flower_vase" and not miso_ambient_manager.waiting_for_arrival():
		_advance_miso_vase_knock(delta)
	var result: Dictionary = miso_ambient_manager.tick(delta, true, has_customer, game.miso_companion.preferred_sleep_spot, miso_ambient_route.is_empty(), _available_miso_ambient_prop_ids())
	if String(result.get("state", "")) == "started":
		_set_miso_ambient_target(result.get("behavior", {}))
	elif String(result.get("state", "")) == "arrived" and String(result.get("behavior", {}).get("id", "")) == "knock_flower_vase":
		_begin_miso_vase_knock()
	elif String(result.get("state", "")) == "finished" and String(result.get("behavior_id", "")) == "knock_flower_vase":
		_restore_miso_knockable_vase()

func _available_miso_ambient_prop_ids() -> Array[String]:
	var available: Array[String] = []
	if current_location_id == "moonmart" and current_location_scene == null and is_instance_valid(miso_knockable_vase) and miso_knockable_vase.visible:
		available.append("flower_bud_vase")
	return available

func _begin_miso_vase_knock() -> void:
	if not is_instance_valid(miso_knockable_vase):
		miso_ambient_manager.cancel_current(false)
		return
	miso_vase_base_transform = miso_knockable_vase.transform
	miso_vase_knock_elapsed = 0.0
	miso_vase_knock_active = true

func _advance_miso_vase_knock(delta: float) -> void:
	if not miso_vase_knock_active or not is_instance_valid(miso_knockable_vase):
		return
	miso_vase_knock_elapsed += maxf(0.0, delta)
	var tip_angle := deg_to_rad(68.0)
	if miso_vase_knock_elapsed < 0.24:
		miso_knockable_vase.rotation = miso_vase_base_transform.get_rotation() + tip_angle * (miso_vase_knock_elapsed / 0.24)
	elif miso_vase_knock_elapsed < 1.05:
		miso_knockable_vase.rotation = miso_vase_base_transform.get_rotation() + tip_angle
	else:
		var recovery := clampf((miso_vase_knock_elapsed - 1.05) / 0.55, 0.0, 1.0)
		miso_knockable_vase.rotation = miso_vase_base_transform.get_rotation() + tip_angle * (1.0 - recovery)
	if miso_vase_knock_elapsed >= 1.6:
		_restore_miso_knockable_vase()

func _restore_miso_knockable_vase() -> void:
	if is_instance_valid(miso_knockable_vase) and miso_vase_knock_active:
		miso_knockable_vase.transform = miso_vase_base_transform
	miso_vase_knock_active = false
	miso_vase_knock_elapsed = 0.0

func _interrupt_miso_vase_knock_if_active() -> void:
	var behavior: Dictionary = miso_ambient_manager.current_behavior()
	if String(behavior.get("id", "")) != "knock_flower_vase":
		return
	_restore_miso_knockable_vase()
	miso_ambient_manager.cancel_current(false)
	miso_ambient_route.clear()
	miso_ambient_route_index = 0

func _set_miso_ambient_target(behavior_value: Variant) -> bool:
	if game == null or miso == null or not behavior_value is Dictionary:
		return false
	var behavior: Dictionary = behavior_value
	var anchor_id := String(behavior.get("anchor", ""))
	var anchor_value: Variant = game.miso_companion.ambient_anchors.get(anchor_id, null)
	if not anchor_value is Array or anchor_value.size() < 2:
		miso_ambient_manager.cancel_current(false)
		return false
	miso_ambient_target = Vector2(float(anchor_value[0]), float(anchor_value[1]))
	miso_ambient_route = _make_shop_route(miso.global_position, miso_ambient_target)
	miso_ambient_route_index = 0
	if miso_ambient_route.is_empty():
		if miso.global_position.distance_to(miso_ambient_target) <= 4.0:
			return true
		miso_ambient_manager.cancel_current(false)
		return false
	miso_ambient_target = miso_ambient_route.back()
	return true

func _advance_miso_ambient_route(delta: float) -> void:
	if miso == null or miso_ambient_route.is_empty():
		return
	while miso_ambient_route_index < miso_ambient_route.size():
		var waypoint: Vector2 = miso_ambient_route[miso_ambient_route_index]
		if miso.global_position.distance_to(waypoint) <= 4.0:
			miso_ambient_route_index += 1
			continue
		var previous_position := miso.global_position
		var timing: Dictionary = game.miso_companion.ambient_behavior_timing
		var speed := maxf(12.0, float(timing.get("walk_speed", 48.0)))
		miso.global_position = miso.global_position.move_toward(waypoint, speed * delta)
		if absf(miso.global_position.x - previous_position.x) > 0.1:
			miso.flip_h = miso.global_position.x < previous_position.x
		miso.z_index = 25 + int(miso.position.y / 100.0)
		return
	miso_ambient_route.clear()
	miso_ambient_route_index = 0

func _move_miso_to_preferred_sleep_spot(delta: float) -> void:
	var spot_id: String = game.miso_companion.preferred_sleep_spot
	var anchor_value: Variant = game.miso_companion.ambient_anchors.get(spot_id, null)
	if not anchor_value is Array or anchor_value.size() < 2:
		return
	var target := Vector2(float(anchor_value[0]), float(anchor_value[1]))
	var route := _make_shop_route(miso.global_position, target)
	if route.is_empty():
		return
	var waypoint: Vector2 = route[0]
	miso.global_position = miso.global_position.move_toward(waypoint, 42.0 * delta)

func _interaction_positions() -> Dictionary:
	if current_location_scene == null:
		var points: Dictionary = INTERACTION_POINTS.duplicate(true)
		if game != null:
			points["miso"] = miso.global_position if miso != null else Vector2(1278, 655)
			for customer in game.customers.active:
				var visitor_id := String(customer.get("id", ""))
				if customer_visuals.has(visitor_id) and String(customer.get("state", "")) != "LEAVING":
					points["customer:" + visitor_id] = (customer_visuals[visitor_id] as Sprite2D).position
		_add_decoration_interactions(points)
		return points
	var points: Dictionary = {}
	var marker_root := current_location_scene.get_node_or_null("InteractionPoints")
	if marker_root == null:
		if current_location_id in ["shop_backroom", "reading_nook", "enchanted_greenhouse"]:
			_add_decoration_interactions(points)
		return points
	for marker in marker_root.get_children():
		if marker is Marker2D:
			points[String(marker.name)] = marker.global_position
	if current_location_id in ["shop_backroom", "reading_nook", "enchanted_greenhouse"]:
		_add_decoration_interactions(points)
	return points

func _add_decoration_interactions(points: Dictionary) -> void:
	if game == null:
		return
	for instance_id in game.decoration.placed:
		var decoration_id := String(instance_id)
		if game.decoration.effect_for_instance(decoration_id, "moon_jasmine_message").is_empty():
			continue
		var entry: Dictionary = game.decoration.placed[decoration_id]
		var furniture_id := String(entry.get("furniture_id", ""))
		var origin: Vector2i = entry.get("origin", Vector2i.ZERO)
		var rotated := bool(entry.get("rotated", false))
		var cell_size := Vector2(1600.0 / game.decoration.grid_size.x, 400.0 / game.decoration.grid_size.y)
		var offset := game.decoration.visual_offset_in_cells(decoration_id) * cell_size
		points["decoration:" + decoration_id] = _decoration_center(origin, furniture_id, rotated) + _decoration_anchor_offset(furniture_id, rotated) + offset

func _hidden_paw_reachable_inspect_targets() -> Dictionary:
	var targets: Dictionary = {}
	for marker_id_value in _interaction_positions().keys():
		var marker_id := String(marker_id_value)
		var target_id := ""
		if marker_id.begins_with("customer:"):
			target_id = marker_id.trim_prefix("customer:")
		elif current_location_scene != null:
			target_id = _location_target_id(marker_id)
		else:
			target_id = marker_id
		if not target_id.is_empty():
			targets[target_id] = marker_id
	return targets

func _sync_hidden_paw_marker() -> void:
	if hidden_paw_marker == null:
		hidden_paw_marker = Label.new()
		hidden_paw_marker.name = "HiddenPawGuideMarker"
		hidden_paw_marker.text = "↓"
		hidden_paw_marker.size = Vector2(40, 34)
		hidden_paw_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hidden_paw_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hidden_paw_marker.add_theme_font_size_override("font_size", 26)
		hidden_paw_marker.add_theme_color_override("font_color", Color("fff0b5"))
		hidden_paw_marker.add_theme_color_override("font_outline_color", Color("34273b"))
		hidden_paw_marker.add_theme_constant_override("outline_size", 4)
		hidden_paw_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hidden_paw_marker.z_index = 100
		add_child(hidden_paw_marker)
	var guidance: Dictionary = game.miso_hidden_paw_guidance if game != null else {}
	if guidance.is_empty() or String(guidance.get("location_id", "")) != current_location_id:
		hidden_paw_marker.visible = false
		return
	var marker_id := String(guidance.get("marker_id", ""))
	var points := _interaction_positions()
	if marker_id.is_empty() or not points.has(marker_id):
		hidden_paw_marker.visible = false
		return
	hidden_paw_marker.global_position = Vector2(points[marker_id]) + Vector2(-20, -38)
	hidden_paw_marker.visible = true

func _craft_station_for_access_id(access_id: String) -> String:
	return String(CRAFT_STATION_ACCESS_IDS.get(access_id, ""))

func _apply_ending_world_state(ending_id: String) -> void:
	if ending_id == "gentle_goodbye":
		_set_grid_frame(back_door_sprite, DOOR_ATLAS_PATH, 1, 0, 2, 1)
		if current_location_id != "moonmart":
			_travel_to_location("moonmart", false)
	elif ending_id in ["keeper", "open_door"]:
		_set_grid_frame(back_door_sprite, DOOR_ATLAS_PATH, 0, 0, 2, 1)

## Awards the authored keepsake for a room object the first time it is used, then
## appends the find to whatever message that interaction produced.
func _announce_location_keepsake(found_text: String) -> void:
	game._set_message(game.last_message + "

" + found_text)

func _interact_location(_secondary: bool) -> void:
	var keepsake: Dictionary = game.discover_collectible(current_location_id, nearby_id.to_snake_case())
	if not keepsake.is_empty():
		var keepsake_name: String = _localize_ui("collectible.%s.name" % String(keepsake.get("id", "")), String(keepsake.get("name", "a small keepsake")))
		var found_text: String = _localize_ui("collectible.found", "You found {name}.").format({"name":keepsake_name})
		call_deferred("_announce_location_keepsake", found_text)
		game._emit_journal()
	if nearby_id in ["ReturnToMoonmart", "ShopDoor"] or (current_location_id == "hidden_midnight_room" and nearby_id == "BetweenDoorway"):
		_travel_to_location("moonmart")
		return
	if current_location_id == "tea_corner" and nearby_id == "TeaShelves" and not _secondary:
		_open_stock_panel("tea_corner_shelf")
		return
	if current_location_id == "tea_corner" and nearby_id == "MoonflowerSeat" and not _secondary:
		game._set_message(_localize_ui("prompt.moonflower_seat.message", "The moonflower seat is here whenever you want to rest. Nothing advances while you sit, and you can leave whenever you like."))
		return
	if current_location_id == "reading_nook" and not _secondary:
		if nearby_id == "ReadingChair":
			game._set_message(_localize_ui("interaction.reading_nook.read", "You settle in with a book. The quiet makes room for the next thought."))
			return
		if nearby_id in ["ReadingShelves", "ReadingShelvesRight", "BotanicalStand"]:
			game._set_message(_localize_ui("interaction.reading_nook.read", "The shelves hold local histories, field notes, and stories visitors have left for one another."))
			return
	if current_location_id == "reading_nook" and _secondary and nearby_id in ["ReadingChair", "ReadingShelves", "ReadingShelvesRight", "BotanicalStand"]:
		var reading_key := "interaction.reading_nook.rest" if nearby_id == "ReadingChair" else "interaction.reading_nook.read"
		game._set_message(_localize_ui(reading_key, "You rest quietly among the books. There is no hurry to leave."))
		return
	if current_location_id == "enchanted_greenhouse" and not _secondary:
		if nearby_id == "MoonflowerTrellis":
			game._set_message(_localize_ui("interaction.greenhouse.trellis", "A moonflower vine climbs the trellis. Anouk's tag notes that its leaves close gently before dawn."))
			return
		if nearby_id in ["PropagationShelf", "SeedlingShelf", "WateringStation"]:
			var watering := game.clean_shop("water_plants")
			var result_key := "interaction.greenhouse.plants.water" if bool(watering.get("ok", false)) else "interaction.greenhouse.plants.already_watered"
			var fallback := "You water the moon herbs and seedlings. The greenhouse can be tended once each shift." if bool(watering.get("ok", false)) else "The moon herbs and seedlings have already been watered this shift."
			game._set_message(_localize_ui(result_key, fallback))
			return
	if current_location_id == "enchanted_greenhouse" and _secondary and nearby_id == "MoonflowerTrellis":
		game._set_message(_localize_ui("interaction.greenhouse.trellis", "The moonflower vine leans toward the glass. Anouk's handwritten tag reads: closes gently before dawn."))
		return
	if current_location_id == "enchanted_greenhouse" and _secondary and nearby_id in ["PropagationShelf", "SeedlingShelf", "WateringStation"]:
		var plant_key := "interaction.greenhouse.plants.inspect"
		var plant_fallback := "Moonflower leaves gather pale light along their veins; careful watering keeps them healthy for the shop's recipes." if nearby_id == "SeedlingShelf" else "The propagation trays hold small magical herbs and cuttings, each tagged for later study."
		game._set_message(_localize_ui(plant_key, plant_fallback))
		return
	if current_location_id == "shop_backroom" and not _secondary:
		match nearby_id:
			"SupplyShelves":
				_open_stock_panel("backroom_storage")
				return
			"DeliveryCrates":
				_open_stock_panel("backroom_delivery")
				return
			"HandTrolley":
				_open_stock_panel("backroom_trolley")
				return
	var talk_targets := {"BakeryFront":"agnes", "BookshopFront":"lucien", "PostOffice":"mara", "FernSpot":"fern", "HarbourOffice":"wren", "ConductorSpot":"conductor", "KeeperDoor":"elias", "LostAndFound":"osric"}
	var target_id := String(talk_targets.get(nearby_id, _location_target_id(nearby_id)) if not _secondary else _location_target_id(nearby_id))
	var talker_id := String(talk_targets.get(nearby_id, "")) if not _secondary else ""
	if _secondary:
		var puzzle: Dictionary = game.environmental_puzzle_for_target(target_id)
		if not puzzle.is_empty():
			game.inspect_object(target_id)
			_open_environmental_puzzle(puzzle)
			return
	game.interact(target_id, _secondary)
	active_location_talker_id = talker_id if message_open else ""

func _location_target_id(marker_id: String) -> String:
	var targets := {
		"BakeryFront": "agnes", "BookshopFront": "lucien_book", "PostOffice": "post_office",
		"TownNoticeboard": "town_map", "WashedGlass": "washed_glass", "NetMender": "net_mender", "EmptyBoat": "empty_boat",
		"OldShrine": "old_grove", "FernSpot": "fern", "MoonflowerPatch": "moonflower_patch",
		"WhisperingTree": "bird_nests", "ImpossibleParcel": "tide_pool", "HarbourOffice": "wren",
		"NightBoat": "ticket_window", "KeeperDoor": "keeper_log", "LensRoom": "fresnel_lens", "LampRoom": "lamp_room",
		"SeawardCliff": "coast_view", "PlatformClock": "platform_clock", "LostAndFound": "passenger_manifest",
		"WaitingBench": "waiting_bench", "TicketWindow": "ticket_window", "TrainDoor": "platform", "ConductorSpot": "conductor", "MemoryWall": "photograph",
		"OldPhotograph": "photograph",
		"OriginalAgreement": "shop_ledger", "BetweenDoorway": "platform", "MisoRestingPlace": "miso",
		"SupplyShelves": "shelf", "DeliveryCrates": "shelf", "HandTrolley": "shelf"
	}
	return String(targets.get(marker_id, marker_id.to_snake_case()))

func _travel_to_location(location_id: String, persist: bool = true) -> void:
	if location_id != "moonmart" and not game.world_map.is_unlocked(location_id):
		return
	if persist and not game.travel_to(location_id):
		return
	if location_id == current_location_id:
		return
	_interrupt_miso_vase_knock_if_active()
	game.remember_player_position(current_location_id, player_position)
	if current_location_scene == null:
		shop_return_position = player_position
		characters_layer.remove_child(player_body)
		world.visible = false
	else:
		var old_player_parent := player_body.get_parent()
		if old_player_parent != null:
			old_player_parent.remove_child(player_body)
		current_location_scene.queue_free()
		current_location_scene = null
	if location_id == "moonmart":
		world.visible = true
		characters_layer.add_child(player_body)
		var doorway_frame := 0 if bool(game.world_map.world_state().get("door_open", true)) else 1
		_set_grid_frame(back_door_sprite, DOOR_ATLAS_PATH, doorway_frame, 0, 2, 1)
		player_position = shop_return_position
		player_body.position = player_position
		player_body.collision_mask = 1
	else:
		world.visible = false
		if location_id == "shop_backroom":
			_set_grid_frame(back_door_sprite, DOOR_ATLAS_PATH, 1, 0, 2, 1)
		var paths := {
			"tea_corner": "res://scenes/locations/tea_corner.tscn",
			"reading_nook": "res://scenes/locations/reading_nook.tscn",
			"enchanted_greenhouse": "res://scenes/locations/enchanted_greenhouse.tscn",
			"old_bellwether": "res://scenes/locations/old_bellwether.tscn",
			"whisperwood": "res://scenes/locations/whisperwood.tscn",
			"moonwater_harbour": "res://scenes/locations/moonwater_harbour.tscn",
			"old_lighthouse": "res://scenes/locations/old_lighthouse.tscn",
			"midnight_platform": "res://scenes/locations/midnight_platform.tscn",
			"shop_backroom": "res://scenes/locations/shop_backroom.tscn",
			"hidden_midnight_room": "res://scenes/locations/hidden_midnight_room.tscn"
		}
		var scene_path := String(paths.get(location_id, ""))
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			characters_layer.add_child(player_body)
			player_body.collision_mask = 1
			world.visible = true
			return
		current_location_scene = load(scene_path).instantiate() as Node2D
		_ensure_location_effect_layers(current_location_scene)
		add_child(current_location_scene)
		var character_layer := current_location_scene.get_node_or_null("DepthSortedCharactersLayer") as Node2D
		(character_layer if character_layer != null else current_location_scene).add_child(player_body)
		player_position = Vector2(120, 785)
		player_body.position = player_position
		player_body.collision_mask = 1 if location_id in ["shop_backroom", "reading_nook", "enchanted_greenhouse"] else 0
	current_location_id = location_id
	var fallback_position := shop_return_position if location_id == "moonmart" else Vector2(120, 785)
	_restore_player_position(location_id, fallback_position)
	game.remember_player_position(current_location_id, player_position)
	_update_location_hud_caption()
	_sync_ambience_for_location()
	_refresh_decoration_transient_access()
	game.decoration.set_room(current_location_id)
	_configure_decoration_room_access()
	_sync_decoration_visuals()
	player.z_index = 40
	_sync_camera_and_parallax()
	if persist:
		game.save_now()

func _restore_player_position(location_id: String, fallback_position: Vector2) -> void:
	var position := fallback_position
	if game.has_saved_player_position(location_id):
		position = game.saved_player_position(location_id)
	player_position = _clamp_player_position(position, location_id)
	if player_body != null:
		player_body.position = player_position
	if location_id == "moonmart":
		shop_return_position = player_position

func _clamp_player_position(position: Vector2, location_id: String) -> Vector2:
	var is_shop := location_id == "moonmart"
	return Vector2(
		clampf(position.x, 42.0, 1550.0),
		clampf(position.y, 646.0 if is_shop else 400.0, 802.0 if is_shop else 820.0)
	)

func _input(event: InputEvent) -> void:
	if settings_panel != null and settings_panel.is_open():
		return
	if active_panel == "environmental_puzzle" and event.is_action_pressed("puzzle_submit"):
		get_viewport().set_input_as_handled()
		call_deferred("_submit_environmental_answer", puzzle_answer_input.text)

func _unhandled_input(event: InputEvent) -> void:
	if settings_panel != null and settings_panel.is_open():
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_back"):
			settings_panel.close()
			get_viewport().set_input_as_handled()
		return
	if active_panel == "decorate":
		_handle_decoration_input(event)
		return
	if side_panel != null and side_panel.visible and active_panel not in ["stock", "craft", "map"] and (event.is_action_pressed("page_next") or event.is_action_pressed("page_previous")):
		var scroll_delta := 420 if event.is_action_pressed("page_next") else -420
		side_scroll.scroll_vertical = clampi(side_scroll.scroll_vertical + scroll_delta, 0, int(side_scroll.get_v_scroll_bar().max_value))
		get_viewport().set_input_as_handled()
		return
	if active_panel == "housekeeping":
		var clean_slot := _number_slot(event)
		if clean_slot >= 0 and clean_slot < CLEANING_ACTION_IDS.size():
			var action_id := CLEANING_ACTION_IDS[clean_slot]
			var clean_result: Dictionary = game.clean_shop(action_id)
			var clean_message := _localize_ui("housekeeping.result.already_done", "Already done this night. The shop can rest too.")
			if bool(clean_result.get("ok", false)):
				_trigger_player_action(4)
				var action_messages := {
					"wipe_counter":["housekeeping.result.wipe_counter", "The counter is clear and smooth under the lamp."],
					"sweep_floor":["housekeeping.result.sweep_floor", "Leaves and tracked-in dust are swept away."],
					"water_plants":["housekeeping.result.water_plants", "The shop plants settle after a gentle drink."],
					"clear_cups":["housekeeping.result.clear_cups", "Clean cups are ready for the next late-night tea."],
					"take_out_rubbish":["housekeeping.result.take_out_rubbish", "The rubbish is outside, and the back room can breathe."],
					"refill_dispenser":["housekeeping.result.refill_dispenser", "The canisters are full and ready for another quiet night."]
				}
				var action_message: Array = action_messages.get(action_id, ["housekeeping.result.done", "The shop feels a little brighter."])
				clean_message = _localize_ui(String(action_message[0]), String(action_message[1]))
			_refresh_housekeeping_panel(clean_message)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("housekeeping") or event.is_action_pressed("ui_back"):
			_close_side_panel()
			get_viewport().set_input_as_handled()
			return
	if active_panel == "dream":
		var dream_slot := _number_slot(event)
		var dream_beat: Dictionary = game.miso_dream_sequence.current_beat()
		var dream_choices: Array = dream_beat.get("choices", [])
		if dream_slot >= 0 and dream_slot < dream_choices.size():
			var dream_choice: Dictionary = dream_choices[dream_slot]
			var dream_result: Dictionary = game.choose_miso_dream_choice(String(dream_choice.get("id", "")))
			var dream_response := _localize_ui(String(dream_result.get("response_id", "")), "Miso's dream shifts softly around you.")
			_refresh_dream_panel(dream_response)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("interact") and game.miso_dream_sequence.ready_to_wake:
			var wake_result: Dictionary = game.wake_from_miso_dream()
			if bool(wake_result.get("ok", false)):
				_close_side_panel()
				_on_message_changed(_localize_ui("companion.dream.wake_message", "Miso wakes with a quiet purr. The dream stays with you as a small, optional memory."))
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_back") or event.is_action_pressed("pause") or event.is_action_pressed("companion"):
			_close_side_panel()
			get_viewport().set_input_as_handled()
			return
	if active_panel == "companion":
		var companion_slot := _number_slot(event)
		if companion_slot >= 0 and companion_slot < 4:
			var care_action: String = ["feed", "pet", "brush", "play"][companion_slot]
			var care_result: Dictionary = game.companion_action(care_action, String(game.miso_companion.favorite_toy))
			var care_message := _localize_ui("companion.result.already_done", "Miso has already had a little attention of that kind tonight.")
			if care_result.get("ok", false):
				miso_purr_hold_time = 4.0
				miso_play_hold_time = 4.0 if care_action == "play" else 0.0
				_sync_miso_purr()
				var care_response_id := "companion.response.%s" % care_action
				if care_action == "play":
					care_response_id += ".favorite"
				care_message = _localize_ui(care_response_id, String(care_result.get("message", "Miso is content.")))
			_refresh_companion_panel(care_message)
			get_viewport().set_input_as_handled()
			return
		if companion_slot >= 4 and companion_slot < 9:
			var abilities := ["spirit_sense", "hidden_paw", "dreamwalking", "memory_echo", "guardian_purr"]
			var ability_id: String = abilities[companion_slot - 4]
			if ability_id == "dreamwalking":
				var dream_result := game.start_miso_dreamwalking()
				if bool(dream_result.get("ok", false)):
					_open_dream_panel()
				else:
					_refresh_companion_panel(_localize_ui("companion.result.ability_locked", "Miso hasn't discovered that ability yet."))
				get_viewport().set_input_as_handled()
				return
			var reachable_targets: Dictionary = _hidden_paw_reachable_inspect_targets() if ability_id == "hidden_paw" else {}
			var ability_result: Dictionary = game.use_miso_ability(ability_id, reachable_targets)
			var ability_message := _localize_ui("companion.result.ability_locked", "Miso hasn't discovered that ability yet.")
			if ability_result.get("ok", false):
				ability_message = _localized_companion_ability_message(ability_id, ability_result)
			elif ability_id == "hidden_paw" and String(ability_result.get("reason", "")) in ["no_reachable_clue", "guidance_active"]:
				ability_message = _localize_ui("companion.response.ability.hidden_paw.waiting", "Miso checks the familiar corners. There is nothing new to show you just yet.")
			elif ability_id == "memory_echo" and String(ability_result.get("reason", "")) == "nothing_to_echo":
				ability_message = _localize_ui("companion.response.ability.memory_echo.none", "Miso has no new memory to share just now.")
			elif ability_id == "guardian_purr" and String(ability_result.get("reason", "")) == "no_active_anomaly":
				ability_message = _localize_ui("companion.response.ability.guardian_purr.no_target", "There is no unsettled anomaly for Miso to soothe just now.")
			_refresh_companion_panel(ability_message)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_down"):
			game.cycle_miso_sleep_spot()
			var resting_spot := String(game.miso_companion.preferred_sleep_spot)
			var resting_definition: Dictionary = game.miso_companion.sleep_spots.get(resting_spot, {})
			_refresh_companion_panel(_localize_ui("companion.response.sleep.%s" % resting_spot, String(resting_definition.get("response", "Miso settles in a new spot."))))
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("companion") or event.is_action_pressed("ui_back") or event.is_action_pressed("interact"):
			_close_side_panel()
			get_viewport().set_input_as_handled()
			return
	if active_panel == "radio":
		var station_slot := _number_slot(event)
		if station_slot >= 0 and station_slot < RADIO_STATIONS.size():
			radio_station_index = station_slot
			settings_manager.set_setting("radio_station_id", String(RADIO_STATIONS[station_slot].get("id", "bellwether_after_hours")))
			_apply_radio_station()
			_refresh_radio_panel()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("radio") or event.is_action_pressed("ui_back") or event.is_action_pressed("interact"):
			_close_side_panel()
			get_viewport().set_input_as_handled()
			return
	if active_panel == "upgrades":
		var upgrade_slot := _number_slot(event)
		if upgrade_slot >= 0 and upgrade_slot < mini(5, upgrade_ids.size()):
			var purchased_upgrade_id := String(upgrade_ids[upgrade_slot])
			var upgrade_result: Dictionary = game.purchase_upgrade(purchased_upgrade_id)
			var purchased_upgrade: Dictionary = upgrade_result.get("upgrade", {})
			var purchased_upgrade_name := _localize_ui("upgrade.%s.name" % purchased_upgrade_id, String(purchased_upgrade.get("name", purchased_upgrade_id)))
			var purchase_message := _format_localized_ui("upgrade.purchased", "Purchased {upgrade}.", {"upgrade":purchased_upgrade_name})
			if not upgrade_result.get("ok", false):
				match String(upgrade_result.get("reason", "")):
					"not_enough_currency":
						var needed_currency := _localize_ui("currency.moon_tokens", "Moon Tokens") if upgrade_result.get("currency", "coins") == "moon_tokens" else _localize_ui("currency.coins", "Coins")
						purchase_message = _format_localized_ui("upgrade.need_currency", "You need {amount} more {currency} for that.", {"amount":str(int(upgrade_result.get("cost", 0))), "currency":needed_currency})
					"already_owned":
						purchase_message = _localize_ui("upgrade.already_owned", "Moonmart already has that improvement.")
					_:
						purchase_message = _localize_ui("upgrade.unavailable", "That improvement is not available yet. Keep building the shop's reputation and harmony.")
			_refresh_upgrades_panel(purchase_message)
			if String(upgrade_ids[upgrade_slot]) == "shop_radio" and bool(upgrade_result.get("ok", false)):
				_apply_radio_station()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("upgrades") or event.is_action_pressed("ui_back"):
			_close_side_panel()
			get_viewport().set_input_as_handled()
			return
	if active_panel == "mystery_cases":
		var case_slot := _number_slot(event)
		if case_slot >= 0 and case_slot < mystery_case_ids.size():
			selected_investigation_id = mystery_case_ids[case_slot]
			_show_mystery_hypotheses()
			get_viewport().set_input_as_handled()
			return
	if active_panel == "mystery_hypotheses":
		if event.is_action_pressed("mystery_pin"):
			var clue_to_toggle := ""
			for clue_id in investigation_clue_ids:
				if game.story.clues.has(clue_id) and not game.story.pinned_clues.has(clue_id):
					clue_to_toggle = clue_id
					break
			if clue_to_toggle.is_empty():
				for clue_id in investigation_clue_ids:
					if game.story.pinned_clues.has(clue_id):
						clue_to_toggle = clue_id
						break
			if not clue_to_toggle.is_empty():
				var pin_value: bool = not game.story.pinned_clues.has(clue_to_toggle)
				game.pin_clue(clue_to_toggle, pin_value)
				_show_mystery_hypotheses()
			get_viewport().set_input_as_handled()
			return
		var hypothesis_slot := _number_slot(event)
		if hypothesis_slot >= 0 and hypothesis_slot < mystery_hypotheses.size():
			var selected: Dictionary = mystery_hypotheses[hypothesis_slot]
			var required: Array[String] = []
			for clue_id in selected.get("required_clues", []):
				required.append(String(clue_id))
			_close_side_panel()
			var result := game.connect_clues(selected_investigation_id, required)
			var result_message := String(result.get("message", "The journal keeps the thought safe for later."))
			var result_hypothesis_id := String(result.get("hypothesis_id", ""))
			if not result_hypothesis_id.is_empty():
				var response_key := "investigation.%s.hypothesis.%s.response" % [selected_investigation_id, result_hypothesis_id]
				result_message = _localize_ui(response_key, result_message)
			elif String(result.get("status", "")) == "unknown_case":
				result_message = _localize_ui("mystery.result.unknown_case", result_message)
			else:
				result_message = _localize_ui("mystery.result.unmatched", result_message)
			_on_message_changed(result_message)
			get_viewport().set_input_as_handled()
			return
	if active_panel == "endings":
		var ending_slot := _number_slot(event)
		var endings := game.available_endings()
		if ending_slot >= 0 and ending_slot < endings.size():
			var ending_id := String(endings[ending_slot].get("id", ""))
			var result := game.choose_ending(ending_id)
			_close_side_panel()
			if result.get("ok", false):
				var ending: Dictionary = result.get("ending", {})
				_apply_ending_world_state(ending_id)
				var ending_title := _localize_ui("journal.ending.%s.title" % ending_id, String(ending.get("title", ending_id)))
				var epilogue := _localize_ui("journal.ending.%s.epilogue" % ending_id, String(ending.get("epilogue", "The story continues in a new quiet season.")))
				var world_note := _localize_ui("journal.ending.world_note.%s" % ending_id, "Moonmart keeps its light burning as a sanctuary between worlds.")
				_on_message_changed("%s\n\n%s\n\n%s" % [ending_title, epilogue, world_note])
			get_viewport().set_input_as_handled()
			return
	if active_panel == "map":
		if event.is_action_pressed("page_next") or event.is_action_pressed("page_previous"):
			var page_count := maxi(1, ceili(float(game.available_locations().size()) / float(MAP_PAGE_SIZE)))
			map_page = clampi(map_page + (1 if event.is_action_pressed("page_next") else -1), 0, page_count - 1)
			_refresh_map_panel()
			get_viewport().set_input_as_handled()
			return
		var destination_slot := _number_slot(event)
		if destination_slot >= 0 and destination_slot < map_location_ids.size():
			var destination := map_location_ids[destination_slot]
			_close_side_panel()
			_travel_to_location(destination)
			get_viewport().set_input_as_handled()
			return
	if active_panel == "journal":
		var memory_slot := _number_slot(event)
		var saved_memories := game.story.ending_memories_for_journal()
		if memory_slot >= 0 and memory_slot < saved_memories.size():
			var memory: Dictionary = saved_memories[memory_slot]
			game._set_message(_ending_memory_message(memory))
			get_viewport().set_input_as_handled()
			return
	if active_panel == "ledger" and event.is_action_pressed("ledger_refund"):
		var latest_sale := game.inventory.latest_refundable_sale()
		if not latest_sale.is_empty():
			var refund_result: Dictionary = game.refund_sale(String(latest_sale.get("id", "")))
			if refund_result.get("ok", false):
				status_label.text = _format_localized_ui("ledger.refund.success", "Refunded {amount} {currency} and returned the goods to stock.", {"amount":str(refund_result.get("amount", 0)), "currency":_localize_ui("currency.%s" % String(refund_result.get("currency", "coins")), String(refund_result.get("currency", "coins")).replace("_", " "))})
			else:
				status_label.text = _localize_ui("ledger.refund.failure", "The refund cannot complete until Moonmart has enough funds and room for the returned items.")
			active_panel = ""
			_toggle_panel("ledger")
		get_viewport().set_input_as_handled()
		return
	if active_panel == "environmental_puzzle":
		var current_puzzle: Dictionary = game.environmental_puzzles.puzzle(active_environmental_puzzle_id, game.story.flags)
		var puzzle_solved := bool(current_puzzle.get("solved", false))
		var close_puzzle := event.is_action_pressed("pause") or (puzzle_solved and event.is_action_pressed("interact"))
		close_puzzle = close_puzzle or event.is_action_pressed("ui_back") or (puzzle_solved and event.is_action_pressed("interact"))
		if close_puzzle:
			_close_side_panel()
		get_viewport().set_input_as_handled()
		return
	if active_panel == "checkout":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			if checkout_phase == "recommendation":
				var recommendation_direction := -1 if event.is_action_pressed("move_left") else 1
				checkout_recommendation_choice_index = posmod(checkout_recommendation_choice_index + recommendation_direction, CHECKOUT_RECOMMENDATION_CHOICES.size())
				_refresh_checkout_panel()
			elif checkout_phase == "packing":
				var pack_direction := -1 if event.is_action_pressed("move_left") else 1
				checkout_packing_choice_index = posmod(checkout_packing_choice_index + pack_direction, CHECKOUT_PACKING_CHOICES.size())
				_refresh_checkout_panel()
			elif checkout_phase == "payment":
				var tender_direction := -1 if event.is_action_pressed("move_left") else 1
				checkout_tender_choice_index = posmod(checkout_tender_choice_index + tender_direction, CHECKOUT_TENDER_CHOICES.size())
				_refresh_checkout_panel()
			elif not checkout_item_ids.is_empty():
				var direction := -1 if event.is_action_pressed("move_left") else 1
				checkout_cursor = posmod(checkout_cursor + direction, checkout_item_ids.size())
				_refresh_checkout_panel()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("interact"):
			if checkout_phase == "recommendation":
				_resolve_checkout_recommendation(CHECKOUT_RECOMMENDATION_CHOICES[checkout_recommendation_choice_index])
			elif checkout_phase == "packing":
				_advance_checkout_after_packing(CHECKOUT_PACKING_CHOICES[checkout_packing_choice_index])
			elif checkout_phase == "payment":
				_finish_checkout_payment(CHECKOUT_TENDER_CHOICES[checkout_tender_choice_index])
			elif _checkout_is_complete():
				_continue_checkout_after_scan()
			elif assisted_checkout_enabled:
				var customer_record := game.customers.get_customer(checkout_customer_id)
				var full_basket: Dictionary = customer_record.get("basket", {}).duplicate(true)
				checkout_scanned = full_basket
				_continue_checkout_after_scan()
			else:
				_scan_checkout_item(checkout_cursor)
			get_viewport().set_input_as_handled()
			return
		var checkout_slot := _number_slot(event)
		if checkout_phase == "recommendation" and checkout_slot >= 0 and checkout_slot < CHECKOUT_RECOMMENDATION_CHOICES.size():
			_resolve_checkout_recommendation(CHECKOUT_RECOMMENDATION_CHOICES[checkout_slot])
			get_viewport().set_input_as_handled()
			return
		if checkout_phase == "packing" and checkout_slot >= 0 and checkout_slot < CHECKOUT_PACKING_CHOICES.size():
			_advance_checkout_after_packing(CHECKOUT_PACKING_CHOICES[checkout_slot])
			get_viewport().set_input_as_handled()
			return
		if checkout_phase == "payment" and checkout_slot >= 0 and checkout_slot < CHECKOUT_TENDER_CHOICES.size():
			_finish_checkout_payment(CHECKOUT_TENDER_CHOICES[checkout_slot])
			get_viewport().set_input_as_handled()
			return
		if checkout_phase == "scan" and checkout_slot >= 0 and checkout_slot < 5:
			_scan_checkout_item(checkout_slot)
			get_viewport().set_input_as_handled()
			return
	if active_panel == "craft":
		if event.is_action_pressed("page_next") or event.is_action_pressed("page_previous"):
			craft_page = posmod(craft_page + (1 if event.is_action_pressed("page_next") else -1), _craft_total_page_count())
			_refresh_craft_panel()
			get_viewport().set_input_as_handled()
			return
		var craft_slot := _number_slot(event)
		if _craft_page_is_experiment():
			var experiment_page := craft_page - _craft_recipe_page_count()
			var experiment_index := experiment_page * 5 + craft_slot
			if craft_slot >= 0 and craft_slot < 5 and experiment_index < craft_experiment_ingredient_ids.size():
				var ingredient_id := craft_experiment_ingredient_ids[experiment_index]
				if game.inventory.available_quantity(ingredient_id) <= 0:
					status_label.text = _localize_ui("craft.experiment.result.out_of_stock", "That ingredient is not in stock yet. Nothing was used.")
					get_viewport().set_input_as_handled()
					return
				if craft_experiment_selected.has(ingredient_id):
					craft_experiment_selected.erase(ingredient_id)
				else:
					craft_experiment_selected[ingredient_id] = 1
				_refresh_craft_panel()
				get_viewport().set_input_as_handled()
				return
			if event.is_action_pressed("interact"):
				_submit_craft_experiment()
				get_viewport().set_input_as_handled()
				return
		var craft_index := craft_page * 5 + craft_slot
		if craft_slot >= 0 and craft_slot < 5 and craft_index < available_recipe_ids.size():
			var recipe_id := available_recipe_ids[craft_index]
			var craft_limit := 3 if simplified_crafting_enabled else 1
			var result: Dictionary = {}
			var crafted_count := 0
			for _craft_attempt in range(craft_limit):
				result = game.craft(recipe_id, active_craft_station_id)
				if not result.get("ok", false):
					break
				crafted_count += 1
			if crafted_count > 0:
				_trigger_player_action(7)
				if sfx_manager != null:
					sfx_manager.play_sfx("ceramic_cup")
				var recipe_name := _localized_recipe_name(recipe_id)
				var output_id := String(game.recipes.get(recipe_id, {}).get("output_product_id", ""))
				var output_name := _localized_product_name(output_id, "finished goods")
				status_label.text = _format_localized_ui("craft.result.success", "{recipe} · {count} {product} made and put away", {"recipe":recipe_name, "count":crafted_count, "product":output_name})
			else:
				match String(result.get("reason", "")):
					"storage_capacity": status_label.text = _localize_ui("craft.error.storage_capacity", "Backroom storage is full. Make room before preparing more drinks.")
					"product_capacity": status_label.text = _localize_ui("craft.error.product_capacity", "There is no room for another batch of that drink.")
					"wrong_station":
						var required_station_id := String(result.get("required_station", ""))
						var required_station_name := _localize_ui(String(CRAFT_STATION_UI_IDS.get(required_station_id, "craft.station.default")), String(CRAFT_STATION_NAMES.get(required_station_id, "RIGHT STATION"))).to_lower()
						status_label.text = _format_localized_ui("craft.error.wrong_station", "That recipe belongs at the {station}.", {"station":required_station_name})
					_: status_label.text = _localize_ui("craft.error.ingredients", "There aren't enough ingredients for that recipe yet.")
			_refresh_craft_panel()
			get_viewport().set_input_as_handled()
			return
	if active_panel == "stock":
		if event.is_action_pressed("page_next") or event.is_action_pressed("page_previous"):
			var last_page := maxi(0, int((stocked_product_ids.size() - 1) / 5))
			stock_page = clampi(stock_page + (1 if event.is_action_pressed("page_next") else -1), 0, last_page)
			_refresh_stock_panel()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("stock_restock") or event.is_action_pressed("stock_restock_all"):
			if stock_panel_mode == "backroom_delivery":
				status_label.text = _localize_ui("stock.status.deliveries_storage", "Deliveries arrive in storage first. Use the supply shelves or trolley to replenish a display.")
			else:
				var restock_selected_index := stock_page * 5 + stock_selected_slot
				if restock_selected_index < stocked_product_ids.size():
					var selected_stock_id := stocked_product_ids[restock_selected_index]
					var is_bulk_restock := event.is_action_pressed("stock_restock_all")
					var is_backroom_storage := stock_panel_mode in ["backroom_storage", "backroom_trolley"]
					if is_bulk_restock:
						if not is_backroom_storage:
							status_label.text = _localize_ui("stock.status.bulk_restock_backroom", "Bulk restocking is available from the backroom trolley. Carry individual goods to the displays.")
						else:
							var shelf_space := game.inventory.shelf_capacity_for(selected_stock_id) - game.inventory.shelf_quantity(selected_stock_id)
							var amount_to_move := mini(game.inventory.storage_quantity(selected_stock_id), maxi(0, shelf_space))
							var bulk_result: Dictionary = game.restock_shelf(selected_stock_id, amount_to_move)
							status_label.text = _format_localized_ui("stock.status.restock_success", "{product} moved to the display · {shown} shown, {storage} in backroom", {"product":_localized_product_name(selected_stock_id), "shown":str(game.inventory.shelf_quantity(selected_stock_id)), "storage":str(game.inventory.storage_quantity(selected_stock_id))}) if bulk_result.get("ok", false) else _localize_ui("stock.status.restock_unavailable", "That display cannot be replenished yet. Check its backroom quantity and capacity.")
					elif is_backroom_storage:
						if game.inventory.is_carrying_stock():
							var return_result: Dictionary = game.return_carried_stock_to_storage(selected_stock_id)
							if return_result.get("ok", false):
								_trigger_player_action(3)
								status_label.text = _format_localized_ui("stock.status.carry_returned", "{product} returned to backroom storage.", {"product":_localized_product_name(selected_stock_id)})
							elif String(return_result.get("reason", "")) == "different_product":
								status_label.text = _format_localized_ui("stock.status.carry_wrong_product", "You're carrying {carried}; select that product before returning it.", {"carried":_localized_product_name(String(return_result.get("carried_product_id", "")))})
							else:
								status_label.text = _localize_ui("stock.status.carry_return_unavailable", "That item cannot be returned to storage right now.")
						else:
							var pickup_result: Dictionary = game.pick_up_stock_to_carry(selected_stock_id)
							if pickup_result.get("ok", false):
								_trigger_player_action(3)
								status_label.text = _format_localized_ui("stock.status.carry_pickup", "Picked up {product} · close this panel and carry it to a display.", {"product":_localized_product_name(selected_stock_id)})
							elif String(pickup_result.get("reason", "")) == "hands_full":
								status_label.text = _format_localized_ui("stock.status.carry_hands_full", "You're already carrying {product}. Place it or return it before picking up another.", {"product":_localized_product_name(String(pickup_result.get("product_id", "")))})
							else:
								status_label.text = _localize_ui("stock.status.restock_unavailable", "That display cannot be replenished yet. Check its backroom quantity and capacity.")
					else:
						var carried_id: String = game.inventory.carried_product_id
						if not game.inventory.is_carrying_stock():
							status_label.text = _localize_ui("stock.status.carry_need_pickup", "Pick up this item from the backroom before stocking it.")
						elif carried_id != selected_stock_id:
							status_label.text = _format_localized_ui("stock.status.carry_wrong_product", "You're carrying {carried}; select that product's display.", {"carried":_localized_product_name(carried_id)})
						else:
							var place_result: Dictionary = game.place_carried_stock_on_shelf(selected_stock_id)
							if place_result.get("ok", false):
								_trigger_player_action(3)
								status_label.text = _format_localized_ui("stock.status.carry_placed", "{product} placed on the display · {shown}/{capacity} shown.", {"product":_localized_product_name(selected_stock_id), "shown":str(game.inventory.shelf_quantity(selected_stock_id)), "capacity":str(game.inventory.shelf_capacity_for(selected_stock_id))})
							elif String(place_result.get("reason", "")) == "shelf_capacity":
								status_label.text = _localize_ui("stock.status.carry_shelf_full", "That display is full. Keep carrying the item or return it to the backroom.")
							else:
								status_label.text = _localize_ui("stock.status.restock_unavailable", "That display cannot be replenished yet. Check its backroom quantity and capacity.")
					_refresh_stock_panel()
			get_viewport().set_input_as_handled()
			return
		var stock_action_pressed := event.is_action_pressed("stock_markdown") or event.is_action_pressed("stock_markdown_clear") or event.is_action_pressed("stock_donate") or event.is_action_pressed("stock_donate_all")
		if stock_action_pressed and stock_panel_mode in ["retail_shelf", "retail_fridge"]:
			var action_selected_index := stock_page * 5 + stock_selected_slot
			if action_selected_index < stocked_product_ids.size():
				var action_selected_id := stocked_product_ids[action_selected_index]
				if event.is_action_pressed("stock_markdown_clear"):
					game.clear_stock_discount(action_selected_id)
					status_label.text = _format_localized_ui("stock.status.price_restored", "Price restored · {product} now sells for {price} Coins.", {"product":_localized_product_name(action_selected_id), "price":str(game.inventory.price_for(action_selected_id))})
				elif event.is_action_pressed("stock_markdown"):
					game.discount_stock(action_selected_id, 0.75)
					status_label.text = _format_localized_ui("stock.status.markdown", "{product} marked down to {price} Coins for tonight.", {"product":_localized_product_name(action_selected_id), "price":str(game.inventory.price_for(action_selected_id))})
				else:
					var donation_amount := game.inventory.available_quantity(action_selected_id) if event.is_action_pressed("stock_donate_all") else 1
					var donation: Dictionary = game.donate_stock(action_selected_id, donation_amount)
					status_label.text = _format_localized_ui("stock.status.donated", "Donated {amount} {product} to the Bellwether pantry.", {"amount":str(donation_amount), "product":_localized_product_name(action_selected_id)}) if donation.get("ok", false) else _localize_ui("stock.status.nothing_to_donate", "There is no stock available to donate.")
				_refresh_stock_panel()
			get_viewport().set_input_as_handled()
			return
		var slot := _number_slot(event)
		var product_index := stock_page * 5 + slot
		if slot >= 0 and product_index < stocked_product_ids.size():
			var product_id := stocked_product_ids[product_index]
			stock_selected_slot = slot
			if stock_panel_mode in ["backroom_storage", "backroom_trolley"]:
				if game.inventory.is_carrying_stock() and product_id == game.inventory.carried_product_id:
					status_label.text = _format_localized_ui("stock.status.carry_return_select", "{product} selected · press {restock} to return the item you're carrying to storage.", {"product":_localized_product_name(product_id), "restock":_binding_label("stock_restock")})
				elif game.inventory.is_carrying_stock():
					status_label.text = _format_localized_ui("stock.status.carry_hands_full", "You're already carrying {product}. Place it or return it before picking up another.", {"product":_localized_product_name(game.inventory.carried_product_id)})
				else:
					status_label.text = _format_localized_ui("stock.status.selected_storage", "{product} selected · {amount} in storage. Press {restock} to pick up one and carry it to its display.", {"product":_localized_product_name(product_id), "amount":str(game.inventory.storage_quantity(product_id)), "restock":_binding_label("stock_restock")})
			elif stock_panel_mode in ["retail_shelf", "retail_fridge"] and game.inventory.is_carrying_stock():
				status_label.text = _format_localized_ui("stock.status.carry_selected", "{product} display selected · press {restock} to place the item you're carrying here.", {"product":_localized_product_name(product_id), "restock":_binding_label("stock_restock")})
			elif stock_panel_mode == "backroom_delivery" or stock_panel_mode in ["retail_shelf", "retail_fridge"]:
				var result: Dictionary = game.order_stock(product_id)
				if result.get("ok", false):
					status_label.text = _format_localized_ui("stock.status.delivery_stored", "{product} delivery put away · −{cost} Coins. It is now in backroom storage.", {"product":_localized_product_name(product_id), "cost":str(result.cost)})
				else:
					if result.get("reason", "") == "craft_only":
						status_label.text = _format_localized_ui("stock.status.craft_only", "{product} is made at the kettle and cannot be ordered from the supplier.", {"product":_localized_product_name(product_id)})
					elif result.get("reason", "") == "not_enough_coins":
						status_label.text = _format_localized_ui("stock.status.not_enough_coins", "That delivery needs {cost} Coins. Keep the order for later.", {"cost":str(result.get("cost", 0))})
					else:
						status_label.text = _localize_ui("stock.status.no_delivery_capacity", "There isn't enough backroom capacity for that delivery yet.")
			_refresh_stock_panel()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interact"):
		if not message_open:
			_trigger_player_action(5)
		if message_open:
			_dismiss_message()
		elif not active_panel.is_empty():
			_close_side_panel()
		elif nearby_id == "" and game.shift_status != "open":
			_run_auto_stock()
			game.begin_shift()
		elif nearby_id == "shelf" or nearby_id == "fridge":
			_open_stock_panel(nearby_id)
		elif nearby_id == "journal":
			_toggle_panel("journal")
		elif not _craft_station_for_access_id(nearby_id).is_empty():
			_open_craft_panel(_craft_station_for_access_id(nearby_id))
		elif nearby_id.begins_with("customer:"):
			game.interact(nearby_id.trim_prefix("customer:"))
		elif nearby_id == "register":
			_open_checkout_panel()
		elif nearby_id == "miso":
			_open_companion_panel()
		elif nearby_id.begins_with("decoration:"):
			var decoration_message := game.read_placed_decoration_message(nearby_id.trim_prefix("decoration:"))
			if not decoration_message.is_empty():
				game._set_message(decoration_message)
		elif current_location_scene != null:
			_interact_location(false)
		elif nearby_id == "back_door" and game.story.flags.get("hidden_midnight_room_found", false):
			if game.world_map.ending_id == "gentle_goodbye":
				var memory_route := game.essential_activity_route("hidden_midnight_room")
				if memory_route.begins_with("journal_memory:"):
					var memory := game.story.read_ending_memory(memory_route.trim_prefix("journal_memory:"))
					game._set_message(_ending_memory_message(memory))
				else:
					game._set_message(_localize_ui("journal.memory_not_recorded", "The doorway stays closed by choice. No memory of that room was recorded in this save."))
			else:
				_travel_to_location("hidden_midnight_room")
		else:
			game.interact(nearby_id)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inspect"):
		if not message_open:
			_trigger_player_action(4)
		if message_open:
			_dismiss_message()
		elif nearby_id.begins_with("decoration:"):
			var decoration_message := game.read_placed_decoration_message(nearby_id.trim_prefix("decoration:"))
			if not decoration_message.is_empty():
				game._set_message(decoration_message)
		elif current_location_scene != null and not nearby_id.is_empty():
			_interact_location(true)
		elif not nearby_id.is_empty():
			game.interact(nearby_id, true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal"):
		_toggle_panel("journal")
	elif event.is_action_pressed("town_map"):
		_toggle_panel("map")
	elif event.is_action_pressed("calendar"):
		_toggle_panel("calendar")
	elif event.is_action_pressed("housekeeping"):
		_toggle_panel("housekeeping")
	elif event.is_action_pressed("upgrades"):
		_toggle_panel("upgrades")
	elif event.is_action_pressed("radio"):
		_toggle_panel("radio")
	elif event.is_action_pressed("companion"):
		_toggle_panel("companion")
	elif event.is_action_pressed("decorate"):
		_toggle_panel("decorate")
	elif event.is_action_pressed("mystery_board"):
		_toggle_panel("mystery_board")
	elif event.is_action_pressed("ledger"):
		_toggle_panel("ledger")
	elif event.is_action_pressed("inventory"):
		_toggle_panel("inventory")
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_back"):
		if message_open:
			_dismiss_message()
		elif active_panel != "":
			_close_side_panel()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()

func _toggle_panel(kind: String) -> void:
	_hide_product_detail_icon()
	if active_panel == "environmental_puzzle" and kind != "environmental_puzzle":
		_close_side_panel()
	if message_open:
		_dismiss_message()
	if active_panel == "decorate" and kind != "decorate" and decoration_preview != null:
		decoration_preview.visible = false
	if kind == "mystery_board":
		if active_panel == "mystery_hypotheses":
			_open_mystery_board()
		elif active_panel == "mystery_cases":
			_close_side_panel()
		else:
			_open_mystery_board()
		return
	if kind == "map":
		if active_panel == "map":
			_close_side_panel()
		else:
			_open_map_panel()
		return
	if kind == "calendar":
		if active_panel == "calendar":
			_close_side_panel()
		else:
			_open_calendar_panel()
		return
	if kind == "housekeeping":
		if active_panel == "housekeeping":
			_close_side_panel()
		else:
			_open_housekeeping_panel()
		return
	if kind == "upgrades":
		if active_panel == "upgrades":
			_close_side_panel()
		else:
			_open_upgrades_panel()
		return
	if kind == "companion":
		if active_panel == "companion":
			_close_side_panel()
		else:
			_open_companion_panel()
		return
	if kind == "radio":
		if active_panel == "radio":
			_close_side_panel()
		else:
			_open_radio_panel()
		return
	if kind == "decorate":
		if not _decoration_room_supported():
			status_label.text = _localize_ui("decorate.unavailable_room", "Decorating is available in Moonmart and its backroom.")
			return
		if game.shift_status == "open":
			status_label.text = _localize_ui("decorate.unavailable_open_shift", "Organizing is available between shifts. Finish or close this night first.")
			return
		if active_panel == "decorate":
			_close_side_panel()
		else:
			_open_decoration_panel()
		return
	if active_panel == kind:
		_close_side_panel()
		return
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = kind
	if kind == "journal":
		side_label.text = _format_localized_ui("journal.panel", "{body}\n\n{interact} interacts · {journal} opens the journal · {back} goes back.", {"body":_journal_panel_text(), "interact":_binding_label("interact"), "journal":_binding_label("journal"), "back":_binding_label("ui_back")})
	elif kind == "ledger":
		var tier: Dictionary = game.shop_progression.current_reputation_tier()
		var proficiency_lines: Array[String] = []
		for skill_id in game.shop_progression.proficiency_definitions:
			var skill_id_string := String(skill_id)
			var skill_name := String(game.shop_progression.proficiency_definitions[skill_id].get("name", skill_id.capitalize()))
			var skill_rank := game.shop_progression.proficiency_rank(skill_id_string)
			var rank_name := game.shop_progression.proficiency_rank_name(skill_id_string)
			proficiency_lines.append("%s · %s" % [_localize_ui("proficiency.%s.name" % skill_id_string, skill_name), _localize_ui("proficiency.%s.rank.%d" % [skill_id_string, skill_rank], rank_name)])
		side_label.text = _format_localized_ui("ledger.panel", "SHOP LEDGER\n\nNight {night} · {shift}\nCoins: {coins}\nMoon Tokens: {moons}\n\nLast shift earned · {earned_coins} Coins · {earned_moons} Moon Tokens\n\nReputation · {reputation} · {tier}\nMidnight Harmony · {harmony} / 100\nCleanliness · {cleanliness}%\n\n{skills}\n\nMost customers pay in Coins. Some travellers from the Between trade in Moon Tokens.\n\n{interact} interacts · {ledger} opens the ledger · {back} goes back.", {"night":str(game.shift_number), "shift":_localize_ui("shift.%s" % game.shift_status, game.shift_status.replace("_", " ")), "coins":str(current_coins), "moons":str(current_moons), "earned_coins":str(game.last_shift_coin_earnings), "earned_moons":str(game.last_shift_moon_earnings), "reputation":str(game.shop_progression.reputation), "tier":_localize_ui("reputation_tier.%s" % String(tier.get("id", "little_corner_shop")), String(tier.get("name", "Little Corner Shop"))), "harmony":str(game.shop_progression.harmony), "cleanliness":str(roundi(game.shop_progression.cleanliness)), "skills":"\n".join(proficiency_lines), "interact":_binding_label("interact"), "ledger":_binding_label("ledger"), "back":_binding_label("ui_back")})
		var latest_sale := game.inventory.latest_refundable_sale()
		if not latest_sale.is_empty():
			side_label.text += _format_localized_ui("ledger.latest_sale", "\n\nLatest sale · {total} {currency}. Press {refund} to refund it.", {"total":str(latest_sale.get("total", 0)), "currency":_localize_ui("currency.%s" % String(latest_sale.get("currency", "coins")), String(latest_sale.get("currency", "coins")).replace("_", " ").capitalize()), "refund":_binding_label("ledger_refund")})
	elif kind == "inventory":
		var lines: Array[String] = [_localize_ui("inventory.heading", "INVENTORY & STOCK")]
		for id in game.inventory.products:
			var product: Dictionary = game.inventory.products[id]
			var shelf_capacity := game.inventory.shelf_capacity_for(String(id))
			var fresh_for := game.inventory.freshness_remaining(String(id))
			var freshness_text := _format_localized_ui("inventory.freshness", " · best before in {shifts} shifts", {"shifts":str(fresh_for)}) if fresh_for >= 0 else ""
			var price_modifier := _format_localized_ui("inventory.discount", " · {percent}% off", {"percent":"%.0f" % ((1.0 - float(game.inventory.price_modifiers.get(String(id), 1.0))) * 100.0)}) if game.inventory.price_modifiers.has(String(id)) else ""
			lines.append(_format_localized_ui("inventory.row", "{product}    display {shown} / {capacity}  ·  backroom {storage}{freshness}{discount}", {"product":_localized_product_name(String(id), String(product.get("name", id))), "shown":str(game.inventory.shelf_quantity(String(id))), "capacity":str(shelf_capacity), "storage":str(game.inventory.storage_quantity(String(id))), "freshness":freshness_text, "discount":price_modifier}))
		if not game.inventory.prepared_items.is_empty():
			lines.append("\n" + _localize_ui("inventory.prepared_heading", "Prepared drinks"))
			for recipe_id in game.inventory.prepared_items:
				var recipe_name := _localized_recipe_name(recipe_id)
				lines.append(_format_localized_ui("inventory.prepared_item", "{name}    × {count}", {"name":recipe_name, "count":str(game.inventory.prepared_items[recipe_id])}))
		lines.append(_format_localized_ui("inventory.controls", "\n{interact} interacts · {inventory} opens inventory · {back} goes back.", {"interact":_binding_label("interact"), "inventory":_binding_label("inventory"), "back":_binding_label("ui_back")}))
		side_label.text = "\n".join(lines)
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)

func _open_mystery_board() -> void:
	_hide_product_detail_icon()
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "mystery_cases"
	mystery_case_ids.clear()
	var lines: Array[String] = [_localize_ui("mystery.cases.heading", "THE MIDNIGHT JOURNAL · OPEN CASES"), "\n" + _localize_ui("mystery.cases.prompt", "Choose a question to investigate.")]
	for case_id in game.story.investigation_definitions:
		var case_data: Dictionary = game.story.investigation_definitions[case_id]
		if int(case_data.get("chapter", 1)) > game.story.chapter:
			continue
		if bool(game.story.investigation_state.get(case_id, {}).get("completed", false)):
			continue
		mystery_case_ids.append(String(case_id))
		lines.append("\n%d   %s" % [mystery_case_ids.size(), _localize_ui("investigation.%s.title" % case_id, String(case_data.get("title", case_id)))])
	if mystery_case_ids.is_empty():
		lines.append("\n" + _localize_ui("mystery.cases.empty", "No open investigations right now. Give the night time to surprise you."))
	if mystery_case_ids.is_empty():
		lines.append(_format_localized_ui("mystery.cases.controls_empty", "\n\n{mystery} opens the mystery board · {interact} interacts · {back} goes back.", {"mystery":_binding_label("mystery_board"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	else:
		lines.append(_format_localized_ui("mystery.cases.controls", "\n\n{selection} selects a case. {mystery} opens the mystery board · {interact} interacts · {back} goes back.", {"selection":_selection_hint(mini(9, mystery_case_ids.size())), "mystery":_binding_label("mystery_board"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)

func _show_mystery_hypotheses() -> void:
	active_panel = "mystery_hypotheses"
	var case_data: Dictionary = game.story.investigation_definitions.get(selected_investigation_id, {})
	mystery_hypotheses.clear()
	for hypothesis_value in case_data.get("hypotheses", []):
		if hypothesis_value is Dictionary and game.story.investigation_hypothesis_available(hypothesis_value):
			mystery_hypotheses.append(hypothesis_value)
	investigation_clue_ids.clear()
	var case_title := _localize_ui("investigation.%s.title" % selected_investigation_id, String(case_data.get("title", selected_investigation_id)))
	var lines: Array[String] = [case_title, "\n" + _localize_ui("mystery.hypotheses.prompt", "Choose an explanation. Unfinished ideas only bring another hint.")]
	for index in range(mini(5, mystery_hypotheses.size())):
		var hypothesis: Dictionary = mystery_hypotheses[index]
		var clues: Array[String] = []
		for clue_id in hypothesis.get("required_clues", []):
			var clue_id_string := String(clue_id)
			if not investigation_clue_ids.has(clue_id_string):
				investigation_clue_ids.append(clue_id_string)
			var clue: Dictionary = game.story.clue_definitions.get(clue_id_string, {})
			var mark := "★" if game.story.pinned_clues.has(clue_id_string) else ("✓" if game.story.clues.has(clue_id_string) else "?")
			var clue_text := _localize_ui("clue.%s.text" % clue_id_string, String(clue.get("text", String(clue_id).replace("_", " "))))
			if mystery_hint_level == "none":
				clue_text = _localize_ui("mystery.clue.recorded", "Recorded clue") if mark != "?" else _localize_ui("mystery.clue.unfound", "Unfound clue")
			clues.append("%s %s" % [mark, clue_text])
		var hypothesis_id := String(hypothesis.get("id", ""))
		var hypothesis_text := _localize_ui("investigation.%s.hypothesis.%s.text" % [selected_investigation_id, hypothesis_id], String(hypothesis.get("text", _localize_ui("mystery.hypothesis.fallback", "Theory"))))
		var theory_line := "\n%d   %s\n      %s" % [index + 1, hypothesis_text, " · ".join(clues)]
		if mystery_hint_level == "guided":
			for clue_id in hypothesis.get("required_clues", []):
				if not game.story.clues.has(String(clue_id)):
					var next_clue: Dictionary = game.story.clue_definitions.get(String(clue_id), {})
					var hint := _localize_ui("clue.%s.text" % String(clue_id), String(next_clue.get("text", _localize_ui("mystery.hypotheses.generic_guided_hint", "look for another clue connected to this idea"))))
					theory_line += _format_localized_ui("mystery.hypotheses.guided_hint", "\n      Guided hint · {hint}", {"hint":hint})
					break
		lines.append(theory_line)
	lines.append(_format_localized_ui("mystery.hypotheses.controls", "\n\n{selection} connects a theory · {pin} pins the next discovered clue · {mystery} returns to cases · {back} goes back.", {"selection":_selection_hint(mini(5, mystery_hypotheses.size())), "pin":_binding_label("mystery_pin"), "mystery":_binding_label("mystery_board"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)

func _number_slot(event: InputEvent) -> int:
	for slot in range(9):
		if event.is_action_pressed("ui_select_%d" % (slot + 1)):
			return slot
	return -1

func _binding_label(action: String) -> String:
	var events: Array[InputEvent] = []
	if InputMap.has_action(action):
		for action_event in InputMap.action_get_events(action):
			events.append(action_event)
	if events.is_empty():
		return "Unbound"
	return events[0].as_text().replace(" (Physical)", "").replace("(Physical)", "").replace(" - Physical", "").strip_edges()

func _selection_hint(count: int) -> String:
	var labels: Array[String] = []
	for slot in range(clampi(count, 0, 9)):
		labels.append(_binding_label("ui_select_%d" % (slot + 1)))
	return ", ".join(labels)

func _open_map_panel() -> void:
	_hide_product_detail_icon()
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "map"
	map_page = 0
	_refresh_map_panel()
	game.set_paused(true)

func _refresh_map_panel() -> void:
	map_location_ids.clear()
	var available_locations := game.available_locations()
	var page_count := maxi(1, ceili(float(available_locations.size()) / float(MAP_PAGE_SIZE)))
	map_page = clampi(map_page, 0, page_count - 1)
	var first_index := map_page * MAP_PAGE_SIZE
	var last_index := mini(first_index + MAP_PAGE_SIZE, available_locations.size())
	var lines: Array[String] = [_localize_ui("map.heading", "BELLWETHER · TOWN MAP"), _format_localized_ui("map.page", "\nPage {page}/{pages}", {"page":str(map_page + 1), "pages":str(page_count)}), "\n" + _localize_ui("map.prompt", "Choose a place you have discovered.")]
	for location_index in range(first_index, last_index):
		var location: Dictionary = available_locations[location_index]
		var location_id := String(location.get("id", ""))
		map_location_ids.append(location_id)
		var current_marker := "  · " + _localize_ui("map.marker.current", "you are here") if location_id == current_location_id else ""
		var location_name := _localize_ui("location.%s.name" % location_id, String(location.get("name", location_id)))
		var location_description := _localize_ui("location.%s.description" % location_id, String(location.get("description", "")))
		lines.append("\n%d   %s%s\n      %s" % [map_location_ids.size(), location_name, current_marker, location_description])
	lines.append(_format_localized_ui("map.controls", "\n\n{previous}/{next} changes page · {selection} selects a destination · {interact} travels · {back} goes back.", {"previous":_binding_label("page_previous"), "next":_binding_label("page_next"), "selection":_selection_hint(map_location_ids.size()), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)
	side_panel.visible = true
	side_label.visible = true
	side_scroll.scroll_vertical = 0

func _open_calendar_panel() -> void:
	_hide_product_detail_icon()
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "calendar"
	var calendar_shift := maxi(game.shift_number, 1) if game.shift_status == "open" else maxi(game.shift_number + 1, 1)
	var date: Dictionary = game.calendar.date_for_shift(calendar_shift)
	var season: Dictionary = game.calendar.season_for_shift(calendar_shift)
	var festival: Dictionary = game.calendar.festival_for_shift(calendar_shift)
	var season_id := String(season.get("id", "spring"))
	var season_name := _localize_ui("calendar.season.%s.name" % season_id, String(season.get("name", "Spring")))
	var season_description := _localize_ui("calendar.season.%s.description" % season_id, String(season.get("description", "The town settles into a new season.")))
	var weekday_id := String(date.get("weekday", "Monday")).to_lower()
	var weekday := _localize_ui("calendar.weekday.%s" % weekday_id, String(date.get("weekday", "Monday")))
	var weather_id := game.calendar.weather_for_shift(calendar_shift)
	var weather := _localize_ui("calendar.weather.%s" % weather_id, weather_id.capitalize())
	var lines: Array[String] = [
		_localize_ui("calendar.heading", "BELLWETHER · SEASONAL CALENDAR"),
		"",
		_format_localized_ui("calendar.date", "Year {year} · {weekday}, day {day} of {days}", {"year":str(date.get("year", 1)), "weekday":weekday, "day":str(date.get("day_of_year", 1)), "days":str(game.calendar.days_per_year)}),
		"",
		_format_localized_ui("calendar.season_day", "{season} · day {day} of {days}", {"season":season_name, "day":str(date.get("season_day", 1)), "days":str(game.calendar.days_per_season)}),
		season_description,
		_format_localized_ui("calendar.weather_line", "Tonight's weather · {weather}", {"weather":weather})
	]
	if not festival.is_empty():
		var festival_id := String(festival.get("id", ""))
		var festival_name := _localize_ui("calendar.festival.%s.name" % festival_id, String(festival.get("name", "Festival")))
		var festival_description := _localize_ui("calendar.festival.%s.description" % festival_id, String(festival.get("description", "Bellwether gathers beneath the night sky.")))
		lines.append("\n" + _format_localized_ui("calendar.festival_tonight", "Festival tonight · {festival}", {"festival":festival_name}))
		lines.append(festival_description)
		if game.calendar.has_attended_festival(String(festival.get("id", "")), int(date.get("year", 1))):
			lines.append(_localize_ui("calendar.festival_attended", "You have already joined this year's gathering."))
	else:
		var next_name := ""
		var next_shift := 0
		for candidate in game.calendar.festivals:
			var occurrence := game.calendar.next_festival_shift(String(candidate.get("id", "")), calendar_shift - 1)
			if occurrence > 0 and (next_shift == 0 or occurrence < next_shift):
				next_shift = occurrence
				var next_festival_id := String(candidate.get("id", ""))
				next_name = _localize_ui("calendar.festival.%s.name" % next_festival_id, String(candidate.get("name", "Festival")))
		if next_shift > 0:
			lines.append(_format_localized_ui("calendar.next_festival", "\nNext celebration · {festival} in {nights} nights", {"festival":next_name, "nights":str(next_shift - int(date.get("shift", 1))) }))
	lines.append(_format_localized_ui("calendar.season_cycle", "\nSeasons turn every {days} nights. Every festival returns each year.", {"days":str(game.calendar.days_per_season)}))
	lines.append(_format_localized_ui("calendar.controls", "\n{calendar} opens the calendar · {interact} interacts · {back} goes back.", {"calendar":_binding_label("calendar"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)

func _open_housekeeping_panel() -> void:
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "housekeeping"
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)
	_refresh_housekeeping_panel()

func _refresh_housekeeping_panel(message: String = "") -> void:
	var lines: Array[String] = [_localize_ui("housekeeping.heading", "MOONMART · LITTLE HOUSEKEEPING"), "", _format_localized_ui("housekeeping.cleanliness", "Cleanliness · {value}%", {"value":str(roundi(game.shop_progression.cleanliness))}), _localize_ui("housekeeping.description", "A tidy shop can attract a few more wandering neighbours.")]
	for index in range(CLEANING_ACTION_IDS.size()):
		var action_id := CLEANING_ACTION_IDS[index]
		var done := game.cleaning_action_done(action_id)
		var improvement := float(game.shop_progression.cleanliness_config.get("actions", {}).get(action_id, 0.0))
		lines.append("\n%d   %s  ·  +%d%%%s" % [index + 1, _localize_ui("housekeeping.action.%s" % action_id, CLEANING_ACTION_NAMES[index]), roundi(improvement), _localize_ui("housekeeping.done", "  ✓ tonight") if done else ""])
	lines.append("\n\n" + _localize_ui("housekeeping.prompt", "Choose a small task. Nothing is lost if you leave it for another night."))
	lines.append(_format_localized_ui("housekeeping.controls", "{housekeeping} opens housekeeping · {interact} interacts · {back} goes back.", {"housekeeping":_binding_label("housekeeping"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	if not message.is_empty():
		lines.append("\n" + message)
	side_label.text = "\n".join(lines)

func _open_companion_panel() -> void:
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "companion"
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)
	_refresh_companion_panel()

func _open_dream_panel() -> void:
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "dream"
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)
	_refresh_dream_panel()

func _refresh_dream_panel(response: String = "") -> void:
	var beat: Dictionary = game.miso_dream_sequence.current_beat()
	var title_id := String(beat.get("title_id", "companion.dream.heading"))
	var text_id := String(beat.get("text_id", "companion.dream.empty"))
	var lines: Array[String] = [_localize_ui("companion.dream.heading", "A DREAM WITH MISO"), "", _localize_ui(title_id, "A familiar place"), _localize_ui(text_id, "The dream rests quietly around you.")]
	if not response.is_empty():
		lines.append("\n" + response)
	if game.miso_dream_sequence.ready_to_wake:
		lines.append("\n" + _format_localized_ui("companion.dream.wake_prompt", "{interact}  Wake gently", {"interact":_binding_label("interact")}))
	else:
		var choices: Array = beat.get("choices", [])
		for index in range(choices.size()):
			var choice: Dictionary = choices[index]
			var key := _binding_label("ui_select_%d" % (index + 1))
			lines.append("\n%s   %s" % [key, _localize_ui(String(choice.get("label_id", "")), "Follow the dream")])
		lines.append("\n" + _localize_ui("companion.dream.suspend_hint", "You can step away and return to this dream later."))
	side_label.text = "\n".join(lines)

func _refresh_companion_panel(message: String = "") -> void:
	var companion = game.miso_companion
	var care_ids := ["feed", "pet", "brush", "play"]
	var care_fallbacks := ["Offer a little food", "Pet Miso", "Brush Miso", "Play with the felt moon"]
	var lines: Array[String] = [_localize_ui("companion.heading", "MISO · COMPANION CARE"), "", _format_localized_ui("companion.mood", "Mood · {mood}     Happiness · {value} / 100", {"mood":_localize_ui("companion.mood.%s" % companion.mood_id, companion.mood_id.replace("_", " ").capitalize()), "value":str(companion.happiness)}), _format_localized_ui("companion.favorite_toy", "Favorite toy · {name}", {"name":_localize_ui("companion.toy.%s" % companion.favorite_toy, String(companion.toy_definitions.get(companion.favorite_toy, {}).get("name", companion.favorite_toy)))}), _format_localized_ui("companion.resting_place", "Preferred resting place · {name}", {"name":_localize_ui("companion.sleep.%s" % companion.preferred_sleep_spot, String(companion.sleep_spots.get(companion.preferred_sleep_spot, {}).get("name", companion.preferred_sleep_spot)))})]
	for index in range(care_ids.size()):
		lines.append("\n%s   %s" % [_binding_label("ui_select_%d" % (index + 1)), _localize_ui("companion.care.%s" % care_ids[index], care_fallbacks[index])])
	lines.append(_format_localized_ui("companion.choose_rest", "\n{key}   Choose a resting place", {"key":_binding_label("move_down")}))
	lines.append("\n" + _localize_ui("companion.abilities_heading", "Miso's story abilities"))
	var ability_ids := ["spirit_sense", "hidden_paw", "dreamwalking", "memory_echo", "guardian_purr"]
	for index in range(ability_ids.size()):
		var ability_id: String = ability_ids[index]
		var definition: Dictionary = companion.ability_definitions.get(ability_id, {})
		var state := _localize_ui("companion.ready", "ready") if companion.ability_available(ability_id) else _localize_ui("companion.not_yet", "not yet")
		if ability_id == "dreamwalking" and game.miso_dream_sequence.active:
			state = _localize_ui("companion.dream.resume", "resume")
		lines.append("%d   %s  ·  %s" % [index + 5, _localize_ui("companion.ability.%s" % ability_id, String(definition.get("name", ability_id.replace("_", " ").capitalize()))), state])
	var moonlight_state := _format_localized_ui("companion.moonlight_active", "active · {key} reveals hidden writing", {"key":_binding_label("inspect")}) if companion.ability_available("moonlight_perception") else _localize_ui("companion.not_yet", "not yet")
	lines.append(_format_localized_ui("companion.moonlight", "Moonlight Perception  ·  {state}", {"state":moonlight_state}))
	lines.append("\n" + _localize_ui("companion.daily_limit", "Care actions and abilities can each be used once per night. Nothing bad happens if you skip them."))
	lines.append(_format_localized_ui("companion.controls", "{companion} opens companion care · {interact} interacts · {back} goes back.", {"companion":_binding_label("companion"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	if not message.is_empty():
		lines.append("\n" + message)
	side_label.text = "\n".join(lines)

func _localized_companion_ability_message(ability_id: String, result: Dictionary) -> String:
	var fallback := String(result.get("message", "Miso watches the room quietly."))
	if ability_id == "hidden_paw":
		var clue_id := String(result.get("clue_id", ""))
		if clue_id.is_empty():
			return _localize_ui("companion.response.ability.hidden_paw.waiting", fallback)
		var clue: Dictionary = game.story.clue_definitions.get(clue_id, {})
		var clue_text := _localize_ui("clue.%s.text" % clue_id, String(clue.get("text", clue_id.replace("_", " "))))
		return _format_localized_ui("companion.response.ability.hidden_paw.found", "Miso points toward a detail you may have missed: {clue}. Follow the marker and inspect it.", {"clue":clue_text})
	if ability_id == "spirit_sense":
		var visitor_suffix := ". The cat senses a visitor from the Between."
		var visitor_prefix := "Miso's ears turn toward "
		if fallback.begins_with(visitor_prefix) and fallback.ends_with(visitor_suffix):
			var visitor_name := fallback.substr(visitor_prefix.length(), fallback.length() - visitor_prefix.length() - visitor_suffix.length())
			return _format_localized_ui("companion.response.ability.spirit_sense.visitor", "Miso's ears turn toward {visitor}. The cat senses a visitor from the Between.", {"visitor":visitor_name})
		return _localize_ui("companion.response.ability.spirit_sense.empty", fallback)
	if ability_id == "memory_echo":
		var echo_title := _localize_ui(String(result.get("memory_echo_title_id", "")), "A remembered moment")
		var echo_text := _localize_ui(String(result.get("memory_echo_text_id", "")), fallback)
		return _format_localized_ui("companion.response.ability.memory_echo.revealed", "{title}\n{fragment}", {"title":echo_title, "fragment":echo_text})
	if ability_id == "guardian_purr":
		var anomaly_message_id := String(result.get("stabilized_anomaly_message_id", ""))
		var anomaly_text := _localize_ui(anomaly_message_id, "a lingering disturbance")
		return _format_localized_ui("companion.response.ability.guardian_purr.stabilized", "Miso's purr settles the disturbance: {anomaly}", {"anomaly":anomaly_text})
	return _localize_ui("companion.response.ability.%s" % ability_id, fallback)

func _open_radio_panel() -> void:
	if not game.shop_progression.has_upgrade("shop_radio"):
		status_label.text = _localize_ui("radio.unavailable_locked", "Moonmart could use a little radio. Look in Shop Improvements between shifts.")
		return
	if current_location_id != "moonmart":
		status_label.text = _localize_ui("radio.unavailable_location", "The Moonmart radio only reaches the shop.")
		return
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "radio"
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)
	_refresh_radio_panel()

func _refresh_radio_panel() -> void:
	var lines: Array[String] = [_localize_ui("radio.heading", "MOONMART RADIO · STATIONS"), "", _localize_ui("radio.description", "Choose a station. The shop's quiet room ambience continues beneath the broadcast.")]
	for index in range(RADIO_STATIONS.size()):
		var station: Dictionary = RADIO_STATIONS[index]
		var station_id := String(station.get("id", ""))
		var selected := _localize_ui("radio.now_playing", "  · now playing") if index == radio_station_index and radio_player != null and radio_player.playing else ""
		lines.append("\n%d   %s  ·  %s%s" % [index + 1, _localize_ui("radio.station.%s.name" % station_id, String(station.get("name", "Radio station"))), _localize_ui("radio.station.%s.detail" % station_id, String(station.get("detail", "A quiet broadcast"))), selected])
	lines.append(_format_localized_ui("radio.controls", "\nTune with {one}, {two}, or {three} · {back} closes radio.", {"one":_binding_label("ui_select_1"), "two":_binding_label("ui_select_2"), "three":_binding_label("ui_select_3"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)

func _open_upgrades_panel() -> void:
	if game.shift_status == "open":
		status_label.text = _localize_ui("upgrade.unavailable_open_shift", "Shop upgrades are available between shifts.")
		return
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	active_panel = "upgrades"
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)
	_refresh_upgrades_panel()

func _refresh_upgrades_panel(message: String = "") -> void:
	upgrade_ids.clear()
	var tier: Dictionary = game.shop_progression.current_reputation_tier()
	var lines: Array[String] = [_localize_ui("upgrade.heading", "MOONMART · SHOP IMPROVEMENTS"), "", _format_localized_ui("upgrade.reputation", "Reputation · {value}  ·  {tier}", {"value":str(game.shop_progression.reputation), "tier":_localize_ui("reputation_tier.%s" % String(tier.get("id", "little_corner_shop")), String(tier.get("name", "Little Corner Shop")))}), _format_localized_ui("upgrade.harmony", "Midnight Harmony · {value} / 100", {"value":str(game.shop_progression.harmony)}), ""]
	for upgrade in game.available_upgrades():
		if upgrade_ids.size() >= 5:
			break
		var upgrade_id := String(upgrade.get("id", ""))
		upgrade_ids.append(upgrade_id)
		var currency := _localize_ui("currency.moon_tokens", "Moon Tokens") if upgrade.get("currency", "coins") == "moon_tokens" else _localize_ui("currency.coins", "Coins")
		lines.append("%d   %s  ·  %d %s\n      %s" % [upgrade_ids.size(), _localize_ui("upgrade.%s.name" % upgrade_id, String(upgrade.get("name", upgrade_id))), upgrade.get("cost", 0), currency, _localize_ui("upgrade.%s.description" % upgrade_id, String(upgrade.get("description", "A small shop improvement.")))])
	if upgrade_ids.is_empty():
		lines.append(_localize_ui("upgrade.empty", "No improvements are available yet. Keep welcoming neighbours and caring for Moonmart."))
	lines.append(_format_localized_ui("upgrade.controls", "\n\n{selection} purchases an improvement · {upgrades} opens upgrades · {back} goes back.", {"selection":_selection_hint(mini(5, upgrade_ids.size())), "upgrades":_binding_label("upgrades"), "back":_binding_label("ui_back")}))
	if not message.is_empty():
		lines.append("\n" + message)
	side_label.text = "\n".join(lines)

func _configure_decoration_access() -> void:
	# Shop placement anchors and fixtures belong only to the retail layout.
	# Saves from other locations still keep their own room-keyed layouts.
	game.decoration.set_room("moonmart")
	# Interaction anchors are protected placement cells. Static collision cells
	# stay separate so a fixture remains reachable from the clear side.
	var access := {
		"spawn": Vector2i(12, 8), "exit": Vector2i(22, 6),
		"register": Vector2i(17, 6), "shelf": Vector2i(2, 6),
		"fridge": Vector2i(7, 6), "coffee_machine": Vector2i(8, 7), "tea_counter": Vector2i(10, 7),
		"kettle": Vector2i(12, 7), "microwave": Vector2i(14, 7),
		"sandwich_station": Vector2i(16, 8), "bakery_warmer": Vector2i(19, 7),
		"window": Vector2i(11, 6), "journal": Vector2i(20, 6),
		"back_door": Vector2i(22, 5), "miso": Vector2i(19, 7), "cat_bed": Vector2i(20, 9)
	}
	game.decoration.set_fixed_obstacles(SHOP_FIXED_FURNITURE_CELLS)
	game.decoration.access_points = access.duplicate(true)
	# Normalize existing saves against the static room collision and protected
	# cells. Invalid old placements are relocated to the nearest legal cell.
	game.decoration.import_state(game.decoration.export_state())

func _configure_decoration_room_access() -> void:
	if current_location_id == "moonmart":
		_configure_decoration_access()
	elif current_location_id == "shop_backroom":
		# Preserve clear approaches to the storage shelves, delivery point, trolley,
		# and door while allowing the backroom to have its own decor layout.
		game.decoration.set_fixed_obstacles([])
		game.decoration.access_points = {
			"spawn": Vector2i(1, 9), "exit": Vector2i(12, 7),
			"supply_shelves": Vector2i(5, 0), "delivery_crates": Vector2i(13, 7),
			"hand_trolley": Vector2i(18, 8)
		}
		game.decoration.import_state(game.decoration.export_state())
	elif current_location_id in ["reading_nook", "enchanted_greenhouse"]:
		if current_location_id == "reading_nook":
			var reading_obstacles: Array[Vector2i] = []
			for x in range(3, 7):
				reading_obstacles.append(Vector2i(x, 6))
				reading_obstacles.append(Vector2i(x, 7))
				if x != 5:
					reading_obstacles.append(Vector2i(x, 8))
			for x in range(9, 13):
				for y in range(6, 9):
					reading_obstacles.append(Vector2i(x, y))
			for x in range(18, 22):
				for y in range(6, 9):
					if not (x == 19 and y == 8):
						reading_obstacles.append(Vector2i(x, y))
			for x in range(14, 17):
				for y in range(6, 9):
					reading_obstacles.append(Vector2i(x, y))
			game.decoration.set_fixed_obstacles(reading_obstacles)
			game.decoration.access_points = {
				"spawn": Vector2i(1, 9), "exit": Vector2i(1, 8),
				"reading_chair": Vector2i(11, 9), "reading_shelves": Vector2i(5, 8),
				"reading_shelves_right": Vector2i(19, 8), "botanical_stand": Vector2i(15, 9)
			}
		else:
			var greenhouse_obstacles: Array[Vector2i] = []
			for x in range(3, 7):
				greenhouse_obstacles.append(Vector2i(x, 6))
				if x != 5:
					greenhouse_obstacles.append(Vector2i(x, 7))
					greenhouse_obstacles.append(Vector2i(x, 8))
			for x in range(8, 13):
				for y in range(6, 9):
					greenhouse_obstacles.append(Vector2i(x, y))
			for x in range(13, 16):
				for y in range(6, 9):
					if not (x == 14 and y == 8):
						greenhouse_obstacles.append(Vector2i(x, y))
			for x in range(17, 22):
				for y in range(2, 7):
					greenhouse_obstacles.append(Vector2i(x, y))
			for x in range(18, 22):
				for y in range(6, 9):
					greenhouse_obstacles.append(Vector2i(x, y))
			game.decoration.set_fixed_obstacles(greenhouse_obstacles)
			game.decoration.access_points = {
				"spawn": Vector2i(1, 9), "exit": Vector2i(22, 8),
				"propagation_shelf": Vector2i(5, 7), "seedling_shelf": Vector2i(19, 9),
				"watering_station": Vector2i(14, 8), "moonflower_trellis": Vector2i(10, 9)
			}
		game.decoration.import_state(game.decoration.export_state())

func _decoration_room_supported() -> bool:
	return current_location_id in ["moonmart", "shop_backroom", "reading_nook", "enchanted_greenhouse"]

func _refresh_decoration_transient_access() -> void:
	if game == null or game.decoration == null:
		return
	if active_panel != "decorate" or not _decoration_room_supported():
		game.decoration.set_transient_access_points([])
		return
	var protected_cells: Array[Vector2i] = []
	if player_body != null:
		protected_cells.append(_shop_cell_for_point(player_body.position))
	if current_location_id == "moonmart":
		for visitor_id in customer_visuals:
			var visitor_visual: Sprite2D = customer_visuals[visitor_id]
			if visitor_visual.visible:
				protected_cells.append(_shop_cell_for_point(visitor_visual.position))
	game.decoration.set_transient_access_points(protected_cells)

func _decoration_render_layer() -> Node2D:
	if current_location_id in ["shop_backroom", "reading_nook", "enchanted_greenhouse"] and current_location_scene != null:
		return current_location_scene.get_node_or_null("RoomDecorationLayer") as Node2D
	return foreground_furniture_layer

func _open_decoration_panel() -> void:
	_hide_product_detail_icon()
	active_panel = "decorate"
	decoration_ids.clear()
	for furniture_id in game.decoration.furniture:
		var furniture: Dictionary = game.decoration.furniture[furniture_id]
		if not bool(furniture.get("essential", false)):
			decoration_ids.append(String(furniture_id))
	decoration_ids.sort()
	if selected_decoration_id.is_empty() or not decoration_ids.has(selected_decoration_id):
		selected_decoration_id = decoration_ids[0] if not decoration_ids.is_empty() else ""
	decoration_page = int(decoration_ids.find(selected_decoration_id) / 4) if not selected_decoration_id.is_empty() else 0
	decoration_rotated = false
	decoration_cursor = Vector2i(12, 8)
	decoration_cursor_offset = Vector2.ZERO
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)
	_refresh_decoration_panel()
	_update_decoration_preview()

func _refresh_decoration_panel(message: String = "") -> void:
	var room_name := _localize_ui("decorate.room.backroom", "BACKROOM") if current_location_id == "shop_backroom" else _localize_ui("decorate.room.moonmart", "MOONMART")
	var lines: Array[String] = [_format_localized_ui("decorate.heading", "{room} · ORGANIZE", {"room":room_name}), "", _localize_ui("decorate.prompt", "Select a piece, move its preview, then place it. Small decor can be nudged freely; its floor space stays protected.")]
	var page_count := maxi(1, ceili(float(decoration_ids.size()) / 4.0))
	decoration_page = clampi(decoration_page, 0, page_count - 1)
	var page_start := decoration_page * 4
	for slot in range(mini(4, decoration_ids.size() - page_start)):
		var furniture_id := decoration_ids[page_start + slot]
		var furniture: Dictionary = game.decoration.furniture[furniture_id]
		var marker := "›" if furniture_id == selected_decoration_id else " "
		lines.append("\n%d %s %s   %s" % [slot + 1, marker, _localized_furniture_name(furniture_id, String(furniture.get("name", furniture_id))), _furniture_footprint_text(furniture)])
	var rotation := _localize_ui("decorate.rotation.rotated", "rotated") if decoration_rotated else _localize_ui("decorate.rotation.default", "default")
	var offset_x_text := str(snappedf(decoration_cursor_offset.x, 0.01))
	var offset_y_text := str(snappedf(decoration_cursor_offset.y, 0.01))
	if decoration_cursor_offset.x >= 0.0: offset_x_text = "+" + offset_x_text
	if decoration_cursor_offset.y >= 0.0: offset_y_text = "+" + offset_y_text
	var cursor_offset_label := _format_localized_ui("decorate.cursor.offset", "free offset {x}, {y}", {"x":offset_x_text, "y":offset_y_text}) if game.decoration.supports_free_visual_placement(selected_decoration_id) else _localize_ui("decorate.cursor.grid_aligned", "grid aligned")
	lines.append(_format_localized_ui("decorate.cursor", "\n\nCursor · {x}, {y}   ·   {offset}   ·   {rotation}", {"x":str(decoration_cursor.x + 1), "y":str(decoration_cursor.y + 1), "offset":cursor_offset_label, "rotation":rotation}))
	lines.append(_format_localized_ui("decorate.page", "Page {page} / {pages} · {previous} / {next} change page", {"page":str(decoration_page + 1), "pages":str(page_count), "previous":_binding_label("page_previous"), "next":_binding_label("page_next")}))
	lines.append(_format_localized_ui("decorate.controls", "Mouse places small decor freely · {up} / {left} / {down} / {right} nudge and cross cells · Shift + arrows jump a cell · {rotate} rotate · {place} place · {remove} remove · {close} closes", {"up":_binding_label("move_up"), "left":_binding_label("move_left"), "down":_binding_label("move_down"), "right":_binding_label("move_right"), "rotate":_binding_label("decoration_rotate"), "place":_binding_label("interact"), "remove":_binding_label("decoration_remove"), "close":_binding_label("decorate")}))
	lines.append(_localize_ui("decorate.walkway", "Keep the room's entrances and work areas clear; every placed piece must leave a walkable route."))
	if not message.is_empty():
		lines.append("\n" + message)
	side_label.text = "\n".join(lines)

func _furniture_footprint_text(furniture: Dictionary) -> String:
	var raw: Array = furniture.get("footprint", [1, 1])
	if raw.size() < 2:
		return "1×1"
	var width := int(raw[1]) if decoration_rotated else int(raw[0])
	var height := int(raw[0]) if decoration_rotated else int(raw[1])
	return "%d×%d" % [width, height]

func _localized_furniture_name(furniture_id: String, fallback: String = "") -> String:
	var source_name := fallback if not fallback.is_empty() else furniture_id.replace("_", " ").capitalize()
	return _localize_ui("furniture.%s.name" % furniture_id, source_name)


func _handle_decoration_input(event: InputEvent) -> void:
	if game.decoration.supports_free_visual_placement(selected_decoration_id):
		if event is InputEventMouseMotion:
			if _set_decoration_cursor_from_world(get_global_mouse_position()):
				_refresh_decoration_panel()
				_update_decoration_preview()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton:
			var mouse_button := event as InputEventMouseButton
			if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
				if _set_decoration_cursor_from_world(get_global_mouse_position()):
					_place_decoration()
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("page_next") or event.is_action_pressed("page_previous"):
		var page_count := maxi(1, ceili(float(decoration_ids.size()) / 4.0))
		decoration_page = posmod(decoration_page + (1 if event.is_action_pressed("page_next") else -1), page_count)
		var page_start := decoration_page * 4
		if page_start < decoration_ids.size():
			selected_decoration_id = decoration_ids[page_start]
			decoration_cursor_offset = Vector2.ZERO
		_refresh_decoration_panel()
		_update_decoration_preview()
		get_viewport().set_input_as_handled()
		return
	var slot := _number_slot(event)
	var page_start := decoration_page * 4
	if slot >= 0 and slot < mini(4, decoration_ids.size() - page_start):
		selected_decoration_id = decoration_ids[page_start + slot]
		decoration_rotated = false
		decoration_cursor_offset = Vector2.ZERO
		_refresh_decoration_panel()
		_update_decoration_preview()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("decoration_rotate"):
		decoration_rotated = not decoration_rotated
		_refresh_decoration_panel()
		_update_decoration_preview()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("decoration_remove"):
		_remove_decoration_at_cursor()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("decorate") or event.is_action_pressed("ui_back") or event.is_action_pressed("pause"):
		_close_side_panel()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right") or event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		var direction := Vector2i(int(event.is_action_pressed("move_right")) - int(event.is_action_pressed("move_left")), int(event.is_action_pressed("move_down")) - int(event.is_action_pressed("move_up")))
		var key_event := event as InputEventKey
		var move_by_cell := key_event != null and key_event.shift_pressed
		if game.decoration.supports_free_visual_placement(selected_decoration_id) and not move_by_cell:
			var fine_step := 0.125
			var next_x := decoration_cursor_offset.x + float(direction.x) * fine_step
			var next_y := decoration_cursor_offset.y + float(direction.y) * fine_step
			if next_x > 0.45 and decoration_cursor.x < game.decoration.grid_size.x - 1:
				decoration_cursor.x += 1
				decoration_cursor_offset.x = -0.45
			else:
				decoration_cursor_offset.x = clampf(next_x, -0.45, 0.45)
			if next_x < -0.45 and decoration_cursor.x > 0:
				decoration_cursor.x -= 1
				decoration_cursor_offset.x = 0.45
			if next_y > 0.45 and decoration_cursor.y < game.decoration.grid_size.y - 1:
				decoration_cursor.y += 1
				decoration_cursor_offset.y = -0.45
			else:
				decoration_cursor_offset.y = clampf(next_y, -0.45, 0.45)
			if next_y < -0.45 and decoration_cursor.y > 0:
				decoration_cursor.y -= 1
				decoration_cursor_offset.y = 0.45
		else:
			decoration_cursor.x += direction.x
			decoration_cursor.y += direction.y
			decoration_cursor.x = clampi(decoration_cursor.x, 0, game.decoration.grid_size.x - 1)
			decoration_cursor.y = clampi(decoration_cursor.y, 0, game.decoration.grid_size.y - 1)
			if not game.decoration.supports_free_visual_placement(selected_decoration_id):
				decoration_cursor_offset = Vector2.ZERO
		_refresh_decoration_panel()
		_update_decoration_preview()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		_place_decoration()
		get_viewport().set_input_as_handled()

func _place_decoration() -> void:
	_refresh_decoration_transient_access()
	if selected_decoration_id.is_empty():
		_refresh_decoration_panel(_localize_ui("decorate.error.no_furniture", "No nonessential furniture is available."))
		return
	if _decoration_overlaps_shop_fixture(decoration_cursor, selected_decoration_id, decoration_rotated):
		_refresh_decoration_panel(_localize_ui("decorate.error.fixed_fixture", "That footprint overlaps a fixed room fixture. Choose another clear cell."))
		_update_decoration_preview()
		return
	var verdict: Dictionary = game.decoration.can_place(selected_decoration_id, decoration_cursor, decoration_rotated)
	if not bool(verdict.get("ok", false)):
		_refresh_decoration_panel(_decoration_rejection_message(String(verdict.get("reason", "invalid_placement"))))
		return
	var instance_id := "decor_%d" % (Time.get_ticks_usec())
	if not game.decoration.place(instance_id, selected_decoration_id, decoration_cursor, decoration_rotated):
		_refresh_decoration_panel(_localize_ui("decorate.error.route_clear", "That piece cannot be placed here. The required route stays clear."))
		return
	game.decoration.set_visual_offset(instance_id, decoration_cursor_offset)
	game.save_now()
	_sync_decoration_visuals()
	_layout_customer_visuals()
	_refresh_decoration_panel(_format_localized_ui("decorate.result.placed", "Placed {item}.", {"item":_localized_furniture_name(selected_decoration_id, String(game.decoration.furniture[selected_decoration_id].get("name", selected_decoration_id)))}))
	_update_decoration_preview()

func _remove_decoration_at_cursor() -> void:
	for instance_id in game.decoration.placed:
		var entry: Dictionary = game.decoration.placed[instance_id]
		var origin: Vector2i = entry.get("origin", Vector2i.ZERO)
		var furniture_id := String(entry.get("furniture_id", ""))
		var footprint := _decoration_footprint(furniture_id, bool(entry.get("rotated", false)))
		var cursor_inside := decoration_cursor.x >= origin.x and decoration_cursor.y >= origin.y and decoration_cursor.x < origin.x + footprint.x and decoration_cursor.y < origin.y + footprint.y
		if cursor_inside and game.decoration.remove(String(instance_id)):
			game.save_now()
			_sync_decoration_visuals()
			_layout_customer_visuals()
			_refresh_decoration_panel(_localize_ui("decorate.result.removed", "Removed the piece at the cursor."))
			_update_decoration_preview()
			return
	_refresh_decoration_panel(_localize_ui("decorate.error.nothing_to_remove", "There is no placed piece at this grid cell."))

func _decoration_rejection_message(reason: String) -> String:
	match reason:
		"overlap": return _localize_ui("decorate.error.overlap", "That space is occupied. Move the cursor to a clear cell.")
		"outside_room": return _localize_ui("decorate.error.outside_room", "That footprint would extend beyond the shop floor.")
		"blocks_required_interaction": return _localize_ui("decorate.error.required_access", "That would cover a required entrance, exit or checkout approach.")
		"blocks_navigation": return _localize_ui("decorate.error.navigation", "That would cut off the route between essential shop areas.")
	return _localize_ui("decorate.error.invalid", "That piece cannot be placed there. Choose another clear cell.")

func _decoration_cell_position(cell: Vector2i) -> Vector2:
	var size := Vector2(1600.0 / game.decoration.grid_size.x, 400.0 / game.decoration.grid_size.y)
	return Vector2((float(cell.x) + 0.5) * size.x, 400.0 + (float(cell.y) + 0.5) * size.y)

func _set_decoration_cursor_from_world(point: Vector2) -> bool:
	var grid_size: Vector2i = game.decoration.grid_size
	var cell_size := Vector2(1600.0 / grid_size.x, 400.0 / grid_size.y)
	if point.x < 0.0 or point.x >= cell_size.x * grid_size.x or point.y < 400.0 or point.y >= 400.0 + cell_size.y * grid_size.y:
		return false
	decoration_cursor = Vector2i(floori(point.x / cell_size.x), floori((point.y - 400.0) / cell_size.y))
	var relative := (point - _decoration_cell_position(decoration_cursor)) / cell_size
	decoration_cursor_offset = relative.clamp(Vector2(-0.45, -0.45), Vector2(0.45, 0.45))
	return true

func _decoration_footprint(furniture_id: String, rotated: bool) -> Vector2i:
	var raw: Array = game.decoration.furniture.get(furniture_id, {}).get("footprint", [1, 1])
	var footprint := Vector2i(int(raw[0]), int(raw[1])) if raw.size() >= 2 else Vector2i.ONE
	return Vector2i(footprint.y, footprint.x) if rotated else footprint

func _decoration_center(origin: Vector2i, furniture_id: String, rotated: bool) -> Vector2:
	var cell_size := Vector2(1600.0 / game.decoration.grid_size.x, 400.0 / game.decoration.grid_size.y)
	var footprint := _decoration_footprint(furniture_id, rotated)
	return Vector2((float(origin.x) + float(footprint.x) / 2.0) * cell_size.x, 400.0 + (float(origin.y) + float(footprint.y) / 2.0) * cell_size.y)

func _decoration_overlaps_shop_fixture(origin: Vector2i, furniture_id: String, rotated: bool) -> bool:
	var footprint := _decoration_footprint(furniture_id, rotated)
	for x in range(origin.x, origin.x + footprint.x):
		for y in range(origin.y, origin.y + footprint.y):
			if game.decoration.is_fixed_obstacle(Vector2i(x, y)):
				return true
	return false

func _decoration_texture_rect(furniture_id: String) -> Rect2:
	var texture_path := _decoration_texture_path(furniture_id)
	var definition: Dictionary = game.decoration.furniture.get(furniture_id, {}) if game != null else {}
	var visual: Dictionary = definition.get("visual", {})
	if texture_path != FURNITURE_PATH:
		if visual.has("atlas_cell"):
			var grid: Array = visual.get("atlas_grid", [1, 1])
			var cell: Array = visual.get("atlas_cell", [0, 0])
			if grid.size() >= 2 and cell.size() >= 2:
				return _grid_region(texture_path, int(cell[0]), int(cell[1]), int(grid[0]), int(grid[1]))
		var texture := load(texture_path) as Texture2D
		return Rect2(Vector2.ZERO, Vector2(texture.get_width(), texture.get_height()))
	match furniture_id:
		"pastry_case": return _grid_region(FURNITURE_PATH, 3, 0, 4, 2)
		"reading_chair": return _grid_region(FURNITURE_PATH, 2, 1, 4, 2)
		"moon_lantern": return _grid_region(FURNITURE_PATH, 1, 1, 4, 2)
		"flower_pot": return _grid_region(FURNITURE_PATH, 0, 1, 4, 2)
	return _grid_region(FURNITURE_PATH, 0, 1, 4, 2)

func _decoration_texture_path(furniture_id: String) -> String:
	if game == null:
		return FURNITURE_PATH
	var definition: Dictionary = game.decoration.furniture.get(furniture_id, {})
	var visual: Dictionary = definition.get("visual", {})
	return String(visual.get("path", FURNITURE_PATH))

func _decoration_sprite_scale(furniture_id: String, footprint: Vector2i) -> Vector2:
	var definition: Dictionary = game.decoration.furniture.get(furniture_id, {})
	var visual: Dictionary = definition.get("visual", {})
	if visual.has("path"):
		var native_scale := float(visual.get("scale", 0.08))
		return Vector2.ONE * native_scale
	return Vector2(0.24 * footprint.x, 0.24 * footprint.y)

func _decoration_anchor_offset(furniture_id: String, rotated: bool) -> Vector2:
	var definition: Dictionary = game.decoration.furniture.get(furniture_id, {})
	var visual: Dictionary = definition.get("visual", {})
	var anchor: Array = visual.get("anchor", [0.5, 0.95])
	if anchor.size() < 2:
		return Vector2.ZERO
	var footprint := _decoration_footprint(furniture_id, rotated)
	var sprite_size := _decoration_texture_rect(furniture_id).size * _decoration_sprite_scale(furniture_id, footprint)
	return Vector2((0.5 - float(anchor[0])) * sprite_size.x, (0.5 - float(anchor[1])) * sprite_size.y)

func _sync_decoration_visuals() -> void:
	for instance_id in decoration_visuals:
		var old_visual: Sprite2D = decoration_visuals[instance_id]
		if is_instance_valid(old_visual):
			old_visual.queue_free()
	decoration_visuals.clear()
	for instance_id in decoration_lights:
		var old_light: PointLight2D = decoration_lights[instance_id]
		if is_instance_valid(old_light):
			old_light.queue_free()
	decoration_lights.clear()
	if game == null:
		return
	var render_layer := _decoration_render_layer()
	if render_layer == null:
		return
	var lighting_layer := separate_lighting_layer
	if current_location_scene != null:
		lighting_layer = current_location_scene.get_node_or_null("SeparateLightingLayer") as Node2D
	for instance_id in game.decoration.placed:
		var entry: Dictionary = game.decoration.placed[instance_id]
		var furniture_id := String(entry.get("furniture_id", ""))
		var cell: Vector2i = entry.get("origin", Vector2i.ZERO)
		var rotated := bool(entry.get("rotated", false))
		var footprint := _decoration_footprint(furniture_id, rotated)
		var texture_path := _decoration_texture_path(furniture_id)
		var cell_size := Vector2(1600.0 / game.decoration.grid_size.x, 400.0 / game.decoration.grid_size.y)
		var visual_offset := game.decoration.visual_offset_in_cells(String(instance_id)) * cell_size
		var sprite_position := _decoration_center(cell, furniture_id, rotated) + _decoration_anchor_offset(furniture_id, rotated) + visual_offset
		var visual := _atlas_sprite(load(texture_path) as Texture2D, _decoration_texture_rect(furniture_id), _decoration_sprite_scale(furniture_id, footprint), sprite_position, "Decoration_" + String(instance_id), render_layer)
		visual.z_index = 21 + int(visual.position.y / 100.0)
		visuals_add(instance_id, visual)
		var attachment: Dictionary = game.decoration.furniture.get(furniture_id, {}).get("lighting_attachment", {})
		if String(attachment.get("kind", "")) == "point_light" and lighting_layer != null:
			var attachment_point: Array = attachment.get("point", [0.5, 0.5])
			if attachment_point.size() >= 2:
				var placed_fixture_light := PointLight2D.new()
				placed_fixture_light.name = "DecorationLight_" + String(instance_id)
				if decoration_light_texture == null:
					decoration_light_texture = _make_soft_light_texture()
				placed_fixture_light.texture = decoration_light_texture
				placed_fixture_light.texture_scale = 0.42
				placed_fixture_light.energy = 0.20
				placed_fixture_light.color = Color(1.0, 0.79, 0.54)
				placed_fixture_light.range_z_min = 20
				placed_fixture_light.range_z_max = 50
				placed_fixture_light.position = Vector2((float(cell.x) + float(attachment_point[0]) * footprint.x) * cell_size.x, 400.0 + (float(cell.y) + float(attachment_point[1]) * footprint.y) * cell_size.y) + visual_offset
				# The dedicated parent layer owns the accessibility toggle. Keep each
				# child light visible so lights added while the setting is off return
				# when that layer is enabled again.
				lighting_layer.add_child(placed_fixture_light)
				decoration_lights[String(instance_id)] = placed_fixture_light

func visuals_add(instance_id: Variant, visual: Sprite2D) -> void:
	decoration_visuals[String(instance_id)] = visual

func _update_decoration_preview() -> void:
	_refresh_decoration_transient_access()
	var render_layer := _decoration_render_layer()
	if render_layer == null or selected_decoration_id.is_empty():
		return
	var texture_path := _decoration_texture_path(selected_decoration_id)
	var texture_rect := _decoration_texture_rect(selected_decoration_id)
	if decoration_preview == null or not is_instance_valid(decoration_preview):
		decoration_preview = _atlas_sprite(load(texture_path) as Texture2D, texture_rect, Vector2(0.24, 0.24), Vector2.ZERO, "DecorationPreview", render_layer)
	elif decoration_preview.get_parent() != render_layer:
		decoration_preview.reparent(render_layer)
	decoration_preview.z_index = 60
	decoration_preview.texture = load(texture_path) as Texture2D
	decoration_preview.region_rect = texture_rect
	var cell_size := Vector2(1600.0 / game.decoration.grid_size.x, 400.0 / game.decoration.grid_size.y)
	var preview_offset := decoration_cursor_offset * cell_size if game.decoration.supports_free_visual_placement(selected_decoration_id) else Vector2.ZERO
	decoration_preview.position = _decoration_center(decoration_cursor, selected_decoration_id, decoration_rotated) + _decoration_anchor_offset(selected_decoration_id, decoration_rotated) + preview_offset
	var footprint := _decoration_footprint(selected_decoration_id, decoration_rotated)
	decoration_preview.scale = _decoration_sprite_scale(selected_decoration_id, footprint)
	var verdict: Dictionary = game.decoration.can_place(selected_decoration_id, decoration_cursor, decoration_rotated)
	var placement_ok := bool(verdict.get("ok", false)) and not _decoration_overlaps_shop_fixture(decoration_cursor, selected_decoration_id, decoration_rotated)
	decoration_preview.modulate = Color(0.52, 1.0, 0.63, 0.7) if placement_ok else Color(1.0, 0.40, 0.36, 0.72)
	decoration_preview.visible = active_panel == "decorate"

func _open_stock_panel(shelf_id: String) -> void:
	_hide_product_detail_icon()
	active_panel = "stock"
	stock_panel_mode = shelf_id
	stocked_product_ids.clear()
	stock_page = 0
	stock_selected_slot = 0
	var backroom_mode := shelf_id.begins_with("backroom_")
	var cold_only := shelf_id == "fridge"
	match shelf_id:
		"fridge": stock_category = _localize_ui("stock.category.chilled", "CHILLED GOODS")
		"backroom_storage": stock_category = _localize_ui("stock.category.storage", "BACKROOM STORAGE · SUPPLY SHELVES")
		"backroom_delivery": stock_category = _localize_ui("stock.category.delivery", "DELIVERY CRATES · SUPPLIER")
		"backroom_trolley": stock_category = _localize_ui("stock.category.trolley", "HAND TROLLEY · DISPLAY RESTOCK")
		_: stock_category = _localize_ui("stock.category.shelf", "SHELF GOODS")
	for id in game.inventory.products:
		var category := String(game.inventory.products[id].get("category", "everyday"))
		if backroom_mode or (category == "cold") == cold_only:
			stocked_product_ids.append(String(id))
	_refresh_stock_panel()
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)

func _open_checkout_panel() -> void:
	if game.customers.active.is_empty():
		game.interact("register")
		return
	var customer: Dictionary = {}
	for visitor in game.customers.active:
		if String(visitor.get("state", "")) in ["QUEUING", "CHECKOUT"]:
			customer = visitor
			break
	if customer.is_empty():
		status_label.text = _localize_ui("checkout.no_customer", "No one is at the register yet. Visitors browse before they join the queue.")
		return
	checkout_customer_id = String(customer.get("id", ""))
	game.customers.begin_checkout(checkout_customer_id)
	checkout_item_ids.clear()
	checkout_scanned.clear()
	checkout_phase = "scan"
	checkout_packing_choice_index = 0
	checkout_tender_choice_index = 0
	checkout_recommendation_choice_index = 0
	checkout_recommendation_resolved = false
	checkout_recommended_items.clear()
	checkout_recommendation_item_id = ""
	for product_id in customer.get("basket", {}):
		checkout_item_ids.append(String(product_id))
	checkout_cursor = 0
	var hospitality_rank := game.shop_progression.proficiency_rank("hospitality")
	if game.shop_progression.has_upgrade("scanner_assist"):
		checkout_scanned = customer.get("basket", {}).duplicate(true)
	elif hospitality_rank >= 2:
		var basket: Dictionary = customer.get("basket", {})
		for product_id in basket:
			checkout_scanned[String(product_id)] = mini(1, int(basket[product_id]))
			break
	active_panel = "checkout"
	_refresh_checkout_panel()
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(false)

func _open_environmental_puzzle(puzzle: Dictionary) -> void:
	active_environmental_puzzle_id = String(puzzle.get("id", ""))
	active_panel = "environmental_puzzle"
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	side_scroll.size = Vector2(440, 520)
	var solved := bool(puzzle.get("solved", false))
	puzzle_answer_input.visible = not solved
	puzzle_answer_input.placeholder_text = _localize_ui("puzzle.answer_placeholder", "Write what the clues suggest…")
	puzzle_answer_input.clear()
	var puzzle_id := active_environmental_puzzle_id
	var title := _localize_ui("puzzle.%s.title" % puzzle_id, String(puzzle.get("title", "A Small Mystery")))
	var prompt := _localize_ui("puzzle.%s.prompt" % puzzle_id, String(puzzle.get("prompt", "The details ask for a little thought.")))
	var lines: Array[String] = [title, "", prompt, ""]
	if solved:
		lines.append(_localize_ui("puzzle.%s.solved" % puzzle_id, String(puzzle.get("solved_message", "The details settle into place."))))
		lines.append(_format_localized_ui("puzzle.controls_solved", "\n{interact} interacts · {back} goes back.", {"interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	else:
		lines.append(_localize_ui("puzzle.instructions", "Take your time. A wrong answer only brings another hint."))
		lines.append(_format_localized_ui("puzzle.controls_submit", "\nType an answer and press {submit} to submit. {back} goes back.", {"submit":_binding_label("puzzle_submit"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)
	if not solved:
		puzzle_answer_input.grab_focus()

func _submit_environmental_answer(answer: String) -> void:
	if active_panel != "environmental_puzzle" or active_environmental_puzzle_id.is_empty():
		return
	var source_puzzle: Dictionary = game.environmental_puzzles.puzzle(active_environmental_puzzle_id, game.story.flags)
	var localized_answers := _localize_ui("puzzle.%s.accepted_answers" % active_environmental_puzzle_id, "").split("|", false)
	for localized_answer in localized_answers:
		if _normalize_puzzle_answer(answer) == _normalize_puzzle_answer(String(localized_answer)):
			var source_answers: Array = source_puzzle.get("accepted_answers", [])
			if not source_answers.is_empty():
				answer = String(source_answers[0])
			break
	var result: Dictionary = game.submit_environmental_puzzle(active_environmental_puzzle_id, answer)
	var puzzle: Dictionary = game.environmental_puzzles.puzzle(active_environmental_puzzle_id, game.story.flags)
	var puzzle_id := active_environmental_puzzle_id
	var title := _localize_ui("puzzle.%s.title" % puzzle_id, String(puzzle.get("title", "A Small Mystery")))
	var prompt := _localize_ui("puzzle.%s.prompt" % puzzle_id, String(puzzle.get("prompt", "The details ask for a little thought.")))
	var lines: Array[String] = [title, "", prompt, ""]
	if bool(result.get("ok", false)):
		lines.append(_localize_ui("puzzle.%s.solved" % puzzle_id, String(result.get("message", puzzle.get("solved_message", "The details settle into place.")))))
		var reward_text := _localize_ui("puzzle.%s.reward" % puzzle_id, String(result.get("reward_text", "")))
		if not reward_text.is_empty():
			lines.append("\n" + reward_text)
		lines.append(_format_localized_ui("puzzle.controls_solved", "\n{interact} interacts · {back} goes back.", {"interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
		puzzle_answer_input.release_focus()
		puzzle_answer_input.visible = false
	else:
		var hint_list: Array = puzzle.get("hints", [])
		var hint_index := clampi(int(result.get("attempts", 1)) - 1, 0, maxi(0, hint_list.size() - 1))
		var fallback_hint := String(result.get("message", "Look around and try another idea whenever you like."))
		lines.append(_localize_ui("puzzle.%s.hint.%d" % [puzzle_id, hint_index + 1], fallback_hint))
		lines.append(_format_localized_ui("puzzle.controls_retry", "\nTry another answer when you're ready. {back} goes back.", {"back":_binding_label("ui_back")}))
		puzzle_answer_input.clear()
		puzzle_answer_input.grab_focus()
	side_label.text = "\n".join(lines)

func _normalize_puzzle_answer(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	for accented in ["á", "à", "ä", "é", "è", "ë", "í", "ì", "ï", "ó", "ò", "ö", "ú", "ù", "ü", "ñ"]:
		var plain := "a" if accented in ["á", "à", "ä"] else ("e" if accented in ["é", "è", "ë"] else ("i" if accented in ["í", "ì", "ï"] else ("o" if accented in ["ó", "ò", "ö"] else ("u" if accented in ["ú", "ù", "ü"] else "n"))))
		normalized = normalized.replace(accented, plain)
	for punctuation in [".", ",", "!", "?", "'", "\"", ":", ";"]:
		normalized = normalized.replace(punctuation, "")
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	return normalized

func _scan_checkout_item(slot: int) -> void:
	if slot < 0 or slot >= checkout_item_ids.size():
		return
	var product_id := checkout_item_ids[slot]
	var basket := _checkout_target_basket()
	var scanned_count := int(checkout_scanned.get(product_id, 0))
	if scanned_count < int(basket.get(product_id, 0)):
		checkout_scanned[product_id] = scanned_count + 1
	checkout_cursor = slot
	_refresh_checkout_panel()

func _checkout_target_basket() -> Dictionary:
	var customer := game.customers.get_customer(checkout_customer_id)
	if customer.is_empty():
		return {}
	var target_basket: Dictionary = customer.get("basket", {}).duplicate(true)
	for product_id in checkout_recommended_items:
		target_basket[String(product_id)] = int(target_basket.get(String(product_id), 0)) + int(checkout_recommended_items[product_id])
	return target_basket

func _checkout_is_complete() -> bool:
	var customer := game.customers.get_customer(checkout_customer_id)
	if customer.is_empty():
		return false
	return checkout_scanned == _checkout_target_basket()

func _continue_checkout_after_scan() -> void:
	if not _checkout_is_complete():
		return
	if not checkout_recommendation_resolved:
		checkout_recommendation_resolved = true
		var recommendation: Dictionary = game.checkout_recommendation(checkout_customer_id)
		checkout_recommendation_item_id = String(recommendation.get("product_id", ""))
		var recommendation_items: Dictionary = {}
		if not checkout_recommendation_item_id.is_empty() and int(recommendation.get("count", 0)) == 1:
			recommendation_items[checkout_recommendation_item_id] = 1
		if not recommendation_items.is_empty() and game.checkout_recommendation_is_valid(checkout_customer_id, recommendation_items):
			checkout_recommendation_choice_index = CHECKOUT_RECOMMENDATION_CHOICES.find("skip")
			checkout_phase = "recommendation"
			_refresh_checkout_panel()
			return
	_enter_checkout_packing_phase()

func _resolve_checkout_recommendation(choice_id: String) -> void:
	if checkout_phase != "recommendation" or not CHECKOUT_RECOMMENDATION_CHOICES.has(choice_id) or checkout_recommendation_item_id.is_empty() or not _checkout_is_complete():
		return
	if choice_id == "offer":
		var recommendation_items: Dictionary = {}
		recommendation_items[checkout_recommendation_item_id] = 1
		if not game.checkout_recommendation_is_valid(checkout_customer_id, recommendation_items):
			checkout_recommendation_item_id = ""
			_enter_checkout_packing_phase()
			return
		checkout_recommended_items[checkout_recommendation_item_id] = 1
		if not checkout_item_ids.has(checkout_recommendation_item_id):
			checkout_item_ids.append(checkout_recommendation_item_id)
		if assisted_checkout_enabled:
			checkout_scanned = _checkout_target_basket()
			_continue_checkout_after_scan()
			return
		checkout_phase = "scan"
		checkout_cursor = checkout_item_ids.find(checkout_recommendation_item_id)
		_refresh_checkout_panel()
		return
	checkout_recommendation_item_id = ""
	_enter_checkout_packing_phase()

func _enter_checkout_packing_phase() -> void:
	var customer := game.customers.get_customer(checkout_customer_id)
	if customer.is_empty() or not _checkout_is_complete():
		return
	checkout_phase = "packing"
	var preferred_choice := String(customer.get("packing_preference", "paper"))
	var preferred_index := CHECKOUT_PACKING_CHOICES.find(preferred_choice)
	checkout_packing_choice_index = maxi(0, preferred_index)
	_refresh_checkout_panel()

func _advance_checkout_after_packing(choice_id: String) -> void:
	if checkout_phase != "packing" or not CHECKOUT_PACKING_CHOICES.has(choice_id) or not _checkout_is_complete():
		return
	var customer := game.customers.get_customer(checkout_customer_id)
	if String(customer.get("payment_currency", "coins")) != "moon_tokens":
		checkout_packing_choice_index = CHECKOUT_PACKING_CHOICES.find(choice_id)
		checkout_phase = "payment"
		checkout_tender_choice_index = 0
		_refresh_checkout_panel()
		return
	_finish_checkout_sale(choice_id, "moon_tokens")

func _finish_checkout_payment(tender_id: String) -> void:
	if checkout_phase != "payment" or not CHECKOUT_TENDER_CHOICES.has(tender_id) or not _checkout_is_complete():
		return
	var choice_id: String = CHECKOUT_PACKING_CHOICES[checkout_packing_choice_index]
	_finish_checkout_sale(choice_id, tender_id)

func _finish_checkout_sale(packing_choice: String, payment_tender: String) -> void:
	if not _checkout_is_complete():
		return
	var customer_to_finish := checkout_customer_id
	var scan_copy := checkout_scanned.duplicate(true)
	var recommendation_copy := checkout_recommended_items.duplicate(true)
	_close_side_panel()
	game.checkout_scanned(customer_to_finish, scan_copy, packing_choice, payment_tender, recommendation_copy)

func _refresh_checkout_panel() -> void:
	var customer := game.customers.get_customer(checkout_customer_id)
	if customer.is_empty():
		_hide_product_detail_icon()
		side_label.text = _format_localized_ui("checkout.customer_left", "CHECKOUT\n\nThe customer stepped away. Press {back} to close.", {"back":_binding_label("ui_back")})
		return
	if checkout_phase == "recommendation" and not checkout_recommendation_item_id.is_empty():
		_refresh_product_detail_icon(checkout_recommendation_item_id)
	elif checkout_phase != "packing" and checkout_item_ids.size() > 0:
		var icon_id := checkout_item_ids[clampi(checkout_cursor, 0, checkout_item_ids.size() - 1)]
		_refresh_product_detail_icon(icon_id)
	else:
		_hide_product_detail_icon()
	var basket := _checkout_target_basket()
	var lines: Array[String] = [_localize_ui("checkout.header", "A CUSTOMER AT THE COUNTER"), _format_localized_ui("checkout.basket", "{name}'s basket", {"name":String(customer.get("name", "Visitor"))}) + "\n"]
	var total := 0
	for i in range(checkout_item_ids.size()):
		var product_id := checkout_item_ids[i]
		var product: Dictionary = game.inventory.products.get(product_id, {})
		var needed := int(basket.get(product_id, 0))
		var scanned := int(checkout_scanned.get(product_id, 0))
		total += game.inventory.price_for(product_id) * needed
		var cursor := "›" if i == checkout_cursor else " "
		lines.append("%s %d   %s   %s" % [cursor, i + 1, _localized_product_name(product_id, String(product.get("name", product_id))), _format_localized_ui("checkout.scan_count", "Scanned {scanned} / {needed}", {"scanned":scanned, "needed":needed})])
	var payment_currency := String(customer.get("payment_currency", "coins"))
	var currency_label := _localize_ui("currency.moon_tokens", "Moon Tokens") if payment_currency == "moon_tokens" else _localize_ui("currency.coins", "Coins")
	lines.append(_format_localized_ui("checkout.total", "\nTotal · {total} {currency}", {"total":total, "currency":currency_label}))
	if checkout_phase == "recommendation":
		var suggested_product: Dictionary = game.inventory.products.get(checkout_recommendation_item_id, {})
		var suggested_name := _localized_product_name(checkout_recommendation_item_id, String(suggested_product.get("name", checkout_recommendation_item_id)))
		var suggested_currency := _localize_ui("currency.moon_tokens", "Moon Tokens") if payment_currency == "moon_tokens" else _localize_ui("currency.coins", "Coins")
		var selected_recommendation: String = CHECKOUT_RECOMMENDATION_CHOICES[checkout_recommendation_choice_index]
		lines.append(_localize_ui("checkout.recommendation.heading", "A SMALL SUGGESTION"))
		lines.append(_format_localized_ui("checkout.recommendation.prompt", "You could suggest {product} for {price} {currency}.", {"product":suggested_name, "price":str(game.inventory.price_for(checkout_recommendation_item_id)), "currency":suggested_currency}))
		for index in range(CHECKOUT_RECOMMENDATION_CHOICES.size()):
			var option_id: String = CHECKOUT_RECOMMENDATION_CHOICES[index]
			var marker := "›" if option_id == selected_recommendation else " "
			var option_label := _localize_ui("checkout.recommendation.option.%s" % option_id, option_id.capitalize())
			lines.append("%s %d   %s" % [marker, index + 1, option_label])
		lines.append(_format_localized_ui("checkout.recommendation.controls", "\n{selection} choose · {left} / {right} select · {interact} confirms · {back} goes back", {"selection":_selection_hint(CHECKOUT_RECOMMENDATION_CHOICES.size()), "left":_binding_label("move_left"), "right":_binding_label("move_right"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
		lines.append(_localize_ui("checkout.patient", "Take your time; there is no impatience penalty."))
	elif checkout_phase == "packing":
		var preference := String(customer.get("packing_preference", "paper"))
		var selected_choice: String = CHECKOUT_PACKING_CHOICES[checkout_packing_choice_index]
		lines.append(_localize_ui("checkout.packing.heading", "PACKING"))
		lines.append(_localize_ui("checkout.packing.preference.%s" % preference, "They'd prefer a paper bag."))
		for index in range(CHECKOUT_PACKING_CHOICES.size()):
			var option_id: String = CHECKOUT_PACKING_CHOICES[index]
			var marker := "›" if option_id == selected_choice else " "
			var option_label := _localize_ui("checkout.packing.option.%s" % option_id, option_id.capitalize())
			lines.append("%s %d   %s" % [marker, index + 1, option_label])
		lines.append(_format_localized_ui("checkout.packing.controls", "\n{selection} packs now · {left} / {right} choose style · {interact} confirms · {back} goes back", {"selection":_selection_hint(CHECKOUT_PACKING_CHOICES.size()), "left":_binding_label("move_left"), "right":_binding_label("move_right"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
		lines.append(_localize_ui("checkout.patient", "Take your time; there is no impatience penalty."))
	elif checkout_phase == "payment":
		lines.append(_localize_ui("checkout.payment.heading", "PAYMENT · COINS"))
		lines.append(_localize_ui("checkout.payment.prompt", "Choose how the customer pays."))
		for index in range(CHECKOUT_TENDER_CHOICES.size()):
			var tender_id: String = CHECKOUT_TENDER_CHOICES[index]
			var marker := "›" if index == checkout_tender_choice_index else " "
			var tender_label := _localize_ui("checkout.payment.option.%s" % tender_id, tender_id.capitalize())
			lines.append("%s %d   %s" % [marker, index + 1, tender_label])
		lines.append(_format_localized_ui("checkout.payment.controls", "\n{selection} choose · {left} / {right} select · {interact} confirms · {back} goes back", {"selection":_selection_hint(CHECKOUT_TENDER_CHOICES.size()), "left":_binding_label("move_left"), "right":_binding_label("move_right"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
		lines.append(_localize_ui("checkout.patient", "Take your time; there is no impatience penalty."))
	else:
		lines.append(_format_localized_ui("checkout.controls", "\n{selection} scans directly · {left} / {right} choose item · {interact} scans / packs", {"selection":_selection_hint(mini(5, checkout_item_ids.size())), "left":_binding_label("move_left"), "right":_binding_label("move_right"), "interact":_binding_label("interact")}))
		lines.append("\n" + (_localize_ui("checkout.packing.next", "Basket complete. Press {interact} to continue checkout.").format({"interact":_binding_label("interact")}) if _checkout_is_complete() else _localize_ui("checkout.patient", "Take your time; there is no impatience penalty.")))
		if String(customer.get("payment_currency", "coins")) == "moon_tokens":
			lines.append(_localize_ui("checkout.payment.automatic", "This supernatural exchange settles automatically in Moon Tokens after packing."))
	side_label.text = "\n".join(lines)

func _open_craft_panel(station_id: String = "magical_kettle") -> void:
	_hide_product_detail_icon()
	active_panel = "craft"
	active_craft_station_id = station_id
	craft_page = 0
	craft_experiment_selected.clear()
	_refresh_craft_recipe_ids()
	_refresh_craft_experiment_ingredients()
	_refresh_craft_panel()
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)

func _refresh_craft_recipe_ids() -> void:
	available_recipe_ids.clear()
	for recipe in game.available_recipes(active_craft_station_id):
		available_recipe_ids.append(String(recipe.get("id", "")))

func _refresh_craft_experiment_ingredients() -> void:
	craft_experiment_ingredient_ids = game.experimentable_ingredient_ids(active_craft_station_id)

func _craft_recipe_page_count() -> int:
	return maxi(1, int(ceil(float(available_recipe_ids.size()) / 5.0)))

func _craft_experiment_page_count() -> int:
	return maxi(1, int(ceil(float(craft_experiment_ingredient_ids.size()) / 5.0)))

func _craft_total_page_count() -> int:
	return _craft_recipe_page_count() + _craft_experiment_page_count()

func _craft_page_is_experiment() -> bool:
	return craft_page >= _craft_recipe_page_count()

func _submit_craft_experiment() -> void:
	if craft_experiment_selected.is_empty():
		status_label.text = _localize_ui("craft.experiment.result.no_ingredients", "Choose at least one ingredient to try.")
		return
	var result: Dictionary = game.experiment_recipe(active_craft_station_id, craft_experiment_selected.duplicate(true))
	if bool(result.get("ok", false)):
		var recipe_id := String(result.get("recipe_id", ""))
		var output_id := String(result.get("output_product_id", ""))
		var recipe_name := _localized_recipe_name(recipe_id, String(result.get("name", recipe_id)))
		var output_name := _localized_product_name(output_id, "finished goods")
		status_label.text = _format_localized_ui("craft.experiment.result.success", "Discovered {recipe} · {product} made and put away.", {"recipe":recipe_name, "product":output_name})
		craft_experiment_selected.clear()
		craft_page = 0
		_refresh_craft_recipe_ids()
		_refresh_craft_experiment_ingredients()
		_trigger_player_action(7)
		if sfx_manager != null:
			sfx_manager.play_sfx("ceramic_cup")
	else:
		match String(result.get("reason", "")):
			"storage_capacity": status_label.text = _localize_ui("craft.error.storage_capacity", "Backroom storage is full. Make room before preparing more drinks.")
			"product_capacity": status_label.text = _localize_ui("craft.error.product_capacity", "There is no room for another batch of that drink.")
			"missing_ingredients": status_label.text = _localize_ui("craft.experiment.result.missing_ingredients", "You don't have all of those ingredients. Nothing was used.")
			"recipe_locked": status_label.text = _localize_ui("craft.experiment.result.locked", "That combination may work later, after the shop's story has moved forward.")
			"already_discovered": status_label.text = _localize_ui("craft.experiment.result.already_discovered", "That recipe is already in your book.")
			"wrong_station":
				var required_station_id := String(result.get("required_station", ""))
				var required_station_name := _localize_ui(String(CRAFT_STATION_UI_IDS.get(required_station_id, "craft.station.default")), String(CRAFT_STATION_NAMES.get(required_station_id, "RIGHT STATION"))).to_lower()
				status_label.text = _format_localized_ui("craft.error.wrong_station", "That recipe belongs at the {station}.", {"station":required_station_name})
			_: status_label.text = _localize_ui("craft.experiment.result.no_match", "Nothing quite comes together. Your ingredients are untouched.")
	_refresh_craft_panel()

func _refresh_craft_panel() -> void:
	var page_count := _craft_total_page_count()
	craft_page = clampi(craft_page, 0, page_count - 1)
	var station_name := _localize_ui(String(CRAFT_STATION_UI_IDS.get(active_craft_station_id, "craft.station.default")), String(CRAFT_STATION_NAMES.get(active_craft_station_id, "PREPARATION STATION")))
	var lines: Array[String] = [station_name, _format_localized_ui("craft.page", "\nPage {page} / {pages} · {previous} / {next} change page", {"page":craft_page + 1, "pages":page_count, "previous":_binding_label("page_previous"), "next":_binding_label("page_next")})]
	if _craft_page_is_experiment():
		var experiment_page := craft_page - _craft_recipe_page_count()
		var first_ingredient_index := experiment_page * 5
		var end_ingredient_index := mini(first_ingredient_index + 5, craft_experiment_ingredient_ids.size())
		lines.append("\n" + _localize_ui("craft.experiment.heading", "TRY A COMBINATION"))
		lines.append(_localize_ui("craft.experiment.instructions", "Select ingredients you have on hand, then try the combination. Ingredients are only used when a recipe matches."))
		for index in range(first_ingredient_index, end_ingredient_index):
			var ingredient_id := craft_experiment_ingredient_ids[index]
			var selected_mark := "✓" if craft_experiment_selected.has(ingredient_id) else " "
			var ingredient_name := _localized_product_name(ingredient_id, String(game.inventory.products.get(ingredient_id, {}).get("name", ingredient_id)))
			lines.append("\n%d   %s %s · %d" % [index - first_ingredient_index + 1, selected_mark, ingredient_name, game.inventory.available_quantity(ingredient_id)])
		if craft_experiment_ingredient_ids.is_empty():
			lines.append("\n" + _localize_ui("craft.experiment.no_ingredients", "No new recipes can be tried at this station yet."))
		var selected_names: Array[String] = []
		for ingredient_id in craft_experiment_selected:
			selected_names.append(_localized_product_name(String(ingredient_id)))
		selected_names.sort()
		var selected_text := ", ".join(selected_names) if not selected_names.is_empty() else _localize_ui("craft.experiment.none", "none selected")
		lines.append("\n\n" + _format_localized_ui("craft.experiment.selected", "Combination · {ingredients}", {"ingredients":selected_text}))
		lines.append(_format_localized_ui("craft.experiment.footer", "\n{selection} toggles an ingredient · {previous} / {next} changes page · {interact} tries the combination · {back} closes", {"selection":_selection_hint(mini(5, maxi(0, craft_experiment_ingredient_ids.size() - first_ingredient_index))), "previous":_binding_label("page_previous"), "next":_binding_label("page_next"), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	else:
		lines.append("\n" + _localize_ui("craft.instruction.choose", "Choose a recipe for this station."))
		var first_index := craft_page * 5
		var end_index := mini(first_index + 5, available_recipe_ids.size())
		for index in range(first_index, end_index):
			var slot := index - first_index
			var recipe_id := available_recipe_ids[index]
			var recipe: Dictionary = game.recipes[recipe_id]
			var output_id := String(recipe.get("output_product_id", ""))
			var output: Dictionary = game.inventory.products.get(output_id, {})
			var ingredients: Array[String] = []
			for product_id in recipe.get("ingredients", {}):
				var count := int(recipe.ingredients[product_id])
				ingredients.append("%s × %d" % [_localized_product_name(String(product_id), String(game.inventory.products[product_id].get("name", product_id))), count])
			var output_stock := _format_localized_ui("craft.stock_status", "Display {display} · backroom {backroom}", {"display":game.inventory.shelf_quantity(output_id), "backroom":game.inventory.storage_quantity(output_id)}) if not output.is_empty() else _localize_ui("craft.stock_unavailable", "Output unavailable")
			var freshness_left := game.inventory.freshness_remaining(output_id, "storage")
			var freshness_text := _format_localized_ui("craft.freshness.shifts", "{count} shifts", {"count":freshness_left}) if freshness_left >= 0 else _localize_ui("craft.freshness.unknown", "n/a")
			var output_details := _format_localized_ui("craft.output_details", "{stock} · backroom freshness {freshness}", {"stock":output_stock, "freshness":freshness_text})
			lines.append("\n%d   %s\n      %s\n      %s" % [slot + 1, _localized_recipe_name(recipe_id, String(recipe.get("name", recipe_id))), ", ".join(ingredients), output_details])
		if available_recipe_ids.is_empty():
			lines.append("\n" + _localize_ui("craft.empty", "No recipes are ready at this station yet. Listen to what regulars order."))
		var batch_note := _localize_ui("craft.batch_note", " up to three servings") if simplified_crafting_enabled else ""
		lines.append(_format_localized_ui("craft.footer", "\n\n{selection} prepares{batch_note}. Finished goods go to backroom storage; move them to a display to sell. {experiment} turns the page to try combinations · {back} goes back.", {"selection":_selection_hint(mini(5, maxi(0, available_recipe_ids.size() - first_index))), "batch_note":batch_note, "experiment":_binding_label("page_next"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)

func _refresh_stock_panel() -> void:
	var selected_index := stock_page * 5 + stock_selected_slot
	if selected_index >= 0 and selected_index < stocked_product_ids.size():
		_refresh_product_detail_icon(stocked_product_ids[selected_index])
	else:
		_hide_product_detail_icon()
	var current_date: Dictionary = game.calendar.date_for_shift(maxi(game.shift_number, 1))
	var current_season := String(current_date.get("season_id", "spring"))
	var instruction := _localize_ui("stock.instruction.supplier", "Choose a delivery from your supplier. Each order costs Coins.")
	match stock_panel_mode:
		"backroom_storage": instruction = _format_localized_ui("stock.instruction.storage", "Select an item and press {restock} to pick up one for its display. Close the panel to carry it through the shop.", {"restock":_binding_label("stock_restock")})
		"backroom_delivery": instruction = _localize_ui("stock.instruction.delivery", "Choose a delivery for backroom storage. Each order costs Coins.")
		"backroom_trolley": instruction = _format_localized_ui("stock.instruction.trolley", "Select an item and press {restock} to pick up one for its display; {restock_all} quickly fills it from the trolley.", {"restock":_binding_label("stock_restock"), "restock_all":_binding_label("stock_restock_all")})
	if game.inventory.is_carrying_stock() and stock_panel_mode in ["retail_shelf", "retail_fridge"]:
		instruction = _format_localized_ui("stock.instruction.carrying", "Carrying {product} · select its display and press {restock} to place it.", {"product":_localized_product_name(game.inventory.carried_product_id), "restock":_binding_label("stock_restock")})
	elif game.inventory.is_carrying_stock() and stock_panel_mode in ["backroom_storage", "backroom_trolley"]:
		instruction = _format_localized_ui("stock.instruction.carrying_backroom", "Carrying {product} · select it and press {restock} to return it to storage.", {"product":_localized_product_name(game.inventory.carried_product_id), "restock":_binding_label("stock_restock")})
	var page_count := maxi(1, int(ceil(float(stocked_product_ids.size()) / 5.0)))
	var lines: Array[String] = [stock_category, _format_localized_ui("stock.page_caption", "\n{instruction}  Page {page} / {pages}", {"instruction":instruction, "page":stock_page + 1, "pages":page_count})]
	for slot in range(5):
		var i := stock_page * 5 + slot
		if i >= stocked_product_ids.size():
			break
		var product_id := stocked_product_ids[i]
		var product: Dictionary = game.inventory.products[product_id]
		var shelf_capacity := game.inventory.shelf_capacity_for(product_id)
		var selected_mark := "›" if slot == stock_selected_slot else " "
		var shelf_life := game.inventory.freshness_remaining(product_id)
		var sale_price := game.inventory.price_for(product_id)
		var craft_only := bool(product.get("craft_only", false))
		var price_text := _localize_ui("stock.price.craft_only", "made at kettle") if craft_only else _format_localized_ui("stock.price.coins", "{price} Coins", {"price":str(sale_price)})
		if not craft_only and game.inventory.price_modifiers.has(product_id):
			price_text += _localize_ui("stock.price.sale", " sale")
		var seasonal_label := _localize_ui("stock.seasonal.highlight", " · in season") if product.get("seasonal_seasons", []).has(current_season) else ""
		var freshness_text := _format_localized_ui("stock.freshness", " · best-before {shifts} shifts", {"shifts":str(shelf_life)}) if shelf_life >= 0 else ""
		lines.append(_format_localized_ui("stock.row", "\n{marker}{slot}   {product}  ·  display {shown} / {capacity}  ·  backroom {storage}  ·  {price}{seasonal}{freshness}", {"marker":selected_mark, "slot":str(slot + 1), "product":_localized_product_name(product_id, String(product.get("name", product_id))), "shown":str(game.inventory.shelf_quantity(product_id)), "capacity":str(shelf_capacity), "storage":str(game.inventory.storage_quantity(product_id)), "price":price_text, "seasonal":seasonal_label, "freshness":freshness_text}))
	var choice_hint := _selection_hint(mini(5, stocked_product_ids.size() - stock_page * 5))
	var controls := _format_localized_ui("stock.controls.retail", "{selection} orders one delivery. {restock} replenishes one; {restock_all} fills display. {markdown} discounts; {markdown_clear} clears discount. {donate} donates one; {donate_all} donates all.", {"selection":choice_hint, "restock":_binding_label("stock_restock"), "restock_all":_binding_label("stock_restock_all"), "markdown":_binding_label("stock_markdown"), "markdown_clear":_binding_label("stock_markdown_clear"), "donate":_binding_label("stock_donate"), "donate_all":_binding_label("stock_donate_all")})
	match stock_panel_mode:
		"backroom_storage": controls = _format_localized_ui("stock.controls.backroom_storage", "{selection} selects an item. {restock} picks up one to carry to its display; {restock_all} quickly fills display space.", {"selection":choice_hint, "restock":_binding_label("stock_restock"), "restock_all":_binding_label("stock_restock_all")})
		"backroom_delivery": controls = _format_localized_ui("stock.controls.backroom_delivery", "{selection} orders one supplier delivery; crafted goods are made at the kettle.", {"selection":choice_hint})
		"backroom_trolley": controls = _format_localized_ui("stock.controls.backroom_trolley", "{selection} selects an item. {restock} picks up one to carry to its display; {restock_all} quickly fills display space.", {"selection":choice_hint, "restock":_binding_label("stock_restock"), "restock_all":_binding_label("stock_restock_all")})
	if game.inventory.is_carrying_stock() and stock_panel_mode in ["backroom_storage", "backroom_trolley"]:
		controls = _format_localized_ui("stock.controls.backroom_carrying", "{selection} selects an item. {restock} returns the item you're carrying when you select the same product.", {"selection":choice_hint, "restock":_binding_label("stock_restock")})
	lines.append(_format_localized_ui("stock.controls.footer", "\n\n{controls} {previous} / {next} browse.\nYou have {coins} Coins. {interact} interacts · {inventory} opens inventory · {back} goes back.", {"controls":controls, "previous":_binding_label("page_previous"), "next":_binding_label("page_next"), "coins":current_coins, "interact":_binding_label("interact"), "inventory":_binding_label("inventory"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)

func _refresh_product_detail_icon(product_id: String) -> void:
	if selected_product_icon == null:
		return
	var product: Dictionary = game.inventory.products.get(product_id, {})
	var icon_id := String(product.get("icon_alias", product_id))
	var icon_index := int(PRODUCT_ICON_INDEX.get(icon_id, -1))
	if icon_index < 0:
		_hide_product_detail_icon()
		return
	var icon_atlas_path := PRODUCT_ICON_PATH
	var cell_index := icon_index
	var atlas_rows := 5
	if icon_index >= 84:
		icon_atlas_path = PRODUCT_ICON_EXTENSION_5_PATH
		cell_index = icon_index - 84
		atlas_rows = 4
	elif icon_index >= 68:
		icon_atlas_path = PRODUCT_ICON_EXTENSION_4_PATH
		cell_index = icon_index - 68
		atlas_rows = 4
	elif icon_index >= 52:
		icon_atlas_path = PRODUCT_ICON_EXTENSION_3_PATH
		cell_index = icon_index - 52
		atlas_rows = 4
	elif icon_index >= 36:
		icon_atlas_path = PRODUCT_ICON_EXTENSION_2_PATH
		cell_index = icon_index - 36
		atlas_rows = 4
	elif icon_index >= 20:
		icon_atlas_path = PRODUCT_ICON_EXTENSION_PATH
		cell_index = icon_index - 20
		atlas_rows = 4
	var texture := load(icon_atlas_path) as Texture2D
	if texture == null:
		_hide_product_detail_icon()
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = _grid_region(icon_atlas_path, cell_index % 4, int(cell_index / 4), 4, atlas_rows)
	selected_product_icon.texture = atlas
	selected_product_icon.visible = true

func _hide_product_detail_icon() -> void:
	if selected_product_icon == null:
		return
	selected_product_icon.texture = null
	selected_product_icon.visible = false

func _close_side_panel() -> void:
	var closing_pause_menu := active_panel == "pause"
	var restore_focus := pause_previous_focus_owner
	pause_previous_focus_owner = null
	if game != null and game.decoration != null:
		game.decoration.set_transient_access_points([])
	if active_panel == "checkout" and not checkout_customer_id.is_empty():
		game.customers.cancel_checkout(checkout_customer_id)
	if puzzle_answer_input != null:
		puzzle_answer_input.release_focus()
		puzzle_answer_input.visible = false
	active_environmental_puzzle_id = ""
	active_panel = ""
	side_panel.visible = false
	side_label.visible = false
	side_scroll.size = Vector2(440, 580)
	_hide_product_detail_icon()
	for button in pause_buttons:
		button.visible = false
	speed_label.visible = false
	speed_slider.visible = false
	if decoration_preview != null:
		decoration_preview.visible = false
	game.set_paused(false)
	if closing_pause_menu and is_instance_valid(restore_focus) and restore_focus.is_inside_tree() and restore_focus.is_visible_in_tree():
		restore_focus.grab_focus()

func _open_pause_menu() -> void:
	pause_previous_focus_owner = get_viewport().gui_get_focus_owner()
	active_panel = "pause"
	var close_verdict: Dictionary = game.can_close_shift()
	var close_note := _localize_ui("pause.service_complete", "The minimum open-service promise is complete; unfinished story visits will wait safely for another night.") if close_verdict.get("ok", false) else _format_localized_ui("pause.service_remaining", "Moonmart needs {minutes} more service minute{plural} before an early close is available.", {"minutes":int(close_verdict.get("remaining_minutes", 0)), "plural":"s" if int(close_verdict.get("remaining_minutes", 0)) != 1 else ""})
	side_label.text = _format_localized_ui("pause.body", "A quiet moment\n\nThe night is saved whenever a story or shop transaction is completed. You can also save now and return later.\n\n{close_note}\n\n{back} resumes your shift.", {"close_note":close_note, "back":_binding_label("ui_back")})
	side_panel.visible = true
	side_label.visible = true
	for button in pause_buttons:
		button.visible = true
	if not pause_buttons.is_empty():
		pause_buttons[0].grab_focus()
	speed_slider.value = game.clock.speed_multiplier
	speed_label.visible = true
	speed_slider.visible = true
	_on_speed_changed(speed_slider.value)
	game.set_paused(true)

func _on_speed_changed(value: float) -> void:
	_apply_settings_game_speed(value)
	if settings_manager != null:
		settings_manager.set_setting("game_speed", value)
	if speed_label != null:
		speed_label.text = _format_localized_ui("hud.shift_pace", "Shift pace · ×{pace}", {"pace":_format_locale_number(value, 1)})

func _open_settings_from_pause() -> void:
	if settings_panel != null:
		settings_panel.open()
		game.set_paused(true)

func _run_auto_stock() -> void:
	if not bool(auto_stock_config.get("enabled", false)):
		return
	var targets: Dictionary = auto_stock_config.get("targets", {})
	var restocked: Array[String] = []
	for product_id in targets:
		var id := String(product_id)
		if not game.inventory.products.has(id):
			continue
		var target := int(targets[product_id])
		var product_limit := 20 + (10 if game.shop_progression.has_upgrade("expanded_shelf_capacity") else 0)
		var target_total := mini(target, product_limit)
		var target_shelf := mini(target_total, game.inventory.shelf_capacity_for(id))
		var shelf_gap := maxi(0, target_shelf - game.inventory.shelf_quantity(id))
		var from_storage := mini(shelf_gap, game.inventory.storage_quantity(id))
		if from_storage > 0:
			game.restock_shelf(id, from_storage)
		var order_space := maxi(0, product_limit - game.inventory.quantity(id))
		var order_quantity := mini(maxi(0, target_total - game.inventory.quantity(id)), order_space)
		if order_quantity > 0:
			var result: Dictionary = game.order_stock(id, order_quantity)
			if not result.get("ok", false):
				continue
		var remaining_shelf_gap := maxi(0, target_shelf - game.inventory.shelf_quantity(id))
		var delivery_to_display := mini(remaining_shelf_gap, game.inventory.storage_quantity(id))
		if delivery_to_display > 0:
			game.restock_shelf(id, delivery_to_display)
		if from_storage > 0 or order_quantity > 0:
			restocked.append(_localized_product_name(String(id)))
	if not restocked.is_empty():
		status_label.text = _format_localized_ui("stock.status.automatic_delivery", "Automatic delivery · {products}", {"products":", ".join(restocked)})

func _resume_from_pause() -> void:
	_close_side_panel()

func _save_resume_from_pause() -> bool:
	if not game.save_now():
		_show_save_failure_notice()
		return false
	_close_side_panel()
	return true

func _close_shift_from_pause() -> void:
	_close_side_panel()
	game.close_shift()
	game.save_now()

func _save_quit_from_pause() -> bool:
	if not game.save_now():
		_show_save_failure_notice()
		return false
	get_tree().quit()
	return true

func _dismiss_message() -> void:
	message_open = false
	active_location_talker_id = ""
	message_panel.visible = false
	message_label.visible = false
	if game != null:
		game.finish_customer_conversation()
		game.set_paused(false)
		if game.story.selected_ending.is_empty() and not game.available_endings().is_empty():
			_open_ending_panel()

func _open_ending_panel() -> void:
	active_panel = "endings"
	var lines: Array[String] = [_localize_ui("journal.endings.heading", "A NEW COVENANT"), "\n" + _localize_ui("journal.endings.prompt", "How would you like Moonmart's doorway to change?")]
	var endings := game.available_endings()
	for i in range(mini(3, endings.size())):
		var ending_id := String(endings[i].get("id", ""))
		var title := _localize_ui("journal.ending.%s.title" % ending_id, String(endings[i].get("title", "Ending")))
		var epilogue := _localize_ui("journal.ending.%s.epilogue" % ending_id, String(endings[i].get("epilogue", "")))
		lines.append("\n%d   %s\n      %s" % [i + 1, title, epilogue])
	lines.append(_format_localized_ui("journal.endings.controls", "\n\n{selection} chooses. {interact} interacts · {back} goes back to keep thinking.", {"selection":_selection_hint(mini(3, endings.size())), "interact":_binding_label("interact"), "back":_binding_label("ui_back")}))
	side_label.text = "\n".join(lines)
	side_panel.visible = true
	side_label.visible = true
	game.set_paused(true)

func _on_clock_updated(text_value: String, _elapsed_minutes: float) -> void:
	current_clock = text_value
	clock_label.text = "☾  " + text_value

func _on_message_changed(text_value: String) -> void:
	if text_value.is_empty():
		return
	message_label.text = text_value
	message_panel.visible = true
	message_label.visible = true
	message_open = true
	call_deferred("_fit_message_panel")
	if game != null:
		game.set_paused(true)

func _fit_message_panel() -> void:
	if message_panel == null or message_label == null or message_hint_label == null or not message_panel.visible:
		return
	# Keep short notices compact while reserving room for longer localized dialogue.
	var wrapped_lines := maxi(1, message_label.get_line_count())
	var panel_height := clampf(float(wrapped_lines * 30 + 54), 190.0, 200.0)
	var panel_position := Vector2(300.0, 825.0 - panel_height)
	message_panel.position = panel_position
	message_panel.size = Vector2(1000.0, panel_height)
	message_panel.set_meta("moonmart_ui_base_position", panel_position)
	message_panel.set_meta("moonmart_ui_base_size", message_panel.size)
	message_label.position = panel_position + Vector2(26.0, 18.0)
	message_label.size = Vector2(948.0, panel_height - 52.0)
	message_label.set_meta("moonmart_ui_base_position", message_label.position)
	message_label.set_meta("moonmart_ui_base_size", message_label.size)
	message_hint_label.position = panel_position + Vector2(790.0, panel_height - 34.0)
	message_hint_label.set_meta("moonmart_ui_base_position", message_hint_label.position)
	message_hint_label.set_meta("moonmart_ui_base_size", message_hint_label.size)

func _on_journal_changed(text_value: String) -> void:
	current_journal = text_value
	if active_panel == "journal":
		side_label.text = _format_localized_ui("journal.panel", "{body}\n\n{interact} interacts · {journal} opens the journal · {back} goes back.", {"body":_journal_panel_text(), "interact":_binding_label("interact"), "journal":_binding_label("journal"), "back":_binding_label("ui_back")})

func _on_companion_reaction(text_value: String) -> void:
	if miso_reaction_label == null or miso_reaction_panel == null:
		return
	miso_reaction_label.text = text_value
	miso_reaction_label.visible = true
	miso_reaction_panel.visible = true
	miso_reaction_time_remaining = 7.0

func _journal_panel_text() -> String:
	var body := current_journal
	var memories := game.story.ending_memories_for_journal()
	if not memories.is_empty():
		body += "\n\n" + _format_localized_ui("journal.memories_hint", "Choose 1–{count} to read a remembered place again.", {"count":memories.size()})
	var collectible_ids: Array[String] = []
	for collectible_id in game.discovered_collectibles:
		var collectible_entry_id := String(collectible_id)
		if game.collectible_definitions.has(collectible_entry_id):
			collectible_ids.append(collectible_entry_id)
	collectible_ids.sort()
	var collectible_total: int = game.collectible_definitions.size()
	if collectible_total > 0:
		body += _format_localized_ui("journal.collectibles.progress", "\n\nKEEPSAKES · {found}/{total}", {"found":collectible_ids.size(), "total":collectible_total})
		if collectible_ids.is_empty():
			body += "\n" + _localize_ui("journal.collectibles.empty", "Small things from the road will be written here when you find them.")
		else:
			for collectible_id in collectible_ids:
				var collectible: Dictionary = game.collectible_definitions[collectible_id]
				var name := _localize_ui("collectible.%s.name" % collectible_id, String(collectible.get("name", collectible_id.replace("_", " ").capitalize())))
				var description := _localize_ui("collectible.%s.description" % collectible_id, String(collectible.get("description", "")))
				body += "\n\n%s" % name
				if not description.is_empty():
					body += "\n%s" % description
	var recipe_ids: Array[String] = []
	for recipe_id in game.discovered_recipe_ids:
		var recipe_entry_id := String(recipe_id)
		if game.recipes.has(recipe_entry_id):
			recipe_ids.append(recipe_entry_id)
	recipe_ids.sort()
	if not game.recipes.is_empty():
		body += _format_localized_ui("journal.recipes.progress", "\n\nCOOKBOOK · {found}/{total}", {"found":recipe_ids.size(), "total":game.recipes.size()})
		if recipe_ids.is_empty():
			body += "\n" + _localize_ui("journal.recipes.empty", "Your recipe notes are waiting for a first discovery.")
		else:
			for recipe_id in recipe_ids:
				body += "\n" + _localized_recipe_name(recipe_id, String(game.recipes[recipe_id].get("name", recipe_id)))
	if game.mysteries != null and not game.mysteries.investigations.is_empty():
		var solved_investigations := 0
		for investigation_id in game.mysteries.investigations:
			if String(game.mysteries.states.get(String(investigation_id), {}).get("status", "active")) == "solved":
				solved_investigations += 1
		body += _format_localized_ui("journal.investigations.progress", "\n\nMYSTERIES · {found}/{total}", {"found":solved_investigations, "total":game.mysteries.investigations.size()})
	if game.environmental_puzzles != null and not game.environmental_puzzles.definitions.is_empty():
		var solved_puzzles := 0
		for puzzle_id in game.environmental_puzzles.definitions:
			if bool(game.environmental_puzzles.states.get(String(puzzle_id), {}).get("solved", false)):
				solved_puzzles += 1
		body += _format_localized_ui("journal.puzzles.progress", "\nPUZZLES · {found}/{total}", {"found":solved_puzzles, "total":game.environmental_puzzles.definitions.size()})
	if game.calendar != null and not game.calendar.festivals.is_empty():
		var attended_festival_ids: Dictionary = {}
		for attendance_key in game.calendar.attended_festivals:
			var festival_key_parts := String(attendance_key).split(":", false, 1)
			if not festival_key_parts.is_empty() and not festival_key_parts[0].is_empty():
				attended_festival_ids[festival_key_parts[0]] = true
		body += _format_localized_ui("journal.festivals.progress", "\nFESTIVALS · {found}/{total}", {"found":attended_festival_ids.size(), "total":game.calendar.festivals.size()})
	return body

func _ending_memory_message(memory: Dictionary) -> String:
	var memory_id := String(memory.get("id", ""))
	var title := _localize_ui("journal.ending_memory.%s.title" % memory_id, String(memory.get("title", "A remembered place")))
	var body := _localize_ui("journal.ending_memory.%s.text" % memory_id, String(memory.get("text", "")))
	return "%s\n\n%s" % [title, body]

func _on_customer_changed(customer: Dictionary, arrived: bool, play_arrival_sound: bool = true) -> void:
	var id := String(customer.get("id", ""))
	if arrived:
		if play_arrival_sound and current_location_id == "moonmart" and sfx_manager != null:
			var threshold_unresolved: bool = game != null and bool(game.story.flags.get("pip_reflection", false)) and not bool(game.story.flags.get("boundary_stabilized", false)) and game.world_map.ending_id.is_empty()
			if threshold_unresolved:
				sfx_manager.play_threshold_door_bell()
			else:
				sfx_manager.play_door_bell()
		customer_id = id
		customer_name = String(customer.get("name", "A visitor"))
		customer_states[id] = String(customer.get("state", "ARRIVING"))
		var visual: Sprite2D
		if id == "pip":
			visual = pip
			pip_anchor = Vector2(504, 662)
		elif id == "agnes":
			visual = agnes_sprite
		else:
			if not customer_visuals.has(id):
				var art_path := String(NAMED_CHARACTER_SHEETS.get(id, GENERIC_CUSTOMER_PATH))
				var character_scale: Vector2 = NAMED_CHARACTER_SCALE_OVERRIDES.get(id, Vector2(0.30, 0.30))
				visual = _grid_sprite(art_path, 0, 0, 4, 1, character_scale, Vector2(1000, 704), "Visitor_" + id, characters_layer)
			else:
				visual = customer_visuals[id]
		customer_visuals[id] = visual
		visual.visible = true
	else:
		customer_visuals.erase(id)
		customer_states.erase(id)
		customer_targets.erase(id)
		customer_routes.erase(id)
		customer_route_indices.erase(id)
		if id == "pip": pip.visible = false
		elif id == "agnes": agnes_sprite.visible = false
		else:
			var departed := characters_layer.get_node_or_null("Visitor_" + id) as Sprite2D
			if departed != null: departed.queue_free()
		_layout_customer_visuals()
		return
	_layout_customer_visuals()

func _layout_customer_visuals() -> void:
	var visitor_index := 0
	for visitor in game.customers.active:
		var id := String(visitor.get("id", ""))
		if not customer_visuals.has(id):
			continue
		if id == "pip":
			customer_targets[id] = pip_anchor
			continue
		var state := String(visitor.get("state", "ARRIVING"))
		var browsing_choice: Dictionary = visitor.get("browsing_choice", {})
		var product_id := String(browsing_choice.get("product_id", ""))
		var category := String(game.inventory.products.get(product_id, {}).get("category", "everyday"))
		var browse_position := Vector2(194, 706)
		if category == "cold":
			browse_position = Vector2(468, 708)
		elif category == "bakery":
			browse_position = Vector2(708, 706)
		elif category == "midnight":
			browse_position = Vector2(1296, 702)
		var target := Vector2(1430, 710)
		match state:
			"BROWSING": target = browse_position
			"LINGERING": target = Vector2(818, 626)
			"CONVERSING": target = Vector2(1190, 704)
			"QUEUING", "CHECKOUT": target = Vector2(1124, 706)
			"LEAVING": target = Vector2(1475, 610)
		var offset := Vector2((visitor_index % 2) * 32.0, (visitor_index / 2) * 18.0)
		var visitor_target := target + offset
		customer_targets[id] = visitor_target
		customer_routes[id] = _make_shop_route((customer_visuals[id] as Sprite2D).position, visitor_target)
		customer_route_indices[id] = 0
		visitor_index += 1

func _on_customer_state_changed(customer: Dictionary, state: String) -> void:
	var id := String(customer.get("id", ""))
	customer_states[id] = state
	if customer_visuals.has(id):
		var visual: Sprite2D = customer_visuals[id]
		visual.visible = state != "LEAVING"
	_layout_customer_visuals()
	if active_panel == "decorate":
		_refresh_decoration_transient_access()

func _on_money_changed(coins: int, moon_tokens: int) -> void:
	current_coins = coins
	current_moons = moon_tokens
	coin_label.text = str(coins)
	moon_token_label.text = str(moon_tokens)

func _on_shift_changed(number: int, status: String) -> void:
	shift_status = status
	if current_location_id != "moonmart":
		_play_location_score()
		_update_location_hud_caption()
		return
	var calendar_shift := maxi(number, 1) if status == "open" else maxi(number + 1, 1)
	var date: Dictionary = game.calendar.date_for_shift(calendar_shift)
	var day := String(date.get("weekday", "Monday")).left(3)
	var season := String(date.get("season", "Spring"))
	status_label.text = _format_localized_ui("hud.shift_status", "N{night} · {day} · {season} · {status}", {"night":str(calendar_shift), "day":_localize_ui("calendar.weekday.%s" % String(date.get("weekday", "Monday")).to_lower(), day), "season":_localize_ui("calendar.season.%s.name" % String(date.get("season_id", "spring")), season), "status":_localize_ui("shift.%s" % status, "OPEN" if status == "open" else "BETWEEN")})

func _update_location_hud_caption() -> void:
	if status_label == null or game == null:
		return
	if current_location_id == "moonmart":
		if game.shift_number == 0:
			status_label.text = _localize_ui("welcome.tagline", "A little shop between the hills and the sea")
		else:
			_on_shift_changed(game.shift_number, game.shift_status)
		return
	var location_name := _localize_ui("location.%s.name" % current_location_id, current_location_id.replace("_", " ").capitalize())
	status_label.text = location_name

func _on_story_event(event_id: String, visitor_name_value: String) -> void:
	if sfx_manager != null:
		sfx_manager.play_story_reveal()
	if event_id == "pip_reflection":
		pip.visible = true
		pip_anchor = Vector2(535, 654)
		pip.position = pip_anchor
		pip.modulate = Color(1.0, 0.86, 0.96, 0.95)
	elif event_id == "hidden_photograph":
		var sparkle := _atlas_sprite(load(UI_ICON_PATH) as Texture2D, _grid_region(UI_ICON_PATH, 2, 1, 4, 2), Vector2(0.28, 0.28), Vector2(1146, 570), "PhotographStarSparkle", prop_effects_layer)
		sparkle.z_index = 40

func _story_title(id: String) -> String:
	match id:
		"meet_agnes": return "Agnes leaves a warm pastry for your first night."
		"pip_reflection": return "Pip asks for strawberry milk. Their reflection is missing from the window."
		"receipt_1974": return "An old receipt appears in the till. It is dated 1974, and bears Pip's order."
		"hidden_photograph": return "Behind the receipt is a photograph of Pip, standing in this very shop."
		"pip_first_memory": return "Pip remembers Moonmart as a safe place, long before tonight."
	return "A familiar visitor shares a quiet moment with you."

func _on_sale_completed(name: String, total: int, currency: String) -> void:
	if sfx_manager != null:
		sfx_manager.play_sfx("ceramic_cup")
		var threshold_unresolved: bool = game != null and bool(game.story.flags.get("pip_reflection", false)) and not bool(game.story.flags.get("boundary_stabilized", false)) and game.world_map.ending_id.is_empty()
		if threshold_unresolved:
			sfx_manager.play_threshold_register_chime()
		else:
			sfx_manager.play_register_chime()
	var currency_label := _localize_ui("currency.moon_tokens", "Moon Tokens") if currency == "moon_tokens" else _localize_ui("currency.coins", "Coins")
	status_label.text = _format_localized_ui("checkout.sale_result", "{name} · +{total} {currency}", {"name":name, "total":total, "currency":currency_label})

func _panel(at: Vector2, size: Vector2, fill: Color, border: Color, border_size: int) -> PanelContainer:
	var control := PanelContainer.new()
	control.position = at
	control.size = size
	control.add_theme_stylebox_override("panel", _style(fill, border, border_size, 16))
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func _raster_panel_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(JOURNAL_PANEL_PATH) as Texture2D
	style.texture_margin_left = 80
	style.texture_margin_top = 80
	style.texture_margin_right = 80
	style.texture_margin_bottom = 80
	style.content_margin_left = 28
	style.content_margin_top = 28
	style.content_margin_right = 28
	style.content_margin_bottom = 28
	return style

func _panel_rect(at: Vector2, size: Vector2, fill: Color, border: Color, border_size: int) -> Panel:
	var control := Panel.new()
	control.position = at
	control.size = size
	control.add_theme_stylebox_override("panel", _style(fill, border, border_size, 8))
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func _style(fill: Color, border: Color, border_size: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_size)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func _label(text_value: String, font_size: int, color: Color, at: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.text = text_value
	var readable := settings_manager != null and bool(settings_manager.get_setting("dyslexia_friendly_text", false))
	label.add_theme_font_override("font", OPEN_DYSLEXIC_FONT if readable else MOONMART_FONT)
	label.position = at
	label.size = size
	label.set_meta("moonmart_base_font_size", font_size)
	label.add_theme_font_size_override("font_size", roundi(font_size * (1.12 if readable else 1.0)))
	label.add_theme_constant_override("line_spacing", 3 if readable else 0)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("29243b"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _add_hud_icon(column: int, row: int, at: Vector2, size: Vector2) -> TextureRect:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = load(UI_ICON_PATH) as Texture2D
	atlas_texture.region = _grid_region(UI_ICON_PATH, column, row, 4, 2)
	var icon := TextureRect.new()
	icon.name = "HudIcon_%d_%d" % [column, row]
	icon.texture = atlas_texture
	icon.position = at
	icon.size = size
	icon.set_meta("moonmart_ui_base_position", at)
	icon.set_meta("moonmart_ui_base_size", size)
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(icon)
	icon.size = size
	icon.call_deferred("set_size", size)
	return icon

func _refresh_side_panel_icon() -> void:
	if side_panel_icon == null or side_panel_icon_kind == active_panel:
		return
	side_panel_icon_kind = active_panel
	var icon_index := -1
	match active_panel:
		"mystery_cases", "mystery_hypotheses", "environmental_puzzle": icon_index = 0
		"checkout", "stock", "inventory": icon_index = 1
		"companion": icon_index = 3
		"journal", "ledger", "endings": icon_index = 15
		"map": icon_index = 9
		"calendar", "radio": icon_index = 14
		"housekeeping": icon_index = 5
		"decorate", "craft": icon_index = 6
		"upgrades": icon_index = 7
	if icon_index < 0:
		side_panel_icon.visible = false
		side_panel_icon.texture = null
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = load(UI_ICON_EXTENSION_PATH) as Texture2D
	atlas.region = _grid_region(UI_ICON_EXTENSION_PATH, icon_index % 4, int(icon_index / 4), 4, 4)
	side_panel_icon.texture = atlas
	side_panel_icon.visible = active_panel != "pause"

func _pause_button(text_value: String, at: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	var readable := settings_manager != null and bool(settings_manager.get_setting("dyslexia_friendly_text", false))
	button.add_theme_font_override("font", OPEN_DYSLEXIC_FONT if readable else MOONMART_FONT)
	button.position = at
	button.size = Vector2(360, 52)
	button.set_meta("moonmart_base_font_size", 19)
	button.add_theme_font_size_override("font_size", roundi(19 * (1.12 if readable else 1.0)))
	button.add_theme_color_override("font_color", Color("fff0d8"))
	button.add_theme_stylebox_override("normal", _style(Color("51445f"), Color("e4b189"), 2, 12))
	button.add_theme_stylebox_override("hover", _style(Color("765a70"), Color("ffe1a5"), 3, 12))
	var focus_ring := StyleBoxFlat.new()
	focus_ring.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	focus_ring.border_color = Color("ffe1a5")
	focus_ring.set_border_width_all(3)
	focus_ring.set_corner_radius_all(12)
	focus_ring.draw_center = false
	button.add_theme_stylebox_override("focus", focus_ring)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.visible = false
	hud_layer.add_child(button)
	pause_buttons.append(button)
	return button
