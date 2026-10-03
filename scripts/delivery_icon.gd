class_name DeliveryIcon
extends Control
var kind := 0
var ink := Color("e4eee3")
func _draw() -> void:
	var c := size * 0.5
	var tip := c + Vector2(0,-16)
	if kind == 0:
		draw_line(c + Vector2(0,15), tip, ink, 3, true)
	elif kind == 1 or kind == 2 or kind >= 6:
		var sign_value := 1 if kind == 1 or kind == 6 else -1
		var points := PackedVector2Array()
		for i in range(21):
			var t := i / 20.0
			points.append(c + Vector2(sign_value * (14 * sin(t * PI * 0.8) - 8), 16 - t * 32))
		draw_polyline(points, ink, 3, true)
		tip = points[-1]
		if kind >= 6:
			draw_line(c + Vector2(-16,10), c + Vector2(-16,-8), ink, 2, true)
	elif kind == 3 or kind == 4:
		draw_circle(c + Vector2(-4,-5), 12, ink, false, 2, true)
		draw_line(c + Vector2(-7,-16), c + Vector2(-7,6), ink, 1, true)
		draw_line(c + Vector2(-1,-16), c + Vector2(-1,6), ink, 1, true)
		tip = c + Vector2(19 if kind == 3 else -19,16)
		draw_line(c + Vector2(7,5), tip, ink, 3, true)
	else:
		draw_circle(c, 12, ink, false, 2, true)
		for i in range(3):
			draw_line(c + Vector2(-6 + i*6,-20), c + Vector2(-6 + i*6,-10), ink, 2, true)
		return
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0,-4), tip + Vector2(-6,5), tip + Vector2(6,5)]), ink)
