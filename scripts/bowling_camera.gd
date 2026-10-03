class_name BowlingCameraRig
extends Camera3D

# Camera follows actor/ball anchors; it does not read a predicted landing point.
# Reusable by a future animated bowler through update_approach(actor_position).
var mode := 0 # follow, side, fixed
var orbit_yaw := 0.0
var initialized := false

func reset_view() -> void:
	initialized = false
	orbit_yaw = 0
	update_approach(Vector3(0.75, 0, -15), 0, 1)

func place(eye: Vector3, target: Vector3, lens: float, delta: float) -> void:
	var safe_eye := eye
	safe_eye.x = clampf(safe_eye.x, -2.20, 2.20)
	safe_eye.y = clampf(safe_eye.y, 0.35, 2.95)
	safe_eye.z = minf(safe_eye.z, 11.5)
	if mode == 1:
		safe_eye = Vector3(6.4, 4.5, -7)
		target = Vector3(0, 0.7, 1)
		lens = 58
	elif mode == 2:
		safe_eye = Vector3(0.70, 2.8, -19)
		target = Vector3(0, 1, 7)
		lens = 58
	var weight := 1.0 - exp(-12.0 * delta)
	if not initialized:
		position = safe_eye
		fov = lens
		initialized = true
	else:
		position = position.lerp(safe_eye, weight)
		fov = lerpf(fov, lens, weight)
	var desired := Basis.looking_at((target - position).normalized(), Vector3.UP)
	quaternion = quaternion.slerp(desired.get_rotation_quaternion(), weight) if delta < 1 else desired.get_rotation_quaternion()
	current = true

func update_approach(actor_position: Vector3, progress: float, delta: float) -> void:
	var gather := smoothstep(0.60, 1.0, progress)
	var offset := Vector3(lerpf(-0.35, 0.4, gather), lerpf(2.10, 2.65, gather), lerpf(-3.9, -4.0, gather))
	offset = Basis(Vector3.UP, orbit_yaw) * offset
	place(actor_position + offset, actor_position + Vector3(0, lerpf(1.15,1.0,gather), lerpf(1.2,0.3,gather)), 52, delta)

func update_delivery(ball_position: Vector3, velocity: Vector3, delta: float) -> void:
	var direction := Vector3(velocity.x, 0, maxf(velocity.z, 0.5)).normalized()
	var eye := ball_position - direction * 3.8 + Vector3(0.35, 1.35, 0)
	place(eye, ball_position + direction * 1.3, 52, delta)

func drag(horizontal_pixels: float) -> void:
	orbit_yaw = clampf(orbit_yaw - horizontal_pixels * 0.002, -0.35, 0.35)
