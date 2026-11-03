class_name Player
extends CharacterBody2D
## Top-down player: movement, facing, interacting and using the selected item.
##
## The look comes from the avatar chosen at the start (GameState.avatar_id,
## data/avatars/). $Placeholder shows until an avatar is applied.

const INTERACT_REACH := 12.0

@export var speed := 90.0
## World zoom: 2 shows about 20 x 11 tiles, like Stardew Valley. Keep it a
## whole number so pixel art stays sharp. The HUD isn't affected.
@export var camera_zoom := 2:
	set(value):
		camera_zoom = maxi(value, 1)
		if is_node_ready():
			camera.zoom = Vector2.ONE * camera_zoom

var facing := Vector2.DOWN

var _avatar: AvatarData
## True while waiting for a bite; the player can't move.
var _fishing := false
## True while a tool is being swung; the player can't move or use another.
var _using_tool := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var interact_area: Area2D = $InteractArea
@onready var camera: Camera2D = $Camera2D
@onready var placeholder: CanvasItem = $Placeholder


func _ready() -> void:
	add_to_group("player")
	camera.zoom = Vector2.ONE * camera_zoom
	interact_area.position = facing * INTERACT_REACH
	EventBus.avatar_changed.connect(_on_avatar_changed)
	_on_avatar_changed(GameState.avatar_id)


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if not DialogueManager.is_active() and not _fishing and not _using_tool:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		facing = _to_cardinal(direction)
		interact_area.position = facing * INTERACT_REACH
	_update_animation(direction != Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if DialogueManager.is_active() or _fishing or _using_tool:
		return
	if event.is_action_pressed("interact"):
		# A ripe crop straight ahead comes first: the shipping bin stands next to the field.
		if _try_harvest():
			AudioManager.play_ui(&"pickup")
			get_viewport().set_input_as_handled()
		elif _interact_with_nearest():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("use_tool"):
		_use_selected_item()
		get_viewport().set_input_as_handled()


## Places the player without camera smoothing lag (used on level load).
func teleport(world_position: Vector2) -> void:
	global_position = world_position
	camera.reset_smoothing()


func set_camera_limits(bounds: Rect2i) -> void:
	camera.limit_left = bounds.position.x
	camera.limit_top = bounds.position.y
	camera.limit_right = bounds.end.x
	camera.limit_bottom = bounds.end.y


## World position of the tile in front of the player (what tools act on).
func get_target_position() -> Vector2:
	return global_position + facing * FarmGrid.CELL_SIZE


func apply_avatar(avatar: AvatarData) -> void:
	_avatar = avatar
	sprite.sprite_frames = avatar.build_sprite_frames() if avatar else null
	placeholder.visible = sprite.sprite_frames == null
	if avatar:
		Art.fit_sprite(sprite, Vector2(avatar.get_frame_size()), AvatarData.WORLD_FRAME_SIZE)
	_update_animation(false)


func _on_avatar_changed(avatar_id: StringName) -> void:
	apply_avatar(Registry.get_avatar(avatar_id) if avatar_id != &"" else null)


func _interact_with_nearest() -> bool:
	var nearest: Interactable = null
	var nearest_distance := INF
	for area in interact_area.get_overlapping_areas():
		if area is Interactable:
			var distance := global_position.distance_squared_to(area.global_position)
			if distance < nearest_distance:
				nearest = area
				nearest_distance = distance
	if nearest == null:
		return false
	nearest.interact(self)
	return true


func _try_harvest() -> bool:
	var farm := _get_farm_grid()
	return farm != null and farm.try_harvest(farm.world_to_cell(get_target_position()))


func _use_selected_item() -> void:
	var item := GameState.get_selected_item()
	if item and item.tool_type == ItemData.ToolType.FISHING:
		_cast(item)
		return
	var farm := _get_farm_grid()
	if item == null:
		return
	if farm == null:
		var farm_item := item.category == ItemData.Category.SEED or item.tool_type != ItemData.ToolType.NONE
		EventBus.notification_requested.emit("Use this on your farm" if farm_item else "You can't use %s here" % item.display_name)
		AudioManager.play_ui(&"error")
		return
	var cell := farm.world_to_cell(get_target_position())
	if item.category != ItemData.Category.TOOL or item.tool_type == ItemData.ToolType.SPRINKLER:
		# Seeds and sprinklers: no swing; seeds are tossed onto the tile.
		if farm.use_item(item, cell):
			AudioManager.play_tool(item)
			if item.category == ItemData.Category.SEED:
				_show_tool_action(item, farm, cell)
		else:
			AudioManager.play_ui(&"error")
		return
	# Tools: the swing plays even if nothing is there; the tile changes when it lands.
	_using_tool = true
	_update_animation(false)
	var debris_kind: String = GameState.farm.debris.get(cell, "")
	var action := _show_tool_action(item, farm, cell)
	await action.hit
	if farm.use_item(item, cell):
		AudioManager.play_tool(item)
		action.burst(ToolAction.bit_color(item, debris_kind))
	else:
		AudioManager.play_ui(&"error")
	await action.finished
	_using_tool = false


func _show_tool_action(item: ItemData, farm: FarmGrid, cell: Vector2i) -> ToolAction:
	var action := ToolAction.new()
	add_child(action)
	var tile_center := farm.to_global((Vector2(cell) + Vector2(0.5, 0.5)) * FarmGrid.CELL_SIZE)
	action.play(item, facing, tile_center - global_position)
	return action


func _cast(rod: ItemData) -> void:
	var level := get_tree().current_scene.get("_level") as Node
	# Cast two tiles out if that's water, else one. The bobber floats 2 px
	# above the target, so that's the point that has to be water.
	var bobber := Vector2(0, -2)
	var target := global_position + facing * FarmGrid.CELL_SIZE * 2.0
	if not Fishing.is_water(level, target + bobber):
		target = get_target_position()
	if not Fishing.is_water(level, target + bobber):
		EventBus.notification_requested.emit("Face the water to fish")
		AudioManager.play_ui(&"error")
		return
	if not GameState.spend_energy(rod.energy_cost):
		EventBus.notification_requested.emit("Too tired...")
		return
	_fishing = true
	_update_animation(false)
	AudioManager.play_tool(rod)
	var cast := FishingCast.new()
	add_child(cast)
	cast.setup(rod, facing, target + bobber, Fishing.catch(rod.level, TimeManager.season, randf(), randf()))
	var fish: ItemData = await cast.finished
	_fishing = false
	if fish == null:
		return
	if GameState.inventory.add_item(fish, 1) > 0:
		EventBus.notification_requested.emit("Your backpack is full, the %s got away" % fish.display_name)
	else:
		AudioManager.play_ui(&"pickup")
		EventBus.notification_requested.emit("You caught a %s! (sells for %d g)" % [fish.display_name, fish.sell_price])


func _get_farm_grid() -> FarmGrid:
	return get_tree().get_first_node_in_group(FarmGrid.GROUP) as FarmGrid


func _update_animation(moving: bool) -> void:
	var direction := _direction_name(facing)
	var animation := ("walk_" if moving else "idle_") + direction
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)
		sprite.flip_h = _avatar != null and _avatar.is_mirrored(direction)


static func _to_cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0 else Vector2.UP


static func _direction_name(direction: Vector2) -> String:
	match direction:
		Vector2.UP:
			return "up"
		Vector2.LEFT:
			return "left"
		Vector2.RIGHT:
			return "right"
	return "down"
