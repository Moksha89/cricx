extends Node3D

const BLUE = Color("2674da")
const GOLD = Color("f4bc54")
var batsman: Node3D
var bowler: Node3D
var bat: Node3D
var ball: MeshInstance3D
var camera: Camera3D
var score_label: Label
var message: Label
var action: Button
var shot_button: Button
var aim_button: Button
var bowling_nets := false
var mode_button: Button
var length_button: Button
var pace_button: Button
var playback_button: Button
var nets_playback := 1.0
var bounce_marker: MeshInstance3D
var hint_label: Label
var session_label: Label
var nets: Node3D
var line_index := 1
var length_index := 1
var pace_index := 1
const NET_LINES := [-0.60, 0.0, 0.60]
const NET_LENGTHS := [4.5, 6.8, 8.8]
const NET_PACES := [18.0, 21.0, 24.0]
var last_release := Vector3.ZERO
var last_crossing := Vector3.ZERO
var last_launch_velocity := Vector3.ZERO
var score := 0
var deliveries := 0
var wickets := 0
var phase := "ready"
var clock := 0.0
var swing_age := -10.0
var physics := CricketBallPhysics.new()
var contact_checked := false
var loft := false
var aim := 0.0
var umpire: Node3D
var bowling_arm: Node3D
var follow_camera := false
var delivery_x := 0.0
var bowling_release_offset := 0.0
var delivery_speed := 23.0
var hit := false
var view := 0
var motion_time := 0.0
var fielders: Array[CricketAthlete] = []
var rng := RandomNumberGenerator.new()
var materials: Dictionary = {}
var stadium_batches: Dictionary = {}
var stadium_nodes: Array[MultiMeshInstance3D] = []

func material(color: Color) -> StandardMaterial3D:
	if materials.has(color):
		return materials[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	materials[color] = m
	return m

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	parent.add_child(n)
	return n

func stadium_box(size: Vector3, pos: Vector3, color: Color, angle: float) -> void:
	if not stadium_batches.has(color):
		stadium_batches[color] = []
	var transform := Transform3D(Basis(Vector3.UP, angle).scaled_local(size), pos)
	stadium_batches[color].append(transform)

func build_stadium_batches() -> void:
	for color in stadium_batches:
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		var unit := BoxMesh.new()
		unit.size = Vector3.ONE
		instances.mesh = unit
		instances.instance_count = stadium_batches[color].size()
		for i in range(instances.instance_count):
			instances.set_instance_transform(i, stadium_batches[color][i])
		var group := MultiMeshInstance3D.new()
		group.multimesh = instances
		group.material_override = material(color)
		add_child(group)
		stadium_nodes.append(group)
	stadium_batches.clear()

func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.height = radius * 2.0
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	parent.add_child(n)
	return n

func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 16
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	parent.add_child(n)
	return n

func limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, color: Color) -> void:
	var segment := cylinder(parent, radius, start.distance_to(end), (start + end) * 0.5, color)
	segment.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	sphere(parent, radius, end, color)

func player(pos: Vector3, kit: Color, helmet: bool = false) -> Node3D:
	var p := CricketAthlete.new()
	add_child(p)
	p.position = pos + Vector3(0, 0.04, 0)
	p.build(kit, helmet, material)
	return p

func stumps(z: float) -> void:
	for x in [-0.0953, 0.0, 0.0953]:
		cylinder(self, 0.019, CricketBallPhysics.STUMP_HEIGHT, Vector3(x, CricketBallPhysics.PITCH_LEVEL + CricketBallPhysics.STUMP_HEIGHT * 0.5, z), Color("f2e4ba"))
	box(self, Vector3(0.2286, 0.018, 0.04), Vector3(0, CricketBallPhysics.BAIL_TOP - 0.009, z), GOLD)

func _ready() -> void:
	rng.randomize()
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("85b5cc")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.25
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 0.5
	sun.shadow_enabled = true
	add_child(sun)
	cylinder(self, 48, 0.2, Vector3(0, -0.07, 0), Color("347650"))
	for i in range(12):
		var stripe := box(self, Vector3(3.8, 0.001, 58), Vector3(-22 + i * 4, 0.0335, 0), Color("3b8055") if i % 2 == 0 else Color("347650"))
		stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(self, Vector3(3.05, 0.08, 22), Vector3(0, 0, 0), Color("c5ac78"))
	for z in [-9.0, 9.0]:
		box(self, Vector3(3.0, 0.02, 0.06), Vector3(0, 0.052, z), Color.WHITE)
		for x in [-1.1, 1.1]:
			box(self, Vector3(0.04, 0.02, 1.25), Vector3(x, 0.053, z), Color.WHITE)
	stumps(10.06)
	stumps(-10.06)
	for i in range(72):
		var angle := i * TAU / 72.0
		stadium_box(Vector3(3.8, 0.12, 0.16), Vector3(sin(angle) * 40, 0.04, cos(angle) * 40), Color("eee4c9"), angle)
		for tier in range(3):
			var radius := 46.0 + tier * 3
			stadium_box(Vector3(4.1, 2.0 + tier, 3), Vector3(sin(angle) * radius, 0.9 + tier * 1.3, cos(angle) * radius), Color("18334a") if i % 2 == 0 else Color("285771"), angle)
			stadium_box(Vector3(3.7, 0.25, 2.5), Vector3(sin(angle) * radius, 2.05 + tier * 1.8, cos(angle) * radius), GOLD if i % 4 == 0 else BLUE, angle)
	build_stadium_batches()
	for x in [-35, 35]:
		for z in [-35, 35]:
			cylinder(self, 0.23, 18, Vector3(x, 9, z), Color("8b9eaa"))
			box(self, Vector3(4, 1.4, 0.6), Vector3(x, 18, z), Color("e6f1f7"))
	batsman = player(Vector3(0.55, 0, 8.6), BLUE, true)
	batsman.rotation.y = PI - 0.25
	bat = Node3D.new()
	batsman.add_child(bat)
	bat.position = Vector3(0.18, 1.12, 0.10)
	box(bat, Vector3(0.19, 0.85, 0.09), Vector3(0, -0.4, 0), Color("e1bd7d"))
	cylinder(bat, 0.035, 0.3, Vector3(0, 0.16, 0), Color("e04943"))
	bowler = player(Vector3(0.75, 0, -15), Color("df6549"))
	(bowler as CricketAthlete).configure_spin_bowler()
	umpire = player(Vector3(1.5, 0, -11.8), Color("eeeeeb"))
	cylinder(umpire, 0.36, 0.04, Vector3(0, 2.02, 0), Color("eeeeeb"))
	cylinder(umpire, 0.23, 0.18, Vector3(0, 2.08, 0), Color("eeeeeb"))
	bowling_arm = bowler.get_node("UpperBody/RightArm")
	(bowler as CricketAthlete).offspin_pose(OffspinAction.RELEASE_TIME)
	bowling_release_offset = (bowler as CricketAthlete).right_hand.x
	(bowler as CricketAthlete).idle_pose(0)
	for pos in [Vector3(-10, 0, 15), Vector3(12, 0, 12), Vector3(-20, 0, -5), Vector3(23, 0, -12), Vector3(0, 0, 25)]:
		fielders.append(player(pos, Color("df6549")) as CricketAthlete)
	ball = sphere(self, 0.075, Vector3(0, 1.8, -10), Color("b52c3b"))
	ball.visible = false
	camera = Camera3D.new()
	add_child(camera)
	set_camera()
	build_nets()
	build_ui()
	(batsman as CricketAthlete).bat_pose(bat, -10, 0)
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("smoke_test")
	if "--capture" in OS.get_cmdline_user_args():
		call_deferred("capture")

func set_camera() -> void:
	if bowling_nets and view == 0:
		camera.position = Vector3(0.75, 3.7, -20)
		camera.look_at(Vector3(0, 0.65, 3))
	elif bowling_nets and view == 1:
		camera.position = Vector3(5.2, 2.7, -11.8)
		camera.look_at(Vector3(0.75, 1.2, -12))
	elif view == 0:
		camera.position = Vector3(0, 4.5, 16)
		camera.look_at(Vector3(0, 1, -3))
	else:
		camera.position = Vector3(28, 24, 32)
		camera.look_at(Vector3.ZERO)
	camera.current = true

func label(text_value: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func button(text_value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text_value
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.custom_minimum_size = Vector2(170, 64)
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(callback)
	return b

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := PanelContainer.new()
	root.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 94
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	top.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)
	var title := VBoxContainer.new()
	row.add_child(title)
	title.add_child(label("CRICX  /  FIRST NETS", 25, GOLD))
	session_label = label("BOUNDARY NETS • 6 balls • Original prototype", 16)
	title.add_child(session_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	score_label = label("0 / 0     0.0 overs", 25)
	row.add_child(score_label)
	mode_button = button("BOWLING NETS", toggle_nets)
	row.add_child(mode_button)
	row.add_child(button("CAMERA", func(): view = 1 - view; set_camera()))
	row.add_child(button("LICENCES", show_licences))
	var bottom := PanelContainer.new()
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -135
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	bottom.add_child(content)
	message = label("Welcome to the nets. Tap BOWL to face your first delivery.", 21, GOLD)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(message)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 16)
	content.add_child(controls)
	controls.add_child(button("RESTART", reset))
	shot_button = button("SHOT: DRIVE", choose_shot_or_line)
	controls.add_child(shot_button)
	aim_button = button("AIM: STRAIGHT", choose_aim_or_length)
	controls.add_child(aim_button)
	pace_button = button("PACE: 76 km/h", choose_pace)
	pace_button.visible = false
	controls.add_child(pace_button)
	playback_button = button("REPLAY: 1×", func(): nets_playback = 0.5 if nets_playback == 1.0 else (0.25 if nets_playback == 0.5 else 1.0); refresh_net_controls())
	playback_button.visible = false
	controls.add_child(playback_button)
	action = button("BOWL", act)
	controls.add_child(action)
	hint_label = label("Touch SWING as the ball reaches you • Boundaries only: 4 / 6 • No pitch marker", 16)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint_label)

func show_licences() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "CricX — Open-source licences"
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog)
	var text := RichTextLabel.new()
	text.custom_minimum_size = Vector2(760, 390)
	text.text = "CricX First Nets\nOriginal procedural game assets.\n\n" + Engine.get_license_text()
	text.text += "\n\nAndroid components: Kotlin and kotlinx.coroutines — Copyright JetBrains s.r.o.; AndroidX — Copyright The Android Open Source Project. Licensed under Apache License 2.0.\n"
	for component in Engine.get_copyright_info():
		text.text += "\n" + component["name"] + "\n"
		for part in component["parts"]:
			for copyright_line in part["copyright"]:
				text.text += copyright_line + "\n"
			text.text += "Licence: " + part["license"] + "\n"
	for licence_name in Engine.get_license_info():
		text.text += "\n\n" + licence_name + "\n" + Engine.get_license_info()[licence_name]
	dialog.add_child(text)
	var was_paused := get_tree().paused
	var close := func():
		get_tree().paused = was_paused
		dialog.queue_free()
	dialog.confirmed.connect(close)
	dialog.canceled.connect(close)
	get_tree().paused = true
	dialog.popup_centered()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		act()

func act() -> void:
	if phase == "ready":
		phase = "runup"
		clock = 0
		hit = false
		contact_checked = false
		bounce_marker.visible = false
		swing_age = -10
		delivery_x = NET_LINES[line_index] if bowling_nets else rng.randf_range(-0.55, 0.55)
		delivery_speed = NET_PACES[pace_index] if bowling_nets else rng.randf_range(22, 27)
		message.text = "Read the ball. " + ("LOFT" if loft else "DRIVE") + " selected."
		if bowling_nets:
			message.text = "Watch the gather, front-foot plant and release."
			action.text = "BOWLING…"
			action.disabled = true
		else:
			action.text = "SWING"
	elif phase == "delivery" or phase == "runup":
		if not bowling_nets and swing_age < -5:
			swing_age = 0
			action.disabled = true
	elif phase == "finished":
		reset()

func swing_angle(age: float) -> float:
	var contact_angle := -0.5 if loft else 0.0
	if age < 0.13:
		return lerpf(0.75, contact_angle, clampf(age / 0.13, 0, 1))
	if age < 0.36:
		return lerpf(contact_angle, -1.6, (age - 0.13) / 0.23)
	return lerpf(-1.6, 0, clampf((age - 0.36) / 0.3, 0, 1))

func _physics_process(delta: float) -> void:
	if bowling_nets:
		delta *= nets_playback
	clock += delta
	motion_time += delta
	if swing_age >= 0:
		swing_age += delta
		bat.rotation.x = swing_angle(swing_age)
	if phase == "runup":
		bowler.position.x = 0.75
		bowler.position.z = -15.0 + OffspinAction.travel(clock)
		bowler.position.y = 0.04 + (bowler as CricketAthlete).hop_height(clock)
		(bowler as CricketAthlete).offspin_pose(clock)
		ball.position = (bowler as CricketAthlete).release_point()
		ball.visible = true
		if clock >= OffspinAction.RELEASE_TIME:
			phase = "delivery"
			clock = 0
			bowler.position.y = 0.04
			(bowler as CricketAthlete).offspin_pose(OffspinAction.RELEASE_TIME)
			var origin := (bowler as CricketAthlete).release_point()
			var lateral_speed := delivery_speed * (delivery_x - origin.x) / (10.06 - origin.z)
			last_release = origin
			last_launch_velocity = Vector3(lateral_speed, -1.4, delivery_speed)
			if bowling_nets:
				last_launch_velocity = nets_velocity(origin, Vector3(delivery_x, CricketBallPhysics.GROUND, NET_LENGTHS[length_index]), delivery_speed)
			physics.launch(origin, last_launch_velocity)
			ball.position = physics.position + Vector3(0, 0.039, 0)
			ball.visible = true
	elif phase == "delivery" or phase == "flight":
		var before := physics.position
		physics.advance(delta)
		if bowling_nets and physics.bounces > 0:
			bounce_marker.position = Vector3(physics.first_bounce_position.x, 0.06, physics.first_bounce_position.z)
			bounce_marker.visible = true
		ball.position = physics.position + Vector3(0, 0.039, 0)
		if phase == "delivery":
			(bowler as CricketAthlete).follow_pose(clock)
			bowler.position.z = -15.0 + OffspinAction.travel(OffspinAction.RELEASE_TIME + clock)
			if not bowling_nets and not contact_checked and CricketBallPhysics.crosses_plane(before, physics.position, 8.6):
				contact_checked = true
				var point := CricketBallPhysics.at_plane(before, physics.position, 8.6)
				var fraction := (8.6 - before.z) / (physics.position.z - before.z)
				var age_at_contact := swing_age - delta * (1 - fraction)
				if age_at_contact >= 0.045 and age_at_contact <= 0.23 and absf(point.x) < 0.65 and point.y < 1.5:
					hit = true
					var quality := clampf(1.0 - absf(age_at_contact - 0.13) / 0.15, 0, 1)
					var speed := lerpf(15, 35, quality)
					var direction := Vector3(sin(aim), 0, -cos(aim))
					physics.launch(point, direction * speed + Vector3(0, lerpf(10, 21, quality) if loft else 2.5, 0))
					phase = "flight"
					clock = 0
					message.text = "Clean contact — watch the field!"
					follow_camera = true
			if phase == "delivery" and CricketBallPhysics.crosses_plane(before, physics.position, 10.06):
				var point := CricketBallPhysics.at_plane(before, physics.position, 10.06)
				if bowling_nets:
					last_crossing = point
					var struck := CricketBallPhysics.strikes_stumps(point)
					if struck:
						wickets += 1
					finish_delivery(nets_result(struck))
				elif CricketBallPhysics.strikes_stumps(point):
					wickets += 1
					finish_delivery("Bowled! The delivery struck your stumps.")
				else:
					finish_delivery("Dot ball. Through to the keeper.")
		elif phase == "flight":
			var runs := physics.boundary_runs()
			if runs > 0:
				score += runs
				finish_delivery("SIX! Cleared the rope." if runs == 6 else "FOUR! Reached the boundary.")
			elif physics.rolling and physics.velocity.length() < 0.05:
				finish_delivery("Dot ball. Stopped inside the rope — boundaries-only nets.")
			elif clock >= 18:
				finish_delivery("Dot ball. Practice delivery complete.")
		if follow_camera and view == 0:
			camera.look_at(ball.position)
	elif phase == "result" and clock >= 1.8:
		ball.visible = false
		umpire.get_node("UpperBody/LeftArm").rotation = Vector3.ZERO
		umpire.get_node("UpperBody/RightArm").rotation = Vector3.ZERO
		bowler.position = Vector3(0.75, 0.04, -15)
		(bowler as CricketAthlete).idle_pose(0)
		follow_camera = false
		set_camera()
		action.disabled = false
		if deliveries >= 6:
			phase = "finished"
			action.text = "PLAY AGAIN"
			message.text = ("Nets complete — %d / 6 deliveries hit the stumps." % wickets) if bowling_nets else ("Over complete — %d runs, %d wickets. Play again?" % [score, wickets])
		else:
			phase = "ready"
			action.text = "BOWL"

	(batsman as CricketAthlete).bat_pose(bat, swing_age, motion_time)
	for i in range(fielders.size()):
		fielders[i].idle_pose(motion_time + i)
	if phase == "ready" or phase == "finished":
		(bowler as CricketAthlete).idle_pose(motion_time)

func finish_delivery(text_value: String) -> void:
	phase = "result"
	clock = 0
	if text_value.begins_with("SIX"):
		umpire.get_node("UpperBody/LeftArm").rotation.z = PI
		umpire.get_node("UpperBody/RightArm").rotation.z = PI
	deliveries += 1
	message.text = text_value
	update_score()

func update_score() -> void:
	score_label.text = ("%d / 6 balls   %d hits" % [deliveries, wickets]) if bowling_nets else ("%d / %d     %d.%d overs" % [score, wickets, deliveries / 6, deliveries % 6])

func reset() -> void:
	score = 0
	wickets = 0
	deliveries = 0
	phase = "ready"
	clock = 0
	swing_age = -10
	contact_checked = false
	hit = false
	follow_camera = false
	bat.rotation = Vector3.ZERO
	umpire.get_node("UpperBody/LeftArm").rotation = Vector3.ZERO
	umpire.get_node("UpperBody/RightArm").rotation = Vector3.ZERO
	bowler.position = Vector3(0.75, 0.04, -15)
	(bowler as CricketAthlete).idle_pose(0)
	ball.visible = false
	bounce_marker.visible = false
	action.disabled = false
	action.text = "BOWL"
	message.text = "Choose line, length and pace, then tap BOWL." if bowling_nets else "Fresh over. Tap BOWL when you are ready."
	refresh_net_controls()
	set_camera()
	(batsman as CricketAthlete).bat_pose(bat, -10, 0)
	update_score()

func smoke_test() -> void:
	set_physics_process(false)
	assert(batsman != null and bowler != null and umpire != null)
	assert(Engine.get_license_text().contains("Permission is hereby granted"))
	var stadium_count := 0
	for group in stadium_nodes:
		stadium_count += group.multimesh.instance_count
	assert(stadium_count == 504, "Stadium geometry missing")
	for i in range(6):
		act()
		delivery_x = 0
		act() # Early run-up swing must miss, not allow repeated swings.
		for step in range(650):
			_physics_process(1.0 / 120.0)
			if phase == "ready" or phase == "finished":
				break
	assert(phase == "finished" and deliveries == 6 and wickets == 6)
	act()
	assert(deliveries == 0 and phase == "ready" and not ball.visible)
	loft = true
	act()
	for step in range(3000):
		if phase == "delivery" and physics.position.z > 5.1 and swing_age < -5:
			act()
		_physics_process(1.0 / 120.0)
		if phase == "ready":
			break
	assert(hit and score == 6 and deliveries == 1, "Loft should clear rope on the full")
	reset()
	loft = false
	act()
	for step in range(3000):
		if phase == "delivery" and physics.position.z > 5.1 and swing_age < -5:
			act()
		_physics_process(1.0 / 120.0)
		if phase == "ready":
			break
	assert(hit and score == 4 and deliveries == 1, "Drive should bounce before boundary")
	reset()
	assert(deliveries == 0 and phase == "ready" and not ball.visible)
	act()
	delivery_x = 0.5
	for step in range(650):
		_physics_process(1.0 / 120.0)
		if phase == "ready":
			break
	assert(wickets == 0 and score == 0 and deliveries == 1, "A missed ball outside stumps is a dot, not a wicket")
	reset()
	print("PASS: scene, early swing, stumps, six-ball over, restart, loft six, bounced four, outside-stump dot")
	get_tree().quit()

func capture() -> void:
	if "--nets" in OS.get_cmdline_user_args():
		toggle_nets()
	if "--overview" in OS.get_cmdline_user_args():
		view = 1
		set_camera()
	if "--players" in OS.get_cmdline_user_args():
		camera.position = Vector3(3.5, 2.2, 5.1)
		camera.look_at(Vector3(0.55, 1.05, 8.6))
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/scene.png")
	get_tree().quit()

func choose_shot_or_line() -> void:
	if bowling_nets:
		if phase != "ready" and phase != "finished":
			return
		line_index = (line_index + 1) % NET_LINES.size()
	else:
		loft = not loft
	refresh_net_controls()

func choose_aim_or_length() -> void:
	if bowling_nets:
		if phase != "ready" and phase != "finished":
			return
		length_index = (length_index + 1) % NET_LENGTHS.size()
	else:
		aim = -0.45 if aim == 0 else (0.45 if aim < 0 else 0.0)
	refresh_net_controls()

func choose_pace() -> void:
	if phase == "ready" or phase == "finished":
		pace_index = (pace_index + 1) % NET_PACES.size()
	refresh_net_controls()

func refresh_net_controls() -> void:
	shot_button.text = ("LINE: " + ["LEFT", "MIDDLE", "RIGHT"][line_index]) if bowling_nets else ("SHOT: LOFT" if loft else "SHOT: DRIVE")
	aim_button.text = ("LENGTH: " + ["SHORT", "GOOD", "FULL"][length_index]) if bowling_nets else ("AIM: LEFT" if aim < 0 else ("AIM: RIGHT" if aim > 0 else "AIM: STRAIGHT"))
	pace_button.text = "PACE: %d km/h" % roundi(NET_PACES[pace_index] * 3.6)
	pace_button.visible = bowling_nets
	playback_button.visible = bowling_nets
	playback_button.text = "REPLAY: " + ("1×" if nets_playback == 1 else ("½×" if nets_playback == 0.5 else "¼×"))

func toggle_nets() -> void:
	bowling_nets = not bowling_nets
	nets.visible = bowling_nets
	batsman.visible = not bowling_nets
	umpire.visible = not bowling_nets
	for fielder in fielders:
		fielder.visible = not bowling_nets
	mode_button.text = "BATTING NETS" if bowling_nets else "BOWLING NETS"
	session_label.text = "BOWLING NETS • Action / line / length" if bowling_nets else "BOUNDARY NETS • 6 balls • Original prototype"
	hint_label.text = "CAMERA: behind bowler / side action • Straight-ball test • Spin physics not yet included" if bowling_nets else "Touch SWING as the ball reaches you • Boundaries only: 4 / 6 • No pitch marker"
	view = 0
	reset()

static func nets_velocity(origin: Vector3, landing: Vector3, forward_speed: float) -> Vector3:
	# Solve the ballistic release needed to land at the chosen point.
	# Speed control is forward pace, not measured celebrity release speed.
	var flight_time := (landing.z - origin.z) / forward_speed
	assert(flight_time > 0)
	return Vector3((landing.x - origin.x) / flight_time,
		(landing.y - origin.y + 0.5 * CricketBallPhysics.GRAVITY * flight_time * flight_time) / flight_time,
		forward_speed)

func nets_result(struck: bool) -> String:
	var bounce := physics.first_bounce_position
	return ("STUMPS HIT" if struck else "MISSED STUMPS") + " • Bounce %.1f m before stumps • Line %.2f m • Release %.2f m" % [10.06 - bounce.z, bounce.x, last_release.y]

func build_nets() -> void:
	nets = Node3D.new()
	nets.name = "BowlingNets"
	add_child(nets)
	nets.visible = false
	bounce_marker = cylinder(nets, 0.16, 0.008, Vector3.ZERO, GOLD)
	bounce_marker.visible = false
	var wires: Array[Transform3D] = []
	for side in [-1, 1]:
		for row in range(9):
			wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.009, 0.009, 29)), Vector3(side * 2.6, row * 0.4 + 0.06, -1.5)))
		for column in range(74):
			wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.009, 3.2, 0.009)), Vector3(side * 2.6, 1.66, -16 + column * 0.4)))
		for z in [-16, -8, 0, 8, 13]:
			cylinder(nets, 0.04, 3.3, Vector3(side * 2.6, 1.69, z), Color("38545c"))
	for row in range(9):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(5.2, 0.009, 0.009)), Vector3(0, row * 0.4 + 0.06, 13)))
	for column in range(14):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.009, 3.2, 0.009)), Vector3(-2.6 + column * 0.4, 1.66, 13)))
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	var unit := BoxMesh.new()
	unit.size = Vector3.ONE
	mesh.mesh = unit
	mesh.instance_count = wires.size()
	for index in range(wires.size()):
		mesh.set_instance_transform(index, wires[index])
	var fence := MultiMeshInstance3D.new()
	fence.multimesh = mesh
	fence.material_override = material(Color("44606a"))
	fence.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nets.add_child(fence)
