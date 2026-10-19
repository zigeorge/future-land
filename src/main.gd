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
func open_backpack(shop_open := false) -> Backpack:
	var backpack: Backpack = BACKPACK_SCENE.instantiate()
	backpack.shop_open = shop_open
	$UI.add_child(backpack)
	get_tree().paused = true
	backpack.closed.connect(func() -> void: get_tree().paused = false)
	return backpack


func _open_menu(title: String, backdrop: bool) -> GameMenu:
	var menu: GameMenu = MENU_SCENE.instantiate()
	menu.title = title
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
