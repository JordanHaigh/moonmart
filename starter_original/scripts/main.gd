extends Node2D
# Moonmart original starter gameplay prototype.
# Loads the original modular assets from res://starter_original/assets/png/.
const SPEED := 235.0
const WORLD_W := 2200.0
const WALK_MIN := 570.0
const WALK_MAX := 795.0
var player: Sprite2D
var actor_sprites: Dictionary = {}
var actor_targets: Dictionary = {}
var interactables: Array[Dictionary] = []
var player_velocity := Vector2.ZERO
var money := 250
var moon_tokens := 0
var shift := 1
var game_minutes := 0.0
var paused_for_dialogue := false
var prompt := ""
var inventory := {"strawberry_milk": 5, "tea": 4, "biscuits": 8}
var flags := {"pip_served": false, "receipt_found": false, "agnes_asked": false, "backroom_checked": false}
var ui: CanvasLayer
var hud: Label
var hint: Label
var message_panel: PanelContainer
var message_text: Label
var camera: Camera2D
var elapsed := 0.0
var walk_frame := -1
var rng := RandomNumberGenerator.new()
var _e_was_down := false
var _save_was_down := false

func _ready() -> void:
    rng.seed = 127
    _build_world()
    _build_actors()
    _build_ui()
    _load_game()
    _refresh_ui()

func _sprite(path: String, pos: Vector2, scale_factor: Vector2 = Vector2.ONE) -> Sprite2D:
    var node := Sprite2D.new()
    node.texture = load("res://starter_original/assets/png/" + path + ".png")
    node.position = pos
    node.scale = scale_factor
    add_child(node)
    return node

func _build_world() -> void:
    _sprite("env/sky", Vector2(800, 450)).z_index = -50
    _sprite("env/sky", Vector2(1900, 450)).z_index = -50
    _sprite("env/treeline", Vector2(800, 290)).z_index = -45
    _sprite("env/wall", Vector2(800, 320)).z_index = -30
    _sprite("env/wall", Vector2(1900, 320)).z_index = -30
    _sprite("env/window", Vector2(480, 190)).z_index = -29
    _sprite("env/window", Vector2(1500, 190)).z_index = -29
    _sprite("env/floor", Vector2(800, 760)).z_index = -20
    _sprite("env/floor", Vector2(1900, 760)).z_index = -20
    for x in [130, 390, 720, 1100, 1450, 1870]:
        _sprite("env/lamp", Vector2(x, 60), Vector2(0.9, 0.9)).z_index = -10
    for x in [245, 875, 1650]:
        _sprite("env/star_lamp", Vector2(x, 155), Vector2(0.7, 0.7)).z_index = -10
    for x in [70, 270, 850, 1300, 1700, 2070]:
        _sprite("furniture/shelf", Vector2(x, 410)).z_index = -5
    for x in [480, 655]:
        _sprite("furniture/fridge", Vector2(x, 395)).z_index = -4
    _sprite("env/arch", Vector2(1120, 395)).z_index = -3
    _sprite("furniture/door", Vector2(1120, 425), Vector2(0.7, 0.75)).z_index = -2
    _sprite("furniture/counter", Vector2(1780, 610)).z_index = 4
    _sprite("furniture/register", Vector2(1705, 492)).z_index = 5
    _sprite("furniture/display", Vector2(930, 610), Vector2(0.8, 0.8)).z_index = 3
    _sprite("furniture/coffee", Vector2(250, 565), Vector2(0.8, 0.8)).z_index = 3
    _sprite("characters/miso", Vector2(1855, 514), Vector2(0.78, 0.78)).z_index = 7
    for x in [90, 810, 1230, 2050]:
        _sprite("env/plant", Vector2(x, 565), Vector2(0.75, 0.75)).z_index = 5
    interactables = [
        {"id":"fridge", "label":"Take strawberry milk", "position":Vector2(560, 635), "radius":130.0},
        {"id":"coffee", "label":"Brew tea", "position":Vector2(250, 650), "radius":130.0},
        {"id":"display", "label":"Restock biscuits", "position":Vector2(930, 685), "radius":120.0},
        {"id":"door", "label":"Inspect the backroom", "position":Vector2(1120, 650), "radius":110.0},
        {"id":"counter", "label":"Use checkout", "position":Vector2(1740, 710), "radius":180.0},
        {"id":"miso", "label":"Pet Miso", "position":Vector2(1855, 650), "radius":130.0},
        {"id":"receipt", "label":"Inspect old receipt", "position":Vector2(1500, 680), "radius":100.0}
    ]
    camera = Camera2D.new()
    camera.position = Vector2(800, 450)
    camera.limit_left = 0
    camera.limit_right = 2200
    camera.limit_top = 0
    camera.limit_bottom = 900
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 3.0
    add_child(camera)
    camera.make_current()

func _build_actors() -> void:
    player = _sprite("characters/player", Vector2(800, 730), Vector2(0.7, 0.7))
    player.z_index = 12
    actor_sprites["pip"] = _sprite("characters/pip", Vector2(1450, 560), Vector2(0.7, 0.7))
    actor_sprites["agnes"] = _sprite("characters/agnes", Vector2(1920, 690), Vector2(0.65, 0.65))
    actor_sprites["fern"] = _sprite("characters/fern", Vector2(340, 700), Vector2(0.65, 0.65))
    actor_sprites["lucien"] = _sprite("characters/lucien", Vector2(590, 705), Vector2(0.65, 0.65))
    actor_sprites["wren"] = _sprite("characters/wren", Vector2(1320, 705), Vector2(0.65, 0.65))
    for id in actor_sprites:
        actor_sprites[id].z_index = 10
        actor_targets[id] = actor_sprites[id].position

func _build_ui() -> void:
    ui = CanvasLayer.new()
    add_child(ui)
    var top := PanelContainer.new()
    top.position = Vector2(18, 14)
    top.custom_minimum_size = Vector2(330, 112)
    ui.add_child(top)
    hud = Label.new()
    hud.add_theme_font_size_override("font_size", 22)
    hud.add_theme_color_override("font_color", Color("fff0d8"))
    top.add_child(hud)
    var bottom := PanelContainer.new()
    bottom.position = Vector2(16, 790)
    bottom.custom_minimum_size = Vector2(620, 90)
    ui.add_child(bottom)
    hint = Label.new()
    hint.add_theme_font_size_override("font_size", 20)
    hint.add_theme_color_override("font_color", Color("fff0d8"))
    bottom.add_child(hint)
    message_panel = PanelContainer.new()
    message_panel.position = Vector2(350, 670)
    message_panel.custom_minimum_size = Vector2(900, 110)
    ui.add_child(message_panel)
    message_text = Label.new()
    message_text.add_theme_font_size_override("font_size", 24)
    message_text.add_theme_color_override("font_color", Color("fff0d8"))
    message_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_panel.add_child(message_text)
    message_panel.visible = false

func _process(delta: float) -> void:
    if paused_for_dialogue:
        if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_ESCAPE):
            paused_for_dialogue = false
            message_panel.visible = false
        return
    elapsed += delta
    game_minutes += delta * 14.4
    if game_minutes >= 360.0:
        _finish_shift()
    var axis := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): axis.x -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): axis.x += 1
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): axis.y -= 1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): axis.y += 1
    player_velocity = axis.normalized() * SPEED
    player.position += player_velocity * delta
    player.position.x = clampf(player.position.x, 40.0, WORLD_W - 60.0)
    player.position.y = clampf(player.position.y, WALK_MIN, WALK_MAX)
    camera.position.x = clampf(player.position.x, 800.0, 1400.0)
    if absf(axis.x) > 0.1:
        player.flip_h = axis.x < 0
    if axis.length() > 0.1:
        var next_frame := int(elapsed * 7.0) % 4
        if next_frame != walk_frame:
            walk_frame = next_frame
            player.texture = load("res://starter_original/assets/png/characters/player_walk_%d.png" % walk_frame)
    else:
        if walk_frame != -1:
            player.texture = load("res://starter_original/assets/png/characters/player.png")
            walk_frame = -1
    _move_customers(delta)
    var target := _closest_interaction()
    prompt = target.get("label", "")
    if Input.is_key_pressed(KEY_E):
        if not _e_was_down:
            _interact(target)
        _e_was_down = true
    else:
        _e_was_down = false
    if Input.is_key_pressed(KEY_F5) and not _save_was_down:
        _save_game()
    _save_was_down = Input.is_key_pressed(KEY_F5)
    _refresh_ui()

func _move_customers(delta: float) -> void:
    for id in actor_sprites:
        var actor: Sprite2D = actor_sprites[id]
        if id == "agnes": continue
        if actor.position.distance_to(actor_targets[id]) < 12.0 and rng.randf() < delta * 0.17:
            actor_targets[id] = Vector2(rng.randf_range(250, 1650), rng.randf_range(615, 735))
        var direction: Vector2 = actor_targets[id] - actor.position
        if direction.length() > 10.0:
            actor.position += direction.normalized() * delta * (42.0 if id == "pip" else 62.0)
            actor.flip_h = direction.x < 0
        if id == "pip":
            actor.position.y += sin(elapsed * 2.0) * 0.15

func _closest_interaction() -> Dictionary:
    var best: Dictionary = {}
    var distance := 999999.0
    for target in interactables:
        var d: float = player.position.distance_to(target["position"])
        if d < target["radius"] and d < distance:
            distance = d
            best = target
    for id in actor_sprites:
        var d: float = player.position.distance_to(actor_sprites[id].position)
        if d < 125.0 and d < distance:
            distance = d
            best = {"id":id, "label":"Talk to " + id.capitalize()}
    return best

func _interact(target: Dictionary) -> void:
    if target.is_empty(): return
    match target["id"]:
        "fridge":
            inventory["strawberry_milk"] += 1
            _say("You picked up a strawberry milk. Pip's favourite!")
        "coffee": _say("The kettle hums softly. You brew a cup of moonflower tea.")
        "display":
            inventory["biscuits"] += 2
            _say("You neatly restocked the biscuit display. +2 biscuits")
        "counter":
            if inventory["biscuits"] > 0:
                inventory["biscuits"] -= 1
                money += 12
                _say("A customer bought biscuits. +12 coins")
            else: _say("The biscuit shelf is empty. Time to restock!")
        "pip":
            if inventory["strawberry_milk"] > 0 and not flags["pip_served"]:
                inventory["strawberry_milk"] -= 1
                money += 8
                moon_tokens += 1
                flags["pip_served"] = true
                _say("Pip: You remembered! Strawberry milk, just like always... Thank you!")
            else: _say("Pip: Some places feel like home, even when you can't remember why.")
        "agnes":
            flags["agnes_asked"] = true
            _say("Agnes: A receipt from 1974? That's strange, dear. Ask Miso where the old ledger went.")
        "receipt":
            flags["receipt_found"] = true
            _say("You found a faded receipt dated 1974. One strawberry milk. Customer: PIP.")
        "door":
            flags["backroom_checked"] = true
            _say("Behind the curtain: old boxes, a locked trunk, and a door outlined in moonlight...")
        "miso": _say("Miso purrs. For a moment, the crescent on the shop sign seems to glow brighter.")
        "fern": _say("Fern: The forest has been unusually quiet. Even the crickets have stopped singing.")
        "lucien": _say("Lucien: Do you have decaf? Immortality is exhausting enough without caffeine.")
        "wren": _say("Wren: There's magic in this shop. Old magic. And I don't think it wants to be forgotten.")
    _save_game()

func _say(line: String) -> void:
    paused_for_dialogue = true
    message_text.text = "  " + line + "\n  [Enter / Esc to continue]"
    message_panel.visible = true

func _finish_shift() -> void:
    shift += 1
    game_minutes = 0
    money += 15
    _save_game()
    _say("The first light of dawn arrives. Shift complete! +15 coins. A new night awaits.")

func _refresh_ui() -> void:
    var mins := int(game_minutes)
    var absolute_hour := (23 + int((30 + mins) / 60)) % 24
    var hour := absolute_hour % 12
    if hour == 0: hour = 12
    var suffix := "AM" if absolute_hour < 12 else "PM"
    var minute := (30 + mins) % 60
    hud.text = "  MOONMART  -  Night %d\n  %02d:%02d %s   -   %d coins   -   %d Moon Tokens\n  Pip's milk: %s  |  Receipt: %s" % [shift, hour, minute, suffix, money, moon_tokens, "yes" if flags["pip_served"] else "no", "yes" if flags["receipt_found"] else "no"]
    hint.text = "  WASD Move    E Interact    F5 Save\n  %s" % ("E  " + prompt if prompt != "" else "Explore the shop and meet your visitors")

func _save_game() -> void:
    var payload := {"version":1,"shift":shift,"minutes":game_minutes,"money":money,"moon_tokens":moon_tokens,"inventory":inventory,"flags":flags,"player_x":player.position.x,"player_y":player.position.y}
    var file := FileAccess.open("user://moonmart_save.json", FileAccess.WRITE)
    if file: file.store_string(JSON.stringify(payload, "  "))

func _load_game() -> void:
    if not FileAccess.file_exists("user://moonmart_save.json"): return
    var file := FileAccess.open("user://moonmart_save.json", FileAccess.READ)
    if file == null: return
    var payload = JSON.parse_string(file.get_as_text())
    if not payload is Dictionary or payload.get("version", 0) != 1: return
    shift = int(payload.get("shift", 1))
    game_minutes = float(payload.get("minutes", 0))
    money = int(payload.get("money", 250))
    moon_tokens = int(payload.get("moon_tokens", 0))
    inventory = payload.get("inventory", inventory)
    flags = payload.get("flags", flags)
    player.position = Vector2(float(payload.get("player_x", 800)), float(payload.get("player_y", 730)))
