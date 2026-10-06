class_name InventorySlot
extends RefCounted
## One stack of items in an Inventory.

var item: ItemData
var count := 0


func is_empty() -> bool:
	return item == null or count <= 0
