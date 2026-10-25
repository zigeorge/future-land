class_name ShippingBin
extends Interactable
## Put items in during the day; they're sold overnight at full price
## (GameState.shipping). Opens the backpack in shipping mode.


func interact(player: Node) -> void:
	super(player)
	var main := get_tree().current_scene
	if main.has_method("open_backpack"):
		main.open_backpack(false, true)
