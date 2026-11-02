extends Node
## Music and sound-effect playback on the Music / SFX buses.
##
## Usage: AudioManager.play_music(preload("res://assets/audio/music/farm.ogg"))
##        AudioManager.play_sfx(preload("res://assets/audio/sfx/hoe.wav"))
##        AudioManager.play_ui(&"pickup"), AudioManager.play_tool(item)
##
## Every button in the game clicks when pressed and ticks when it gets focus
## or the mouse; nothing else is needed for new menus.

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const SFX_VOICES := 8
const SILENT_DB := -40.0

var _music: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	add_child(_music)
	_music.finished.connect(_on_track_finished)
	EventBus.day_started.connect(func(_d: int, season: int, _y: int) -> void: play_season(season))
	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)
	get_tree().node_added.connect(_on_node_added)


const MUSIC_LIST_PATH := "res://data/music.json"
## Music volume (dB) on the Music bus; quiet enough to talk over.
const MUSIC_DB := -8.0

var _season_tracks: Array[AudioStream] = []
var _season_index := 0
var _current_season := -1


## Starts the playlist for a season from data/music.json (silence if empty).
func play_season(season: int) -> void:
	if season == _current_season and _music.playing:
		return
	_current_season = season
	_season_tracks.clear()
	_season_index = 0
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MUSIC_LIST_PATH))
	var names := ["spring", "summer", "autumn", "winter"]
	if data is Dictionary:
		for path: String in data.get("seasons", {}).get(names[season], []):
			var stream := load(path) as AudioStream
			if stream:
				_season_tracks.append(stream)
	if _season_tracks.is_empty():
		stop_music()
	else:
		play_music(_season_tracks[0])


func _on_track_finished() -> void:
	if _season_tracks.is_empty():
		return
	_season_index = (_season_index + 1) % _season_tracks.size()
	_music.stream = _season_tracks[_season_index]
	_music.play()


func play_music(stream: AudioStream, fade_time := 1.0) -> void:
	if stream == null or (_music.stream == stream and _music.playing):
		return
	if _music.playing:
		await _fade_music(SILENT_DB, fade_time * 0.5)
	_music.stream = stream
	_music.volume_db = SILENT_DB
	_music.play()
	await _fade_music(MUSIC_DB, fade_time * 0.5)


func stop_music(fade_time := 1.0) -> void:
	await _fade_music(SILENT_DB, fade_time)
	_music.stop()


## Plays a one-shot sound. pitch_variation adds slight randomness (e.g. 0.1).
func play_sfx(stream: AudioStream, pitch_variation := 0.0) -> void:
	if stream == null:
		return
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_VOICES
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


const UI_SOUND_DIR := "res://assets/audio/sfx/ui/%s.wav"
## Tool sounds are found by item id, like item icons: sfx/tools/<id>.wav.
const TOOL_SOUND_DIR := "res://assets/audio/sfx/tools/%s.wav"
## Ignore focus ticks this soon after another UI sound (menus focus their first button when they open).
const UI_GAP_MSEC := 120

var _sounds: Dictionary = {}  # path -> AudioStream (null if the file doesn't exist)
var _last_ui_msec := -UI_GAP_MSEC


## Interface sounds: click, hover, select, confirm, cancel, error, pickup.
func play_ui(sound_name: StringName) -> void:
	_last_ui_msec = Time.get_ticks_msec()
	play_sfx(_sound(UI_SOUND_DIR % sound_name))


## The sound of using a tool (silent for items without one).
func play_tool(item: ItemData) -> void:
	if item:
		play_sfx(_sound(TOOL_SOUND_DIR % item.id), 0.06)


func _sound(path: String) -> AudioStream:
	if not _sounds.has(path):
		_sounds[path] = load(path) if ResourceLoader.exists(path) else null
	return _sounds[path]


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null:
		return
	button.pressed.connect(func() -> void: play_ui(&"click"))
	button.mouse_entered.connect(_hover.bind(button))
	button.focus_entered.connect(_hover.bind(button))


func _hover(button: BaseButton) -> void:
	if not button.disabled and Time.get_ticks_msec() - _last_ui_msec > UI_GAP_MSEC:
		play_ui(&"hover")


## volume is linear, 0.0 - 1.0 (for settings sliders).
func set_bus_volume(bus: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(volume, 0.0, 1.0)))


func _fade_music(target_db: float, duration: float) -> void:
	if duration <= 0.0:
		_music.volume_db = target_db
		return
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", target_db, duration)
	await tween.finished
