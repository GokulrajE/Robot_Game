extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	game = load("res://scenes/adventure.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	# Headless tests run many actions in one frame; keep audio resources checked, but skip mixing.
	for sound in game.find_children("*Sound", "AudioStreamPlayer", true, false):
		assert(sound.stream != null)
		sound.stream = null
	assert(game.state == "ready")
	game.get_node("%Start").pressed.emit()
	assert(game.state == "playing" and game.enemies.size() == 3 and game.crystals.size() == 3)
	assert(game.set_mouse_target(game.get_viewport().get_camera_3d().unproject_position(Vector3(11, 0, 0))))
	var position = game.player.position
	game.move_player(0.1)
	assert(game.player.position.x > position.x)
	game.reset_input()
	game.crystals[0].position = game.player.position
	game.check_collisions()
	assert(game.collected == 1 and game.score == 100)
	game.enemies[0].position = game.player.position + Vector3(1.25, 0, 0)
	var count = game.enemies.size()
	game.get_node("%Pulse").pressed.emit()
	assert(game.enemies.size() < count and game.cooldown == 3)
	var score = game.score
	game.send_pulse()
	assert(game.score == score)
	game.get_node("%Pause").pressed.emit()
	var time = game.remaining
	position = game.player.position
	var enemy_position = game.enemies[0].position
	game._process(5)
	assert(game.remaining == time and game.player.position == position and game.enemies[0].position == enemy_position)
	game.get_node("%Resume").pressed.emit()
	assert(game.state == "playing")
	game.invincible = 0
	game.enemies[0].position = game.player.position
	game.check_collisions()
	assert(game.hearts == 2)
	game.check_collisions()
	assert(game.hearts == 2)
	game.hearts = 1
	game.invincible = 0
	game.check_collisions()
	assert(game.state == "finished")
	game.get_node("%Resume").pressed.emit()
	assert(game.state == "playing" and game.score == 0 and game.hearts == 3)
	for index in range(10):
		game.crystals[0].position = game.player.position
		game.check_collisions()
	assert(game.win_delay > 0 and game.collected == 10)
	game._process(1.0)
	assert(game.state == "finished" and game.collected == 10)
	game.mode = 1
	game.start_session()
	game.clear_actors()
	game.remaining = 0.01
	game._process(0.02)
	assert(game.state == "finished" and game.get_node("%ResultTitle").text == "Adventure complete!")
	game.start_session()
	game.get_node("%Stop").pressed.emit()
	assert(game.state == "finished")
	game.get_node("%Back").pressed.emit()
	assert(game.state == "ready" and game.enemies.is_empty())
	game.start_session()
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(game.state == "paused")
	game.get_node("%Back").pressed.emit()
	assert(game.state == "ready")
	var config := ConfigFile.new()
	assert(config.load("user://adventure_progress.cfg") == OK)
	assert(config.get_value("progress", "best").has("0"))
	game.queue_free()
	await process_frame
	await process_frame
	print("PASS: adventure controls, movement, collection, pulse/cooldown, pause freeze, damage/invincibility, defeat, win, timeout, replay, focus pause and persistence")
	await create_timer(0.15).timeout
	quit()
