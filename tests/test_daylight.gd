extends TestCase
## Day / night tint and the season look.

const SPRING := 0
const WINTER := 3


func test_noon_is_full_daylight_and_midnight_is_night() -> void:
	for season in 4:
		assert_eq(Daylight.color_at(12 * 60, season), Daylight.DAY, "noon, season %d" % season)
		assert_eq(Daylight.color_at(24 * 60, season), Daylight.NIGHT, "midnight, season %d" % season)


func test_winter_gets_dark_earlier_than_summer() -> void:
	var evening := 18 * 60 + 30
	assert_eq(Daylight.color_at(evening, 1), Daylight.DAY, "summer evening is still light")
	assert_true(Daylight.color_at(evening, WINTER).v < 0.85, "winter evening is dark")


func test_the_light_changes_gradually_at_sunset() -> void:
	var sunset := Daylight.SUN_TIMES[SPRING].y
	var before := Daylight.color_at(sunset - 5, SPRING)
	var after := Daylight.color_at(sunset + 5, SPRING)
	assert_true(before.v - after.v < 0.1, "no sudden jump")


func test_season_look_leaves_spring_as_drawn() -> void:
	SeasonLook.set_season(SPRING)
	assert_eq(SeasonLook.get_material().get_shader_parameter("amount"), 0.0)
	SeasonLook.set_season(WINTER)
	assert_true(SeasonLook.get_material().get_shader_parameter("amount") > 0.5, "winter recolours")
	SeasonLook.set_season(TimeManager.season)
