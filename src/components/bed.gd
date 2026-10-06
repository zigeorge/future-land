class_name Bed
extends Interactable
## Sleeping ends the day and autosaves.


func interact(player: Node) -> void:
	super(player)
	TimeManager.start_next_day()
	SaveManager.save_game()
	EventBus.notification_requested.emit("Good morning! %s" % TimeManager.get_date_text())
