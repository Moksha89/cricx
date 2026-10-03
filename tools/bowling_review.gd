extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var athlete := scene.bowler as CricketAthlete
	scene.batsman.visible = false
	scene.umpire.visible = false
	for fielder in scene.fielders:
		fielder.visible = false
	for child in scene.get_children():
		if child is CanvasLayer:
			child.visible = false
	var overlay := CanvasLayer.new()
	scene.add_child(overlay)
	var title := Label.new()
	title.text = "CRICX • OFF-SPIN ACTION STUDY
Hand-authored from supplied footage • Placeholder character"
	title.position = Vector2(24, 20)
	title.add_theme_font_size_override("font_size", 24)
	overlay.add_child(title)
	var phase_label := Label.new()
	phase_label.position = Vector2(24, 660)
	phase_label.add_theme_font_size_override("font_size", 26)
	overlay.add_child(phase_label)
	scene.camera.fov = 42
	scene.action.disabled = true
	scene.score_label.text = "ACTION STUDY"
	scene.message.text = "Reference study: approach → gather → front-foot plant → release → follow-through"
	DirAccess.make_dir_recursive_absolute("res://build/bowling-review")
	for frame in range(180):
		var angle_index := frame / 90
		var t := (frame % 90) / 89.0 * 2.60
		athlete.position = Vector3(0.75, 0.04 + athlete.hop_height(t), -15 + OffspinAction.travel(t))
		athlete.offspin_pose(t)
		scene.ball.visible = t <= OffspinAction.RELEASE_TIME
		scene.ball.position = athlete.release_point()
		if angle_index == 0:
			scene.camera.position = athlete.position + Vector3(4.2, 1.9, -0.3)
		else:
			scene.camera.position = athlete.position + Vector3(0, 1.9, 4.5)
		scene.camera.look_at(athlete.position + Vector3(0, 1.15, 0))
		var stage := "APPROACH" if t < 0.85 else ("GATHER" if t < 1.20 else ("DELIVERY STRIDE" if t < 1.40 else ("FRONT-FOOT PLANT" if t < 1.60 else ("RELEASE / FOLLOW-THROUGH" if t < 2.25 else "RECOVERY"))))
		phase_label.text = ("SIDE VIEW" if angle_index == 0 else "FRONT VIEW") + " • " + stage
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var error := picture.save_png("res://build/bowling-review/frame_%03d.png" % frame)
		if error != OK:
			push_error("Review frame failed")
			quit(1)
			return
	print("PASS: 180 rendered action-study frames, side and front views")
	quit()
