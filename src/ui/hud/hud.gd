extends Control
## Always-visible game UI: date, clock, money, story deadline and buy-back
## goal (once the story has revealed them), energy, hotbar, messages.
## Restyle freely in hud.tscn; the script only needs the %UniqueName nodes.

const SLOT_SIZE := Vector2(40, 40)
## Item icons are 16x16, shown at exactly 2x.
const ICON_SIZE := Vector2(32, 32)
const MESSAGE_SECONDS := 2.0

## 26x26 hotbar slot frames (assets/art/ui/hotbar_slot.png and
## hotbar_slot_selected.png). Without them, slots use the theme's panel style
## and the selected slot is tinted.
@export var slot_texture: Texture2D
@export var selected_slot_texture: Texture2D

var _slots: Array[PanelContainer] = []
var _message_tween: Tween

@onready var date_label: Label = %DateLabel
@onready var clock_label: Label = %ClockLabel
@onready var money_label: Label = %MoneyLabel
@onready var deadline_label: Label = %DeadlineLabel
@onready var goal_label: Label = %GoalLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var hotbar: HBoxContainer = %Hotbar
@onready var message_label: Label = %MessageLabel


func _ready() -> void:
	_build_hotbar()
	message_label.modulate.a = 0.0
	EventBus.time_ticked.connect(func(_d: int, _h: int, _m: int) -> void: _update_time())
	EventBus.day_started.connect(func(_d: int, _s: int, _y: int) -> void: _update_time())
	EventBus.money_changed.connect(_update_money)
	EventBus.energy_changed.connect(_update_energy)
	EventBus.inventory_changed.connect(_update_hotbar)
	EventBus.hotbar_selection_changed.connect(func(_i: int) -> void: _update_hotbar())
	EventBus.notification_requested.connect(show_message)
	EventBus.story_flag_changed.connect(func(_f: StringName, _v: Variant) -> void: _update_story())
	EventBus.game_loaded.connect(_refresh_all)
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hotbar_next"):
		GameState.selected_hotbar_slot += 1
	elif event.is_action_pressed("hotbar_prev"):
		GameState.selected_hotbar_slot -= 1
	elif event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode
		if key >= KEY_1 and key <= KEY_9:
			GameState.selected_hotbar_slot = key - KEY_1
		elif key == KEY_0:
			GameState.selected_hotbar_slot = 9


func show_message(text: String) -> void:
	message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(message_label, "modulate:a", 1.0, 0.15)
	_message_tween.tween_interval(MESSAGE_SECONDS)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.4)


func _refresh_all() -> void:
	_update_time()
	_update_story()
	_update_money(GameState.money)
	_update_energy(GameState.energy, GameState.MAX_ENERGY)
	_update_hotbar()


func _update_time() -> void:
	date_label.text = TimeManager.get_date_text()
	clock_label.text = TimeManager.get_clock_text()
	deadline_label.text = "%d days left" % GameState.get_days_remaining()


func _update_story() -> void:
	deadline_label.visible = GameState.has_story_flag(&"main_quest_started")
	deadline_label.text = "%d days left" % GameState.get_days_remaining()
	goal_label.visible = GameState.has_story_flag(&"buyback_goal_unlocked")
	goal_label.text = "Buy back: %s g" % _with_commas(GameState.BUYBACK_PRICE)


static func _with_commas(amount: int) -> String:
	var digits := str(amount)
	var result := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return result


func _update_money(amount: int) -> void:
	money_label.text = "%d g" % amount


func _update_energy(current: int, maximum: int) -> void:
	energy_bar.max_value = maximum
	energy_bar.value = current


func _build_hotbar() -> void:
	for i in GameState.HOTBAR_SIZE:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = ICON_SIZE
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		var label := Label.new()
		label.name = "Label"
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
		slot.add_child(icon)
		slot.add_child(label)
		hotbar.add_child(slot)
		_slots.append(slot)


func _update_hotbar() -> void:
	for i in _slots.size():
		var slot := _slots[i]
		var icon: TextureRect = slot.get_node("Icon")
		var label: Label = slot.get_node("Label")
		var item := GameState.inventory.get_item_at(i)
		var count := GameState.inventory.slots[i].count
		icon.texture = item.icon if item else null
		icon.texture_filter = Art.filter_for(icon.texture, 16)
		if item == null:
			label.text = ""
		elif item.icon == null:
			# No art yet: show a short name instead of an icon.
			label.text = item.display_name.left(6) + ("\n%d" % count if count > 1 else "")
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		else:
			# Stack size in the bottom-right corner.
			label.text = str(count) if count > 1 else ""
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_style_slot(slot, i == GameState.selected_hotbar_slot)


func _style_slot(slot: PanelContainer, selected: bool) -> void:
	var texture := selected_slot_texture if selected else slot_texture
	if texture:
		var style := StyleBoxTexture.new()
		style.texture = texture
		style.set_texture_margin_all(5)
		style.set_content_margin_all(4)
		slot.add_theme_stylebox_override("panel", style)
		slot.self_modulate = Color.WHITE
	else:
		slot.remove_theme_stylebox_override("panel")
		slot.self_modulate = Color(2.0, 1.7, 0.6) if selected else Color.WHITE
