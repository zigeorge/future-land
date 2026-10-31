extends TestCase

## Test suite for Inventory edge cases, stacking overflow, and slot bounds.
## Author: Tom (Tester)


func test_stack_overflow_splits_across_slots() -> void:
	var inventory := Inventory.new(5)
	var carrot := Registry.get_item(&"carrot")
	assert_true(carrot != null, "carrot item must exist in registry")

	# Max stack of carrot is 99. Adding 150 carrots should fill slot 0 with 99 and slot 1 with 51.
	var remaining := inventory.add_item(carrot, 150)
	assert_eq(remaining, 0, "all 150 carrots should fit into 5 slots")
	assert_eq(inventory.slots[0].count, 99, "slot 0 filled to maximum stack")
	assert_eq(inventory.slots[1].count, 51, "slot 1 holds remainder")
	assert_true(inventory.slots[2].is_empty(), "slot 2 remains empty")
	assert_eq(inventory.count_item(&"carrot"), 150, "total count equals 150")


func test_add_item_when_all_slots_full_returns_overflow() -> void:
	var inventory := Inventory.new(2)
	var hoe := Registry.get_item(&"hoe")
	assert_true(hoe != null)

	# Max stack of hoe is 1. Adding 3 hoes to 2 slots should leave 1 overflow.
	var overflow := inventory.add_item(hoe, 3)
	assert_eq(overflow, 1, "third hoe does not fit into two single-stack slots")
	assert_eq(inventory.count_item(&"hoe"), 2)


func test_remove_from_slot_reduces_count_and_clears_item() -> void:
	var inventory := Inventory.new(3)
	var seeds := Registry.get_item(&"carrot_seeds")
	inventory.add_item(seeds, 10)

	# Partial removal
	assert_true(inventory.remove_from_slot(0, 4))
	assert_eq(inventory.slots[0].count, 6)
	assert_eq(inventory.slots[0].item.id, &"carrot_seeds")

	# Removing remaining count empties the slot
	assert_true(inventory.remove_from_slot(0, 6))
	assert_true(inventory.slots[0].is_empty())
	assert_true(inventory.slots[0].item == null)

	# Removing from empty slot returns false
	assert_false(inventory.remove_from_slot(0, 1))


func test_invalid_and_negative_inputs_are_safely_ignored() -> void:
	var inventory := Inventory.new(3)
	var carrot := Registry.get_item(&"carrot")

	# Adding null item or non-positive amount returns input unchanged
	assert_eq(inventory.add_item(null, 5), 5)
	assert_eq(inventory.add_item(carrot, 0), 0)
	assert_eq(inventory.add_item(carrot, -5), -5)
	assert_eq(inventory.count_item(&"carrot"), 0)

	# Out-of-bounds slot index access returns null safely
	assert_true(inventory.get_item_at(-1) == null)
	assert_true(inventory.get_item_at(99) == null)
	assert_false(inventory.remove_from_slot(-1, 1))
	assert_false(inventory.remove_from_slot(99, 1))


func test_clear_inventory_resets_all_slots() -> void:
	var inventory := Inventory.new(4)
	inventory.add_item(Registry.get_item(&"hoe"), 1)
	inventory.add_item(Registry.get_item(&"watering_can"), 1)
	assert_eq(inventory.count_item(&"hoe"), 1)
	assert_eq(inventory.count_item(&"watering_can"), 1)

	inventory.clear()
	for i in inventory.size():
		assert_true(inventory.slots[i].is_empty(), "slot %d must be empty after clear" % i)
