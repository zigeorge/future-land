class_name ToolAction
extends Node2D
## One use of a tool, drawn around the player (the character sheets have no
## tool frames): the tool's icon is swung, poured or run, and bits fly up
## from the tile when it lands.
##
##   var action := ToolAction.new()
##   player.add_child(action)
##   action.play(item, facing, target)   # target: tile centre, player-local
##   await action.hit                     # the moment the tool lands
##   action.burst(color)                  # optional: bits from the tile
##   await action.finished
##
## Emits `hit` once and `finished` when the animation is over; it then frees itself.

signal hit
signal finished

enum Motion { SWING, POUR, RUN, TOSS }

## Size of the tool in the world (the player is 16 x 32).
const TOOL_SIZE := 14.0
## Where the handle is on the hand-tool icons (fraction of the image); the
## head is at the opposite corner, so the icon points up and right.
const ICON_HANDLE := Vector2(0.15, 0.85)
## Per facing: hand position, then the raised and the striking rotation (degrees).
## Facing up, the tool is behind the player and shows above the head.
const SWING := {
	Vector2.RIGHT: [Vector2(3, -13), -35.0, 80.0],
	Vector2.DOWN: [Vector2(4, -10), -30.0, 120.0],
	Vector2.UP: [Vector2(2, -22), 30.0, -45.0],
}
## Machines are bigger than hand tools.
const MACHINE_SIZE := 18.0
const BIT_SIZE := 1.6
const WIND_SECONDS := 0.12
const STRIKE_SECONDS := 0.1
const HOLD_SECONDS := 0.14
const POUR_SECONDS := 0.45
const RUN_SECONDS := 0.4
const GRAVITY := 260.0

var _facing := Vector2.DOWN
var _target := Vector2.ZERO
var _sprite: Sprite2D
var _motion := Motion.SWING
## Flying bits: [position, velocity, colour, life left].
var _bits: Array = []
var _drops := 0.0  # watering: seconds of drops still to spawn


static func motion_for(item: ItemData) -> Motion:
	match item.tool_type:
		ItemData.ToolType.WATERING_CAN:
			return Motion.POUR
		ItemData.ToolType.CULTIVATOR:
			return Motion.RUN
	if item.category == ItemData.Category.SEED:
		return Motion.TOSS
	# The chainsaw and the lawn mower are machines too, though they clear like an axe and a sickle.
	return Motion.RUN if item.id in [&"chainsaw", &"lawn_mower"] else Motion.SWING


## What flies up from a tile: what was cleared, else soil or water.
static func bit_color(item: ItemData, debris_kind: String) -> Color:
	match debris_kind:
		"weed":
			return Color(0.4, 0.65, 0.22)
		"stone":
			return Color(0.62, 0.62, 0.64)
		"branch":
			return Color(0.55, 0.38, 0.2)
	if item.tool_type == ItemData.ToolType.WATERING_CAN:
		return Color(0.65, 0.88, 1.0)
	return Color(0.8, 0.64, 0.44)  # dust, light enough to show on dark soil


func play(item: ItemData, facing: Vector2, target: Vector2) -> void:
	_facing = facing
	_target = target
	_motion = motion_for(item)
	if facing == Vector2.UP:
		# Behind the player but above the ground: draw before the player's sprite.
		get_parent().move_child(self, 0)
	else:
		z_index = 1
	_sprite = Sprite2D.new()
	_sprite.texture = item.icon
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var size := item.icon.get_size() if item.icon else Vector2(128, 128)
	_sprite.scale = Vector2.ONE * TOOL_SIZE / maxf(size.x, size.y)
	add_child(_sprite)
	match _motion:
		Motion.SWING:
			_swing(size)
		Motion.POUR:
			_pour()
		Motion.RUN:
			_run()
		Motion.TOSS:
			_toss()


## Bits flying up from the tile: soil, splashes, grass, chips.
func burst(color: Color, count := 7) -> void:
	for i in count:
		var velocity := Vector2(randf_range(-30, 30), randf_range(-70, -35))
		_bits.append([_target + Vector2(randf_range(-4, 4), randf_range(-2, 3)), velocity, color, randf_range(0.3, 0.45)])


func _swing(size: Vector2) -> void:
	var left := _facing == Vector2.LEFT
	var pose: Array = SWING[Vector2.RIGHT if left else _facing]
	_sprite.centered = false
	_sprite.offset = -ICON_HANDLE * size
	_sprite.position = Vector2(-pose[0].x, pose[0].y) if left else pose[0]
	_sprite.flip_h = left
	if left:
		_sprite.offset.x = -(1.0 - ICON_HANDLE.x) * size.x
	var side := -1.0 if left else 1.0
	_sprite.rotation_degrees = side * pose[1] * 0.5
	var tween := create_tween()
	tween.tween_property(_sprite, "rotation_degrees", side * pose[1], WIND_SECONDS).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "rotation_degrees", side * pose[2], STRIKE_SECONDS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(hit.emit)
	tween.tween_interval(HOLD_SECONDS)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.08)
	tween.finished.connect(_end)


func _pour() -> void:
	# The can's spout points left in the icon.
	var right := _facing == Vector2.RIGHT or _facing == Vector2.DOWN
	_sprite.flip_h = right
	_sprite.position = Vector2(_facing.x * 8.0, -9.0 + maxf(_facing.y, 0.0) * 4.0)
	var tilt := 35.0 if right else -35.0
	var tween := create_tween()
	tween.tween_property(_sprite, "rotation_degrees", tilt, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _drops = POUR_SECONDS - 0.2)
	tween.tween_interval(0.12)
	tween.tween_callback(hit.emit)
	tween.tween_interval(POUR_SECONDS - 0.12)
	tween.tween_property(_sprite, "rotation_degrees", 0.0, 0.1)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.08)
	tween.finished.connect(_end)


func _run() -> void:
	# Machines are held out in front and shake while they work.
	_sprite.flip_h = _facing == Vector2.LEFT
	_sprite.scale *= MACHINE_SIZE / TOOL_SIZE
	var base := Vector2(_facing.x * 10.0, -6.0 + _facing.y * 10.0)
	_sprite.position = base
	var tween := create_tween()
	var steps := int(RUN_SECONDS / 0.04)
	for i in steps:
		tween.tween_property(_sprite, "position", base + Vector2(randf_range(-0.7, 0.7), randf_range(-0.7, 0.7)), 0.04)
		if i == steps / 3:
			tween.tween_callback(hit.emit)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.08)
	tween.finished.connect(_end)


func _toss() -> void:
	# The packet shows over the hand and a few seeds arc onto the tile.
	_sprite.scale *= 0.8
	_sprite.position = Vector2(_facing.x * 5.0, -16.0)
	for i in 4:
		var start := _sprite.position + Vector2(randf_range(-2, 2), 2)
		var flight := 0.3
		var velocity := (_target + Vector2(randf_range(-3, 3), randf_range(-2, 2)) - start) / flight - Vector2(0, GRAVITY * flight / 2.0)
		_bits.append([start, velocity, Color(0.95, 0.85, 0.55), flight])
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(hit.emit)
	tween.tween_interval(0.15)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.1)
	tween.finished.connect(_end)


func _end() -> void:
	_sprite.visible = false
	# Let the last bits land before going away.
	while not _bits.is_empty():
		await get_tree().process_frame
	finished.emit()
	queue_free()


func _process(delta: float) -> void:
	if _drops > 0.0:
		_drops -= delta
		var spout := _sprite.position + Vector2(5.0 if _sprite.flip_h else -5.0, -2.0)
		var velocity := (_target - spout) / 0.25 - Vector2(0, GRAVITY * 0.25 / 2.0)
		_bits.append([spout, velocity + Vector2(randf_range(-6, 6), 0), Color(0.55, 0.8, 1.0, 0.9), 0.25])
	for bit: Array in _bits:
		bit[1].y += GRAVITY * delta
		bit[0] += bit[1] * delta
		bit[3] -= delta
	_bits = _bits.filter(func(bit: Array) -> bool: return bit[3] > 0.0)
	queue_redraw()


func _draw() -> void:
	for bit: Array in _bits:
		var color: Color = bit[2]
		color.a *= clampf(bit[3] / 0.15, 0.0, 1.0)
		draw_rect(Rect2(bit[0] - Vector2.ONE * BIT_SIZE / 2.0, Vector2.ONE * BIT_SIZE), color)
