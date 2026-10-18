extends Node
## Plays conversations from res://data/dialogue/ (format: data/README.md).
##
## The UI listens to EventBus.dialogue_* signals and calls advance() or
## choose(); it never reads the files itself.

const DIALOGUE_DIR := "res://data/dialogue/"
## Written in dialogue files where the player's name should appear.
const PLAYER_TOKEN := "{player}"

## Who says the current line: the role from the dialogue sheet (used for
## portraits), and whether it is the player.
var current_speaker_role := ""
var current_speaker_is_player := false

var _graph: DialogueGraph
var _node_id := ""
var _current_id: StringName = &""


func is_active() -> bool:
	return _current_id != &""


func is_choosing() -> bool:
	return is_active() and not _graph.get_choices(_node_id).is_empty()


func start(dialogue_id: StringName) -> void:
	if is_active():
		return
	var graph := DialogueGraph.load_file(DIALOGUE_DIR + String(dialogue_id) + ".json")
	if graph.error != "":
		push_error("Dialogue '%s': %s" % [dialogue_id, graph.error])
		return
	_graph = graph
	_current_id = dialogue_id
	EventBus.dialogue_started.emit(dialogue_id)
	_show(graph.start)


## Moves past the current line. Does nothing while a choice is waiting.
func advance() -> void:
	if is_active() and not is_choosing():
		_show(str(_graph.get_node_data(_node_id).get("next", DialogueGraph.END)))


func choose(index: int) -> void:
	if not is_choosing():
		return
	var choices := _graph.get_choices(_node_id)
	if index >= 0 and index < choices.size():
		_show(str(choices[index].get("next", DialogueGraph.END)))


func _show(node_id: String) -> void:
	if node_id == DialogueGraph.END or node_id == "":
		_finish()
		return
	if not _graph.nodes.has(node_id):
		push_error("Dialogue '%s': missing node %s" % [_current_id, node_id])
		_finish()
		return
	_node_id = node_id
	var node := _graph.get_node_data(node_id)
	_apply_effects(node)
	var speaker := str(node.get("speaker", ""))
	current_speaker_is_player = speaker == PLAYER_TOKEN
	current_speaker_role = "" if current_speaker_is_player else speaker
	var shown_name := _player_name() if current_speaker_is_player else Registry.get_npc_name(speaker)
	EventBus.dialogue_line_shown.emit(shown_name, _fill(str(node.get("text", ""))))
	var choices := _graph.get_choices(node_id)
	if not choices.is_empty():
		var texts: Array[String] = []
		for choice: Dictionary in choices:
			texts.append(_fill(str(choice.get("text", ""))))
		EventBus.dialogue_choices_shown.emit(texts)


func _apply_effects(node: Dictionary) -> void:
	if node.has("set_flag"):
		GameState.set_story_flag(StringName(node["set_flag"]))
	var relationship: Dictionary = node.get("relationship", {})
	for npc_name: String in relationship:
		GameState.change_relationship(npc_name, int(relationship[npc_name]))
	if node.has("notify"):
		EventBus.notification_requested.emit(str(node["notify"]))


## Replaces {player}, {buyback_price} and {days_remaining} in a line.
func _fill(text: String) -> String:
	return text.replace(PLAYER_TOKEN, _player_name()) \
		.replace("{buyback_price}", GameState.format_money(GameState.BUYBACK_PRICE)) \
		.replace("{days_remaining}", str(GameState.get_days_remaining()))


func _player_name() -> String:
	return GameState.player_name if GameState.player_name != "" else "You"


func _finish() -> void:
	var finished_id := _current_id
	_current_id = &""
	_graph = null
	_node_id = ""
	EventBus.dialogue_finished.emit(finished_id)
