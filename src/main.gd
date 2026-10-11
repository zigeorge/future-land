extends Node
## Root scene. Owns the persistent UI and swaps levels inside $World.

const FADE_SECONDS := 0.3
const AVATAR_SELECT_SCENE := preload("res://src/ui/avatar_select/avatar_select.tscn")

@export_file("*.tscn") var start_level := "res://src/world/farm/farm.tscn"

var _level: Level
var _transitioning := false

@onready var world: Node2D = $World
@onready var fade: ColorRect = $Transition/Fade


func _ready() -> void:
	EventBus.level_change_requested.connect(change_level)
	_load_level(start_level, &"")
	if GameState.avatar_id == &"":
		_choose_avatar()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):
		if SaveManager.save_game():
			EventBus.notification_requested.emit("Game saved")
	elif event.is_action_pressed("quick_load"):
		var loaded := SaveManager.load_game()
		EventBus.notification_requested.emit("Game loaded" if loaded else "No save file")
	elif event.is_action_pressed("debug_next_day") and OS.is_debug_build():
		TimeManager.start_next_day()
		EventBus.notification_requested.emit("[debug] %s" % TimeManager.get_date_text())


## Pauses the game until the player picks an avatar.
func _choose_avatar() -> void:
	var screen := AVATAR_SELECT_SCENE.instantiate()
	$UI.add_child(screen)
	get_tree().paused = true
	await screen.avatar_chosen
	get_tree().paused = false


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
	world.add_child(_level)
	_level.place_player(spawn_point)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished
