class_name EnergyBar
extends Control
## Horizontal energy bar: the fill is drawn into the empty slot of the frame,
## cut to the current level, with the frame on top. Any texture resolution.

const LOW_LEVEL := 0.25
const LOW_TINT := Color(1.0, 0.45, 0.4)

@export var frame: Texture2D
@export var fill: Texture2D
## The empty slot inside the frame, in frame pixels.
@export var slot := Rect2(61, 46, 519, 38)

## 0.0 (exhausted) to 1.0 (full).
var ratio := 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	texture_filter = Art.filter_for(frame, size.x)


func _draw() -> void:
	if frame == null or fill == null:
		return
	var scale := size / frame.get_size()
	var slot_rect := Rect2(slot.position * scale, slot.size * scale)
	var shown := Rect2(slot_rect.position, Vector2(slot_rect.size.x * ratio, slot_rect.size.y))
	var source := Rect2(Vector2.ZERO, Vector2(fill.get_width() * ratio, fill.get_height()))
	if ratio > 0.0:
		draw_texture_rect_region(fill, shown, source, LOW_TINT if ratio < LOW_LEVEL else Color.WHITE)
	draw_texture_rect(frame, Rect2(Vector2.ZERO, size), false)
