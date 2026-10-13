class_name CropData
extends Resource
## Definition of a crop type. One .tres file per crop in data/crops/.

## Must match the file name (data/crops/<id>.tres).
@export var id: StringName
@export var display_name := ""
## Days spent in each growth stage. [1, 2, 2] = 3 stages, ready after 5 days.
@export var days_per_stage: Array[int] = [1, 1, 1]
## One texture per stage, plus a final one for "ready to harvest".
@export var stage_textures: Array[Texture2D] = []
## Alternative to stage_textures: one strip with every stage as a square,
## side by side (e.g. 64x16 pixel art or 512x128 HD). Any resolution works.
@export var stage_strip: Texture2D

var _strip_frames: Dictionary = {}
@export var harvest_item: ItemData
@export_range(1, 99) var harvest_amount := 1
@export_flags("Spring", "Summer", "Autumn", "Winter") var seasons := 1


func get_total_days() -> int:
	var total := 0
	for days in days_per_stage:
		total += days
	return total


func is_ready(days_grown: int) -> bool:
	return days_grown >= get_total_days()


## Stage index for visuals: 0 .. days_per_stage.size() (last = ready).
func get_stage(days_grown: int) -> int:
	var elapsed := 0
	for i in days_per_stage.size():
		elapsed += days_per_stage[i]
		if days_grown < elapsed:
			return i
	return days_per_stage.size()


func grows_in(season: int) -> bool:
	return seasons & (1 << season) != 0


## Number of stage images available (growing stages + ripe).
func get_stage_count() -> int:
	if not stage_textures.is_empty():
		return stage_textures.size()
	if stage_strip:
		return int(stage_strip.get_width() / stage_strip.get_height())
	return 0


## Image for a stage, or null if there's no art for it.
func get_stage_texture(stage: int) -> Texture2D:
	if stage < 0 or stage >= get_stage_count():
		return null
	if not stage_textures.is_empty():
		return stage_textures[stage]
	if not _strip_frames.has(stage):
		var side := stage_strip.get_height()
		var atlas := AtlasTexture.new()
		atlas.atlas = stage_strip
		atlas.region = Rect2(stage * side, 0, side, side)
		_strip_frames[stage] = atlas
	return _strip_frames[stage]
