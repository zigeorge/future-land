class_name Registry
## Looks up content resources by id.
##
## Convention: a resource's file name is its id, e.g. data/items/hoe.tres
## has id &"hoe". This lets saves and dialogue refer to content by id.

const ITEMS_DIR := "res://data/items/"
const CROPS_DIR := "res://data/crops/"
const AVATARS_DIR := "res://data/avatars/"
const PORTRAITS_DIR := "res://assets/art/portraits/"

## Order shown on the avatar selection screen.
const AVATAR_IDS: Array[StringName] = [&"avatar_1", &"avatar_2", &"avatar_3", &"avatar_4"]


static func get_item(id: StringName) -> ItemData:
	return _load(ITEMS_DIR, id) as ItemData


static func get_crop(id: StringName) -> CropData:
	return _load(CROPS_DIR, id) as CropData


static func get_avatar(id: StringName) -> AvatarData:
	return _load(AVATARS_DIR, id) as AvatarData


## Portrait for an avatar id or a speaker name, e.g. "Village Chief" ->
## assets/art/portraits/village_chief.png. Null if there is none (yet).
static func get_portrait(name: String) -> Texture2D:
	var file := name.to_snake_case().replace(" ", "_")
	var path := PORTRAITS_DIR + file + ".png"
	return load(path) if ResourceLoader.exists(path) else null



static func _load(dir: String, id: StringName) -> Resource:
	var path := dir + String(id) + ".tres"
	if id == &"" or not ResourceLoader.exists(path):
		push_error("Registry: no resource with id '%s' at %s" % [id, path])
		return null
	return load(path)
