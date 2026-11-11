extends Node2D

# Minimal self-contained Moonmart walkable prototype.
# Placeholder procedural visuals; production sprites are not yet uploaded.
const WALK_SPEED := 230.0
const FLOOR_Y := 650.0
var player_pos := Vector2(800, FLOOR_Y)
var customer_pos := Vector2(350, FLOOR_Y)
var coins := 40
var strawberry_milk := 3
var message := "Welcome to Moonmart! Walk with A/D or arrows. E: interact."
var clock_minutes := 0.0
var moonmart_font: Font = ThemeDB.fallback_font

func _process(delta: float) -> void:
    var movement := Input.get_axis("ui_left", "ui_right")
    if Input.is_key_pressed(KEY_A):
        movement -= 1.0
    if Input.is_key_pressed(KEY_D):
        movement += 1.0
    player_pos.x = clampf(player_pos.x + clampf(movement, -1.0, 1.0) * WALK_SPEED * delta, 80.0, 1520.0)
    customer_pos.x += sin(Time.get_ticks_msec() / 900.0) * delta * 22.0
    clock_minutes = fmod(clock_minutes + delta * 14.4, 360.0)
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_E:
        if absf(player_pos.x - 1280.0) < 150.0:
            if strawberry_milk > 0:
                strawberry_milk -= 1
                coins += 8
                message = "You sold strawberry milk. Pip will be delighted!"
            else:
                message = "Out of strawberry milk! Restock at the shelves."
        elif absf(player_pos.x - 460.0) < 150.0:
            strawberry_milk += 1
            message = "Restocked one strawberry milk."
        else:
            message = "Walk to the shelves (left) or register (right), then press E."
        queue_redraw()
    elif event.keycode == KEY_F5:
        var save := {"player_x": player_pos.x, "coins": coins, "milk": strawberry_milk, "clock": clock_minutes}
        var file := FileAccess.open("user://moonmart_save.json", FileAccess.WRITE)
        if file:
            file.store_string(JSON.stringify(save))
            message = "Shift saved."

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1600, 900), Color("#302a4b"))
    draw_rect(Rect2(0, 560, 1600, 340), Color("#776084"))
    draw_rect(Rect2(70, 90, 1460, 480), Color("#554365"))
    draw_rect(Rect2(520, 125, 500, 340), Color("#242846"))
    draw_circle(Vector2(790, 210), 66, Color("#f8e5c9"))
    for i in 7:
        draw_rect(Rect2(115 + i * 180, 470, 120, 95), Color("#957394"))
    draw_rect(Rect2(280, 300, 340, 270), Color("#a18091"))
    draw_rect(Rect2(300, 320, 300, 230), Color("#695373"))
    for i in 4:
        draw_rect(Rect2(320, 345 + i * 50, 260, 15), Color("#d2a18d"))
    draw_rect(Rect2(1120, 450, 330, 145), Color("#c68f94"))
    draw_rect(Rect2(1140, 470, 290, 22), Color("#f2c4a4"))
    draw_circle(customer_pos + Vector2(0, -70), 30, Color("#f4e3d4"))
    draw_rect(Rect2(customer_pos.x - 23, FLOOR_Y - 42, 46, 60), Color("#9f829e"))
    draw_circle(player_pos + Vector2(0, -85), 32, Color("#f8d4bb"))
    draw_rect(Rect2(player_pos.x - 25, FLOOR_Y - 54, 50, 65), Color("#e7c0b2"))
    draw_circle(Vector2(1080, 360), 32, Color("#fff2d9"))
    draw_string(moonmart_font, Vector2(70, 65), "Moonmart", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("#fff0dd"))
    draw_string(moonmart_font, Vector2(70, 105), "A cozy supernatural mystery | Prototype", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#f7d9d2"))
    draw_string(moonmart_font, Vector2(1120, 65), "Coins: %d   Milk: %d" % [coins, strawberry_milk], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#fff0dd"))
    draw_string(moonmart_font, Vector2(60, 810), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#fff0dd"))
    draw_string(moonmart_font, Vector2(60, 855), "A/D: Move   E: Interact   F5: Save", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#fff0dd"))
