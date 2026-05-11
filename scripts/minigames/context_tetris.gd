extends "res://scripts/minigames/base_minigame.gd"

const BG_PATH := "res://assets/art/satellite_signal_bg.png"
const DISH_PATH := "res://assets/art/satellite_dish.png"
const RECEIVER_OFF_PATH := "res://assets/art/satellite_receiver_off.png"
const RECEIVER_ON_PATH := "res://assets/art/satellite_receiver_on.png"

const DISH_SIZE := Vector2(315, 271)
const RECEIVER_SIZE := Vector2(286, 262)
const DISH_Y := 318.0
const RAIL_LEFT := 72.0
const RAIL_RIGHT := 456.0
const TARGET_DISH_X := 286.0
const ALIGN_TOLERANCE := 34.0
const LOCK_SECONDS := 0.55

var dish_x := TARGET_DISH_X - 150.0
var dragging := false
var lock_time := 0.0
var pulse := 0.0
var dish_sprite: TextureRect
var receiver_sprite: TextureRect
var lock_bar: ProgressBar
var target_waves: Array[Line2D] = []
var live_waves: Array[Line2D] = []
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
	dish_x = RAIL_LEFT + 52.0
	dragging = false
	lock_time = 0.0
	score = 0
	receiver_sprite.texture = load(RECEIVER_OFF_PATH)
	lock_bar.value = 0.0
	_set_dish_x(dish_x)

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	pulse += delta * 8.0
	var alignment := _alignment_strength()
	score = roundi(alignment * 100.0)
	lock_bar.value = alignment
	receiver_sprite.texture = load(RECEIVER_ON_PATH) if alignment >= 0.86 else load(RECEIVER_OFF_PATH)
	receiver_sprite.scale = Vector2.ONE * (1.0 + maxf(alignment - 0.8, 0.0) * sin(pulse * 2.0) * 0.025)

	if alignment >= 0.94:
		lock_time += delta
		for line in spark_lines:
			line.visible = true
			line.modulate.a = 0.55 + sin(pulse + float(spark_lines.find(line))) * 0.35
	else:
		lock_time = 0.0
		for line in spark_lines:
			line.visible = false

	_update_waves(alignment)
	if lock_time >= LOCK_SECONDS:
		await _finish_signal_lock()

func _unhandled_input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _mouse_hits_dish(event.position) or _mouse_hits_rail(event.position):
				dragging = true
				play_action_sound("move")
				_set_dish_x(event.position.x - DISH_SIZE.x * 0.54)
				get_viewport().set_input_as_handled()
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		_set_dish_x(event.position.x - DISH_SIZE.x * 0.54)
		get_viewport().set_input_as_handled()

func _build_stage() -> void:
	_build_target_waves()

	dish_sprite = make_sprite(DISH_PATH, DISH_SIZE)
	dish_sprite.position = Vector2(dish_x, DISH_Y)
	dish_sprite.z_index = 12
	content_layer.add_child(dish_sprite)

	receiver_sprite = make_sprite(RECEIVER_OFF_PATH, RECEIVER_SIZE)
	receiver_sprite.position = Vector2(860, 282)
	receiver_sprite.pivot_offset = RECEIVER_SIZE * 0.5
	receiver_sprite.z_index = 11
	content_layer.add_child(receiver_sprite)

	_build_live_waves()
	_build_lock_bar()
	_build_sparks()
	_set_dish_x(dish_x)

func _build_target_waves() -> void:
	target_waves.clear()
	var origin := _signal_origin_for(TARGET_DISH_X)
	for index in range(3):
		var line := _make_wave_line(origin, index, Color("#ffffff82"), 7.0)
		line.z_index = 5
		content_layer.add_child(line)
		target_waves.append(line)

func _build_live_waves() -> void:
	live_waves.clear()
	for index in range(3):
		var line := _make_wave_line(_signal_origin_for(dish_x), index, Color("#ff5b5b"), 9.0)
		line.z_index = 14
		content_layer.add_child(line)
		live_waves.append(line)

func _build_lock_bar() -> void:
	lock_bar = ProgressBar.new()
	lock_bar.position = Vector2(826, 596)
	lock_bar.size = Vector2(330, 22)
	lock_bar.min_value = 0.0
	lock_bar.max_value = 1.0
	lock_bar.show_percentage = false
	lock_bar.modulate = Color("#67e887")
	content_layer.add_child(lock_bar)

func _build_sparks() -> void:
	spark_lines.clear()
	var center := Vector2(1003, 392)
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var line := Line2D.new()
		line.width = 7.0
		line.default_color = Color("#ffef5f")
		line.points = PackedVector2Array([
			center + Vector2(cos(angle), sin(angle)) * 142.0,
			center + Vector2(cos(angle), sin(angle)) * 180.0
		])
		line.visible = false
		line.z_index = 16
		content_layer.add_child(line)
		spark_lines.append(line)

func _set_dish_x(new_x: float) -> void:
	dish_x = clampf(new_x, RAIL_LEFT, RAIL_RIGHT)
	if dish_sprite:
		dish_sprite.position = Vector2(dish_x, DISH_Y)
	_update_waves(_alignment_strength())

func _alignment_strength() -> float:
	return clampf(1.0 - absf(dish_x - TARGET_DISH_X) / ALIGN_TOLERANCE, 0.0, 1.0)

func _signal_origin_for(x: float) -> Vector2:
	return Vector2(x + 232.0, DISH_Y + 116.0)

func _make_wave_line(origin: Vector2, index: int, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = _wave_points(origin, index)
	return line

func _update_waves(alignment: float) -> void:
	var origin := _signal_origin_for(dish_x)
	var color := Color("#ff5b5b").lerp(Color("#63f46f"), alignment)
	for index in range(live_waves.size()):
		live_waves[index].points = _wave_points(origin, index)
		live_waves[index].default_color = color
		live_waves[index].width = 7.0 + alignment * 4.0
		live_waves[index].modulate.a = 0.65 + sin(pulse + float(index)) * 0.16

func _wave_points(origin: Vector2, index: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius_x := 135.0 + float(index) * 126.0
	var radius_y := 72.0 + float(index) * 58.0
	for step in range(34):
		var angle := lerpf(-0.62, 0.62, float(step) / 33.0)
		points.append(origin + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points

func _mouse_hits_dish(point: Vector2) -> bool:
	return Rect2(dish_sprite.position, DISH_SIZE).grow(22.0).has_point(point)

func _mouse_hits_rail(point: Vector2) -> bool:
	return Rect2(Vector2(70, 524), Vector2(694, 88)).has_point(point)

func _finish_signal_lock() -> void:
	if not running:
		return
	play_action_sound("collect")
	for line in live_waves:
		line.default_color = Color("#63f46f")
	await finish_with_result(true, "CONTEXT_SUCCESS", 0.45)

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
