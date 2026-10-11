class_name AvatarData
extends Resource
## A player look the player can pick before starting. One .tres per avatar in
## data/avatars/; the order on the selection screen is Registry.AVATAR_IDS.
##
## The sheet is 80x128: 5 columns (idle, walk 1-4) x 4 rows of 16x32 frames,
## feet on each frame's bottom row. If a sheet only has one side-facing row,
## point both left and right at it and mirror one of them.

const FRAME_SIZE := Vector2i(16, 32)
const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]

## Must match the file name (data/avatars/<id>.tres).
@export var id: StringName
@export var display_name := ""
@export var sheet: Texture2D
@export_range(0, 3) var row_down := 0
@export_range(0, 3) var row_up := 1
@export_range(0, 3) var row_left := 2
@export_range(0, 3) var row_right := 3
@export var mirror_left := false
@export var mirror_right := false
@export var walk_fps := 8.0


func get_row(direction: String) -> int:
	match direction:
		"up":
			return row_up
		"left":
			return row_left
		"right":
			return row_right
	return row_down


func is_mirrored(direction: String) -> bool:
	return (direction == "left" and mirror_left) or (direction == "right" and mirror_right)


## One frame of the sheet, e.g. for previews.
func get_frame(direction: String, column: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(column * FRAME_SIZE.x, get_row(direction) * FRAME_SIZE.y), FRAME_SIZE)
	return atlas


## idle_<direction> (column 0) and walk_<direction> (columns 1-4) animations.
func build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for direction in DIRECTIONS:
		_add_animation(frames, "idle_" + direction, direction, [0], 1.0)
		_add_animation(frames, "walk_" + direction, direction, [1, 2, 3, 4], walk_fps)
	return frames


func _add_animation(frames: SpriteFrames, animation: StringName, direction: String, columns: Array, fps: float) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, true)
	for column: int in columns:
		frames.add_frame(animation, get_frame(direction, column))
