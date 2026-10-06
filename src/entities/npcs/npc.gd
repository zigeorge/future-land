class_name NPC
extends StaticBody2D
## A villager the player can talk to. Set npc_name and dialogue_id per
## instance in the level; the dialogue itself lives in data/dialogue/.

@export var npc_name := "Villager"
## File name (without .json) in data/dialogue/.
@export var dialogue_id: StringName = &"welcome"

@onready var name_label: Label = $NameLabel
@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	name_label.text = npc_name
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_player: Node) -> void:
	DialogueManager.start(dialogue_id)
