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

const SPRINKLER_ICON := preload("res://assets/art/items/sprinkler.png")
const WEED_SHEET := preload("res://assets/art/tilesets/environment/grass_tufts.png")
const BRANCH_SHEET := preload("res://assets/art/environment/beach/driftwood.png")
const STONE := preload("res://assets/art/environment/rock_small.png")
## How much debris a new farm starts with (Zheng: scattered randomly).
const DEBRIS_COUNTS := {"weed": 70, "stone": 35, "branch": 35}
## No debris this close (in tiles) to the farmhouse door.
const CLEAR_AROUND_DOOR := 5
## Debris the player can't walk through (weeds stay passable).
const SOLID_DEBRIS := ["stone", "branch"]
const SOLID_DEBRIS_SIZE := 12.0

var _debris_art: Dictionary = {}  # "kind:variant" -> Texture2D, built in _ready
## Colliders for solid debris, on the "world" layer.
var _debris_body := StaticBody2D.new()
var _debris_shapes: Dictionary = {}  # Vector2i -> CollisionShape2D

var _cursor_cell := Vector2i.MAX
var _target_cell := Vector2i.MAX
## crop id -> CropData, loaded outside _draw(): a texture loaded for the first
## time inside _draw() renders as a white box.
var _crops: Dictionary = {}


## Sibling tile layers whose tiles can't be farmed on (water, paths).
@onready var _blocking_layers: Array[TileMapLayer] = _find_layers(["../GroundTiles"])


func _ready() -> void:
	add_to_group(GROUP)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # HD crop, soil and sprinkler art
	_debris_body.collision_layer = 1
	_debris_body.collision_mask = 0
	add_child(_debris_body)
	EventBus.farm_changed.connect(func(_cell: Vector2i) -> void: _refresh())
	EventBus.game_loaded.connect(_refresh)
	for i in 4:
		_debris_art["weed:%d" % i] = _atlas(WEED_SHEET, Vector2i(i, 0))
		_debris_art["branch:%d" % i] = _atlas(BRANCH_SHEET, Vector2i(i, 0))
		_debris_art["stone:%d" % i] = STONE
	_refresh()
	if not GameState.farm.debris_generated:
		# Wait a physics frame so buildings and trees can be detected.
		await get_tree().physics_frame
		_scatter_debris()


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var target := world_to_cell(player.get_target_position()) if player else Vector2i.MAX
	if target == _target_cell:
		return
	_target_cell = target
	# Only highlight cells where the hoe (or seeds, water) would do something.
	var farm := GameState.farm
	var cell := target if farm.is_tilled(target) or farm.has_sprinkler(target) or farm.debris.has(target) or can_till(target) else Vector2i.MAX
	if cell != _cursor_cell:
		_cursor_cell = cell
		queue_redraw()


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((to_local(world_position) / CELL_SIZE).floor())


func can_till(cell: Vector2i) -> bool:
	var farm := GameState.farm
	if not area.has_point(cell) or farm.is_tilled(cell) or farm.has_sprinkler(cell) or farm.debris.has(cell):
		return false
	for layer in _blocking_layers:
		if layer.get_cell_source_id(cell) != -1:
			return false
	var query := PhysicsPointQueryParameters2D.new()
	query.position = to_global((Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE)
	query.collision_mask = OBSTACLE_MASK
	return get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


## Why `cell` can't be tilled, as a message for the player ("" = it can).
func till_problem(cell: Vector2i) -> String:
	var farm := GameState.farm
	if not area.has_point(cell):
		return "You can't farm here"
	if farm.is_tilled(cell):
		return "This soil is already tilled"
	if farm.has_sprinkler(cell):
		return "A sprinkler is here (press E to pick it up)"
	if farm.debris.has(cell):
		var kind: String = farm.debris[cell]
		return "Clear the %s first (use the %s)" % [kind, "sickle" if kind == "weed" else "axe"]
	for layer in _blocking_layers:
		var source := layer.get_cell_source_id(cell)
		if source == 0:
			return "You can't dig up the path"
		if source != -1:
			return "You can't till water"
	if not can_till(cell):
		return "Something is in the way"
	return ""


## Applies the given item to a cell. Returns true if something happened.
func use_item(item: ItemData, cell: Vector2i) -> bool:
	if not area.has_point(cell):
		EventBus.notification_requested.emit("You can't farm here")
		return false
	match item.category:
		ItemData.Category.TOOL:
			return _use_tool(item, cell)
		ItemData.Category.SEED:
			return _plant_seed(item, cell)
	EventBus.notification_requested.emit("You can't use %s here. Ship it or sell it." % item.display_name)
	return false


func try_harvest(cell: Vector2i) -> bool:
	if area.has_point(cell) and GameState.farm.has_sprinkler(cell):
		return _pick_up_sprinkler(cell)
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
			var problem := till_problem(cell)
			if problem != "":
				EventBus.notification_requested.emit(problem)
				return false
			success = GameState.farm.till(cell)
		ItemData.ToolType.WATERING_CAN:
			var tile := GameState.farm.get_tile(cell)
			if tile == null:
				EventBus.notification_requested.emit("Water tilled soil: use the hoe first")
				return false
			if tile.watered:
				EventBus.notification_requested.emit("Already watered today")
				return false
			success = GameState.farm.water(cell)
		ItemData.ToolType.CULTIVATOR:
			success = _cultivate(cell, item.effective_range)
		ItemData.ToolType.SCYTHE, ItemData.ToolType.AXE, ItemData.ToolType.PICKAXE:
			success = _clear(item, cell)
		ItemData.ToolType.SPRINKLER:
			return _place_sprinkler(item, cell)
	if success:
		GameState.spend_energy(item.energy_cost)
	return success


## Tills up to `reach` tiles in a line, starting at `cell`, away from the player.
func _cultivate(cell: Vector2i, reach: int) -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	var step := Vector2i(player.facing) if player else Vector2i.DOWN
	var tilled := 0
	for i in reach:
		var target := cell + step * i
		if can_till(target) and GameState.farm.till(target):
			tilled += 1
	if tilled == 0:
		EventBus.notification_requested.emit(till_problem(cell))
	return tilled > 0


## Clears debris with a sickle / axe (and a line of `effective_range` cells
## for the lawn mower).
func _clear(item: ItemData, cell: Vector2i) -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	var step := Vector2i(player.facing) if player else Vector2i.DOWN
	var cleared := 0
	for i in item.effective_range:
		if GameState.farm.clear_debris(cell + step * i, item.tool_type) != "":
			cleared += 1
	if cleared == 0 and GameState.farm.debris.has(cell):
		var kind: String = GameState.farm.debris[cell]
		var tool_name := "sickle" if kind == "weed" else "axe"
		EventBus.notification_requested.emit("Use the %s on this %s" % [tool_name, kind])
	elif cleared == 0:
		EventBus.notification_requested.emit("Nothing to clear here")
	return cleared > 0


func _scatter_debris() -> void:
	var farm := GameState.farm
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var door := get_node_or_null("../Entities/FarmhouseDoor") as Node2D
	var door_cell := world_to_cell(door.global_position) if door else Vector2i(-99, -99)
	var free_cells: Array[Vector2i] = []
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			var cell := Vector2i(x, y)
			if (cell - door_cell).length() > CLEAR_AROUND_DOOR and can_till(cell) and not _touches_obstacle(cell):
				free_cells.append(cell)
	for kind: String in DEBRIS_COUNTS:
		for i in DEBRIS_COUNTS[kind]:
			if free_cells.is_empty():
				break
			var cell: Vector2i = free_cells.pop_at(rng.randi() % free_cells.size())
			farm.debris[cell] = kind
	farm.debris_generated = true
	_sync_debris_shapes()
	queue_redraw()


## Adds or removes colliders so they match the solid debris on the farm.
func _sync_debris_shapes() -> void:
	var debris := GameState.farm.debris
	for cell: Vector2i in _debris_shapes.keys():
		if debris.get(cell, "") not in SOLID_DEBRIS:
			_debris_shapes[cell].queue_free()
			_debris_shapes.erase(cell)
	for cell: Vector2i in debris:
		if debris[cell] in SOLID_DEBRIS and not _debris_shapes.has(cell):
			var rect := RectangleShape2D.new()
			rect.size = Vector2.ONE * SOLID_DEBRIS_SIZE
			var shape := CollisionShape2D.new()
			shape.shape = rect
			shape.position = (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE
			_debris_body.add_child(shape)
			_debris_shapes[cell] = shape


## True if a building, fence or tree overlaps any part of the cell (can_till
## only checks its centre, and a fence crosses the bottom of a cell).
func _touches_obstacle(cell: Vector2i) -> bool:
	var rect := RectangleShape2D.new()
	rect.size = Vector2.ONE * (CELL_SIZE - 2)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = rect
	query.transform = Transform2D(0, to_global((Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE))
	query.collision_mask = OBSTACLE_MASK
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


static func _atlas(sheet: Texture2D, cell: Vector2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(cell * 128, Vector2(128, 128))
	return atlas


func _place_sprinkler(item: ItemData, cell: Vector2i) -> bool:
	if not can_till(cell):
		EventBus.notification_requested.emit("Place sprinklers on open grass next to your crops")
		return false
	if not GameState.farm.place_sprinkler(cell, item.effective_range):
		return false
	GameState.inventory.remove_item(item.id, 1)
	EventBus.notification_requested.emit("Sprinkler placed: waters 4 tiles around it every morning (E: pick up)")
	return true


func _pick_up_sprinkler(cell: Vector2i) -> bool:
	var sprinkler := Registry.get_item(&"sprinkler")
	if GameState.inventory.add_item(sprinkler, 1) > 0:
		EventBus.notification_requested.emit("Backpack is full")
		return false
	GameState.farm.remove_sprinkler(cell)
	return true


func _plant_seed(item: ItemData, cell: Vector2i) -> bool:
	var crop := Registry.get_crop(item.crop_id)
	if crop == null:
		return false
	if not crop.grows_in(TimeManager.season):
		EventBus.notification_requested.emit("%s can't grow in %s." % [crop.display_name, TimeManager.get_season_name()])
		return false
	var tile := GameState.farm.get_tile(cell)
	if tile == null:
		EventBus.notification_requested.emit("Plant seeds in tilled soil: use the hoe first")
		return false
	if tile.has_crop():
		EventBus.notification_requested.emit("Something is already planted here")
		return false
	if not GameState.farm.plant(cell, crop.id):
		return false
	GameState.inventory.remove_item(item.id, 1)
	var next_season := (TimeManager.season + 1) % TimeManager.SEASON_NAMES.size()
	var days_left := TimeManager.get_days_left_in_season()
	if not crop.grows_in(next_season) and crop.get_total_days() > days_left:
		var season_end := "tonight" if days_left == 0 else "in %d day%s" % [days_left, "" if days_left == 1 else "s"]
		EventBus.notification_requested.emit("%s needs %d days to grow, but %s ends %s: it will wither" % [
			crop.display_name, crop.get_total_days(), TimeManager.get_season_name(), season_end])
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
	for cell: Vector2i in GameState.farm.debris:
		var kind: String = GameState.farm.debris[cell]
		var texture: Texture2D = _debris_art.get("%s:%d" % [kind, posmod(cell.x * 7 + cell.y * 3, 4)])
		if texture:
			var inset := 1.0 if kind == "stone" else 0.0
			draw_texture_rect(texture, Rect2(cell * CELL_SIZE, Vector2.ONE * CELL_SIZE).grow(-inset), false)
	for cell: Vector2i in GameState.farm.sprinklers:
		draw_texture_rect(SPRINKLER_ICON, Rect2(cell * CELL_SIZE, Vector2.ONE * CELL_SIZE), false)
	if _cursor_cell != Vector2i.MAX:
		draw_rect(Rect2(_cursor_cell * CELL_SIZE, Vector2.ONE * CELL_SIZE), CURSOR_COLOR, false, 1.0)


func _refresh() -> void:
	_target_cell = Vector2i.MAX  # Re-check the cursor cell.
	_sync_debris_shapes()
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
