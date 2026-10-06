class_name Registry
## Looks up content resources by id.
##
## Convention: a resource's file name is its id, e.g. data/items/hoe.tres
## has id &"hoe". This lets saves and dialogue refer to content by id.

const ITEMS_DIR := "res://data/items/"
const CROPS_DIR := "res://data/crops/"


static func get_item(id: StringName) -> ItemData:
	return _load(ITEMS_DIR, id) as ItemData


static func get_crop(id: StringName) -> CropData:
	return _load(CROPS_DIR, id) as CropData


static func _load(dir: String, id: StringName) -> Resource:
	var path := dir + String(id) + ".tres"
	if id == &"" or not ResourceLoader.exists(path):
		push_error("Registry: no resource with id '%s' at %s" % [id, path])
		return null
	return load(path)
