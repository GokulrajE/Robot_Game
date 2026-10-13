extends SceneTree
func _initialize() -> void:
	call_deferred("run_tests")
func settle() -> void:
	await process_frame
	await process_frame
func run_tests() -> void:
	change_scene_to_file("res://scenes/ui/launcher.tscn")
	await settle()
	current_scene.get_node("%Credits").pressed.emit()
	assert(current_scene.get_node("%CreditsPanel").visible)
	current_scene.get_node("%CloseCredits").pressed.emit()
	assert(not current_scene.get_node("%CreditsPanel").visible)
	current_scene.get_node("%Garden").pressed.emit()
	await settle()
	assert(current_scene.name == "CognitiveGarden")
	current_scene.get_node("%GameSelect").item_selected.emit(2)
	assert(current_scene.mode == 2)
	current_scene.get_node("%Home").pressed.emit()
	await settle()
	current_scene.get_node("%Adventure").pressed.emit()
	await settle()
	assert(current_scene.name == "Adventure")
	current_scene.get_node("%Mode").item_selected.emit(1)
	assert(current_scene.mode == 1)
	current_scene.get_node("%Mute").button_pressed = true
	assert(AudioServer.is_bus_mute(0))
	current_scene.get_node("%Home").pressed.emit()
	await settle()
	assert(current_scene.get_node("%Mute").button_pressed)
	current_scene.get_node("%Ocean").pressed.emit()
	await settle()
	assert(current_scene.name == "OceanRescue")
	current_scene.get_node("%Home").pressed.emit()
	await settle()
	assert(current_scene.has_node("%Ocean"))
	print("PASS: launcher, credits, both section routes, game selectors and shared mute")
	quit()
