extends SceneTree
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	var game = load("res://cognitive_hub.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.auto_fullscreen = false
	for sound in game.find_children("*Sound", "AudioStreamPlayer", true, false): sound.stream = null
	await process_frame
	game.difficulty = 2
	game.start_session()
	assert(game.buttons.size() == 16)
	var ids := {}
	for tile in game.buttons:
		assert(tile is Node3D)
		assert(tile.get_node("Pivot/Icon").get_child_count() == 1)
		ids[tile.icon_id] = true
	assert(ids.size() == 8, "Every memory pair has a distinct object")
	var tile: Node3D = game.buttons[0]
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = root.get_camera_3d().unproject_position(tile.global_position + Vector3(0, 0.8, 0))
	root.push_input(event, true)
	assert(game.selected == [0], "Click the visible 3D object")
	game._process(0.15)
	assert(tile.get_node("Pivot/Icon").visible)
	var before: Vector3 = tile.get_node("Pivot").scale
	game.toggle_pause()
	game._process(5)
	assert(tile.get_node("Pivot").scale == before)
	game.toggle_pause()
	game._process(0.3)
	assert(tile.get_node("Pivot").scale.is_equal_approx(Vector3.ONE))
	game.mode = 1
	game.start_session()
	game.advance_phase()
	assert(game.buttons[game.sequence[0]].get_node("Halo").visible)
	game.mode = 2
	game.start_session()
	assert(game.get_node("%TargetIcon").icon_id == game.target)
	assert(game.cards.count(game.target) == 1)
	game.reduced_motion = true
	game.start_session()
	game.on_tile(game.cards.find(game.target))
	assert(not game.buttons[game.cards.find(game.target)].get_node("AnimationPlayer").is_playing())
	game.queue_free()
	await process_frame
	print("PASS: eight unique 3D icons, object picking, reveal animation, pause freeze, sequence halo, target display and reduced motion")
	quit()
