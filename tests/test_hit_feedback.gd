extends SceneTree
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	var game = load("res://games/adventure/scenes/adventure.tscn").instantiate()
	game.auto_fullscreen = false
	root.add_child(game)
	game.set_process(false)
	game.start_session()
	game.clear_actors()
	game.spawn_enemy()
	var drone = game.enemies[0]
	drone.position = game.player.position
	drone.set_meta("previous_position", drone.position)
	game.check_collisions()
	assert(game.hearts == 2)
	assert(game.player.get_node("Shield").visible)
	assert(game.get_node("%DamageCue").visible)
	game.check_collisions()
	assert(game.hearts == 2)
	game.clear_actors()
	game._process(0.15)
	assert(game.player.get_node("Model").rotation.x < -0.1)
	var heart = game.get_node("%Lives/Heart2/Fill")
	assert(heart.scale.x > 1.2)
	var tilt = game.player.get_node("Model").rotation.x
	game.toggle_pause()
	game._process(1)
	assert(game.player.get_node("Model").rotation.x == tilt)
	assert(is_equal_approx(game.invincible, 1.65))
	game.toggle_pause()
	game._process(0.9)
	assert(heart.modulate.a == 0)
	assert(game.player.get_node("HitFlash").mesh.material.albedo_color.a == 0)
	assert(not game.get_node("%DamageCue").visible)
	assert(game.get_node("%NovaPulse/Status").visible)
	assert(game.player.get_node("Shield").visible)
	game._process(0.8)
	assert(not game.player.get_node("Shield").visible)
	assert(game.player.get_node("Shield/Bubble").mesh.material.albedo_color.a == 0)
	game.start_session()
	assert(game.hearts == 3 and heart.modulate.a == 1 and heart.scale == Vector2.ONE)
	assert(game.player.get_node("Model").rotation.x == 0)
	game.queue_free()
	await process_frame
	await process_frame
	print("PASS: hit reaction, one-heart loss, immunity, shield expiry, pause freeze and replay reset")
	quit()
