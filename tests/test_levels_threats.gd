extends SceneTree
func _initialize() -> void:
	call_deferred("run_tests")
func quiet(game) -> void:
	game.auto_fullscreen = false
	root.add_child(game)
	game.set_process(false)
	for sound in game.find_children("*Sound", "AudioStreamPlayer", true, false): sound.stream = null
func run_tests() -> void:
	var garden = load("res://games/cognitive/scenes/cognitive_hub.tscn").instantiate()
	quiet(garden)
	for level in range(3):
		garden.mode = 2
		garden.difficulty = level
		garden.start_session()
		assert(garden.buttons.size() == [6, 9, 12][level])
		for match_index in range(garden.focus_goal()):
			garden.on_tile(garden.cards.find(garden.target))
			if garden.state == "playing": garden.advance_phase()
		assert(garden.completed_level and garden.score == garden.focus_goal() * 50)
		assert(garden.get_node("%NextLevel").visible == (level < 2))
	garden.mode = 0
	garden.difficulty = 1
	garden.start_session()
	garden._process(181)
	assert(garden.state == "finished" and not garden.completed_level)
	garden.mode = 2
	garden.difficulty = 2
	garden.start_session()
	var before = garden.remaining
	var wrong := 0
	while garden.cards[wrong] == garden.target: wrong += 1
	garden.on_tile(wrong)
	assert(garden.remaining == before - 3)
	garden.queue_free()
	await process_frame
	var game = load("res://games/adventure/scenes/adventure.tscn").instantiate()
	quiet(game)
	for level in range(3):
		game.level = level
		game.start_session()
		assert(game.enemies.size() == 3 + level)
		assert(game.seed_goal() == [10, 14, 18][level])
	game.level = 2
	game.start_session()
	game.clear_actors()
	game.spawn_enemy()
	var enemy = game.enemies[0]
	enemy.position = Vector3(0, 0, -4)
	enemy.set_meta("role", 0)
	enemy.set_meta("clock", 0.0)
	game.move_enemies(0.01)
	assert(enemy.get_meta("attack") == "windup")
	assert(enemy.get_node("ChargeWarning").visible)
	var location: Vector3 = enemy.position
	game.toggle_pause()
	game._process(2)
	assert(enemy.position == location and enemy.get_meta("attack") == "windup")
	game.toggle_pause()
	game.move_enemies(0.7)
	assert(enemy.get_meta("attack") == "dash")
	game.move_enemies(0.6)
	game.check_collisions()
	assert(game.hearts == 2, "Fast attacks use swept collision and cannot tunnel through Nova")
	game.cooldown = 0
	enemy.position = game.player.position + Vector3(1, 0, 0)
	game.send_pulse()
	assert(game.enemies.is_empty())
	var burst = game.get_node("%Effects").get_child(game.get_node("%Effects").get_child_count() - 1)
	assert(burst.has_node("Wave0") and burst.has_node("Wave1"))
	game.advance_effects(0.2)
	var radius: float = burst.get_node("Wave0").scale.x
	game.toggle_pause()
	game._process(1)
	assert(burst.get_node("Wave0").scale.x == radius)
	game.toggle_pause()
	game.level = 0
	game.start_session()
	game.collected = game.seed_goal() - 1
	game.crystals[0].position = game.player.position
	game.check_collisions()
	game._process(1)
	assert(game.completed_level and game.get_node("%NextLevel").visible)
	game.get_node("%NextLevel").pressed.emit()
	assert(game.level == 1 and game.state == "playing" and game.score == 0)
	game.queue_free()
	await process_frame
	print("PASS: level goals, cognitive timeout/penalty, harder populations, charge warning, pause, swept damage, pulse cancellation and next level")
	quit()
