extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_CONNECTIONS := 4
const MISTAKE_LIMIT := 3
const BG_PATH := "res://assets/art/gpu_ritual_bg.png"
const CENTER_COMPUTER_PATH := "res://assets/art/center_computer.png"
const INK := Color("#151515")
const PAPER := Color("#fff7d6")
const PAIRS := [
	{"id": "gpu", "left_key": "GPU_RITUAL_LEFT_GPU", "right_key": "GPU_RITUAL_RIGHT_ALTAR", "color": "#1982c4"},
	{"id": "fan", "left_key": "GPU_RITUAL_LEFT_FAN", "right_key": "GPU_RITUAL_RIGHT_WIND", "color": "#8ac926"},
	{"id": "cash", "left_key": "GPU_RITUAL_LEFT_CASH", "right_key": "GPU_RITUAL_RIGHT_FIRE", "color": "#ffca3a"},
	{"id": "power", "left_key": "GPU_RITUAL_LEFT_POWER", "right_key": "GPU_RITUAL_RIGHT_SOCKET", "color": "#ff595e"}
]

var sockets: Array[Dictionary] = []
var selected_index := -1
var dragging_cable := false
var connected := 0
var mistakes := 0
var cable_layer: Node2D
var dangling_cable: Line2D
var dangling_cable_shadow: Line2D
var dangling_cable_jacket: Line2D
var dangling_cable_highlight: Line2D
var dangling_plug: Control
var center_computer: TextureRect
var altar_panel: Control
var altar_label: Label
var ritual_bar: ProgressBar
var verdict_label: Label
var pips: Array[ColorRect] = []

class RitualSocketIcon:
	extends Control

	var side := "left"
	var pair_id := "gpu"
	var accent := Color("#1982c4")

	func configure(new_side: String, new_pair_id: String, new_accent: Color) -> void:
		side = new_side
		pair_id = new_pair_id
		accent = new_accent
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var icon_id := pair_id
		if side == "right":
			match pair_id:
				"gpu":
					icon_id = "core"
				"fan":
					icon_id = "cooling"
				"cash":
					icon_id = "burn"
				"power":
					icon_id = "socket"
		match icon_id:
			"fan":
				_draw_fan()
			"cash":
				_draw_cash()
			"power":
				_draw_bill()
			"core":
				_draw_core()
			"cooling":
				_draw_cooling()
			"burn":
				_draw_burn()
			"socket":
				_draw_socket()
			_:
				_draw_gpu()

	func _draw_gpu() -> void:
		var card := Rect2(Vector2(size.x * 0.12, size.y * 0.22), Vector2(size.x * 0.70, size.y * 0.48))
		draw_rect(card, Color("#263041"), true)
		_wobbly_rect(card, INK, 3.0)
		draw_circle(card.position + Vector2(card.size.x * 0.30, card.size.y * 0.50), size.x * 0.12, accent.lightened(0.25))
		draw_arc(card.position + Vector2(card.size.x * 0.30, card.size.y * 0.50), size.x * 0.08, 0.0, TAU, 18, INK, 2.0, true)
		draw_rect(Rect2(card.position + Vector2(card.size.x * 0.52, 12), Vector2(card.size.x * 0.34, 7)), accent, true)
		draw_line(card.position + Vector2(8, card.size.y + 5), card.position + Vector2(card.size.x - 8, card.size.y + 5), Color("#ffca3a"), 4.0, true)

	func _draw_fan() -> void:
		var center := size * 0.5
		draw_circle(center, size.x * 0.30, Color("#d7f8d0"))
		draw_arc(center, size.x * 0.30, 0.0, TAU, 28, INK, 3.0, true)
		for index in range(4):
			var angle := TAU * float(index) / 4.0
			var p1 := center + Vector2(cos(angle), sin(angle)) * size.x * 0.08
			var p2 := center + Vector2(cos(angle + 0.45), sin(angle + 0.45)) * size.x * 0.24
			draw_line(p1, p2, accent.darkened(0.15), 6.0, true)
		draw_circle(center, size.x * 0.07, INK)

	func _draw_cash() -> void:
		for index in range(3):
			var bill := Rect2(Vector2(size.x * (0.18 + index * 0.06), size.y * (0.30 + index * 0.08)), Vector2(size.x * 0.50, size.y * 0.22))
			draw_rect(bill, Color("#8be56f"), true)
			_wobbly_rect(bill, INK, 2.5)
			draw_circle(bill.position + bill.size * 0.5, size.x * 0.055, Color("#ffef5f"))

	func _draw_bill() -> void:
		var page := Rect2(Vector2(size.x * 0.22, size.y * 0.16), Vector2(size.x * 0.50, size.y * 0.66))
		draw_rect(page, Color("#fffdf3"), true)
		_wobbly_rect(page, INK, 3.0)
		draw_line(page.position + Vector2(8, 16), page.position + Vector2(page.size.x - 8, 16), accent, 4.0, true)
		draw_line(page.position + Vector2(8, 32), page.position + Vector2(page.size.x - 12, 32), INK, 2.0, true)
		draw_line(page.position + Vector2(8, 46), page.position + Vector2(page.size.x - 18, 46), INK, 2.0, true)
		draw_line(page.position + Vector2(page.size.x - 16, page.size.y - 14), page.position + Vector2(page.size.x - 5, page.size.y - 4), Color("#ff595e"), 3.0, true)

	func _draw_core() -> void:
		var chip := Rect2(Vector2(size.x * 0.26, size.y * 0.20), Vector2(size.x * 0.48, size.y * 0.56))
		draw_rect(chip, Color("#a5ecff"), true)
		_wobbly_rect(chip, INK, 3.0)
		draw_circle(chip.position + chip.size * 0.5, size.x * 0.11, accent)
		for index in range(3):
			var y := chip.position.y + 10 + index * 11
			draw_line(Vector2(chip.position.x - 9, y), Vector2(chip.position.x, y), INK, 2.5, true)
			draw_line(Vector2(chip.end.x, y), Vector2(chip.end.x + 9, y), INK, 2.5, true)

	func _draw_cooling() -> void:
		for index in range(3):
			var y := size.y * (0.30 + index * 0.18)
			draw_line(Vector2(size.x * 0.18, y), Vector2(size.x * 0.82, y - 6.0), accent, 5.0, true)
			draw_line(Vector2(size.x * 0.74, y - 14.0), Vector2(size.x * 0.84, y - 6.0), accent, 3.0, true)
			draw_line(Vector2(size.x * 0.76, y + 5.0), Vector2(size.x * 0.84, y - 6.0), accent, 3.0, true)

	func _draw_burn() -> void:
		var base := Rect2(Vector2(size.x * 0.18, size.y * 0.58), Vector2(size.x * 0.62, size.y * 0.20))
		draw_rect(base, Color("#47333a"), true)
		_wobbly_rect(base, INK, 2.5)
		var flame := PackedVector2Array([
			Vector2(size.x * 0.48, size.y * 0.18),
			Vector2(size.x * 0.68, size.y * 0.58),
			Vector2(size.x * 0.50, size.y * 0.48),
			Vector2(size.x * 0.34, size.y * 0.62)
		])
		draw_colored_polygon(flame, Color("#ff595e"))
		flame.append(flame[0])
		draw_polyline(flame, INK, 3.0, true)
		draw_circle(Vector2(size.x * 0.48, size.y * 0.55), size.x * 0.07, Color("#ffca3a"))

	func _draw_socket() -> void:
		var plate := Rect2(Vector2(size.x * 0.22, size.y * 0.22), Vector2(size.x * 0.54, size.y * 0.56))
		draw_rect(plate, Color("#fffdf3"), true)
		_wobbly_rect(plate, INK, 3.0)
		draw_line(Vector2(size.x * 0.40, size.y * 0.42), Vector2(size.x * 0.40, size.y * 0.58), INK, 4.0, true)
		draw_line(Vector2(size.x * 0.58, size.y * 0.42), Vector2(size.x * 0.58, size.y * 0.58), INK, 4.0, true)
		draw_circle(Vector2(size.x * 0.49, size.y * 0.67), size.x * 0.035, accent)

	func _wobbly_rect(rect: Rect2, color: Color, width: float) -> void:
		var points := PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 1.0),
			rect.position + rect.size,
			rect.position + Vector2(1.0, rect.size.y),
			rect.position
		])
		draw_polyline(points, color, width, true)

func _ready() -> void:
	configure("GAME_GPU_RITUAL_TITLE", "GPU_RITUAL_INSTRUCTIONS", "GAME_GPU_RITUAL_DESC", BG_PATH)
	super._ready()
	if overlay_label:
		overlay_label.z_index = 200
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	selected_index = -1
	dragging_cable = false
	connected = 0
	mistakes = 0
	score = 0
	_clear_cables()
	_reset_sockets()
	_reset_pips()
	_update_altar(false)
	_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fff1cf")
	add_child(bg)
	move_child(bg, 0)

	cable_layer = Node2D.new()
	cable_layer.z_index = 1
	content_layer.add_child(cable_layer)

	_build_column(Vector2(50, 218), tr("GPU_RITUAL_OFFERINGS"), "left")
	_build_column(Vector2(944, 218), tr("GPU_RITUAL_ALTAR_PORTS"), "right")
	_build_altar()
	_build_sockets()

func _build_column(position: Vector2, title_text: String, side: String) -> void:
	_sketch_panel(position, Vector2(286, 404), Color("#fff7d6eb"), false)
	var title := _outlined_label(title_text, 26, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = position + Vector2(16, 12)
	title.size = Vector2(254, 70)
	content_layer.add_child(title)

func _build_altar() -> void:
	altar_panel = _sketch_panel(Vector2(400, 232), Vector2(480, 374), Color("#21182ae8"), true, Color("#ff595e"))
	_icon("spark", Vector2(446, 286), Vector2(42, 42), Color("#ffca3a"))
	_icon("spark", Vector2(790, 286), Vector2(42, 42), Color("#ffca3a"))

	center_computer = make_sprite(CENTER_COMPUTER_PATH, Vector2(286, 180))
	center_computer.position = Vector2(497, 303)
	center_computer.size = Vector2(286, 180)
	center_computer.z_index = 3
	center_computer.modulate = Color(0.9, 0.84, 0.86, 1.0)
	center_computer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(center_computer)

	var title := _outlined_label(tr("GPU_RITUAL_ALTAR_TITLE"), 29, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(430, 248)
	title.size = Vector2(420, 44)
	content_layer.add_child(title)

	ritual_bar = ProgressBar.new()
	ritual_bar.position = Vector2(468, 478)
	ritual_bar.size = Vector2(344, 32)
	ritual_bar.min_value = 0
	ritual_bar.max_value = TARGET_CONNECTIONS
	ritual_bar.show_percentage = false
	content_layer.add_child(ritual_bar)

	altar_label = _outlined_label("", 27, Color("#ffb9c6"), HORIZONTAL_ALIGNMENT_CENTER)
	altar_label.position = Vector2(436, 520)
	altar_label.size = Vector2(408, 38)
	content_layer.add_child(altar_label)

	verdict_label = _outlined_label("", 23, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(430, 564)
	verdict_label.size = Vector2(420, 36)
	content_layer.add_child(verdict_label)

	for index in range(MISTAKE_LIMIT):
		var pip := ColorRect.new()
		pip.position = Vector2(574 + index * 48, 458)
		pip.size = Vector2(34, 14)
		pip.color = Color("#3d3442")
		content_layer.add_child(pip)
		pips.append(pip)

func _build_sockets() -> void:
	var left_x := 82
	var right_x := 972
	var start_y := 306
	var gap := 74
	var left_pairs := _shuffled_pairs()
	var right_pairs := _shuffled_pairs()
	if _orders_match(left_pairs, right_pairs):
		var first: Dictionary = right_pairs.pop_front()
		right_pairs.append(first)
	for index in range(left_pairs.size()):
		var pair: Dictionary = left_pairs[index]
		var y := start_y + index * gap
		_add_socket("left", pair["id"], tr(pair["left_key"]), Color(pair["color"]), Vector2(left_x, y))
	for index in range(right_pairs.size()):
		var pair: Dictionary = right_pairs[index]
		var y := start_y + index * gap
		_add_socket("right", pair["id"], tr(pair["right_key"]), Color(pair["color"]), Vector2(right_x, y))

func _shuffled_pairs() -> Array:
	var copy := PAIRS.duplicate(true)
	copy.shuffle()
	return copy

func _orders_match(left_pairs: Array, right_pairs: Array) -> bool:
	for index in range(left_pairs.size()):
		var left_pair: Dictionary = left_pairs[index]
		var right_pair: Dictionary = right_pairs[index]
		if String(left_pair["id"]) != String(right_pair["id"]):
			return false
	return true

func _add_socket(side: String, pair_id: String, label_text: String, wire_color: Color, position: Vector2) -> void:
	var card := PanelContainer.new()
	card.position = position
	card.size = Vector2(230, 58)
	card.z_index = 4
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 7))
	card.gui_input.connect(_on_socket_input.bind(card))
	content_layer.add_child(card)

	var inner := Control.new()
	inner.custom_minimum_size = card.size
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inner)

	var label := make_label(label_text, 16, INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(12, 2)
	label.size = Vector2(148, 54)
	if side == "right":
		label.position.x = 70
		label.size.x = 148
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(label)

	var item_icon := RitualSocketIcon.new()
	item_icon.position = Vector2(164, 5) if side == "left" else Vector2(8, 5)
	item_icon.size = Vector2(58, 48)
	item_icon.configure(side, pair_id, wire_color)
	item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(item_icon)

	sockets.append({
		"node": card,
		"side": side,
		"id": pair_id,
		"color": wire_color,
		"connected": false
	})

func _on_socket_input(event: InputEvent, card: PanelContainer) -> void:
	if not running:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	var index := _find_socket_index(card)
	if index == -1 or bool(sockets[index]["connected"]):
		return

	if selected_index == -1:
		_begin_drag_from_socket(index)
		return
	if selected_index == index:
		_begin_drag_from_socket(index)
		return
	if sockets[selected_index]["side"] == sockets[index]["side"]:
		_begin_drag_from_socket(index)
		return
	_try_connect(selected_index, index)

func _input(event: InputEvent) -> void:
	if not running or not dragging_cable:
		return

	if event is InputEventMouseMotion:
		_update_dangling_cable(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.position)

func _try_connect(first_index: int, second_index: int) -> void:
	if first_index < 0 or second_index < 0 or first_index >= sockets.size() or second_index >= sockets.size():
		return

	var first := sockets[first_index]
	var second := sockets[second_index]

	if first["id"] == second["id"]:
		_clear_selection()
		_connect_pair(first_index, second_index)
	else:
		_drop_wrong_cable(first, second)
		mistakes += 1
		_flash_wrong(first_index)
		_flash_wrong(second_index)
		_clear_selection()
		_mark_mistake()
		verdict_label.text = tr("GPU_RITUAL_BAD_CABLE")
		verdict_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		_update_status()
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "GPU_RITUAL_FAIL", 0.65)

func _connect_pair(first_index: int, second_index: int) -> void:
	if bool(sockets[first_index]["connected"]) or bool(sockets[second_index]["connected"]):
		return
	sockets[first_index]["connected"] = true
	sockets[second_index]["connected"] = true
	_set_socket_style(first_index, "connected")
	_set_socket_style(second_index, "connected")
	_draw_cable(sockets[first_index], sockets[second_index])

	connected += 1
	score = connected
	ritual_bar.value = connected
	verdict_label.text = tr("GPU_RITUAL_GOOD_CABLE")
	verdict_label.add_theme_color_override("font_color", Color("#5cff86"))
	_update_status()

	if connected >= TARGET_CONNECTIONS:
		_update_altar(true)
		await finish_with_result(true, "GPU_RITUAL_SUCCESS", 0.75)

func _draw_cable(first: Dictionary, second: Dictionary) -> void:
	var first_node := first["node"] as Control
	var second_node := second["node"] as Control
	var start := _socket_anchor(first_node, String(first["side"]))
	var end := _socket_anchor(second_node, String(second["side"]))
	var points := _rope_points(start, end)
	cable_layer.add_child(_make_rope_bundle(first["color"], points, 1))

func _select_socket(index: int) -> void:
	if selected_index != -1:
		_set_socket_style(selected_index, "normal")
	selected_index = index
	_set_socket_style(index, "selected")
	_draw_dangling_cable(index)

func _begin_drag_from_socket(index: int) -> void:
	_select_socket(index)
	dragging_cable = true
	_update_dangling_cable(get_viewport().get_mouse_position())
	play_action_sound("move")

func _finish_drag(point: Vector2) -> void:
	dragging_cable = false
	if selected_index == -1:
		_clear_dangling_cable()
		return

	var target_index := _find_socket_at(point)
	if target_index == selected_index:
		_update_dangling_cable(point)
		return
	if target_index != -1 and not bool(sockets[target_index]["connected"]) and sockets[selected_index]["side"] != sockets[target_index]["side"]:
		_try_connect(selected_index, target_index)
		return

	_update_dangling_cable(point)

func _clear_selection() -> void:
	dragging_cable = false
	_clear_dangling_cable()
	if selected_index != -1 and not bool(sockets[selected_index]["connected"]):
		_set_socket_style(selected_index, "normal")
	selected_index = -1

func _draw_dangling_cable(index: int, tip: Vector2 = Vector2(-99999.0, -99999.0)) -> void:
	_clear_dangling_cable()
	var socket := sockets[index]
	var node := socket["node"] as Control
	var side := String(socket["side"])
	var start := _socket_anchor(node, side)
	var direction := 1.0 if side == "left" else -1.0
	var end := tip
	if end.x < -90000.0:
		end = start + Vector2(96.0 * direction, 58)
	var points := _rope_points(start, end)
	dangling_cable_shadow = _make_rope_line(Color("#00000070"), 24, points, 2, Vector2(0, 7))
	dangling_cable_jacket = _make_rope_line(Color("#171116"), 18, points, 3)
	dangling_cable = _make_rope_line((socket["color"] as Color).lightened(0.02), 12, points, 4)
	dangling_cable_highlight = _make_rope_line((socket["color"] as Color).lightened(0.52), 3, points, 5, Vector2(-2, -3))
	cable_layer.add_child(dangling_cable_shadow)
	cable_layer.add_child(dangling_cable_jacket)
	cable_layer.add_child(dangling_cable)
	cable_layer.add_child(dangling_cable_highlight)
	dangling_plug = _make_drag_plug(socket["color"])
	content_layer.add_child(dangling_plug)
	_place_drag_plug(points)

func _update_dangling_cable(tip: Vector2) -> void:
	if selected_index == -1 or not dangling_cable:
		return
	var socket := sockets[selected_index]
	var node := socket["node"] as Control
	var start := _socket_anchor(node, String(socket["side"]))
	var points := _rope_points(start, tip)
	dangling_cable.points = points
	if dangling_cable_shadow:
		dangling_cable_shadow.points = points
	if dangling_cable_jacket:
		dangling_cable_jacket.points = points
	if dangling_cable_highlight:
		dangling_cable_highlight.points = points
	_place_drag_plug(points)

func _clear_dangling_cable() -> void:
	if dangling_cable and is_instance_valid(dangling_cable):
		dangling_cable.queue_free()
	dangling_cable = null
	if dangling_cable_shadow and is_instance_valid(dangling_cable_shadow):
		dangling_cable_shadow.queue_free()
	dangling_cable_shadow = null
	if dangling_cable_jacket and is_instance_valid(dangling_cable_jacket):
		dangling_cable_jacket.queue_free()
	dangling_cable_jacket = null
	if dangling_cable_highlight and is_instance_valid(dangling_cable_highlight):
		dangling_cable_highlight.queue_free()
	dangling_cable_highlight = null
	if dangling_plug and is_instance_valid(dangling_plug):
		dangling_plug.queue_free()
	dangling_plug = null

func _drop_wrong_cable(first: Dictionary, second: Dictionary) -> void:
	_clear_dangling_cable()
	var first_node := first["node"] as Control
	var second_node := second["node"] as Control
	var start := _socket_anchor(first_node, String(first["side"]))
	var end := _socket_anchor(second_node, String(second["side"]))
	var rope := _make_rope_bundle(first["color"], _rope_points(start, end, 58.0), 2)
	cable_layer.add_child(rope)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(rope, "position:y", rope.position.y + 150.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(rope, "rotation", 0.18, 0.36)
	tween.tween_property(rope, "modulate:a", 0.0, 0.36)
	tween.chain().tween_callback(Callable(rope, "queue_free"))

func _socket_anchor(node: Control, side: String) -> Vector2:
	var rect := node.get_global_rect()
	if side == "left":
		return rect.position + Vector2(rect.size.x, rect.size.y * 0.5)
	return rect.position + Vector2(0, rect.size.y * 0.5)

func _rope_points(start: Vector2, end: Vector2, extra_sag: float = 0.0) -> PackedVector2Array:
	var distance := start.distance_to(end)
	var sag := clampf(distance * 0.17 + 24.0 + extra_sag, 32.0, 164.0)
	var points := PackedVector2Array()
	for step in range(34):
		var t := float(step) / 33.0
		var point := start.lerp(end, t)
		point.y += sin(t * PI) * sag
		points.append(point)
	return points

func _make_rope_bundle(color: Color, points: PackedVector2Array, z: int) -> Node2D:
	var bundle := Node2D.new()
	bundle.z_index = z
	bundle.add_child(_make_rope_line(Color("#00000068"), 24, points, 0, Vector2(0, 7)))
	bundle.add_child(_make_rope_line(Color("#171116"), 18, points, 1))
	bundle.add_child(_make_rope_line((color as Color).lightened(0.02), 12, points, 2))
	bundle.add_child(_make_rope_line((color as Color).lightened(0.52), 3, points, 3, Vector2(-2, -3)))
	_add_rope_twists(bundle, color, points)
	return bundle

func _make_rope_line(color: Color, width: float, points: PackedVector2Array, z: int, offset: Vector2 = Vector2.ZERO) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = points
	line.position = offset
	line.z_index = z
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	return line

func _add_rope_twists(bundle: Node2D, color: Color, points: PackedVector2Array) -> void:
	var twist_color := (color as Color).darkened(0.28)
	for index in range(4, points.size() - 4, 5):
		var tangent := (points[index + 2] - points[index - 2]).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var center := points[index]
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = twist_color
		line.points = PackedVector2Array([
			center - normal * 7.0 - tangent * 3.5,
			center + normal * 7.0 + tangent * 3.5
		])
		line.z_index = 4
		line.antialiased = true
		bundle.add_child(line)

func _make_drag_plug(wire_color: Color) -> Control:
	var plug := Control.new()
	plug.size = Vector2(88, 54)
	plug.pivot_offset = Vector2(80, 27)
	plug.z_index = 8
	plug.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shadow := PanelContainer.new()
	shadow.position = Vector2(25, 13)
	shadow.size = Vector2(40, 32)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.modulate = Color("#0000005f")
	shadow.add_theme_stylebox_override("panel", make_style(Color("#0000005f"), Color("#00000000"), 0, 10))
	plug.add_child(shadow)

	var cord := ColorRect.new()
	cord.position = Vector2(0, 22)
	cord.size = Vector2(33, 10)
	cord.color = wire_color
	cord.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plug.add_child(cord)

	var cord_highlight := ColorRect.new()
	cord_highlight.position = Vector2(0, 22)
	cord_highlight.size = Vector2(33, 3)
	cord_highlight.color = (wire_color as Color).lightened(0.45)
	cord_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plug.add_child(cord_highlight)

	var body := PanelContainer.new()
	body.position = Vector2(28, 9)
	body.size = Vector2(35, 34)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", make_style(Color("#f6f0d5"), Color("#111111"), 4, 10))
	plug.add_child(body)

	var shine := ColorRect.new()
	shine.position = Vector2(34, 15)
	shine.size = Vector2(21, 5)
	shine.color = Color("#ffffff99")
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plug.add_child(shine)

	for y in [16, 33]:
		var prong := ColorRect.new()
		prong.position = Vector2(61, y)
		prong.size = Vector2(23, 5)
		prong.color = Color("#111111")
		prong.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plug.add_child(prong)
	return plug

func _place_drag_plug(points: PackedVector2Array) -> void:
	if not dangling_plug:
		return
	var tip := points[points.size() - 1]
	var direction := tip - points[maxi(points.size() - 4, 0)]
	if direction.length() < 1.0:
		direction = Vector2.RIGHT
	dangling_plug.rotation = direction.angle()
	dangling_plug.position = tip - dangling_plug.pivot_offset

func _add_rope_anchor_icon(parent: Control, side: String, rope_color: Color) -> void:
	var icon := Control.new()
	icon.position = Vector2(172, 9) if side == "left" else Vector2(8, 9)
	icon.size = Vector2(48, 40)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

	var stub := Line2D.new()
	stub.width = 8.0
	stub.default_color = rope_color
	stub.points = PackedVector2Array([Vector2(0, 20), Vector2(18, 20)]) if side == "left" else PackedVector2Array([Vector2(48, 20), Vector2(30, 20)])
	stub.antialiased = true
	icon.add_child(stub)

	var ring := Line2D.new()
	ring.width = 5.0
	ring.default_color = Color("#151515")
	var center := Vector2(30, 20) if side == "left" else Vector2(18, 20)
	var points := PackedVector2Array()
	for step in range(24):
		var angle := TAU * float(step) / 23.0
		points.append(center + Vector2(cos(angle) * 11.0, sin(angle) * 11.0))
	ring.points = points
	ring.antialiased = true
	icon.add_child(ring)

	var knot := ColorRect.new()
	knot.position = center - Vector2(5, 5)
	knot.size = Vector2(10, 10)
	knot.color = rope_color.lightened(0.16)
	knot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(knot)

func _flash_wrong(index: int) -> void:
	_set_socket_style(index, "wrong")
	await get_tree().create_timer(0.18).timeout
	if index >= 0 and index < sockets.size() and is_instance_valid(sockets[index]["node"]) and not bool(sockets[index]["connected"]):
		_set_socket_style(index, "normal")

func _set_socket_style(index: int, state: String) -> void:
	if index < 0 or index >= sockets.size():
		return
	var card := sockets[index]["node"] as PanelContainer
	if not is_instance_valid(card):
		return

	var border := Color("#1d1d1d")
	var fill := Color("#ffffff")
	match state:
		"selected":
			border = Color("#ffef5f")
			fill = Color("#fff7c7")
		"connected":
			border = Color("#22b851")
			fill = Color("#bdfb7f")
		"wrong":
			border = Color("#1d1d1d")
			fill = Color("#ff7777")
	card.add_theme_stylebox_override("panel", make_style(fill, border, 5, 7))

func _reset_sockets() -> void:
	for index in range(sockets.size()):
		sockets[index]["connected"] = false
		_set_socket_style(index, "normal")

func _update_altar(active: bool) -> void:
	if altar_panel:
		altar_panel.call("configure", Color("#173322") if active else Color("#21182a"), Color("#35d96b") if active else Color("#ff595e"), 4.0, 1.6, true, Color("#0000000c"))
	if center_computer:
		center_computer.modulate = Color.WHITE if active else Color(0.9, 0.84, 0.86, 1.0)
	ritual_bar.value = connected
	altar_label.text = tr("GPU_RITUAL_ALTAR_ON") if active else tr("GPU_RITUAL_ALTAR_OFF")
	altar_label.add_theme_color_override("font_color", Color("#5cff86") if active else Color("#ffb9c6"))
	verdict_label.text = tr("GPU_RITUAL_IDLE") if not active else tr("GPU_RITUAL_DONE")

func _mark_mistake() -> void:
	var index := int(clamp(mistakes - 1, 0, pips.size() - 1))
	if index >= 0 and index < pips.size():
		pips[index].color = Color("#ff5b5b")

func _reset_pips() -> void:
	for pip in pips:
		pip.color = Color("#3d3442")

func _update_status() -> void:
	set_status(tr("GPU_RITUAL_STATUS") % [connected, TARGET_CONNECTIONS, mistakes])

func _clear_cables() -> void:
	_clear_dangling_cable()
	if not cable_layer:
		return
	for child in cable_layer.get_children():
		child.queue_free()

func _find_socket_index(card: PanelContainer) -> int:
	for index in range(sockets.size()):
		if sockets[index]["node"] == card:
			return index
	return -1

func _find_socket_at(point: Vector2) -> int:
	for index in range(sockets.size()):
		var card := sockets[index]["node"] as Control
		if is_instance_valid(card) and card.get_global_rect().grow(12.0).has_point(point):
			return index
	return -1

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
	content_layer.add_child(panel)
	return panel

func _icon(name: String, pos: Vector2, icon_size: Vector2, color: Color) -> Control:
	var icon: Control = SketchIcon.new()
	icon.position = pos
	icon.size = icon_size
	icon.call("configure", name, color, Color("#ffffff"))
	content_layer.add_child(icon)
	return icon

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff") if color != Color("#ffffff") else Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	var success := connected >= TARGET_CONNECTIONS
	await finish_with_result(success, "GPU_RITUAL_TIMEOUT_SUCCESS" if success else "GPU_RITUAL_TIMEOUT_FAIL", 0.45)
