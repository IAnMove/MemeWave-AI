extends "res://scripts/minigames/base_minigame.gd"

const TARGET_CONNECTIONS := 4
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

func _ready() -> void:
	configure(
		"GAME_ENERGY_TITLE",
		"ENERGY_INSTRUCTIONS",
		"GAME_ENERGY_DESC",
		""
	)
	super._ready()
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
	bg.color = Color("#162331")
	add_child(bg)
	move_child(bg, 0)

	cable_layer = Node2D.new()
	cable_layer.z_index = 1
	content_layer.add_child(cable_layer)

	_build_column(Vector2(58, 228), tr("ENERGY_SOURCES"), "left")
	_build_column(Vector2(944, 228), tr("ENERGY_TARGETS"), "right")
	_build_model_panel()
	_build_sockets()

func _build_column(position: Vector2, title_text: String, side: String) -> void:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = Vector2(278, 390)
	panel.add_theme_stylebox_override("panel", make_style(Color("#f7f4df"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(title_text, 29, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = position + Vector2(12, 12)
	title.size = Vector2(254, 40)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(title)

	var side_label_key := "ENERGY_CLICK_SOURCE" if side == "left" else "ENERGY_CLICK_TARGET"
	var hint := make_label(tr(side_label_key), 16, Color("#3d3d3d"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = position + Vector2(14, 350)
	hint.size = Vector2(250, 30)
	content_layer.add_child(hint)

func _build_model_panel() -> void:
	model_panel = PanelContainer.new()
	model_panel.position = Vector2(384, 234)
	model_panel.size = Vector2(512, 370)
	model_panel.add_theme_stylebox_override("panel", make_style(Color("#20242a"), Color("#ff595e"), 6, 8))
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
	work_label.position = Vector2(438, 592)
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
	var left_x := 82
	var right_x := 968
	var start_y := 298
	var gap := 76
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

	_add_connector_icon(inner, side, wire_color)

	var label := make_label(label_text, 17, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(14, 2)
	label.size = Vector2(160, 54)
	if side == "right":
		label.position.x = 58
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
	var shadow := _make_cable_line(Color("#111111"), 18, points, 0)
	var line := _make_cable_line(first["color"], 10, points, 1)
	cable_layer.add_child(shadow)
	cable_layer.add_child(line)

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
	dangling_cable_shadow = _make_cable_line(Color("#111111"), 18, points, 2)
	dangling_cable = _make_cable_line(socket["color"], 10, points, 3)
	dangling_cable.z_index = 2
	cable_layer.add_child(dangling_cable_shadow)
	cable_layer.add_child(dangling_cable)
	dangling_plug = _make_drag_plug(socket["color"])
	content_layer.add_child(dangling_plug)
	_place_drag_plug(start, end)

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
	_place_drag_plug(start, tip)

func _clear_dangling_cable() -> void:
	if dangling_cable and is_instance_valid(dangling_cable):
		dangling_cable.queue_free()
	dangling_cable = null
	if dangling_cable_shadow and is_instance_valid(dangling_cable_shadow):
		dangling_cable_shadow.queue_free()
	dangling_cable_shadow = null
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
	group.add_child(_make_cable_line(Color("#111111"), 18, points, 0))
	group.add_child(_make_cable_line(first["color"], 10, points, 1))
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
	var sag := clampf(distance * 0.12 + 18.0 + extra_sag, 28.0, 118.0)
	return PackedVector2Array([
		start,
		start.lerp(end, 0.34) + Vector2(0, sag * 0.45),
		start.lerp(end, 0.68) + Vector2(0, sag),
		end
	])

func _make_cable_line(color: Color, width: float, points: PackedVector2Array, z: int) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = points
	line.z_index = z
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
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
	plug.size = Vector2(74, 42)
	plug.pivot_offset = Vector2(66, 21)
	plug.z_index = 8
	plug.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var cord := ColorRect.new()
	cord.position = Vector2(0, 17)
	cord.size = Vector2(31, 9)
	cord.color = wire_color
	cord.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plug.add_child(cord)

	var body := PanelContainer.new()
	body.position = Vector2(26, 7)
	body.size = Vector2(31, 28)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", make_style(Color("#f6f0d5"), Color("#111111"), 4, 8))
	plug.add_child(body)

	for y in [12, 27]:
		var prong := ColorRect.new()
		prong.position = Vector2(55, y)
		prong.size = Vector2(17, 5)
		prong.color = Color("#111111")
		prong.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plug.add_child(prong)
	return plug

func _place_drag_plug(start: Vector2, tip: Vector2) -> void:
	if not dangling_plug:
		return
	var direction := tip - start
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
