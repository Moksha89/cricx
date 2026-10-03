class_name DeliverySolver
extends RefCounted
const NAMES := ["Normal", "In swing", "Out swing", "In cutter", "Out cutter", "Knuckle", "Reverse in", "Reverse out"]

static func configure(ball: CricketBallPhysics, kind: int, left_handed: bool, range_z: float) -> void:
	var inward := -1.0 if left_handed else 1.0
	ball.drag_coefficient = 0.0035
	ball.swing_coefficient = 0
	ball.late_swing = kind >= 6
	ball.knuckle = kind == 5
	ball.flight_range = maxf(range_z, 1)
	ball.angular_velocity = Vector3(-28, 0, 0)
	if kind == 1 or kind == 2:
		ball.swing_coefficient = inward * (1 if kind == 1 else -1) * 0.0011
	elif kind == 3 or kind == 4:
		ball.angular_velocity.z = -inward * (1 if kind == 3 else -1) * 100
	elif kind == 5:
		ball.angular_velocity = Vector3(2, 0, 0)
	elif kind >= 6:
		ball.swing_coefficient = inward * (1 if kind == 6 else -1) * 0.0024

static func trajectory(origin: Vector3, velocity: Vector3, kind: int, left_handed: bool, range_z: float) -> CricketBallPhysics:
	var ball := CricketBallPhysics.new()
	configure(ball, kind, left_handed, range_z)
	ball.launch(origin, velocity)
	for step in range(1000):
		ball.advance(1.0 / 120)
		if ball.bounces > 0:
			break
	return ball

static func solve(origin: Vector3, landing: Vector3, speed_kmh: float, kind: int, left_handed: bool) -> Vector3:
	var speed := speed_kmh / 3.6
	var yaw := atan2(landing.x - origin.x, landing.z - origin.z)
	var horizontal := Vector2(landing.x - origin.x, landing.z - origin.z).length()
	var g := CricketBallPhysics.GRAVITY
	var discriminant := pow(speed, 4) - g * (g * horizontal * horizontal + 2 * (landing.y - origin.y) * speed * speed)
	var pitch := atan((speed * speed - sqrt(maxf(0, discriminant))) / (g * horizontal))
	for pass_index in range(7):
		var velocity := direction(yaw, pitch) * speed
		var result := trajectory(origin, velocity, kind, left_handed, landing.z - origin.z)
		var error := Vector2(landing.x - result.first_bounce_position.x, landing.z - result.first_bounce_position.z)
		if error.length() < 0.008:
			break
		var h := 0.002
		var yaw_result := trajectory(origin, direction(yaw + h, pitch) * speed, kind, left_handed, landing.z - origin.z)
		var pitch_result := trajectory(origin, direction(yaw, pitch + h) * speed, kind, left_handed, landing.z - origin.z)
		var y_derivative := Vector2(yaw_result.first_bounce_position.x - result.first_bounce_position.x, yaw_result.first_bounce_position.z - result.first_bounce_position.z) / h
		var p_derivative := Vector2(pitch_result.first_bounce_position.x - result.first_bounce_position.x, pitch_result.first_bounce_position.z - result.first_bounce_position.z) / h
		var determinant := y_derivative.x * p_derivative.y - p_derivative.x * y_derivative.y
		if absf(determinant) < 0.00001:
			break
		yaw += clampf((error.x * p_derivative.y - error.y * p_derivative.x) / determinant, -0.15, 0.15)
		pitch += clampf((y_derivative.x * error.y - y_derivative.y * error.x) / determinant, -0.15, 0.15)
	return direction(yaw, pitch) * speed

static func direction(yaw: float, pitch: float) -> Vector3:
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
