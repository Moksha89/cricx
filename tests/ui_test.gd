extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func find_button(node: Node, title: String) -> Button:
	if node is Button and node.text == title:
		return node
	for child in node.get_children():
		var found := find_button(child, title)
		if found != null:
			return found
	return null

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	check(scene.action.action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS, "Batting must react on touch-down")
	check(is_equal_approx(scene.swing_angle(0.13), 0.0), "Drive bat face vertical at ideal contact")
	scene.shot_button.pressed.emit()
	check(scene.loft and scene.shot_button.text == "SHOT: LOFT", "Shot toggle wiring")
	check(scene.swing_angle(0.13) < 0, "Loft bat face opens upwards at contact")
	for expected in [-0.45, 0.45, 0.0]:
		scene.aim_button.pressed.emit()
		check(is_equal_approx(scene.aim, expected), "Aim cycle wiring")
	find_button(scene, "CAMERA").pressed.emit()
	check(scene.view == 1 and scene.camera.position.x > 0, "Overview camera wiring")
	find_button(scene, "CAMERA").pressed.emit()
	check(scene.view == 0, "Batting camera wiring")
	scene.action.pressed.emit()
	check(scene.phase == "runup" and scene.action.text == "SWING", "Bowl control wiring")
	scene.action.pressed.emit()
	check(scene.action.disabled and scene.swing_age == 0, "Swing control wiring")
	find_button(scene, "RESTART").pressed.emit()
	check(scene.phase == "ready" and not scene.action.disabled and scene.deliveries == 0, "Restart during delivery")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	scene._unhandled_key_input(space)
	check(scene.phase == "runup", "Desktop Space input wiring")
	scene.reset()
	find_button(scene, "LICENCES").pressed.emit()
	var popup := scene.get_child(scene.get_child_count() - 1) as AcceptDialog
	check(popup != null and popup.visible and paused, "Licence popup opens and pauses practice")
	if popup != null:
		var contents := popup.get_child(popup.get_child_count() - 1) as RichTextLabel
		check(contents != null and contents.text.contains("Permission is hereby granted") and contents.text.length() > 10000, "Engine and dependency licence contents")
		popup.confirmed.emit()
		await process_frame
		await process_frame
		check(not is_instance_valid(popup) and not paused, "Licence popup closes, resumes practice and frees resources")
	print("UI: shot selection, aim, cameras, touch-down mode, bowl/swing, active restart, keyboard and licences; %d failures" % failures)
	quit(1 if failures > 0 else 0)
