class_name DialogueSpot
extends Interactable
## Plays a conversation when the player interacts with it (signs, notice
## boards, ...). Add as a child Area2D with a CollisionShape2D.

## File name (without .json) in data/dialogue/.
@export var dialogue_id: StringName


func interact(player: Node) -> void:
	super(player)
	if dialogue_id != &"":
		DialogueManager.start(dialogue_id)
