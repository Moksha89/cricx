extends Node3D

# Outdoor bowling practice: rigged bowler, touch controls and SI ball simulation.
const GOLD := Color("e9bb63")
const NET_LINES := [-0.60, 0.0, 0.60]
const NET_LENGTHS := [1.0, 4.3, 7.8]
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
var far_bails: Array[RigidBody3D] = []
var bowler: RiggedBowler
var last_release := Vector3.ZERO
var last_crossing := Vector3.ZERO
var last_launch_velocity := Vector3.ZERO

func _ready() -> void:
	build_room()
	build_nets()
	bowler = RiggedBowler.new()
	add_child(bowler)
	bowler.setup()
	bowler.position = Vector3(0.75, 0.04, -15)
	physics.net_enabled = true
	ball = sphere(self, CricketBallPhysics.RADIUS, Vector3.ZERO, Color("b32f38"))
	ball.visible = false
	camera = BowlingCameraRig.new()
	camera.fov = 58
	add_child(camera)
	set_camera()
	build_ui()
	build_target()
	bowler.pose(1.6)
	release_local = bowler.release_point()-bowler.position
	bowler.pose(0)
	reset()
	refresh_preview()
	if "--capture" in OS.get_cmdline_user_args():
		call_deferred("capture")
	if OS.has_feature("android") and OS.is_debug_build() and FileAccess.file_exists("user://run_qa"):
		call_deferred("android_qa")

func build_room() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("6e9eb7")
	sky_material.sky_horizon_color = Color("d3ddd6")
	sky_material.ground_horizon_color = Color("b7c5b3")
	sky_material.ground_bottom_color = Color("60804b")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d2e1e4")
	environment.ambient_light_energy = 0.30
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -42, 0)
	light.light_color = Color("fff0ce")
	light.light_energy = 0.65
	light.shadow_enabled = true
	add_child(light)
	var terrain := box(self, Vector3(70, 0.12, 75), Vector3(0, -0.035, 0), Color("475c32"))
	var turf_material := ShaderMaterial.new()
	turf_material.shader = load("res://assets/ground.gdshader")
	turf_material.set_shader_parameter("turf",true)
	terrain.material_override = turf_material
	var pitch_surface := box(self, Vector3(3.05, 0.08, 32), Vector3(0, 0, -2), Color("a98b65"))
	var pitch_material := ShaderMaterial.new()
	pitch_material.shader = load("res://assets/ground.gdshader")
	pitch_material.set_shader_parameter("turf",false)
	pitch_surface.material_override = pitch_material
	var random := RandomNumberGenerator.new()
	random.seed = 31
	# Small tufts are instanced geometry, not a painted background.
	var tuft := ArrayMesh.new()
	var vertices := PackedVector3Array([Vector3(-0.025,0,0), Vector3(0.02,0,0), Vector3(0.012,0.045,0.01), Vector3(0,0,-0.025),Vector3(0,0,0.025),Vector3(0.01,0.04,0.012)])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK,Vector3.BACK,Vector3.BACK,Vector3.RIGHT,Vector3.RIGHT,Vector3.RIGHT])
	tuft.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var grass := MultiMesh.new()
	grass.transform_format = MultiMesh.TRANSFORM_3D
	grass.mesh = tuft
	grass.instance_count = 7500
	for i in range(grass.instance_count):
		var x := random.randf_range(1.65, 19) * (-1 if i % 2 == 0 else 1)
		var z := random.randf_range(-22, 28)
		var scale_value := random.randf_range(0.6, 1.5)
		grass.set_instance_transform(i, Transform3D(Basis(Vector3.UP, random.randf_range(0, TAU)).scaled(Vector3.ONE * scale_value), Vector3(x, 0.04, z)))
	var grass_node := MultiMeshInstance3D.new()
	grass_node.multimesh = grass
	grass_node.material_override = material(Color("526c34"))
	(grass_node.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(grass_node)
	for i in range(18):
		var x := random.randf_range(8, 24) * (-1 if i % 2 == 0 else 1)
		var z := random.randf_range(12, 30)
		var height := random.randf_range(4, 7)
		cylinder(self, 0.16, height, Vector3(x, height * 0.5, z), Color("655943"))
		for crown in range(14):
			var canopy := sphere(self, random.randf_range(0.55, 1.1), Vector3(x + random.randf_range(-1.5,1.5), height + random.randf_range(-0.5,1), z + random.randf_range(-1.5,1.5)), Color("597343") if crown % 2 else Color("708650"))
			canopy.scale = Vector3(1.2, random.randf_range(0.7,1.3), 1)
	for z in [-10.06, 10.06]:
		var popping: float = z - signf(z) * 1.22
		box(self, Vector3(3.66, 0.016, 0.045), Vector3(0, 0.054, popping), Color("f0ede0"))
		box(self, Vector3(2.64, 0.016, 0.045), Vector3(0, 0.054, z), Color("f0ede0"))
		for x in [-1.32, 1.32]:
			box(self, Vector3(0.04, 0.016, 2.44), Vector3(x, 0.054, z), Color("f0ede0"))
		for x in [-0.0953, 0.0, 0.0953]:
			cylinder(self, 0.019, CricketBallPhysics.STUMP_HEIGHT, Vector3(x, CricketBallPhysics.PITCH_LEVEL + CricketBallPhysics.STUMP_HEIGHT * 0.5, z), Color("deb77e"))
		for side in [-1,1]:
			if z>0:
				var bail := RigidBody3D.new()
				bail.mass=0.012
				bail.freeze=true
				bail.collision_layer=2
				bail.collision_mask=1
				add_child(bail)
				bail.position=Vector3(side*0.0535,CricketBallPhysics.BAIL_TOP-0.006,z)
				box(bail,Vector3(0.107,0.012,0.035),Vector3.ZERO,GOLD)
				var collision:=CollisionShape3D.new()
				var shape:=BoxShape3D.new()
				shape.size=Vector3(0.107,0.012,0.035)
				collision.shape=shape
				bail.add_child(collision)
				far_bails.append(bail)
			else:
				box(self,Vector3(0.107,0.012,0.035),Vector3(side*0.0535,CricketBallPhysics.BAIL_TOP-0.006,z),GOLD)
	var floor_body:=StaticBody3D.new()
	floor_body.collision_layer=1
	floor_body.collision_mask=2
	var floor_shape:=CollisionShape3D.new()
	var floor_box:=BoxShape3D.new()
	floor_box.size=Vector3(70,0.12,75)
	floor_shape.shape=floor_box
	floor_shape.position=Vector3(0,-0.02,0)
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	# Practice screens and equipment give the lane a clear purpose.
	box(self, Vector3(5.10, 1.65, 0.025), Vector3(0, 0.88, 12.94), Color("193e35"))
	var sign_label := Label3D.new()
	sign_label.text = "PRACTICE MAKES
PROGRESS"
	sign_label.font_size = 72
	sign_label.pixel_size = 0.006
	sign_label.position = Vector3(0, 1.05, 12.90)
	sign_label.rotation.y = PI
	sign_label.modulate = Color("bbc8b7")
	add_child(sign_label)
	for side in [-1, 1]:
		box(self, Vector3(0.025, 1.6, 3.4), Vector3(side * 2.57, 0.90, 3.0), Color("21463b"))
		box(self, Vector3(0.50, 0.45, 0.65), Vector3(side * 2.13, 0.23, 8.5), Color("253b36"))
		cylinder(self, 0.065, 0.26, Vector3(side * 2.04, 0.18, 7.7), Color("6198b9"))

func set_camera() -> void:
	camera.mode = view
	camera.reset_view()
	if camera_button != null:
		camera_button.text = ["◉", "◐", "◎"][view]

const LIME := Color("bdf348")
var safe_root: Control
var speed_control: TouchSpeedSlider
var speed_label: Label
var target_pill: Label
var lock_button: Button
var delivery_buttons: Array[Button] = []
var selected_delivery := 1
var selected_speed := 132.0
var left_handed := false
var target_locked := false
var target_point := Vector3(0, CricketBallPhysics.GROUND, 4.3)
var target_ring: Node3D
var preview_mesh: MeshInstance3D
var preview_velocity := Vector3.ZERO
var release_local := Vector3.ZERO
var target_owner := -1
var mouse_target := false
var refresh_pending := false
var bowl_control: SwipeBowlControl

func panel_style(fill: Color = Color(0.055,0.16,0.12,0.92), edge: Color = Color("466451"), radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func at_panel(rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", panel_style())
	safe_root.add_child(panel)
	return panel

func ui_button(text_value: String, parent: Control, rect: Rect2, callback: Callable) -> Button:
	var control := Button.new()
	control.text = text_value
	control.position = rect.position
	control.size = rect.size
	control.add_theme_font_size_override("font_size", 18)
	control.add_theme_stylebox_override("normal", panel_style())
	control.add_theme_stylebox_override("hover", panel_style(Color("264c37")))
	control.add_theme_stylebox_override("pressed", panel_style(LIME))
	control.add_theme_color_override("font_pressed_color", Color("142b20"))
	control.pressed.connect(callback)
	parent.add_child(control)
	return control

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	safe_root = Control.new()
	layer.add_child(safe_root)
	safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_button("‹", safe_root, Rect2(16,14,48,44), show_settings)
	var heading := label("BOWLING NETS", 25)
	heading.position = Vector2(76,21)
	safe_root.add_child(heading)
	var net_panel := at_panel(Rect2(546,14,188,44))
	var net_title := label("‹     NET 01     ›", 20)
	net_title.position = Vector2(18,9)
	net_panel.add_child(net_title)
	var counter_panel := at_panel(Rect2(1034,14,166,44))
	score_label = label("BALL  1 / 6", 20)
	score_label.position = Vector2(18,9)
	counter_panel.add_child(score_label)
	ui_button("⚙", safe_root, Rect2(1212,14,50,44), show_settings)
	var speed_panel := at_panel(Rect2(16,100,94,380))
	speed_control = TouchSpeedSlider.new()
	speed_control.size = Vector2(94,380)
	speed_panel.add_child(speed_control)
	var speed_title := label("SPEED", 18)
	speed_title.position = Vector2(18,12)
	speed_panel.add_child(speed_title)
	speed_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_label = label("132", 38, LIME)
	speed_label.position = Vector2(16,35)
	speed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_panel.add_child(speed_label)
	var units := label("km/h", 17)
	units.position = Vector2(21,78)
	units.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_panel.add_child(units)
	speed_control.changed.connect(func(value: float):
		if phase == "ready" or phase == "finished":
			selected_speed = value
			speed_label.text = str(int(value))
			request_preview())
	var types := at_panel(Rect2(1040,78,222,374))
	var types_title := label("DELIVERY TYPE", 19)
	types_title.position = Vector2(18,12)
	types.add_child(types_title)
	for kind in range(8):
		var slot := Button.new()
		slot.position = Vector2(12 + (kind % 2) * 102, 48 + (kind / 2) * 78)
		slot.size = Vector2(96,72)
		slot.add_theme_stylebox_override("normal", panel_style(Color("17372b"), Color("617962"), 10))
		slot.add_theme_stylebox_override("hover", panel_style(Color("32563b")))
		slot.pressed.connect(select_delivery.bind(kind))
		types.add_child(slot)
		var icon := DeliveryIcon.new()
		icon.kind = kind
		icon.position = Vector2(28,2)
		icon.size = Vector2(40,40)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		var name_label := label(DeliverySolver.NAMES[kind], 15)
		name_label.position = Vector2(0,46)
		name_label.size.x = 96
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(name_label)
		delivery_buttons.append(slot)
	bowl_control = SwipeBowlControl.new()
	bowl_control.position = Vector2(1070,500)
	bowl_control.size = Vector2(168,168)
	safe_root.add_child(bowl_control)
	bowl_control.bowled.connect(act)
	var swipe_hint := label("SWIPE ↑ TO BOWL", 16)
	swipe_hint.position = Vector2(1070,673)
	safe_root.add_child(swipe_hint)
	camera_button = ui_button("◉", safe_root, Rect2(22,636,54,54), cycle_camera)
	camera_button.tooltip_text = "Follow / side / fixed camera"
	var status := at_panel(Rect2(397,656,486,46))
	target_pill = label("MIDDLE  •  GOOD LENGTH", 17)
	target_pill.position = Vector2(18,13)
	status.add_child(target_pill)
	lock_button = ui_button("LOCK", status, Rect2(360,5,116,36), toggle_lock)
	message = label("Drag the target. Swipe BOWL to deliver.", 17)
	message.position = Vector2(350,610)
	message.size = Vector2(580,36)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	safe_root.add_child(message)
	# Settings-only controls retain automated/keyboard accessibility without a bottom toolbar.
	action = Button.new()
	action.pressed.connect(act)
	action.visible = false
	safe_root.add_child(action)
	line_button = Button.new()
	line_button.pressed.connect(func(): if phase == "ready": line_index = (line_index+1)%3; target_point.x=NET_LINES[line_index]; request_preview())
	line_button.visible = false
	safe_root.add_child(line_button)
	length_button = Button.new()
	length_button.visible = false
	safe_root.add_child(length_button)
	pace_button = Button.new()
	pace_button.visible = false
	safe_root.add_child(pace_button)
	playback_button = Button.new()
	playback_button.visible = false
	playback_button.pressed.connect(func(): nets_playback = 0.5 if nets_playback==1 else 1.0)
	safe_root.add_child(playback_button)
	refresh_controls()
	apply_safe_area()

func apply_safe_area() -> void:
	if not OS.has_feature("android"):
		return
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.x > 0 and screen.y > 0:
		var margin := Vector2(safe.position) / Vector2(screen) * get_viewport().get_visible_rect().size
		var available := Vector2(safe.size) / Vector2(screen)
		safe_root.position = margin
		safe_root.scale = available

func cycle_camera() -> void:
	view = (view + 1) % 3
	set_camera()

func toggle_lock() -> void:
	target_locked = not target_locked
	lock_button.text = "LOCKED" if target_locked else "LOCK"
	lock_button.add_theme_stylebox_override("normal", panel_style(LIME if target_locked else Color("17372b")))
	lock_button.add_theme_color_override("font_color", Color("193323") if target_locked else Color.WHITE)
	target_owner = -1

func select_delivery(kind: int) -> void:
	if phase != "ready" and phase != "finished":
		return
	selected_delivery = kind
	speed_control.maximum = 110 if kind == 5 else 160
	selected_speed = minf(selected_speed, speed_control.maximum)
	speed_control.value = selected_speed
	speed_control.queue_redraw()
	speed_label.text = str(int(selected_speed))
	refresh_controls()
	request_preview()

func refresh_controls() -> void:
	for kind in range(delivery_buttons.size()):
		var selected := kind == selected_delivery
		delivery_buttons[kind].add_theme_stylebox_override("normal", panel_style(LIME if selected else Color("17372b"), Color("617962"), 10))
		var icon := delivery_buttons[kind].get_child(0) as DeliveryIcon
		icon.ink = Color("17372b") if selected else Color("e4eee3")
		icon.queue_redraw()
		var text_label := delivery_buttons[kind].get_child(1) as Label
		text_label.add_theme_color_override("font_color", Color("17372b") if selected else Color.WHITE)
	if target_pill != null:
		var distance := 10.06-target_point.z
		var line := "MIDDLE" if absf(target_point.x)<0.18 else ("OFF SIDE" if (target_point.x<0) != left_handed else "LEG SIDE")
		var length_value := "SHORT" if distance>8 else ("GOOD LENGTH" if distance>4 else ("FULL" if distance>1.5 else "YORKER"))
		target_pill.text = line + "  •  " + length_value

func show_settings() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Practice settings"
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog)
	var rows := VBoxContainer.new()
	dialog.add_child(rows)
	var controls := [button("NEW OVER / RESET", func(): reset(); dialog.hide()), button("BATTER: " + ("LEFT" if left_handed else "RIGHT"), func(): set_handedness(); dialog.hide()), button("PLAYBACK: " + ("1×" if nets_playback==1 else "½×"), func(): nets_playback=0.5 if nets_playback==1 else 1.0; dialog.hide()), button("LICENCES", func(): dialog.hide(); show_licences())]
	for control in controls:
		rows.add_child(control)
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			get_tree().paused = false
			dialog.queue_free())
	get_tree().paused = true
	dialog.popup_centered(Vector2i(340,330))

func build_target() -> void:
	target_ring = Node3D.new()
	add_child(target_ring)
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.61
	mesh.outer_radius = 0.68
	mesh.rings = 32
	mesh.ring_segments = 8
	ring.mesh = mesh
	var glow := StandardMaterial3D.new()
	glow.albedo_color = LIME
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = glow
	target_ring.add_child(ring)
	for axis in [Vector3(0.30,0.012,0.035),Vector3(0.035,0.012,0.30)]:
		var cross_mesh := box(target_ring,axis,Vector3.ZERO,LIME)
		cross_mesh.material_override = glow
	preview_mesh = MeshInstance3D.new()
	preview_mesh.material_override = glow
	add_child(preview_mesh)

func pitch_point(screen_point: Vector2) -> Variant:
	return Plane(Vector3.UP, CricketBallPhysics.PITCH_LEVEL + 0.015).intersects_ray(camera.project_ray_origin(screen_point),camera.project_ray_normal(screen_point))

func drag_target(screen_point: Vector2) -> void:
	var point_value: Variant = pitch_point(screen_point)
	if point_value != null:
		target_point = Vector3(clampf(point_value.x,-1.15,1.15),CricketBallPhysics.GROUND,clampf(point_value.z,-0.5,9.0))
		request_preview()

func request_preview() -> void:
	refresh_controls()
	if not refresh_pending:
		refresh_pending = true
		call_deferred("refresh_preview")

func refresh_preview() -> void:
	refresh_pending = false
	if preview_mesh == null:
		return
	var origin := Vector3(0.75,0.04,-10.8) + release_local
	preview_velocity = DeliverySolver.solve(origin,target_point,selected_speed,selected_delivery,left_handed)
	var simulation := CricketBallPhysics.new()
	DeliverySolver.configure(simulation,selected_delivery,left_handed,target_point.z-origin.z)
	simulation.launch(origin,preview_velocity)
	var path := ImmediateMesh.new()
	path.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for step in range(180):
		path.surface_add_vertex(simulation.position)
		simulation.advance(1.0/120)
		if simulation.bounces>0:
			path.surface_add_vertex(simulation.first_bounce_position)
			break
	path.surface_end()
	preview_mesh.mesh = path
	target_ring.position = Vector3(target_point.x,0.063,target_point.z)
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		act()

func _unhandled_input(event: InputEvent) -> void:
	if phase != "ready" or target_locked:
		return
	if event is InputEventScreenTouch:
		if event.pressed and target_owner<0:
			target_owner = event.index
			drag_target(event.position)
		elif not event.pressed and event.index==target_owner:
			target_owner=-1
	elif event is InputEventScreenDrag and event.index==target_owner:
		drag_target(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		mouse_target=event.pressed
		if mouse_target:
			drag_target(event.position)
	elif event is InputEventMouseMotion and mouse_target:
		drag_target(event.position)

func act() -> void:
	if phase == "finished":
		reset()
	if phase == "ready":
		phase = "approach"
		reset_bails()
		clock = 0
		ball.visible = false
		bounce_marker.visible = false
		action.disabled = true
		bowl_control.disabled = true
		bowl_control.queue_redraw()
		speed_control.enabled = false
		message.text = "Watch the approach and release."

func launch_ball() -> void:
	phase = "delivery"
	clock = 0
	last_release = bowler.release_point()
	last_launch_velocity = DeliverySolver.solve(last_release,target_point,selected_speed,selected_delivery,left_handed)
	DeliverySolver.configure(physics,selected_delivery,left_handed,target_point.z-last_release.z)
	physics.launch(last_release, last_launch_velocity)
	ball.position = last_release
	ball.visible = true
	preview_mesh.visible = false
	target_ring.visible = false
	message.text = DeliverySolver.NAMES[selected_delivery] + " • %.0f km/h" % (last_launch_velocity.length()*3.6)

func _physics_process(delta: float) -> void:
	delta *= nets_playback
	clock += delta
	if phase == "ready" or phase == "finished":
		bowler.idle(delta)
		ball.position = bowler.release_point()
	if phase == "approach":
		var progress := clampf(clock / 1.2, 0, 1)
		var anchor := Vector3(0.75, 0.04, RiggedBowler.approach_z(progress))
		bowler.position = anchor
		bowler.pose(progress * 1.6)
		ball.visible = true
		ball.position = bowler.release_point()
		camera.update_approach(anchor, progress, delta)
		if clock >= 1.2:
			launch_ball()
	elif phase == "delivery":
		var before := physics.position
		bowler.pose(1.6 + clock)
		physics.advance(delta)
		ball.position = physics.position
		ball.quaternion = physics.orientation
		camera.update_delivery(physics.position, physics.velocity, delta)
		if physics.bounces > 0:
			bounce_marker.position = Vector3(physics.first_bounce_position.x, 0.06, physics.first_bounce_position.z)
			bounce_marker.visible = true
		if CricketBallPhysics.crosses_plane(before, physics.position, 10.06):
			last_crossing = CricketBallPhysics.at_plane(before, physics.position, 10.06)
			var struck := CricketBallPhysics.strikes_stumps(last_crossing)
			if struck:
				wickets += 1
				knock_bails()
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
		ball.visible = true
		action.disabled = false
		bowl_control.disabled = false
		bowl_control.queue_redraw()
		speed_control.enabled = true
		preview_mesh.visible = true
		target_ring.visible = true
		phase = "finished" if deliveries >= 6 else "ready"
		action.text = "AGAIN" if phase == "finished" else "LAUNCH"
		bowler.position = Vector3(0.75, 0.04, -15)
		bowler.pose(0)
		ball.position = bowler.release_point()
		set_camera()

func reset() -> void:
	phase = "ready"
	reset_bails()
	bowler.position = Vector3(0.75, 0.04, -15)
	bowler.pose(0)
	clock = 0
	deliveries = 0
	wickets = 0
	ball.visible = true
	ball.position = bowler.release_point()
	bounce_marker.visible = false
	action.disabled = false
	bowl_control.disabled = false
	bowl_control.queue_redraw()
	speed_control.enabled = true
	preview_mesh.visible = true
	target_ring.visible = true
	action.text = "LAUNCH"
	message.text = "Drag line & length. Swipe upward on BOWL."
	refresh_controls()
	update_score()
	set_camera()

func update_score() -> void:
	score_label.text = "BALL  %d / 6" % mini(deliveries+1,6)

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
	if color == Color("475c32") or color == Color("a98b65"):
		var noise := FastNoiseLite.new()
		noise.seed = 1947
		noise.frequency = 0.24
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
		m.uv1_scale = Vector3(1.2, 1.2, 1.2)
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
		for row in range(17):
			wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.003, 0.003, 29)), Vector3(side * 2.6, row * 0.2 + 0.06, -1.5)))
		for column in range(146):
			wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.003, 3.2, 0.003)), Vector3(side * 2.6, 1.66, -16 + column * 0.2)))
		for z in [-16, -8, 0, 8, 13]:
			cylinder(nets, 0.04, 3.3, Vector3(side * 2.6, 1.69, z), Color("173d33"))
	for column in range(27):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.003, 0.003, 29)), Vector3(-2.6 + column * 0.2, 3.26, -1.5)))
	for column in range(146):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(5.2, 0.003, 0.003)), Vector3(0, 3.26, -16 + column * 0.2)))
	for row in range(17):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(5.2, 0.003, 0.003)), Vector3(0, row * 0.2 + 0.06, 13)))
	for column in range(27):
		wires.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.003, 3.2, 0.003)), Vector3(-2.6 + column * 0.2, 1.66, 13)))
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
	fence.material_override = material(Color("244e40"))
	fence.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nets.add_child(fence)

func android_qa() -> void:
	var result := GameplayChecks.run(self)
	var output := FileAccess.open("user://qa_report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result))
	output.close()
	DirAccess.remove_absolute("user://run_qa")
	print("ANDROID_QA: "+JSON.stringify(result))

func knock_bails() -> void:
	for index in range(far_bails.size()):
		var bail:=far_bails[index]
		bail.freeze=false
		bail.linear_velocity=Vector3(-0.6 if index==0 else 0.6,1.2,0.8)
		bail.angular_velocity=Vector3(5,2,4)

func reset_bails() -> void:
	for index in range(far_bails.size()):
		var bail:=far_bails[index]
		bail.freeze=true
		bail.position=Vector3(-0.0535 if index==0 else 0.0535,CricketBallPhysics.BAIL_TOP-0.006,10.06)
		bail.rotation=Vector3.ZERO
		bail.linear_velocity=Vector3.ZERO
		bail.angular_velocity=Vector3.ZERO

func set_handedness() -> void:
	if phase=="ready":
		left_handed=not left_handed
		request_preview()

var inspect_age := 0.0
func _process(delta: float) -> void:
	inspect_age += delta
	if inspect_age<1.0: return
	inspect_age=0.0
	if OS.is_debug_build() and FileAccess.file_exists("user://inspect_state"):
		var output := FileAccess.open("user://state.json",FileAccess.WRITE)
		output.store_string(JSON.stringify({"phase":phase,"speed":selected_speed,"delivery":selected_delivery,"target":[target_point.x,target_point.z],"locked":target_locked,"camera":view,"balls":deliveries}))
		output.close()
