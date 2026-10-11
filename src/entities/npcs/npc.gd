class_name NPC
extends StaticBody2D
## A villager the player can talk to. Everything is set per instance in the
## level's Inspector; the conversations live in data/dialogue/.
##
## Conversation choice: dialogue_id plays until its done_flag is set (the flag
## is set by the dialogue file itself), then repeat_dialogue_id plays.
## Presence: the NPC is only in the level from appear_from_day, while
## requires_flag is set and until hidden_by_flag is set. Changes wait until
## any running conversation has ended.

const FRAME_SIZE := Vector2i(16, 32)
const AUTO_TALK_DELAY := 0.6

@export var npc_name := "Villager"

@export_group("Dialogue")
## First conversation: file name (without .json) in data/dialogue/.
@export var dialogue_id: StringName
## Story flag that marks the first conversation as done. Empty = it never is.
@export var done_flag: StringName
## Played after the first conversation is done. Empty = say nothing more.
@export var repeat_dialogue_id: StringName
## Start the first conversation by itself when the player arrives.
@export var auto_talk := false

@export_group("Presence")
@export var appear_from_day := 1
@export var requires_flag: StringName
@export var hidden_by_flag: StringName

@export_group("Sprite")
## Either a SpriteFrames (plays "idle_down", else the first animation)...
@export var sprite_frames: SpriteFrames
## ...or a horizontal strip of 16x32 idle frames, e.g. assets/art/characters/banker.png.
@export var sprite_texture: Texture2D
@export var idle_fps := 2.0

var _present := true

@onready var name_label: Label = $NameLabel
@onready var interactable: Interactable = $Interactable
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var placeholder: CanvasItem = $Placeholder
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	name_label.text = npc_name
	_setup_sprite()
	interactable.interacted.connect(_on_interacted)
	EventBus.day_started.connect(func(_d: int, _s: int, _y: int) -> void: _refresh_presence())
	EventBus.story_flag_changed.connect(func(_f: StringName, _v: Variant) -> void: _refresh_presence())
	EventBus.dialogue_finished.connect(func(_id: StringName) -> void: _refresh_presence())
	EventBus.avatar_changed.connect(func(_id: StringName) -> void: _try_auto_talk())
	EventBus.game_loaded.connect(_refresh_presence)
	_refresh_presence()
	_try_auto_talk()


func is_present() -> bool:
	return _present


func should_be_present() -> bool:
	if TimeManager.get_day_number() < appear_from_day:
		return false
	if requires_flag != &"" and not GameState.has_story_flag(requires_flag):
		return false
	return hidden_by_flag == &"" or not GameState.has_story_flag(hidden_by_flag)


func get_current_dialogue() -> StringName:
	if done_flag == &"" or not GameState.has_story_flag(done_flag):
		return dialogue_id
	return repeat_dialogue_id


func _on_interacted(_player: Node) -> void:
	var dialogue := get_current_dialogue()
	if dialogue != &"":
		DialogueManager.start(dialogue)


func _refresh_presence() -> void:
	if DialogueManager.is_active():
		return  # Called again from dialogue_finished.
	var present := should_be_present()
	if present == _present:
		return
	_present = present
	visible = present
	collision.set_deferred("disabled", not present)
	interactable.set_deferred("monitorable", present)
	if present:
		_try_auto_talk()


func _try_auto_talk() -> void:
	if not auto_talk or not _present or GameState.avatar_id == &"":
		return
	if done_flag != &"" and GameState.has_story_flag(done_flag):
		return
	await get_tree().create_timer(AUTO_TALK_DELAY).timeout
	if is_inside_tree() and _present and not DialogueManager.is_active():
		DialogueManager.start(dialogue_id)


func _setup_sprite() -> void:
	var frames := sprite_frames
	if frames == null and sprite_texture:
		frames = SpriteFrames.new()
		frames.rename_animation(&"default", &"idle_down")
		frames.set_animation_speed(&"idle_down", idle_fps)
		for i in sprite_texture.get_width() / FRAME_SIZE.x:
			var atlas := AtlasTexture.new()
			atlas.atlas = sprite_texture
			atlas.region = Rect2(Vector2(i * FRAME_SIZE.x, 0), FRAME_SIZE)
			frames.add_frame(&"idle_down", atlas)
	placeholder.visible = frames == null
	if frames == null:
		return
	sprite.sprite_frames = frames
	var names := frames.get_animation_names()
	if not names.is_empty():
		sprite.play(&"idle_down" if frames.has_animation(&"idle_down") else StringName(names[0]))
