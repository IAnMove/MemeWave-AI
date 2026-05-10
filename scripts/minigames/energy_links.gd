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
var model_panel: PanelContainer
var model_status: Label
var model_sprite: TextureRect
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
	model_panel.position = Vector2(406, 245)
	model_panel.size = Vector2(468, 340)
	model_panel.add_theme_stylebox_override("panel", make_style(Color("#20242a"), Color("#ff595e"), 6, 8))
	content_layer.add_child(model_panel)

	var title := make_label(tr("ENERGY_MODEL_NAME"), 35, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(432, 260)
	title.size = Vector2(416, 46)
	title.add_theme_color_override("font_outline_color", Color("#111111"))
	title.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(title)

	model_sprite = make_sprite("res://assets/sprites/hungry_model.png", Vector2(190, 145))
	model_sprite.position = Vector2(545, 310)
	content_layer.add_child(model_sprite)

	model_status = make_label("", 36, Color("#ff5b5b"), HORIZONTAL_ALIGNMENT_CENTER)
	model_status.position = Vector2(432, 468)
	model_status.size = Vector2(416, 52)
	model_status.add_theme_color_override("font_outline_color", Color("#111111"))
	model_status.add_theme_constant_override("outline_size", 6)
	content_layer.add_child(model_status)

	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(468, 532)
	energy_bar.size = Vector2(344, 34)
	energy_bar.min_value = 0
	energy_bar.max_value = 100
	energy_bar.show_percentage = false
	content_layer.add_child(energy_bar)

	work_label = make_label(tr("ENERGY_WORK_IDLE"), 22, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	work_label.position = Vector2(438, 590)
	work_label.size = Vector2(404, 38)
	work_label.add_theme_color_override("font_outline_color", Color("#111111"))
	work_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(work_label)

func _build_sockets() -> void:
	var left_x := 82
	var right_x := 968
	var start_y := 298
	var gap := 76
	for index in range(PAIRS.size()):
		var pair: Dictionary = PAIRS[index]
		var y := start_y + index * gap
		_add_socket("left", pair["id"], tr(pair["left_key"]), Color(pair["color"]), Vector2(left_x, y))
		_add_socket("right", pair["id"], tr(pair["right_key"]), Color(pair["color"]), Vector2(right_x, y))

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
	_clear_selection()

	if first["id"] == second["id"]:
		_connect_pair(first_index, second_index)
	else:
		mistakes += 1
		_flash_wrong(first_index)
		_flash_wrong(second_index)
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
	line.width = 9
	line.default_color = first["color"]
	line.points = PackedVector2Array([
		first_node.get_global_rect().get_center(),
		second_node.get_global_rect().get_center()
	])
	line.z_index = 1
	cable_layer.add_child(line)

func _select_socket(index: int) -> void:
	if selected_index != -1:
		_set_socket_style(selected_index, "normal")
	selected_index = index
	_set_socket_style(index, "selected")

func _clear_selection() -> void:
	if selected_index != -1 and not bool(sockets[selected_index]["connected"]):
		_set_socket_style(selected_index, "normal")
	selected_index = -1

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
			border = Color("#1d1d1d")
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
		model_sprite.modulate = Color("#ffffff")
		work_label.text = tr("ENERGY_WORK_ON")
	else:
		model_panel.add_theme_stylebox_override("panel", make_style(Color("#20242a"), Color("#ff595e"), 6, 8))
		model_status.text = tr("ENERGY_MODEL_OFF")
		model_status.add_theme_color_override("font_color", Color("#ff5b5b"))
		model_sprite.modulate = Color("#777777")
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
