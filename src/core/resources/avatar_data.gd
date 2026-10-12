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
## The current sheets' walk frames don't alternate feet, so the walk is
## rebuilt from them: front/back views alternate the step frame with its
## mirror image (the other foot), side views alternate the widest stride with
## the idle pose. Turn off for sheets with a real 4-frame walk cycle.
@export var auto_walk_cycle := true


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


## idle_<direction> (column 0) and walk_<direction> (columns 1-4, or the
## rebuilt cycle when auto_walk_cycle is on) animations.
func build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var image := _sheet_image() if auto_walk_cycle else null
	for direction in DIRECTIONS:
		_add_animation(frames, "idle_" + direction, [get_frame(direction, 0)], 1.0)
		var walk: Array[Texture2D] = []
		if image:
			walk = _rebuilt_walk(image, direction)
		else:
			for column in range(1, 5):
				walk.append(get_frame(direction, column))
		_add_animation(frames, "walk_" + direction, walk, walk_fps)
	return frames


func _add_animation(frames: SpriteFrames, animation: StringName, textures: Array[Texture2D], fps: float) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, true)
	for texture in textures:
		frames.add_frame(animation, texture)


func _sheet_image() -> Image:
	var image := sheet.get_image() if sheet else null
	if image and image.is_compressed():
		image.decompress()
	return image


func _rebuilt_walk(image: Image, direction: String) -> Array[Texture2D]:
	var row := get_row(direction)
	var idle := get_frame(direction, 0)
	if direction == "down" or direction == "up":
		# Pick the frame whose feet differ most between left and right half...
		var step := 1
		var best := -1
		for column in range(1, 5):
			var score := _foot_asymmetry(image, column, row)
			if score > best:
				best = score
				step = column
		# ...and mirror it to get the same step with the other foot.
		var region := image.get_region(Rect2i(Vector2i(step, row) * FRAME_SIZE, FRAME_SIZE))
		region.flip_x()
		return [get_frame(direction, step), idle, ImageTexture.create_from_image(region), idle]
	var widest := 1
	var widest_span := -1
	for column in range(1, 5):
		var span := _stride_width(image, column, row)
		if span > widest_span:
			widest_span = span
			widest = column
	return [get_frame(direction, widest), idle]


## How different the left and right foot are in the bottom of a frame.
static func _foot_asymmetry(image: Image, column: int, row: int) -> int:
	var origin := Vector2i(column, row) * FRAME_SIZE
	var lowest := [0, 0]
	var mass := [0, 0]
	for y in range(FRAME_SIZE.y - 8, FRAME_SIZE.y):
		for x in FRAME_SIZE.x:
			if image.get_pixelv(origin + Vector2i(x, y)).a > 0.5:
				var half := 0 if x < FRAME_SIZE.x / 2 else 1
				mass[half] += 1
				lowest[half] = maxi(lowest[half], y)
	return absi(lowest[0] - lowest[1]) * 10 + absi(mass[0] - mass[1])


## Horizontal extent of the feet (bottom 6 rows) in a frame.
static func _stride_width(image: Image, column: int, row: int) -> int:
	var origin := Vector2i(column, row) * FRAME_SIZE
	var left := FRAME_SIZE.x
	var right := -1
	for y in range(FRAME_SIZE.y - 6, FRAME_SIZE.y):
		for x in FRAME_SIZE.x:
			if image.get_pixelv(origin + Vector2i(x, y)).a > 0.5:
				left = mini(left, x)
				right = maxi(right, x)
	return right - left
