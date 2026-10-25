extends Node
## Persistent player and world state that must survive level changes.
##
## Levels and UI are views: they read from here and listen to EventBus for
## changes. Anything that must be saved lives here (or in TimeManager).

const STARTING_MONEY := 500
const MAX_ENERGY := 270
## Backpack: 8 columns x 5 rows; the first row is the hotbar.
const INVENTORY_SIZE := 40
const HOTBAR_SIZE := 8

## Story: the land must be bought back within one in-game year
## (docs/Future_Land_NPC_Dialogue.xlsx, sheet "Game Variables").
const DEADLINE_DAYS := 365  # one year, TimeManager.DAYS_PER_YEAR
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

## Typed on the avatar selection screen; shown in dialogue for the player's lines.
var player_name := ""
## Chosen on the avatar selection screen (data/avatars/<id>.tres). Empty = not chosen yet.
var avatar_id: StringName = &"":
	set(value):
		avatar_id = value
		EventBus.avatar_changed.emit(avatar_id)

var inventory := Inventory.new(INVENTORY_SIZE)
var farm := FarmState.new()
## Story progress, set from dialogue files or gameplay (e.g. &"met_mayor": true).
var story_flags: Dictionary = {}
## Shipping bin: items put in today, sold overnight at full price.
## Array of {"id": String, "count": int}.
var shipping: Array = []
## Money the bin earned last night (shown in the morning).
var last_shipping_income := 0
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
	shipping.clear()
	last_shipping_income = 0
	player_name = ""
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
	var first_time := not story_flags.has(flag)
	story_flags[flag] = value
	if first_time:
		_give_rewards(flag)
	EventBus.story_flag_changed.emit(flag, value)


## data/rewards.json: items given once when a flag is first set.
func _give_rewards(flag: StringName) -> void:
	if not FileAccess.file_exists("res://data/rewards.json"):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rewards.json"))
	if not data is Dictionary:
		return
	for reward: Dictionary in data.get("rewards", {}).get(String(flag), []):
		var item := Registry.get_item(StringName(reward.get("item", "")))
		if item:
			inventory.add_item(item, int(reward.get("count", 1)))
			EventBus.notification_requested.emit("You received: %s" % item.display_name)


## Beach finds already picked up today: "map:index" strings.
var forage_taken: Array = []


func has_story_flag(flag: StringName) -> bool:
	return bool(story_flags.get(flag, false))


func change_relationship(npc_name: String, amount: int) -> void:
	relationships[npc_name] = int(relationships.get(npc_name, 0)) + amount


## Pays for the land (once). Returns false if there isn't enough money.
func pay_buyback() -> bool:
	if has_story_flag(&"land_repurchase_paid"):
		return true
	if money < BUYBACK_PRICE:
		return false
	money -= BUYBACK_PRICE
	set_story_flag(&"land_repurchase_paid")
	return true


## True on the morning after the last day of the story year.
func is_deadline_reached() -> bool:
	return get_days_remaining() <= 0 and has_story_flag(&"main_quest_started") \
		and not has_story_flag(&"ending_complete")


## 100000 -> "100,000".
static func format_money(amount: int) -> String:
	var digits := str(absi(amount))
	var result := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return ("-" if amount < 0 else "") + result


## Moves `amount` from an inventory slot into the shipping bin.
func ship_from_slot(index: int, amount: int) -> bool:
	var item := inventory.get_item_at(index)
	if item == null or item.sell_price <= 0:
		return false
	amount = mini(amount, inventory.slots[index].count)
	if not inventory.remove_from_slot(index, amount):
		return false
	for entry: Dictionary in shipping:
		if entry["id"] == String(item.id):
			entry["count"] = int(entry["count"]) + amount
			EventBus.shipping_changed.emit()
			return true
	shipping.append({"id": String(item.id), "count": amount})
	if not has_story_flag(&"first_shipment"):
		set_story_flag(&"first_shipment")
	EventBus.shipping_changed.emit()
	return true


func shipping_value() -> int:
	var total := 0
	for entry: Dictionary in shipping:
		var item := Registry.get_item(StringName(entry["id"]))
		if item:
			total += item.sell_price * int(entry["count"])
	return total


## Overnight: everything in the bin is sold at full price.
func _sell_shipping() -> void:
	last_shipping_income = shipping_value()
	shipping.clear()
	if last_shipping_income > 0:
		money += last_shipping_income
	EventBus.shipping_changed.emit()


func get_days_remaining() -> int:
	return maxi(DEADLINE_DAYS - TimeManager.get_day_number() + 1, 0)


func _on_day_started(_day: int, season: int, _year: int) -> void:
	_sell_shipping()
	forage_taken.clear()
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
		"shipping": shipping,
		"forage_taken": forage_taken,
		"avatar_id": String(avatar_id),
		"player_name": player_name,
	}


func load_save_data(data: Dictionary) -> void:
	money = int(data.get("money", STARTING_MONEY))
	energy = int(data.get("energy", MAX_ENERGY))
	selected_hotbar_slot = int(data.get("selected_hotbar_slot", 0))
	inventory.from_data(data.get("inventory", []))
	farm.from_data(data.get("farm", {}))
	story_flags = data.get("story_flags", {})
	relationships = data.get("relationships", {})
	shipping = data.get("shipping", [])
	forage_taken = data.get("forage_taken", [])
	player_name = str(data.get("player_name", ""))
	avatar_id = StringName(data.get("avatar_id", ""))
