extends TestCase


func test_npc_roles_have_names() -> void:
	var expected := {"Government Official": "Alexander", "Village Chief": "Arthur", "Merchant": "Marcus",
		"Technological Inventor": "Ethan", "Fisherman": "Jack"}
	for role: String in expected:
		assert_eq(Registry.get_npc_name(role), expected[role])
	assert_eq(Registry.get_npc_name("Someone New"), "Someone New", "unknown roles stay as they are")


func test_money_formatting() -> void:
	var game_state := load("res://src/autoload/game_state.gd")
	assert_eq(game_state.format_money(100000), "100,000")
	assert_eq(game_state.format_money(500), "500")
