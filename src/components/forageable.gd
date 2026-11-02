class_name Forageable
extends Interactable
## Something to pick up with E (driftwood, shells). Spawned each day by a
## ForageSpawner; once taken it stays gone until the next morning.

var item_id: StringName
## "map:index", remembered in GameState.forage_taken for today.
var key := ""


func interact(player: Node) -> void:
	super(player)
	var item := Registry.get_item(item_id)
	if item == null:
		return
	if GameState.inventory.add_item(item, 1) > 0:
		EventBus.notification_requested.emit("Backpack is full")
		return
	GameState.forage_taken.append(key)
	AudioManager.play_ui(&"pickup")
	EventBus.notification_requested.emit("Found: %s" % item.display_name)
	get_parent().queue_free()
