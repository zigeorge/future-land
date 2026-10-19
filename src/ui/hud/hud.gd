extends Control
## Always-visible game UI: date, clock, money, story deadline and buy-back
## goal (once the story has revealed them), energy, hotbar, messages.
## Restyle freely in hud.tscn; the script only needs the %UniqueName nodes.

const MESSAGE_SECONDS := 2.0

var _slots: Array[ItemSlot] = []
var _message_tween: Tween

@onready var date_label: Label = %DateLabel
@onready var clock_label: Label = %ClockLabel
@onready var money_label: Label = %MoneyLabel
@onready var deadline_label: Label = %DeadlineLabel
@onready var goal_label: Label = %GoalLabel
@onready var objective_panel: PanelContainer = %GoalPanel
@onready var objective_label: Label = %GoalLabel2
@onready var energy_bar: EnergyBar = %EnergyBar
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
	EventBus.avatar_changed.connect(func(_id: StringName) -> void: _update_story())
	EventBus.game_loaded.connect(_refresh_all)
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hotbar_next"):
		GameState.selected_hotbar_slot += 1
	elif event.is_action_pressed("hotbar_prev"):
		GameState.selected_hotbar_slot -= 1
	elif event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode
		if key >= KEY_1 and key < KEY_1 + GameState.HOTBAR_SIZE:
			GameState.selected_hotbar_slot = key - KEY_1


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
	goal_label.text = "Buy back: %s g" % GameState.format_money(GameState.BUYBACK_PRICE)
	var objective := Objectives.current_text()
	objective_panel.visible = objective != ""
	objective_label.text = "Goal: " + objective


func _update_money(amount: int) -> void:
	money_label.text = "%s g" % GameState.format_money(amount)


func _update_energy(current: int, maximum: int) -> void:
	energy_bar.ratio = float(current) / maximum


func _build_hotbar() -> void:
	for i in GameState.HOTBAR_SIZE:
		var slot := ItemSlot.new()
		hotbar.add_child(slot)
		_slots.append(slot)


func _update_hotbar() -> void:
	for i in _slots.size():
		_slots[i].show_item(GameState.inventory.get_item_at(i), GameState.inventory.slots[i].count)
		_slots[i].set_selected(i == GameState.selected_hotbar_slot)
