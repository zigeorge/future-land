@tool
class_name HDFrameStyle
extends StyleBox
## A 9-slice frame for HD art: the corners and edges of `texture` are drawn
## scaled down (pixels_per_unit texture pixels per UI unit), so a 512 px frame
## gets normal-sized borders. Used for every panel (assets/themes/main_theme.tres).

@export var texture: Texture2D
## Size of the corners / edges in the texture, in texture pixels.
@export var margin_pixels := 160.0
## Texture pixels per UI unit: 16 makes 160 px corners 10 units wide.
@export var pixels_per_unit := 16.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture == null:
		return
	var size := texture.get_size()
	var m := margin_pixels
	var b := minf(m / pixels_per_unit, minf(rect.size.x, rect.size.y) / 2.0)
	# Source and destination columns / rows: corner, stretched middle, corner.
	var sx := [0.0, m, size.x - m, size.x]
	var sy := [0.0, m, size.y - m, size.y]
	var dx := [rect.position.x, rect.position.x + b, rect.end.x - b, rect.end.x]
	var dy := [rect.position.y, rect.position.y + b, rect.end.y - b, rect.end.y]
	var rid := texture.get_rid()
	for row in 3:
		for col in 3:
			var dst := Rect2(dx[col], dy[row], dx[col + 1] - dx[col], dy[row + 1] - dy[row])
			var src := Rect2(sx[col], sy[row], sx[col + 1] - sx[col], sy[row + 1] - sy[row])
			if dst.size.x > 0.0 and dst.size.y > 0.0:
				RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, dst, rid, src)
