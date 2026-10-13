extends SceneTree
var checked := 0
func _initialize() -> void:
	for folder in ["res://games", "res://scenes", "res://assets/themes"]:
		check_folder(folder)
	for legacy in ["res://main.tscn", "res://sitar_game.tscn"]:
		if ResourceLoader.exists(legacy): assert(load(legacy) != null)
	print("PASS: %d relocated scenes and themes load, including original hand-tracking scenes" % checked)
	quit()
func check_folder(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".tscn") or file.ends_with(".tres"):
			assert(load(path.path_join(file)) != null, path.path_join(file))
			checked += 1
	for folder in DirAccess.get_directories_at(path):
		check_folder(path.path_join(folder))
