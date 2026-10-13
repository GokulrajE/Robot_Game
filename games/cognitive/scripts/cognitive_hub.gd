extends Control
## All delayed gameplay advances through _process, so pause freezes every phase.
const TILE = preload("res://games/cognitive/scenes/3d/cognitive_tile.tscn")
const NAMES = ["Memory Meadow", "Melody Steps", "Focus Finder"]
const DESCRIPTIONS = ["Uncover the clouds and pair the matching objects.", "Watch the objects bounce, then repeat their order.", "Find the object that matches the floating example."]
@export var auto_fullscreen := true
var mode := 0
var difficulty := 0
var state := "ready"
var score := 0
var attempts := 0
var correct := 0
var elapsed := 0.0
var remaining := 60.0
var stage := 1
var phase := ""
var delay := 0.0
var cards: Array = []
var selected: Array = []
var matched: Array = []
var sequence: Array = []
var sequence_index := 0
var playback := 0
var target := 0
var buttons: Array[Node3D] = []
var best: Dictionary = {}
var reduced_motion := false
var completed_level := false
func focus_goal() -> int:
	return [5, 8, 12][difficulty]
@onready var board: Node3D = %Board
@onready var title_label: Label = %Title
@onready var hint: Label = %Hint
@onready var stats: Label = %Stats
@onready var status_label: Label = %Status
@onready var pause_button: Button = %Pause
@onready var start_button: Button = %Start
@onready var stop_button: Button = %Stop
@onready var selector: OptionButton = %GameSelect
@onready var level_selector: OptionButton = %Difficulty
@onready var progress: ProgressBar = %Progress
@onready var overlay: Panel = %Overlay
@onready var overlay_title: Label = %OverlayTitle
@onready var overlay_text: Label = %OverlayText
@onready var overlay_action: Button = %OverlayAction

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://cognitive_progress.cfg") == OK:
		best = config.get_value("progress", "best", {})
	start_button.pressed.connect(start_session)
	pause_button.pressed.connect(toggle_pause)
	stop_button.pressed.connect(func(): finish(false))
	selector.item_selected.connect(func(index: int): mode = index; prepare())
	level_selector.item_selected.connect(func(index: int): difficulty = index; prepare())
	%NextLevel.pressed.connect(func(): difficulty = mini(2, difficulty + 1); start_session())
	%MemoryCard.pressed.connect(func(): mode = 0; prepare())
	%MelodyCard.pressed.connect(func(): mode = 1; prepare())
	%FocusCard.pressed.connect(func(): mode = 2; prepare())
	%Motion.toggled.connect(func(value: bool): reduced_motion = value)
	%Mute.toggled.connect(func(value: bool): AudioServer.set_bus_mute(0, value))
	%Mute.button_pressed = AudioServer.is_bus_mute(0)
	%Home.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/launcher.tscn"))
	%Resources.pressed.connect(func(): OS.shell_open("https://www.nia.nih.gov/health/brain-health/cognitive-health-and-older-adults"))
	overlay_action.pressed.connect(func():
		if state == "paused": toggle_pause()
		else: start_session())
	%Back.pressed.connect(func():
		if state == "paused": finish(false)
		prepare())
	prepare()

func prepare() -> void:
	difficulty = clampi(difficulty, 0, 2)
	completed_level = false
	selector.select(mode)
	level_selector.select(difficulty)
	state = "ready"
	overlay.hide()
	score = 0
	attempts = 0
	correct = 0
	elapsed = 0
	remaining = [90.0, 60.0, 45.0][difficulty]
	if mode == 0: remaining = [0.0, 180.0, 120.0][difficulty]
	stage = 1
	delay = 0.0
	phase = ""
	title_label.text = NAMES[mode]
	hint.text = DESCRIPTIONS[mode]
	%LevelDetails.text = (["4 pairs • no time limit • long reveal", "6 pairs • 180 seconds • shorter reveal", "8 pairs • 120 seconds • brief reveal"][difficulty] if mode == 0 else
		["4-step sequence • slow playback", "6-step sequence • medium playback", "8-step sequence • fast playback"][difficulty] if mode == 1 else
		"%d matches • %d choices • %ds%s" % [focus_goal(), [6, 9, 12][difficulty], int(remaining), " • errors cost 3s" if difficulty == 2 else ""])
	status_label.text = "Choose your pace, then press Start session."
	make_board()
	update_hud()

func make_board() -> void:
	for child in board.get_children():
		board.remove_child(child)
		child.queue_free()
	buttons.clear()
	cards.clear()
	selected.clear()
	matched.clear()
	var count := 6
	var columns := 3
	if mode == 0:
		count = [8, 12, 16][difficulty]
		columns = 4
		for index in range(count): cards.append(floori(index / 2.0))
		cards.shuffle()
	elif mode == 2:
		count = [6, 9, 12][difficulty]
		columns = 3 if count < 12 else 4
	var rows := ceili(float(count) / columns)
	for index in range(count):
		var tile: Node3D = TILE.instantiate()
		board.add_child(tile)
		tile.reduced_motion = reduced_motion
		tile.position = Vector3((index % columns - (columns - 1) * 0.5) * 2.65, 0,
			(floori(float(index) / columns) - (rows - 1) * 0.5) * 2.65 + 0.8)
		tile.set_icon(int(cards[index]) if mode == 0 else index % 6)
		tile.reveal(mode != 0, false)
		buttons.append(tile)
	%TargetIcon.visible = false
	%TargetIcon.reduced_motion = reduced_motion

func _unhandled_input(event: InputEvent) -> void:
	if state != "playing": return
	var point: Vector2
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	else: return
	var camera := get_viewport().get_camera_3d()
	var ray_origin := camera.project_ray_origin(point)
	var ray_direction := camera.project_ray_normal(point)
	var closest := INF
	var chosen := -1
	for index in range(buttons.size()):
		# Select the entire object and its pedestal, including raised icon geometry.
		var tile := buttons[index]
		var box := AABB(tile.global_position + Vector3(-1.08, 0, -1.08), Vector3(2.16, 2.1, 2.16))
		var hit = box.intersects_ray(ray_origin, ray_direction)
		if hit != null and ray_origin.distance_to(hit) < closest:
			closest = ray_origin.distance_to(hit)
			chosen = index
	if chosen >= 0:
		on_tile(chosen)
		get_viewport().set_input_as_handled()

func start_session() -> void:
	prepare()
	%NightThemes.begin_session()
	state = "playing"
	if auto_fullscreen and DisplayServer.get_name() != "headless" and get_viewport() == get_window():
		get_window().mode = Window.MODE_FULLSCREEN
	%ClickSound.play()
	if mode == 1:
		sequence.clear()
		next_sequence()
	elif mode == 2:
		next_focus()
	else:
		status_label.text = "Find a pair"
	update_hud()

func toggle_pause() -> void:
	if state == "playing":
		state = "paused"
		overlay_title.text = "Take a breath"
		overlay_text.text = "Your session is paused.\nContinue whenever you feel ready."
		overlay_action.text = "Resume session"
		overlay.show()
	elif state == "paused":
		state = "playing"
		overlay.hide()
	update_hud()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state in ["playing", "paused"]:
		toggle_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing": toggle_pause()

func _process(delta: float) -> void:
	if state != "playing": return
	for tile in buttons: tile.advance_animation(delta)
	%TargetIcon.advance_animation(delta)
	elapsed += delta
	if mode == 2 or (mode == 0 and difficulty > 0):
		remaining = maxf(0, remaining - delta)
		if remaining <= 0:
			finish(false)
			return
	if delay > 0:
		delay -= delta
		if delay <= 0: advance_phase()
	update_hud()

func on_tile(index: int) -> void:
	if state != "playing" or phase != "": return
	%ClickSound.play()
	if mode == 0:
		if index in matched or index in selected: return
		selected.append(index)
		buttons[index].reveal(true, not reduced_motion)
		if selected.size() == 2:
			attempts += 1
			if cards[selected[0]] == cards[selected[1]]:
				correct += 1
				score += 100
				%SuccessSound.play()
				matched.append_array(selected)
				for item in selected:
					buttons[item].mark_matched()
				selected.clear()
				status_label.text = "Lovely match! +100"
				if matched.size() == cards.size(): finish(true)
			else:
				status_label.text = "Try again — remember these two."
				phase = "hide_cards"
				delay = [1.3, 0.9, 0.6][difficulty]
	elif mode == 1:
		attempts += 1
		pop(buttons[index])
		if index == sequence[sequence_index]:
			correct += 1
			score += 25
			sequence_index += 1
			if sequence_index == sequence.size():
				score += 100
				%SuccessSound.play()
				if stage == [4, 6, 8][difficulty]: finish(true)
				else:
					stage += 1
					status_label.text = "Sequence complete! +100"
					phase = "next_sequence"
					delay = 1.0
		else:
			status_label.text = "Let's watch that sequence once more."
			phase = "repeat_sequence"
			delay = [1.3, 0.9, 0.6][difficulty]
	else:
		attempts += 1
		if cards[index] == target:
			correct += 1
			score += 50
			%SuccessSound.play()
			status_label.text = "You found it! +50"
			pop(buttons[index])
			if correct >= focus_goal():
				finish(true)
				return
			phase = "next_focus"
			delay = 0.3
		else:
			status_label.text = "Try another object"
			if difficulty == 2: remaining = maxf(0, remaining - 3.0)
	update_hud()

func next_sequence() -> void:
	sequence.append(randi_range(0, 5))
	begin_playback()

func begin_playback() -> void:
	sequence_index = 0
	playback = 0
	status_label.text = "Watch • Round %d" % stage
	phase = "flash"
	delay = 0.6

func advance_phase() -> void:
	match phase:
		"hide_cards":
			for index in selected: buttons[index].reveal(false, not reduced_motion)
			selected.clear()
			phase = ""
		"next_sequence": next_sequence()
		"repeat_sequence": begin_playback()
		"flash":
			buttons[sequence[playback]].highlight(true)
			%ClickSound.pitch_scale = 0.85 + float(sequence[playback]) * 0.12
			%ClickSound.play()
			phase = "unflash"
			delay = [0.85, 0.65, 0.45][difficulty]
		"unflash":
			buttons[sequence[playback]].highlight(false)
			playback += 1
			if playback == sequence.size():
				phase = ""
				status_label.text = "Your turn • %d objects" % sequence.size()
			else:
				phase = "flash"
				delay = 0.3
		"next_focus": next_focus()

func next_focus() -> void:
	phase = ""
	var icon_count := 8 if difficulty > 0 else 6
	target = randi_range(0, icon_count - 1)
	cards.clear()
	var target_slot := randi_range(0, buttons.size() - 1)
	for index in range(buttons.size()):
		var symbol := target if index == target_slot else (target + randi_range(1, icon_count - 1)) % icon_count
		cards.append(symbol)
		buttons[index].set_icon(symbol)
		buttons[index].reveal(true, not reduced_motion)
	%TargetIcon.set_icon(target)
	%TargetIcon.reveal(true, not reduced_motion)
	%TargetIcon.show()
	status_label.text = "Find this object"

func pop(item: Node3D) -> void:
	if reduced_motion: return
	item.animate("bounce")

func update_hud() -> void:
	%NextLevel.visible = state == "finished" and completed_level and difficulty < 2
	%LevelHUD.text = "LEVEL %d / 3" % (difficulty + 1)
	stats.text = "%04d   •   %ds" % [score, ceili(remaining) if mode == 2 or (mode == 0 and difficulty > 0) else int(elapsed)]
	%Setup.visible = state == "ready"
	%HUD.visible = state == "playing"
	board.visible = state != "ready"
	%TargetIcon.visible = mode == 2 and state == "playing"
	progress.value = (100.0 * matched.size() / maxi(1, cards.size())) if mode == 0 else (100.0 * (stage - 1) / [4, 6, 8][difficulty] if mode == 1 else 100.0 * correct / focus_goal())
	var active := state in ["playing", "paused"]
	selector.disabled = active
	level_selector.disabled = active
	start_button.disabled = active
	pause_button.disabled = not active
	stop_button.disabled = not active
	for index in range(buttons.size()):
		buttons[index].disabled = state != "playing" or phase != "" or index in matched

func finish(completed: bool) -> void:
	if state not in ["playing", "paused"]: return
	state = "finished"
	completed_level = completed
	phase = ""
	var key := "%d_%d" % [mode, difficulty]
	best[key] = maxi(score, int(best.get(key, 0)))
	var config := ConfigFile.new()
	config.set_value("progress", "best", best)
	var saved := config.save("user://cognitive_progress.cfg") == OK
	overlay_title.text = "Level %d complete!" % (difficulty + 1) if completed else ("Time is up" if remaining <= 0 and (mode == 2 or difficulty > 0) else "Session stopped")
	overlay_text.text = "%s\n\n%d points  •  %d seconds\n%d correct / %d attempts\n\n%s" % [NAMES[mode], score, int(elapsed), correct, attempts, "Your best score is saved. Keep growing at your own pace." if saved else "Could not save progress on this device."]
	overlay_action.text = "Play again"
	overlay.show()
	update_hud()
