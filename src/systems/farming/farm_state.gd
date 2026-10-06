class_name FarmState
extends RefCounted
## The farm's soil and crops, stored as data so it persists when the farm
## scene is not loaded. FarmGrid (the node in the farm level) only draws it
## and turns player actions into calls on this class.

signal cell_changed(cell: Vector2i)

## Vector2i -> FarmTile
var tiles: Dictionary = {}


class FarmTile:
	var watered := false
	var crop_id: StringName = &""
	var days_grown := 0

	func has_crop() -> bool:
		return crop_id != &""


func clear() -> void:
	tiles.clear()


func get_tile(cell: Vector2i) -> FarmTile:
	return tiles.get(cell)


func is_tilled(cell: Vector2i) -> bool:
	return tiles.has(cell)


func till(cell: Vector2i) -> bool:
	if is_tilled(cell):
		return false
	tiles[cell] = FarmTile.new()
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
## and all soil dries out.
func advance_day(season: int) -> void:
	for cell: Vector2i in tiles:
		var tile: FarmTile = tiles[cell]
		if tile.has_crop():
			var crop := Registry.get_crop(tile.crop_id)
			if crop == null or not crop.grows_in(season):
				tile.crop_id = &""
				tile.days_grown = 0
			elif tile.watered:
				tile.days_grown += 1
		tile.watered = false
		cell_changed.emit(cell)


func to_data() -> Dictionary:
	var data := {}
	for cell: Vector2i in tiles:
		var tile: FarmTile = tiles[cell]
		data["%d,%d" % [cell.x, cell.y]] = {
			"watered": tile.watered,
			"crop_id": String(tile.crop_id),
			"days_grown": tile.days_grown,
		}
	return data


func from_data(data: Dictionary) -> void:
	tiles.clear()
	for key: String in data:
		var parts := key.split(",")
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		var tile := FarmTile.new()
		tile.watered = bool(data[key].get("watered", false))
		tile.crop_id = StringName(data[key].get("crop_id", ""))
		tile.days_grown = int(data[key].get("days_grown", 0))
		tiles[cell] = tile
		cell_changed.emit(cell)
