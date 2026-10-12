extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280, 900)
	for item in [["res://scenes/launcher.tscn", "launcher"], ["res://cognitive_hub.tscn", "garden"], ["res://scenes/adventure.tscn", "adventure"]]:
		var scene = load(item[0]).instantiate()
		root.add_child(scene)
		if item[1] == "adventure": scene.start_session()
		if item[1] == "garden":
			scene.difficulty = 2
			scene.prepare()
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.test-data/" + item[1] + ".png")
		root.remove_child(scene)
		scene.queue_free()
		await process_frame
	quit()
