extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_CONNECTIONS := 4
const MISTAKE_LIMIT := 3
const PAIRS := [
	{"id": "gpu", "left_key": "GPU_RITUAL_LEFT_GPU", "right_key": "GPU_RITUAL_RIGHT_ALTAR", "color": "#1982c4"},
	{"id": "fan", "left_key": "GPU_RITUAL_LEFT_FAN", "right_key": "GPU_RITUAL_RIGHT_WIND", "color": "#8ac926"},
	{"id": "cash", "left_key": "GPU_RITUAL_LEFT_CASH", "right_key": "GPU_RITUAL_RIGHT_FIRE", "color": "#ffca3a"},
	{"id": "power", "left_key": "GPU_RITUAL_LEFT_POWER", "right_key": "GPU_RITUAL_RIGHT_SOCKET", "color": "#ff595e"}
]

var sockets: Array[Dictionary] = []
var selected_index := -1
var connected := 0
var mistakes := 0
var cable_layer: Node2D
var dangling_cable: Line2D
var altar_panel: Control
var altar_label: Label
var ritual_bar: ProgressBar
var verdict_label: Label
var pips: Array[ColorRect] = []

func _ready() -> void:
	configure("GAME_GPU_RITUAL_TITLE", "GPU_RITUAL_INSTRUCTIONS", "GAME_GPU_RITUAL_DESC", "res://assets/art/object_spritesheet.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	selected_index = -1
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
	bg.color = Color("#18131f")
	add_child(bg)
	move_child(bg, 0)

	cable_layer = Node2D.new()
	cable_layer.z_index = 1
	content_layer.add_child(cable_layer)

	_build_column(Vector2(54, 222), tr("GPU_RITUAL_OFFERINGS"), "left")
	_build_column(Vector2(944, 222), tr("GPU_RITUAL_ALTAR_PORTS"), "right")
	_build_altar()
	_build_sockets()

func _build_column(position: Vector2, title_text: String, side: String) -> void:
	_sketch_panel(position, Vector2(286, 404), Color("#fff7d6"), false)
	var title := _outlined_label(title_text, 27, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = position + Vector2(16, 16)
	title.size = Vector2(254, 44)
	content_layer.add_child(title)

	var hint_key := "GPU_RITUAL_CLICK_LEFT" if side == "left" else "GPU_RITUAL_CLICK_RIGHT"
	var hint := _outlined_label(tr(hint_key), 17, Color("#3d3d3d"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = position + Vector2(18, 358)
	hint.size = Vector2(250, 28)
	content_layer.add_child(hint)

func _build_altar() -> void:
	altar_panel = _sketch_panel(Vector2(400, 238), Vector2(480, 360), Color("#21182a"), true, Color("#ff595e"))
	_icon("spark", Vector2(444, 270), Vector2(48, 48), Color("#ffca3a"))
	_icon("robot", Vector2(546, 302), Vector2(188, 150), Color("#49424f"))
	_icon("spark", Vector2(784, 270), Vector2(48, 48), Color("#ffca3a"))

	var title := _outlined_label(tr("GPU_RITUAL_ALTAR_TITLE"), 34, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(430, 250)
	title.size = Vector2(420, 54)
	content_layer.add_child(title)

	ritual_bar = ProgressBar.new()
	ritual_bar.position = Vector2(468, 472)
	ritual_bar.size = Vector2(344, 32)
	ritual_bar.min_value = 0
	ritual_bar.max_value = TARGET_CONNECTIONS
	ritual_bar.show_percentage = false
	content_layer.add_child(ritual_bar)

	altar_label = _outlined_label("", 27, Color("#ffb9c6"), HORIZONTAL_ALIGNMENT_CENTER)
	altar_label.position = Vector2(436, 516)
	altar_label.size = Vector2(408, 38)
	content_layer.add_child(altar_label)

	verdict_label = _outlined_label("", 23, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(430, 560)
	verdict_label.size = Vector2(420, 36)
	content_layer.add_child(verdict_label)

	for index in range(MISTAKE_LIMIT):
		var pip := ColorRect.new()
		pip.position = Vector2(574 + index * 48, 452)
		pip.size = Vector2(34, 14)
		pip.color = Color("#3d3442")
		content_layer.add_child(pip)
		pips.append(pip)

func _build_sockets() -> void:
	var left_x := 82
	var right_x := 972
	var start_y := 300
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

	var label := make_label(label_text, 18, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(218, 52)
	card.add_child(label)

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
		_select_socket(index)
		return
	if selected_index == index:
		_clear_selection()
		return
	if sockets[selected_index]["side"] == sockets[index]["side"]:
		_select_socket(index)
		return
	_try_connect(selected_index, index)

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
	var line := Line2D.new()
	line.width = 10
	line.default_color = first["color"]
	var start := _socket_anchor(first_node, String(first["side"]))
	var end := _socket_anchor(second_node, String(second["side"]))
	line.points = PackedVector2Array([start, start.lerp(end, 0.5) + Vector2(0, 34), end])
	line.z_index = 1
	cable_layer.add_child(line)

func _select_socket(index: int) -> void:
	if selected_index != -1:
		_set_socket_style(selected_index, "normal")
	selected_index = index
	_set_socket_style(index, "selected")
	_draw_dangling_cable(index)

func _clear_selection() -> void:
	_clear_dangling_cable()
	if selected_index != -1 and not bool(sockets[selected_index]["connected"]):
		_set_socket_style(selected_index, "normal")
	selected_index = -1

func _draw_dangling_cable(index: int) -> void:
	_clear_dangling_cable()
	var socket := sockets[index]
	var node := socket["node"] as Control
	var side := String(socket["side"])
	var start := _socket_anchor(node, side)
	var direction := 1.0 if side == "left" else -1.0
	dangling_cable = Line2D.new()
	dangling_cable.width = 10
	dangling_cable.default_color = socket["color"]
	dangling_cable.points = PackedVector2Array([
		start,
		start + Vector2(42.0 * direction, 38),
		start + Vector2(78.0 * direction, 58)
	])
	dangling_cable.z_index = 2
	cable_layer.add_child(dangling_cable)

func _clear_dangling_cable() -> void:
	if dangling_cable and is_instance_valid(dangling_cable):
		dangling_cable.queue_free()
	dangling_cable = null

func _drop_wrong_cable(first: Dictionary, second: Dictionary) -> void:
	_clear_dangling_cable()
	var first_node := first["node"] as Control
	var second_node := second["node"] as Control
	var start := _socket_anchor(first_node, String(first["side"]))
	var end := _socket_anchor(second_node, String(second["side"]))
	var line := Line2D.new()
	line.width = 10
	line.default_color = first["color"]
	line.points = PackedVector2Array([start, start.lerp(end, 0.55) + Vector2(0, 54), end])
	line.z_index = 2
	cable_layer.add_child(line)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "position:y", line.position.y + 150.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(line, "rotation", 0.18, 0.36)
	tween.tween_property(line, "modulate:a", 0.0, 0.36)
	tween.chain().tween_callback(Callable(line, "queue_free"))

func _socket_anchor(node: Control, side: String) -> Vector2:
	var rect := node.get_global_rect()
	if side == "left":
		return rect.position + Vector2(rect.size.x, rect.size.y * 0.5)
	return rect.position + Vector2(0, rect.size.y * 0.5)

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
	if not cable_layer:
		return
	for child in cable_layer.get_children():
		child.queue_free()

func _find_socket_index(card: PanelContainer) -> int:
	for index in range(sockets.size()):
		if sockets[index]["node"] == card:
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
