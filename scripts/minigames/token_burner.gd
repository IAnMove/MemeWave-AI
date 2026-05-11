extends "res://scripts/minigames/base_minigame.gd"

const BG_PATH := "res://assets/art/ollama_gpu_bg.png"
const LAPTOP_HOT_PATH := "res://assets/art/ollama_laptop_hot.png"
const LAPTOP_COOL_PATH := "res://assets/art/ollama_laptop_cool.png"
const FAN_PATH := "res://assets/art/ollama_fan.png"

const LAPTOP_POS := Vector2(102, 230)
const LAPTOP_SIZE := Vector2(620, 430)
const FAN_START := Vector2(920, 342)
const FAN_SIZE := Vector2(210, 226)
const GPU_ZONE := Rect2(Vector2(190, 270), Vector2(520, 318))
const TEMPERATURE_MAX := 100.0
const COOL_RATE := 50.0
const HEAT_RATE := 9.0

var temperature := TEMPERATURE_MAX
var dragging := false
var drag_offset := Vector2.ZERO
var cooling := false
var fan_spin := 0.0
var laptop_hot: TextureRect
var laptop_cool: TextureRect
var fan: TextureRect
var temp_bar: ProgressBar
var speech_label: Label
var wind_lines: Array[Line2D] = []
var burst_layer: Control

func _ready() -> void:
	configure("GAME_TOKENS_TITLE", "TOKENS_INSTRUCTIONS", "GAME_TOKENS_DESC", BG_PATH)
	super._ready()
	hide_common_minigame_header()
	hide_base_status()
	_hide_base_header_panel()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	temperature = TEMPERATURE_MAX
	dragging = false
	cooling = false
	fan_spin = 0.0
	score = 0
	fan.position = FAN_START
	fan.scale = Vector2.ONE
	fan.rotation = 0.0
	laptop_hot.visible = true
	laptop_cool.visible = false
	_set_speech("TOKENS_CPU_IDLE", Color("#ff5b5b"))
	_update_temperature_ui()
	_update_wind(false)

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	cooling = _fan_over_gpu()
	if cooling:
		temperature = maxf(0.0, temperature - COOL_RATE * delta)
		score = roundi(TEMPERATURE_MAX - temperature)
		fan_spin += delta * 8.5
		fan.rotation = sin(fan_spin) * 0.08
		_set_speech("TOKENS_CPU_FED", Color("#11883a"))
	else:
		temperature = minf(TEMPERATURE_MAX, temperature + HEAT_RATE * delta)
		fan.rotation = sin(Time.get_ticks_msec() * 0.012) * 0.025
		_set_speech("TOKENS_CPU_IDLE", Color("#ff5b5b"))

	_update_temperature_ui()
	_update_wind(cooling)

	if temperature <= 0.0:
		_finish_cooled()

func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_move_fan_to(content_layer.get_local_mouse_position() - drag_offset)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_fan()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		_release_fan()
		get_viewport().set_input_as_handled()

func _build_stage() -> void:
	burst_layer = Control.new()
	burst_layer.position = Vector2.ZERO
	burst_layer.size = Vector2(1280, 720)
	burst_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(burst_layer)

	laptop_hot = make_sprite(LAPTOP_HOT_PATH, LAPTOP_SIZE)
	laptop_hot.position = LAPTOP_POS
	laptop_hot.z_index = 5
	laptop_hot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(laptop_hot)

	laptop_cool = make_sprite(LAPTOP_COOL_PATH, LAPTOP_SIZE)
	laptop_cool.position = LAPTOP_POS
	laptop_cool.z_index = 6
	laptop_cool.visible = false
	laptop_cool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(laptop_cool)

	_build_temperature_panel()
	_build_wind_lines()

	fan = make_sprite(FAN_PATH, FAN_SIZE)
	fan.position = FAN_START
	fan.z_index = 14
	fan.mouse_filter = Control.MOUSE_FILTER_STOP
	fan.gui_input.connect(_on_fan_input)
	content_layer.add_child(fan)

func _build_temperature_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(862, 182)
	panel.size = Vector2(332, 104)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fffdf8"), Color("#151515"), 5, 10))
	content_layer.add_child(panel)

	temp_bar = ProgressBar.new()
	temp_bar.position = Vector2(898, 214)
	temp_bar.size = Vector2(260, 30)
	temp_bar.max_value = TEMPERATURE_MAX
	temp_bar.show_percentage = false
	content_layer.add_child(temp_bar)

	speech_label = make_label("", 25, Color("#ff5b5b"), HORIZONTAL_ALIGNMENT_CENTER)
	speech_label.position = Vector2(844, 262)
	speech_label.size = Vector2(370, 70)
	speech_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	speech_label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(speech_label)

func _build_wind_lines() -> void:
	wind_lines.clear()
	for index in range(8):
		var line := Line2D.new()
		line.width = 7.0
		line.default_color = Color("#66dbff")
		line.z_index = 12
		line.visible = false
		content_layer.add_child(line)
		wind_lines.append(line)

func _on_fan_input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true
		drag_offset = event.position
		fan.scale = Vector2(1.08, 1.08)
		fan.z_index = 25
		play_action_sound("move")
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		dragging = true
		drag_offset = event.position
		fan.scale = Vector2(1.08, 1.08)
		fan.z_index = 25
		play_action_sound("move")
		get_viewport().set_input_as_handled()

func _move_fan_to(pos: Vector2) -> void:
	fan.position = Vector2(
		clampf(pos.x, 46.0, 1136.0 - FAN_SIZE.x),
		clampf(pos.y, 168.0, 642.0 - FAN_SIZE.y)
	)

func _release_fan() -> void:
	dragging = false
	fan.scale = Vector2.ONE
	fan.z_index = 14

func _fan_over_gpu() -> bool:
	if not fan:
		return false
	var fan_rect := Rect2(fan.position + Vector2(18, 16), FAN_SIZE - Vector2(34, 36))
	return fan_rect.intersects(GPU_ZONE)

func _update_temperature_ui() -> void:
	if temp_bar:
		temp_bar.value = temperature
		if temperature > 65.0:
			temp_bar.modulate = Color("#ff5b5b")
		elif temperature > 28.0:
			temp_bar.modulate = Color("#ffdf2e")
		else:
			temp_bar.modulate = Color("#66f28b")
	laptop_hot.visible = temperature > 24.0
	laptop_cool.visible = temperature <= 24.0

func _update_wind(active: bool) -> void:
	for index in range(wind_lines.size()):
		var line := wind_lines[index]
		line.visible = active
		if not active:
			continue
		var start := fan.position + Vector2(32, 48 + index * 17)
		var end := Vector2(520, 334 + sin(fan_spin + index) * 34.0)
		line.points = PackedVector2Array([start, start.lerp(end, 0.48) + Vector2(0, sin(fan_spin + index) * 12.0), end])
		line.modulate.a = 0.45 + sin(fan_spin + index) * 0.22

func _set_speech(key: String, color: Color) -> void:
	if speech_label:
		speech_label.text = tr(key)
		speech_label.add_theme_color_override("font_color", color)

func _finish_cooled() -> void:
	if not running:
		return
	temperature = 0.0
	_update_temperature_ui()
	_update_wind(true)
	_set_speech("TOKENS_SUCCESS", Color("#11883a"))
	play_action_sound("collect")
	_spawn_cool_burst()
	await finish_with_result(true, "TOKENS_SUCCESS", 0.45)

func _spawn_cool_burst() -> void:
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		var ray := Line2D.new()
		ray.width = randf_range(3.0, 6.0)
		ray.default_color = Color("#66dbff")
		ray.points = PackedVector2Array([
			Vector2(446, 334),
			Vector2(446, 334) + Vector2(cos(angle), sin(angle)) * randf_range(44.0, 94.0)
		])
		ray.z_index = 30
		burst_layer.add_child(ray)
		var tween := create_tween()
		tween.tween_property(ray, "modulate:a", 0.0, 0.36)
		tween.parallel().tween_property(ray, "scale", Vector2(1.4, 1.4), 0.36)
		tween.tween_callback(Callable(ray, "queue_free"))

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
	await finish_with_result(temperature <= 24.0, "TOKENS_TIMEOUT_SUCCESS" if temperature <= 24.0 else "TOKENS_FAIL", 0.45)
