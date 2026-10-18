class_name Inventory
extends Resource
## Fixed-size list of item stacks. Emits `changed` whenever contents change.
## Slots 0..GameState.HOTBAR_SIZE-1 are the hotbar.

var slots: Array[InventorySlot] = []


func _init(slot_count := 30) -> void:
	for i in slot_count:
		slots.append(InventorySlot.new())


func size() -> int:
	return slots.size()


func clear() -> void:
	for slot in slots:
		slot.item = null
		slot.count = 0
	emit_changed()


func get_item_at(index: int) -> ItemData:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return null
	return slots[index].item


## Adds items, stacking where possible. Returns how many did NOT fit.
func add_item(item: ItemData, amount := 1) -> int:
	if item == null or amount <= 0:
		return amount
	var remaining := amount
	# Fill existing stacks first, then empty slots.
	for slot in slots:
		if remaining == 0:
			break
		if not slot.is_empty() and slot.item.id == item.id:
			var added := mini(remaining, item.max_stack - slot.count)
			slot.count += added
			remaining -= added
	for slot in slots:
		if remaining == 0:
			break
		if slot.is_empty():
			var added := mini(remaining, item.max_stack)
			slot.item = item
			slot.count = added
			remaining -= added
	if remaining != amount:
		emit_changed()
	return remaining


## Removes `amount` of the item. Returns false (and removes nothing) if there aren't enough.
func remove_item(item_id: StringName, amount := 1) -> bool:
	if count_item(item_id) < amount:
		return false
	var remaining := amount
	for slot in slots:
		if remaining == 0:
			break
		if not slot.is_empty() and slot.item.id == item_id:
			var taken := mini(remaining, slot.count)
			slot.count -= taken
			remaining -= taken
			if slot.count == 0:
				slot.item = null
	emit_changed()
	return true


## Removes up to `amount` from one slot. Returns false if the slot is empty.
func remove_from_slot(index: int, amount := 1) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false
	var slot := slots[index]
	slot.count -= mini(amount, slot.count)
	if slot.count == 0:
		slot.item = null
	emit_changed()
	return true


func count_item(item_id: StringName) -> int:
	var total := 0
	for slot in slots:
		if not slot.is_empty() and slot.item.id == item_id:
			total += slot.count
	return total


func swap_slots(a: int, b: int) -> void:
	var temp := slots[a]
	slots[a] = slots[b]
	slots[b] = temp
	emit_changed()


func to_data() -> Array:
	var data := []
	for slot in slots:
		data.append(null if slot.is_empty() else {"id": String(slot.item.id), "count": slot.count})
	return data


func from_data(data: Array) -> void:
	for i in slots.size():
		var entry: Variant = data[i] if i < data.size() else null
		var slot := slots[i]
		slot.item = null
		slot.count = 0
		if entry is Dictionary:
			slot.item = Registry.get_item(StringName(entry["id"]))
			slot.count = int(entry["count"]) if slot.item else 0
	emit_changed()
