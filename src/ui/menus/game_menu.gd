class_name GameMenu
extends Control
## A full-screen menu of buttons: the title screen and the pause menu.
## Emits `chosen` with the id of the pressed button. Runs while the game is
## paused; keyboard (arrows / W S, Enter / E) and mouse both work.

signal chosen(id: StringName)

@export var title := ""
@export var show_backdrop_image := false

@onready var title_label: Label = %TitleLabel
@onready var buttons_box: VBoxContainer = %Buttons
@onready var backdrop: TextureRect = %Backdrop
@onready var panel: PanelContainer = $Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = title
	backdrop.visible = show_backdrop_image
	if show_backdrop_image:
		# The backdrop already shows the logo; put the buttons over its
		# "Loading..." bar at the bottom.
		title_label.hide()
		panel.offset_top = 100.0
		panel.offset_bottom = 160.0


## Adds a button; disabled buttons are shown greyed out.
func add_option(id: StringName, label: String, enabled := true) -> void:
	var button := Button.new()
	button.text = label
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(140, 0)
	button.pressed.connect(func() -> void: chosen.emit(id))
	buttons_box.add_child(button)


func focus_first() -> void:
	for button: Button in buttons_box.get_children():
		if not button.disabled:
			button.grab_focus()
			return


func _unhandled_input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner() as Button
	if focused == null:
		return
	if event.is_action_pressed("move_down"):
		_move_focus(focused, 1)
	elif event.is_action_pressed("move_up"):
		_move_focus(focused, -1)
	elif event.is_action_pressed("advance_dialogue"):
		focused.pressed.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func _move_focus(from: Button, step: int) -> void:
	var buttons := buttons_box.get_children().filter(func(b: Button) -> bool: return not b.disabled)
	var index := buttons.find(from)
	(buttons[posmod(index + step, buttons.size())] as Button).grab_focus()
