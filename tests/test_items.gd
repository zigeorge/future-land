extends TestCase
## Checks the items generated from docs/Future_Land_Item_List.xlsx.

const ITEMS_DIR := "res://data/items/"


func _item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for file in DirAccess.get_files_at(ITEMS_DIR):
		if file.ends_with(".tres"):
			ids.append(StringName(file.get_basename()))
	return ids


func test_every_item_loads_with_matching_id() -> void:
	var ids := _item_ids()
	assert_true(ids.size() >= 90, "expected all tools, seeds, crops and fish, got %d" % ids.size())
	for id in ids:
		var item := Registry.get_item(id)
		assert_true(item != null, "%s loads" % id)
		if item:
			assert_eq(item.id, id, "id matches file name")
			assert_true(item.display_name != "", "%s has a name" % id)


func test_every_seed_has_a_crop_and_harvest() -> void:
	for id in _item_ids():
		var item := Registry.get_item(id)
		if item and item.category == ItemData.Category.SEED:
			var crop := Registry.get_crop(item.crop_id)
			assert_true(crop != null, "%s -> crop %s" % [id, item.crop_id])
			if crop:
				assert_true(crop.harvest_item != null and crop.harvest_item.sell_price > 0, "%s harvest sells" % crop.id)
				assert_true(crop.seasons != 0, "%s has a season" % crop.id)


func test_shop_lists_point_to_buyable_items() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shops.json"))
	var shops: Dictionary = data["shops"]
	for shop: String in ["merchant", "inventor", "fisherman"]:
		assert_true(shops.has(shop), "shop %s listed" % shop)
		for id: String in shops.get(shop, []):
			var item := Registry.get_item(StringName(id))
			assert_true(item != null and item.buy_price > 0 and item.shop == StringName(shop), "%s sells %s" % [shop, id])


func test_backpack_is_8_by_5_with_8_slot_hotbar() -> void:
	var game_state := load("res://src/autoload/game_state.gd")
	assert_eq(game_state.INVENTORY_SIZE, 40)
	assert_eq(game_state.HOTBAR_SIZE, 8)


func test_remove_from_slot() -> void:
	var inventory := Inventory.new(4)
	inventory.add_item(Registry.get_item(&"carrot"), 5)
	assert_true(inventory.remove_from_slot(0, 2))
	assert_eq(inventory.count_item(&"carrot"), 3)
	assert_true(inventory.remove_from_slot(0, 99))
	assert_true(inventory.slots[0].is_empty())
	assert_false(inventory.remove_from_slot(0, 1), "empty slot")
