class_name FishingCast
extends Node2D
## One fishing attempt, drawn around the player: the rod (the tool's icon)
## swings, the bobber flies out on a line and floats; when a fish bites the
## bobber is pulled under and "!" appears, and the player has REACT_SECONDS
## to press the tool button (C / left click) or E to reel it in.
## Emits `finished` with the caught fish, or null.

signal finished(fish: ItemData)

const ROD_LENGTH := 15.0
## Where the handle and the tip are on the tool icons (fractions of the image).
const ICON_HANDLE := Vector2(0.1, 0.9)
const ICON_TIP := Vector2(0.92, 0.08)
const HAND := Vector2(4, -13)
const CAST_SECONDS := 0.45
const WAIT_RANGE := Vector2(1.5, 4.0)
const REACT_SECONDS := 0.9
const LINE_COLOR := Color(0.95, 0.95, 0.95, 0.85)

enum Phase { CASTING, WAITING, BITE, REELING, DONE }

var _phase := Phase.CASTING
var _fish: ItemData
var _facing := Vector2.RIGHT
var _bobber := Vector2.ZERO        # local position of the bobber
var _target := Vector2.ZERO        # where the bobber lands
var _bob_time := 0.0
var _splash := 0.0                 # 0..1 ripple / splash animation
var _rod: Sprite2D
var _alert: Label


## rod: the fishing tool; target: world point in the water; fish: what will
## bite (null = nothing bites).
func setup(rod: ItemData, facing: Vector2, target_world: Vector2, fish: ItemData) -> void:
	_fish = fish
	_facing = facing
	_target = target_world - get_parent().global_position
	_rod = Sprite2D.new()
	_rod.texture = rod.icon
	_rod.centered = false
	var size := rod.icon.get_size() if rod.icon else Vector2(128, 128)
	_rod.offset = -ICON_HANDLE * size
	_rod.scale = Vector2.ONE * ROD_LENGTH / size.length() * 1.4
	_rod.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_rod.flip_h = facing == Vector2.LEFT
	if _rod.flip_h:
		_rod.offset.x = -(1.0 - ICON_HANDLE.x) * size.x
	_rod.position = _hand()
	_rod.z_index = -1 if facing == Vector2.UP else 1
	add_child(_rod)
	_alert = Label.new()
	_alert.text = "!"
	_alert.add_theme_font_size_override("font_size", 16)
	_alert.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	_alert.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0))
	_alert.add_theme_constant_override("outline_size", 5)
	_alert.position = Vector2(-4, -50)
	_alert.visible = false
	add_child(_alert)
	z_index = 1
	_run()


func _hand() -> Vector2:
	return Vector2(HAND.x * (-1.0 if _facing == Vector2.LEFT else 1.0), HAND.y)


## Rod angle in degrees: 0 = icon as drawn (tip up and forward).
func _set_rod_angle(degrees: float) -> void:
	_rod.rotation_degrees = -degrees if _rod.flip_h else degrees


func _tip() -> Vector2:
	var size := _rod.texture.get_size() if _rod.texture else Vector2(128, 128)
	var tip := ICON_TIP * size
	if _rod.flip_h:
		tip.x = size.x - tip.x
	return _rod.transform * (tip + _rod.offset)


func _run() -> void:
	# Cast: wind up, swing forward, bobber arcs out.
	_set_rod_angle(-75.0)
	_bobber = _tip()
	var swing := create_tween()
	swing.tween_method(_set_rod_angle, -75.0, 20.0, CAST_SECONDS * 0.6).set_ease(Tween.EASE_IN)
	await swing.finished
	var start := _tip()
	var fly := create_tween()
	fly.tween_method(func(t: float) -> void:
		_bobber = start.lerp(_target, t) + Vector2(0, -24.0 * sin(PI * t))
		queue_redraw(), 0.0, 1.0, CAST_SECONDS)
	await fly.finished
	_phase = Phase.WAITING
	_splash = 1.0
	await get_tree().create_timer(randf_range(WAIT_RANGE.x, WAIT_RANGE.y)).timeout
	if _phase != Phase.WAITING:
		return  # the player reeled in early
	if _fish == null:
		EventBus.notification_requested.emit("Nothing is biting. Try again!")
		_reel(null)
		return
	# Bite!
	_phase = Phase.BITE
	_alert.visible = true
	_splash = 1.0
	await get_tree().create_timer(REACT_SECONDS).timeout
	if _phase == Phase.BITE:
		EventBus.notification_requested.emit("It got away! Press C faster when you see \"!\"")
		_reel(null)


func _unhandled_input(event: InputEvent) -> void:
	if _phase == Phase.DONE or _phase == Phase.REELING:
		return
	if event.is_action_pressed("use_tool") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _phase == Phase.BITE:
			_reel(_fish)
		elif _phase == Phase.WAITING:
			EventBus.notification_requested.emit("Too early, nothing on the line")
			_reel(null)


func _reel(fish: ItemData) -> void:
	_phase = Phase.REELING
	_alert.visible = false
	var from := _bobber
	var back := create_tween()
	back.tween_method(func(t: float) -> void:
		_bobber = from.lerp(_tip(), t) + Vector2(0, -16.0 * sin(PI * t))
		_set_rod_angle(lerpf(20.0, -30.0, t))
		queue_redraw(), 0.0, 1.0, 0.35)
	await back.finished
	if fish and fish.icon:
		var trophy := Sprite2D.new()
		trophy.texture = fish.icon
		trophy.scale = Vector2.ONE * 16.0 / fish.icon.get_width()
		trophy.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		trophy.position = Vector2(0, -38)
		add_child(trophy)
		_rod.visible = false
		var rise := create_tween()
		rise.tween_property(trophy, "position:y", -48.0, 0.8).set_ease(Tween.EASE_OUT)
		await rise.finished
	_phase = Phase.DONE
	finished.emit(fish)
	queue_free()


func _process(delta: float) -> void:
	_bob_time += delta
	_splash = maxf(_splash - delta * 1.5, 0.0)
	if _phase == Phase.WAITING:
		_bobber = _target + Vector2(0, sin(_bob_time * 3.0) * 0.8)
	elif _phase == Phase.BITE:
		_bobber = _target + Vector2(sin(_bob_time * 40.0) * 0.8, 2.5)
	queue_redraw()


func _draw() -> void:
	if _rod == null or _phase == Phase.DONE:
		return
	var tip := _tip()
	if _phase != Phase.CASTING or _bobber != Vector2.ZERO:
		# Line from the rod tip to the bobber, sagging a little in the middle.
		var mid := (tip + _bobber) / 2.0 + Vector2(0, 4.0 if _phase in [Phase.WAITING, Phase.BITE] else 1.0)
		var points := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			points.append(tip.lerp(mid, t).lerp(mid.lerp(_bobber, t), t))
		draw_polyline(points, LINE_COLOR, 0.5, true)
	var in_water := _phase in [Phase.WAITING, Phase.BITE]
	if in_water:
		# Ripples, bigger and brighter on landing and on a bite.
		var ring := 3.0 + 2.0 * sin(_bob_time * 2.0)
		draw_arc(_target + Vector2(0, 1), ring, 0, TAU, 20, Color(1, 1, 1, 0.35), 0.5)
		if _splash > 0.0:
			draw_arc(_target + Vector2(0, 1), 3.0 + (1.0 - _splash) * 10.0, 0, TAU, 24, Color(1, 1, 1, _splash), 0.8)
	var sunk := _phase == Phase.BITE
	draw_circle(_bobber, 1.8, Color(0.95, 0.2, 0.15) if not sunk else Color(0.6, 0.15, 0.15, 0.7))
	if not sunk:
		draw_circle(_bobber + Vector2(0, -1.0), 1.0, Color.WHITE)
