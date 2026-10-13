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
	for section in ["adventure", "cognitive"]:
		var scene_path := "res://games/adventure/scenes/adventure.tscn" if section == "adventure" else "res://games/cognitive/scenes/cognitive_hub.tscn"
		var game = load(scene_path).instantiate()
		viewport.add_child(game)
		game.set_process(false)
		game.start_session()
		if section == "adventure":
			for i in range(3):
				game.enemies[i].position = [Vector3(-7, 0, -2), Vector3(8, 0, 4), Vector3(-8, 0, 6)][i]
				game.crystals[i].position = [Vector3(7, 0, -3), Vector3(-5, 0, 3), Vector3(3, 0, 7)][i]
		else:
			for tile in game.buttons: tile.reveal(true, false)
		for theme in range(3):
			game.get_node("%NightThemes").show_theme(theme)
			for frame in range(8): await process_frame
			await RenderingServer.frame_post_draw
			var picture := viewport.get_texture().get_image()
			assert(picture.save_png("res://.test-data/%s_night_%d.png" % [section, theme]) == OK)
		viewport.remove_child(game)
		game.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	print("PASS: six native 4K night-theme previews")
	quit()
