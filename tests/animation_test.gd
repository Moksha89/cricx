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
	var athlete := scene.bowler as CricketAthlete
	for step in range(133):
		var t := step / 120.0
		athlete.run_pose(t, minf(t / 1.1, 1))
		for side in [-1, 1]:
			var name_value := "LeftArm" if side < 0 else "RightArm"
			var parts: Array = athlete.joints[name_value]
			var elbow: Vector3 = parts[1].position * 2 - parts[2].position
			check(absf(elbow.length() - CricketAthlete.UPPER_ARM) < 0.001, "Upper arm length preserved through run-up")
			check(absf(elbow.distance_to(parts[2].position) - CricketAthlete.FOREARM) < 0.001, "Forearm length preserved through run-up")
			var leg_parts: Array = athlete.joints["LeftLeg" if side < 0 else "RightLeg"]
			check(leg_parts[2].position.y + 0.94 - 0.06 >= -0.002, "Foot stays above local ground")
	athlete.run_pose(1.1, 1)
	check(athlete.release_point().is_equal_approx(athlete.to_global(athlete.right_hand)), "Release origin follows hand")
	var batter := scene.batsman as CricketAthlete
	for step in range(80):
		var age := step / 120.0
		scene.bat.rotation.x = scene.swing_angle(age)
		batter.bat_pose(scene.bat, age, 0)
		for side in [-1, 1]:
			var name_value := "LeftArm" if side < 0 else "RightArm"
			var arm := batter.get_node("UpperBody/" + name_value) as Node3D
			var hand: Vector3 = batter.to_local(arm.to_global(batter.joints[name_value][2].position))
			var grip: Vector3 = scene.bat.position + scene.bat.basis * Vector3(0, 0.12 if side < 0 else 0.02, 0)
			check(hand.distance_to(grip) < 0.015, "Both hands stay on bat through swing")
	scene.act()
	for step in range(200):
		scene._physics_process(1.0 / 120)
		if scene.phase == "delivery":
			check(scene.physics.position.distance_to(athlete.release_point()) < 0.001, "Actual delivery launches from animated hand")
			break
	check(scene.phase == "delivery", "Run-up reaches release")
	var planted: Vector3
	for step in range(25):
		var t := OffspinAction.FRONT_PLANT_TIME + step / 120.0
		athlete.position = Vector3(0, 0.04, -15 + OffspinAction.travel(t))
		athlete.offspin_pose(t)
		var shoe := athlete.joints["LeftLeg"][2] as MeshInstance3D
		if step == 0:
			planted = shoe.global_position
		check(shoe.global_position.distance_to(planted) < 0.002, "Front foot stays planted through release")
	athlete.offspin_pose(OffspinAction.RELEASE_TIME)
	var right_parts: Array = athlete.joints["RightArm"]
	var release_elbow: Vector3 = right_parts[1].position * 2 - right_parts[2].position
	var hand: Vector3 = right_parts[2].position
	var elbow_angle := rad_to_deg((-release_elbow).angle_to(hand - release_elbow))
	check(elbow_angle > 170, "Bowling arm is near straight at release")
	check(absf(athlete.upper_body.rotation.z) > 0.20, "Release includes lateral body lean")
	print("Animation: arm lengths, feet, two-hand grip and delivery release; %d failures" % failures)
	quit(1 if failures else 0)
