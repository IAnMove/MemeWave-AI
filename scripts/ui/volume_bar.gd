extends Control

signal value_changed(value: float)

var value := 1.0
var dragging := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(278, 34)

func set_value(new_value: float, emit := false) -> void:
	value = clampf(new_value, 0.0, 1.0)
	queue_redraw()
	if emit:
		value_changed.emit(value)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if event.pressed:
			_update_from_x(event.position.x)
	if event is InputEventMouseMotion and dragging:
		_update_from_x(event.position.x)

func _update_from_x(x: float) -> void:
	var track := _track_rect()
	set_value((x - track.position.x) / track.size.x, true)

func _draw() -> void:
	var track := _track_rect()
	draw_rect(track, Color("#dff8da"), true)
	draw_rect(track, Color("#2d8a48"), false, 3.0, true)

	var fill := Rect2(track.position, Vector2(track.size.x * value, track.size.y))
	if fill.size.x > 0.0:
		draw_rect(fill, Color("#53cf62"), true)
		for offset in range(-24, int(fill.size.x + fill.size.y), 14):
			var from := fill.position + Vector2(offset, fill.size.y)
			var to := fill.position + Vector2(offset + fill.size.y, 0)
			draw_line(from, to, Color("#ffffff55"), 2.0, true)

	var knob_x := track.position.x + track.size.x * value
	var knob_center := Vector2(knob_x, track.position.y + track.size.y * 0.5)
	draw_circle(knob_center, 12.5, Color("#fffdf8"))
	draw_arc(knob_center, 12.5, 0.0, TAU, 32, Color("#1d1d1d"), 3.0, true)

func _track_rect() -> Rect2:
	return Rect2(Vector2(12, 9), Vector2(maxf(size.x - 24.0, 1.0), 16))
