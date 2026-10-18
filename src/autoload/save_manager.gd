extends Node
## Saves and loads the game as JSON in user://.
##
## Each saved system exposes get_save_data() -> Dictionary and
## load_save_data(data). Autoloads are listed in _saved_systems(); scene
## nodes (like Main, which saves the current map) call register().

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1


var _registered: Dictionary = {}


func register(key: String, system: Object) -> void:
	_registered[key] = system


func _saved_systems() -> Dictionary:
	var systems := {"time": TimeManager, "state": GameState}
	for key: String in _registered:
		if is_instance_valid(_registered[key]):
			systems[key] = _registered[key]
	return systems


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data := {"version": SAVE_VERSION}
	var systems := _saved_systems()
	for key: String in systems:
		data[key] = systems[key].get_save_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save game: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	EventBus.game_saved.emit()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file is corrupted: %s" % SAVE_PATH)
		return false
	# TODO: migrate older saves when SAVE_VERSION changes.
	var systems := _saved_systems()
	for key: String in systems:
		systems[key].load_save_data(data.get(key, {}))
	EventBus.game_loaded.emit()
	return true
