extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	seed(403)
	game = load("res://games/ocean_rescue/scenes/ocean_rescue.tscn").instantiate()
	game.auto_fullscreen = false
	root.add_child(game)
	game.set_process(false)
	assert(game.state == "ready")
	for level in range(3):
		game.level = level
		game.start_session()
		assert(game.get_node("%Buoys").get_child_count() == 2 + level * 2)
		assert(game.get_node("%Litter").get_child_count() == 6)
		assert(game.remaining == game.DURATIONS[level])
		for item in game.get_node("%Litter").get_children():
			for buoy in game.get_node("%Buoys").get_children():
				assert(item.position.distance_to(buoy.position) >= 2.5)
	game.level = 0
	game.start_session()
	game.clear_children(game.get_node("%Buoys"))
	var camera = game.get_node("%Camera")
	var screen = camera.unproject_position(Vector3(5,0,3))
	assert(game.set_target(screen))
	game.move_boat(0.2)
	assert(game.get_node("%Boat").position.length() > 0.5)
	assert(game.get_node("%Boat/Wake").visible)
	game.reset_input()
	var item = game.get_node("%Litter").get_child(0)
	item.position = game.get_node("%Boat").position
	game.check_pickups()
	assert(game.collected == 1 and game.score == 100)
	game.check_pickups()
	assert(game.collected == 1, "A floating pickup cannot score twice")
	game._process(0.2)
	assert(not game.pending.is_empty())
	var before = item.position
	var reef = game.get_node("%ReefLife")
	var reef_before = reef.get_node("AnimationPlayer").current_animation_position
	var fish_before = reef.get_node("Schools/School0Fish0").position
	var grass_before = reef.get_node("Seagrass/Clump0/Blade0").mesh.material.get_shader_parameter("game_time")
	var water_before = game.get_node("%Water").mesh.material.get_shader_parameter("game_time")
	var time_before = game.remaining
	game.toggle_pause()
	game._process(5)
	assert(game.remaining == time_before and item.position == before)
	assert(reef.get_node("AnimationPlayer").current_animation_position == reef_before)
	assert(reef.get_node("Schools/School0Fish0").position == fish_before)
	assert(reef.get_node("Seagrass/Clump0/Blade0").mesh.material.get_shader_parameter("game_time") == grass_before)
	assert(game.get_node("%Water").mesh.material.get_shader_parameter("game_time") == water_before)
	assert(not game.set_target(screen))
	game.toggle_pause()
	game._process(0.6)
	assert(game.pending.is_empty())
	assert(reef.get_node("Schools/School0Fish0").position != fish_before)
	assert(game.get_node("%Boat/Model/Cargo0").visible)
	assert(not game.has_node("World/Dolphin"))
	assert(reef.get_node("Schools").get_child_count() == 10)
	# Decorative fish must remain submerged and must never change the score.
	var score_before = game.score
	for second in range(49):
		reef.get_node("AnimationPlayer").seek(second, true)
		for fish in reef.get_node("Schools").get_children():
			assert(fish.position.y < -0.5 and absf(fish.position.x) < 11)
	assert(game.score == score_before)
	game.start_session()
	assert(reef.get_node("AnimationPlayer").current_animation_position == 0)
	# Swept movement stops before a buoy, including a long frame.
	game.get_node("%Boat").position = Vector3.ZERO
	var buoy = game.BUOY.instantiate()
	buoy.position = Vector3(0,0,3)
	game.get_node("%Buoys").add_child(buoy)
	game.target = Vector3(0,0,8)
	game.moving = true
	game.move_boat(2)
	assert(game.get_node("%Boat").position == Vector3.ZERO and not game.moving)
	game.clear_children(game.get_node("%Buoys"))
	# Complete each level, checking replay and next-level state.
	for level in range(3):
		game.level = level
		game.start_session()
		while game.collected < game.GOALS[level]:
			var candidate = null
			for litter in game.get_node("%Litter").get_children():
				if not litter.get_meta("collected", false):
					candidate = litter
					break
			assert(candidate != null)
			candidate.position = game.get_node("%Boat").position
			game.check_pickups()
			game.advance_pickups(0.8)
		assert(game.score == game.GOALS[level] * 100)
		assert(game.celebration > 0)
		game._process(2.6)
		assert(game.state == "finished" and game.completed)
		assert(game.get_node("%Next").visible == (level < 2))
		assert(game.best[str(level)] >= game.score)
		if level < 2:
			game.get_node("%Next").pressed.emit()
			assert(game.level == level + 1 and game.collected == 0)
	game.start_session()
	assert(game.score == 0 and not game.get_node("%Boat/Model/Cargo0").visible)
	game.remaining = 0.01
	game._process(0.02)
	assert(game.state == "finished" and not game.completed)
	game.start_session()
	game.get_node("%Stop").pressed.emit()
	assert(game.state == "finished")
	game.prepare()
	assert(game.state == "ready" and game.pending.is_empty())
	game.start_session()
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(game.state == "paused")
	game.queue_free()
	await process_frame
	await process_frame
	print("PASS: ocean levels, safe spawns, mouse steering, exact-once pickup, basket, paused fish/seagrass/water, buoy collision, wins, persistence, replay, timeout and focus pause")
	await create_timer(0.2).timeout
	quit()
