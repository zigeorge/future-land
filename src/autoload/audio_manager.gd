extends Node
## Music and sound-effect playback on the Music / SFX buses.
##
## Usage: AudioManager.play_music(preload("res://assets/audio/music/farm.ogg"))
##        AudioManager.play_sfx(preload("res://assets/audio/sfx/hoe.wav"))

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
	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)


func play_music(stream: AudioStream, fade_time := 1.0) -> void:
	if stream == null or (_music.stream == stream and _music.playing):
		return
	if _music.playing:
		await _fade_music(SILENT_DB, fade_time * 0.5)
	_music.stream = stream
	_music.volume_db = SILENT_DB
	_music.play()
	await _fade_music(0.0, fade_time * 0.5)


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
