extends TestCase
## Settings are kept in their own file, not in the save game.


func test_settings_are_saved_and_loaded() -> void:
	var before := FileAccess.get_file_as_bytes(Settings.PATH) if FileAccess.file_exists(Settings.PATH) else PackedByteArray()
	var old := [Settings.music_volume, Settings.sfx_volume, Settings.text_speed]
	Settings.set_music_volume(0.3)
	Settings.set_sfx_volume(1.7)
	Settings.set_text_speed(Settings.TextSpeed.INSTANT)
	var reloaded: Node = load("res://src/autoload/settings.gd").new()
	reloaded._ready()
	assert_eq(reloaded.music_volume, 0.3, "music volume")
	assert_eq(reloaded.sfx_volume, 1.0, "volume is capped at 1")
	assert_eq(reloaded.text_speed, Settings.TextSpeed.INSTANT, "text speed")
	assert_eq(reloaded.characters_per_second(), 0.0, "instant text has no typewriter")
	reloaded.free()
	# Put the tester's own settings back.
	Settings.set_music_volume(old[0])
	Settings.set_sfx_volume(old[1])
	Settings.set_text_speed(old[2])
	if before.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.PATH))
	else:
		FileAccess.open(Settings.PATH, FileAccess.WRITE).store_buffer(before)

