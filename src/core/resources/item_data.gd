class_name ItemData
extends Resource
## Definition of an item type. One .tres file per item in data/items/.

enum Category { MISC, TOOL, SEED, CROP, FOOD, RESOURCE }
enum ToolType { NONE, HOE, WATERING_CAN, AXE, PICKAXE, SCYTHE }

## Must match the file name (data/items/<id>.tres).
@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var category := Category.MISC
@export_range(1, 999) var max_stack := 99
@export var sell_price := 0

@export_group("Tool")
@export var tool_type := ToolType.NONE
@export var energy_cost := 2

@export_group("Seed")
## Id of the crop this seed plants (data/crops/<crop_id>.tres).
@export var crop_id: StringName
