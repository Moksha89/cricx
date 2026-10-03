extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://build/camera-preview")
	for frame in range(240):
		if frame == 20:
			scene.act()
		scene._physics_process(1.0 / 60)
		await process_frame
		await RenderingServer.frame_post_draw
		var err := root.get_texture().get_image().save_png("res://build/camera-preview/frame_%03d.png" % frame)
		if err != OK:
			push_error("Camera preview capture failed")
			quit(1)
			return
	print("PASS: rendered 240 frames of approach-anchor and ball-follow camera")
	quit()
