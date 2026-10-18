class_name InventoryGrid
extends GridContainer
## All slots of GameState.inventory as a clickable grid (8 x 5); the first
## row is the hotbar. Emits `slot_pressed` when a slot is clicked or chosen
## with the keyboard cursor (arrows / WASD + E).

signal slot_pressed(index: int)
signal cursor_moved(index: int)

var selected := -1:
	set(value):
		selected = value
		_refresh()
## Keyboard cursor; follows clicks too.
var cursor := 0:
	set(value):
		cursor = posmod(value, _slots.size()) if not _slots.is_empty() else 0
		_refresh()
		cursor_moved.emit(cursor)

var _slots: Array[ItemSlot] = []


func _ready() -> void:
	columns = GameState.HOTBAR_SIZE
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)
	for i in GameState.inventory.size():
		var slot := ItemSlot.new()
		slot.interactive = true
		slot.pressed.connect(_on_slot_pressed.bind(i))
		add_child(slot)
		_slots.append(slot)
	EventBus.inventory_changed.connect(_refresh)
	_refresh()


func handle_cursor_input(event: InputEvent) -> bool:
	if event.is_action_pressed("move_right"):
		cursor += 1
	elif event.is_action_pressed("move_left"):
		cursor -= 1
	elif event.is_action_pressed("move_down"):
		cursor += columns
	elif event.is_action_pressed("move_up"):
		cursor -= columns
	elif event.is_action_pressed("advance_dialogue"):
		slot_pressed.emit(cursor)
	else:
		return false
	return true


func _on_slot_pressed(index: int) -> void:
	cursor = index
	slot_pressed.emit(index)


func _refresh() -> void:
	for i in _slots.size():
		var item := GameState.inventory.get_item_at(i)
		_slots[i].show_item(item, GameState.inventory.slots[i].count)
		_slots[i].set_selected(i == selected or i == cursor)
		_slots[i].modulate = Color(1.0, 0.9, 0.55) if i == selected else Color.WHITE
