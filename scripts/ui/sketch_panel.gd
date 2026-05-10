extends Control

var fill_color := Color("#ffffff")
var border_color := Color("#111111")
var hatch_color := Color("#00000010")
var border_width := 4.0
var roughness := 1.8
var hatch := false
var phase := 0.0

func configure(
		new_fill: Color,
		new_border: Color = Color("#111111"),
		new_border_width: float = 4.0,
		new_roughness: float = 1.8,
		new_hatch: bool = false,
		new_hatch_color: Color = Color("#00000010")
	) -> void:
	fill_color = new_fill
	border_color = new_border
	border_width = new_border_width
	roughness = new_roughness
	hatch = new_hatch
	hatch_color = new_hatch_color
	phase = fmod(size.x * 0.017 + size.y * 0.031 + position.x * 0.011 + position.y * 0.019, 6.28)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _draw() -> void:
	var inset: float = maxf(border_width + 1.0, 4.0)
	var rect := Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0))
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	draw_rect(rect, fill_color, true)
	if hatch:
		_draw_hatch(rect)

	for pass_index in range(2):
		var pass_rect := rect.grow(-float(pass_index) * 2.0)
		var width: float = maxf(1.6, border_width - float(pass_index) * 1.2)
		_draw_wobbly_rect(pass_rect, border_color, width, pass_index)

func _draw_hatch(rect: Rect2) -> void:
	var spacing := 16
	var start := -int(rect.size.y)
	var stop := int(rect.size.x + rect.size.y)
	for offset in range(start, stop, spacing):
		var from := rect.position + Vector2(offset, rect.size.y)
		var to := rect.position + Vector2(offset + rect.size.y, 0)
		draw_line(from, to, hatch_color, 1.0, true)

func _draw_wobbly_rect(rect: Rect2, color: Color, width: float, pass_index: int) -> void:
	var top_left := rect.position
	var top_right := rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right := rect.position + rect.size
	var bottom_left := rect.position + Vector2(0.0, rect.size.y)
	_draw_wobbly_line(top_left, top_right, color, width, pass_index)
	_draw_wobbly_line(top_right, bottom_right, color, width, pass_index + 3)
	_draw_wobbly_line(bottom_right, bottom_left, color, width, pass_index + 6)
	_draw_wobbly_line(bottom_left, top_left, color, width, pass_index + 9)

func _draw_wobbly_line(from: Vector2, to: Vector2, color: Color, width: float, pass_index: int) -> void:
	var length := from.distance_to(to)
	if length <= 0.0:
		return

	var segments: int = maxi(4, int(length / 70.0))
	var direction := to - from
	var normal := Vector2(-direction.y, direction.x).normalized()
	var points := PackedVector2Array()
	for index in range(segments + 1):
		var t := float(index) / float(segments)
		var point := from.lerp(to, t)
		if index != 0 and index != segments:
			var wave := sin(t * TAU * 1.65 + phase + float(pass_index) * 1.33)
			point += normal * wave * roughness
		points.append(point)

	draw_polyline(points, color, width, true)
