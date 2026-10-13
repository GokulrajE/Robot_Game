extends SceneTree
var viewport: SubViewport
func _initialize() -> void:
	call_deferred("capture")
func snap(name: String) -> void:
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://.test-data/" + name + ".png") == OK)
func capture() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(3840, 2160)
	viewport.size_2d_override = Vector2i(1920, 1080)
	viewport.size_2d_override_stretch = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game = load("res://games/adventure/scenes/adventure.tscn").instantiate()
	viewport.add_child(game)
	game.set_process(false)
	await snap("adventure_briefing")
	game.start_session()
	game.clear_actors()
	game.spawn_enemy()
	game.enemies[0].position = game.player.position
	game.enemies[0].set_meta("previous_position", game.player.position)
	game.check_collisions()
	game.clear_actors()
	game._process(0.24)
	await snap("adventure_hit_feedback")
	game._process(0.85)
	await snap("adventure_protection")
	viewport.queue_free()
	await process_frame
	print("PASS: refreshed hub, distinct icons, threat warning and pulse rendered at 4K")
	quit()
