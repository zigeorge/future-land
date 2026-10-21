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

