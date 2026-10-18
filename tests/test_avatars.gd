extends TestCase


func test_every_avatar_builds_all_animations() -> void:
	for id in Registry.AVATAR_IDS:
		var avatar := Registry.get_avatar(id)
		assert_true(avatar != null, "missing data/avatars/%s.tres" % id)
		if avatar == null:
			continue
		assert_eq(avatar.id, id, "id must match the file name")
		var size := avatar.sheet.get_size()
		assert_true(int(size.x) % AvatarData.COLUMNS == 0 and int(size.y) % AvatarData.ROWS == 0, "%s sheet %s splits into 5x4 frames" % [id, size])
		assert_eq(Vector2(avatar.get_frame_size()).y, Vector2(avatar.get_frame_size()).x * 2, "%s frames are twice as tall as wide" % id)
		var frames := avatar.build_sprite_frames()
		for direction in AvatarData.DIRECTIONS:
			assert_eq(frames.get_frame_count("idle_" + direction), 1, "%s idle_%s" % [id, direction])
			assert_true(frames.get_frame_count("walk_" + direction) >= 2, "%s walk_%s" % [id, direction])


func test_mirrored_direction_reuses_a_row() -> void:
	var avatar := AvatarData.new()
	avatar.row_left = 2
	avatar.row_right = 2
	avatar.mirror_right = true
	assert_eq(avatar.get_row("right"), 2)
	assert_true(avatar.is_mirrored("right"))
	assert_false(avatar.is_mirrored("left"))


func test_rebuilt_front_walk_alternates_feet() -> void:
	var avatar := Registry.get_avatar(&"avatar_1").duplicate() as AvatarData
	avatar.auto_walk_cycle = true
	var frames := avatar.build_sprite_frames()
	assert_eq(frames.get_frame_count("walk_down"), 4)
	var step := frames.get_frame_texture("walk_down", 0).get_image()
	var other := frames.get_frame_texture("walk_down", 2).get_image()
	step.flip_x()
	assert_eq(step.get_data(), other.get_data(), "frame 3 is frame 1 mirrored")
