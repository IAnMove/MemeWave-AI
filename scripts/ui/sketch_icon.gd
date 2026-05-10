extends Control

var icon_name := "star"
var accent_color := Color("#111111")
var secondary_color := Color("#ffffff")
var line_color := Color("#111111")

func configure(
		new_icon: String,
		new_accent: Color = Color("#111111"),
		new_secondary: Color = Color("#ffffff"),
		new_line: Color = Color("#111111")
	) -> void:
	icon_name = new_icon
	accent_color = new_accent
	secondary_color = new_secondary
	line_color = new_line
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	match icon_name:
		"robot":
			_draw_robot()
		"star":
			_draw_star()
		"check":
			_draw_check()
		"warning":
			_draw_warning()
		"trash":
			_draw_trash()
		"plane":
			_draw_plane()
		"computer_good":
			_draw_computer(true)
		"computer_bad":
			_draw_computer(false)
		"plant":
			_draw_plant()
		"spark":
			_draw_spark()
		"speaker":
			_draw_speaker()
		"funnel":
			_draw_funnel()
		_:
			_draw_star()

func _draw_robot() -> void:
	var w := size.x
	var h := size.y
	var head := Rect2(Vector2(w * 0.18, h * 0.24), Vector2(w * 0.64, h * 0.58))
	draw_rect(head, accent_color.lightened(0.45), true)
	draw_rect(head, line_color, false, max(2.0, w * 0.055), true)
	draw_circle(Vector2(w * 0.38, h * 0.48), w * 0.055, line_color)
	draw_circle(Vector2(w * 0.62, h * 0.48), w * 0.055, line_color)
	draw_arc(Vector2(w * 0.5, h * 0.58), w * 0.16, 0.2, 2.95, 14, line_color, max(2.0, w * 0.04), true)
	draw_line(Vector2(w * 0.5, h * 0.24), Vector2(w * 0.5, h * 0.08), line_color, max(2.0, w * 0.04), true)
	draw_circle(Vector2(w * 0.5, h * 0.08), w * 0.06, Color("#ff595e"))
	draw_line(Vector2(w * 0.18, h * 0.52), Vector2(w * 0.05, h * 0.52), line_color, max(2.0, w * 0.045), true)
	draw_line(Vector2(w * 0.82, h * 0.52), Vector2(w * 0.95, h * 0.52), line_color, max(2.0, w * 0.045), true)

func _draw_star() -> void:
	var center := size * 0.5
	var outer: float = minf(size.x, size.y) * 0.45
	var inner: float = outer * 0.46
	var points := PackedVector2Array()
	for index in range(10):
		var angle := -PI * 0.5 + float(index) * PI / 5.0
		var radius: float = outer if index % 2 == 0 else inner
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, accent_color)
	points.append(points[0])
	draw_polyline(points, line_color, max(2.0, outer * 0.11), true)

func _draw_check() -> void:
	var radius: float = minf(size.x, size.y) * 0.42
	var center := size * 0.5
	draw_circle(center, radius, accent_color)
	draw_arc(center, radius, 0.0, TAU, 40, line_color, max(2.0, radius * 0.12), true)
	var points := PackedVector2Array([
		Vector2(size.x * 0.28, size.y * 0.52),
		Vector2(size.x * 0.43, size.y * 0.68),
		Vector2(size.x * 0.72, size.y * 0.34)
	])
	draw_polyline(points, secondary_color, max(3.0, radius * 0.18), true)

func _draw_warning() -> void:
	var points := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.09),
		Vector2(size.x * 0.9, size.y * 0.84),
		Vector2(size.x * 0.1, size.y * 0.84)
	])
	draw_colored_polygon(points, accent_color)
	points.append(points[0])
	draw_polyline(points, line_color, max(2.0, size.x * 0.055), true)
	draw_line(Vector2(size.x * 0.5, size.y * 0.32), Vector2(size.x * 0.5, size.y * 0.58), secondary_color, max(3.0, size.x * 0.07), true)
	draw_circle(Vector2(size.x * 0.5, size.y * 0.7), size.x * 0.035, secondary_color)

func _draw_trash() -> void:
	var w := size.x
	var h := size.y
	var body := Rect2(Vector2(w * 0.24, h * 0.34), Vector2(w * 0.52, h * 0.52))
	draw_rect(body, accent_color.lightened(0.28), true)
	draw_rect(body, line_color, false, max(2.0, w * 0.055), true)
	draw_rect(Rect2(Vector2(w * 0.17, h * 0.25), Vector2(w * 0.66, h * 0.1)), accent_color, true)
	draw_rect(Rect2(Vector2(w * 0.34, h * 0.14), Vector2(w * 0.32, h * 0.11)), secondary_color, true)
	draw_line(Vector2(w * 0.36, h * 0.42), Vector2(w * 0.38, h * 0.78), line_color, max(1.5, w * 0.035), true)
	draw_line(Vector2(w * 0.5, h * 0.42), Vector2(w * 0.5, h * 0.78), line_color, max(1.5, w * 0.035), true)
	draw_line(Vector2(w * 0.64, h * 0.42), Vector2(w * 0.62, h * 0.78), line_color, max(1.5, w * 0.035), true)

func _draw_plane() -> void:
	var points := PackedVector2Array([
		Vector2(size.x * 0.12, size.y * 0.22),
		Vector2(size.x * 0.9, size.y * 0.5),
		Vector2(size.x * 0.12, size.y * 0.78),
		Vector2(size.x * 0.28, size.y * 0.52)
	])
	draw_colored_polygon(points, secondary_color)
	points.append(points[0])
	draw_polyline(points, line_color, max(2.0, size.x * 0.055), true)
	draw_line(Vector2(size.x * 0.28, size.y * 0.52), Vector2(size.x * 0.9, size.y * 0.5), line_color, max(1.5, size.x * 0.035), true)

func _draw_computer(good: bool) -> void:
	var w := size.x
	var h := size.y
	var screen := Rect2(Vector2(w * 0.16, h * 0.12), Vector2(w * 0.68, h * 0.52))
	draw_rect(screen, Color("#dff8da") if good else Color("#464646"), true)
	draw_rect(screen, line_color, false, max(3.0, w * 0.045), true)
	var face_color := Color("#0b8842") if good else Color("#111111")
	if good:
		draw_circle(Vector2(w * 0.39, h * 0.36), w * 0.025, face_color)
		draw_circle(Vector2(w * 0.61, h * 0.36), w * 0.025, face_color)
		draw_arc(Vector2(w * 0.5, h * 0.41), w * 0.14, 0.18, 2.96, 14, face_color, max(2.0, w * 0.035), true)
	else:
		draw_line(Vector2(w * 0.35, h * 0.29), Vector2(w * 0.43, h * 0.38), face_color, max(2.0, w * 0.035), true)
		draw_line(Vector2(w * 0.43, h * 0.29), Vector2(w * 0.35, h * 0.38), face_color, max(2.0, w * 0.035), true)
		draw_line(Vector2(w * 0.57, h * 0.29), Vector2(w * 0.65, h * 0.38), face_color, max(2.0, w * 0.035), true)
		draw_line(Vector2(w * 0.65, h * 0.29), Vector2(w * 0.57, h * 0.38), face_color, max(2.0, w * 0.035), true)
		draw_arc(Vector2(w * 0.5, h * 0.51), w * 0.13, 3.45, 5.95, 14, face_color, max(2.0, w * 0.035), true)
		for x in [0.2, 0.78]:
			draw_arc(Vector2(w * x, h * 0.12), w * 0.08, -0.5, 1.8, 8, Color("#5b5b5b"), max(1.5, w * 0.025), true)
	draw_line(Vector2(w * 0.5, h * 0.64), Vector2(w * 0.5, h * 0.72), line_color, max(2.0, w * 0.035), true)
	var keyboard := Rect2(Vector2(w * 0.2, h * 0.72), Vector2(w * 0.6, h * 0.16))
	draw_rect(keyboard, Color("#f3eadf"), true)
	draw_rect(keyboard, line_color, false, max(2.0, w * 0.035), true)

func _draw_plant() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2(w * 0.34, h * 0.58), Vector2(w * 0.32, h * 0.28)), Color("#f29b45"), true)
	draw_rect(Rect2(Vector2(w * 0.34, h * 0.58), Vector2(w * 0.32, h * 0.28)), line_color, false, max(1.5, w * 0.035), true)
	draw_line(Vector2(w * 0.5, h * 0.58), Vector2(w * 0.5, h * 0.22), Color("#0b8842"), max(2.0, w * 0.045), true)
	draw_arc(Vector2(w * 0.4, h * 0.34), w * 0.14, -1.0, 1.4, 14, Color("#0b8842"), max(2.0, w * 0.045), true)
	draw_arc(Vector2(w * 0.6, h * 0.34), w * 0.14, 1.75, 4.1, 14, Color("#0b8842"), max(2.0, w * 0.045), true)

func _draw_spark() -> void:
	draw_line(Vector2(size.x * 0.5, size.y * 0.08), Vector2(size.x * 0.5, size.y * 0.92), accent_color, max(2.0, size.x * 0.08), true)
	draw_line(Vector2(size.x * 0.08, size.y * 0.5), Vector2(size.x * 0.92, size.y * 0.5), accent_color, max(2.0, size.x * 0.08), true)
	draw_line(Vector2(size.x * 0.22, size.y * 0.22), Vector2(size.x * 0.78, size.y * 0.78), accent_color, max(2.0, size.x * 0.05), true)
	draw_line(Vector2(size.x * 0.78, size.y * 0.22), Vector2(size.x * 0.22, size.y * 0.78), accent_color, max(2.0, size.x * 0.05), true)

func _draw_speaker() -> void:
	var w := size.x
	var h := size.y
	var body := PackedVector2Array([
		Vector2(w * 0.12, h * 0.38),
		Vector2(w * 0.30, h * 0.38),
		Vector2(w * 0.52, h * 0.18),
		Vector2(w * 0.52, h * 0.82),
		Vector2(w * 0.30, h * 0.62),
		Vector2(w * 0.12, h * 0.62)
	])
	draw_colored_polygon(body, accent_color)
	body.append(body[0])
	draw_polyline(body, line_color, max(2.0, w * 0.055), true)
	draw_arc(Vector2(w * 0.55, h * 0.5), w * 0.18, -0.82, 0.82, 12, line_color, max(2.0, w * 0.055), true)
	draw_arc(Vector2(w * 0.55, h * 0.5), w * 0.31, -0.72, 0.72, 14, line_color, max(2.0, w * 0.05), true)

func _draw_funnel() -> void:
	var w := size.x
	var h := size.y
	var bowl := PackedVector2Array([
		Vector2(w * 0.14, h * 0.14),
		Vector2(w * 0.88, h * 0.14),
		Vector2(w * 0.58, h * 0.5),
		Vector2(w * 0.58, h * 0.84),
		Vector2(w * 0.42, h * 0.9),
		Vector2(w * 0.42, h * 0.5)
	])
	draw_colored_polygon(bowl, accent_color)
	bowl.append(bowl[0])
	draw_polyline(bowl, line_color, max(2.0, w * 0.06), true)
	draw_line(Vector2(w * 0.24, h * 0.2), Vector2(w * 0.78, h * 0.2), secondary_color, max(2.0, w * 0.045), true)
