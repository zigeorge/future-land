class_name LevelWarp
extends Area2D
## Moves the player to another level when they walk into this area
## (doors, map edges). Needs a CollisionShape2D child.

const PLAYER_LAYER := 1 << 1  # physics layer 2 "player"

@export_file("*.tscn") var target_level := ""
## Name of a Marker2D under the target level's SpawnPoints node.
@export var target_spawn: StringName = &"Default"


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and target_level != "":
		EventBus.level_change_requested.emit(target_level, target_spawn)
