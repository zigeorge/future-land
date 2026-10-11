extends Control
## Avatar selection shown at the start of a new game. The game is paused
## underneath; choosing sets GameState.avatar_id and frees this screen.

signal avatar_chosen(avatar_id: StringName)

const CARD_SIZE := Vector2(72, 108)
const WALK_FRAME_SECONDS := 0.15

var _avatars: Array[AvatarData] = []
var _cards: Array[PanelContainer] = []
var _selected := 0
var _walk_frame := 0
var _walk_timer := 0.0

@onready var cards_box: HBoxContainer = %Cards
@onready var name_label: Label = %NameLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for avatar_id in Registry.AVATAR_IDS:
		var avatar := Registry.get_avatar(avatar_id)
		if avatar:
			_avatars.append(avatar)
			_cards.append(_make_card(_avatars.size() - 1))
	_select(0)


func _process(delta: float) -> void:
	# The highlighted avatar walks on the spot.
	_walk_timer += delta
	if _walk_timer >= WALK_FRAME_SECONDS:
		_walk_timer = 0.0
		_walk_frame = _walk_frame % 4 + 1
		_set_card_frame(_selected, _walk_frame)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_right"):
		_select(_selected + 1)
	elif event.is_action_pressed("move_left"):
		_select(_selected - 1)
	elif event.is_action_pressed("advance_dialogue") or event.is_action_pressed("ui_accept"):
		_confirm()
	else:
		return
	get_viewport().set_input_as_handled()


func _make_card(index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = _avatars[index].get_frame("down", 0)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(picture)
	card.gui_input.connect(_on_card_input.bind(index))
	cards_box.add_child(card)
	return card


func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if index == _selected:
			_confirm()
		else:
			_select(index)


func _select(index: int) -> void:
	_set_card_frame(_selected, 0)
	_selected = posmod(index, _avatars.size())
	_walk_frame = 0
	for i in _cards.size():
		_cards[i].self_modulate = Color(2.0, 1.7, 0.6) if i == _selected else Color(0.7, 0.7, 0.7)
	name_label.text = _avatars[_selected].display_name


func _set_card_frame(index: int, column: int) -> void:
	if index < _cards.size():
		(_cards[index].get_node("Picture") as TextureRect).texture = _avatars[index].get_frame("down", column)


func _confirm() -> void:
	GameState.avatar_id = _avatars[_selected].id
	avatar_chosen.emit(_avatars[_selected].id)
	queue_free()
