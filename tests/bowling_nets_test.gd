extends SceneTree
var failures := 0
func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)
func find_button(node: Node, title: String) -> Button:
	if node is Button and node.text == title:
		return node
	for child in node.get_children():
		var found := find_button(child, title)
		if found != null:
			return found
	return null
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	check(scene.nets.visible and scene.physics.net_enabled, "Nets-only scene and active net containment")
	check(scene.get_node_or_null("Bowler") == null and scene.get_node_or_null("Batsman") == null, "No players in environment-only scene")
	var cases := 0
	for line in range(3):
		for length in range(3):
			for pace in range(3):
				scene.reset()
				scene.line_index = line
				scene.length_index = length
				scene.pace_index = pace
				scene.action.pressed.emit()
				check(scene.action.disabled, "No second launch during delivery")
				var saved_line: int = scene.line_index
				scene.line_button.pressed.emit()
				check(scene.line_index == saved_line, "Line cannot change during delivery")
				for step in range(900):
					scene._physics_process(1.0 / 120)
					if scene.phase == "result":
						break
				check(scene.phase == "result" and scene.deliveries == 1, "One delivery outcome")
				var target := Vector3(scene.NET_LINES[line], CricketBallPhysics.GROUND, scene.NET_LENGTHS[length])
				check(scene.physics.first_bounce_position.distance_to(target) < 0.025, "Actual bounce matches configured line/length")
				check(scene.wickets == (1 if CricketBallPhysics.strikes_stumps(scene.last_crossing) else 0), "Stump outcome follows actual crossing")
				check(scene.last_launch_velocity.z == scene.NET_PACES[pace], "Selected pace used")
				check(scene.bounce_marker.visible, "Actual bounce marker appears")
				cases += 1
	scene.reset()
	for ball in range(6):
		scene.act()
		for step in range(900):
			scene._physics_process(1.0 / 120)
			if scene.phase == "ready" or scene.phase == "finished":
				break
	check(scene.phase == "finished" and scene.deliveries == 6, "Six launches finish session")
	scene.action.pressed.emit()
	check(scene.phase == "ready" and scene.deliveries == 0, "Again starts fresh session")
	scene.camera_button.pressed.emit()
	check(scene.view == 1 and scene.camera.position.x > 6, "Side camera wiring")
	scene.playback_button.pressed.emit()
	scene.act()
	scene._physics_process(0.1)
	check(absf(scene.clock - 0.05) < 0.001, "Half-speed playback")
	check(scene.phase == "approach", "Launch starts camera approach before ball release")
	find_button(scene, "RESET").pressed.emit()
	check(scene.phase == "ready" and not scene.ball.visible and not scene.action.disabled, "Reset active delivery")
	find_button(scene, "LICENCES").pressed.emit()
	check(paused, "Licences pause simulation")
	var popup := scene.get_child(scene.get_child_count() - 1) as AcceptDialog
	check(popup != null and popup.visible, "Licence popup")
	popup.confirmed.emit()
	await process_frame
	await process_frame
	check(not paused and not is_instance_valid(popup), "Licence closes and resumes")
	var rig := scene.camera as BowlingCameraRig
	rig.mode = 0
	rig.reset_view()
	var start := rig.position
	for step in range(120):
		var progress := step / 119.0
		rig.update_approach(Vector3(0.75, 0, lerpf(-15, -10.8, progress)), progress, 1.0 / 120)
	check(rig.position.z > start.z + 4, "Camera dollies with approach anchor")
	check(rig.fov < 49, "Camera tightens view around release")
	for step in range(120):
		rig.update_delivery(Vector3(0, 1, -10 + step * 0.15), Vector3(0, 0, 21), 1.0 / 120)
	check(rig.position.z > 0 and rig.position.y <= 2.95, "Camera follows ball within lane roof clearance")
	rig.drag(10000)
	check(absf(rig.orbit_yaw) <= 0.35, "Touch orbit clamped")
	for axis in [Vector3(20, 0, 0), Vector3(0, 0, 24), Vector3(0, 14, 0)]:
		var p := CricketBallPhysics.new()
		p.net_enabled = true
		p.launch(Vector3(0, 1.5, 0), axis)
		for step in range(600):
			p.advance(1.0 / 120)
			check(absf(p.position.x) <= CricketBallPhysics.NET_HALF_WIDTH - CricketBallPhysics.RADIUS + 0.001, "Side net contains ball")
			check(p.position.z <= CricketBallPhysics.NET_END - CricketBallPhysics.RADIUS + 0.001, "End net contains ball")
			check(p.position.y <= CricketBallPhysics.NET_TOP - CricketBallPhysics.RADIUS + 0.001, "Roof net contains ball")
		check(p.net_contacts > 0, "Actual net contact recorded")
	print("Bowling nets: 27 delivery combinations, containment, cameras, reset, playback and licences; %d failures" % failures)
	quit(1 if failures else 0)
