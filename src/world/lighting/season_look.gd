class_name SeasonLook
## Gives each season its own look until there is seasonal art: grass,
## bushes and tree leaves turn yellow-green in summer, orange in autumn and
## snowy white in winter. Only green pixels change, so paths, water,
## buildings, characters and crops look the same all year.
##
## Levels call apply_to() on load; Daylight calls set_season() when the
## season changes. Props with their own seasonal_textures are left alone.

const SHADER := preload("res://src/world/lighting/season_look.gdshader")
## Nodes in a level that get the season look (the green fill under the tiles, grass, paths, bushes).
const LAYERS: Array[String] = ["Ground", "GrassTiles", "GroundTiles", "Decor"]
## Per season: the colour green turns into (times brightness) and how much.
const TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0),     # spring: as drawn
	Color(1.35, 1.55, 0.55),  # summer: sunnier, a little yellow
	Color(1.95, 1.15, 0.45),  # autumn: orange
	Color(2.0, 2.1, 2.3),     # winter: snow
]
const AMOUNTS: Array[float] = [0.0, 0.35, 0.75, 0.85]
## Evergreens (pines) stay green in autumn and only get snow in winter.
const EVERGREEN_AMOUNTS: Array[float] = [0.0, 0.15, 0.0, 0.7]
const EVERGREEN_PREFIX := "tree_pine"

static var _material: ShaderMaterial
static var _evergreen: ShaderMaterial


## The material every seasonal layer and leafy tree shares.
static func get_material() -> ShaderMaterial:
	if _material == null:
		_create()
	return _material


static func get_evergreen_material() -> ShaderMaterial:
	if _evergreen == null:
		_create()
	return _evergreen


static func set_season(season: int) -> void:
	var tint := TINTS[season]
	for pair in [[get_material(), AMOUNTS], [get_evergreen_material(), EVERGREEN_AMOUNTS]]:
		var material: ShaderMaterial = pair[0]
		material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
		material.set_shader_parameter("amount", pair[1][season])


static func apply_to(level: Node) -> void:
	for layer_name in LAYERS:
		var layer := level.get_node_or_null(layer_name) as CanvasItem
		if layer:
			layer.material = get_material()
	for node in level.find_children("*", "Prop", true, false):
		var prop := node as Prop
		var file := prop.scene_file_path.get_file()
		if prop.seasonal_textures.is_empty() and file.begins_with("tree_"):
			prop.sprite.material = get_evergreen_material() if file.begins_with(EVERGREEN_PREFIX) else get_material()


static func _create() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_evergreen = ShaderMaterial.new()
	_evergreen.shader = SHADER
	set_season(TimeManager.season)
