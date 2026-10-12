class_name Prop
extends StaticBody2D
## A placed object: tree, building, fence... The sprite's bottom edge sits on
## the node's position and the collision only covers the base, so the player
## can walk behind the top. Put props under a level's Entities node (y-sorted).

## Size in the world (16 units per tile). The texture may be drawn at any
## multiple of this (HD art: 8x) and is scaled to fit. Zero = the texture's
## own size (1x pixel art).
@export var world_size := Vector2.ZERO
## Optional: one texture per season (Spring, Summer, Autumn, Winter).
@export var seasonal_textures: Array[Texture2D] = []

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if seasonal_textures.size() == TimeManager.SEASON_NAMES.size():
		_apply_season(TimeManager.season)
		EventBus.day_started.connect(func(_d: int, season: int, _y: int) -> void: _apply_season(season))
	_fit()


func _apply_season(season: int) -> void:
	sprite.texture = seasonal_textures[season]
	_fit()


func _fit() -> void:
	if sprite.texture:
		var pixels := sprite.texture.get_size()
		Art.fit_sprite(sprite, pixels, world_size if world_size != Vector2.ZERO else pixels)
