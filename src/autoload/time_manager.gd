extends Node
## In-game clock and calendar.
##
## A year has 365 days: 4 seasons of 3 months, 12 months of 30-31 days.
## Time advances in 10-minute ticks. A day runs from 06:00 until 02:00 the
## next morning; at 02:00 the player passes out and the next day begins.

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
const MONTHS_PER_SEASON := 3
## Days in each month of the year; 3 months per season, 365 days in total.
const MONTH_DAYS: Array[int] = [30, 31, 30, 31, 30, 31, 30, 31, 30, 31, 30, 30]
const DAYS_PER_YEAR := 365
const MINUTES_PER_TICK := 10
const DAY_START_MINUTES := 6 * 60
const DAY_END_MINUTES := 26 * 60

## Real seconds per in-game 10-minute tick. A day has 120 ticks, so 4.5 s
## makes a day last 9 real minutes.
@export var seconds_per_tick := 4.5

## 1 on the first day of the year, 365 on the last.
var day_of_year := 1
var year := 1
## Minutes since midnight of the current day (may exceed 24 * 60 after midnight).
var minutes := DAY_START_MINUTES
## Paused during menus, dialogue and level transitions.
var paused := false

## Day of the current month (1-31).
var day: int:
	get:
		return _month_and_day().y
## Month of the year (1-12).
var month: int:
	get:
		return _month_and_day().x
var season: Season:
	get:
		return ((month - 1) / MONTHS_PER_SEASON) as Season

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


## Days since the game started: 1 on the first day, 366 on the first day of year 2.
func get_day_number() -> int:
	return (year - 1) * DAYS_PER_YEAR + day_of_year


func get_season_name() -> String:
	return SEASON_NAMES[season]


## Month within the season (1-3).
func get_month_of_season() -> int:
	return (month - 1) % MONTHS_PER_SEASON + 1


func get_clock_text() -> String:
	var hour := get_hour()
	var suffix := "am" if hour < 12 else "pm"
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, get_minute(), suffix]


func get_date_text() -> String:
	var text := "%s, Month %d, Day %d" % [get_season_name(), get_month_of_season(), day]
	return text if year == 1 else "%s, Year %d" % [text, year]


## Back to 06:00 on the first day of year 1 (new game).
func reset() -> void:
	day_of_year = 1
	year = 1
	minutes = DAY_START_MINUTES
	_accumulator = 0.0
	EventBus.time_ticked.emit(day, get_hour(), get_minute())


## Ends the current day and starts the next one (called by beds / passing out).
func start_next_day() -> void:
	day_of_year += 1
	if day_of_year > DAYS_PER_YEAR:
		day_of_year = 1
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


## (month, day of month) for day_of_year.
func _month_and_day() -> Vector2i:
	var remaining := day_of_year
	for i in MONTH_DAYS.size():
		if remaining <= MONTH_DAYS[i]:
			return Vector2i(i + 1, remaining)
		remaining -= MONTH_DAYS[i]
	return Vector2i(MONTH_DAYS.size(), MONTH_DAYS[-1])


func get_save_data() -> Dictionary:
	return {"day_of_year": day_of_year, "year": year, "minutes": minutes}


func load_save_data(data: Dictionary) -> void:
	day_of_year = clampi(int(data.get("day_of_year", 1)), 1, DAYS_PER_YEAR)
	year = int(data.get("year", 1))
	minutes = int(data.get("minutes", DAY_START_MINUTES))
	_accumulator = 0.0
	EventBus.time_ticked.emit(day, get_hour(), get_minute())
