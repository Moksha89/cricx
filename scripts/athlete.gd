class_name CricketAthlete
extends Node3D

# Original articulated mesh athlete. All dimensions are metres.
# Two-link IK preserves limb lengths; this is procedural animation, not motion capture.
const UPPER_ARM := 0.30
const FOREARM := 0.29
var joints: Dictionary = {}
var skin := Color("b47b59")
var kit: Color
var padded := false
var make_material: Callable
var chest: MeshInstance3D
var head: Node3D
var right_hand := Vector3.ZERO
var upper_body: Node3D

func mesh_part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = make_material.call(color)
	node.position = pos
	parent.add_child(node)
	return node

func oval(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var node := mesh_part(parent, mesh, color, pos)
	node.scale = size
	return node

func block(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_part(parent, mesh, color, pos)

func build(color: Color, helmet: bool, material_factory: Callable) -> void:
	kit = color
	padded = helmet
	make_material = material_factory
	chest = oval(self, Vector3(0.48, 0.65, 0.29), Vector3(0, 1.25, 0), kit)
	oval(self, Vector3(0.35, 0.23, 0.27), Vector3(0, 0.96, 0), kit.darkened(0.12))
	# Collar, shirt panels and waistband give readable kit detail at gameplay distance.
	block(self, Vector3(0.11, 0.045, 0.30), Vector3(0, 1.52, 0), Color.WHITE)
	block(self, Vector3(0.35, 0.035, 0.28), Vector3(0, 0.99, 0), Color("253249"))
	for side in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "LeftArm" if side < 0 else "RightArm"
		arm.position = Vector3(side * 0.23, 1.47, 0)
		add_child(arm)
		var pieces: Array[MeshInstance3D] = []
		pieces.append(oval(arm, Vector3.ONE, Vector3.ZERO, kit))
		pieces.append(oval(arm, Vector3.ONE, Vector3.ZERO, skin))
		pieces.append(oval(arm, Vector3(0.10, 0.12, 0.085), Vector3.ZERO, Color("ede8dc") if padded else skin))
		joints[arm.name] = pieces
		var leg := Node3D.new()
		leg.name = "LeftLeg" if side < 0 else "RightLeg"
		leg.position = Vector3(side * 0.13, 0.94, 0)
		add_child(leg)
		pieces = []
		pieces.append(oval(leg, Vector3.ONE, Vector3.ZERO, kit.darkened(0.10)))
		pieces.append(oval(leg, Vector3.ONE, Vector3.ZERO, kit.darkened(0.10)))
		pieces.append(oval(leg, Vector3(0.18, 0.12, 0.31), Vector3.ZERO, Color("f0f2eb")))
		if padded:
			var pad := oval(leg, Vector3(0.19, 0.48, 0.13), Vector3.ZERO, Color("eee6d1"))
			pieces.append(pad)
		joints[leg.name] = pieces
	head = Node3D.new()
	head.position = Vector3(0, 1.66, 0)
	add_child(head)
	oval(head, Vector3(0.15, 0.17, 0.15), Vector3.ZERO, skin)
	oval(head, Vector3(0.29, 0.36, 0.28), Vector3(0, 0.15, 0), skin)
	oval(head, Vector3(0.05, 0.08, 0.065), Vector3(0, 0.14, 0.143), skin)
	for side in [-1, 1]:
		oval(head, Vector3(0.044, 0.026, 0.02), Vector3(side * 0.057, 0.20, 0.128), Color("22272b"))
		oval(head, Vector3(0.045, 0.08, 0.04), Vector3(side * 0.147, 0.15, 0), skin)
	block(head, Vector3(0.075, 0.014, 0.02), Vector3(0, 0.063, 0.137), Color("684537"))
	oval(head, Vector3(0.30, 0.14, 0.28), Vector3(0, 0.30, -0.02), Color("232426")).name = "Hair"
	if padded:
		oval(head, Vector3(0.34, 0.23, 0.33), Vector3(0, 0.30, -0.02), kit.darkened(0.3))
		block(head, Vector3(0.36, 0.025, 0.19), Vector3(0, 0.25, 0.16), kit.darkened(0.3))
		for y in [0.06, 0.13]:
			block(head, Vector3(0.32, 0.012, 0.015), Vector3(0, y, 0.20), Color("9aa6ae"))
		for side in [-1, 1]:
			block(head, Vector3(0.012, 0.23, 0.015), Vector3(side * 0.15, 0.13, 0.20), Color("9aa6ae"))
	upper_body = Node3D.new()
	upper_body.name = "UpperBody"
	upper_body.position = Vector3(0, 0.98, 0)
	var original_children := get_children()
	add_child(upper_body)
	for child in original_children:
		if child.name != "LeftLeg" and child.name != "RightLeg":
			child.reparent(upper_body)
	idle_pose(0)

func segment(node: MeshInstance3D, a: Vector3, b: Vector3, width: float) -> void:
	node.position = (a + b) * 0.5
	node.scale = Vector3(width, a.distance_to(b) + width * 0.35, width)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func solve_elbow(target: Vector3, bend: Vector3) -> Vector3:
	var distance := clampf(target.length(), 0.015, UPPER_ARM + FOREARM - 0.001)
	var axis := target.normalized()
	var along := (UPPER_ARM * UPPER_ARM - FOREARM * FOREARM + distance * distance) / (2 * distance)
	var sideways := bend - axis * bend.dot(axis)
	if sideways.length_squared() < 0.001:
		sideways = axis.cross(Vector3.RIGHT)
	return axis * along + sideways.normalized() * sqrt(maxf(UPPER_ARM * UPPER_ARM - along * along, 0))

func arm_pose(side: int, target: Vector3, bend: Vector3) -> void:
	var name_value := "LeftArm" if side < 0 else "RightArm"
	var arm := get_node("UpperBody/" + name_value) as Node3D
	var local := arm.to_local(upper_body.to_global(target - Vector3(0, 0.98, 0)))
	local = local.normalized() * minf(local.length(), UPPER_ARM + FOREARM - 0.001)
	var elbow := solve_elbow(local, bend)
	var parts: Array = joints[name_value]
	segment(parts[0], Vector3.ZERO, elbow, 0.135)
	segment(parts[1], elbow, local, 0.095)
	parts[2].position = local
	if side > 0:
		right_hand = to_local(arm.to_global(local))

func leg_pose(side: int, stride: float, lift: float) -> void:
	leg_target(side, Vector3(side * 0.155, 0.10 + lift, stride))

func leg_target(side: int, target: Vector3) -> void:
	var name_value := "LeftLeg" if side < 0 else "RightLeg"
	var leg := get_node(name_value) as Node3D
	var ankle := target - leg.position
	var axis := ankle.normalized()
	var length := minf(ankle.length(), 0.899)
	ankle = axis * length
	var forward := Vector3.BACK - axis * Vector3.BACK.dot(axis)
	var knee := ankle * 0.5 + forward.normalized() * sqrt(maxf(0.45 * 0.45 - length * length * 0.25, 0))
	var parts: Array = joints[name_value]
	segment(parts[0], Vector3.ZERO, knee, 0.19)
	segment(parts[1], knee, ankle, 0.14)
	parts[2].position = ankle + Vector3(0, -0.04, 0.075)
	if padded:
		parts[3].position = (knee + ankle) * 0.5 + Vector3(0, 0, 0.09)
		parts[3].quaternion = Quaternion(Vector3.UP, (knee - ankle).normalized())

func offspin_pose(time: float) -> void:
	if time < 0.85:
		idle_pose(time)
		for side in [-1, 1]:
			var cycle := time * 14 + (PI if side < 0 else 0.0)
			leg_pose(side, sin(cycle) * 0.22, maxf(0, cos(cycle)) * 0.14)
			arm_pose(side, Vector3(side * 0.22, 1.19, sin(cycle) * 0.13 + 0.20), Vector3(side, 0, 1))
		return
	var pose := OffspinAction.sample(time)
	upper_body.rotation = Vector3(pose[6], pose[5], pose[7])
	arm_pose(1, pose[1], Vector3.RIGHT)
	arm_pose(-1, pose[2], Vector3.LEFT)
	leg_target(-1, pose[3])
	leg_target(1, pose[4])
	head.rotation.y = -pose[5] * 0.65

func hop_height(time: float) -> float:
	return float(OffspinAction.sample(time)[8]) if time >= 0.85 else 0.0

func idle_pose(time: float) -> void:
	upper_body.rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	chest.scale.y = 0.65 + sin(time * 2) * 0.004
	for side in [-1, 1]:
		leg_pose(side, 0, 0)
		arm_pose(side, Vector3(side * 0.29, 0.92, 0.06), Vector3(side, 0, 1))

func run_pose(_time: float, progress: float) -> void:
	offspin_pose(progress * OffspinAction.RELEASE_TIME)

func release_point() -> Vector3:
	return to_global(right_hand)

func follow_pose(time: float) -> void:
	offspin_pose(OffspinAction.RELEASE_TIME + time)

func bat_pose(bat_node: Node3D, age: float, time: float) -> void:
	var moving := age >= 0 and age < 0.66
	var transfer := sin(clampf(age / 0.66, 0, 1) * PI) if moving else 0.0
	leg_pose(-1, 0.06 + transfer * 0.16, 0)
	leg_pose(1, -0.08, transfer * 0.025)
	chest.rotation.y = -transfer * 0.18
	head.rotation.y = 0.16
	chest.scale.y = 0.65 + sin(time * 2) * 0.003
	for side in [-1, 1]:
		var grip := bat_node.position + bat_node.basis * Vector3(0, 0.12 if side < 0 else 0.02, 0)
		arm_pose(side, grip, Vector3(side, -0.2, 0.5))

func configure_spin_bowler() -> void:
	# Original reference-study details. This is not a scanned celebrity likeness.
	head.get_node("Hair").visible = false
	oval(head, Vector3(0.32, 0.22, 0.31), Vector3(0, 0.29, -0.016), Color("171b23"))
	for i in range(3):
		var fold := oval(head, Vector3(0.323, 0.023, 0.30), Vector3(0, 0.235 + i * 0.036, -0.016), Color("292e37"))
		fold.rotation.z = -0.07 + i * 0.06
	oval(head, Vector3(0.23, 0.105, 0.22), Vector3(0, 0.025, 0.026), Color("242320"))
	for side in [-1, 1]:
		oval(head, Vector3(0.045, 0.12, 0.047), Vector3(side * 0.107, 0.075, 0.094), Color("242320"))
		oval(head, Vector3(0.075, 0.022, 0.020), Vector3(side * 0.041, 0.089, 0.139), Color("242320"))
		block(head, Vector3(0.070, 0.013, 0.018), Vector3(side * 0.058, 0.232, 0.127), Color("242320"))
