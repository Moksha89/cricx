extends SceneTree
var failures := 0
func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.mode_button.pressed.emit()
	check(scene.bowling_nets and scene.nets.visible and not scene.batsman.visible, "Mode control enters isolated bowling nets")
	check(scene.camera.position.z < -15 and scene.pace_button.visible, "Bowler camera and pace control")
	var cases := 0
	for line in range(3):
		for length in range(3):
			for pace in range(3):
				scene.reset()
				scene.line_index = line
				scene.length_index = length
				scene.pace_index = pace
				scene.act()
				check(scene.action.disabled, "No swing control in bowling nets")
				var saved_line: int = scene.line_index
				scene.choose_shot_or_line()
				check(scene.line_index == saved_line, "Settings cannot change during an active delivery")
				for step in range(900):
					scene._physics_process(1.0 / 120)
					if scene.phase == "result":
						break
				check(scene.phase == "result" and scene.deliveries == 1 and not scene.hit, "One bowling outcome without batting collision")
				var target := Vector3(scene.NET_LINES[line], CricketBallPhysics.GROUND, scene.NET_LENGTHS[length])
				check(scene.physics.first_bounce_position.distance_to(target) < 0.025, "Actual first bounce matches configured line and length")
				check(scene.wickets == (1 if CricketBallPhysics.strikes_stumps(scene.last_crossing) else 0), "Stump result follows actual crossing")
				check(scene.last_launch_velocity.z == scene.NET_PACES[pace], "Selected pace is used")
				check(scene.last_release.y > 1.8 and scene.last_release.y < 2.2, "Delivery starts at animated release height")
				cases += 1
	scene.reset()
	for ball in range(6):
		scene.act()
		for step in range(900):
			scene._physics_process(1.0 / 120)
			if scene.phase == "ready" or scene.phase == "finished":
				break
	check(scene.phase == "finished" and scene.deliveries == 6, "Six bowling deliveries finish nets session")
	scene.mode_button.pressed.emit()
	check(not scene.bowling_nets and not scene.nets.visible and scene.batsman.visible and scene.phase == "ready", "Return to batting resets session")
	check(scene.shot_button.text.begins_with("SHOT") and not scene.pace_button.visible, "Batting controls restored")
	scene.toggle_nets()
	scene.playback_button.pressed.emit()
	check(scene.nets_playback == 0.5, "Slow playback control")
	scene.act()
	for step in range(120):
		scene._physics_process(1.0 / 120)
	check(scene.phase == "runup" and absf(scene.clock - 0.5) < 0.001, "Slow playback scales action time")
	scene.reset()
	scene.nets_playback = 1.0
	scene.act()
	scene.reset()
	check(scene.phase == "ready" and not scene.ball.visible and not scene.action.disabled, "Active bowling restart")
	print("Bowling nets: %d line/length/pace combinations, six-ball session, switching and restart; %d failures" % [cases, failures])
	quit(1 if failures else 0)
