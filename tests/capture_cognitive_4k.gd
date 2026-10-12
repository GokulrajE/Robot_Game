extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(3840, 2160)
	viewport.size_2d_override = Vector2i(1920, 1080)
	viewport.size_2d_override_stretch = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game = load("res://cognitive_hub.tscn").instantiate()
	viewport.add_child(game)
	game.set_process(false)
	for mode in range(3):
		game.mode = mode
		game.difficulty = 2
		game.start_session()
		if mode == 0:
			for tile in game.buttons: tile.reveal(true, false)
		elif mode == 1:
			game.advance_phase()
			game.buttons[game.sequence[0]].advance_animation(0.2)
		else:
			for tile in game.buttons: tile.advance_animation(0.5)
			game.get_node("%TargetIcon").advance_animation(0.5)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		var picture := viewport.get_texture().get_image()
		assert(picture.get_size() == Vector2i(3840, 2160))
		assert(picture.save_png("res://.test-data/cognitive_%d_4k.png" % mode) == OK)
	viewport.queue_free()
	await process_frame
	print("PASS: all three cognitive games rendered at native 4K")
	quit()
