class_name RiggedBowler
extends Node3D

var skeleton: Skeleton3D
var rest: Dictionary = {}
var idle_time := 0.0

func setup() -> void:
	var character: Node3D = load("res://assets/characters/bowler.glb").instantiate()
	add_child(character)
	skeleton = find_skeleton(character)
	assert(skeleton != null, "Skinned athlete needs a skeleton")
	for i in range(skeleton.get_bone_count()):
		rest[skeleton.get_bone_name(i)] = skeleton.get_bone_global_rest(i)
	pose(0)

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := find_skeleton(child)
		if found != null:
			return found
	return null

func point(name_value: String) -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone(name_value)).origin

func aim_bone(name_value: String, direction: Vector3) -> void:
	var index := skeleton.find_bone(name_value)
	var original: Transform3D = rest[name_value]
	var target_rotation := Basis(Quaternion(original.basis.y.normalized(), direction.normalized())) * original.basis
	var parent := skeleton.get_bone_parent(index)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var local := parent_basis.inverse() * target_rotation
	skeleton.set_bone_pose_rotation(index, local.orthonormalized().get_rotation_quaternion())

func ik(upper: String, lower: String, target: Vector3, bend: Vector3) -> void:
	var shoulder := point(upper)
	var upper_rest: Transform3D = rest[upper]
	var lower_rest: Transform3D = rest[lower]
	var end_name := lower.replace("forearm", "hand").replace("shin", "foot")
	var end_rest: Transform3D = rest[end_name]
	var a := upper_rest.origin.distance_to(lower_rest.origin)
	var b := lower_rest.origin.distance_to(end_rest.origin)
	var offset := target - shoulder
	var distance := clampf(offset.length(), absf(a - b) + 0.001, a + b - 0.0001)
	var axis := offset.normalized()
	var along := (a * a - b * b + distance * distance) / (2 * distance)
	var sideways := bend - axis * bend.dot(axis)
	if sideways.length_squared() < 0.001:
		sideways = axis.cross(Vector3.RIGHT)
	var elbow := shoulder + axis * along + sideways.normalized() * sqrt(maxf(a * a - along * along, 0))
	aim_bone(upper, elbow - shoulder)
	aim_bone(lower, shoulder + axis * distance - elbow)

func pose(time: float) -> void:
	skeleton.reset_bone_poses()
	var pelvis_index := skeleton.find_bone("pelvis")
	var pelvis_rest := skeleton.get_bone_rest(pelvis_index)
	var plant := smoothstep(1.12,1.4,time) * (1-smoothstep(1.9,2.3,time))
	skeleton.set_bone_pose_position(pelvis_index,pelvis_rest.origin+Vector3(0,-0.04*plant,0))
	var release := smoothstep(1.12, 1.60, time)
	var follow := smoothstep(1.60, 2.30, time)
	for side in [-1, 1]:
		var tag := "R" if side < 0 else "L"
		var stride := sin(time * 17 + (PI if side < 0 else 0.0)) * 0.20
		var lift := maxf(0, cos(time * 17 + (PI if side < 0 else 0.0))) * 0.12
		if time == 0 or time >= 2.3:
			stride = 0
			lift = 0
		elif time >= 1.12:
			stride = lerpf(0.20 if side > 0 else -0.20, 0, follow)
			lift = 0 if side > 0 else (0.25 * (1 - follow))
			if side>0 and time<=1.60:
				stride=0.20-0.20*smoothstep(1.4,1.6,time)
		ik("thigh_" + tag, "shin_" + tag, Vector3(side * 0.12, 0.10 + lift, stride), Vector3.BACK)
		var hand := Vector3(side * 0.27, 1.10, -stride + 0.12)
		if time == 0 or time >= 2.3:
			hand = Vector3(side * 0.27, 0.88, 0.065)
		elif time >= 1.12:
			if side < 0:
				hand = Vector3(-0.25, lerpf(1.28, 2.07, release), lerpf(-0.35, 0.01, release))
				if follow > 0:
					hand = Vector3(-0.22, 1.47 + cos(follow * PI) * 0.59, sin(follow * PI) * 0.40)
			else:
				hand = Vector3(0.22, lerpf(1.95, 1.08, release), 0.25 * (1 - follow))
		ik("upper_arm_" + tag, "forearm_" + tag, hand, Vector3(side, 0, 0.5))

func release_point() -> Vector3:
	return skeleton.to_global(point("hand_R") + Vector3(0, 0.005, 0.015))

static func approach_z(progress: float) -> float:
	if progress<0.875:
		return lerpf(-15,-11,progress/0.875)
	return -11+0.20*smoothstep(0.875,1,progress)

func idle(delta: float) -> void:
	idle_time += delta
	pose(0)
	var chest_index := skeleton.find_bone("chest")
	var original := skeleton.get_bone_rest(chest_index).basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(chest_index,original*Quaternion(Vector3.RIGHT,sin(idle_time*1.8)*0.004))
