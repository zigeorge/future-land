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
	assert_eq(crop.get_stage_count(), crop.days_per_stage.size() + 1, "growing stages + ripe")
	for stage in crop.get_stage_count():
		var texture := crop.get_stage_texture(stage)
		assert_eq(texture.get_width(), texture.get_height(), "stage %d is square" % stage)


func test_stage_strip_splits_at_any_resolution() -> void:
	for side in [16, 128]:
		var crop := CropData.new()
		crop.stage_strip = ImageTexture.create_from_image(Image.create(side * 4, side, false, Image.FORMAT_RGBA8))
		assert_eq(crop.get_stage_count(), 4)
		assert_eq((crop.get_stage_texture(2) as AtlasTexture).region, Rect2(side * 2, 0, side, side))
