extends "res://scripts/minigames/base_minigame.gd"

const BG_PATH := "res://assets/art/server_room_bg.png"
const COMPUTER_OFF_PATH := "res://assets/art/server_computer_off.png"
const COMPUTER_ON_PATH := "res://assets/art/server_computer_on.png"
const OUTLET_PATH := "res://assets/art/server_outlet.png"
const PLUG_PATH := "res://assets/art/server_plug.png"

const COMPUTER_POS := Vector2(80, 248)
const COMPUTER_SIZE := Vector2(600, 416)
const OUTLET_POS := Vector2(934, 258)
const OUTLET_SIZE := Vector2(214, 232)
const PLUG_SIZE := Vector2(178, 107)
const PLUG_START := Vector2(690, 504)
const PLUG_TIP_LOCAL := Vector2(170, 55)
const PLUG_CABLE_LOCAL := Vector2(8, 55)
const CABLE_START := Vector2(612, 520)
const SOCKET_TARGET := Vector2(1036, 392)
const SNAP_RADIUS := 92.0
const DRAG_MIN := Vector2(315, 244)
const DRAG_MAX := Vector2(1084, 598)

var plug_connected := false
var dragging := false
var drag_offset := Vector2.ZERO
var pulse := 0.0
var return_tween: Tween

var computer_off: TextureRect
var computer_on: TextureRect
var outlet: TextureRect
var plug: TextureRect
var cable_shadow: Line2D
var cable_core: Line2D
var target_rings: Array[Line2D] = []
var power_glow: PanelContainer

func _ready() -> void:
	configure("GAME_WAKE_PET_TITLE", "WAKE_PET_INSTRUCTIONS", "GAME_WAKE_PET_DESC", BG_PATH)
	super._ready()
	hide_common_minigame_header()
	hide_base_status()
	_hide_base_header_panel()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	plug_connected = false
	dragging = false
	score = 0
	_kill_return_tween()
	plug.position = PLUG_START
	plug.scale = Vector2.ONE
	plug.rotation = 0.0
	plug.modulate = Color.WHITE
	computer_off.visible = true
	computer_on.visible = false
	power_glow.modulate.a = 0.0
	_set_target_rings_visible(true)
	_update_cable()

func _process(delta: float) -> void:
	super._process(delta)
	if not plug:
		return

	pulse += delta * 4.6
	_update_target_rings()
	_update_cable()

func _input(event: InputEvent) -> void:
	if not dragging or plug_connected:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_move_plug_to(content_layer.get_local_mouse_position() - drag_offset)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_plug()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		_release_plug()
		get_viewport().set_input_as_handled()

func _build_stage() -> void:
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.color = Color("#05070a20")
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(dim)

	_build_target_rings()
	outlet = make_sprite(OUTLET_PATH, OUTLET_SIZE)
	outlet.position = OUTLET_POS
	outlet.z_index = 8
	outlet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(outlet)

	power_glow = PanelContainer.new()
	power_glow.position = Vector2(118, 276)
	power_glow.size = Vector2(520, 264)
	power_glow.z_index = 3
	power_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_glow.modulate.a = 0.0
	power_glow.add_theme_stylebox_override("panel", make_style(Color("#6afcff66"), Color("#6afcff00"), 0, 36))
	content_layer.add_child(power_glow)

	computer_off = make_sprite(COMPUTER_OFF_PATH, COMPUTER_SIZE)
	computer_off.position = COMPUTER_POS
	computer_off.z_index = 5
	computer_off.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(computer_off)

	computer_on = make_sprite(COMPUTER_ON_PATH, COMPUTER_SIZE)
	computer_on.position = COMPUTER_POS
	computer_on.z_index = 6
	computer_on.visible = false
	computer_on.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(computer_on)

	cable_shadow = _make_cable_line(22.0, Color("#05070acc"), 4)
	cable_core = _make_cable_line(13.0, Color("#343a43"), 5)

	plug = make_sprite(PLUG_PATH, PLUG_SIZE)
	plug.position = PLUG_START
	plug.z_index = 12
	plug.mouse_filter = Control.MOUSE_FILTER_STOP
	plug.gui_input.connect(_on_plug_gui_input)
	content_layer.add_child(plug)
	_update_cable()

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

func _build_target_rings() -> void:
	target_rings.clear()
	for index in range(3):
		var ring := Line2D.new()
		ring.closed = true
		ring.width = 6.0 - float(index)
		ring.default_color = Color("#fff06a")
		ring.position = SOCKET_TARGET
		ring.z_index = 7
		var radius := 44.0 + float(index) * 18.0
		var points := PackedVector2Array()
		for step in range(52):
			var angle := TAU * float(step) / 52.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		ring.points = points
		content_layer.add_child(ring)
		target_rings.append(ring)

func _make_cable_line(width: float, color: Color, z: int) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = z
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	content_layer.add_child(line)
	return line

func _on_plug_gui_input(event: InputEvent) -> void:
	if not running or plug_connected:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_start_drag(event.position)
		get_viewport().set_input_as_handled()

func _start_drag(local_point: Vector2) -> void:
	_kill_return_tween()
	dragging = true
	drag_offset = local_point
	plug.z_index = 18
	plug.scale = Vector2(1.06, 1.06)
	play_action_sound("move")

func _move_plug_to(top_left: Vector2) -> void:
	if not plug:
		return

	var max_pos := DRAG_MAX - PLUG_SIZE
	plug.position = Vector2(
		clampf(top_left.x, DRAG_MIN.x, max_pos.x),
		clampf(top_left.y, DRAG_MIN.y, max_pos.y)
	)

func _release_plug() -> void:
	if not dragging:
		return

	dragging = false
	plug.scale = Vector2.ONE
	plug.z_index = 12
	if _plug_tip().distance_to(SOCKET_TARGET) <= SNAP_RADIUS:
		_connect_plug()
	else:
		_return_plug()

func _return_plug() -> void:
	play_action_sound("bad")
	return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(plug, "position", PLUG_START, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return_tween.tween_property(plug, "rotation", -0.04, 0.08)
	return_tween.chain().tween_property(plug, "rotation", 0.0, 0.12)
	return_tween.tween_callback(func() -> void: return_tween = null)

func _connect_plug() -> void:
	if plug_connected or not running:
		return

	plug_connected = true
	dragging = false
	score = 1
	plug.position = SOCKET_TARGET - PLUG_TIP_LOCAL
	plug.scale = Vector2.ONE
	plug.rotation = 0.0
	plug.z_index = 12
	_update_cable()
	_set_target_rings_visible(false)
	_power_on()
	play_action_sound("collect")
	await get_tree().create_timer(0.68).timeout
	finish(true)

func _power_on() -> void:
	computer_off.visible = false
	computer_on.visible = true
	computer_on.modulate = Color(1.35, 1.35, 1.2, 1.0)
	power_glow.modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(computer_on, "modulate", Color.WHITE, 0.28)
	tween.tween_property(power_glow, "modulate:a", 0.42, 0.28)
	tween.chain().tween_property(power_glow, "modulate:a", 0.18, 0.34)

	_spawn_power_burst(SOCKET_TARGET, Color("#fff06a"))
	_spawn_power_burst(Vector2(356, 390), Color("#66f7ff"))

func _spawn_power_burst(origin: Vector2, color: Color) -> void:
	for index in range(14):
		var angle := TAU * float(index) / 14.0 + randf_range(-0.12, 0.12)
		var length := randf_range(34.0, 86.0)
		var ray := Line2D.new()
		ray.width = randf_range(3.0, 6.0)
		ray.default_color = color
		ray.z_index = 20
		ray.points = PackedVector2Array([
			origin + Vector2(cos(angle), sin(angle)) * 12.0,
			origin + Vector2(cos(angle), sin(angle)) * length
		])
		content_layer.add_child(ray)
		var tween := create_tween()
		tween.tween_property(ray, "modulate:a", 0.0, 0.34)
		tween.parallel().tween_property(ray, "scale", Vector2(1.35, 1.35), 0.34)
		tween.tween_callback(Callable(ray, "queue_free"))

func _update_cable() -> void:
	if not cable_shadow or not cable_core or not plug:
		return

	var end := _plug_cable_point()
	var points := PackedVector2Array([
		CABLE_START,
		CABLE_START.lerp(end, 0.32) + Vector2(-10, 88),
		CABLE_START.lerp(end, 0.68) + Vector2(8, 64),
		end
	])
	cable_shadow.points = points
	cable_core.points = points

func _update_target_rings() -> void:
	for index in range(target_rings.size()):
		var ring := target_rings[index]
		if not ring.visible:
			continue
		var offset := float(index) * 0.55
		var wave := (sin(pulse + offset) + 1.0) * 0.5
		ring.scale = Vector2.ONE * (0.88 + wave * 0.24)
		ring.modulate.a = 0.42 + wave * 0.36

func _set_target_rings_visible(visible: bool) -> void:
	for ring in target_rings:
		ring.visible = visible
		ring.modulate = Color.WHITE

func _kill_return_tween() -> void:
	if return_tween and return_tween.is_valid():
		return_tween.kill()
	return_tween = null

func _plug_tip() -> Vector2:
	return plug.position + PLUG_TIP_LOCAL * plug.scale.x

func _plug_cable_point() -> Vector2:
	return plug.position + PLUG_CABLE_LOCAL * plug.scale.x

func on_timeout() -> void:
	finish(false)
