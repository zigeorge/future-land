extends TestCase

const DIALOGUE_DIR := "res://data/dialogue/"


func test_every_dialogue_file_is_valid() -> void:
	var files := DirAccess.get_files_at(DIALOGUE_DIR)
	assert_true(files.size() > 0, "no dialogue files found")
	for file in files:
		if file.ends_with(".json"):
			var problems := DialogueGraph.load_file(DIALOGUE_DIR + file).validate()
			assert_true(problems.is_empty(), "%s: %s" % [file, problems])


func test_npc_dialogue_ids_exist() -> void:
	# Ids used by the NPCs in the farm and village scenes.
	for id in ["land_requisition_notice", "inventor_visit", "inventor_repeat", "village_introduction",
			"chief_repeat", "merchant_introduction", "merchant_repeat", "farming_tips"]:
		assert_true(FileAccess.file_exists(DIALOGUE_DIR + id + ".json"), "missing %s.json" % id)


func test_lines_format_becomes_a_chain() -> void:
	var graph := DialogueGraph.from_data({"lines": [{"text": "a"}, {"text": "b"}]})
	assert_eq(graph.start, "0")
	assert_eq(graph.get_node_data("0")["next"], "1")
	assert_eq(graph.get_node_data("1")["next"], DialogueGraph.END)


func test_validate_reports_missing_targets_and_loops() -> void:
	var dangling := DialogueGraph.from_data({"start": "A", "nodes": {"A": {"text": "x", "next": "B"}}})
	assert_false(dangling.validate().is_empty(), "missing node B")
	var loop := DialogueGraph.from_data({"start": "A", "nodes": {
		"A": {"text": "x", "next": "B"}, "B": {"text": "y", "next": "A"}}})
	assert_false(loop.validate().is_empty(), "A -> B -> A never ends")


func test_story_intro_sets_main_quest_flags() -> void:
	var graph := DialogueGraph.load_file(DIALOGUE_DIR + "land_requisition_notice.json")
	var flags := []
	for node: Dictionary in graph.nodes.values():
		if node.has("set_flag"):
			flags.append(node["set_flag"])
	for flag in ["land_notice_received", "buyback_goal_unlocked", "main_quest_started"]:
		assert_true(flag in flags, "intro should set %s" % flag)
