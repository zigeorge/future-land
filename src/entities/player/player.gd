class_name Player
extends CharacterBody2D
## Top-down player: movement, facing, interacting and using the selected item.
##
## Art hookup: give $Sprite a SpriteFrames with animations named
## idle_down / idle_up / idle_left / idle_right and
## walk_down / walk_up / walk_left / walk_right. Frames are 16x32 with the
## feet at the bottom; $Placeholder hides itself once frames are assigned.

const INTERACT_REACH := 12.0

@export var speed := 90.0

var facing := Vector2.DOWN

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var interact_area: Area2D = $InteractArea
@onready var camera: Camera2D = $Camera2D
@onready var placeholder: CanvasItem = $Placeholder


func _ready() -> void:
	add_to_group("player")
	placeholder.visible = sprite.sprite_frames == null
	interact_area.position = facing * INTERACT_REACH


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if not DialogueManager.is_active():
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		facing = _to_cardinal(direction)
		interact_area.position = facing * INTERACT_REACH
	_update_animation(direction != Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if DialogueManager.is_active():
		return
	if event.is_action_pressed("interact"):
		if _interact_with_nearest() or _try_harvest():
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
	var farm := _get_farm_grid()
	if item == null or farm == null:
		return
	farm.use_item(item, farm.world_to_cell(get_target_position()))


func _get_farm_grid() -> FarmGrid:
	return get_tree().get_first_node_in_group(FarmGrid.GROUP) as FarmGrid


func _update_animation(moving: bool) -> void:
	var animation := ("walk_" if moving else "idle_") + _direction_name(facing)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)


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
