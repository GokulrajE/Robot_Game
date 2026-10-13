extends Control
## Scene-authored presentation; this script owns input, session rules and animation time.
const LITTER = [preload("res://games/ocean_rescue/scenes/3d/bottle_detailed.tscn"), preload("res://games/ocean_rescue/scenes/3d/container_detailed.tscn")]
const BUOY = preload("res://games/ocean_rescue/scenes/3d/buoy.tscn")
const SPLASH = preload("res://games/ocean_rescue/scenes/3d/splash.tscn")
const BOUNDS = Rect2(-12.0, -6.0, 24.0, 16.0)
const GOALS = [8, 12, 16]
const DURATIONS = [90.0, 80.0, 70.0]
@export var auto_fullscreen := true
var state := "ready"
var level := 0
var score := 0
var collected := 0
var remaining := 90.0
var elapsed := 0.0
var moving := false
var boat_speed := 0.0
var target := Vector3.ZERO
var bump_cooldown := 0.0
var celebration := 0.0
var best: Dictionary = {}
var save_ok := true
var completed := false
var pending: Array[Dictionary] = []

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://ocean_progress.cfg") == OK:
		best = config.get_value("progress", "best", {})
	%Start.pressed.connect(start_session)
	%Pause.pressed.connect(toggle_pause)
	%Stop.pressed.connect(func(): finish(false))
	%Resume.pressed.connect(func():
		if state == "paused": toggle_pause()
		else: start_session())
	%Back.pressed.connect(prepare)
	%Home.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/launcher.tscn"))
	%Next.pressed.connect(func(): level = mini(2, level + 1); start_session())
	%Level.item_selected.connect(func(index: int): level = index; prepare())
	%Mute.button_pressed = AudioServer.is_bus_mute(0)
	%Mute.toggled.connect(func(value: bool): AudioServer.set_bus_mute(0, value))
	%Ambience.finished.connect(func():
		if state == "playing": %Ambience.play())
	prepare()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func prepare() -> void:
	state = "ready"
	completed = false
	score = 0
	collected = 0
	elapsed = 0
	remaining = DURATIONS[level]
	celebration = 0
	bump_cooldown = 0
	pending.clear()
	for index in range(3): %Boat.get_node("Model/Cargo%d" % index).hide()
	clear_children(%Litter)
	clear_children(%Buoys)
	clear_children(%Effects)
	%Boat.position = Vector3.ZERO
	%Boat.rotation = Vector3(0, -0.45, 0)
	%Boat.get_node("Model").position = Vector3.ZERO
	%Boat.get_node("Model").rotation = Vector3.ZERO
	%Boat.get_node("AnimationPlayer").stop()
	%Boat.get_node("Model/Scoop").rotation.x = 0
	%ScoreAnimation.stop()
	%Score.scale = Vector2.ONE
	%ReefLife.get_node("AnimationPlayer").play("roam")
	%ReefLife.get_node("AnimationPlayer").seek(0, true)
	%ReefLife.get_node("Seagrass/Clump0/Blade0").mesh.material.set_shader_parameter("game_time", 0.0)
	%Water.mesh.material.set_shader_parameter("game_time", 0.0)
	%Ambience.stop()
	reset_input()
	%Level.select(level)
	%Goal.text = "%d items · %ds · %d navigation buoys" % [GOALS[level], int(remaining), 2 + level * 2]
	update_hud()

func start_session() -> void:
	prepare()
	state = "playing"
	if auto_fullscreen and DisplayServer.get_name() != "headless" and get_viewport() == get_window():
		get_window().mode = Window.MODE_FULLSCREEN
	for index in range(2 + level * 2):
		var buoy := BUOY.instantiate()
		buoy.position = free_position(4.0)
		%Buoys.add_child(buoy)
	for index in range(mini(6, GOALS[level])): spawn_litter()
	%Ambience.stream_paused = false
	%Ambience.play()
	update_hud()

func free_position(clearance: float) -> Vector3:
	for attempt in range(150):
		var point := Vector3(randf_range(-11.0, 11.0), 0, randf_range(-5.0, 9.0))
		if point.distance_to(%Boat.position) < clearance: continue
		var free := true
		for group in [%Litter, %Buoys]:
			for other in group.get_children():
				if point.distance_to(other.position) < 2.5: free = false
		if free: return point
	# With at most twelve actors, this coarse scan supplies a separated fallback.
	for x in range(-11, 12, 2):
		for z in range(-5, 10, 2):
			var point := Vector3(x, 0, z)
			var free := point.distance_to(%Boat.position) >= 2
			for group in [%Litter, %Buoys]:
				for other in group.get_children():
					if point.distance_to(other.position) < 2: free = false
			if free: return point
	return Vector3(-11, 0, 9)

func spawn_litter() -> void:
	var item: Node3D = LITTER[(collected + %Litter.get_child_count()) % 2].instantiate()
	item.position = free_position(2.5)
	item.rotation.y = randf() * TAU
	item.set_meta("phase", randf() * TAU)
	%Litter.add_child(item)

func _process(delta: float) -> void:
	if state != "playing": return
	elapsed += delta
	%Water.mesh.material.set_shader_parameter("game_time", elapsed)
	%Boat.get_node("Wake/Trail").mesh.material.set_shader_parameter("game_time", elapsed)
	$World/Island0/Shore.mesh.material.set_shader_parameter("game_time", elapsed)
	%Boat.get_node("Model").position.y = sin(elapsed * 2.2) * 0.055
	%Boat.get_node("Model").rotation.z = sin(elapsed * 1.6) * 0.025
	%Boat.get_node("Model").rotation.x = sin(elapsed * 2.1) * 0.035
	%Boat.get_node("AnimationPlayer").advance(delta)
	%ScoreAnimation.advance(delta)
	for effect in %Effects.get_children():
		if not effect.is_queued_for_deletion(): effect.advance_effect(delta)
	advance_pickups(delta)
	%ReefLife.get_node("AnimationPlayer").advance(delta)
	%ReefLife.get_node("Seagrass/Clump0/Blade0").mesh.material.set_shader_parameter("game_time", elapsed)
	if celebration > 0:
		celebration = maxf(0, celebration - delta)
		if celebration == 0: finish(true)
		return
	remaining = maxf(0, remaining - delta)
	bump_cooldown = maxf(0, bump_cooldown - delta)
	move_boat(delta)
	for item in %Litter.get_children():
		if item.get_meta("collected", false): continue
		item.position.y = 0.1 + sin(elapsed * 2 + float(item.get_meta("phase"))) * 0.09
	check_pickups()
	if remaining <= 0 and celebration <= 0: finish(false)
	update_hud()

func move_boat(delta: float) -> void:
	if not moving: return
	var direction: Vector3 = target - %Boat.position
	direction.y = 0
	boat_speed = move_toward(boat_speed, minf(4.5 + level * 0.2, direction.length() * 3), delta * 18)
	var next: Vector3 = %Boat.position.move_toward(target, boat_speed * delta)
	for buoy in %Buoys.get_children():
		var nearest := Geometry3D.get_closest_point_to_segment(buoy.position, %Boat.position, next)
		if nearest.distance_to(buoy.position) < 1.35:
			reset_input()
			if bump_cooldown <= 0:
				%BumpSound.play()
				spawn_splash(%Boat.position)
				bump_cooldown = 1
			return
	%Boat.position = next
	if direction.length_squared() > 0.001:
		%Boat.rotation.y = lerp_angle(%Boat.rotation.y, atan2(direction.x, direction.z), minf(1, delta * 7))
	%Boat.get_node("Wake").visible = true
	if %Boat.position.distance_to(target) < 0.04: reset_input()

func check_pickups() -> void:
	if state != "playing" or celebration > 0: return
	for item in %Litter.get_children():
		if item.get_meta("collected", false): continue
		if Vector2(item.position.x, item.position.z).distance_to(Vector2(%Boat.position.x, %Boat.position.z)) > 1.5: continue
		item.set_meta("collected", true)
		pending.append({"item": item, "from": item.position, "age": 0.0})
		collected += 1
		score += 100
		%CollectSound.play()
		%SplashSound.play()
		%Boat.get_node("AnimationPlayer").stop()
		%Boat.get_node("AnimationPlayer").play("scoop")
		%Boat.get_node("AnimationPlayer").advance(0)
		%ScoreAnimation.stop()
		%ScoreAnimation.play("pop")
		spawn_splash(item.position, true)
		if collected >= GOALS[level]:
			celebration = 2.5
			reset_input()
			%CelebrationSound.play()
			break
		if collected + uncollected_count() < GOALS[level]: spawn_litter()

func uncollected_count() -> int:
	var count := 0
	for item in %Litter.get_children():
		if not item.get_meta("collected", false): count += 1
	return count

func advance_pickups(delta: float) -> void:
	for pickup in pending.duplicate():
		pickup.age += delta
		var ratio := minf(1, pickup.age / 0.75)
		var item: Node3D = pickup.item
		item.global_position = (pickup.from as Vector3).lerp(%Boat.get_node("Basket").global_position, ratio) + Vector3.UP * sin(ratio * PI) * 1.4
		item.scale = Vector3.ONE * lerpf(1, 0.35, ratio)
		if ratio >= 1:
			for index in range(mini(3, collected)): %Boat.get_node("Model/Cargo%d" % index).show()
			pending.erase(pickup)
			%Litter.remove_child(item)
			item.queue_free()

func spawn_splash(location: Vector3, points := false) -> void:
	var effect := SPLASH.instantiate()
	effect.position = Vector3(location.x, 0.03, location.z)
	%Effects.add_child(effect)
	effect.get_node("Points").visible = points

func set_target(screen: Vector2) -> bool:
	if state != "playing" or celebration > 0: return false
	if not get_viewport_rect().has_point(screen): return false
	var point = Plane(Vector3.UP, 0).intersects_ray(%Camera.project_ray_origin(screen), %Camera.project_ray_normal(screen))
	if point == null: return false
	target = Vector3(clampf(point.x, BOUNDS.position.x, BOUNDS.end.x), 0, clampf(point.z, BOUNDS.position.y, BOUNDS.end.y))
	moving = true
	%Destination.position = target + Vector3(0, 0.1, 0)
	%Destination.show()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if set_target(event.position): get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if set_target(event.position): get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		if set_target(event.position): get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if set_target(event.position): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and state in ["playing", "paused"]:
		toggle_pause()
		get_viewport().set_input_as_handled()

func reset_input() -> void:
	moving = false
	boat_speed = 0
	target = %Boat.position
	%Destination.hide()
	%Boat.get_node("Wake").hide()

func toggle_pause() -> void:
	if state == "playing":
		state = "paused"
		reset_input()
		%Ambience.stream_paused = true
		for sound in [%CollectSound, %SplashSound, %CelebrationSound, %BumpSound]: sound.stop()
		%ResultTitle.text = "A moment by the sea"
		%ResultText.text = "Click or drag to steer. Collect floating litter.\nOrange buoys block your route; steer around them.\n\n%d / %d collected · %ds left" % [collected, GOALS[level], ceili(remaining)]
		%Resume.text = "Resume voyage"
	elif state == "paused":
		state = "playing"
		%Ambience.stream_paused = false
	update_hud()

func finish(success: bool) -> void:
	if state not in ["playing", "paused"]: return
	state = "finished"
	completed = success
	reset_input()
	%Ambience.stop()
	var key := str(level)
	best[key] = maxi(score, int(best.get(key, 0)))
	var config := ConfigFile.new()
	config.set_value("progress", "best", best)
	save_ok = config.save("user://ocean_progress.cfg") == OK
	%ResultTitle.text = "A cleaner lagoon!" if success else "Every pickup helps"
	%ResultText.text = "%d / %d items recovered · %d points\nLevel %d best: %d\n%s" % [collected, GOALS[level], score, level + 1, best[key], "Progress saved." if save_ok else "Could not save progress on this device."]
	%Resume.text = "Play again"
	update_hud()

func update_hud() -> void:
	%Setup.visible = state == "ready"
	%HUD.visible = state == "playing"
	%Overlay.visible = state in ["paused", "finished"]
	%Next.visible = state == "finished" and completed and level < 2
	%Score.text = "%04d" % score
	%Time.text = "%ds" % ceili(remaining)
	%Collected.text = "%d / %d" % [collected, GOALS[level]]
	%Progress.value = 100.0 * collected / GOALS[level]

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing": toggle_pause()
