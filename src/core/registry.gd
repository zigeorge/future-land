class_name Registry
## Looks up content resources by id.
##
## Convention: a resource's file name is its id, e.g. data/items/hoe.tres
## has id &"hoe". This lets saves and dialogue refer to content by id.

const ITEMS_DIR := "res://data/items/"
const CROPS_DIR := "res://data/crops/"
const AVATARS_DIR := "res://data/avatars/"
const PORTRAITS_DIR := "res://assets/art/portraits/"
const NPC_NAMES_PATH := "res://data/npcs.json"

static var _npc_names: Dictionary = {}

## Order shown on the avatar selection screen.
const AVATAR_IDS: Array[StringName] = [&"avatar_1", &"avatar_2", &"avatar_3", &"avatar_4"]


static func get_item(id: StringName) -> ItemData:
	return _load(ITEMS_DIR, id) as ItemData


static func get_crop(id: StringName) -> CropData:
	return _load(CROPS_DIR, id) as CropData


static func get_avatar(id: StringName) -> AvatarData:
	return _load(AVATARS_DIR, id) as AvatarData


## Name players see for an NPC role ("Village Chief" -> "Arthur"), from
## data/npcs.json. Unknown roles are shown as they are.
static func get_npc_name(role: String) -> String:
	if _npc_names.is_empty() and FileAccess.file_exists(NPC_NAMES_PATH):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(NPC_NAMES_PATH))
		if data is Dictionary:
			_npc_names = data.get("names", {})
	return str(_npc_names.get(role, role))


## Portrait for a file name or a speaker name, e.g. "Village Chief" ->
## assets/art/portraits/village_chief.png. Null if there is none (yet).
static func get_portrait(name: String) -> Texture2D:
	var file := name.to_lower().replace(" ", "_")
	var path := PORTRAITS_DIR + file + ".png"
	return load(path) if ResourceLoader.exists(path) else null



static func _load(dir: String, id: StringName) -> Resource:
	var path := dir + String(id) + ".tres"
	if id == &"" or not ResourceLoader.exists(path):
		push_error("Registry: no resource with id '%s' at %s" % [id, path])
		return null
	return load(path)
