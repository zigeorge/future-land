class_name FarmState
extends RefCounted
## The farm's soil and crops, stored as data so it persists when the farm
## scene is not loaded. FarmGrid (the node in the farm level) only draws it
## and turns player actions into calls on this class.

signal cell_changed(cell: Vector2i)

## Vector2i -> FarmTile
var tiles: Dictionary = {}
## Placed sprinklers: Vector2i -> how many tiles they water (effective range).
var sprinklers: Dictionary = {}
## Weeds, stones and branches on the farm: Vector2i -> "weed" / "stone" / "branch".
var debris: Dictionary = {}
## Set once the farm has been scattered with debris (new game).
var debris_generated := false

## Which tool clears which debris.
const CLEARED_BY := {
	"weed": [ItemData.ToolType.SCYTHE],
	"branch": [ItemData.ToolType.AXE],
	"stone": [ItemData.ToolType.AXE, ItemData.ToolType.PICKAXE],  # axe until a pickaxe exists
}


class FarmTile:
	var watered := false
	var crop_id: StringName = &""
	var days_grown := 0

	func has_crop() -> bool:
		return crop_id != &""


func clear() -> void:
	tiles.clear()
	sprinklers.clear()
	debris.clear()
	debris_generated = false


func get_tile(cell: Vector2i) -> FarmTile:
	return tiles.get(cell)


func is_tilled(cell: Vector2i) -> bool:
	return tiles.has(cell)


func till(cell: Vector2i) -> bool:
	if is_tilled(cell) or has_sprinkler(cell) or debris.has(cell):
		return false
	tiles[cell] = FarmTile.new()
	for sprinkler: Vector2i in sprinklers:
		if cell in sprinkler_cells(sprinkler, sprinklers[sprinkler]):
			tiles[cell].watered = true
	cell_changed.emit(cell)
	return true


func water(cell: Vector2i) -> bool:
	var tile := get_tile(cell)
	if tile == null or tile.watered:
		return false
	tile.watered = true
	cell_changed.emit(cell)
	return true


func plant(cell: Vector2i, crop_id: StringName) -> bool:
	var tile := get_tile(cell)
	if tile == null or tile.has_crop():
		return false
	tile.crop_id = crop_id
	tile.days_grown = 0
	cell_changed.emit(cell)
	return true


## Removes debris if `tool_type` can clear it. Returns the debris kind, or "".
func clear_debris(cell: Vector2i, tool_type: int) -> String:
	var kind: String = debris.get(cell, "")
	if kind == "" or not tool_type in CLEARED_BY[kind]:
		return ""
	debris.erase(cell)
	cell_changed.emit(cell)
	return kind


func has_sprinkler(cell: Vector2i) -> bool:
	return sprinklers.has(cell)


## Places a sprinkler on open (untilled) ground.
func place_sprinkler(cell: Vector2i, reach: int) -> bool:
	if is_tilled(cell) or has_sprinkler(cell) or debris.has(cell):
		return false
	sprinklers[cell] = reach
	_water_around(cell)
	cell_changed.emit(cell)
	return true


## Removes a sprinkler; returns false if there is none.
func remove_sprinkler(cell: Vector2i) -> bool:
	if not sprinklers.erase(cell):
		return false
	cell_changed.emit(cell)
	return true


## Cells a sprinkler waters: range 4 = the 4 neighbours, 8 = all 8 around it.
static func sprinkler_cells(cell: Vector2i, reach: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [cell + Vector2i.UP, cell + Vector2i.DOWN, cell + Vector2i.LEFT, cell + Vector2i.RIGHT]
	if reach >= 8:
		cells.append_array([cell + Vector2i(-1, -1), cell + Vector2i(1, -1), cell + Vector2i(-1, 1), cell + Vector2i(1, 1)])
	return cells


func _water_around(sprinkler: Vector2i) -> void:
	for cell in sprinkler_cells(sprinkler, sprinklers[sprinkler]):
		var tile := get_tile(cell)
		if tile and not tile.watered:
			tile.watered = true
			cell_changed.emit(cell)


func can_harvest(cell: Vector2i) -> bool:
	var tile := get_tile(cell)
	if tile == null or not tile.has_crop():
		return false
	var crop := Registry.get_crop(tile.crop_id)
	return crop != null and crop.is_ready(tile.days_grown)


## Removes a ready crop and returns its CropData (null if nothing to harvest).
func harvest(cell: Vector2i) -> CropData:
	if not can_harvest(cell):
		return null
	var tile := get_tile(cell)
	var crop := Registry.get_crop(tile.crop_id)
	tile.crop_id = &""
	tile.days_grown = 0
	cell_changed.emit(cell)
	return crop


## Called once each morning: watered crops grow, out-of-season crops die,
## all soil dries out, then sprinklers water the soil around them.
## Grows watered crops one day. Crops that can't grow in `season` wither;
## returns their names (one entry per tile).
func advance_day(season: int) -> Array[String]:
	var withered: Array[String] = []
	for cell: Vector2i in tiles:
		var tile: FarmTile = tiles[cell]
		if tile.has_crop():
			var crop := Registry.get_crop(tile.crop_id)
			if crop == null or not crop.grows_in(season):
				withered.append(crop.display_name if crop else String(tile.crop_id))
				tile.crop_id = &""
				tile.days_grown = 0
			elif tile.watered:
				tile.days_grown += 1
		tile.watered = false
		cell_changed.emit(cell)
	for sprinkler: Vector2i in sprinklers:
		_water_around(sprinkler)
	return withered


func to_data() -> Dictionary:
	var data := {}
	for cell: Vector2i in tiles:
		var tile: FarmTile = tiles[cell]
		data["%d,%d" % [cell.x, cell.y]] = {
			"watered": tile.watered,
			"crop_id": String(tile.crop_id),
			"days_grown": tile.days_grown,
		}
	var placed := {}
	for cell: Vector2i in sprinklers:
		placed["%d,%d" % [cell.x, cell.y]] = sprinklers[cell]
	if not placed.is_empty():
		data["_sprinklers"] = placed
	var scattered := {}
	for cell: Vector2i in debris:
		scattered["%d,%d" % [cell.x, cell.y]] = debris[cell]
	data["_debris"] = scattered
	data["_debris_generated"] = debris_generated
	return data


func from_data(data: Dictionary) -> void:
	tiles.clear()
	sprinklers.clear()
	debris.clear()
	var scattered: Dictionary = data.get("_debris", {})
	for key: String in scattered:
		var d := key.split(",")
		debris[Vector2i(int(d[0]), int(d[1]))] = str(scattered[key])
	debris_generated = bool(data.get("_debris_generated", false))
	var placed: Dictionary = data.get("_sprinklers", {})
	for key: String in placed:
		var p := key.split(",")
		sprinklers[Vector2i(int(p[0]), int(p[1]))] = int(placed[key])
	for key: String in data:
		if key.begins_with("_"):
			continue
		var parts := key.split(",")
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		var tile := FarmTile.new()
		tile.watered = bool(data[key].get("watered", false))
		tile.crop_id = StringName(data[key].get("crop_id", ""))
		tile.days_grown = int(data[key].get("days_grown", 0))
		tiles[cell] = tile
		cell_changed.emit(cell)
