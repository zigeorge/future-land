class_name Objectives
## The player's current goal, from data/objectives.json.

const PATH := "res://data/objectives.json"

static var _list: Array = []


## Current objective as a Dictionary (text, map, target), or {} when none.
static func current() -> Dictionary:
	if _list.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_list = data.get("objectives", []) if data is Dictionary else []
	for objective: Dictionary in _list:
		var required := str(objective.get("requires_flag", ""))
		if required != "" and not GameState.has_story_flag(StringName(required)):
			continue
		if not GameState.has_story_flag(StringName(str(objective.get("done_flag", "")))):
			return objective
	return {}


static func current_text() -> String:
	return str(current().get("text", "")).replace("{buyback_price}", GameState.format_money(GameState.BUYBACK_PRICE))


## World position the arrow should point to in `level`, or null: the target
## itself when it's in this map, else the exit leading to its map.
static func target_position(level: Node) -> Variant:
	var objective := current()
	var target := str(objective.get("target", ""))
	var map := str(objective.get("map", ""))
	if target == "" or level == null:
		return null
	if level.scene_file_path.get_file().get_basename() == map:
		for node in level.find_children("*", "", true, false):
			if node is NPC and node.npc_name == target and node.is_present():
				return node.global_position
			if node.name == target and node is Node2D:
				var farm := node as FarmGrid
				if farm:
					return farm.to_global(Vector2(farm.area.get_center()) * FarmGrid.CELL_SIZE)
				return (node as Node2D).global_position
		return null
	for warp in level.find_children("*", "LevelWarp", true, false):
		if (warp as LevelWarp).target_level.get_file().get_basename() == map:
			return (warp as Node2D).global_position
	return null
