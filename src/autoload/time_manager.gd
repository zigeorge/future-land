extends Node
## In-game clock and calendar: minutes, days, seasons, years.
##
## Time advances in 10-minute ticks. A day runs from 06:00 until 02:00 the
## next morning; at 02:00 the player passes out and the next day begins.

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
const DAYS_PER_SEASON := 28
const MINUTES_PER_TICK := 10
const DAY_START_MINUTES := 6 * 60
const DAY_END_MINUTES := 26 * 60

## Real seconds per in-game tick (Stardew Valley uses ~7 s per 10 minutes).
@export var seconds_per_tick := 7.0

var day := 1
var season: Season = Season.SPRING
var year := 1
## Minutes since midnight of the current day (may exceed 24 * 60 after midnight).
var minutes := DAY_START_MINUTES
## Paused during menus, dialogue and level transitions.
var paused := false

var _accumulator := 0.0


func _process(delta: float) -> void:
	if paused or DialogueManager.is_active():
		return
	_accumulator += delta
	while _accumulator >= seconds_per_tick:
		_accumulator -= seconds_per_tick
		_tick()


func get_hour() -> int:
	return (minutes / 60) % 24


func get_minute() -> int:
	return minutes % 60


## Days since the game started: 1 on the first day, 29 on Summer 1, ...
func get_day_number() -> int:
	return ((year - 1) * SEASON_NAMES.size() + season) * DAYS_PER_SEASON + day


func get_season_name() -> String:
	return SEASON_NAMES[season]


func get_clock_text() -> String:
	var hour := get_hour()
	var suffix := "am" if hour < 12 else "pm"
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, get_minute(), suffix]


func get_date_text() -> String:
	return "%s %d, Year %d" % [get_season_name(), day, year]


## Ends the current day and starts the next one (called by beds / passing out).
func start_next_day() -> void:
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season = ((season + 1) % SEASON_NAMES.size()) as Season
		if season == Season.SPRING:
			year += 1
	minutes = DAY_START_MINUTES
	_accumulator = 0.0
	EventBus.day_started.emit(day, season, year)
	EventBus.time_ticked.emit(day, get_hour(), get_minute())


func _tick() -> void:
	minutes += MINUTES_PER_TICK
	EventBus.time_ticked.emit(day, get_hour(), get_minute())
	if minutes >= DAY_END_MINUTES:
		# TODO(gameplay): penalty for passing out (money / energy).
		start_next_day()


func get_save_data() -> Dictionary:
	return {"day": day, "season": season, "year": year, "minutes": minutes}


func load_save_data(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	season = int(data.get("season", Season.SPRING)) as Season
	year = int(data.get("year", 1))
	minutes = int(data.get("minutes", DAY_START_MINUTES))
	_accumulator = 0.0
	EventBus.time_ticked.emit(day, get_hour(), get_minute())
