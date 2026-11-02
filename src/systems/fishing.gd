class_name Fishing
## Fishing: cast into water with a fishing tool; what bites depends on the
## season, the tool's level (a level-2 tool catches level 1-2 fish) and each
## fish's catch chance (data from the item list).

## Tile sources in a level's GroundTiles layer that are water (all tiles).
const WATER_SOURCES: Array[int] = [1, 7]
## Beach atlas: tile x = 0 is sand, x = 1 shore, x >= 2 sea.
const BEACH_SOURCE := 8
const SHORE_TILE := 1
## The shore tile is sand above this fraction of its height and surf below.
const SHORE_WATER_FROM := 0.8
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
		var x := ground.get_cell_atlas_coords(cell).x
		if x != SHORE_TILE:
			return x > SHORE_TILE
		var local := ground.to_local(world_position)
		var top := ground.map_to_local(cell).y - ground.tile_set.tile_size.y / 2.0
		return (local.y - top) / ground.tile_set.tile_size.y >= SHORE_WATER_FROM
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
