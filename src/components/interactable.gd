class_name Interactable
extends Area2D
## Anything the player can press "interact" on (NPCs, beds, signs, chests...).
##
## Add as a child Area2D with a CollisionShape2D, then either connect to
## `interacted` or extend this script and override interact().

signal interacted(player: Node)

const INTERACTABLE_LAYER := 1 << 3  # physics layer 4 "interactable"

## Shown to the player, e.g. "Talk", "Sleep", "Open".
@export var prompt := "Interact"


func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false


func interact(player: Node) -> void:
	interacted.emit(player)
