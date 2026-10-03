class_name OffspinAction
extends RefCounted

# Hand-authored pose study from the user-supplied bowling reference.
# Times are game seconds, not timestamps of the edited/slow-motion footage.
# Character faces +Z. Targets are local metres; lean angles are radians.
const RELEASE_TIME := 1.60
const FRONT_PLANT_TIME := 1.40
const END_TIME := 2.45
const KEYS := [
	# time, right hand, left hand, left ankle, right ankle, yaw, forward lean, lateral lean, hop
	[0.85, Vector3(0.20,1.18,0.20), Vector3(-0.18,1.26,0.26), Vector3(-0.15,0.10,0.14), Vector3(0.15,0.12,-0.20), -0.20, 0.03, 0.00, 0.00],
	[1.05, Vector3(0.15,1.96,-0.08), Vector3(-0.12,1.92,0.16), Vector3(-0.15,0.18,0.26), Vector3(0.15,0.30,-0.20), -0.40, -0.10, 0.02, 0.12],
	[1.20, Vector3(0.12,1.94,-0.20), Vector3(-0.08,2.00,0.20), Vector3(-0.15,0.22,0.40), Vector3(0.15,0.10,-0.27), -0.45, -0.07, 0.02, 0.00],
	[1.40, Vector3(0.24,2.05,-0.05), Vector3(-0.19,1.73,0.43), Vector3(-0.15,0.10,0.28), Vector3(0.15,0.29,-0.28), -0.22, 0.00, 0.12, 0.00],
	[1.60, Vector3(0.24,2.063,0.035), Vector3(-0.24,1.11,0.32), Vector3(-0.15,0.10,0.06), Vector3(0.15,0.40,-0.25), 0.10, 0.14, 0.26, 0.00],
	[1.78, Vector3(0.20,1.55,0.55), Vector3(-0.30,1.00,-0.06), Vector3(-0.15,0.10,-0.16), Vector3(0.15,0.38,0.06), 0.28, 0.30, 0.35, 0.00],
	[2.02, Vector3(-0.10,1.00,0.34), Vector3(-0.32,1.13,-0.31), Vector3(-0.15,0.20,-0.24), Vector3(0.15,0.10,0.28), 0.39, 0.28, 0.23, 0.00],
	[2.25, Vector3(0.27,1.08,0.12), Vector3(-0.24,1.20,-0.18), Vector3(-0.15,0.10,0.10), Vector3(0.15,0.15,-0.18), 0.18, 0.12, 0.08, 0.00],
	[2.45, Vector3(0.29,0.92,0.06), Vector3(-0.29,0.92,0.06), Vector3(-0.155,0.10,0), Vector3(0.155,0.10,0), 0.00, 0.00, 0.00, 0.00],
]

static func sample(time: float) -> Array:
	for i in range(KEYS.size() - 1):
		if time <= KEYS[i + 1][0]:
			var a: Array = KEYS[i]
			var b: Array = KEYS[i + 1]
			var weight := smoothstep(a[0], b[0], time)
			var result: Array = [time]
			for column in range(1, a.size()):
				if a[column] is Vector3:
					result.append(a[column].lerp(b[column], weight))
				else:
					result.append(lerpf(a[column], b[column], weight))
			return result
	return KEYS.back().duplicate()

static func travel(time: float) -> float:
	# Front foot is planted over 1.40–1.60: root travels .22 m while
	# the local front ankle retreats by .22 m, keeping the shoe fixed.
	if time <= 0.85:
		return time / 0.85 * 2.80
	if time <= 1.40:
		return lerpf(2.80, 4.00, clampf((time - 0.85) / 0.55, 0, 1))
	if time <= 1.60:
		return 4.00 + smoothstep(1.40, 1.60, time) * 0.22
	if time <= 1.78:
		return 4.22 + smoothstep(1.60, 1.78, time) * 0.22
	return lerpf(4.44, 5.50, clampf((time - 1.78) / 0.67, 0, 1))
