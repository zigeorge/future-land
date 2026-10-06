extends Node
## Plays dialogue written as JSON files in res://data/dialogue/.
##
## The story lead edits only the JSON files (format: data/README.md).
## UI listens to EventBus.dialogue_* signals; it never parses files itself.

const DIALOGUE_DIR := "res://data/dialogue/"

var _lines: Array = []
var _index := -1
var _current_id: StringName = &""


func is_active() -> bool:
	return _current_id != &""


func start(dialogue_id: StringName) -> void:
	if is_active():
		return
	var data := _load_dialogue(dialogue_id)
	if data.is_empty():
		return
	_lines = data.get("lines", [])
	_index = -1
	_current_id = dialogue_id
	EventBus.dialogue_started.emit(dialogue_id)
	advance()


## Shows the next line, or ends the conversation after the last one.
func advance() -> void:
	if not is_active():
		return
	_index += 1
	if _index >= _lines.size():
		_finish()
		return
	var line: Dictionary = _lines[_index]
	if line.has("set_flag"):
		GameState.set_story_flag(StringName(line["set_flag"]))
	EventBus.dialogue_line_shown.emit(str(line.get("speaker", "")), str(line.get("text", "")))


func _finish() -> void:
	var finished_id := _current_id
	_current_id = &""
	_lines = []
	_index = -1
	EventBus.dialogue_finished.emit(finished_id)


func _load_dialogue(dialogue_id: StringName) -> Dictionary:
	var path := DIALOGUE_DIR + String(dialogue_id) + ".json"
	if not FileAccess.file_exists(path):
		push_error("Dialogue not found: %s" % path)
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY or not data.has("lines"):
		push_error("Dialogue file is not valid (needs a \"lines\" array): %s" % path)
		return {}
	return data
