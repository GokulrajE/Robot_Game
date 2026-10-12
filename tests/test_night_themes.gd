extends SceneTree
const THEMES = preload("res://scripts/night_themes.gd")
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	seed(314159)
	THEMES.last_session_theme = -1
	var previous := -1
	var visited := {}
	for scene_path in ["res://scenes/adventure.tscn", "res://cognitive_hub.tscn"]:
		var game = load(scene_path).instantiate()
		game.auto_fullscreen = false
		root.add_child(game)
		game.set_process(false)
		for sound in game.find_children("*Sound", "AudioStreamPlayer", true, false): sound.stream = null
		var themes = game.get_node("%NightThemes")
		assert(themes.theme_index == 0, "Setup previews option B")
		for session in range(12):
			game.start_session()
			if previous == -1: assert(themes.theme_index == 0)
			else: assert(themes.theme_index != previous)
			previous = themes.theme_index
			visited[previous] = true
			assert(themes.get_child_count() == 1)
			game.toggle_pause()
			game._process(2)
			assert(themes.theme_index == previous)
			game.toggle_pause()
			assert(themes.theme_index == previous)
		game.queue_free()
		await process_frame
	assert(visited.size() == 3)
	var prize = load("res://scenes/3d/crystal.tscn").instantiate()
	assert(prize.has_node("SoftGlow") and prize.has_node("GlowLight"))
	prize.free()
	print("PASS: option B first, three themes, no consecutive repeat across sections, pause stability, scene cleanup and glowing prizes")
	quit()
