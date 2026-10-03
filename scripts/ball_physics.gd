class_name CricketBallPhysics
extends RefCounted

# SI units. Aerodynamic coefficients are prototype tuning, not measured player data.
const GRAVITY := 9.81
const RADIUS := 0.036
const PITCH_LEVEL := 0.04
const STUMP_HEIGHT := 0.7112
const BAIL_TOP := PITCH_LEVEL + STUMP_HEIGHT + 0.0127
const GROUND := PITCH_LEVEL + RADIUS
const RESTITUTION := 0.55
const IMPACT_RETENTION := 0.88
const ROLL_DECELERATION := 2.8
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var bounces := 0
var rolling := false
var first_bounce_position := Vector3.INF
const MASS := 0.156
const INERTIA := 0.4 * MASS * RADIUS * RADIUS
const SURFACE_FRICTION := 0.28
var angular_velocity := Vector3.ZERO
var orientation := Quaternion.IDENTITY
var drag_coefficient := 0.0
var swing_coefficient := 0.0
var late_swing := false
var knuckle := false
var flight_range := 20.0
var flight_start := Vector3.ZERO
var elapsed := 0.0
var net_enabled := false
var net_contacts := 0
const NET_HALF_WIDTH := 2.6
const NET_END := 13.0
const NET_TOP := 3.26
const NET_RESTITUTION := 0.08

func launch(origin: Vector3, initial_velocity: Vector3) -> void:
	position = origin
	flight_start = origin
	elapsed = 0
	orientation = Quaternion.IDENTITY
	velocity = initial_velocity
	bounces = 0
	rolling = false
	first_bounce_position = Vector3.INF
	net_contacts = 0

func advance(delta: float) -> void:
	assert(delta >= 0)
	var remaining := delta
	# Small bounded substeps make bounces stable even when called by a slow frame.
	while remaining > 0.0000001:
		var step := minf(remaining, 1.0 / 240.0)
		elapsed += step
		if angular_velocity.length_squared() > 0.001:
			orientation = (Quaternion(angular_velocity.normalized(), angular_velocity.length() * step) * orientation).normalized()
		if rolling:
			var speed := Vector2(velocity.x, velocity.z).length()
			var next_speed := maxf(0, speed - ROLL_DECELERATION * step)
			if speed > 0:
				var direction := Vector3(velocity.x, 0, velocity.z) / speed
				position += direction * ((speed + next_speed) * 0.5 * step)
				velocity = direction * next_speed
			position.y = GROUND
			angular_velocity = Vector3(velocity.z / RADIUS, 0, -velocity.x / RADIUS)
		else:
			var acceleration := air_acceleration()
			var next := position + velocity * step + acceleration * (0.5 * step * step)
			if next.y < GROUND:
				# Solve time of ground contact; apply restitution to velocity at impact.
				var effective_gravity := maxf(0.01, -acceleration.y)
				var impact_time := (velocity.y + sqrt(velocity.y * velocity.y + 2.0 * effective_gravity * maxf(0, position.y - GROUND))) / effective_gravity
				impact_time = clampf(impact_time, 0, step)
				position += velocity * impact_time + acceleration * (0.5 * impact_time * impact_time)
				position.y = GROUND
				velocity += acceleration * impact_time
				var normal_impulse := MASS * (1 + RESTITUTION) * absf(velocity.y)
				velocity.y = -velocity.y * RESTITUTION
				if angular_velocity.length_squared() > 0.001:
					var lever := Vector3(0, -RADIUS, 0)
					var slip := velocity + angular_velocity.cross(lever)
					slip.y = 0
					var impulse := -slip / (1.0 / MASS + RADIUS * RADIUS / INERTIA)
					impulse = impulse.limit_length(SURFACE_FRICTION * normal_impulse)
					velocity += impulse / MASS
					angular_velocity += lever.cross(impulse) / INERTIA
				else:
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
					var after_acceleration := air_acceleration()
					position += velocity * rest + after_acceleration * (0.5 * rest * rest)
					velocity += after_acceleration * rest
					position.y = maxf(position.y, GROUND)
				else:
					position += velocity * rest
			else:
				position = next
				velocity += acceleration * step
		if net_enabled:
			resolve_net()
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

func resolve_net() -> void:
	# Stationary compliant-net approximation: lose normal energy on contact.
	# It contains the ball; it does not simulate cloth deformation.
	if position.z < -16.0 - RADIUS:
		return
	var limit := NET_HALF_WIDTH - RADIUS
	if absf(position.x) > limit and position.y <= NET_TOP:
		var side := signf(position.x)
		position.x = side * limit
		if velocity.x * side > 0:
			velocity.x = -velocity.x * NET_RESTITUTION
			velocity.y *= 0.65
			velocity.z *= 0.65
			net_contacts += 1
	if position.z > NET_END - RADIUS and absf(position.x) <= NET_HALF_WIDTH and position.y <= NET_TOP:
		position.z = NET_END - RADIUS
		if velocity.z > 0:
			velocity.z = -velocity.z * NET_RESTITUTION
			velocity.x *= 0.65
			velocity.y *= 0.65
			net_contacts += 1
	if position.y > NET_TOP - RADIUS and absf(position.x) <= NET_HALF_WIDTH:
		position.y = NET_TOP - RADIUS
		if velocity.y > 0:
			velocity.y = -velocity.y * NET_RESTITUTION
			velocity.x *= 0.65
			velocity.z *= 0.65
			net_contacts += 1

func air_acceleration() -> Vector3:
	var speed := velocity.length()
	var result := Vector3(0, -GRAVITY, 0) - velocity * (drag_coefficient * speed)
	var progress := clampf((position.z - flight_start.z) / flight_range, 0, 1)
	var movement := smoothstep(0.55, 0.95, progress) if late_swing else 1.0
	result.x += swing_coefficient * speed * speed * movement
	if knuckle:
		result.x += 0.00035 * speed * speed * (sin(elapsed * 26) + 0.5 * sin(elapsed * 41))
	return result
