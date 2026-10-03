class_name GameplayChecks
extends RefCounted

static func run(scene: Node3D) -> Dictionary:
	var issues: Array[String] = []
	var tally := {"checks":0}
	var verify := func(ok: bool, description: String):
		tally.checks += 1
		if not ok:
			issues.append(description)
	scene.set_physics_process(false)
	scene.reset()
	verify.call(scene.bowler.skeleton.get_bone_count()>=17,"Skinned full-body bowler and skeleton loaded")
	for kind in range(8):
		scene.reset()
		scene.delivery_buttons[kind].pressed.emit()
		scene.selected_speed=100.0
		scene.speed_control.value=100.0
		scene.target_point=Vector3(0.3,CricketBallPhysics.GROUND,4.3)
		scene.refresh_preview()
		var preview_origin: Vector3 = Vector3(0.75,0.04,-10.8)+scene.release_local
		var predicted := DeliverySolver.trajectory(preview_origin,scene.preview_velocity,kind,scene.left_handed,scene.target_point.z-preview_origin.z)
		verify.call(predicted.first_bounce_position.distance_to(scene.target_point)<0.025,"Preview agrees with target: "+DeliverySolver.NAMES[kind])
		scene.act()
		var start_z: float=scene.bowler.position.z
		for step in range(160):
			scene._physics_process(1.0/120)
			if scene.phase=="delivery":
				break
		verify.call(scene.phase=="delivery" and scene.bowler.position.z>start_z+3,"Animated run-up and synchronized release: "+str(kind))
		verify.call(scene.last_release.distance_to(scene.bowler.release_point())<0.001,"Ball origin equals hand at release: "+str(kind))
		verify.call(absf(scene.last_launch_velocity.length()*3.6-100)<0.001,"Actual delivery speed: "+str(kind))
		for step in range(500):
			scene._physics_process(1.0/120)
			if scene.phase=="ready":
				break
		verify.call(scene.deliveries==1 and scene.physics.first_bounce_position.distance_to(scene.target_point)<0.025,"Actual bounce: "+str(kind))
	var planted := Vector3.ZERO
	for step in range(25):
		var time:=1.4+step/120.0
		scene.bowler.position=Vector3(0.75,0.04,RiggedBowler.approach_z(time/1.6))
		scene.bowler.pose(time)
		var foot: Vector3=scene.bowler.skeleton.to_global(scene.bowler.point("foot_L"))
		if step==0:
			planted=foot
		verify.call(foot.distance_to(planted)<0.003,"Front-foot plant is stable through release")
	scene.reset()
	scene.select_delivery(0)
	var press := InputEventScreenTouch.new()
	press.index=7
	press.pressed=true
	press.position=Vector2(24,330)
	scene.speed_control._gui_input(press)
	var low_speed: float=scene.selected_speed
	var drag := InputEventScreenDrag.new()
	drag.index=7
	drag.position=scene.speed_control.global_position+Vector2(24,115)
	scene.speed_control._input(drag)
	verify.call(scene.selected_speed>low_speed+50,"Vertical speed dragging updates simulation setting")
	var release := InputEventScreenTouch.new()
	release.index=7
	release.pressed=false
	release.position=drag.position
	scene.speed_control._input(release)
	var world_touch := InputEventScreenTouch.new()
	world_touch.index=3
	world_touch.pressed=true
	world_touch.position=scene.camera.unproject_position(Vector3(0.8,0.055,2.5))
	scene._unhandled_input(world_touch)
	verify.call(absf(scene.target_point.x-0.8)<0.01 and absf(scene.target_point.z-2.5)<0.02,"Raycast pitch drag sets line and length")
	var selected: Vector3=scene.target_point
	press.index=8
	scene.speed_control._gui_input(press)
	drag.index=8
	drag.position=scene.speed_control.global_position+Vector2(24,200)
	scene.speed_control._input(drag)
	scene._unhandled_input(drag)
	verify.call(scene.target_point.is_equal_approx(selected),"Simultaneous speed touch cannot move target owned by another finger")
	release.index=8
	scene.speed_control._input(release)
	scene.lock_button.pressed.emit()
	world_touch.position=scene.camera.unproject_position(Vector3(-0.8,0.055,8))
	scene._unhandled_input(world_touch)
	verify.call(scene.target_point.is_equal_approx(selected),"Locked target cannot move")
	scene.lock_button.pressed.emit()
	scene._unhandled_input(world_touch)
	verify.call(scene.target_point.x< -0.75 and scene.target_point.z>7.9,"Unlocked target moves again")
	scene.reset()
	var swipe := InputEventScreenTouch.new()
	swipe.index=11
	swipe.pressed=true
	swipe.position=Vector2(84,135)
	scene.bowl_control._gui_input(swipe)
	var swipe_end := InputEventScreenTouch.new()
	swipe_end.index=11
	swipe_end.position=scene.bowl_control.global_position+Vector2(84,50)
	scene.bowl_control._input(swipe_end)
	verify.call(scene.phase=="approach","Swipe-up and release starts bowling")
	scene.act()
	verify.call(scene.deliveries==0 and scene.phase=="approach","Second delivery blocked during action")
	scene.reset()
	for ball in range(6):
		scene.act()
		for step in range(700):
			scene._physics_process(1.0/120)
			if scene.phase=="ready" or scene.phase=="finished":
				break
	verify.call(scene.phase=="finished" and scene.deliveries==6,"Six-ball over finishes")
	scene.act()
	verify.call(scene.deliveries==0 and scene.phase=="approach","Swipe/action starts new over")
	scene.reset()
	for mode in range(3):
		scene.view=mode
		scene.set_camera()
		verify.call(scene.camera.mode==mode and scene.camera.current,"Camera mode "+str(mode))
	scene.view=0
	scene.reset()
	scene.selected_speed=132
	scene.speed_control.value=132
	scene.target_point=Vector3(0,CricketBallPhysics.GROUND,4.3)
	scene.select_delivery(1)
	scene.target_locked=false
	scene.refresh_preview()
	scene.set_physics_process(true)
	return {"checks":tally.checks,"failures":issues,"renderer":RenderingServer.get_video_adapter_name(),"platform":OS.get_name()}
