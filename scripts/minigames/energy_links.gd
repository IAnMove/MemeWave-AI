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
var connected := 0
var mistakes := 0
var cable_layer: Node2D
var dangling_cable: Line2D
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
	var line := Line2D.new()
	line.width = 10
	line.default_color = first["color"]
	var start := _socket_anchor(first_node, String(first["side"]))
	var end := _socket_anchor(second_node, String(second["side"]))
	line.points = PackedVector2Array([
		start,
		start.lerp(end, 0.5) + Vector2(0, 34),
		end
	])
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
	if not cable_layer:
		return
	for child in cable_layer.get_children():
		child.queue_free()

func _find_socket_index(card: PanelContainer) -> int:
	for index in range(sockets.size()):
		if sockets[index]["node"] == card:
			return index
	return -1

func on_timeout() -> void:
	var success := connected >= TARGET_CONNECTIONS
	await finish_with_result(success, "ENERGY_TIMEOUT_SUCCESS" if success else "ENERGY_FAIL", 0.45)
