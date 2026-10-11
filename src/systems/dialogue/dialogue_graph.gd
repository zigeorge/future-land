class_name DialogueGraph
extends RefCounted
## One conversation, loaded from data/dialogue/<id>.json.
##
## Two formats are accepted (see data/README.md):
## - Graph, generated from docs/Future_Land_NPC_Dialogue.xlsx:
##     {"start": "GOV_001", "nodes": {"GOV_001": {"speaker": "...", "text": "...", "next": "GOV_002"}}}
## - List, for short hand-written conversations:
##     {"lines": [{"speaker": "...", "text": "..."}]}
##
## Node fields: speaker, text, next (missing or "END" ends the conversation),
## choices [{text, next}], set_flag, relationship {npc name: amount}, notify.

const END := "END"

var start := ""
var nodes: Dictionary = {}
## Set when the data can't be used at all.
var error := ""


static func load_file(path: String) -> DialogueGraph:
	if not FileAccess.file_exists(path):
		var missing := DialogueGraph.new()
		missing.error = "file not found: %s" % path
		return missing
	return from_data(JSON.parse_string(FileAccess.get_file_as_string(path)))


static func from_data(data: Variant) -> DialogueGraph:
	var graph := DialogueGraph.new()
	if typeof(data) != TYPE_DICTIONARY:
		graph.error = "not a JSON object (check for a missing comma or quote)"
	elif data.has("lines"):
		var lines: Array = data["lines"]
		for i in lines.size():
			var node: Dictionary = (lines[i] as Dictionary).duplicate()
			node["next"] = str(i + 1) if i + 1 < lines.size() else END
			graph.nodes[str(i)] = node
		graph.start = "0"
	elif data.has("nodes"):
		graph.nodes = data["nodes"]
		graph.start = str(data.get("start", ""))
	else:
		graph.error = "needs a \"lines\" array or a \"nodes\" object"
	if graph.error == "" and not graph.nodes.has(graph.start):
		graph.error = "start node '%s' does not exist" % graph.start
	return graph


func get_node_data(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})


func get_choices(node_id: String) -> Array:
	return get_node_data(node_id).get("choices", [])


static func get_targets(node: Dictionary) -> Array[String]:
	var targets: Array[String] = []
	if node.has("choices"):
		for choice: Dictionary in node["choices"]:
			targets.append(str(choice.get("next", END)))
	else:
		targets.append(str(node.get("next", END)))
	return targets


## Problems that would break the conversation in game. Empty = fine.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if error != "":
		problems.append(error)
		return problems
	for node_id: String in nodes:
		for target in get_targets(nodes[node_id]):
			if target != END and not nodes.has(target):
				problems.append("%s points to missing node %s" % [node_id, target])
	# The conversation must be able to finish.
	var seen := {}
	var queue: Array[String] = [start]
	var can_end := false
	while not queue.is_empty():
		var node_id: String = queue.pop_back()
		if seen.has(node_id) or not nodes.has(node_id):
			continue
		seen[node_id] = true
		for target in get_targets(nodes[node_id]):
			if target == END:
				can_end = true
			else:
				queue.append(target)
	if not can_end:
		problems.append("no path from %s reaches the end (endless loop)" % start)
	return problems
