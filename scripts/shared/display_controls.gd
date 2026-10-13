extends HBoxContainer
## Main-viewport rendering remains native resolution; quality only changes MSAA.
func _ready() -> void:
	$Quality.select(clampi(int(get_viewport().msaa_3d), 0, 2))
	$Quality.item_selected.connect(func(index: int): get_viewport().msaa_3d = index)
	$Fullscreen.pressed.connect(toggle_fullscreen)
	refresh_label()

func toggle_fullscreen() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	refresh_label()

func refresh_label() -> void:
	$Fullscreen.text = "Windowed / F11" if get_window().mode == Window.MODE_FULLSCREEN else "Fullscreen / F11"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
