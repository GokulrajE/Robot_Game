extends SceneTree
## Offscreen native 4K verification avoids changing the user's desktop resolution.
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
	var game = load("res://scenes/adventure.tscn").instantiate()
	viewport.add_child(game)
	game.start_session()
	game.set_process(false)
	# Put hero at the far edge to check HUD occlusion at the tightest visible position.
	game.player.position = Vector3(0, 0, -5.6)
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var camera := viewport.get_camera_3d()
	var far_head := camera.unproject_position(Vector3(0, 2.5, -5.6))
	var near_feet := camera.unproject_position(Vector3(0, 0, 5.6))
	assert(far_head.y > 120, "Far-edge hero must remain below the HUD")
	assert(near_feet.y < 950, "Near-edge hero must remain above pulse controls")
	game.player.position = Vector3.ZERO
	await process_frame
	await RenderingServer.frame_post_draw
	game.clear_effects()
	game.crystals[0].position = game.player.position
	game.check_collisions()
	game.advance_effects(0.3)
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	assert(picture.get_size() == Vector2i(3840, 2160))
	assert(picture.save_png("res://.test-data/crystal_pickup_4k.png") == OK)
	print("PASS: native 3840x2160 render, 1920x1080 logical UI, MSAA 4x, 3D meshes and camera")
	game.clear_effects()
	game.notify_pulse_ready()
	game.advance_effects(0.35)
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.test-data/pulse_ready_4k.png")
	viewport.queue_free()
	await process_frame
	quit()

