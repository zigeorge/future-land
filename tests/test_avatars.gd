extends TestCase


func test_every_avatar_builds_all_animations() -> void:
	for id in Registry.AVATAR_IDS:
		var avatar := Registry.get_avatar(id)
		assert_true(avatar != null, "missing data/avatars/%s.tres" % id)
		if avatar == null:
			continue
		assert_eq(avatar.id, id, "id must match the file name")
		assert_eq(avatar.sheet.get_size(), Vector2(80, 128), "%s sheet size" % id)
		var frames := avatar.build_sprite_frames()
		for direction in AvatarData.DIRECTIONS:
			assert_eq(frames.get_frame_count("idle_" + direction), 1, "%s idle_%s" % [id, direction])
			assert_eq(frames.get_frame_count("walk_" + direction), 4, "%s walk_%s" % [id, direction])


func test_mirrored_direction_reuses_a_row() -> void:
	var avatar := AvatarData.new()
	avatar.row_left = 2
	avatar.row_right = 2
	avatar.mirror_right = true
	assert_eq(avatar.get_row("right"), 2)
	assert_true(avatar.is_mirrored("right"))
	assert_false(avatar.is_mirrored("left"))
