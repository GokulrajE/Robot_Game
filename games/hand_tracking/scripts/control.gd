extends Node2D

func _ready():
	var gender_btn = $GenderOption as OptionButton
	gender_btn.add_item("Male", 0)
	gender_btn.add_item("Female", 1)
	gender_btn.add_item("Other", 2)
	gender_btn.selected = 0
	$ErrorLabel.visible = false
	$SubmitButton.pressed.connect(_on_submit_pressed)

func _on_submit_pressed():
	var id: String    = ($IDField as LineEdit).text.strip_edges()
	var stroke: String = ($StrokeTimeField as LineEdit).text.strip_edges()

	if id == "" or stroke == "":
		$ErrorLabel.text    = "Please fill in all fields."
		$ErrorLabel.visible = true
		return

	var gender_btn = $GenderOption as OptionButton
	Global.player_id         = id
	Global.player_gender     = gender_btn.get_item_text(gender_btn.selected)
	Global.player_stroketime = stroke
	Global.skip_practice     = true

	get_tree().change_scene_to_file("res://games/hand_tracking/scenes/sitar_game.tscn")
