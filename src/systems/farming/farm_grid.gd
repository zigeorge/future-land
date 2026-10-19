class_name FarmGrid
extends Node2D
## The farm's soil. Draws GameState.farm and turns the player's tool / seed /
## harvest actions into FarmState calls.
##
## Any open ground inside `area` can be tilled: not paths or water (tiles on
## the sibling GroundTiles layer) and not under a building, tree, fence or NPC.
##
## Soil uses dry_soil_texture / wet_soil_texture and crops use their
## CropData stage art; anything without art falls back to placeholder
## shapes drawn in _draw().

const GROUP := &"farm_grid"
const CELL_SIZE := 16

## Physics layers that make a cell untillable: 1 "world" and 3 "npc".
const OBSTACLE_MASK := (1 << 0) | (1 << 2)
const SOIL_COLOR := Color("6b4a2b")
const WET_SOIL_COLOR := Color("3f2a19")
const CROP_COLOR := Color("7bd389")
const READY_COLOR := Color("ffb703")
const CURSOR_COLOR := Color(1, 1, 1, 0.6)

## Cells where farming is allowed, relative to this node's position.
@export var area := Rect2i(0, 0, 16, 10)
## Tilled-soil tiles, any resolution (assets/art/tilesets/environment/soil_dry.png, soil_wet.png).
@export var dry_soil_texture: Texture2D
@export var wet_soil_texture: Texture2D

var _cursor_cell := Vector2i.MAX
var _target_cell := Vector2i.MAX
## crop id -> CropData, loaded outside _draw(): a texture loaded for the first
## time inside _draw() renders as a white box.
var _crops: Dictionary = {}


## Sibling tile layers whose tiles can't be farmed on (water, paths).
@onready var _blocking_layers: Array[TileMapLayer] = _find_layers(["../GroundTiles"])


func _ready() -> void:
	add_to_group(GROUP)
	EventBus.farm_changed.connect(func(_cell: Vector2i) -> void: _refresh())
	EventBus.game_loaded.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var target := world_to_cell(player.get_target_position()) if player else Vector2i.MAX
	if target == _target_cell:
		return
	_target_cell = target
	# Only highlight cells where the hoe (or seeds, water) would do something.
	var cell := target if GameState.farm.is_tilled(target) or can_till(target) else Vector2i.MAX
	if cell != _cursor_cell:
		_cursor_cell = cell
		queue_redraw()


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((to_local(world_position) / CELL_SIZE).floor())


func can_till(cell: Vector2i) -> bool:
	if not area.has_point(cell) or GameState.farm.is_tilled(cell):
		return false
	for layer in _blocking_layers:
		if layer.get_cell_source_id(cell) != -1:
			return false
	var query := PhysicsPointQueryParameters2D.new()
	query.position = to_global((Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE)
	query.collision_mask = OBSTACLE_MASK
	return get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


## Applies the given item to a cell. Returns true if something happened.
func use_item(item: ItemData, cell: Vector2i) -> bool:
	if not area.has_point(cell):
		return false
	match item.category:
		ItemData.Category.TOOL:
			return _use_tool(item, cell)
		ItemData.Category.SEED:
			return _plant_seed(item, cell)
	return false


func try_harvest(cell: Vector2i) -> bool:
	if not area.has_point(cell) or not GameState.farm.can_harvest(cell):
		return false
	var crop := GameState.farm.harvest(cell)
	var leftover := GameState.inventory.add_item(crop.harvest_item, crop.harvest_amount)
	if leftover > 0:
		# TODO(gameplay): drop leftover items on the ground instead.
		EventBus.notification_requested.emit("Inventory full!")
	EventBus.crop_harvested.emit(cell, crop.id)
	return true


func _use_tool(item: ItemData, cell: Vector2i) -> bool:
	if GameState.energy < item.energy_cost:
		EventBus.notification_requested.emit("Too tired...")
		return false
	var success := false
	match item.tool_type:
		ItemData.ToolType.HOE:
			success = can_till(cell) and GameState.farm.till(cell)
		ItemData.ToolType.WATERING_CAN:
			success = GameState.farm.water(cell)
	if success:
		GameState.spend_energy(item.energy_cost)
	return success


func _plant_seed(item: ItemData, cell: Vector2i) -> bool:
	var crop := Registry.get_crop(item.crop_id)
	if crop == null:
		return false
	if not crop.grows_in(TimeManager.season):
		EventBus.notification_requested.emit("%s can't grow in %s." % [crop.display_name, TimeManager.get_season_name()])
		return false
	if not GameState.farm.plant(cell, crop.id):
		return false
	GameState.inventory.remove_item(item.id, 1)
	if not GameState.has_story_flag(&"first_crop_planted"):
		GameState.set_story_flag(&"first_crop_planted")
	return true


func _draw() -> void:
	for cell: Vector2i in GameState.farm.tiles:
		var tile: FarmState.FarmTile = GameState.farm.tiles[cell]
		var rect := Rect2(cell * CELL_SIZE, Vector2.ONE * CELL_SIZE)
		var soil_texture := wet_soil_texture if tile.watered else dry_soil_texture
		if soil_texture:
			draw_texture_rect(soil_texture, rect, false)
		else:
			draw_rect(rect, WET_SOIL_COLOR if tile.watered else SOIL_COLOR)
		if tile.has_crop():
			_draw_crop(tile, rect)
	if _cursor_cell != Vector2i.MAX:
		draw_rect(Rect2(_cursor_cell * CELL_SIZE, Vector2.ONE * CELL_SIZE), CURSOR_COLOR, false, 1.0)


func _refresh() -> void:
	_target_cell = Vector2i.MAX  # Re-check the cursor cell.
	for tile: FarmState.FarmTile in GameState.farm.tiles.values():
		if tile.has_crop() and not _crops.has(tile.crop_id):
			var crop := Registry.get_crop(tile.crop_id)
			_crops[tile.crop_id] = crop
			if crop and crop.get_stage_count() > 0:
				texture_filter = Art.filter_for(crop.get_stage_texture(0), CELL_SIZE)
	queue_redraw()


func _draw_crop(tile: FarmState.FarmTile, rect: Rect2) -> void:
	var crop: CropData = _crops.get(tile.crop_id)
	if crop == null:
		return
	var stage := crop.get_stage(tile.days_grown)
	var texture := crop.get_stage_texture(stage)
	if texture:
		draw_texture_rect(texture, rect, false)
		return
	var final_stage := crop.days_per_stage.size()
	var radius := lerpf(2.0, CELL_SIZE * 0.4, float(stage) / final_stage)
	draw_circle(rect.get_center(), radius, READY_COLOR if stage == final_stage else CROP_COLOR)


func _find_layers(paths: Array) -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = []
	for path: String in paths:
		var layer := get_node_or_null(path) as TileMapLayer
		if layer:
			layers.append(layer)
	return layers
