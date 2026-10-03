extends SceneTree
var failures := 0
var cases := 0
func check(ok: bool, label_value: String) -> void:
	if not ok:
		failures += 1
		push_error(label_value)
func _initialize() -> void:
	var origin := Vector3(0.5,2.1,-10.8)
	for handed in [false,true]:
		for kind in range(8):
			for speed in [60.0,100.0,160.0 if kind!=5 else 110.0]:
				for target in [Vector3(-0.6,CricketBallPhysics.GROUND,1),Vector3(0.6,CricketBallPhysics.GROUND,8)]:
					var velocity := DeliverySolver.solve(origin,target,speed,kind,handed)
					check(absf(velocity.length()*3.6-speed)<0.001,"Requested speed is actual release speed")
					var ball := DeliverySolver.trajectory(origin,velocity,kind,handed,target.z-origin.z)
					check(ball.first_bounce_position.distance_to(target)<0.025,"Preview/landing agreement for %s %s %.0f" % [DeliverySolver.NAMES[kind],str(handed),speed])
					cases+=1
	var base := Vector3(0,-2,36)
	var inside := CricketBallPhysics.new()
	var outside := CricketBallPhysics.new()
	DeliverySolver.configure(inside,1,false,18)
	DeliverySolver.configure(outside,2,false,18)
	inside.launch(Vector3(0,2,0),base)
	outside.launch(Vector3(0,2,0),base)
	inside.advance(0.25)
	outside.advance(0.25)
	check(inside.position.x>0.01 and outside.position.x < -0.01,"Swing curves during flight")
	check(absf(inside.position.x+outside.position.x)<0.001,"Opposite swing mirrors")
	var left := CricketBallPhysics.new()
	DeliverySolver.configure(left,1,true,18)
	left.launch(Vector3(0,2,0),base)
	left.advance(0.25)
	check(left.position.x < -0.01,"Inward swing reverses with batter handedness")
	var reverse := CricketBallPhysics.new()
	DeliverySolver.configure(reverse,6,false,18)
	reverse.launch(Vector3(0,2,0),base)
	reverse.position.z=3
	check(absf(reverse.air_acceleration().x)<0.00001,"Reverse swing has no early lateral force")
	reverse.position.z=16
	check(reverse.air_acceleration().x>0.2,"Reverse swing develops late lateral force")
	for kind in [3,4]:
		var cutter := CricketBallPhysics.new()
		DeliverySolver.configure(cutter,kind,false,18)
		cutter.launch(Vector3(0,2,0),base)
		cutter.advance(0.25)
		check(absf(cutter.position.x)<0.0001,"Cutter has no imposed airborne sideways force")
		for step in range(80):
			cutter.advance(1.0/120)
			if cutter.bounces>0:
				break
		check(cutter.velocity.x>0.1 if kind==3 else cutter.velocity.x < -0.1,"Cutter spin transfers sideways momentum at bounce")
	var knuckle := CricketBallPhysics.new()
	DeliverySolver.configure(knuckle,5,false,18)
	check(knuckle.angular_velocity.length()<3 and knuckle.knuckle,"Knuckle low-spin profile")
	print("Deliveries: %d speed/target/type/handedness cases plus flight, spin and late-movement checks; %d failures" % [cases,failures])
	quit(1 if failures else 0)
