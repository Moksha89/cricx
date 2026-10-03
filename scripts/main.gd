extends Node3D

# Indoor nets only. No player, animation, stadium or batting logic is loaded.
const GOLD := Color("e9bb63")
const NET_LINES := [-0.60, 0.0, 0.60]
const NET_LENGTHS := [4.5, 6.8, 8.8]
const NET_PACES := [18.0, 21.0, 24.0]
var materials: Dictionary = {}
var physics := CricketBallPhysics.new()
var camera: BowlingCameraRig
var camera_button: Button
var ball: MeshInstance3D
var nets: Node3D
var bounce_marker: MeshInstance3D
var action: Button
var line_button: Button
var length_button: Button
var pace_button: Button
var playback_button: Button
var message: Label
var score_label: Label
var phase := "ready"
var clock := 0.0
var deliveries := 0
var wickets := 0
var line_index := 1
var length_index := 1
var pace_index := 1
var nets_playback := 1.0
var view := 0
var last_release := Vector3.ZERO
var last_crossing := Vector3.ZERO
var last_launch_velocity := Vector3.ZERO

func _ready() -> void:
	build_room()
	build_nets()
	physics.net_enabled = true
	ball = sphere(self, CricketBallPhysics.RADIUS, Vector3.ZERO, Color("b32f38"))
	ball.visible = false
	camera = BowlingCameraRig.new()
	camera.fov = 58
	add_child(camera)
	set_camera()
	build_ui()
	reset()
	if "--capture" in OS.get_cmdline_user_args():
		call_deferred("capture")

func build_room() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("ccd1d0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e4ebef")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-72, -24, 0)
	light.light_energy = 0.65
	light.shadow_enabled = true
	add_child(light)
	box(self, Vector3(20, 0.15, 42), Vector3(0, -0.08, -2), Color("385f52"))
	box(self, Vector3(3.05, 0.08, 22), Vector3(0, 0, 0), Color("89957f"))
	# Neutral indoor hall, original geometry. Open entrance behind the camera.
	box(self, Vector3(0.20, 7.8, 42), Vector3(-10, 3.9, -2), Color("bec7c5"))
	box(self, Vector3(0.20, 7.8, 42), Vector3(10, 3.9, -2), Color("bec7c5"))
	box(self, Vector3(20, 7.8, 0.20), Vector3(0, 3.9, 19), Color("bec7c5"))
	box(self, Vector3(20, 0.16, 42), Vector3(0, 7.8, -2), Color("aeb8b9"))
	for z in [-19, -12, -5, 2, 9, 16]:
		for x in [-7.5, 7.5]:
			box(self, Vector3(0.30, 7.5, 0.30), Vector3(x, 3.75, z), Color("e0e5e3"))
		box(self, Vector3(19.8, 0.18, 0.15), Vector3(0, 7.4, z), Color("d8dfdd"))
		box(self, Vector3(19.8, 0.12, 0.12), Vector3(0, 7.45, z + 2.8), Color("d8dfdd"))
		for x in [-4.5, 4.5]:
			box(self, Vector3(1.4, 0.045, 0.45), Vector3(x, 7.3, z), Color("f4f5e7"))
	for z in [-10.06, 10.06]:
		var popping: float = z - signf(z) * 1.22
		box(self, Vector3(3.66, 0.016, 0.05), Vector3(0, 0.054, popping), Color("eeeede"))
		box(self, Vector3(2.64, 0.016, 0.05), Vector3(0, 0.054, z), Color("eeeede"))
		for x in [-1.32, 1.32]:
			box(self, Vector3(0.04, 0.016, 2.44), Vector3(x, 0.054, z), Color("eeeede"))
	for z in [-10.06, 10.06]:
		for x in [-0.0953, 0.0, 0.0953]:
			cylinder(self, 0.019, CricketBallPhysics.STUMP_HEIGHT, Vector3(x, CricketBallPhysics.PITCH_LEVEL + CricketBallPhysics.STUMP_HEIGHT * 0.5, z), Color("e0bf7e"))
		box(self, Vector3(0.2286, 0.018, 0.04), Vector3(0, CricketBallPhysics.BAIL_TOP - 0.009, z), GOLD)

func set_camera() -> void:
	camera.mode = view
	camera.reset_view()
	if camera_button != null:
		camera_button.text = "CAM: " + ["FOLLOW", "SIDE", "FIXED"][view]

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
	top.offset_bottom = 80
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	top.add_child(row)
	row.add_child(label("CRICX  /  BOWLING NETS", 25, GOLD))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	score_label = label("0 / 6 balls   0 hits", 24)
	row.add_child(score_label)
	camera_button = button("CAM: FOLLOW", func(): view = (view + 1) % 3; set_camera())
	row.add_child(camera_button)
	row.add_child(button("LICENCES", show_licences))
	var bottom := PanelContainer.new()
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -130
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	bottom.add_child(column)
	message = label("Choose line, length and pace, then tap LAUNCH.", 20, GOLD)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(message)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 14)
	column.add_child(controls)
	controls.add_child(button("RESET", reset))
	line_button = button("LINE: MIDDLE", func(): if phase == "ready" or phase == "finished": line_index = (line_index + 1) % 3; refresh_controls())
	controls.add_child(line_button)
	length_button = button("LENGTH: GOOD", func(): if phase == "ready" or phase == "finished": length_index = (length_index + 1) % 3; refresh_controls())
	controls.add_child(length_button)
	pace_button = button("PACE: 76 km/h", func(): if phase == "ready" or phase == "finished": pace_index = (pace_index + 1) % 3; refresh_controls())
	controls.add_child(pace_button)
	playback_button = button("REPLAY: 1×", func(): nets_playback = 0.5 if nets_playback == 1 else (0.25 if nets_playback == 0.5 else 1.0); refresh_controls())
	controls.add_child(playback_button)
	action = button("LAUNCH", act)
	controls.add_child(action)
	var hint := label("Environment + straight-ball test • No player or bowling action • Gold spot = actual first bounce", 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

func refresh_controls() -> void:
	line_button.text = "LINE: " + ["LEFT", "MIDDLE", "RIGHT"][line_index]
	length_button.text = "LENGTH: " + ["SHORT", "GOOD", "FULL"][length_index]
	pace_button.text = "PACE: %d km/h" % roundi(NET_PACES[pace_index] * 3.6)
	playback_button.text = "REPLAY: " + ("1×" if nets_playback == 1 else ("½×" if nets_playback == 0.5 else "¼×"))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		act()

func _unhandled_input(event: InputEvent) -> void:
	if phase != "ready" or view != 0:
		return
	if event is InputEventScreenDrag:
		camera.drag(event.relative.x)
		camera.update_approach(Vector3(0.75, 0, -15), 0, 0.1)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		camera.drag(event.relative.x)
		camera.update_approach(Vector3(0.75, 0, -15), 0, 0.1)

func act() -> void:
	if phase == "finished":
		reset()
	elif phase == "ready":
		phase = "approach"
		clock = 0
		ball.visible = false
		bounce_marker.visible = false
		action.disabled = true
		message.text = "Camera approach preview — player anchor only."

func launch_ball() -> void:
	phase = "delivery"
	clock = 0
	last_release = Vector3(0.75, 2.0, -10.8)
	last_launch_velocity = nets_velocity(last_release, Vector3(NET_LINES[line_index], CricketBallPhysics.GROUND, NET_LENGTHS[length_index]), NET_PACES[pace_index])
	physics.launch(last_release, last_launch_velocity)
	ball.position = last_release
	ball.visible = true
	message.text = "Ball in flight — fixed launcher, no spin applied."

func _physics_process(delta: float) -> void:
	delta *= nets_playback
	clock += delta
	if phase == "approach":
		var progress := clampf(clock / 1.2, 0, 1)
		var anchor := Vector3(0.75, 0, lerpf(-15.0, -10.8, progress))
		camera.update_approach(anchor, progress, delta)
		if clock >= 1.2:
			launch_ball()
	elif phase == "delivery":
		var before := physics.position
		physics.advance(delta)
		ball.position = physics.position
		camera.update_delivery(physics.position, physics.velocity, delta)
		if physics.bounces > 0:
			bounce_marker.position = Vector3(physics.first_bounce_position.x, 0.06, physics.first_bounce_position.z)
			bounce_marker.visible = true
		if CricketBallPhysics.crosses_plane(before, physics.position, 10.06):
			last_crossing = CricketBallPhysics.at_plane(before, physics.position, 10.06)
			var struck := CricketBallPhysics.strikes_stumps(last_crossing)
			if struck:
				wickets += 1
				# Initial low-energy wicket response; bails are not simulated yet.
				physics.velocity.z = -absf(physics.velocity.z) * 0.12
				physics.velocity.x *= 0.45
			deliveries += 1
			phase = "result"
			clock = 0
			var bounce := physics.first_bounce_position
			message.text = ("STUMPS HIT" if struck else "MISSED") + " • Bounce %.1f m before stumps • Line %.2f m • Release %.2f m" % [10.06 - bounce.z, bounce.x, last_release.y]
			update_score()
	elif phase == "result":
		physics.advance(delta)
		ball.position = physics.position
		if clock < 1.4:
			return
		ball.visible = false
		action.disabled = false
		phase = "finished" if deliveries >= 6 else "ready"
		action.text = "AGAIN" if phase == "finished" else "LAUNCH"
		set_camera()

func reset() -> void:
	phase = "ready"
	clock = 0
	deliveries = 0
	wickets = 0
	ball.visible = false
	bounce_marker.visible = false
	action.disabled = false
	action.text = "LAUNCH"
	message.text = "Choose line, length and pace, then tap LAUNCH."
	refresh_controls()
	update_score()
	set_camera()

func update_score() -> void:
	score_label.text = "%d / 6 balls   %d hits" % [deliveries, wickets]

func capture() -> void:
	if "--side" in OS.get_cmdline_user_args():
		view = 1
		set_camera()
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/scene.png")
	get_tree().quit()

func material(color: Color) -> StandardMaterial3D:
	if materials.has(color):
		return materials[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if color == Color("bec7c5") or color == Color("385f52") or color == Color("89957f"):
		var noise := FastNoiseLite.new()
		noise.seed = 1947
		noise.frequency = 0.16
		noise.fractal_octaves = 3
		var gradient := Gradient.new()
		gradient.set_color(0, color.darkened(0.12))
		gradient.set_color(1, color.lightened(0.06))
		var texture := NoiseTexture2D.new()
		texture.width = 256
		texture.height = 256
		texture.seamless = true
		texture.noise = noise
		texture.color_ramp = gradient
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.7, 0.7, 0.7)
		m.albedo_texture = texture
		m.albedo_color = Color.WHITE
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

static func nets_velocity(origin: Vector3, landing: Vector3, forward_speed: float) -> Vector3:
	# Solve the ballistic release needed to land at the chosen point.
	# Speed control is forward pace, not measured celebrity release speed.
	var flight_time := (landing.z - origin.z) / forward_speed
	assert(flight_time > 0)
	return Vector3((landing.x - origin.x) / flight_time,
		(landing.y - origin.y + 0.5 * CricketBallPhysics.GRAVITY * flight_time * flight_time) / flight_time,
		forward_speed)

func build_nets() -> void:
	nets = Node3D.new()
	nets.name = "BowlingNets"
	add_child(nets)
	nets.visible = true
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
	for column in range(14):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.009, 0.009, 29)), Vector3(-2.6 + column * 0.4, 3.26, -1.5)))
	for column in range(74):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(5.2, 0.009, 0.009)), Vector3(0, 3.26, -16 + column * 0.4)))
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
