class_name NPC
extends StaticBody2D
## A villager the player can talk to. Set npc_name, dialogue_id and
## sprite_frames per instance in the level; the dialogue itself lives in
## data/dialogue/.

@export var npc_name := "Villager"
## File name (without .json) in data/dialogue/.
@export var dialogue_id: StringName = &"welcome"
## 16x32 frames, feet at the bottom. Plays "idle_down" if present, else the
## first animation. Leave empty to show the coloured placeholder.
@export var sprite_frames: SpriteFrames

@onready var name_label: Label = $NameLabel
@onready var interactable: Interactable = $Interactable
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var placeholder: CanvasItem = $Placeholder


func _ready() -> void:
	name_label.text = npc_name
	placeholder.visible = sprite_frames == null
	if sprite_frames:
		sprite.sprite_frames = sprite_frames
		var names := sprite_frames.get_animation_names()
		if not names.is_empty():
			sprite.play(&"idle_down" if sprite_frames.has_animation(&"idle_down") else StringName(names[0]))
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_player: Node) -> void:
	DialogueManager.start(dialogue_id)
