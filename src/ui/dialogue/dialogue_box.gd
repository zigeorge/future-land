extends PanelContainer
## Displays dialogue lines from DialogueManager with a typewriter effect, and
## the player's choices when a line offers some.
## Restyle freely in dialogue_box.tscn; keep the %UniqueName nodes.

const CHARACTERS_PER_SECOND := 40.0

var _typing_tween: Tween
var _pending_choices: Array[String] = []

@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel
@onready var choices_box: VBoxContainer = %Choices
@onready var hint_label: Label = %HintLabel


func _ready() -> void:
	hide()
	EventBus.dialogue_line_shown.connect(_on_line_shown)
	EventBus.dialogue_choices_shown.connect(_on_choices_shown)
	EventBus.dialogue_finished.connect(func(_id: StringName) -> void: hide())


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if choices_box.visible:
		_handle_choice_input(event)
	elif event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		if _is_typing():
			_finish_typing()
		else:
			DialogueManager.advance()


func _on_line_shown(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	text_label.text = text
	text_label.visible_ratio = 0.0
	_clear_choices()
	show()
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, text.length() / CHARACTERS_PER_SECOND)
	_typing_tween.finished.connect(_show_pending_choices)


func _on_choices_shown(choices: Array[String]) -> void:
	_pending_choices = choices
	if not _is_typing():
		_show_pending_choices()


func _show_pending_choices() -> void:
	if _pending_choices.is_empty():
		return
	for i in _pending_choices.size():
		var button := Button.new()
		button.text = "> " + _pending_choices[i]
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(DialogueManager.choose.bind(i))
		choices_box.add_child(button)
	_pending_choices = []
	choices_box.show()
	hint_label.hide()
	(choices_box.get_child(0) as Button).grab_focus()


func _handle_choice_input(event: InputEvent) -> void:
	var buttons := choices_box.get_children()
	var focused := buttons.find(get_viewport().gui_get_focus_owner())
	var step := 0
	if event.is_action_pressed("move_down"):
		step = 1
	elif event.is_action_pressed("move_up"):
		step = -1
	if step != 0:
		(buttons[posmod(focused + step, buttons.size())] as Button).grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("advance_dialogue") and focused >= 0:
		get_viewport().set_input_as_handled()
		DialogueManager.choose(focused)


func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()
	choices_box.hide()
	hint_label.show()


func _is_typing() -> bool:
	return _typing_tween != null and _typing_tween.is_running()


func _finish_typing() -> void:
	_typing_tween.kill()
	text_label.visible_ratio = 1.0
	_show_pending_choices()
