extends TestCase


func test_add_item_stacks_into_one_slot() -> void:
	var inventory := Inventory.new(5)
	var seeds := Registry.get_item(&"carrot_seeds")
	inventory.add_item(seeds, 10)
	inventory.add_item(seeds, 5)
	assert_eq(inventory.slots[0].count, 15)
	assert_true(inventory.slots[1].is_empty())


func test_add_item_returns_overflow_when_full() -> void:
	var inventory := Inventory.new(1)
	var hoe := Registry.get_item(&"hoe")
	assert_eq(inventory.add_item(hoe, 1), 0)
	assert_eq(inventory.add_item(hoe, 1), 1, "max_stack of a hoe is 1")


func test_remove_item_fails_without_enough() -> void:
	var inventory := Inventory.new(5)
	inventory.add_item(Registry.get_item(&"carrot"), 2)
	assert_false(inventory.remove_item(&"carrot", 3))
	assert_eq(inventory.count_item(&"carrot"), 2)
	assert_true(inventory.remove_item(&"carrot", 2))
	assert_true(inventory.slots[0].is_empty())


func test_save_round_trip() -> void:
	var inventory := Inventory.new(5)
	inventory.add_item(Registry.get_item(&"hoe"), 1)
	inventory.add_item(Registry.get_item(&"carrot_seeds"), 7)
	var loaded := Inventory.new(5)
	loaded.from_data(JSON.parse_string(JSON.stringify(inventory.to_data())))
	assert_eq(loaded.get_item_at(0).id, &"hoe")
	assert_eq(loaded.count_item(&"carrot_seeds"), 7)
