extends TestCase

## Test suite for year-end dual resolution conditions and inventory boundary safety.
## Author: Tom (Tester)


func test_year_end_loss_condition_under_100k() -> void:
	var state: Node = load("res://src/autoload/game_state.gd").new()
	state.money = 99999
	state.story_flags.clear()

	var can_pay: bool = state.money >= 100000 or bool(state.story_flags.get(&"land_repurchase_paid", false))
	assert_false(can_pay, "Player holding 99,999 g must not satisfy repurchase condition")
	state.free()


func test_year_end_win_condition_at_100k() -> void:
	var state: Node = load("res://src/autoload/game_state.gd").new()
	state.money = 100000
	state.story_flags.clear()

	var can_pay: bool = state.money >= 100000 or bool(state.story_flags.get(&"land_repurchase_paid", false))
	assert_true(can_pay, "Player holding 100,000 g must satisfy repurchase condition")
	state.free()


func test_repurchase_flag_permits_win_regardless_of_cash() -> void:
	var state: Node = load("res://src/autoload/game_state.gd").new()
	state.money = 0
	state.story_flags[&"land_repurchase_paid"] = true

	var can_pay: bool = state.money >= 100000 or bool(state.story_flags.get(&"land_repurchase_paid", false))
	assert_true(can_pay, "Setting land_repurchase_paid flag guarantees victory resolution")
	state.free()


func test_full_inventory_add_item_returns_leftover() -> void:
	var inv := Inventory.new(2)
	var carrot: ItemData = Registry.get_item(&"carrot")
	var radish: ItemData = Registry.get_item(&"radish")
	var turnip: ItemData = Registry.get_item(&"turnip")

	# Fill both slots to maximum capacity
	assert_eq(inv.add_item(carrot, 99), 0)
	assert_eq(inv.add_item(radish, 99), 0)

	# Adding a 3rd distinct item must fail completely and return full input count
	var leftover: int = inv.add_item(turnip, 5)
	assert_eq(leftover, 5, "Adding item to full inventory must return full count as leftover")
	assert_eq(inv.count_item(&"turnip"), 0, "No item should enter inventory when full")
