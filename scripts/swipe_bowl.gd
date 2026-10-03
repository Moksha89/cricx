class_name SwipeBowlControl
extends Control
signal bowled
var disabled := false
var touch_id := -1
var start := Vector2.ZERO
var current_point := Vector2.ZERO
var mouse_dragging := false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
func _gui_input(event: InputEvent) -> void:
	if disabled:
		accept_event()
		return
	if event is InputEventScreenTouch and event.pressed and touch_id < 0:
		touch_id = event.index
		start = event.position + global_position
		current_point = start
		accept_event()
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and touch_id < 0:
		mouse_dragging = true
		start = event.position + global_position
		current_point = start
		accept_event()
func finish() -> void:
	var valid := not disabled and current_point.y - start.y < -24 and current_point.distance_to(start) >= 32
	touch_id = -1
	mouse_dragging = false
	queue_redraw()
	if valid:
		bowled.emit()
	accept_event()
func _input(event: InputEvent) -> void:
	if touch_id >= 0:
		if event is InputEventScreenDrag and event.index == touch_id:
			current_point = event.position
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.index == touch_id and not event.pressed:
			current_point = event.position
			finish()
			get_viewport().set_input_as_handled()
	elif mouse_dragging and event is InputEventMouseMotion:
		current_point = event.position
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif mouse_dragging and event is InputEventMouseButton and not event.pressed:
		current_point = event.position
		finish()
		get_viewport().set_input_as_handled()
func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.48
	draw_circle(center, radius, Color("17362c"))
	draw_circle(center, radius - 4, Color("d5f8af"))
	draw_circle(center, radius - 8, Color("789551") if disabled else Color("bdf348"))
	draw_circle(center + Vector2(6,-16), 19, Color("18352a"))
	for i in range(3):
		draw_line(center + Vector2(-42,-14 + i*10), center + Vector2(-18,-24 + i*10), Color("18352a"), 3, true)
	draw_arc(center + Vector2(6,-16), 16, -1.4, 1.2, 20, Color("bdf348"), 2, true)
	var font := ThemeDB.fallback_font
	draw_string(font, center + Vector2(-32,45), "BOWL", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("18352a"))
	if touch_id >= 0 or mouse_dragging:
		draw_line(start - global_position, current_point - global_position, Color.WHITE, 4, true)
