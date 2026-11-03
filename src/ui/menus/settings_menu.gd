class_name SettingsMenu
extends Control
## The settings screen, opened from the title screen and the pause menu.
## Changes apply and save at once; Back or Esc closes it.
## Keyboard: W S / arrows move between rows, A D / arrows change a value,
## Enter / E presses a button.

signal closed

## How much one key press moves a volume slider.
const VOLUME_STEP := 0.1
## Same gold as the selected hotbar slot.
const FOCUS_COLOR := Color("ffd23f")

var _music: HSlider
var _sfx: HSlider
var _text_speed: Button
var _fullscreen: CheckButton
var _back: Button
var _rows: Array[Control] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.12, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	_music = _add_slider(grid, "Music", Settings.music_volume, Settings.set_music_volume)
	_sfx = _add_slider(grid, "Sounds", Settings.sfx_volume, _on_sfx_changed)
	_text_speed = Button.new()
	_text_speed.custom_minimum_size = Vector2(110, 0)
	_text_speed.pressed.connect(_cycle_text_speed.bind(1))
	_add_row(grid, "Text speed", _text_speed)
	_fullscreen = CheckButton.new()
	_fullscreen.button_pressed = Settings.fullscreen
	_fullscreen.toggled.connect(Settings.set_fullscreen)
	_add_row(grid, "Fullscreen", _fullscreen)
	_update_text_speed()

	_back = Button.new()
	_back.text = "Back"
	_back.pressed.connect(_close)
	box.add_child(_back)
	_rows.append(_back)
	_music.grab_focus()


func _add_slider(grid: GridContainer, label: String, value: float, on_change: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(110, 16)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	_add_row(grid, label, slider)
	return slider


func _add_row(grid: GridContainer, label: String, control: Control) -> void:
	var name_label := Label.new()
	name_label.text = label
	grid.add_child(name_label)
	grid.add_child(control)
	_rows.append(control)
	# Sliders show focus faintly, so the selected row's name turns gold.
	control.focus_entered.connect(func() -> void: name_label.add_theme_color_override("font_color", FOCUS_COLOR))
	control.focus_exited.connect(func() -> void: name_label.remove_theme_color_override("font_color"))


func _on_sfx_changed(volume: float) -> void:
	Settings.set_sfx_volume(volume)
	AudioManager.play_ui(&"select")  # so the player hears the new level


func _cycle_text_speed(step: int) -> void:
	var count := Settings.TextSpeed.size()
	Settings.set_text_speed(posmod(Settings.text_speed + step, count) as Settings.TextSpeed)
	_update_text_speed()


func _update_text_speed() -> void:
	_text_speed.text = "< %s >" % Settings.TEXT_SPEED_NAMES[Settings.text_speed]


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if event.is_action_pressed("pause"):
		_close()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_up"):
		var step := 1 if event.is_action_pressed("move_down") else -1
		_rows[posmod(_rows.find(focused) + step, _rows.size())].grab_focus()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		var step := 1 if event.is_action_pressed("move_right") else -1
		if focused is HSlider:
			(focused as HSlider).value += step * VOLUME_STEP
		elif focused == _text_speed:
			_cycle_text_speed(step)
		else:
			return
	elif event.is_action_pressed("advance_dialogue") and focused is BaseButton:
		var button := focused as BaseButton
		if button.toggle_mode:
			button.button_pressed = not button.button_pressed
		else:
			button.pressed.emit()
	else:
		return
	get_viewport().set_input_as_handled()
