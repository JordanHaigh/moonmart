class_name MoonmartTime
extends RefCounted

signal time_changed(minutes_from_start: float, clock_text: String)
signal shift_time_reached

var shift_minutes := 360.0
var prep_minutes := 30.0
var standard_rate := 0.24
var vertical_slice_rate := 0.5
var vertical_slice_shifts := 5
var elapsed_minutes: float = 0.0
var minutes_per_real_second: float = 0.5
var paused: bool = false
var running: bool = false
var speed_multiplier: float = 1.0
var active_profile := "vertical_slice"
var _finish_emitted := false

func configure(balance: Dictionary) -> void:
	shift_minutes = maxf(60.0, float(balance.get("standard_shift_minutes", shift_minutes)))
	prep_minutes = clampf(float(balance.get("preparation_minutes", prep_minutes)), 0.0, shift_minutes)
	standard_rate = clampf(float(balance.get("standard_minutes_per_real_second", standard_rate)), 0.05, 2.0)
	vertical_slice_shifts = maxi(0, int(balance.get("vertical_slice_shifts", vertical_slice_shifts)))
	vertical_slice_rate = clampf(float(balance.get("vertical_slice_minutes_per_real_second", vertical_slice_rate)), 0.05, 2.0)

func set_shift_profile(shift_number: int) -> void:
	active_profile = "vertical_slice" if shift_number <= vertical_slice_shifts else "standard"
	minutes_per_real_second = vertical_slice_rate if active_profile == "vertical_slice" else standard_rate

func start() -> void:
	elapsed_minutes = 0.0
	running = true
	paused = false
	_finish_emitted = false
	emit_time()

func tick(delta: float) -> void:
	if not running or paused:
		return
	elapsed_minutes = minf(shift_minutes, elapsed_minutes + delta * minutes_per_real_second * speed_multiplier)
	emit_time()
	if elapsed_minutes >= shift_minutes and not _finish_emitted:
		_finish_emitted = true
		running = false
		shift_time_reached.emit()

func close_early() -> void:
	if not running:
		return
	running = false
	shift_time_reached.emit()

func emit_time() -> void:
	time_changed.emit(elapsed_minutes, clock_text())

func clock_text() -> String:
	var total := int(floor(prep_minutes + elapsed_minutes))
	var hour_24 := (23 + int(total / 60)) % 24
	var period := "AM" if hour_24 < 12 else "PM"
	var hour := hour_24 % 12
	if hour == 0:
		hour = 12
	var minute := total % 60
	return "%02d:%02d %s" % [hour, minute, period]

func is_open() -> bool:
	return elapsed_minutes >= prep_minutes

func to_save() -> Dictionary:
	return {"elapsed_minutes": elapsed_minutes, "running": running, "paused": paused, "speed_multiplier": speed_multiplier, "minutes_per_real_second": minutes_per_real_second, "active_profile": active_profile}

func from_save(data: Dictionary) -> void:
	elapsed_minutes = clampf(float(data.get("elapsed_minutes", 0.0)), 0.0, shift_minutes)
	running = bool(data.get("running", false))
	paused = bool(data.get("paused", false))
	speed_multiplier = clampf(float(data.get("speed_multiplier", 1.0)), 0.25, 3.0)
	minutes_per_real_second = clampf(float(data.get("minutes_per_real_second", minutes_per_real_second)), 0.05, 2.0)
	active_profile = String(data.get("active_profile", "vertical_slice"))
	_finish_emitted = elapsed_minutes >= shift_minutes
	emit_time()
