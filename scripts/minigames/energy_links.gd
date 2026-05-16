extends "res://scripts/minigames/base_minigame.gd"

const TARGET_CONNECTIONS := 4
const BG_PATH := "res://assets/art/energy_links_bg.png"
const INK := Color("#161616")
const PAPER := Color("#fff8dc")
const PAIRS := [
	{
		"id": "plug",
		"left_key": "ENERGY_LEFT_PLUG",
		"right_key": "ENERGY_RIGHT_MOTOR",
		"color": "#ff595e"
	},
	{
		"id": "solar",
		"left_key": "ENERGY_LEFT_SOLAR",
		"right_key": "ENERGY_RIGHT_BATTERY",
		"color": "#ffca3a"
	},
	{
		"id": "gpu",
		"left_key": "ENERGY_LEFT_GPU",
		"right_key": "ENERGY_RIGHT_RACK",
		"color": "#1982c4"
	},
	{
		"id": "hamster",
		"left_key": "ENERGY_LEFT_HAMSTER",
		"right_key": "ENERGY_RIGHT_GENERATOR",
		"color": "#8ac926"
	}
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
var model_panel: PanelContainer
var model_status: Label
var monitor_screen: PanelContainer
var monitor_glow: ColorRect
var computer_case: PanelContainer
var computer_light: ColorRect
var screen_lines: Array[ColorRect] = []
var work_label: Label
var energy_bar: ProgressBar

class EnergySocketIcon:
	extends Control

	var side := "left"
	var pair_id := "plug"
	var accent := Color("#ff595e")

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
				"plug":
					icon_id = "motor"
				"solar":
					icon_id = "battery"
				"gpu":
					icon_id = "rack"
				"hamster":
					icon_id = "generator"
		match icon_id:
			"solar":
				_draw_solar()
			"battery":
				_draw_battery()
			"gpu":
				_draw_gpu()
			"rack":
				_draw_rack()
			"hamster":
				_draw_hamster()
			"generator":
				_draw_generator()
			"motor":
				_draw_motor()
			_:
				_draw_plug()

	func _draw_solar() -> void:
		_draw_sun(Vector2(size.x * 0.24, size.y * 0.25), size.x * 0.12)
		var panel := Rect2(Vector2(size.x * 0.28, size.y * 0.32), Vector2(size.x * 0.54, size.y * 0.42))
		draw_rect(panel, Color("#1f4f9a"), true)
		_wobbly_rect(panel, INK, 3.0)
		for index in range(1, 3):
			var x := panel.position.x + panel.size.x * float(index) / 3.0
			draw_line(Vector2(x, panel.position.y + 4), Vector2(x, panel.position.y + panel.size.y - 4), Color("#ffffff88"), 1.5, true)
		draw_line(panel.position + Vector2(4, panel.size.y * 0.5), panel.position + Vector2(panel.size.x - 4, panel.size.y * 0.5), Color("#ffffff88"), 1.5, true)

	func _draw_plug() -> void:
		draw_line(Vector2(size.x * 0.08, size.y * 0.50), Vector2(size.x * 0.42, size.y * 0.50), accent, 6.0, true)
		var body := Rect2(Vector2(size.x * 0.36, size.y * 0.27), Vector2(size.x * 0.32, size.y * 0.46))
		draw_rect(body, PAPER, true)
		_wobbly_rect(body, INK, 3.0)
		draw_line(Vector2(size.x * 0.68, size.y * 0.39), Vector2(size.x * 0.88, size.y * 0.39), INK, 4.0, true)
		draw_line(Vector2(size.x * 0.68, size.y * 0.61), Vector2(size.x * 0.88, size.y * 0.61), INK, 4.0, true)

	func _draw_gpu() -> void:
		var card := Rect2(Vector2(size.x * 0.12, size.y * 0.24), Vector2(size.x * 0.72, size.y * 0.48))
		draw_rect(card, Color("#263041"), true)
		_wobbly_rect(card, INK, 3.0)
		draw_circle(card.position + Vector2(card.size.x * 0.28, card.size.y * 0.50), size.x * 0.13, Color("#66c6ff"))
		draw_arc(card.position + Vector2(card.size.x * 0.28, card.size.y * 0.50), size.x * 0.09, 0.0, TAU, 16, INK, 2.0, true)
		draw_rect(Rect2(card.position + Vector2(card.size.x * 0.50, 12), Vector2(card.size.x * 0.36, 7)), accent, true)
		draw_line(Vector2(card.position.x + 8, card.position.y + card.size.y + 5), Vector2(card.position.x + card.size.x - 8, card.position.y + card.size.y + 5), Color("#ffca3a"), 4.0, true)

	func _draw_hamster() -> void:
		var center := Vector2(size.x * 0.44, size.y * 0.52)
		draw_arc(center, size.x * 0.27, 0.0, TAU, 30, INK, 4.0, true)
		draw_arc(center, size.x * 0.21, 0.0, TAU, 30, Color("#c98a36"), 3.0, true)
		draw_line(center + Vector2(-14, 0), center + Vector2(14, 0), INK, 2.0, true)
		draw_line(center + Vector2(0, -14), center + Vector2(0, 14), INK, 2.0, true)
		draw_circle(center + Vector2(0, 7), size.x * 0.08, Color("#d8a35d"))
		draw_circle(center + Vector2(5, 4), 1.8, INK)
		draw_line(Vector2(size.x * 0.66, size.y * 0.62), Vector2(size.x * 0.88, size.y * 0.68), accent, 4.0, true)

	func _draw_motor() -> void:
		var body := Rect2(Vector2(size.x * 0.18, size.y * 0.34), Vector2(size.x * 0.52, size.y * 0.32))
		draw_rect(body, Color("#c7c7c7"), true)
		_wobbly_rect(body, INK, 3.0)
		draw_circle(Vector2(size.x * 0.76, size.y * 0.50), size.x * 0.12, accent)
		draw_arc(Vector2(size.x * 0.76, size.y * 0.50), size.x * 0.12, 0.0, TAU, 20, INK, 2.5, true)
		draw_line(Vector2(size.x * 0.06, size.y * 0.64), Vector2(size.x * 0.88, size.y * 0.64), INK, 3.0, true)

	func _draw_battery() -> void:
		var body := Rect2(Vector2(size.x * 0.18, size.y * 0.25), Vector2(size.x * 0.56, size.y * 0.50))
		draw_rect(body, Color("#313740"), true)
		_wobbly_rect(body, INK, 3.0)
		draw_rect(Rect2(Vector2(body.end.x, body.position.y + body.size.y * 0.30), Vector2(size.x * 0.10, body.size.y * 0.40)), accent, true)
		draw_line(body.position + Vector2(10, body.size.y * 0.50), body.position + Vector2(body.size.x - 10, body.size.y * 0.50), Color("#ffffff8c"), 3.0, true)
		draw_line(body.position + Vector2(body.size.x * 0.28, 10), body.position + Vector2(body.size.x * 0.28, body.size.y - 10), Color("#ff595e"), 3.0, true)
		draw_line(body.position + Vector2(body.size.x * 0.50, 10), body.position + Vector2(body.size.x * 0.50, body.size.y - 10), Color("#ffca3a"), 3.0, true)
		draw_line(body.position + Vector2(body.size.x * 0.72, 10), body.position + Vector2(body.size.x * 0.72, body.size.y - 10), Color("#8ac926"), 3.0, true)

	func _draw_rack() -> void:
		var rack := Rect2(Vector2(size.x * 0.18, size.y * 0.16), Vector2(size.x * 0.58, size.y * 0.70))
		draw_rect(rack, Color("#2a3038"), true)
		_wobbly_rect(rack, INK, 3.0)
		for index in range(3):
			var shelf := Rect2(rack.position + Vector2(7, 8 + index * 15), Vector2(rack.size.x - 14, 10))
			draw_rect(shelf, Color("#11151a"), true)
			draw_circle(shelf.position + Vector2(shelf.size.x - 8, 5), 2.4, [Color("#ff595e"), Color("#ffca3a"), Color("#8ac926")][index])

	func _draw_generator() -> void:
		var base := Rect2(Vector2(size.x * 0.14, size.y * 0.34), Vector2(size.x * 0.56, size.y * 0.34))
		draw_rect(base, Color("#e2e2d8"), true)
		_wobbly_rect(base, INK, 3.0)
		draw_circle(Vector2(size.x * 0.70, size.y * 0.51), size.x * 0.14, accent)
		draw_arc(Vector2(size.x * 0.70, size.y * 0.51), size.x * 0.14, 0.0, TAU, 18, INK, 3.0, true)
		draw_line(Vector2(size.x * 0.16, size.y * 0.30), Vector2(size.x * 0.64, size.y * 0.30), INK, 2.0, true)
		draw_line(Vector2(size.x * 0.22, size.y * 0.22), Vector2(size.x * 0.28, size.y * 0.34), INK, 2.0, true)

	func _draw_sun(center: Vector2, radius: float) -> void:
		draw_circle(center, radius, Color("#ffca3a"))
		for index in range(8):
			var angle := TAU * float(index) / 8.0
			draw_line(center + Vector2(cos(angle), sin(angle)) * (radius + 3.0), center + Vector2(cos(angle), sin(angle)) * (radius + 10.0), Color("#ffca3a"), 2.5, true)

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
	configure(
		"GAME_ENERGY_TITLE",
		"ENERGY_INSTRUCTIONS",
		"GAME_ENERGY_DESC",
		BG_PATH
	)
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
	_clear_cables()
	_reset_sockets()
	_update_model_state(false)
	_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fff1cf")
	add_child(bg)
	move_child(bg, 0)

	cable_layer = Node2D.new()
	cable_layer.z_index = 1
	content_layer.add_child(cable_layer)

	_build_column(Vector2(50, 218), tr("ENERGY_SOURCES"), "left")
	_build_column(Vector2(944, 218), tr("ENERGY_TARGETS"), "right")
	_build_model_panel()
	_build_sockets()

func _build_column(position: Vector2, title_text: String, side: String) -> void:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = Vector2(288, 404)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6ec"), INK, 5, 8))
	content_layer.add_child(panel)

	var title := make_label(title_text, 26, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = position + Vector2(14, 12)
	title.size = Vector2(260, 70)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(title)

func _build_model_panel() -> void:
	model_panel = PanelContainer.new()
	model_panel.position = Vector2(384, 230)
	model_panel.size = Vector2(512, 382)
	model_panel.add_theme_stylebox_override("panel", make_style(Color("#20242ae8"), Color("#ff595e"), 6, 8))
	content_layer.add_child(model_panel)

	var title := make_label(tr("ENERGY_MODEL_NAME"), 35, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(420, 250)
	title.size = Vector2(440, 46)
	title.add_theme_color_override("font_outline_color", Color("#111111"))
	title.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(title)

	_build_power_devices()

	model_status = make_label("", 36, Color("#ff5b5b"), HORIZONTAL_ALIGNMENT_CENTER)
	model_status.position = Vector2(416, 472)
	model_status.size = Vector2(448, 52)
	model_status.add_theme_color_override("font_outline_color", Color("#111111"))
	model_status.add_theme_constant_override("outline_size", 6)
	content_layer.add_child(model_status)

	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(468, 536)
	energy_bar.size = Vector2(344, 28)
	energy_bar.min_value = 0
	energy_bar.max_value = 100
	energy_bar.show_percentage = false
	content_layer.add_child(energy_bar)

	work_label = make_label(tr("ENERGY_WORK_IDLE"), 22, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	work_label.position = Vector2(438, 566)
	work_label.size = Vector2(404, 34)
	work_label.add_theme_color_override("font_outline_color", Color("#111111"))
	work_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(work_label)

func _build_power_devices() -> void:
	monitor_screen = PanelContainer.new()
	monitor_screen.position = Vector2(438, 316)
	monitor_screen.size = Vector2(190, 112)
	monitor_screen.add_theme_stylebox_override("panel", make_style(Color("#11151a"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(monitor_screen)

	monitor_glow = ColorRect.new()
	monitor_glow.position = Vector2(452, 330)
	monitor_glow.size = Vector2(162, 84)
	monitor_glow.color = Color("#05070a")
	monitor_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(monitor_glow)

	var monitor_stand := PanelContainer.new()
	monitor_stand.position = Vector2(512, 428)
	monitor_stand.size = Vector2(42, 34)
	monitor_stand.add_theme_stylebox_override("panel", make_style(Color("#555555"), Color("#1d1d1d"), 3, 4))
	content_layer.add_child(monitor_stand)

	var monitor_base := PanelContainer.new()
	monitor_base.position = Vector2(474, 458)
	monitor_base.size = Vector2(118, 18)
	monitor_base.add_theme_stylebox_override("panel", make_style(Color("#6a6a6a"), Color("#1d1d1d"), 3, 8))
	content_layer.add_child(monitor_base)

	computer_case = PanelContainer.new()
	computer_case.position = Vector2(666, 318)
	computer_case.size = Vector2(150, 142)
	computer_case.add_theme_stylebox_override("panel", make_style(Color("#55575d"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(computer_case)

	var drive_slot := ColorRect.new()
	drive_slot.position = Vector2(690, 348)
	drive_slot.size = Vector2(86, 10)
	drive_slot.color = Color("#1a1a1a")
	content_layer.add_child(drive_slot)

	computer_light = ColorRect.new()
	computer_light.position = Vector2(782, 430)
	computer_light.size = Vector2(14, 14)
	computer_light.color = Color("#4b3f3f")
	content_layer.add_child(computer_light)

	screen_lines.clear()
	for index in range(3):
		var line := ColorRect.new()
		line.position = Vector2(470, 350 + index * 20)
		line.size = Vector2(0, 6)
		line.color = Color("#9cff8a")
		content_layer.add_child(line)
		screen_lines.append(line)

func _build_sockets() -> void:
	var left_x := 78
	var right_x := 976
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

	var item_icon := EnergySocketIcon.new()
	item_icon.position = Vector2(162, 5) if side == "left" else Vector2(8, 5)
	item_icon.size = Vector2(60, 48)
	item_icon.configure(side, pair_id, wire_color)
	inner.add_child(item_icon)

	var label := make_label(label_text, 16, INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(10, 2)
	label.size = Vector2(148, 54)
	if side == "right":
		label.position.x = 70
		label.size.x = 148
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(label)

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
		_update_status()

func _connect_pair(first_index: int, second_index: int) -> void:
	sockets[first_index]["connected"] = true
	sockets[second_index]["connected"] = true
	_set_socket_style(first_index, "connected")
	_set_socket_style(second_index, "connected")
	_draw_cable(sockets[first_index], sockets[second_index])

	connected += 1
	score = connected
	energy_bar.value = connected * 100.0 / TARGET_CONNECTIONS
	_update_status()

	if connected >= TARGET_CONNECTIONS:
		_update_model_state(true)
		await finish_with_result(true, "ENERGY_SUCCESS", 0.75)

func _draw_cable(first: Dictionary, second: Dictionary) -> void:
	var first_node := first["node"] as Control
	var second_node := second["node"] as Control
	var start := _socket_anchor(first_node, String(first["side"]))
	var end := _socket_anchor(second_node, String(second["side"]))
	var points := _cable_points(start, end)
	cable_layer.add_child(_make_cable_bundle(first["color"], points, 0))

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
		end = start + Vector2(98.0 * direction, 58)
	var points := _cable_points(start, end)
	dangling_cable_shadow = _make_cable_line(Color("#00000076"), 24, points, 2, Vector2(0, 7))
	dangling_cable_jacket = _make_cable_line(Color("#111111"), 18, points, 3)
	dangling_cable = _make_cable_line((socket["color"] as Color).lightened(0.04), 12, points, 4)
	dangling_cable_highlight = _make_cable_line((socket["color"] as Color).lightened(0.48), 3, points, 5, Vector2(-2, -3))
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
	var points := _cable_points(start, tip)
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
	var group := Node2D.new()
	group.z_index = 2
	var points := _cable_points(start, end, 58.0)
	group.add_child(_make_cable_bundle(first["color"], points, 0))
	cable_layer.add_child(group)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(group, "position:y", group.position.y + 150.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(group, "rotation", 0.18, 0.36)
	tween.tween_property(group, "modulate:a", 0.0, 0.36)
	tween.chain().tween_callback(Callable(group, "queue_free"))

func _socket_anchor(node: Control, side: String) -> Vector2:
	var rect := node.get_global_rect()
	if side == "left":
		return rect.position + Vector2(rect.size.x, rect.size.y * 0.5)
	return rect.position + Vector2(0, rect.size.y * 0.5)

func _cable_points(start: Vector2, end: Vector2, extra_sag: float = 0.0) -> PackedVector2Array:
	var distance := start.distance_to(end)
	var sag := clampf(distance * 0.16 + 22.0 + extra_sag, 30.0, 154.0)
	var points := PackedVector2Array()
	for step in range(32):
		var t := float(step) / 31.0
		var point := start.lerp(end, t)
		point.y += sin(t * PI) * sag
		points.append(point)
	return points

func _make_cable_bundle(color: Color, points: PackedVector2Array, z: int) -> Node2D:
	var bundle := Node2D.new()
	bundle.z_index = z
	bundle.add_child(_make_cable_line(Color("#00000068"), 24, points, 0, Vector2(0, 7)))
	bundle.add_child(_make_cable_line(Color("#111111"), 18, points, 1))
	bundle.add_child(_make_cable_line((color as Color).lightened(0.04), 12, points, 2))
	bundle.add_child(_make_cable_line((color as Color).lightened(0.48), 3, points, 3, Vector2(-2, -3)))
	return bundle

func _make_cable_line(color: Color, width: float, points: PackedVector2Array, z: int, offset: Vector2 = Vector2.ZERO) -> Line2D:
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

func _add_connector_icon(parent: Control, side: String, wire_color: Color) -> void:
	var icon := Control.new()
	icon.position = Vector2(170, 7) if side == "left" else Vector2(8, 7)
	icon.size = Vector2(52, 44)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

	if side == "left":
		var cord := ColorRect.new()
		cord.position = Vector2(0, 19)
		cord.size = Vector2(19, 7)
		cord.color = wire_color
		cord.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(cord)

		var body := PanelContainer.new()
		body.position = Vector2(16, 10)
		body.size = Vector2(25, 24)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_theme_stylebox_override("panel", make_style(Color("#f7f3dc"), Color("#151515"), 4, 7))
		icon.add_child(body)

		for y in [14, 27]:
			var prong := ColorRect.new()
			prong.position = Vector2(39, y)
			prong.size = Vector2(12, 4)
			prong.color = Color("#151515")
			prong.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.add_child(prong)
	else:
		var plate := PanelContainer.new()
		plate.position = Vector2(5, 4)
		plate.size = Vector2(42, 36)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_theme_stylebox_override("panel", make_style(Color("#fffdf0"), Color("#151515"), 4, 8))
		icon.add_child(plate)

		for x in [17, 30]:
			var hole := ColorRect.new()
			hole.position = Vector2(x, 15)
			hole.size = Vector2(5, 12)
			hole.color = Color("#151515")
			hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.add_child(hole)

		var ground := ColorRect.new()
		ground.position = Vector2(23, 29)
		ground.size = Vector2(7, 5)
		ground.color = Color("#151515")
		ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(ground)

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

func _flash_wrong(index: int) -> void:
	_set_socket_style(index, "wrong")
	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(sockets[index]["node"]) and not bool(sockets[index]["connected"]):
		_set_socket_style(index, "normal")

func _set_socket_style(index: int, state: String) -> void:
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

func _update_model_state(active: bool) -> void:
	if active:
		model_panel.add_theme_stylebox_override("panel", make_style(Color("#163322"), Color("#35d96b"), 6, 8))
		model_status.text = tr("ENERGY_MODEL_ON")
		model_status.add_theme_color_override("font_color", Color("#5cff86"))
		if monitor_screen:
			monitor_screen.add_theme_stylebox_override("panel", make_style(Color("#233d35"), Color("#35d96b"), 5, 8))
		if monitor_glow:
			monitor_glow.color = Color("#173322")
		if computer_case:
			computer_case.add_theme_stylebox_override("panel", make_style(Color("#c5d1d0"), Color("#35d96b"), 5, 8))
		if computer_light:
			computer_light.color = Color("#5cff86")
		for index in range(screen_lines.size()):
			screen_lines[index].size.x = 58 + index * 34
		work_label.text = tr("ENERGY_WORK_ON")
	else:
		model_panel.add_theme_stylebox_override("panel", make_style(Color("#20242a"), Color("#ff595e"), 6, 8))
		model_status.text = tr("ENERGY_MODEL_OFF")
		model_status.add_theme_color_override("font_color", Color("#ff5b5b"))
		if monitor_screen:
			monitor_screen.add_theme_stylebox_override("panel", make_style(Color("#11151a"), Color("#1d1d1d"), 5, 8))
		if monitor_glow:
			monitor_glow.color = Color("#05070a")
		if computer_case:
			computer_case.add_theme_stylebox_override("panel", make_style(Color("#55575d"), Color("#1d1d1d"), 5, 8))
		if computer_light:
			computer_light.color = Color("#4b3f3f")
		for line in screen_lines:
			line.size.x = 0
		energy_bar.value = 0
		work_label.text = tr("ENERGY_WORK_IDLE")

func _update_status() -> void:
	set_status(tr("ENERGY_STATUS") % [connected, TARGET_CONNECTIONS, mistakes])

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

func on_timeout() -> void:
	var success := connected >= TARGET_CONNECTIONS
	await finish_with_result(success, "ENERGY_TIMEOUT_SUCCESS" if success else "ENERGY_FAIL", 0.45)
