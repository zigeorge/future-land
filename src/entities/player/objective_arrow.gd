extends Node2D
## A small arrow circling the player, pointing toward the current goal
## (see Objectives). Hidden when there is no target or it's close by.

const RADIUS := 16.0
const HIDE_WITHIN := 28.0
const COLOR := Color(1.0, 0.85, 0.3)

var _direction := Vector2.ZERO


func _process(_delta: float) -> void:
	var level := get_tree().current_scene.get("_level") as Node
	var target: Variant = Objectives.target_position(level)
	var player := get_parent() as Node2D
	var offset: Vector2 = (target - player.global_position) if target != null else Vector2.ZERO
	var direction := offset.normalized() if offset.length() > HIDE_WITHIN else Vector2.ZERO
	visible = direction != Vector2.ZERO and not DialogueManager.is_active()
	if direction != _direction:
		_direction = direction
		queue_redraw()
	modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() / 250.0)


func _draw() -> void:
	if _direction == Vector2.ZERO:
		return
	var tip := _direction * (RADIUS + 5)
	var base := _direction * RADIUS
	var side := _direction.orthogonal() * 3.5
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), COLOR)
	draw_polyline(PackedVector2Array([tip, base + side, base - side, tip]), Color(0.2, 0.12, 0.05), 0.6)
