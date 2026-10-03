class_name CricketBallPhysics
extends RefCounted

# SI units: metres, seconds. Deliberately omits seam, swing, spin and aerodynamic drag.
const GRAVITY := 9.81
const RADIUS := 0.036
const PITCH_LEVEL := 0.04
const STUMP_HEIGHT := 0.7112
const BAIL_TOP := PITCH_LEVEL + STUMP_HEIGHT + 0.0127
const GROUND := PITCH_LEVEL + RADIUS
const RESTITUTION := 0.55
const IMPACT_RETENTION := 0.88
const ROLL_DECELERATION := 2.8
const BOUNDARY := 40.0
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var bounces := 0
var rolling := false
var boundary_score := 0
var first_bounce_position := Vector3.INF

func launch(origin: Vector3, initial_velocity: Vector3) -> void:
	position = origin
	velocity = initial_velocity
	bounces = 0
	rolling = false
	boundary_score = 0
	first_bounce_position = Vector3.INF

func advance(delta: float) -> void:
	assert(delta >= 0)
	var remaining := delta
	# Small bounded substeps make bounces stable even when called by a slow frame.
	while remaining > 0.0000001:
		var step := minf(remaining, 1.0 / 240.0)
		var previous := position
		if rolling:
			var speed := Vector2(velocity.x, velocity.z).length()
			var next_speed := maxf(0, speed - ROLL_DECELERATION * step)
			if speed > 0:
				var direction := Vector3(velocity.x, 0, velocity.z) / speed
				position += direction * ((speed + next_speed) * 0.5 * step)
				velocity = direction * next_speed
			position.y = GROUND
			record_boundary(previous, position, bounces)
		else:
			var next := position + velocity * step + Vector3(0, -0.5 * GRAVITY * step * step, 0)
			if next.y < GROUND:
				# Solve time of ground contact; apply restitution to velocity at impact.
				var impact_time := (velocity.y + sqrt(velocity.y * velocity.y + 2.0 * GRAVITY * maxf(0, position.y - GROUND))) / GRAVITY
				impact_time = clampf(impact_time, 0, step)
				position += velocity * impact_time + Vector3(0, -0.5 * GRAVITY * impact_time * impact_time, 0)
				position.y = GROUND
				record_boundary(previous, position, bounces)
				var impact_position := position
				velocity.y -= GRAVITY * impact_time
				velocity.y = -velocity.y * RESTITUTION
				velocity.x *= IMPACT_RETENTION
				velocity.z *= IMPACT_RETENTION
				if bounces == 0:
					first_bounce_position = position
				bounces += 1
				if velocity.y < 0.6:
					rolling = true
					velocity.y = 0
				var rest := step - impact_time
				if not rolling:
					position += velocity * rest + Vector3(0, -0.5 * GRAVITY * rest * rest, 0)
					velocity.y -= GRAVITY * rest
					position.y = maxf(position.y, GROUND)
				else:
					position += velocity * rest
				record_boundary(impact_position, position, bounces)
			else:
				position = next
				velocity.y -= GRAVITY * step
				record_boundary(previous, position, bounces)
		remaining -= step

static func crosses_plane(before: Vector3, after: Vector3, z: float) -> bool:
	return before.z < z and after.z >= z

static func at_plane(before: Vector3, after: Vector3, z: float) -> Vector3:
	return before.lerp(after, clampf((z - before.z) / (after.z - before.z), 0, 1))

static func strikes_stumps(point: Vector3) -> bool:
	if point.y < GROUND or point.y > BAIL_TOP + RADIUS:
		return false
	for x in [-0.0953, 0.0, 0.0953]:
		if absf(point.x - x) <= 0.019 + RADIUS:
			return true
	return point.y >= BAIL_TOP - 0.018 - RADIUS and absf(point.x) <= 0.1143 + RADIUS

func record_boundary(before: Vector3, after: Vector3, bounce_count: int) -> void:
	if boundary_score == 0 and Vector2(before.x, before.z).length() < BOUNDARY and Vector2(after.x, after.z).length() >= BOUNDARY:
		boundary_score = 6 if bounce_count == 0 else 4

func boundary_runs() -> int:
	return boundary_score
