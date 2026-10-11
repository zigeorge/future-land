extends Node
## Persistent player and world state that must survive level changes.
##
## Levels and UI are views: they read from here and listen to EventBus for
## changes. Anything that must be saved lives here (or in TimeManager).

const STARTING_MONEY := 500
const MAX_ENERGY := 270
const INVENTORY_SIZE := 30
const HOTBAR_SIZE := 10

## Story: the land must be bought back within one in-game year
## (docs/Future_Land_NPC_Dialogue.xlsx, sheet "Game Variables").
const DEADLINE_DAYS := 4 * 28
const BUYBACK_PRICE := 100000

const STARTING_ITEMS := {
	&"hoe": 1,
	&"watering_can": 1,
	&"carrot_seeds": 15,
}

var money := STARTING_MONEY:
	set(value):
		money = maxi(value, 0)
		EventBus.money_changed.emit(money)

var energy := MAX_ENERGY:
	set(value):
		energy = clampi(value, 0, MAX_ENERGY)
		EventBus.energy_changed.emit(energy, MAX_ENERGY)

var selected_hotbar_slot := 0:
	set(value):
		selected_hotbar_slot = posmod(value, HOTBAR_SIZE)
		EventBus.hotbar_selection_changed.emit(selected_hotbar_slot)

## Chosen on the avatar selection screen (data/avatars/<id>.tres). Empty = not chosen yet.
var avatar_id: StringName = &"":
	set(value):
		avatar_id = value
		EventBus.avatar_changed.emit(avatar_id)

var inventory := Inventory.new(INVENTORY_SIZE)
var farm := FarmState.new()
## Story progress, set from dialogue files or gameplay (e.g. &"met_mayor": true).
var story_flags: Dictionary = {}
## NPC name -> friendship points, changed by dialogue.
var relationships: Dictionary = {}


func _ready() -> void:
	inventory.changed.connect(EventBus.inventory_changed.emit)
	farm.cell_changed.connect(EventBus.farm_changed.emit)
	EventBus.day_started.connect(_on_day_started)
	new_game()


func new_game() -> void:
	money = STARTING_MONEY
	energy = MAX_ENERGY
	story_flags.clear()
	relationships.clear()
	avatar_id = &""
	farm.clear()
	inventory.clear()
	for item_id: StringName in STARTING_ITEMS:
		inventory.add_item(Registry.get_item(item_id), STARTING_ITEMS[item_id])
	selected_hotbar_slot = 0


func get_selected_item() -> ItemData:
	return inventory.get_item_at(selected_hotbar_slot)


## Returns false (and spends nothing) if the player is too tired.
func spend_energy(amount: int) -> bool:
	if energy < amount:
		return false
	energy -= amount
	return true


func set_story_flag(flag: StringName, value: Variant = true) -> void:
	story_flags[flag] = value
	EventBus.story_flag_changed.emit(flag, value)


func has_story_flag(flag: StringName) -> bool:
	return bool(story_flags.get(flag, false))


func change_relationship(npc_name: String, amount: int) -> void:
	relationships[npc_name] = int(relationships.get(npc_name, 0)) + amount


func get_days_remaining() -> int:
	return maxi(DEADLINE_DAYS - TimeManager.get_day_number() + 1, 0)


func _on_day_started(_day: int, season: int, _year: int) -> void:
	energy = MAX_ENERGY
	farm.advance_day(season)


func get_save_data() -> Dictionary:
	return {
		"money": money,
		"energy": energy,
		"selected_hotbar_slot": selected_hotbar_slot,
		"inventory": inventory.to_data(),
		"farm": farm.to_data(),
		"story_flags": story_flags,
		"relationships": relationships,
		"avatar_id": String(avatar_id),
	}


func load_save_data(data: Dictionary) -> void:
	money = int(data.get("money", STARTING_MONEY))
	energy = int(data.get("energy", MAX_ENERGY))
	selected_hotbar_slot = int(data.get("selected_hotbar_slot", 0))
	inventory.from_data(data.get("inventory", []))
	farm.from_data(data.get("farm", {}))
	story_flags = data.get("story_flags", {})
	relationships = data.get("relationships", {})
	avatar_id = StringName(data.get("avatar_id", ""))
