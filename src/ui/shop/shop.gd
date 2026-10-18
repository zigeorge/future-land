class_name Shop
extends Control
## A shop: buy the items listed for this shop in data/shops.json (seeds only
## in their season), or open the backpack to sell. Opened after the shop
## owner's greeting; runs while the game is paused.

signal closed

const SHOPS_PATH := "res://data/shops.json"
## Shop id -> the role of its owner (for the name above the list).
const OWNERS := {&"merchant": "Merchant", &"inventor": "Technological Inventor", &"fisherman": "Fisherman"}

var shop_id: StringName = &"merchant"
var _rows: Array[Dictionary] = []

@onready var title_label: Label = %Title
@onready var money_label: Label = %Money
@onready var list: VBoxContainer = %List
@onready var sell_button: Button = %SellButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = "%s's shop" % Registry.get_npc_name(OWNERS.get(shop_id, String(shop_id).capitalize()))
	sell_button.pressed.connect(_open_backpack)
	close_button.pressed.connect(close)
	EventBus.money_changed.connect(func(_amount: int) -> void: _refresh())
	EventBus.inventory_changed.connect(_refresh)
	_build_list()
	_refresh()
	_focus_first()


func _unhandled_input(event: InputEvent) -> void:
	if get_node_or_null("Backpack"):
		return  # The backpack on top handles its own keys.
	if event.is_action_pressed("pause") or event.is_action_pressed("toggle_inventory"):
		close()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_up"):
		_move_focus(1 if event.is_action_pressed("move_down") else -1)
	elif event.is_action_pressed("advance_dialogue"):
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused and not focused.disabled:
			focused.pressed.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func close() -> void:
	closed.emit()
	queue_free()


## Items this shop sells today: tools always, seeds only in their season.
static func items_for(shop: StringName) -> Array[ItemData]:
	var items: Array[ItemData] = []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHOPS_PATH))
	if not data is Dictionary:
		return items
	for id: String in data.get("shops", {}).get(String(shop), []):
		var item := Registry.get_item(StringName(id))
		if item == null:
			continue
		if item.category == ItemData.Category.SEED:
			var crop := Registry.get_crop(item.crop_id)
			if crop and not crop.grows_in(TimeManager.season):
				continue
		items.append(item)
	# Seeds first (what players buy most), then everything else, cheapest first.
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		var a_seed := a.category == ItemData.Category.SEED
		var b_seed := b.category == ItemData.Category.SEED
		return a_seed and not b_seed if a_seed != b_seed else a.buy_price < b.buy_price)
	return items


## Buys `amount` of an item if there is enough money and room.
static func buy(item: ItemData, amount: int) -> bool:
	var cost := item.buy_price * amount
	if GameState.money < cost:
		EventBus.notification_requested.emit("Not enough money")
		return false
	var leftover := GameState.inventory.add_item(item, amount)
	if leftover > 0:
		GameState.inventory.remove_item(item.id, amount - leftover)
		EventBus.notification_requested.emit("Backpack is full")
		return false
	GameState.money -= cost
	return true


func _build_list() -> void:
	for item in items_for(shop_id):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var slot := ItemSlot.new()
		slot.show_item(item, 1)
		row.add_child(slot)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 0)
		var name_label := Label.new()
		name_label.text = item.display_name
		var info := Label.new()
		info.text = _info_text(item)
		info.add_theme_font_size_override("font_size", 7)
		info.modulate = Color(1, 1, 1, 0.7)
		text.add_child(name_label)
		text.add_child(info)
		row.add_child(text)
		var price := Label.new()
		price.text = "%s g" % GameState.format_money(item.buy_price)
		price.custom_minimum_size = Vector2(46, 0)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(price)
		var buttons: Array[Button] = []
		for amount in ([1, 5] if item.max_stack > 1 else [1]):
			var button := Button.new()
			button.text = "Buy" if amount == 1 else "x5"
			button.custom_minimum_size = Vector2(32, 0)
			button.pressed.connect(func() -> void: buy(item, amount))
			row.add_child(button)
			buttons.append(button)
		list.add_child(row)
		_rows.append({"item": item, "buttons": buttons, "price": price})
	if _rows.is_empty():
		var empty := Label.new()
		empty.text = "Nothing for sale right now."
		list.add_child(empty)


func _info_text(item: ItemData) -> String:
	if item.category == ItemData.Category.SEED:
		var crop := Registry.get_crop(item.crop_id)
		var days := crop.get_total_days() if crop else 0
		var harvest := crop.harvest_item.sell_price if crop and crop.harvest_item else 0
		return "%d days to grow - crop sells for %d g" % [days, harvest]
	return item.description.left(60) + ("..." if item.description.length() > 60 else "")


func _refresh() -> void:
	money_label.text = "%s g" % GameState.format_money(GameState.money)
	for row in _rows:
		var item: ItemData = row["item"]
		for button: Button in row["buttons"]:
			var amount := 1 if button.text == "Buy" else 5
			button.disabled = GameState.money < item.buy_price * amount


func _open_backpack() -> void:
	var main := get_tree().current_scene
	if main.has_method("open_backpack"):
		var backpack: Backpack = main.open_backpack(true)
		backpack.reparent(self)
		backpack.closed.connect(func() -> void:
			get_tree().paused = true  # still in the shop
			_focus_first())


func _focus_first() -> void:
	for row in _rows:
		for button: Button in row["buttons"]:
			if not button.disabled:
				button.grab_focus()
				return
	close_button.grab_focus()


func _move_focus(step: int) -> void:
	var buttons: Array[Button] = []
	for row in _rows:
		buttons.append((row["buttons"] as Array)[0])
	buttons.append(sell_button)
	buttons.append(close_button)
	var current := buttons.find(get_viewport().gui_get_focus_owner())
	buttons[posmod(current + step, buttons.size())].grab_focus()
