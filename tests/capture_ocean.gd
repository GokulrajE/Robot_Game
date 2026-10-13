extends SceneTree
var viewport: SubViewport
func _initialize() -> void:
	call_deferred("capture")
func snap(name: String) -> void:
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://.test-data/" + name + ".png") == OK)
func capture() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(3840,2160)
	viewport.size_2d_override = Vector2i(1920,1080)
	viewport.size_2d_override_stretch = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game = load("res://games/ocean_rescue/scenes/ocean_rescue.tscn").instantiate()
	game.auto_fullscreen = false
	viewport.add_child(game)
	game.set_process(false)
	await snap("ocean_setup")
	game.start_session()
	game.target = Vector3(2,0,2)
	game.moving = true
	game._process(0.4)
	game._process(0.4)
	await snap("ocean_play")
	game.get_node("%Litter").get_child(0).position = game.get_node("%Boat").position
	game.check_pickups()
	game._process(0.25)
	await snap("ocean_collect")
	game.queue_free()
	await process_frame
	var library = load("res://scenes/ui/launcher.tscn").instantiate()
	viewport.add_child(library)
	await snap("library_with_ocean")
	library.queue_free()
	await process_frame
	viewport.queue_free()
	await process_frame
	print("PASS: Ocean Rescue setup and gameplay rendered at 4K")
	quit()
