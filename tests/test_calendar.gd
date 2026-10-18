extends TestCase

const TimeScript := preload("res://src/autoload/time_manager.gd")


func test_year_has_365_days_in_12_months() -> void:
	var total := 0
	for days in TimeScript.MONTH_DAYS:
		total += days
	assert_eq(total, TimeScript.DAYS_PER_YEAR)
	assert_eq(TimeScript.MONTH_DAYS.size(), 4 * TimeScript.MONTHS_PER_SEASON)


func test_days_map_to_months_and_seasons() -> void:
	var time: Node = TimeScript.new()
	var cases := {
		1: [1, 1, TimeScript.Season.SPRING],
		30: [1, 30, TimeScript.Season.SPRING],
		31: [2, 1, TimeScript.Season.SPRING],
		91: [3, 30, TimeScript.Season.SPRING],
		92: [4, 1, TimeScript.Season.SUMMER],
		365: [12, 30, TimeScript.Season.WINTER],
	}
	for day_of_year: int in cases:
		time.day_of_year = day_of_year
		assert_eq([time.month, time.day, time.season], cases[day_of_year], "day %d" % day_of_year)
	time.free()


func test_a_day_lasts_nine_minutes() -> void:
	var time: Node = TimeScript.new()
	var ticks := (TimeScript.DAY_END_MINUTES - TimeScript.DAY_START_MINUTES) / TimeScript.MINUTES_PER_TICK
	assert_eq(ticks * time.seconds_per_tick, 9.0 * 60.0)
	time.free()
