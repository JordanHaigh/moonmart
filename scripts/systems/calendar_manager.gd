class_name MoonmartCalendar
extends RefCounted

## Seasonal calendar keyed to completed overnight shifts. Story progression is
## intentionally not consulted here, so seasons and festivals cannot gate it.
signal calendar_changed(date: Dictionary)

var days_per_season := 14
var days_per_year := 56
var weekdays: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
var seasons: Array[Dictionary] = []
var festivals: Array[Dictionary] = []
var current_shift := 1
var seed_value := 73129
var attended_festivals: Dictionary = {}

func setup(config: Dictionary, seed: int = 73129) -> void:
	seed_value = seed
	days_per_season = maxi(1, int(config.get("days_per_season", 14)))
	days_per_year = maxi(days_per_season, int(config.get("days_per_year", days_per_season * 4)))
	weekdays.clear()
	for weekday in config.get("weekdays", ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]):
		weekdays.append(String(weekday))
	if weekdays.is_empty():
		weekdays = ["Day"]
	seasons.clear()
	for season in config.get("seasons", []):
		if season is Dictionary and not String(season.get("id", "")).is_empty():
			seasons.append(season.duplicate(true))
	if seasons.is_empty():
		seasons = [
			{"id": "spring", "name": "Spring", "weather_weights": {"clear": 1}},
			{"id": "summer", "name": "Summer", "weather_weights": {"clear": 1}},
			{"id": "autumn", "name": "Autumn", "weather_weights": {"clear": 1}},
			{"id": "winter", "name": "Winter", "weather_weights": {"clear": 1}}
		]
		days_per_year = days_per_season * seasons.size()
	festivals.clear()
	for festival in config.get("festivals", []):
		if festival is Dictionary and not String(festival.get("id", "")).is_empty():
			var row: Dictionary = festival.duplicate(true)
			row["season_day"] = clampi(int(row.get("season_day", 1)), 1, days_per_season)
			festivals.append(row)

func set_current_shift(shift_number: int) -> void:
	current_shift = maxi(1, shift_number)
	calendar_changed.emit(current_date())

func advance_shift() -> void:
	set_current_shift(current_shift + 1)

func current_date() -> Dictionary:
	return date_for_shift(current_shift)

func date_for_shift(shift_number: int) -> Dictionary:
	var safe_shift := maxi(1, shift_number)
	var zero_day := safe_shift - 1
	var day_of_year := posmod(zero_day, days_per_year) + 1
	var year := int(zero_day / days_per_year) + 1
	var season_index := mini(int((day_of_year - 1) / days_per_season), seasons.size() - 1)
	var season: Dictionary = seasons[season_index]
	var season_day := posmod(day_of_year - 1, days_per_season) + 1
	var weekday := weekdays[posmod(zero_day, weekdays.size())]
	return {
		"shift": safe_shift,
		"year": year,
		"day_of_year": day_of_year,
		"season_id": String(season.get("id", "")),
		"season": String(season.get("name", season.get("id", "Season"))),
		"season_day": season_day,
		"weekday": weekday
	}

func current_season() -> Dictionary:
	return season_for_shift(current_shift)

func season_for_shift(shift_number: int) -> Dictionary:
	var date := date_for_shift(shift_number)
	for season in seasons:
		if String(season.get("id", "")) == String(date.get("season_id", "")):
			return season.duplicate(true)
	return {}

func current_weather() -> String:
	return weather_for_shift(current_shift)

func weather_for_shift(shift_number: int) -> String:
	var season := season_for_shift(shift_number)
	var weights: Dictionary = season.get("weather_weights", {"clear": 1})
	var total := 0
	for weather in weights:
		total += maxi(0, int(weights[weather]))
	if total <= 0:
		return "clear"
	var roll := posmod(_weather_hash(maxi(1, shift_number)), total)
	for weather in weights:
		roll -= maxi(0, int(weights[weather]))
		if roll < 0:
			return String(weather)
	return "clear"

func current_festival() -> Dictionary:
	return festival_for_shift(current_shift)

func festival_for_shift(shift_number: int) -> Dictionary:
	var date := date_for_shift(shift_number)
	for festival in festivals:
		if String(festival.get("season", "")) == String(date.get("season_id", "")) and int(festival.get("season_day", 0)) == int(date.get("season_day", 0)):
			return festival.duplicate(true)
	return {}

## Returns the next scheduled occurrence, including next year's date if this
## year's festival was missed. Attendance never alters the recurrence.
func next_festival_shift(festival_id: String, after_shift: int = -1) -> int:
	var festival := _festival_by_id(festival_id)
	if festival.is_empty():
		return -1
	var start_shift := current_shift if after_shift < 0 else maxi(0, after_shift)
	var season_index := _season_index(String(festival.get("season", "")))
	if season_index < 0:
		return -1
	var target_day := season_index * days_per_season + int(festival.get("season_day", 1))
	var candidate := int(floor(float(start_shift) / days_per_year)) * days_per_year + target_day
	if candidate <= start_shift:
		candidate += days_per_year
	return candidate

func mark_festival_attended(festival_id: String, shift_number: int = -1) -> bool:
	if _festival_by_id(festival_id).is_empty():
		return false
	var attended_shift := current_shift if shift_number < 0 else maxi(1, shift_number)
	var year := int(floor(float(attended_shift - 1) / days_per_year)) + 1
	attended_festivals["%s:%d" % [festival_id, year]] = true
	return true

func has_attended_festival(festival_id: String, year: int = -1) -> bool:
	var target_year := int(current_date().get("year", 1)) if year < 0 else maxi(1, year)
	return bool(attended_festivals.get("%s:%d" % [festival_id, target_year], false))

func export_state() -> Dictionary:
	return {"current_shift": current_shift, "seed": seed_value, "attended_festivals": attended_festivals.duplicate(true)}

func import_state(data: Dictionary) -> void:
	current_shift = maxi(1, int(data.get("current_shift", 1)))
	seed_value = int(data.get("seed", seed_value))
	attended_festivals = data.get("attended_festivals", {}).duplicate(true)
	calendar_changed.emit(current_date())

func _festival_by_id(festival_id: String) -> Dictionary:
	for festival in festivals:
		if String(festival.get("id", "")) == festival_id:
			return festival
	return {}

func _season_index(season_id: String) -> int:
	for index in range(seasons.size()):
		if String(seasons[index].get("id", "")) == season_id:
			return index
	return -1

func _weather_hash(shift_number: int) -> int:
	var value := posmod(seed_value, 2147483647)
	value = posmod(value + shift_number * 48271, 2147483647)
	value = posmod(value * 16807 + 1, 2147483647)
	return value
