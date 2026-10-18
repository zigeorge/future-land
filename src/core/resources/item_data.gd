class_name ItemData
extends Resource
## Definition of an item type. One .tres file per item in data/items/,
## generated from docs/Future_Land_Item_List.xlsx by tools/items_from_xlsx.py.

enum Category { MISC, TOOL, SEED, CROP, FOOD, RESOURCE, FISH }
enum ToolType { NONE, HOE, WATERING_CAN, AXE, PICKAXE, SCYTHE }

## Must match the file name (data/items/<id>.tres).
@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var category := Category.MISC
@export_range(1, 999) var max_stack := 99
@export_range(1, 4) var level := 1

@export_group("Trade")
## Price in a shop; 0 = not sold.
@export var buy_price := 0
## What a shop pays for one.
@export var sell_price := 0
## Which shop sells it: merchant, inventor or fisherman (empty = none).
@export var shop: StringName

@export_group("Tool")
@export var tool_type := ToolType.NONE
@export var energy_cost := 2

@export_group("Seed")
## Id of the crop this seed plants (data/crops/<crop_id>.tres).
@export var crop_id: StringName

@export_group("Fish")
## Seasons when it can be caught.
@export_flags("Spring", "Summer", "Autumn", "Winter") var seasons := 0
## Chance to catch it with a suitable tool, 0.0 - 1.0.
@export_range(0.0, 1.0) var catch_chance := 0.0
