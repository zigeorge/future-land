extends TestCase

const SPRING := 0


func test_tool_level_limits_the_fish() -> void:
	for fish in Fishing.candidates(1, SPRING):
		assert_eq(fish.level, 1, "%s needs a better tool" % fish.id)
	assert_true(Fishing.candidates(4, SPRING).size() > Fishing.candidates(1, SPRING).size())


func test_season_limits_the_fish() -> void:
	for fish in Fishing.candidates(4, SPRING):
		assert_true(fish.seasons & 1 != 0, "%s is not a spring fish" % fish.id)


func test_catch_rolls() -> void:
	assert_eq(Fishing.catch(1, SPRING, 0.99, 0.5), null, "no bite")
	var fish := Fishing.catch(1, SPRING, 0.0, 0.0)
	assert_true(fish != null and fish.category == ItemData.Category.FISH)


func test_ending_dialogue_pays_and_ends() -> void:
	var graph := DialogueGraph.load_file("res://data/dialogue/year_end_resolution_farm_saved.json")
	var pays := graph.nodes.values().any(func(n: Dictionary) -> bool: return n.get("pay_buyback", false))
	var ends := graph.nodes.values().any(func(n: Dictionary) -> bool: return n.get("ending", "") == "saved")
	assert_true(pays and ends)



func test_only_the_surf_on_a_shore_tile_is_water() -> void:
	var level := Node2D.new()
	var ground := TileMapLayer.new()
	ground.name = "GroundTiles"
	ground.tile_set = load("res://assets/art/tilesets/world_tileset.tres")
	ground.scale = Vector2.ONE / 8.0  # 128 px tiles drawn as 16 px cells, like the beach
	ground.set_cell(Vector2i(0, 0), Fishing.BEACH_SOURCE, Vector2i(0, 0))
	ground.set_cell(Vector2i(0, 1), Fishing.BEACH_SOURCE, Vector2i(Fishing.SHORE_TILE, 0))
	ground.set_cell(Vector2i(0, 2), Fishing.BEACH_SOURCE, Vector2i(2, 0))
	level.add_child(ground)
	assert_false(Fishing.is_water(level, Vector2(8, 8)), "sand")
	assert_false(Fishing.is_water(level, Vector2(8, 22)), "sand at the top of the shore tile")
	assert_true(Fishing.is_water(level, Vector2(8, 30)), "surf at the bottom of the shore tile")
	assert_true(Fishing.is_water(level, Vector2(8, 40)), "sea")
	level.free()
