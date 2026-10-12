extends Node2D

# =============================================================================
# SITAR EXPERIMENT (single scene — practice + real)
#
# PHASE 1 — PRACTICE: 10 blocks x 24 targets. No recording, no saving, no capture.
# PHASE 2 — REAL:     30 blocks x 24 targets. Recording, per-block CSV saving,
#                     and RealSense capture at each block end.
#
# Every block:
#   - 2 START TARGETS appear together (block 1: centers of L_1 & L_6;
#     later blocks: the previous block's last 2 finger positions).
#   - The block can only start once BOTH start targets are covered by a finger,
#     held through a 3-2-1-GO countdown (lifting a finger restarts the wait).
#   - The 2 start targets count as targets 1 and 2; targets 3-24 then spawn.
#   - Sector distribution for targets 3-24: each sector appears twice, EXCEPT
#     the 2 sectors the hands rest in (1 each). Target 3 is never in those.
#   - During gameplay, if BOTH hands lift, ghost circles show at the last 2
#     finger positions until both return.
#   - Continue button between blocks.
#
# After practice block 10: a "Start Actual Game" button opens the demographic
# form (control.tscn). On submit it returns here with Global.skip_practice=true,
# and the real 30-block phase begins.
#
# Recording starts when the demographic form opens (control.tscn sends
# recording_start). ArUco markers are visible on the form screen so the
# annotation script can recover H from the first frames of the AVI.
# =============================================================================

# ── UDP ───────────────────────────────────────────────────────────────────────
var udp_send    := PacketPeerUDP.new()
var udp_receive := PacketPeerUDP.new()

const PYTHON_IP   = "127.0.0.1"
const PYTHON_PORT = 9998
const GODOT_PORT  = 9999

const PX_PER_CM_X := 1920.0 / 93.0
const PX_PER_CM_Y := 1080.0 / 52.5

var waiting_for_hand := false
var pending_result   := {}
var current_tap_id   := 0

# ── Geometry ──────────────────────────────────────────────────────────────────
@export var center := Vector2(960, 955)

@export var lower_inner := 180.0
@export var lower_outer := 580.0
@export var upper_inner := 580.0
@export var upper_outer := 950.0

@export var segments   := 6
@export var line_width := 3.0

# ── Experiment structure ──────────────────────────────────────────────────────
@export var targets_per_block := 24
@export var practice_blocks   := 1
@export var real_blocks       := 2

@export var lower_colors := [
	Color("#737153"), Color("#737153"), Color("#737153"),
	Color("#737153"), Color("#737153"), Color("#737153")
]
@export var upper_colors := [
	Color("#354024"), Color("#354024"), Color("#354024"),
	Color("#354024"), Color("#354024"), Color("#354024")
]

# ── Phase / block state ───────────────────────────────────────────────────────
var practice_mode := true
var current_block := 1
var total_blocks  := practice_blocks

var current_index      := 0
var spawn_sector_index := 0
var spawn_time_ms      := 0
var results            := []
var player_gender       = ""
var player_id           = ""
var player_stroketime   = ""

var player_scene   = preload("res://Player/Player.tscn")
var current_target = null

var sector_pool:         Array = []
var _pending_sector_name := ""

var _tap_in_progress := false
var game_running     := false
var touches          := {}
var show_sectors     := false

# ── Start targets (paired) ────────────────────────────────────────────────────
var start_target_left  = null
var start_target_right = null
var start_positions: Array = []
var left_start_touched  := false
var right_start_touched := false

# ── Ghost circles (hands lifted mid-game) ─────────────────────────────────────
var last_two_finger_snap : Array = []
var ghost_positions      : Array = []
var show_ghost_circles   := false
var circle_radius        := 80.0

# ── Carryover of last 2 touch positions (for next block's start targets) ──────
var last_two_touches: Array = []

const ROOT_FOLDER := "C:/Users/Jemi/OneDrive/Desktop/test"

# ── Session folder (set once in _ready, named test_{player_id}) ───────────────
var session_folder := ""

# ─────────────────────────────────────────────────────────────────────────────

func _ready():
	player_id         = Global.player_id
	player_gender     = Global.player_gender
	player_stroketime = Global.player_stroketime

	session_folder = "%s/test_%s" % [ROOT_FOLDER, player_id]
	DirAccess.make_dir_recursive_absolute(session_folder)

	udp_receive.bind(GODOT_PORT)
	udp_send.set_dest_address(PYTHON_IP, PYTHON_PORT)
	print("UDP ready — experiment scene loaded")

	DirAccess.make_dir_recursive_absolute(ROOT_FOLDER)

	# Returning from the demographic form -> go straight to the real phase.
	if Global.skip_practice:
		Global.skip_practice = false
		practice_mode = false
		total_blocks  = real_blocks
		current_block = 1
		last_two_touches.clear()   # real block 1 uses L_1/L_6
	else:
		practice_mode = true
		total_blocks  = practice_blocks
		current_block = 1

	begin_block()

func _process(_delta):
	if udp_receive.get_available_packet_count() > 0:
		var packet  = udp_receive.get_packet()
		var message = JSON.parse_string(packet.get_string_from_utf8())
		if message:
			var hand   = message.get("hand", "")
			var tap_id = message.get("tap_id", -1)
			if hand != "" and tap_id == current_tap_id and waiting_for_hand:
				print("Hand received from Python: ", hand, " (tap_id: ", tap_id, ")")
				pending_result["hand_used"]        = hand
				pending_result["tap_wall_time_ms"] = str(message.get("wall_time_ms", ""))
				pending_result["left_x"]           = str(message.get("left_x",  "Unknown"))
				pending_result["left_y"]           = str(message.get("left_y",  "Unknown"))
				pending_result["right_x"]          = str(message.get("right_x", "Unknown"))
				pending_result["right_y"]          = str(message.get("right_y", "Unknown"))
				# Store results only during the real phase
				if not practice_mode:
					results.append(pending_result)
				pending_result   = {}
				waiting_for_hand = false

# ─────────────────────────────────────────────────────────────────────────────

func begin_block():
	results.clear()
	current_index  = 0
	current_tap_id = 0

	start_positions = get_start_positions()
	var occupied_sectors := [
		position_to_sector(start_positions[0]),
		position_to_sector(start_positions[1]),
	]
	build_sector_pool(occupied_sectors)

	await start_sequence()
	start_game()
	current_index = 2
	spawn_target()

# ── START POSITIONS ───────────────────────────────────────────────────────────

func get_start_positions() -> Array:
	if current_block == 1 or last_two_touches.size() < 2:
		var l1 = get_sector_center(0, 0)   # L_1 (left)
		var l6 = get_sector_center(0, 5)   # L_6 (right)
		return [l1, l6]
	else:
		var a = last_two_touches[0]
		var b = last_two_touches[1]
		if a.x <= b.x:
			return [a, b]
		else:
			return [b, a]

# ── START SEQUENCE: show 2 targets, wait for both covered, countdown ──────────

func start_sequence():
	touches.clear()
	left_start_touched  = false
	right_start_touched = false

	start_target_left = player_scene.instantiate()
	start_target_left.position = start_positions[0]
	start_target_left.add_to_group("start_targets")
	add_child(start_target_left)

	start_target_right = player_scene.instantiate()
	start_target_right.position = start_positions[1]
	start_target_right.add_to_group("start_targets")
	add_child(start_target_right)

	var label1 = $CountdownLabel
	var label2 = $LABEL2

	label1.visible  = true
	label1.position = Vector2(940, 600)
	label2.visible  = true
	label2.position = Vector2(940, 600)
	if practice_mode:
		label1.text = "PRACTICE %d of %d\nPlace your fingers on the targets" % [current_block, total_blocks]
	else:
		label1.text = "Block %d of %d\nPlace your fingers on the targets" % [current_block, total_blocks]
	label2.text = ""

	await wait_for_both_targets()

	# NOTE: recording_start is now sent from control.gd (_ready) when the
	# demographic form opens, so it is NOT sent here anymore.

	_hide_touch_error()
	label1.visible = false

	var countdown := ["3", "2", "1", "GO!"]
	for t in countdown:
		label2.text = t
		var duration := 0.5 if t == "GO!" else 1.0
		await get_tree().create_timer(duration).timeout

	label2.visible = false

	# Record the 2 start targets as targets 1 and 2 — real block 1 only.
	if not practice_mode and current_block == 1:
		_record_start_target(1, "START_L", start_positions[0], start_positions[1])
		_record_start_target(2, "START_R", start_positions[0], start_positions[1])

	for node in get_tree().get_nodes_in_group("start_targets"):
		if is_instance_valid(node):
			node.visible = false
			node.queue_free()
	start_target_left  = null
	start_target_right = null

	await get_tree().process_frame
	await get_tree().process_frame

func wait_for_both_targets(_frames_required: int = 0) -> void:
	while not (left_start_touched and right_start_touched):
		await get_tree().process_frame
		if not left_start_touched and not right_start_touched:
			_show_touch_error("Touch both targets to start")
		elif not left_start_touched:
			_show_touch_error("Touch the LEFT target")
		elif not right_start_touched:
			_show_touch_error("Touch the RIGHT target")
	_hide_touch_error()

func _target_hit_radius(target_node) -> float:
	var area = target_node.get_node("Area2D")
	var hit_radius := 100.0
	for child in area.get_children():
		if child is CollisionShape2D and child.shape != null:
			if child.shape is CircleShape2D:
				hit_radius = child.shape.radius * area.global_scale.x
				break
			if child.shape is RectangleShape2D:
				var s = child.shape.size * area.global_scale
				hit_radius = min(s.x, s.y) / 2.0
				break
	return hit_radius

func _record_start_target(target_number: int, sector_name: String, left_pos: Vector2, right_pos: Vector2) -> void:
	var own_pos := left_pos if sector_name == "START_L" else right_pos
	results.append({
		"id":                player_id,
		"gender":            player_gender,
		"Time_since_stroke": player_stroketime,
		"target_number":     target_number,
		"clicked_sector":    sector_name,
		"spawn_position":    str(own_pos),
		"reaction_time":     0,
		"hand_used":         "START",
		"tap_wall_time_ms":  "Unknown",
		"left_x":  str(left_pos.x),  "left_y":  str(left_pos.y),
		"right_x": str(right_pos.x), "right_y": str(right_pos.y)
	})

func start_game():
	var phase := "PRACTICE" if practice_mode else "REAL"
	print("%s block %d started — targets: %d" % [phase, current_block, targets_per_block])
	game_running = true

# ── SECTOR POOL ───────────────────────────────────────────────────────────────

func build_sector_pool(occupied_sectors: Array):
	sector_pool.clear()

	var counts := {}
	for ring in range(2):
		for seg in range(segments):
			counts[Vector2i(ring, seg)] = 2

	for occ in occupied_sectors:
		var key = Vector2i(occ["ring"], occ["seg"])
		if counts.has(key):
			counts[key] = counts[key] - 1

	for key in counts:
		for _i in range(counts[key]):
			sector_pool.append({"ring": key.x, "seg": key.y})

	sector_pool.shuffle()

	if occupied_sectors.size() > 0:
		var occ_keys := []
		for occ in occupied_sectors:
			occ_keys.append(Vector2i(occ["ring"], occ["seg"]))
		if sector_pool.size() > 0:
			var first_key = Vector2i(sector_pool[0]["ring"], sector_pool[0]["seg"])
			if first_key in occ_keys:
				for j in range(1, sector_pool.size()):
					var k = Vector2i(sector_pool[j]["ring"], sector_pool[j]["seg"])
					if not (k in occ_keys):
						var tmp = sector_pool[0]
						sector_pool[0] = sector_pool[j]
						sector_pool[j] = tmp
						break

	print("Sector pool built: ", sector_pool.size(), " targets")

func pick_next_sector() -> Vector2:
	var pool_idx = current_index - 2
	var chosen = sector_pool[pool_idx]
	var ring: int = chosen["ring"]
	var seg: int  = chosen["seg"]

	var ring_label := "L" if ring == 0 else "U"
	_pending_sector_name = ring_label + "_" + str(seg + 1)

	return get_random_point_in_sector(ring, seg)

func position_to_sector(pos: Vector2) -> Dictionary:
	var rel = pos - center
	var dist = rel.length()

	var ang = atan2(rel.y, rel.x)
	if ang < 0:
		ang += TAU

	var angle_step := PI / float(segments)
	var seg = int((ang - PI) / angle_step)
	seg = clamp(seg, 0, segments - 1)

	var ring := 0
	if dist >= lower_outer:
		ring = 1
	else:
		ring = 0

	return {"ring": ring, "seg": seg}

func get_sector_center(ring: int, seg_idx: int) -> Vector2:
	var angle_step := PI / float(segments)
	var a0 := PI + seg_idx * angle_step
	var a1 := a0 + angle_step
	var a_mid := (a0 + a1) * 0.5

	var r_inner: float
	var r_outer: float
	if ring == 0:
		r_inner = lower_inner
		r_outer = lower_outer
	else:
		r_inner = upper_inner
		r_outer = upper_outer
	var r_mid := (r_inner + r_outer) * 0.5

	return center + Vector2(cos(a_mid), sin(a_mid)) * r_mid

func get_random_point_in_sector(ring: int, seg_idx: int, padding := 0.15) -> Vector2:
	var angle_step := PI / float(segments)
	var a0 := PI + seg_idx * angle_step
	var a1 := a0 + angle_step

	var a_pad := (a1 - a0) * padding
	var a_min := a0 + a_pad
	var a_max := a1 - a_pad

	var r_inner: float
	var r_outer: float
	if ring == 0:
		r_inner = lower_inner
		r_outer = lower_outer
	else:
		r_inner = upper_inner
		r_outer = upper_outer

	var r_pad := (r_outer - r_inner) * padding
	var r_min := r_inner + r_pad
	var r_max := r_outer - r_pad

	var angle := randf_range(a_min, a_max)
	var r     := sqrt(randf_range(r_min * r_min, r_max * r_max))

	return center + Vector2(cos(angle), sin(angle)) * r

# ─────────────────────────────────────────────────────────────────────────────

func spawn_target():
	spawn_sector_index = current_index

	if current_target:
		current_target.queue_free()

	var spawn_pos := pick_next_sector()

	print("Target ", current_index + 1, "/", targets_per_block,
		  " | sector: ", _pending_sector_name,
		  " | position: ", spawn_pos)

	current_target          = player_scene.instantiate()
	current_target.position = spawn_pos
	add_child(current_target)

	_tap_in_progress = false
	spawn_time_ms    = Time.get_ticks_msec()

# ── Touch tracking ────────────────────────────────────────────────────────────

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S:
			show_sectors = !show_sectors
			queue_redraw()
			print("Show sectors: ", show_sectors)

	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			print("Finger", event.index, "pressed at", event.position)

			if not game_running:
				if start_target_left != null and is_instance_valid(start_target_left):
					if event.position.distance_to(start_target_left.position) <= 100.0:
						left_start_touched = true
						start_target_left.visible = false
				if start_target_right != null and is_instance_valid(start_target_right):
					if event.position.distance_to(start_target_right.position) <= 100.0:
						right_start_touched = true
						start_target_right.visible = false

			if touches.size() == 2:
				last_two_finger_snap = touches.values().duplicate()
				last_two_touches     = touches.values().duplicate()

			if game_running and touches.size() >= 2 and show_ghost_circles:
				show_ghost_circles = false
				ghost_positions    = []
				queue_redraw()
				print("Ghost circles hidden — both fingers back down")

			if game_running and current_target != null and is_instance_valid(current_target):
				if event.position.distance_to(current_target.position) <= 120:
					_hide_touch_error()
					_on_target_clicked(event.position)
				else:
					print("Touch outside target — ignored at: ", event.position)
		else:
			if touches.size() == 2:
				last_two_finger_snap = touches.values().duplicate()
				last_two_touches     = touches.values().duplicate()

			touches.erase(event.index)
			print("Finger", event.index, "released")

			if game_running and touches.size() == 0 and last_two_finger_snap.size() == 2:
				ghost_positions    = last_two_finger_snap.duplicate()
				show_ghost_circles = true
				queue_redraw()
				print("Ghost circles shown at: ", ghost_positions)

			if touches.size() <= 2:
				_hide_touch_error()

	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() == 2:
			last_two_finger_snap = touches.values().duplicate()
			last_two_touches     = touches.values().duplicate()

func _show_touch_error(msg: String):
	var err_label = $TouchErrorLabel
	if err_label:
		err_label.text    = msg
		err_label.visible = true

func _hide_touch_error():
	var err_label = $TouchErrorLabel
	if err_label:
		err_label.visible = false

# ─────────────────────────────────────────────────────────────────────────────

func _on_target_clicked(touch_pos: Vector2):
	print("_on_target_clicked called at: ", touch_pos)
	if not game_running:
		return
	if _tap_in_progress:
		return
	if current_target == null or not is_instance_valid(current_target):
		return

	print("Tap accepted")
	_tap_in_progress = true
	current_tap_id  += 1
	var this_tap_id  = current_tap_id

	var reaction_time = Time.get_ticks_msec() - spawn_time_ms

	pending_result = {
		"id":                player_id,
		"gender":            player_gender,
		"Time_since_stroke": player_stroketime,
		"target_number":     current_index + 1,
		"clicked_sector":    _pending_sector_name,
		"spawn_position":    str(current_target.position),
		"reaction_time":     reaction_time
	}
	waiting_for_hand = true

	var tap_message = JSON.stringify({
		"tap_x":  int(current_target.position.x),
		"tap_y":  int(current_target.position.y),
		"tap_id": this_tap_id
	})
	udp_send.put_packet(tap_message.to_utf8_buffer())
	print("Sent tap to Python: ", current_target.position, " (tap_id: ", this_tap_id, ")")

	current_target.die()
	await get_tree().create_timer(0.2).timeout

	current_index += 1
	print("current_index is now: ", current_index)

	if current_index >= targets_per_block:
		game_running = false
		end_block()
		return

	var wait_frames := 0
	while waiting_for_hand:
		await get_tree().process_frame
		wait_frames += 1
		if wait_frames % 30 == 0:
			udp_send.put_packet(tap_message.to_utf8_buffer())
			print("Resending tap to Python (attempt ", wait_frames / 30, ")")
		if wait_frames > 180:
			print("WARNING: No hand response after 3s, continuing anyway")
			waiting_for_hand = false
			pending_result["hand_used"]        = "Unknown"
			pending_result["tap_wall_time_ms"] = "Unknown"
			pending_result["left_x"]           = "Unknown"
			pending_result["left_y"]           = "Unknown"
			pending_result["right_x"]          = "Unknown"
			pending_result["right_y"]          = "Unknown"
			if not practice_mode:
				results.append(pending_result)
			pending_result = {}

	spawn_target()

# ─────────────────────────────────────────────────────────────────────────────

func _draw():
	if show_sectors:
		var angle_step  = PI / segments
		var start_angle = PI
		for i in range(segments):
			var a0 = start_angle + i * angle_step
			var a1 = a0 + angle_step
			draw_sector(center, lower_inner, lower_outer, a0, a1, lower_colors[i % lower_colors.size()])
			draw_sector(center, upper_inner, upper_outer, a0, a1, upper_colors[i % upper_colors.size()])

	if show_ghost_circles and ghost_positions.size() == 2:
		for pos in ghost_positions:
			draw_circle(pos, circle_radius, Color(1, 1, 1, 0.15))
			draw_arc(pos, circle_radius, 0, TAU, 64, Color(1, 1, 1, 0.6), 3.0)

func draw_sector(c: Vector2, r_in: float, r_out: float, a0: float, a1: float, col: Color) -> void:
	var points     := PackedVector2Array()
	var arc_points := 8

	for j in range(arc_points + 1):
		var t = float(j) / float(arc_points)
		var a = lerp(a0, a1, t)
		points.append(c + Vector2(cos(a), sin(a)) * r_out)

	for j in range(arc_points, -1, -1):
		var t = float(j) / float(arc_points)
		var a = lerp(a0, a1, t)
		points.append(c + Vector2(cos(a), sin(a)) * r_in)

	draw_colored_polygon(points, col)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.TAN, line_width)

# ── BLOCK END / TRANSITIONS ───────────────────────────────────────────────────

func end_block():
	if current_target:
		current_target.queue_free()

	if not practice_mode:
		print("\n── Real Block %d Results ──" % current_block)
		for row in results:
			print("Target ", row["target_number"], " | ", row["clicked_sector"], " | ", row["reaction_time"], "ms")
		save_results()
		save_results_json()

		var capture_signal = JSON.stringify({"action": "capture", "block": current_block})
		udp_send.put_packet(capture_signal.to_utf8_buffer())
		print("Capture signal sent to Python for block %d" % current_block)

	if practice_mode:
		if current_block >= practice_blocks:
			show_start_real_button()
		else:
			show_continue_button()
	else:
		if current_block >= real_blocks:
			finish_session()
		else:
			show_continue_button()

func show_continue_button():
	var btn = $ContinueButton
	btn.text     = "Continue"
	btn.visible  = true
	btn.disabled = false
	if btn.pressed.is_connected(_on_start_real_pressed):
		btn.pressed.disconnect(_on_start_real_pressed)
	if not btn.pressed.is_connected(_on_continue_pressed):
		btn.pressed.connect(_on_continue_pressed)

func _on_continue_pressed():
	var btn = $ContinueButton
	btn.visible  = false
	btn.disabled = true
	$LABEL2.visible = false
	$CountdownLabel.visible = false
	touches.clear()
	current_block += 1
	begin_block()

func show_start_real_button():
	var btn = $ContinueButton
	btn.text     = "Start Actual Game"
	btn.visible  = true
	btn.disabled = false
	if btn.pressed.is_connected(_on_continue_pressed):
		btn.pressed.disconnect(_on_continue_pressed)
	if not btn.pressed.is_connected(_on_start_real_pressed):
		btn.pressed.connect(_on_start_real_pressed)

func _on_start_real_pressed():
	var btn = $ContinueButton
	btn.visible  = false
	btn.disabled = true
	var tree = get_tree()
	get_tree().root.remove_child(self)
	queue_free()
	tree.change_scene_to_file("res://Player/control.tscn")

func finish_session():
	var label = $LABEL2
	label.position = Vector2(940, 600)
	label.visible  = true
	label.text     = "SESSION COMPLETE"

	udp_send.put_packet(JSON.stringify({"action": "exit"}).to_utf8_buffer())

	await get_tree().create_timer(2.0).timeout
	var tree = get_tree()
	get_tree().root.remove_child(self)
	queue_free()
	tree.change_scene_to_file("res://main.tscn")

# ── SAVING (per-block folder, real phase only) ────────────────────────────────

func block_folder() -> String:
	var folder := "%s/test%d" % [session_folder, current_block]
	DirAccess.make_dir_recursive_absolute(folder)
	return folder

func px_to_cm_x(px: float) -> String:
	return "%.2f" % (px / PX_PER_CM_X)

func px_to_cm_y(py: float) -> String:
	return "%.2f" % (py / PX_PER_CM_Y)

func _convert_coord(val: String, is_x: bool) -> String:
	if val == "Unknown" or val == "Null" or val == "null":
		return "Unknown"
	if is_x:
		return px_to_cm_x(float(val))
	else:
		return px_to_cm_y(float(val))

func save_results():
	var time   = Time.get_datetime_string_from_system().replace(":", "-")
	var folder = block_folder()
	var tag    = "%s_%s_%s" % [player_id, player_gender, player_stroketime]
	var file_name = "%s/game_data__%s__%s.csv" % [folder, tag, time]
	var file      = FileAccess.open(file_name, FileAccess.WRITE)

	file.store_csv_line(["ID", "Gender", "Time since stroke", "Block"])
	file.store_csv_line([player_id, player_gender, player_stroketime, str(current_block)])
	file.store_csv_line([])

	file.store_csv_line(["Target Number", "Clicked Sector", "Spawn Position (cm)", "Spawn Position",
						 "Hand Used", "Tap Wall Time (ms)",
						 "Left Hand X (cm)", "Left Hand Y (cm)",
						 "Right Hand X (cm)", "Right Hand Y (cm)", "Reaction Time (ms)"])
	for i in results:
		var parts    = i["spawn_position"].replace("(","").replace(")","").split(", ")
		var spawn_cm = px_to_cm_x(float(parts[0])) + ", " + px_to_cm_y(float(parts[1]))
		file.store_csv_line([
			str(i["target_number"]),
			i["clicked_sector"],
			spawn_cm,
			i["spawn_position"],
			i.get("hand_used",        "Unknown"),
			i.get("tap_wall_time_ms", "Unknown"),
			_convert_coord(i.get("left_x",  "Unknown"), true),
			_convert_coord(i.get("left_y",  "Unknown"), false),
			_convert_coord(i.get("right_x", "Unknown"), true),
			_convert_coord(i.get("right_y", "Unknown"), false),
			str(i["reaction_time"])
		])

	file.close()
	print("Saved CSV: ", file_name)

func save_results_json():
	var time   = Time.get_datetime_string_from_system().replace(":", "-")
	var folder = block_folder()
	var tag    = "%s_%s_%s" % [player_id, player_gender, player_stroketime]
	var file_name = "%s/game_data__%s__%s.json" % [folder, tag, time]
	var file      = FileAccess.open(file_name, FileAccess.WRITE)

	var clean_targets = []
	for r in results:
		var parts = r["spawn_position"].replace("(","").replace(")","").split(", ")
		clean_targets.append({
			"target_number":     r["target_number"],
			"clicked_sector":    r["clicked_sector"],
			"spawn_position_px": r["spawn_position"],
			"spawn_position_cm": px_to_cm_x(float(parts[0])) + ", " + px_to_cm_y(float(parts[1])),
			"hand_used":         r.get("hand_used",        "Unknown"),
			"tap_wall_time_ms":  r.get("tap_wall_time_ms", "Unknown"),
			"left_x_cm":         _convert_coord(r.get("left_x",  "Unknown"), true),
			"left_y_cm":         _convert_coord(r.get("left_y",  "Unknown"), false),
			"right_x_cm":        _convert_coord(r.get("right_x", "Unknown"), true),
			"right_y_cm":        _convert_coord(r.get("right_y", "Unknown"), false),
			"reaction_time":     r["reaction_time"]
		})

	var _output = {
		"id":                player_id,
		"gender":            player_gender,
		"Time_since_stroke": player_stroketime,
		"block":             current_block,
		"targets":           clean_targets
	}
	file.store_string(JSON.stringify(_output, "\t"))
	file.close()
	print("Saved JSON: ", file_name)
