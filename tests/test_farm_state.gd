extends TestCase

const SPRING := 0
const SUMMER := 1
const CELL := Vector2i(2, 3)


func test_must_till_before_planting() -> void:
	var farm := FarmState.new()
	assert_false(farm.plant(CELL, &"carrot"))
	assert_true(farm.till(CELL))
	assert_true(farm.plant(CELL, &"carrot"))


func test_watered_crop_grows_until_harvestable() -> void:
	var farm := _planted_farm()
	for day in Registry.get_crop(&"carrot").get_total_days():
		assert_false(farm.can_harvest(CELL), "not ready on day %d" % day)
		farm.water(CELL)
		farm.advance_day(SPRING)
	assert_true(farm.can_harvest(CELL))
	assert_eq(farm.harvest(CELL).id, &"carrot")
	assert_false(farm.get_tile(CELL).has_crop())


func test_dry_crop_does_not_grow() -> void:
	var farm := _planted_farm()
	farm.advance_day(SPRING)
	assert_eq(farm.get_tile(CELL).days_grown, 0)


func test_soil_dries_overnight() -> void:
	var farm := _planted_farm()
	farm.water(CELL)
	farm.advance_day(SPRING)
	assert_false(farm.get_tile(CELL).watered)


func test_out_of_season_crop_dies() -> void:
	var farm := _planted_farm()
	farm.advance_day(SUMMER)
	assert_false(farm.get_tile(CELL).has_crop())
	assert_true(farm.is_tilled(CELL), "soil stays tilled")


func test_save_round_trip() -> void:
	var farm := _planted_farm()
	farm.water(CELL)
	var loaded := FarmState.new()
	loaded.from_data(JSON.parse_string(JSON.stringify(farm.to_data())))
	var tile := loaded.get_tile(CELL)
	assert_true(tile != null)
	assert_eq(tile.crop_id, &"carrot")
	assert_true(tile.watered)


func _planted_farm() -> FarmState:
	var farm := FarmState.new()
	farm.till(CELL)
	farm.plant(CELL, &"carrot")
	return farm
