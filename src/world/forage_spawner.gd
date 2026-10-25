class_name ForageSpawner
extends Node2D
## Scatters `count` finds on random free cells of `area` each day (the same
## spots all day, new ones the next morning). Each find shows a random
## picture from its sheet (4 x 4 pictures of 128 px).

## item id -> picture sheet
@export var finds := {
	&"driftwood": preload("res://assets/art/environment/beach/driftwood.png"),
	&"seashell": preload("res://assets/art/environment/beach/seashells.png"),
}
@export var count := 8
## Cells (16 units) where finds may appear.
@export var area := Rect2i(0, 0, 10, 10)
@export var map_id := "beach"

const CELL := 16
const SIZE := 11.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [map_id, TimeManager.get_day_number()])
	var ids: Array = finds.keys()
	var used := {}
	for i in count:
		var cell := Vector2i(rng.randi_range(area.position.x, area.end.x - 1), rng.randi_range(area.position.y, area.end.y - 1))
		var id: StringName = ids[rng.randi() % ids.size()]
		var picture := Vector2i(rng.randi() % 4, rng.randi() % 4)
		var key := "%s:%d" % [map_id, i]
		if used.has(cell) or key in GameState.forage_taken:
			continue
		used[cell] = true
		_spawn(id, picture, cell, key)


func _spawn(id: StringName, picture: Vector2i, cell: Vector2i, key: String) -> void:
	var holder := Node2D.new()
	holder.position = (Vector2(cell) + Vector2(0.5, 0.8)) * CELL
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = finds[id]
	atlas.region = Rect2(picture * 128, Vector2(128, 128))
	sprite.texture = atlas
	sprite.scale = Vector2.ONE * SIZE / 128.0
	sprite.offset = Vector2(0, -48)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	holder.add_child(sprite)
	var pickup := Forageable.new()
	pickup.item_id = id
	pickup.key = key
	pickup.prompt = "Pick up"
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	pickup.add_child(shape)
	holder.add_child(pickup)
	add_child(holder)
