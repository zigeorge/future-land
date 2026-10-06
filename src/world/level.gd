class_name Level
extends Node2D
## Base script for every map (farm, town, ...).
##
## Expected children:
##   Entities/Player     - the player instance (Entities should be y-sorted)
##   SpawnPoints/<Name>  - Marker2D nodes where the player can arrive

@export var music: AudioStream
@export var default_spawn: StringName = &"Default"
## Playable area in pixels; used for camera limits.
@export var bounds := Rect2i(0, 0, 640, 360)


func _ready() -> void:
	if music:
		AudioManager.play_music(music)


func place_player(spawn_point: StringName = &"") -> void:
	var player := get_node_or_null("Entities/Player") as Player
	if player == null:
		push_error("Level %s has no Entities/Player node" % name)
		return
	player.set_camera_limits(bounds)
	var marker_name := spawn_point if spawn_point != &"" else default_spawn
	var marker := get_node_or_null(NodePath("SpawnPoints/" + marker_name)) as Marker2D
	if marker:
		player.teleport(marker.global_position)
	else:
		push_warning("Level %s has no spawn point '%s'" % [name, marker_name])
