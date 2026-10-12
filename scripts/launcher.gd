extends Control

func _ready() -> void:
	%Garden.pressed.connect(func(): get_tree().change_scene_to_file("res://cognitive_hub.tscn"))
	%Adventure.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/adventure.tscn"))
	%Credits.pressed.connect(func(): %CreditsPanel.show(); %CloseCredits.grab_focus())
	%CloseCredits.pressed.connect(func(): %CreditsPanel.hide(); %Credits.grab_focus())
	%Mute.button_pressed = AudioServer.is_bus_mute(0)
	%Mute.toggled.connect(func(value: bool): AudioServer.set_bus_mute(0, value))
