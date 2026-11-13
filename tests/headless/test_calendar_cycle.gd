extends Node

const CalendarScript = preload("res://scripts/systems/calendar_manager.gd")

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/calendar.json"))
	_expect(parsed is Dictionary, "calendar production config parses")
	if not parsed is Dictionary:
		_finish()
		return
	var calendar = CalendarScript.new()
	calendar.setup(parsed, 9127)
	_expect(calendar.days_per_season == 14 and calendar.days_per_year == 56, "calendar keeps four 14-shift seasons in a 56-shift year")
	_expect(String(calendar.date_for_shift(1).season_id) == "spring" and int(calendar.date_for_shift(1).season_day) == 1, "first shift begins spring on its first day")
	_expect(String(calendar.date_for_shift(14).season_id) == "spring" and int(calendar.date_for_shift(14).season_day) == 14, "spring ends on its fourteenth shift")
	_expect(String(calendar.date_for_shift(15).season_id) == "summer" and int(calendar.date_for_shift(15).season_day) == 1, "summer begins after fourteen spring shifts")
	_expect(String(calendar.date_for_shift(56).season_id) == "winter" and int(calendar.date_for_shift(56).season_day) == 14, "winter ends on the last shift of the first year")
	_expect(int(calendar.date_for_shift(57).year) == 2 and String(calendar.date_for_shift(57).season_id) == "spring", "a 56-shift year rolls into spring of the next year")
	var occurrences: Dictionary = {}
	for shift_number in range(1, calendar.days_per_year + 1):
		var festival: Dictionary = calendar.festival_for_shift(shift_number)
		if not festival.is_empty():
			var festival_id := String(festival.get("id", ""))
			occurrences[festival_id] = int(occurrences.get(festival_id, 0)) + 1
	_expect(occurrences.size() == 8, "all eight configured festivals have a date in the year")
	for festival_id in occurrences:
		_expect(int(occurrences[festival_id]) == 1, "%s occurs exactly once per year" % String(festival_id))
	_expect(calendar.next_festival_shift("spring_bloom", 3) == 4, "next-festival lookup includes the upcoming shift")
	_expect(calendar.next_festival_shift("spring_bloom", 4) == 60, "a missed festival recurs on the same date next year")
	_expect(calendar.next_festival_shift("summer_firefly", 2) == 18, "next-festival lookup crosses the spring-to-summer boundary")
	_expect(calendar.next_festival_shift("not_a_festival", 1) == -1, "unknown festival IDs do not create phantom dates")
	var weather_first_pass: Array[String] = []
	var weather_repeat_pass: Array[String] = []
	for shift_number in range(1, calendar.days_per_year + 1):
		weather_first_pass.append(calendar.weather_for_shift(shift_number))
	for shift_number in range(1, calendar.days_per_year + 1):
		weather_repeat_pass.append(calendar.weather_for_shift(shift_number))
	_expect(weather_first_pass == weather_repeat_pass, "weather stays deterministic for a stable calendar seed")
	calendar.set_current_shift(4)
	_expect(calendar.mark_festival_attended("spring_bloom"), "a configured festival attendance can be recorded")
	var saved_state: Dictionary = calendar.export_state()
	var restored = CalendarScript.new()
	restored.setup(parsed, 1)
	restored.import_state(saved_state)
	_expect(restored.has_attended_festival("spring_bloom", 1), "festival attendance persists across calendar save and load")
	_expect(not restored.has_attended_festival("spring_bloom", 2), "festival attendance is tracked separately by year")
	_finish()

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _finish() -> void:
	if failures.is_empty():
		print("Calendar cycle checks passed: %d checks." % checks)
	else:
		for failure in failures:
			push_error(failure)
		print("Calendar cycle checks failed: %d of %d." % [failures.size(), checks])
	get_tree().quit(0 if failures.is_empty() else 1)
