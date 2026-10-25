class_name Fishing
## Fishing: cast into water with a fishing tool; what bites depends on the
## season, the tool's level (a level-2 tool catches level 1-2 fish) and each
## fish's catch chance (data from the item list).

## Tile sources in a level's GroundTiles layer that are water (all tiles).
const WATER_SOURCES: Array[int] = [1, 7]
## Beach atlas: tile x = 0 is sand, x >= 1 shore and sea.
const BEACH_SOURCE := 8
## Chance that something bites at all on a cast.
const BITE_CHANCE := 0.8
const ITEMS_DIR := "res://data/items/"

static var _fish: Array[ItemData] = []


static func is_water(level: Node, world_position: Vector2) -> bool:
	var ground := level.get_node_or_null("GroundTiles") as TileMapLayer if level else null
	if ground == null:
		return false
	var cell := ground.local_to_map(ground.to_local(world_position))
	var source := ground.get_cell_source_id(cell)
	if source == BEACH_SOURCE:
		return ground.get_cell_atlas_coords(cell).x >= 1
	return source in WATER_SOURCES


## Fish that can bite now with a tool of `tool_level`.
static func candidates(tool_level: int, season: int) -> Array[ItemData]:
	if _fish.is_empty():
		for file in DirAccess.get_files_at(ITEMS_DIR):
			if file.ends_with(".tres"):
				var item := Registry.get_item(StringName(file.get_basename()))
				if item and item.category == ItemData.Category.FISH:
					_fish.append(item)
	return _fish.filter(func(f: ItemData) -> bool:
		return f.level <= tool_level and f.seasons & (1 << season) != 0)


## The fish caught on one cast, or null. `roll` and `pick` are 0..1 random numbers.
static func catch(tool_level: int, season: int, roll: float, pick: float) -> ItemData:
	var fish := candidates(tool_level, season)
	if fish.is_empty() or roll >= BITE_CHANCE:
		return null
	var total := 0.0
	for f in fish:
		total += f.catch_chance
	var target := pick * total
	for f in fish:
		target -= f.catch_chance
		if target <= 0.0:
			return f
	return fish[-1]
