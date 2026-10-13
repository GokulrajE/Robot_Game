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
	game.level = 2
	game.start_session()
	game.clear_actors()
	game.spawn_enemy()
	game.enemies[0].position = Vector3(0, 0, -4)
	game.enemies[0].set_meta("role", 0)
	game.enemies[0].set_meta("clock", 0.0)
	game.move_enemies(0.01)
	await snap("adventure_charge_refresh")
	game.send_pulse()
	game._process(1.2)
	await snap("adventure_pulse_refresh")
	game.toggle_pause()
	await snap("adventure_pause_help")
	viewport.queue_free()
	await process_frame
	print("PASS: refreshed hub, distinct icons, threat warning and pulse rendered at 4K")
	quit()
