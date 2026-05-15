extends "res://scripts/minigames/base_minigame.gd"

class SpaceBackdrop:
	extends Control

	const STARS := [
		Vector3(84, 88, 1.5), Vector3(142, 186, 1.1), Vector3(238, 118, 1.3),
		Vector3(354, 64, 1.0), Vector3(446, 146, 1.4), Vector3(534, 94, 1.0),
		Vector3(646, 120, 1.6), Vector3(716, 58, 1.0), Vector3(826, 154, 1.2),
		Vector3(936, 76, 1.5), Vector3(1046, 142, 1.1), Vector3(1168, 84, 1.3),
		Vector3(118, 314, 1.0), Vector3(256, 278, 1.4), Vector3(382, 332, 1.0),
		Vector3(506, 292, 1.2), Vector3(746, 286, 1.0), Vector3(842, 352, 1.5),
		Vector3(1112, 278, 1.1), Vector3(1210, 326, 1.3)
	]

	var pulse := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func update_pulse(new_pulse: float) -> void:
		pulse = new_pulse
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#111723"), true)
		draw_rect(Rect2(0, 0, size.x, 210), Color("#17213a"), true)
		draw_rect(Rect2(0, 210, size.x, 230), Color("#1a2944"), true)
		_draw_soft_nebula()
		_draw_stars()
		_draw_earth()

	func _draw_soft_nebula() -> void:
		draw_colored_polygon(_ellipse_points(Vector2(318, 214), Vector2(360, 92), 46, -0.15), Color("#385c8d2e"))
		draw_colored_polygon(_ellipse_points(Vector2(770, 188), Vector2(410, 118), 46, 0.09), Color("#4d477a2a"))
		draw_colored_polygon(_ellipse_points(Vector2(966, 346), Vector2(330, 112), 46, -0.20), Color("#2d675c22"))

	func _draw_stars() -> void:
		for item in STARS:
			var alpha := 0.54 + sin(pulse * 0.32 + item.x * 0.027) * 0.18
			draw_circle(Vector2(item.x, item.y), item.z, Color(1.0, 0.96, 0.82, alpha))

	func _draw_earth() -> void:
		var earth_center := Vector2(610, 930)
		var earth_radius := 610.0
		draw_circle(earth_center, earth_radius, Color("#63b9de"))
		draw_circle(earth_center + Vector2(0, 22), earth_radius - 26.0, Color("#79d0e8"))
		_draw_land(Vector2(178, 492), Vector2(210, 48), 0.06)
		_draw_land(Vector2(504, 440), Vector2(260, 62), -0.10)
		_draw_land(Vector2(814, 516), Vector2(235, 54), 0.14)
		_draw_land(Vector2(1074, 604), Vector2(255, 70), -0.04)
		_draw_cloud_band(Vector2(260, 382), Vector2(620, 0), 0.08)
		_draw_cloud_band(Vector2(392, 548), Vector2(536, 0), -0.10)
		_draw_cloud_band(Vector2(784, 464), Vector2(500, 0), 0.06)
		draw_arc(earth_center, earth_radius, PI + 0.08, TAU - 0.08, 108, Color("#111111"), 7.0, true)
		draw_arc(earth_center, earth_radius - 18.0, PI + 0.10, TAU - 0.10, 108, Color("#dff8ff84"), 4.0, true)

	func _draw_land(center: Vector2, radius: Vector2, rotation: float) -> void:
		var points := _ellipse_points(center, radius, 38, rotation)
		draw_colored_polygon(points, Color("#4aa164c7"))
		draw_polyline(points + PackedVector2Array([points[0]]), Color("#1f5d33a6"), 3.0, true)

	func _draw_cloud_band(center: Vector2, span: Vector2, wave: float) -> void:
		var points := PackedVector2Array()
		for step in range(28):
			var t := float(step) / 27.0
			var x := center.x - span.x * 0.5 + span.x * t
			var y := center.y + sin(t * TAU + wave) * 13.0
			points.append(Vector2(x, y))
		draw_polyline(points, Color("#ffffff8d"), 10.0, true)
		draw_polyline(points, Color("#ffffffd0"), 3.0, true)

	func _ellipse_points(center: Vector2, radius: Vector2, steps: int, rotation: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for step in range(steps):
			var angle := TAU * float(step) / float(steps)
			var point := Vector2(cos(angle) * radius.x, sin(angle) * radius.y).rotated(rotation)
			points.append(center + point)
		return points

class SignalBeam:
	extends Control

	var origin := Vector2.ZERO
	var target := Vector2.ZERO
	var satellite := Vector2.ZERO
	var alignment := 0.0
	var pulse := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func configure(new_origin: Vector2, new_target: Vector2) -> void:
		origin = new_origin
		target = new_target
		satellite = target
		queue_redraw()

	func update_state(new_alignment: float, new_pulse: float, satellite_point: Vector2) -> void:
		alignment = new_alignment
		pulse = new_pulse
		satellite = satellite_point
		queue_redraw()

	func _draw() -> void:
		if origin == target:
			return

		var color := Color("#ff5b5b").lerp(Color("#66f28b"), alignment)
		var direction := (target - origin).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var spread := 82.0
		var cone := PackedVector2Array([
			origin,
			target + normal * spread + direction * 34.0,
			target - normal * spread + direction * 34.0
		])
		draw_colored_polygon(cone, Color(color.r, color.g, color.b, 0.08 + alignment * 0.10))

		var center_angle := direction.angle()
		var wave_shift := fmod(pulse * 7.0, 42.0)
		for index in range(5):
			var radius := 112.0 + float(index) * 76.0 + wave_shift
			var wave_points := _arc_points(origin, radius, center_angle - 0.27, center_angle + 0.27)
			var wave_alpha := 0.33 + alignment * 0.36 - float(index) * 0.025
			draw_polyline(wave_points, Color(color.r, color.g, color.b, clampf(wave_alpha, 0.18, 0.72)), 5.0, true)

		_draw_dashed_line(origin, target, Color("#fff7b864"), 4.0, 8)
		draw_line(origin, satellite, Color(color.r, color.g, color.b, 0.44 + alignment * 0.42), 3.0 + alignment * 5.0, true)

	func _arc_points(center: Vector2, radius: float, start_angle: float, end_angle: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for step in range(24):
			var t := float(step) / 23.0
			var angle := lerpf(start_angle, end_angle, t)
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		return points

	func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, parts: int) -> void:
		for index in range(parts):
			if index % 2 == 1:
				continue
			var start_t := float(index) / float(parts)
			var end_t := minf(start_t + 0.075, 1.0)
			draw_line(from.lerp(to, start_t), from.lerp(to, end_t), color, width, true)

class CaptureZone:
	extends Control

	var alignment := 0.0
	var pulse := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func update_state(new_alignment: float, new_pulse: float) -> void:
		alignment = new_alignment
		pulse = new_pulse
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var color := Color("#ff5b5b").lerp(Color("#66f28b"), alignment)
		var radius := 52.0 + sin(pulse * 0.75) * 2.5
		draw_circle(center, radius + 15.0, Color(color.r, color.g, color.b, 0.09 + alignment * 0.10))
		draw_arc(center, radius, 0.0, TAU, 84, Color(color.r, color.g, color.b, 0.82), 5.0, true)
		draw_arc(center, radius + 14.0, -0.85, 0.85, 28, Color("#fff7b8b8"), 4.0, true)
		draw_arc(center, radius + 14.0, PI - 0.85, PI + 0.85, 28, Color("#fff7b8b8"), 4.0, true)
		draw_line(center + Vector2(-72, 0), center + Vector2(-22, 0), Color("#fff7b8b0"), 3.0, true)
		draw_line(center + Vector2(22, 0), center + Vector2(72, 0), Color("#fff7b8b0"), 3.0, true)
		draw_line(center + Vector2(0, -60), center + Vector2(0, -24), Color("#fff7b8b0"), 3.0, true)
		draw_line(center + Vector2(0, 24), center + Vector2(0, 60), Color("#fff7b8b0"), 3.0, true)

class SatelliteView:
	extends Control

	var alignment := 0.0
	var pulse := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func update_state(new_alignment: float, new_pulse: float) -> void:
		alignment = new_alignment
		pulse = new_pulse
		queue_redraw()

	func _draw() -> void:
		var glow := 0.12 + alignment * 0.25
		draw_circle(Vector2(108, 58), 88.0, Color("#66f28b", glow))
		_draw_solar_panel(Rect2(4, 38, 68, 42), -0.05)
		_draw_solar_panel(Rect2(134, 36, 70, 44), 0.07)
		_draw_body()
		_draw_receiver()

	func _draw_solar_panel(rect: Rect2, lean: float) -> void:
		var points := PackedVector2Array([
			rect.position + Vector2(0, 6),
			rect.position + Vector2(rect.size.x, 0) + Vector2(lean * 22.0, 0),
			rect.position + rect.size + Vector2(lean * 22.0, 0),
			rect.position + Vector2(0, rect.size.y - 6)
		])
		draw_colored_polygon(points, Color("#3b95ca"))
		draw_polyline(points + PackedVector2Array([points[0]]), Color("#111111"), 4.0, true)
		for index in range(1, 3):
			var x := rect.position.x + rect.size.x * float(index) / 3.0
			draw_line(Vector2(x, rect.position.y + 5), Vector2(x + lean * 18.0, rect.position.y + rect.size.y - 5), Color("#b9e9ff8a"), 2.0, true)
		draw_line(rect.position + Vector2(5, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 5, rect.size.y * 0.5), Color("#1f5f8ea0"), 2.0, true)

	func _draw_body() -> void:
		var body := Rect2(72, 22, 62, 72)
		draw_rect(body, Color("#f8f2df"), true)
		_draw_wobbly_rect(body, Color("#111111"), 4.0)
		draw_rect(Rect2(86, 35, 34, 24), Color("#ffcf22"), true)
		_draw_wobbly_rect(Rect2(86, 35, 34, 24), Color("#111111"), 3.0)
		draw_circle(Vector2(103, 76), 8.0, Color("#253245"))
		draw_circle(Vector2(103, 76), 3.8, Color("#66c6ff"))
		draw_line(Vector2(84, 26), Vector2(62, 8), Color("#111111"), 4.0, true)
		draw_circle(Vector2(60, 7), 5.0, Color("#ff5b5b"))

	func _draw_receiver() -> void:
		var arm_from := Vector2(133, 56)
		var arm_mid := Vector2(166, 45)
		var dish_center := Vector2(183, 42)
		draw_line(arm_from, arm_mid, Color("#111111"), 5.0, true)
		draw_arc(dish_center, 22.0, 2.18, 4.04, 24, Color("#111111"), 6.0, true)
		draw_arc(dish_center, 18.0, 2.18, 4.04, 24, Color("#e8ecf2"), 4.0, true)
		draw_circle(dish_center + Vector2(-15, 0), 4.6, Color("#111111"))

	func _draw_wobbly_rect(rect: Rect2, color: Color, width: float) -> void:
		var points := PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 1.5),
			rect.position + rect.size,
			rect.position + Vector2(-1.5, rect.size.y),
			rect.position
		])
		draw_polyline(points, color, width, true)

class RepeaterStation:
	extends Control

	var alignment := 0.0
	var pulse := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func update_state(new_alignment: float, new_pulse: float) -> void:
		alignment = new_alignment
		pulse = new_pulse
		queue_redraw()

	func _draw() -> void:
		var signal_color := Color("#ff5b5b").lerp(Color("#66f28b"), alignment)
		_draw_platform()
		_draw_tower()
		_draw_camera(signal_color)
		_draw_console(signal_color)

	func _draw_platform() -> void:
		var base := PackedVector2Array([Vector2(58, 250), Vector2(342, 250), Vector2(366, 296), Vector2(34, 296)])
		draw_colored_polygon(base, Color("#4c5864"))
		draw_polyline(base + PackedVector2Array([base[0]]), Color("#111111"), 5.0, true)
		draw_rect(Rect2(86, 220, 224, 32), Color("#687787"), true)
		_draw_rect_outline(Rect2(86, 220, 224, 32), 4.0)

	func _draw_tower() -> void:
		draw_line(Vector2(188, 96), Vector2(108, 248), Color("#111111"), 7.0, true)
		draw_line(Vector2(188, 96), Vector2(282, 248), Color("#111111"), 7.0, true)
		draw_line(Vector2(188, 96), Vector2(196, 248), Color("#111111"), 7.0, true)
		draw_line(Vector2(132, 202), Vector2(258, 202), Color("#111111"), 5.0, true)
		draw_line(Vector2(154, 158), Vector2(236, 158), Color("#111111"), 5.0, true)
		draw_arc(Vector2(188, 112), 76.0, 2.82, 6.60, 40, Color("#111111"), 8.0, true)
		draw_arc(Vector2(188, 112), 68.0, 2.82, 6.60, 40, Color("#d8e0e8"), 5.0, true)

	func _draw_camera(signal_color: Color) -> void:
		var angle := -2.55
		var body := _rotated_rect(Vector2(156, 92), Vector2(96, 48), angle)
		draw_colored_polygon(body, Color("#263345"))
		draw_polyline(body + PackedVector2Array([body[0]]), Color("#111111"), 5.0, true)
		var lens := Vector2(118, 73)
		draw_circle(lens, 21.0, Color("#111111"))
		draw_circle(lens, 13.0, signal_color)
		draw_circle(lens, 5.0, Color("#fff7d6"))
		draw_line(Vector2(188, 112), Vector2(156, 92), Color("#111111"), 6.0, true)
		draw_circle(Vector2(188, 112), 9.0, Color("#111111"))

	func _draw_console(signal_color: Color) -> void:
		draw_rect(Rect2(190, 254, 138, 32), Color("#1c2632"), true)
		_draw_rect_outline(Rect2(190, 254, 138, 32), 3.0)
		for index in range(5):
			var x := 207.0 + float(index) * 24.0
			var light_color := signal_color if index <= int(round(alignment * 4.0)) else Color("#5b6570")
			draw_circle(Vector2(x, 270), 6.0, light_color)

	func _rotated_rect(center: Vector2, rect_size: Vector2, angle: float) -> PackedVector2Array:
		var half := rect_size * 0.5
		var points := PackedVector2Array()
		for point in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
			points.append(center + point.rotated(angle))
		return points

	func _draw_rect_outline(rect: Rect2, width: float) -> void:
		draw_polyline(PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 0),
			rect.position + rect.size,
			rect.position + Vector2(0, rect.size.y),
			rect.position
		]), Color("#111111"), width, true)

const BG_PATH := "res://assets/art/satellite_signal_bg.png"
const SATELLITE_PATH := "res://assets/art/satellite_sprite.png"
const SATELLITE_SIZE := Vector2(230, 154)
const ORBIT_LEFT := 112.0
const ORBIT_RIGHT := 698.0
const ORBIT_BASE_Y := 70.0
const TARGET_SATELLITE_X := 396.0
const ALIGN_TOLERANCE := 42.0
const LOCK_SECONDS := 0.55
const OK_COLOR := Color("#66f28b")
const STATION_SIGNAL_ORIGIN := Vector2(966, 330)
const STAGE_SIZE := Vector2(1280, 720)

var satellite_x := TARGET_SATELLITE_X - 310.0
var dragging := false
var drag_offset_x := SATELLITE_SIZE.x * 0.5
var lock_time := 0.0
var pulse := 0.0
var satellite_node: Control
var space_backdrop: Control
var signal_beam: Control
var capture_zone: Control
var repeater_panel: Control
var station_label: Label
var lock_bar: ProgressBar
var orbit_line: Line2D
var signal_line: Line2D
var spark_lines: Array[Line2D] = []

func _ready() -> void:
	configure("GAME_CONTEXT_TITLE", "CONTEXT_INSTRUCTIONS", "GAME_CONTEXT_DESC", BG_PATH)
	super._ready()
	hide_common_minigame_header()
	hide_base_status()
	_hide_base_header_panel()
	if tutorial_panel:
		tutorial_panel.visible = false
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	satellite_x = ORBIT_LEFT + 78.0
	dragging = false
	lock_time = 0.0
	score = 0
	lock_bar.value = 0.0
	station_label.text = tr("CONTEXT_STATUS_SEARCH")
	_set_satellite_x(satellite_x)

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	pulse += delta * 8.0
	var alignment := _alignment_strength()
	score = roundi(alignment * 100.0)
	lock_bar.value = alignment
	_update_signal(alignment)
	_update_station_state(alignment)

	if alignment >= 0.94:
		lock_time += delta
		_set_sparks_visible(true)
	else:
		lock_time = 0.0
		_set_sparks_visible(false)

	if lock_time >= LOCK_SECONDS:
		await _finish_signal_lock()

func _input(event: InputEvent) -> void:
	if not running:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_drag(_event_position_in_content(event))
		else:
			_stop_drag()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_try_start_drag(_event_position_in_content(event))
		else:
			_stop_drag()
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and dragging:
		_drag_satellite_to(_event_position_in_content(event))

func _build_stage() -> void:
	_build_signal_beam()
	_build_orbit_area()
	_build_repeater_station()
	_build_satellite()
	_build_lock_bar()
	_build_sparks()
	_set_satellite_x(satellite_x)

func _build_orbit_area() -> void:
	orbit_line = Line2D.new()
	orbit_line.width = 3.0
	orbit_line.default_color = Color("#fff7b84a")
	orbit_line.points = _orbit_points()
	orbit_line.z_index = 4
	orbit_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	orbit_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	content_layer.add_child(orbit_line)

	orbit_line.modulate.a = 0.38

func _build_signal_beam() -> void:
	signal_line = Line2D.new()
	signal_line.width = 4.0
	signal_line.default_color = Color("#ff5b5b")
	signal_line.z_index = 9
	signal_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	signal_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	content_layer.add_child(signal_line)

func _build_repeater_station() -> void:
	station_label = _outlined_label("", 24, Color("#ff5b5b"), HORIZONTAL_ALIGNMENT_CENTER, 4, Color("#111111"))
	station_label.position = Vector2(882, 610)
	station_label.size = Vector2(326, 38)
	station_label.z_index = 15
	content_layer.add_child(station_label)

func _build_satellite() -> void:
	satellite_node = make_sprite(SATELLITE_PATH, SATELLITE_SIZE)
	satellite_node.size = SATELLITE_SIZE
	satellite_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satellite_node.z_index = 11
	satellite_node.pivot_offset = SATELLITE_SIZE * 0.5
	satellite_node.rotation = deg_to_rad(-5.0)
	content_layer.add_child(satellite_node)

func _build_lock_bar() -> void:
	lock_bar = ProgressBar.new()
	lock_bar.position = Vector2(930, 650)
	lock_bar.size = Vector2(242, 20)
	lock_bar.min_value = 0.0
	lock_bar.max_value = 1.0
	lock_bar.show_percentage = false
	lock_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_bar.z_index = 16
	lock_bar.add_theme_stylebox_override("background", make_style(Color("#1c2632"), Color("#111111"), 3, 6))
	lock_bar.add_theme_stylebox_override("fill", make_style(Color("#ff5b5b"), Color("#ff5b5b"), 0, 5))
	content_layer.add_child(lock_bar)

func _build_sparks() -> void:
	spark_lines.clear()
	var centers := [_target_signal_origin(), _station_signal_origin()]
	for center in centers:
		for index in range(6):
			var angle := TAU * float(index) / 6.0
			var line := Line2D.new()
			line.width = 5.0
			line.default_color = OK_COLOR
			line.points = PackedVector2Array([
				center + Vector2(cos(angle), sin(angle)) * 24.0,
				center + Vector2(cos(angle), sin(angle)) * 48.0
			])
			line.visible = false
			line.z_index = 17
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			content_layer.add_child(line)
			spark_lines.append(line)

func _try_start_drag(point: Vector2) -> void:
	if not (_mouse_hits_satellite(point) or _mouse_hits_orbit(point)):
		return

	dragging = true
	drag_offset_x = point.x - satellite_x if _mouse_hits_satellite(point) else SATELLITE_SIZE.x * 0.5
	play_action_sound("move")
	_drag_satellite_to(point)

func _drag_satellite_to(point: Vector2) -> void:
	if not dragging:
		return

	_set_satellite_x(point.x - drag_offset_x)
	get_viewport().set_input_as_handled()

func _stop_drag() -> void:
	if not dragging:
		return

	dragging = false
	get_viewport().set_input_as_handled()

func _set_satellite_x(new_x: float) -> void:
	satellite_x = clampf(new_x, ORBIT_LEFT, ORBIT_RIGHT)
	if satellite_node:
		satellite_node.position = _satellite_pos_for(satellite_x)
		var drift := sin((satellite_x - ORBIT_LEFT) / (ORBIT_RIGHT - ORBIT_LEFT) * PI) * -4.0
		satellite_node.rotation = deg_to_rad(-6.0 + drift)
	_update_signal(_alignment_strength())

func _set_dish_x(new_x: float) -> void:
	_set_satellite_x(new_x)

func _update_signal(alignment: float) -> void:
	var color := Color("#ff5b5b").lerp(OK_COLOR, alignment)
	if signal_line:
		signal_line.default_color = Color(color.r, color.g, color.b, 0.50 + alignment * 0.40)
		signal_line.width = 2.5 + alignment * 4.0
		signal_line.points = PackedVector2Array([_station_signal_origin(), _satellite_signal_origin()])
	if lock_bar:
		lock_bar.add_theme_stylebox_override("fill", make_style(color, color, 0, 5))
	if signal_beam:
		signal_beam.call("update_state", alignment, pulse, _satellite_signal_origin())
	if capture_zone:
		capture_zone.call("update_state", alignment, pulse)
	if space_backdrop:
		space_backdrop.call("update_pulse", pulse)
	if satellite_node and satellite_node.has_method("update_state"):
		satellite_node.call("update_state", alignment, pulse)
	if repeater_panel:
		repeater_panel.call("update_state", alignment, pulse)

func _update_station_state(alignment: float) -> void:
	var locked := alignment >= 0.86
	station_label.text = tr("CONTEXT_STATUS_LOCK") if locked else tr("CONTEXT_STATUS_SEARCH")
	station_label.add_theme_color_override("font_color", OK_COLOR if locked else Color("#ff5b5b"))
	if satellite_node:
		satellite_node.scale = Vector2.ONE * (1.0 + maxf(alignment - 0.78, 0.0) * sin(pulse * 1.6) * 0.025)

func _set_sparks_visible(visible: bool) -> void:
	for index in range(spark_lines.size()):
		var line := spark_lines[index]
		line.visible = visible
		if visible:
			line.modulate.a = 0.42 + sin(pulse + float(index)) * 0.30

func _finish_signal_lock() -> void:
	if not running:
		return
	play_action_sound("collect")
	signal_line.default_color = OK_COLOR
	await finish_with_result(true, "CONTEXT_SUCCESS", 0.45)

func _event_position_in_content(event: InputEvent) -> Vector2:
	var local_event := content_layer.make_input_local(event)
	if local_event is InputEventMouse:
		return (local_event as InputEventMouse).position
	if local_event is InputEventScreenTouch:
		return (local_event as InputEventScreenTouch).position
	if local_event is InputEventScreenDrag:
		return (local_event as InputEventScreenDrag).position
	return content_layer.get_local_mouse_position()

func _alignment_strength() -> float:
	return clampf(1.0 - absf(satellite_x - TARGET_SATELLITE_X) / ALIGN_TOLERANCE, 0.0, 1.0)

func _satellite_pos_for(x: float) -> Vector2:
	return Vector2(x, _orbit_y_for(x))

func _orbit_y_for(x: float) -> float:
	var t := clampf((x - ORBIT_LEFT) / (ORBIT_RIGHT - ORBIT_LEFT), 0.0, 1.0)
	return ORBIT_BASE_Y + sin(t * PI) * -44.0 + sin(t * TAU) * 8.0

func _satellite_signal_origin() -> Vector2:
	if not satellite_node:
		return _target_signal_origin()
	return satellite_node.position + Vector2(115, 77)

func _target_signal_origin() -> Vector2:
	return _satellite_pos_for(TARGET_SATELLITE_X) + Vector2(115, 77)

func _station_signal_origin() -> Vector2:
	return STATION_SIGNAL_ORIGIN

func _orbit_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in range(54):
		var t := float(step) / 53.0
		var x := lerpf(ORBIT_LEFT + SATELLITE_SIZE.x * 0.5, ORBIT_RIGHT + SATELLITE_SIZE.x * 0.5, t)
		var y := _orbit_y_for(x - SATELLITE_SIZE.x * 0.5) + SATELLITE_SIZE.y * 0.5
		points.append(Vector2(x, y))
	return points

func _mouse_hits_satellite(point: Vector2) -> bool:
	if not satellite_node:
		return false
	return Rect2(satellite_node.position, SATELLITE_SIZE).grow(28.0).has_point(point)

func _mouse_hits_orbit(point: Vector2) -> bool:
	return Rect2(Vector2(70, 24), Vector2(850, 274)).has_point(point)

func _outlined_label(
		text: String,
		font_size: int,
		color: Color,
		align: HorizontalAlignment,
		outline_size: int = 2,
		outline_color: Color = Color("#ffffff")
	) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", outline_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _hide_base_header_panel() -> void:
	if not title_label:
		return
	var node: Node = title_label
	for _step in range(3):
		node = node.get_parent()
		if not node:
			return
	if node is Control:
		(node as Control).visible = false

func on_timeout() -> void:
	await finish_with_result(false, "CONTEXT_FAIL", 0.45)
