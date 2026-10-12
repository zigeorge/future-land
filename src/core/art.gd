class_name Art
## Shows art at any resolution.
##
## Gameplay uses fixed world sizes: a tile is 16 units, a character 16x32.
## Art may be drawn bigger than that, e.g. HD art at 8x (a tile is 128 px,
## a character frame 128x256 px). It is scaled down to its world size and
## smoothed, so it stays sharp; 1x pixel art keeps sharp square pixels.

const TILE := 16


## Linear filtering (with mipmaps) for art drawn bigger than it is shown,
## nearest-neighbour for 1x pixel art.
static func filter_for(texture: Texture2D, world_width: float) -> CanvasItem.TextureFilter:
	if texture and texture.get_width() > world_width + 0.5:
		return CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return CanvasItem.TEXTURE_FILTER_NEAREST


## Scales a sprite so one frame of `frame_pixels` covers `world_size`, with
## the bottom of the frame on the node's position (feet, tree base, ...).
static func fit_sprite(sprite: Node2D, frame_pixels: Vector2, world_size: Vector2) -> void:
	sprite.scale = world_size / frame_pixels
	sprite.set("offset", Vector2(0, -frame_pixels.y / 2))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if frame_pixels.x > world_size.x + 0.5 \
		else CanvasItem.TEXTURE_FILTER_NEAREST
