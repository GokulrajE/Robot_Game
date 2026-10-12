extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	game = load("res://cognitive_hub.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	# Headless tests run many actions in one frame; keep audio resources checked, but skip mixing.
	for sound in game.find_children("*Sound", "AudioStreamPlayer", true, false):
		assert(sound.stream != null)
		sound.stream = null
	game.start_session()
	game.on_tile(0)
	var mismatch := 1
	while game.cards[mismatch] == game.cards[0]: mismatch += 1
	game.on_tile(mismatch)
	assert(game.phase == "hide_cards" and game.score == 0)
	game.toggle_pause()
	game._process(5)
	assert(game.selected.size() == 2)
	game.toggle_pause()
	game._process(2)
	assert(game.selected.is_empty())
	for level in range(3):
		game.difficulty = level
		game.mode = 0
		game.start_session()
		game.toggle_pause()
		var before = game.elapsed
		game._process(5.0)
		game.on_tile(0)
		assert(game.elapsed == before and game.selected.is_empty())
		game.toggle_pause()
		for value in range(game.cards.size() / 2):
			for index in range(game.cards.size()):
				if game.cards[index] == value: game.on_tile(index)
		assert(game.state == "finished")
		assert(game.score == game.cards.size() / 2 * 100)
	game.mode = 1
	game.start_session()
	while game.phase != "": game.advance_phase()
	game.on_tile((game.sequence[0] + 1) % 6)
	assert(game.phase == "repeat_sequence" and game.score == 0)
	while game.state == "playing":
		while game.phase != "": game.advance_phase()
		var sequence = game.sequence.duplicate()
		for index in sequence: game.on_tile(index)
	assert(game.score > 0)
	game.mode = 2
	game.start_session()
	var target_index = game.cards.find(game.target)
	game.on_tile(target_index)
	assert(game.score == 50)
	game.toggle_pause()
	var remaining = game.remaining
	game._process(20)
	assert(game.remaining == remaining)
	game.toggle_pause()
	game._process(100)
	assert(game.state == "finished")
	game.start_session()
	assert(game.score == 0 and game.attempts == 0)
	game.finish(false)
	assert(game.state == "finished")
	game.queue_free()
	await process_frame
	print("PASS: all game modes, difficulty, scoring, pause/resume, timeout, stop and replay")
	await create_timer(0.15).timeout
	quit()
