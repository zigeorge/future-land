extends TestCase

## Test suite for season progression, crop lifecycle across seasons, and boundary wipes.
## Author: Tom (Tester)

const SPRING := 0
const SUMMER := 1
const AUTUMN := 2
const WINTER := 3

const CELL_A := Vector2i(4, 5)
const CELL_B := Vector2i(6, 7)


func test_spring_crops_die_on_summer_rollover() -> void:
	var farm := FarmState.new()
	farm.till(CELL_A)
	assert_true(farm.plant(CELL_A, &"radish"))
	assert_true(farm.get_tile(CELL_A).has_crop())

	# Spring day advance: crop survives and grows if watered
	farm.water(CELL_A)
	farm.advance_day(SPRING)
	assert_true(farm.get_tile(CELL_A).has_crop())
	assert_eq(farm.get_tile(CELL_A).days_grown, 1)

	# Transition into Summer: Spring crop is out-of-season and must be cleared
	farm.advance_day(SUMMER)
	assert_false(farm.get_tile(CELL_A).has_crop(), "Spring crop should be wiped in Summer")
	assert_eq(farm.get_tile(CELL_A).days_grown, 0, "Days grown should reset to 0")
	assert_true(farm.is_tilled(CELL_A), "Soil must stay tilled after crop dies")


func test_summer_crops_die_on_autumn_rollover() -> void:
	var farm := FarmState.new()
	farm.till(CELL_A)
	assert_true(farm.plant(CELL_A, &"watermelon"))

	# Advance into Autumn: Summer crop dies
	farm.advance_day(AUTUMN)
	assert_false(farm.get_tile(CELL_A).has_crop(), "Summer crop should be wiped in Autumn")
	assert_true(farm.is_tilled(CELL_A), "Soil stays tilled")


func test_autumn_crops_die_on_winter_rollover() -> void:
	var farm := FarmState.new()
	farm.till(CELL_A)
	assert_true(farm.plant(CELL_A, &"pumpkin"))

	# Advance into Winter: Autumn crop dies
	farm.advance_day(WINTER)
	assert_false(farm.get_tile(CELL_A).has_crop(), "Autumn crop should be wiped in Winter")
	assert_true(farm.is_tilled(CELL_A), "Soil stays tilled")


func test_winter_crops_die_on_spring_rollover() -> void:
	var farm := FarmState.new()
	farm.till(CELL_A)
	assert_true(farm.plant(CELL_A, &"brussels_sprout"))

	# Advance into Spring: Winter crop dies
	farm.advance_day(SPRING)
	assert_false(farm.get_tile(CELL_A).has_crop(), "Winter crop should be wiped in Spring")
	assert_true(farm.is_tilled(CELL_A), "Soil stays tilled")


func test_crop_grows_in_correct_season_only() -> void:
	var radish := Registry.get_crop(&"radish")
	assert_true(radish.grows_in(SPRING))
	assert_false(radish.grows_in(SUMMER))
	assert_false(radish.grows_in(AUTUMN))
	assert_false(radish.grows_in(WINTER))

	var watermelon := Registry.get_crop(&"watermelon")
	assert_false(watermelon.grows_in(SPRING))
	assert_true(watermelon.grows_in(SUMMER))
	assert_false(watermelon.grows_in(AUTUMN))
	assert_false(watermelon.grows_in(WINTER))
