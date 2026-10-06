extends PanelContainer
## Displays dialogue lines from DialogueManager with a typewriter effect.
## Restyle freely in dialogue_box.tscn; keep the %UniqueName nodes.

const CHARACTERS_PER_SECOND := 40.0

var _typing_tween: Tween

@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel


func _ready() -> void:
	hide()
	EventBus.dialogue_line_shown.connect(_on_line_shown)
	EventBus.dialogue_finished.connect(func(_id: StringName) -> void: hide())


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("advance_dialogue"):
		return
	get_viewport().set_input_as_handled()
	if _typing_tween and _typing_tween.is_running():
		_typing_tween.kill()
		text_label.visible_ratio = 1.0
	else:
		DialogueManager.advance()


func _on_line_shown(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	text_label.text = text
	text_label.visible_ratio = 0.0
	show()
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, text.length() / CHARACTERS_PER_SECOND)
