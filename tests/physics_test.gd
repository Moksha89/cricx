extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func simulate(fps: int, origin: Vector3, velocity: Vector3, seconds: float) -> CricketBallPhysics:
	var p := CricketBallPhysics.new()
	p.launch(origin, velocity)
	for frame in range(int(seconds * fps)):
		p.advance(1.0 / fps)
		check(p.position.y >= CricketBallPhysics.GROUND - 0.00001, "Ground penetration at %d Hz" % fps)
	return p

func _initialize() -> void:
	var free := CricketBallPhysics.new()
	free.launch(Vector3(0, 10, 0), Vector3(3, 2, 8))
	free.advance(0.5)
	check(free.position.distance_to(Vector3(1.5, 9.77375, 4)) < 0.0001, "Analytic gravity trajectory")
	check(absf(free.velocity.y + 2.905) < 0.0001, "Gravity velocity")
	var low := simulate(30, Vector3(0, 2.15, -10.5), Vector3(0, -1.4, 23), 1.0)
	var high := simulate(120, Vector3(0, 2.15, -10.5), Vector3(0, -1.4, 23), 1.0)
	check(low.position.distance_to(high.position) < 0.002, "30/120 Hz delivery invariance")
	check(low.bounces == 1 and high.bounces == 1, "Single pitch bounce before stumps")
	var roll := simulate(60, Vector3(0, CricketBallPhysics.GROUND, 0), Vector3(0, 0, 10), 10)
	check(roll.rolling and roll.velocity.length() < 0.001, "Friction brings ball to rest")
	var six := simulate(60, Vector3(0, 0.7, 8.6), Vector3(0, 21, -35), 2)
	check(six.boundary_runs() == 6, "Airborne boundary six")
	var four := simulate(60, Vector3(0, 0.7, 8.6), Vector3(0, 2.5, -35), 6)
	check(four.boundary_runs() == 4, "Bounced boundary four")
	var dot := simulate(60, Vector3(0, 0.7, 8.6), Vector3(0, 2.5, -10), 10)
	check(dot.boundary_runs() == 0, "Short shot must not award boundary")
	# Boundary crossed before landing in the SAME coarse update must remain six.
	var edge := CricketBallPhysics.new()
	edge.launch(Vector3(0, 0.08, -39.99), Vector3(0, -1, -30))
	edge.advance(1.0 / 30)
	check(edge.boundary_runs() == 6 and edge.bounces > 0, "Boundary-before-bounce event ordering")
	check(CricketBallPhysics.strikes_stumps(Vector3(0, 0.4, 10)), "Centre stump")
	check(not CricketBallPhysics.strikes_stumps(Vector3(0.4, 0.4, 10)), "Outside off stump")
	check(not CricketBallPhysics.strikes_stumps(Vector3(0, 1.2, 10)), "Over the stumps")
	check(not CricketBallPhysics.strikes_stumps(Vector3(0, 0.82, 10)), "Clear above regulation stump and bail height")
	check(CricketBallPhysics.crosses_plane(Vector3(0, 1, 9), Vector3(0, 0.5, 11), 10), "Swept wicket crossing avoids tunnelling")
	check(CricketBallPhysics.at_plane(Vector3(0, 1, 9), Vector3(0, 0.5, 11), 10).is_equal_approx(Vector3(0, 0.75, 10)), "Interpolated wicket crossing")
	print("Physics: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
