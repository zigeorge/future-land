extends TestCase


func test_stages_follow_days_per_stage() -> void:
	var crop := CropData.new()
	crop.days_per_stage = [1, 2]
	assert_eq(crop.get_total_days(), 3)
	assert_eq(crop.get_stage(0), 0)
	assert_eq(crop.get_stage(1), 1)
	assert_eq(crop.get_stage(2), 1)
	assert_eq(crop.get_stage(3), 2, "final stage = ready")
	assert_true(crop.is_ready(3))


func test_seasons_flags() -> void:
	var crop := CropData.new()
	crop.seasons = 0b0101  # Spring + Autumn
	assert_true(crop.grows_in(0))
	assert_false(crop.grows_in(1))
	assert_true(crop.grows_in(2))


func test_carrot_has_a_texture_per_stage() -> void:
	var crop := Registry.get_crop(&"carrot")
	assert_eq(crop.stage_textures.size(), crop.days_per_stage.size() + 1, "growing stages + ripe")
	for texture in crop.stage_textures:
		assert_eq(texture.get_size(), Vector2(16, 16))
