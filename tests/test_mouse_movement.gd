extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run_tests")
func click_at(position: Vector2, button := MOUSE_BUTTON_LEFT, double := false) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = button
	event.pressed = true
	event.double_click = double
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
func run_tests() -> void:
	game = load("res://scenes/adventure.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for sound in game.find_children("*Sound", "AudioStreamPlayer", true, false): sound.stream = null
	await process_frame
	await process_frame
	game.start_session()
	var camera := root.get_camera_3d()
	click_at(camera.unproject_position(Vector3(4, 0, 2)))
	assert(game.has_move_target)
	assert(game.move_target.distance_to(Vector3(4, 0, 2)) < 0.01)
	game.move_player(100)
	assert(game.player.position.distance_to(Vector3(4, 0, 2)) < 0.01)
	assert(not game.has_move_target and not game.get_node("%MoveMarker").visible)
	var drag := InputEventMouseMotion.new()
	drag.position = camera.unproject_position(Vector3(-3, 0, 1))
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(drag, true)
	assert(game.has_move_target and game.move_target.distance_to(Vector3(-3, 0, 1)) < 0.01)
	game.reset_input()
	# Essential HUD buttons consume input rather than move Nova.
	click_at(Vector2(1770, 65))
	assert(not game.has_move_target)
	click_at(camera.unproject_position(Vector3(4, 0, 2)), MOUSE_BUTTON_RIGHT)
	assert(game.cooldown == 0 and not game.has_move_target)
	click_at(camera.unproject_position(Vector3(4, 0, 2)), MOUSE_BUTTON_LEFT, true)
	assert(game.cooldown > 0)
	game.cooldown = 0
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = camera.unproject_position(Vector3(-4, 0, 2))
	touch.double_tap = true
	root.push_input(touch, true)
	assert(game.cooldown > 0 and game.move_target.distance_to(Vector3(-4, 0, 2)) < 0.01)
	assert(game.set_mouse_target(camera.unproject_position(Vector3(13.8, 0, 9.8))))
	assert(is_equal_approx(game.move_target.x, game.BOUNDS.end.x))
	assert(is_equal_approx(game.move_target.z, game.BOUNDS.end.y))
	game.toggle_pause()
	assert(not game.has_move_target)
	assert(not game.set_mouse_target(camera.unproject_position(Vector3.ZERO)))
	game.toggle_pause()
	assert(not game.has_move_target)
	assert(not game.set_mouse_target(camera.unproject_position(Vector3(30, 0, 20))))
	game.queue_free()
	await process_frame
	print("PASS: click/drag movement, double-click and touch pulse, right-click inactive, UI interception, expanded bounds and pause reset")
	quit()
