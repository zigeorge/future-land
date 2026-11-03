extends Node
## Player settings: music and sound volume, text speed, fullscreen.
##
## Kept in user://settings.cfg, apart from the save game, so starting a new
## game or loading an old save never changes them. Loaded once at startup.

const PATH := "user://settings.cfg"

enum TextSpeed { SLOW, NORMAL, INSTANT }
const TEXT_SPEED_NAMES: Array[String] = ["Slow", "Normal", "Instant"]
## Typewriter speed per TextSpeed (0 = the whole line at once).
const CHARACTERS_PER_SECOND: Array[float] = [20.0, 40.0, 0.0]

## Linear volume, 0.0 - 1.0.
var music_volume := 1.0
var sfx_volume := 1.0
var text_speed := TextSpeed.NORMAL
var fullscreen := false


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		music_volume = clampf(config.get_value("audio", "music", music_volume), 0.0, 1.0)
		sfx_volume = clampf(config.get_value("audio", "sfx", sfx_volume), 0.0, 1.0)
		text_speed = clampi(config.get_value("text", "speed", text_speed), 0, TextSpeed.size() - 1) as TextSpeed
		fullscreen = config.get_value("display", "fullscreen", fullscreen)
	_apply_volume()
	# Browsers only allow fullscreen after a click, so the web page starts windowed.
	if fullscreen and not OS.has_feature("web"):
		_apply_fullscreen()


func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	_apply_volume()
	save()


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	_apply_volume()
	save()


func set_text_speed(speed: TextSpeed) -> void:
	text_speed = speed
	save()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	save()


func characters_per_second() -> float:
	return CHARACTERS_PER_SECOND[text_speed]


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("text", "speed", text_speed)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(PATH)


func _apply_volume() -> void:
	AudioManager.set_bus_volume(AudioManager.MUSIC_BUS, music_volume)
	AudioManager.set_bus_volume(AudioManager.SFX_BUS, sfx_volume)


func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
