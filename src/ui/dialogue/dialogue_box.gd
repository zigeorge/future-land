extends Control
## Displays dialogue lines from DialogueManager with a typewriter effect. When a
## line offers answers they appear in a separate box above the dialogue's
## right side, Animal Crossing style.
## Restyle freely in dialogue_box.tscn; keep the %UniqueName nodes.

const CHARACTERS_PER_SECOND := 40.0

var _typing_tween: Tween
var _pending_choices: Array[String] = []
## Highlighted choice. Tracked here rather than read from GUI focus, because
## focus is lost if the player clicks elsewhere.
var _choice_index := 0
var _choice_texts: Array[String] = []

@onready var portrait: TextureRect = %Portrait
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel
@onready var choices_panel: PanelContainer = %ChoicesPanel
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
	if choices_panel.visible:
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
	_show_portrait(speaker)
	text_label.text = text
	text_label.visible_ratio = 0.0
	_clear_choices()
	show()
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, text.length() / CHARACTERS_PER_SECOND)
	_typing_tween.finished.connect(_show_pending_choices)


## assets/art/portraits/<speaker>.png; the player ("You") uses the avatar's.
func _show_portrait(speaker: String) -> void:
	var texture: Texture2D = null
	if speaker == "You":
		var avatar := Registry.get_avatar(GameState.avatar_id) if GameState.avatar_id != &"" else null
		texture = avatar.get_portrait() if avatar else null
	elif speaker != "":
		texture = Registry.get_portrait(speaker)
	portrait.texture = texture
	portrait.texture_filter = Art.filter_for(texture, 64)
	portrait.visible = texture != null


func _on_choices_shown(choices: Array[String]) -> void:
	_pending_choices = choices
	if not _is_typing():
		_show_pending_choices()


func _show_pending_choices() -> void:
	if _pending_choices.is_empty():
		return
	_choice_texts = _pending_choices
	for i in _pending_choices.size():
		var button := Button.new()
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(DialogueManager.choose.bind(i))
		button.mouse_entered.connect(_highlight_choice.bind(i))
		choices_box.add_child(button)
	_pending_choices = []
	choices_panel.show()
	hint_label.hide()
	_highlight_choice(0)


func _handle_choice_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		_highlight_choice(_choice_index + 1)
	elif event.is_action_pressed("move_up"):
		_highlight_choice(_choice_index - 1)
	elif event.is_action_pressed("advance_dialogue") or event.is_action_pressed("ui_accept"):
		DialogueManager.choose(_choice_index)
	else:
		return
	get_viewport().set_input_as_handled()


func _highlight_choice(index: int) -> void:
	var buttons := choices_box.get_children()
	_choice_index = posmod(index, buttons.size())
	for i in buttons.size():
		var button := buttons[i] as Button
		button.text = ("> " if i == _choice_index else "   ") + _choice_texts[i]
		button.modulate = Color(1, 0.85, 0.4) if i == _choice_index else Color.WHITE


func _clear_choices() -> void:
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()
	choices_panel.hide()
	hint_label.show()


func _is_typing() -> bool:
	return _typing_tween != null and _typing_tween.is_running()


func _finish_typing() -> void:
	_typing_tween.kill()
	text_label.visible_ratio = 1.0
	_show_pending_choices()
