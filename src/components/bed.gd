class_name Bed
extends Interactable
## The farmhouse door: asks whether to end the day (data/dialogue/sleep_prompt.json);
## Main ends the day when the player says yes.


func interact(player: Node) -> void:
	super(player)
	DialogueManager.start(&"sleep_prompt")
