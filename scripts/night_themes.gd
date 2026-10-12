extends Node3D
## Selection only. All environment geometry and materials live in the theme scenes.
const THEMES = [
	preload("res://scenes/3d/themes/starlight.tscn"),
	preload("res://scenes/3d/themes/moonlit.tscn"),
	preload("res://scenes/3d/themes/lunar.tscn")]
const NAMES = ["Starlight Courtyard", "Moonlit Robo Garden", "Lunar Greenhouse"]
static var last_session_theme := -1
var theme_index := -1

func _ready() -> void:
	show_theme(0)

func begin_session() -> void:
	# B opens the first game; subsequent games cannot repeat the previous theme.
	var next := 0
	if last_session_theme >= 0:
		next = (last_session_theme + randi_range(1, THEMES.size() - 1)) % THEMES.size()
	last_session_theme = next
	show_theme(next)

func show_theme(index: int) -> void:
	index = clampi(index, 0, THEMES.size() - 1)
	if theme_index == index: return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	theme_index = index
	add_child(THEMES[index].instantiate())
