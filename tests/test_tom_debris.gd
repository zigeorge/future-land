extends TestCase

## Test suite for farm debris mechanics, tool requirements, and serialization.
## Author: Tom (Tester)

const CELL_WEED := Vector2i(3, 4)
const CELL_BRANCH := Vector2i(5, 6)
const CELL_STONE := Vector2i(7, 8)
const CELL_EMPTY := Vector2i(10, 10)


func test_tool_type_restrictions_for_debris() -> void:
	var farm := FarmState.new()
	farm.debris[CELL_WEED] = "weed"
	farm.debris[CELL_BRANCH] = "branch"
	farm.debris[CELL_STONE] = "stone"

	# Hoe and watering can must not clear any debris
	assert_eq(farm.clear_debris(CELL_WEED, ItemData.ToolType.HOE), "")
	assert_eq(farm.clear_debris(CELL_BRANCH, ItemData.ToolType.WATERING_CAN), "")
	assert_eq(farm.clear_debris(CELL_STONE, ItemData.ToolType.CULTIVATOR), "")

	# Scythe clears weeds, but cannot clear branches or stones
	assert_eq(farm.clear_debris(CELL_BRANCH, ItemData.ToolType.SCYTHE), "")
	assert_eq(farm.clear_debris(CELL_STONE, ItemData.ToolType.SCYTHE), "")
	assert_eq(farm.clear_debris(CELL_WEED, ItemData.ToolType.SCYTHE), "weed")
	assert_false(farm.debris.has(CELL_WEED))

	# Axe clears branches and stones, but cannot clear weeds
	assert_eq(farm.clear_debris(CELL_BRANCH, ItemData.ToolType.AXE), "branch")
	assert_eq(farm.clear_debris(CELL_STONE, ItemData.ToolType.AXE), "stone")
	assert_false(farm.debris.has(CELL_BRANCH))
	assert_false(farm.debris.has(CELL_STONE))

	# Clearing non-existent debris returns empty string
	assert_eq(farm.clear_debris(CELL_EMPTY, ItemData.ToolType.AXE), "")


func test_clearing_debris_unblocks_tilling() -> void:
	var farm := FarmState.new()
	farm.debris[CELL_WEED] = "weed"
	farm.debris[CELL_STONE] = "stone"

	# Cannot till ground occupied by debris
	assert_false(farm.till(CELL_WEED), "cannot till over weed")
	assert_false(farm.till(CELL_STONE), "cannot till over stone")

	# Clearing debris makes tile tillable
	assert_eq(farm.clear_debris(CELL_WEED, ItemData.ToolType.SCYTHE), "weed")
	assert_true(farm.till(CELL_WEED), "cleared weed ground can be tilled")

	assert_eq(farm.clear_debris(CELL_STONE, ItemData.ToolType.AXE), "stone")
	assert_true(farm.till(CELL_STONE), "cleared stone ground can be tilled")


func test_debris_blocks_sprinkler_placement() -> void:
	var farm := FarmState.new()
	farm.debris[CELL_BRANCH] = "branch"

	# Cannot place sprinkler on top of debris
	assert_false(farm.place_sprinkler(CELL_BRANCH, 4), "sprinkler cannot be placed on branch")

	# Clear branch and verify sprinkler can be placed
	assert_eq(farm.clear_debris(CELL_BRANCH, ItemData.ToolType.AXE), "branch")
	assert_true(farm.place_sprinkler(CELL_BRANCH, 4), "sprinkler placed on cleared ground")


func test_debris_roundtrip_serialization() -> void:
	var farm := FarmState.new()
	farm.debris[CELL_WEED] = "weed"
	farm.debris[CELL_BRANCH] = "branch"
	farm.debris[CELL_STONE] = "stone"
	farm.debris_generated = true

	# Clear weed, leaving branch and stone
	assert_eq(farm.clear_debris(CELL_WEED, ItemData.ToolType.SCYTHE), "weed")

	# Serialize to dictionary and reload into fresh instance
	var saved_data := farm.to_data()
	var loaded_farm := FarmState.new()
	loaded_farm.from_data(saved_data)

	assert_true(loaded_farm.debris_generated, "debris_generated flag preserved")
	assert_false(loaded_farm.debris.has(CELL_WEED), "cleared weed is not restored")
	assert_eq(loaded_farm.debris.get(CELL_BRANCH), "branch", "branch preserved")
	assert_eq(loaded_farm.debris.get(CELL_STONE), "stone", "stone preserved")


func test_cell_changed_signal_emitted_on_successful_clear() -> void:
	var farm := FarmState.new()
	farm.debris[CELL_WEED] = "weed"

	var emitted_cells: Array[Vector2i] = []
	farm.cell_changed.connect(func(cell: Vector2i) -> void:
		emitted_cells.append(cell)
	)

	# Failed clear attempt should not emit signal
	farm.clear_debris(CELL_WEED, ItemData.ToolType.AXE)
	assert_eq(emitted_cells.size(), 0, "failed clear does not emit signal")

	# Successful clear should emit signal with the exact cell coordinate
	farm.clear_debris(CELL_WEED, ItemData.ToolType.SCYTHE)
	assert_eq(emitted_cells.size(), 1, "successful clear emits signal")
	assert_eq(emitted_cells[0], CELL_WEED, "signal emitted with target coordinate")
