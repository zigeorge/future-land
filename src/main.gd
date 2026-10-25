extends Node
## Root scene. Owns the persistent UI, swaps levels inside $World, and runs
## the game flow: title screen -> new game (look + name) or continue, and
## the pause menu (Esc) with save / load.

const FADE_SECONDS := 0.3
const AVATAR_SELECT_SCENE := preload("res://src/ui/avatar_select/avatar_select.tscn")
const MENU_SCENE := preload("res://src/ui/menus/game_menu.tscn")
const BACKPACK_SCENE := preload("res://src/ui/inventory/backpack.tscn")
const SHOP_SCENE := preload("res://src/ui/shop/shop.tscn")

@export_file("*.tscn") var start_level := "res://src/world/farm/farm.tscn"

var _level: Level
var _level_path := ""
var _transitioning := false
var _menu: GameMenu

@onready var world: Node2D = $World
@onready var fade: ColorRect = $Transition/Fade


func _ready() -> void:
	EventBus.level_change_requested.connect(change_level)
	EventBus.shop_requested.connect(open_shop)
	EventBus.ending_requested.connect(_show_ending)
	EventBus.end_day_requested.connect(_end_day)
	EventBus.day_started.connect(func(_d: int, _s: int, _y: int) -> void: _check_deadline())
	SaveManager.register("world", self)
	_load_level(start_level, &"")
	_show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _can_pause():
		_show_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_inventory") and _can_pause():
		open_backpack()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_save"):
		_save()
	elif event.is_action_pressed("quick_load"):
		_load()
	elif event.is_action_pressed("debug_next_day") and OS.is_debug_build():
		TimeManager.start_next_day()
		EventBus.notification_requested.emit("[debug] %s" % TimeManager.get_date_text())
	elif event.is_action_pressed("debug_end_year") and OS.is_debug_build():
		# Jump to the last day of the story year (sleep once more to reach the deadline).
		GameState.set_story_flag(&"main_quest_started")
		TimeManager.day_of_year = GameState.DEADLINE_DAYS
		TimeManager.reset_clock()
		EventBus.notification_requested.emit("[debug] Last day of the year. Sleep to reach the deadline.")


# --- Title screen and pause menu ---------------------------------------------

func _show_title() -> void:
	_close_menu()
	_menu = _open_menu("Future Land", true)
	_menu.add_option(&"continue", "Continue", SaveManager.has_save())
	_menu.add_option(&"new", "New Game")
	_menu.focus_first()
	match await _menu.chosen:
		&"continue":
			_close_menu()
			_load()
		&"new":
			_close_menu()
			_new_game()


func _show_pause_menu() -> void:
	_menu = _open_menu("Paused", false)
	_menu.add_option(&"resume", "Resume")
	_menu.add_option(&"save", "Save Game")
	_menu.add_option(&"load", "Load Game", SaveManager.has_save())
	_menu.add_option(&"title", "Quit to Title")
	_menu.focus_first()
	match await _menu.chosen:
		&"resume":
			_close_menu()
		&"save":
			_close_menu()
			_save()
		&"load":
			_close_menu()
			_load()
		&"title":
			_show_title()


## Opens a shop (after its owner's greeting) and pauses the game until it is closed.
func open_shop(shop_id: StringName) -> void:
	var shop: Shop = SHOP_SCENE.instantiate()
	shop.shop_id = shop_id
	$UI.add_child(shop)
	get_tree().paused = true
	shop.closed.connect(func() -> void: get_tree().paused = false)


## Opens the backpack and pauses the game until it is closed.
func open_backpack(shop_open := false, bin_open := false) -> Backpack:
	var backpack: Backpack = BACKPACK_SCENE.instantiate()
	backpack.shop_open = shop_open
	backpack.bin_open = bin_open
	$UI.add_child(backpack)
	get_tree().paused = true
	backpack.closed.connect(func() -> void: get_tree().paused = false)
	return backpack


func _open_menu(title: String, backdrop: bool, message := "") -> GameMenu:
	var menu: GameMenu = MENU_SCENE.instantiate()
	menu.title = title
	menu.message = message
	menu.show_backdrop_image = backdrop
	$UI.add_child(menu)
	get_tree().paused = true
	return menu


func _close_menu() -> void:
	if is_instance_valid(_menu):
		_menu.queue_free()
	_menu = null
	get_tree().paused = false


func _can_pause() -> bool:
	return _menu == null and not get_tree().paused and not DialogueManager.is_active() and not _transitioning


# --- Ending a day -------------------------------------------------------------

## Sleep: fade out, next morning, autosave, fade in.
func _end_day() -> void:
	if _transitioning:
		return
	_transitioning = true
	TimeManager.paused = true
	await _fade_to(1.0)
	if not GameState.has_story_flag(&"first_sleep"):
		GameState.set_story_flag(&"first_sleep")
	TimeManager.start_next_day()
	SaveManager.save_game()
	await get_tree().create_timer(0.4).timeout
	await _fade_to(0.0)
	TimeManager.paused = false
	_transitioning = false
	var morning := "Good morning! %s" % TimeManager.get_date_text()
	if GameState.last_shipping_income > 0:
		morning += "  The shipping bin earned %s g." % GameState.format_money(GameState.last_shipping_income)
	EventBus.notification_requested.emit(morning)


# --- Year end -----------------------------------------------------------------

## The morning after the last day: the official comes for the decision.
func _check_deadline() -> void:
	if not GameState.is_deadline_reached():
		return
	await get_tree().create_timer(1.0).timeout
	# Wait for any conversation already running (e.g. an NPC greeting).
	while DialogueManager.is_active():
		await EventBus.dialogue_finished
		await get_tree().process_frame
	var can_pay := GameState.money >= GameState.BUYBACK_PRICE or GameState.has_story_flag(&"land_repurchase_paid")
	DialogueManager.start(&"year_end_resolution_farm_saved" if can_pay else &"year_end_resolution_demolition")


func _show_ending(kind: String) -> void:
	var saved := kind == "saved"
	if not saved:
		# Demolition: the screen fades to red as the robots move in.
		fade.color = Color(0.35, 0.02, 0.02)
		EventBus.notification_requested.emit("The demolition robots move in...")
		await _fade_to(1.0)
		await get_tree().create_timer(1.5).timeout
	_close_menu()
	fade.modulate.a = 0.0
	fade.color = Color.BLACK
	_menu = _open_menu("The Farm Endures" if saved else "The Farm Is Demolished", false,
		"You raised the money and bought back your land. A year ago this was just a place to live; now it's home." if saved
		else "You couldn't raise enough money in time. The city cleared the land, and your family's farm is gone.")
	if saved:
		_menu.add_option(&"continue", "Keep farming")
	_menu.add_option(&"title", "Title screen")
	_menu.focus_first()
	if not saved:
		(_menu.get_node("Dim") as ColorRect).color = Color(0.3, 0.02, 0.02, 0.92)
	var choice: StringName = await _menu.chosen
	if choice == &"continue":
		_close_menu()
		SaveManager.save_game()
	else:
		_show_title()


# --- New game, save, load ----------------------------------------------------

func _new_game() -> void:
	GameState.new_game()
	TimeManager.reset()
	_load_level(start_level, &"")
	var screen := AVATAR_SELECT_SCENE.instantiate()
	$UI.add_child(screen)
	get_tree().paused = true
	await screen.avatar_chosen
	get_tree().paused = false
	await get_tree().create_timer(0.4).timeout
	DialogueManager.start(&"opening")


func _save() -> void:
	if SaveManager.save_game():
		EventBus.notification_requested.emit("Game saved")


func _load() -> void:
	var loaded := SaveManager.load_game()
	EventBus.notification_requested.emit("Game loaded" if loaded else "No save file")


## Saved with the game: the current map and where the player stands.
func get_save_data() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var position := player.global_position if player else Vector2.ZERO
	return {"level": _level_path, "x": position.x, "y": position.y}


func load_save_data(data: Dictionary) -> void:
	var path := str(data.get("level", start_level))
	if not ResourceLoader.exists(path):
		path = start_level
	_load_level(path, &"")
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and data.has("x"):
		player.teleport(Vector2(float(data["x"]), float(data["y"])))


# --- Levels ----------------------------------------------------------------

func change_level(level_path: String, spawn_point: StringName = &"") -> void:
	if _transitioning:
		return
	_transitioning = true
	TimeManager.paused = true
	await _fade_to(1.0)
	_load_level(level_path, spawn_point)
	await _fade_to(0.0)
	TimeManager.paused = false
	_transitioning = false


func _load_level(level_path: String, spawn_point: StringName) -> void:
	if _level:
		world.remove_child(_level)
		_level.queue_free()
	var scene := load(level_path) as PackedScene
	if scene == null:
		push_error("Could not load level: %s" % level_path)
		return
	_level = scene.instantiate() as Level
	_level_path = level_path
	world.add_child(_level)
	_level.place_player(spawn_point)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished
