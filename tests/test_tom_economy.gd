extends TestCase

## Test suite for economy pricing, zero-arbitrage exploit audits, and shipping bin settlement.
## Author: Tom (Tester)

const ITEMS_DIR := "res://data/items/"
const CROPS_DIR := "res://data/crops/"


func _ids_in(dir: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			ids.append(StringName(file.get_basename()))
	return ids


func test_no_item_sells_for_more_than_buy_price() -> void:
	for item_id: StringName in _ids_in(ITEMS_DIR):
		var item: ItemData = Registry.get_item(item_id)
		if item and item.buy_price > 0 and item.sell_price > 0:
			assert_true(
				item.sell_price <= item.buy_price,
				"Arbitrage exploit detected: %s sells for %d but costs %d" % [item.id, item.sell_price, item.buy_price]
			)


func test_durable_tools_permit_full_refund() -> void:
	# Verified list of 8 durable goods that resell at 100% purchase price
	var durable_items: Array[StringName] = [
		&"fishing_rod",
		&"lawn_mower",
		&"echo_sonar_caster",
		&"cultivator",
		&"chainsaw",
		&"sprinkler",
		&"nano_net_launcher",
		&"quantum_tide_harvester",
	]
	for id in durable_items:
		var item: ItemData = Registry.get_item(id)
		assert_true(item != null, "Durable item %s must exist in Registry" % id)
		if item:
			assert_eq(item.sell_price, item.buy_price, "%s must resell at full purchase price" % id)


func test_all_crops_yield_positive_profit_margin() -> void:
	for crop_id: StringName in _ids_in(CROPS_DIR):
		var crop: CropData = Registry.get_crop(crop_id)
		var seed_item: ItemData = Registry.get_item(StringName(String(crop_id) + "_seeds"))
		assert_true(crop != null, "Crop %s must exist" % crop_id)
		assert_true(seed_item != null, "Seed item must exist for crop %s" % crop_id)
		if not crop or not seed_item:
			continue

		var harvest_item: ItemData = crop.harvest_item
		assert_true(harvest_item != null, "Harvest item must exist for crop %s" % crop_id)
		if not harvest_item:
			continue

		var total_revenue: int = harvest_item.sell_price * crop.harvest_amount
		var seed_cost: int = seed_item.buy_price
		assert_true(
			total_revenue > seed_cost,
			"Crop %s produces net loss: revenue %d <= seed cost %d" % [crop_id, total_revenue, seed_cost]
		)


func test_shipping_bin_valuation_multi_item() -> void:
	var state: Node = load("res://src/autoload/game_state.gd").new()
	state.inventory = Inventory.new(8)
	state.shipping.clear()
	state.money = 100

	# Put 3 carrots (48g each = 144g) and 2 radishes (28g each = 56g) into shipping
	var carrot: ItemData = Registry.get_item(&"carrot")
	var radish: ItemData = Registry.get_item(&"radish")
	state.shipping.append({"id": "carrot", "count": 3})
	state.shipping.append({"id": "radish", "count": 2})

	var expected_total: int = (3 * carrot.sell_price) + (2 * radish.sell_price)
	assert_eq(state.shipping_value(), expected_total, "Shipping value calculation must match item prices")

	state._sell_shipping()
	assert_eq(state.money, 100 + expected_total, "Money must increment by exact shipping revenue")
	assert_true(state.shipping.is_empty(), "Shipping bin must be cleared after overnight sale")
	state.free()
