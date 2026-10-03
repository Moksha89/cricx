class_name TouchSpeedSlider
extends Control
signal changed(value: float)
var value := 132.0
var maximum := 160.0
var touch_id := -1
var mouse_dragging := false
var enabled := true
const LIME := Color("bbf34b")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
func set_at(point: Vector2) -> void:
	value = roundf(lerpf(maximum, 60, clampf((point.y - 105) / maxf(size.y - 135, 1), 0, 1)))
	changed.emit(value)
	queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if not enabled:
		accept_event()
		return
	if event is InputEventScreenTouch and event.pressed and touch_id < 0:
		touch_id = event.index
		set_at(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and touch_id < 0:
		mouse_dragging = event.pressed
		if mouse_dragging:
			set_at(event.position)
		accept_event()
	accept_event()
func _input(event: InputEvent) -> void:
	if touch_id >= 0:
		if event is InputEventScreenDrag and event.index == touch_id:
			set_at(event.position - global_position)
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.index == touch_id and not event.pressed:
			touch_id = -1
			get_viewport().set_input_as_handled()
	elif mouse_dragging and event is InputEventMouseMotion:
		set_at(event.position - global_position)
		get_viewport().set_input_as_handled()
	elif mouse_dragging and event is InputEventMouseButton and not event.pressed:
		mouse_dragging = false
func _draw() -> void:
	var x := 24.0
	var top := 105.0
	var bottom := size.y - 30
	var y := lerpf(bottom, top, (value - 60) / maxf(maximum - 60, 1))
	draw_line(Vector2(x, top), Vector2(x, bottom), Color("57705b"), 7, true)
	draw_line(Vector2(x, y), Vector2(x, bottom), LIME, 7, true)
	for i in range(11):
		var tick := lerpf(top, bottom, i / 10.0)
		draw_line(Vector2(x + 13, tick), Vector2(x + (25 if i % 5 == 0 else 20), tick), Color("728b77"), 1, true)
	draw_circle(Vector2(x, y), 14, Color("142b21"))
	draw_circle(Vector2(x, y), 10, LIME)

	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(45,112),str(int(maximum)),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e6efe3"))
	draw_string(font,Vector2(45,bottom+4),"60",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e6efe3"))
