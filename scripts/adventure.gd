extends Control
## Session state, input, movement and collision rules. All presentation is in scenes.
const ENEMY = preload("res://scenes/3d/enemy.tscn")
const COLLECT_EFFECT = preload("res://scenes/3d/collect_effect.tscn")
const READY_EFFECT = preload("res://scenes/3d/ready_effect.tscn")
@export var auto_fullscreen := true
var win_delay := 0.0
var ready_notifications := 0
const CRYSTAL = preload("res://scenes/3d/crystal.tscn")
const BOUNDS := Rect2(-13.2, -5.6, 26.4, 14.8)
const PLAYER_SPEED := 5.8
const PULSE_RADIUS := 3.0
var mode := 0
var state := "ready"
var score := 0
var hearts := 3
var collected := 0
var elapsed := 0.0
var remaining := 60.0
var invincible := 0.0
var cooldown := 0.0
var pulse_time := 0.0
var spawn_time := 0.0
var enemies: Array[Node3D] = []
var crystals: Array[Node3D] = []
var move_target := Vector3.ZERO
var has_move_target := false
var best: Dictionary = {}
@onready var player: Node3D = %Player

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://adventure_progress.cfg") == OK:
		best = config.get_value("progress", "best", {})
	%Start.pressed.connect(start_session)
	%Pause.pressed.connect(toggle_pause)
	%Stop.pressed.connect(func(): finish("Session stopped"))
	%Pulse.pressed.connect(send_pulse)
	%Resume.pressed.connect(func():
		if state == "paused": toggle_pause()
		else: start_session())
	%Back.pressed.connect(func():
		if state == "paused": finish("Session stopped")
		prepare())
	%Home.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/launcher.tscn"))
	%Mode.item_selected.connect(func(index: int): mode = index; prepare())
	%Mute.button_pressed = AudioServer.is_bus_mute(0)
	%Mute.toggled.connect(func(value: bool): AudioServer.set_bus_mute(0, value))
	prepare()

func clear_actors() -> void:
	for actor in %Actors.get_children():
		%Actors.remove_child(actor)
		actor.queue_free()
	enemies.clear()
	crystals.clear()

func prepare() -> void:
	%Mode.select(mode)
	state = "ready"
	clear_actors()
	%Overlay.hide()
	clear_effects()
	win_delay = 0.0
	ready_notifications = 0
	%ScoreAnimation.stop()
	%Score.scale = Vector2.ONE
	%Score.modulate = Color.WHITE
	%PulseAnimation.play("pulse_cooling")
	%PulseAnimation.advance(0)
	score = 0
	hearts = 3
	collected = 0
	elapsed = 0
	remaining = 75.0 if mode == 0 else 60.0
	invincible = 0
	cooldown = 0
	pulse_time = 0
	spawn_time = 2.5
	player.position = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.face(Vector3.ZERO)
	player.set_protected(false)
	%PulseRing.hide()
	reset_input()
	%Title.text = "Seed Quest" if mode == 0 else "Sentinel Dash"
	%Instructions.text = "Collect 10 golden seeds. Click or drag to move. Double-tap to pulse." if mode == 0 else "Survive 60 seconds. Click or drag to move. Double-tap to pulse."
	set_animation_active(false)
	update_hud()

func start_session() -> void:
	prepare()
	%NightThemes.begin_session()
	if auto_fullscreen and DisplayServer.get_name() != "headless" and get_viewport() == get_window():
		get_window().mode = Window.MODE_FULLSCREEN
	state = "playing"
	for index in range(3): spawn_enemy()
	for index in range(3): spawn_crystal()
	set_animation_active(true)
	%ClickSound.play()
	notify_pulse_ready()
	update_hud()

func safe_position(from_player: float, others: Array = []) -> Vector3:
	for attempt in range(100):
		var point := Vector3(randf_range(-12.2, 12.2), 0, randf_range(-5.2, 8.2))
		if point.distance_to(player.position) < from_player: continue
		var available := true
		for other in others:
			if point.distance_to(other.position) < 1.5: available = false
		if available: return point
	return Vector3(-10, 0, -5) if player.position.x > 0 else Vector3(10, 0, 5)

func spawn_enemy() -> void:
	var enemy: Node3D = ENEMY.instantiate()
	enemy.position = safe_position(5.75, enemies)
	%Actors.add_child(enemy)
	enemies.append(enemy)

func spawn_crystal() -> void:
	var crystal: Node3D = CRYSTAL.instantiate()
	crystal.position = safe_position(1.8, crystals)
	%Actors.add_child(crystal)
	crystals.append(crystal)

func _process(delta: float) -> void:
	if state != "playing": return
	advance_effects(delta)
	if win_delay > 0:
		win_delay = maxf(0, win_delay - delta)
		if win_delay <= 0: finish("All seeds collected!")
		return
	elapsed += delta
	remaining = maxf(0, remaining - delta)
	invincible = maxf(0, invincible - delta)
	var previous_cooldown := cooldown
	cooldown = maxf(0, cooldown - delta)
	if previous_cooldown > 0 and cooldown <= 0: notify_pulse_ready()
	pulse_time = maxf(0, pulse_time - delta)
	%PulseRing.visible = pulse_time > 0
	%PulseRing.position = player.position + Vector3(0, 0.12, 0)
	%PulseRing.scale = Vector3.ONE * (1.0 - pulse_time * 0.6)
	player.set_protected(invincible > 0)
	move_player(delta)
	move_enemies(delta)
	check_collisions()
	if state != "playing": return
	spawn_time -= delta
	if spawn_time <= 0:
		spawn_time = 4.0 if mode == 0 else 2.5
		if enemies.size() < (5 if mode == 0 else 9): spawn_enemy()
	if remaining <= 0:
		finish("Adventure complete!" if mode == 1 else "Time’s up — try another adventure")
	update_hud()

func ground_point(screen_position: Vector2) -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return null
	var point = Plane(Vector3.UP, 0.0).intersects_ray(
		camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))
	if not get_viewport_rect().has_point(screen_position): return null
	if point == null or absf(point.x) > 15.0 or absf(point.z) > 13.0: return null
	return point

func set_mouse_target(screen_position: Vector2) -> bool:
	if state != "playing" or win_delay > 0: return false
	var point = ground_point(screen_position)
	if point == null: return false
	move_target = Vector3(clampf(point.x, BOUNDS.position.x, BOUNDS.end.x),
		0, clampf(point.z, BOUNDS.position.y, BOUNDS.end.y))
	has_move_target = true
	%MoveMarker.position = move_target + Vector3(0, 0.1, 0)
	%MoveMarker.show()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if state != "playing": return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and set_mouse_target(event.position):
			if event.double_click: send_pulse()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if set_mouse_target(event.position): get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		if set_mouse_target(event.position):
			if event.double_tap: send_pulse()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if set_mouse_target(event.position): get_viewport().set_input_as_handled()

func move_player(delta: float) -> void:
	if state != "playing" or not has_move_target: return
	var direction := move_target - player.position
	player.position = player.position.move_toward(move_target, PLAYER_SPEED * delta)
	if player.position.distance_to(move_target) < 0.01:
		reset_input()
	else:
		player.face(direction.normalized())

func move_enemies(delta: float) -> void:
	for index in range(enemies.size()):
		var enemy := enemies[index]
		var direction: Vector3 = (player.position - enemy.position).normalized()
		# Alternating creatures weave as they pursue, keeping paths readable.
		if index % 2 == 1: direction = direction.rotated(Vector3.UP, sin(elapsed * 2.0 + index) * 0.65)
		enemy.position += direction * (1.6 + minf(elapsed, 60.0) * 0.015) * delta
		enemy.position.x = clampf(enemy.position.x, BOUNDS.position.x, BOUNDS.end.x)
		enemy.position.z = clampf(enemy.position.z, BOUNDS.position.y, BOUNDS.end.y)
		enemy.face(direction)

func check_collisions() -> void:
	if state != "playing" or win_delay > 0: return
	for crystal in crystals.duplicate():
		if crystal.position.distance_to(player.position) < 0.75:
			spawn_effect(COLLECT_EFFECT, crystal.position)
			crystals.erase(crystal)
			crystal.queue_free()
			collected += 1
			add_points(100)
			%CollectSound.play()
			if mode == 0 and collected >= 10:
				win_delay = 0.9
				reset_input()
				set_animation_active(false)
				return
			spawn_crystal()
	if invincible > 0: return
	for enemy in enemies:
		if enemy.position.distance_to(player.position) < 0.8:
			hearts -= 1
			invincible = 1.8
			%HurtSound.play()
			if hearts <= 0: finish("A brave adventure!")
			break

func send_pulse() -> void:
	if state != "playing" or cooldown > 0 or win_delay > 0: return
	cooldown = 3.0
	%PulseAnimation.play("pulse_cooling")
	%PulseAnimation.advance(0)
	pulse_time = 0.45
	%PulseSound.play()
	var hits := 0
	for enemy in enemies.duplicate():
		if enemy.position.distance_to(player.position) <= PULSE_RADIUS:
			enemies.erase(enemy)
			enemy.queue_free()
			hits += 1
	add_points(hits * 50)
	update_hud()

func add_points(amount: int) -> void:
	if amount <= 0: return
	score += amount
	%Score.text = "%04d" % score
	%ScoreAnimation.stop()
	%ScoreAnimation.play("score_pop")
	%ScoreAnimation.advance(0)

func spawn_effect(scene: PackedScene, location: Vector3) -> void:
	var effect := scene.instantiate() as Node3D
	effect.position = location
	%Effects.add_child(effect)

func clear_effects() -> void:
	for effect in %Effects.get_children():
		%Effects.remove_child(effect)
		effect.queue_free()

func advance_effects(delta: float) -> void:
	for effect in %Effects.get_children():
		if not effect.is_queued_for_deletion(): effect.advance_effect(delta)
	%ScoreAnimation.advance(delta)
	%PulseAnimation.advance(delta)

func notify_pulse_ready() -> void:
	ready_notifications += 1
	spawn_effect(READY_EFFECT, player.position)
	%ReadySound.play()
	%PulseAnimation.play("pulse_ready")
	%PulseAnimation.advance(0)

func reset_input() -> void:
	has_move_target = false
	move_target = player.position
	%MoveMarker.hide()
	player.face(Vector3.ZERO)

func set_animation_active(active: bool) -> void:
	player.set_animation_active(active)
	for actor in %Actors.get_children(): actor.set_animation_active(active)

func toggle_pause() -> void:
	if state == "playing":
		state = "paused"
		reset_input()
		set_animation_active(false)
		%ResultTitle.text = "Take a breath"
		%ResultText.text = "%d points  •  %ds remaining" % [score, ceili(remaining)]
		%Resume.text = "Resume adventure"
		%Overlay.show()
		%Resume.grab_focus()
	elif state == "paused":
		state = "playing"
		set_animation_active(true)
		%Overlay.hide()
	update_hud()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state in ["playing", "paused"]:
		toggle_pause()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if state != "playing": return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		send_pulse()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing": toggle_pause()

func finish(message: String) -> void:
	if state not in ["playing", "paused"]: return
	state = "finished"
	reset_input()
	set_animation_active(false)
	best[str(mode)] = maxi(score, int(best.get(str(mode), 0)))
	var config := ConfigFile.new()
	config.set_value("progress", "best", best)
	var saved := config.save("user://adventure_progress.cfg") == OK
	%ResultTitle.text = message
	%ResultText.text = "%d points  •  %d seeds  •  %d seconds\nPersonal best: %d\n\n%s" % [score, collected, int(elapsed), best[str(mode)], "Your best score is saved. Ready for another try?" if saved else "Progress could not be saved on this device."]
	%Resume.text = "Play again"
	%Overlay.show()
	%Resume.grab_focus()
	update_hud()

func update_hud() -> void:
	%Setup.visible = state == "ready"
	%HUD.visible = state == "playing"
	%Score.text = "%04d" % score
	%Time.text = "%ds" % ceili(remaining)
	%Mode.disabled = state in ["playing", "paused"]
	%Start.disabled = state in ["playing", "paused"]
	%Pause.disabled = state != "playing"
	%Stop.disabled = state != "playing"
	%Pulse.disabled = state != "playing" or cooldown > 0 or win_delay > 0
	%PulseCharge.value = (1.0 - cooldown / 3.0) * 100.0
