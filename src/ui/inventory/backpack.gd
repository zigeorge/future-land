class_name Backpack
extends Control
## The backpack screen (I / Tab): all inventory slots, details of the chosen
## item with its sell price, and moving items between slots (choose an item,
## then the slot to move it to). While a shop is open, items can be sold.
## Runs while the game is paused.

signal closed

## Set by the shop screen: selling is only possible inside a shop.
var shop_open := false:
	set(value):
		shop_open = value
		if is_node_ready():
			_show_details()

@onready var grid: InventoryGrid = %Grid
@onready var name_label: Label = %ItemName
@onready var description_label: Label = %ItemDescription
@onready var price_label: Label = %ItemPrice
@onready var sell_one_button: Button = %SellOne
@onready var sell_all_button: Button = %SellAll
@onready var hint_label: Label = %Hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	grid.slot_pressed.connect(_on_slot_pressed)
	grid.cursor_moved.connect(func(_index: int) -> void: _show_details())
	sell_one_button.pressed.connect(_sell.bind(false))
	sell_all_button.pressed.connect(_sell.bind(true))
	EventBus.inventory_changed.connect(_show_details)
	_show_details()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory") or event.is_action_pressed("pause"):
		close()
	elif not grid.handle_cursor_input(event):
		return
	get_viewport().set_input_as_handled()


func close() -> void:
	closed.emit()
	queue_free()


## First press chooses an item; the next press moves it there (swapping
## with whatever is in that slot). Pressing the same slot again unchooses it.
func _on_slot_pressed(index: int) -> void:
	var inventory := GameState.inventory
	if grid.selected == -1:
		if inventory.get_item_at(index):
			grid.selected = index
	elif grid.selected == index:
		grid.selected = -1
	else:
		inventory.swap_slots(grid.selected, index)
		grid.selected = -1
	_show_details()


func _details_index() -> int:
	return grid.selected if grid.selected != -1 else grid.cursor


func _show_details() -> void:
	var index := _details_index()
	var item := GameState.inventory.get_item_at(index)
	var count := GameState.inventory.slots[index].count if item else 0
	name_label.text = item.display_name + (" x%d" % count if count > 1 else "") if item else ""
	description_label.text = item.description if item else ""
	if item == null:
		price_label.text = ""
	elif item.sell_price > 0:
		price_label.text = "Sells for %s g" % GameState.format_money(item.sell_price)
	else:
		price_label.text = "Can't be sold"
	var can_sell := shop_open and item != null and item.sell_price > 0
	sell_one_button.visible = shop_open
	sell_all_button.visible = shop_open
	sell_one_button.disabled = not can_sell
	sell_all_button.disabled = not can_sell or count < 2
	if grid.selected != -1:
		hint_label.text = "Choose where to move it  -  same slot to cancel"
	else:
		hint_label.text = "Click an item (or arrows + E) to see it and move it  -  I / Esc to close"


func _sell(all: bool) -> void:
	var index := _details_index()
	var item := GameState.inventory.get_item_at(index)
	if item == null or item.sell_price <= 0:
		return
	var amount: int = GameState.inventory.slots[index].count if all else 1
	if GameState.inventory.remove_from_slot(index, amount):
		GameState.money += item.sell_price * amount
		EventBus.notification_requested.emit("Sold %s x%d for %s g" % [item.display_name, amount, GameState.format_money(item.sell_price * amount)])
	if GameState.inventory.get_item_at(index) == null:
		grid.selected = -1
	_show_details()
