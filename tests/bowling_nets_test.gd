extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var result := GameplayChecks.run(scene)
	for issue in result.failures:
		push_error(issue)
	print("Gameplay: %d checks covering all eight deliveries, animation, speed, multi-touch ownership, target lock, swipe, cameras and over; %d failures" % [result.checks,result.failures.size()])
	quit(0 if result.failures.is_empty() else 1)
