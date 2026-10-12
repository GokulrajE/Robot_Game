extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1920, 1080)
	for item in [["res://scenes/launcher.tscn", "launcher_3d"], ["res://cognitive_hub.tscn", "garden_hd"], ["res://scenes/adventure.tscn", "adventure_3d"]]:
		var scene = load(item[0]).instantiate()
		root.add_child(scene)
		if item[1] == "adventure_3d":
			scene.start_session()
			scene.set_process(false)
		if item[1] == "garden_hd":
			scene.difficulty = 2
			scene.prepare()
		for frame in range(15): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.test-data/" + item[1] + ".png")
		root.remove_child(scene)
		scene.queue_free()
		await process_frame
	quit()
