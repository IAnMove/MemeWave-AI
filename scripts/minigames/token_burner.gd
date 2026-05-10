extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_TOKENS := 8
const ITEM_SIZE := Vector2(94, 94)
const ITEM_MIN_SPEED := 116.0
const ITEM_MAX_SPEED := 172.0
const DROP_LANE_LEFT_X := 348.0
const DROP_LANE_RIGHT_X := 666.0
const SPAWN_MIN_X := DROP_LANE_LEFT_X + 8.0
const SPAWN_MAX_X := DROP_LANE_RIGHT_X - ITEM_SIZE.x - 8.0
const DRAG_MIN_X := DROP_LANE_LEFT_X
const DRAG_MAX_X := 1082.0
const CPU_WALL_X := 740.0
const MOUTH_RECT := Rect2(Vector2(832, 376), Vector2(262, 82))
const TOKEN_FEED_SOUND_PATH := "res://assets/sounds/token_feed.wav"

var items: Array[Dictionary] = []
var dragged: Control
var spawn_timer := 0.0
var fed_tokens := 0
var misses := 0
var mouth: PanelContainer
var mouth_sensor: Control
var mouth_lip: PanelContainer
var mouth_teeth: Array[ColorRect] = []
var tongue: ColorRect
var mouth_highlight: ColorRect
var cpu_body: Control
var feed_bar: ProgressBar
var pupil_left: ColorRect
var pupil_right: ColorRect
var cheek_left: ColorRect
var cheek_right: ColorRect
var happy_eye_left: Line2D
var happy_eye_right: Line2D
var happy_sound: AudioStreamPlayer
var happy_feedback_id := 0

func _ready() -> void:
	configure(
		"GAME_TOKENS_TITLE",
		"TOKENS_INSTRUCTIONS",
		"GAME_TOKENS_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	items.clear()
	dragged = null
	spawn_timer = 0.0
	fed_tokens = 0
	misses = 0
	score = 0
	_clear_dynamic_items()
	if feed_bar:
		feed_bar.value = 0
	set_status(tr("TOKENS_STATUS") % [0, TARGET_TOKENS, 0])

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.52, 0.88)
		_spawn_item()

	for item in items.duplicate():
		var node := item["node"] as Control
		if not is_instance_valid(node):
			items.erase(item)
			continue

		node.position.y += float(item["speed"]) * delta
		node.rotation += float(item["spin"]) * delta
		_apply_cpu_wall(node)

		if _try_feed_item(item):
			continue

		if node.position.y > 735.0:
			if item["kind"] == "token":
				misses += 1
			_remove_item(item)
			_update_status()

func _build_stage() -> void:
	_build_paper_background()
	_build_header_illustration()
	_build_sam_panel()
	_build_drop_lane()
	_build_cpu()
	_build_happy_sound()

func _build_paper_background() -> void:
	var paper := ColorRect.new()
	paper.name = "TokenWhiteBackground"
	paper.position = Vector2(0, 196)
	paper.size = Vector2(1280, 524)
	paper.color = Color("#ffffff")
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(paper)

func _build_header_illustration() -> void:
	var frame: Control = SketchPanel.new()
	frame.position = Vector2(1040, 102)
	frame.size = Vector2(156, 82)
	frame.z_index = 42
	frame.call("configure", Color("#ffffff"), Color("#1d1d1d"), 3.0, 1.3, false)
	add_child(frame)

	var illustration := make_sprite("res://assets/art/tokens_burner_bg.png", Vector2(142, 68))
	illustration.position = Vector2(1047, 109)
	illustration.z_index = 43
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(illustration)

func _build_sam_panel() -> void:
	var panel: Control = SketchPanel.new()
	panel.position = Vector2(70, 246)
	panel.size = Vector2(250, 296)
	panel.call("configure", Color("#ffffff"), Color("#1d1d1d"), 4.0, 1.7, false)
	content_layer.add_child(panel)

	var sam := make_sprite("res://assets/sprites/sam_face.png", Vector2(190, 176))
	sam.position = Vector2(100, 266)
	content_layer.add_child(sam)

	var label := make_label("SAM", 31, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(102, 464)
	label.size = Vector2(184, 42)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(label)

func _build_drop_lane() -> void:
	var lane_left := Line2D.new()
	lane_left.width = 4
	lane_left.default_color = Color("#9bd7ff66")
	lane_left.points = PackedVector2Array([
		Vector2(DROP_LANE_LEFT_X, 210),
		Vector2(DROP_LANE_LEFT_X + 5, 320),
		Vector2(DROP_LANE_LEFT_X - 4, 460),
		Vector2(DROP_LANE_LEFT_X, 618)
	])
	content_layer.add_child(lane_left)

	var lane_right := Line2D.new()
	lane_right.width = 4
	lane_right.default_color = Color("#9bd7ff66")
	lane_right.points = PackedVector2Array([
		Vector2(DROP_LANE_RIGHT_X, 210),
		Vector2(DROP_LANE_RIGHT_X - 4, 335),
		Vector2(DROP_LANE_RIGHT_X + 5, 472),
		Vector2(DROP_LANE_RIGHT_X, 618)
	])
	content_layer.add_child(lane_right)

	for index in range(3):
		var arrow: Control = SketchIcon.new()
		arrow.position = Vector2(438 + index * 62, 296 + index * 38)
		arrow.size = Vector2(34, 34)
		arrow.rotation = PI * 0.5
		arrow.call("configure", "plane", Color("#66c6ff"), Color("#fff06a"))
		content_layer.add_child(arrow)

func _build_cpu() -> void:
	mouth_sensor = Control.new()
	mouth_sensor.name = "TokenMouthHitbox"
	mouth_sensor.position = MOUTH_RECT.position
	mouth_sensor.size = MOUTH_RECT.size
	mouth_sensor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(mouth_sensor)

	mouth_lip = PanelContainer.new()
	mouth_lip.position = MOUTH_RECT.position + Vector2(-14, -14)
	mouth_lip.size = MOUTH_RECT.size + Vector2(28, 28)
	mouth_lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouth_lip.add_theme_stylebox_override("panel", make_style(Color("#ff5b5b"), Color("#1d1d1d"), 5, 12))
	content_layer.add_child(mouth_lip)

	mouth = PanelContainer.new()
	mouth.position = MOUTH_RECT.position
	mouth.size = MOUTH_RECT.size
	mouth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouth.add_theme_stylebox_override("panel", make_style(Color("#111116"), Color("#1d1d1d"), 5, 10))
	content_layer.add_child(mouth)

	mouth_teeth.clear()
	for index in range(8):
		var tooth := ColorRect.new()
		tooth.position = MOUTH_RECT.position + Vector2(17 + index * 30, 4)
		tooth.size = Vector2(18, 25)
		tooth.color = Color("#fffdf8")
		tooth.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_layer.add_child(tooth)
		mouth_teeth.append(tooth)

	tongue = ColorRect.new()
	tongue.position = MOUTH_RECT.position + Vector2(64, 58)
	tongue.size = Vector2(136, 14)
	tongue.color = Color("#ff9fd6")
	tongue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(tongue)

	mouth_highlight = ColorRect.new()
	mouth_highlight.position = MOUTH_RECT.position + Vector2(38, 42)
	mouth_highlight.size = Vector2(186, 5)
	mouth_highlight.color = Color("#ffffff3a")
	mouth_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(mouth_highlight)

	var top_shadow := ColorRect.new()
	top_shadow.position = Vector2(758, 456)
	top_shadow.size = Vector2(418, 15)
	top_shadow.color = Color("#b6c2c5")
	top_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(top_shadow)

	var case_shadow := PanelContainer.new()
	case_shadow.position = Vector2(CPU_WALL_X + 18, 468)
	case_shadow.size = Vector2(442, 132)
	case_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	case_shadow.add_theme_stylebox_override("panel", make_style(Color("#a7d5e5"), Color("#1d1d1d"), 4, 6))
	content_layer.add_child(case_shadow)

	cpu_body = SketchPanel.new()
	cpu_body.position = Vector2(CPU_WALL_X, 456)
	cpu_body.size = Vector2(450, 138)
	cpu_body.call("configure", Color("#dff2ff"), Color("#1d1d1d"), 5.0, 1.7, false)
	content_layer.add_child(cpu_body)

	var body_top := ColorRect.new()
	body_top.position = Vector2(770, 466)
	body_top.size = Vector2(390, 8)
	body_top.color = Color("#ffffffaa")
	body_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(body_top)

	var screen := PanelContainer.new()
	screen.position = Vector2(782, 482)
	screen.size = Vector2(366, 86)
	screen.add_theme_stylebox_override("panel", make_style(Color("#bff0ff"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(screen)

	var shine := ColorRect.new()
	shine.position = Vector2(798, 494)
	shine.size = Vector2(334, 5)
	shine.color = Color("#ffffff88")
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(shine)

	var cpu_name := make_label(tr("TOKENS_CPU_NAME"), 32, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	cpu_name.position = Vector2(822, 493)
	cpu_name.size = Vector2(286, 38)
	cpu_name.add_theme_color_override("font_outline_color", Color("#ffffff"))
	cpu_name.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(cpu_name)

	var eye_left := PanelContainer.new()
	eye_left.position = Vector2(860, 530)
	eye_left.size = Vector2(42, 38)
	eye_left.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 10))
	content_layer.add_child(eye_left)

	pupil_left = ColorRect.new()
	pupil_left.position = Vector2(883, 534)
	pupil_left.size = Vector2(13, 16)
	pupil_left.color = Color("#1d1d1d")
	content_layer.add_child(pupil_left)

	happy_eye_left = Line2D.new()
	happy_eye_left.width = 6
	happy_eye_left.default_color = Color("#1d1d1d")
	happy_eye_left.points = PackedVector2Array([
		Vector2(865, 548),
		Vector2(882, 537),
		Vector2(900, 548)
	])
	happy_eye_left.visible = false
	content_layer.add_child(happy_eye_left)

	var eye_right := PanelContainer.new()
	eye_right.position = Vector2(1028, 530)
	eye_right.size = Vector2(42, 38)
	eye_right.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 10))
	content_layer.add_child(eye_right)

	pupil_right = ColorRect.new()
	pupil_right.position = Vector2(1051, 534)
	pupil_right.size = Vector2(13, 16)
	pupil_right.color = Color("#1d1d1d")
	content_layer.add_child(pupil_right)

	happy_eye_right = Line2D.new()
	happy_eye_right.width = 6
	happy_eye_right.default_color = Color("#1d1d1d")
	happy_eye_right.points = PackedVector2Array([
		Vector2(1033, 548),
		Vector2(1050, 537),
		Vector2(1068, 548)
	])
	happy_eye_right.visible = false
	content_layer.add_child(happy_eye_right)

	cheek_left = ColorRect.new()
	cheek_left.position = Vector2(820, 558)
	cheek_left.size = Vector2(38, 12)
	cheek_left.color = Color("#ff9fd680")
	content_layer.add_child(cheek_left)

	cheek_right = ColorRect.new()
	cheek_right.position = Vector2(1074, 558)
	cheek_right.size = Vector2(38, 12)
	cheek_right.color = Color("#ff9fd680")
	content_layer.add_child(cheek_right)

	for index in range(7):
		var vent := ColorRect.new()
		vent.position = Vector2(788 + index * 18, 575)
		vent.size = Vector2(10, 6)
		vent.color = Color("#1d1d1d88")
		vent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_layer.add_child(vent)

	var power_light := PanelContainer.new()
	power_light.position = Vector2(1124, 573)
	power_light.size = Vector2(16, 16)
	power_light.add_theme_stylebox_override("panel", make_style(Color("#70ff7a"), Color("#1d1d1d"), 3, 8))
	content_layer.add_child(power_light)

	var stand := PanelContainer.new()
	stand.position = Vector2(926, 594)
	stand.size = Vector2(78, 32)
	stand.add_theme_stylebox_override("panel", make_style(Color("#d5d5d5"), Color("#1d1d1d"), 4, 4))
	content_layer.add_child(stand)

	var base := PanelContainer.new()
	base.position = Vector2(846, 622)
	base.size = Vector2(238, 26)
	base.add_theme_stylebox_override("panel", make_style(Color("#d5d5d5"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(base)

	feed_bar = ProgressBar.new()
	feed_bar.position = Vector2(826, 594)
	feed_bar.size = Vector2(278, 20)
	feed_bar.min_value = 0
	feed_bar.max_value = TARGET_TOKENS
	feed_bar.value = 0
	feed_bar.show_percentage = false
	content_layer.add_child(feed_bar)

func _build_happy_sound() -> void:
	happy_sound = AudioStreamPlayer.new()
	var token_feed_stream := _load_sound_stream(TOKEN_FEED_SOUND_PATH)
	happy_sound.stream = token_feed_stream if token_feed_stream else _make_chime_stream()
	happy_sound.volume_db = -8.0
	add_child(happy_sound)

func _make_chime_stream() -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 0.24
	var sample_count := int(float(mix_rate) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var t: float = float(index) / float(mix_rate)
		var freq: float = 659.25 if t < 0.11 else 880.0
		var attack: float = clampf(t / 0.025, 0.0, 1.0)
		var release: float = clampf(1.0 - t / duration, 0.0, 1.0)
		var envelope: float = attack * release * release
		var wave: float = sin(TAU * freq * t) + sin(TAU * freq * 2.0 * t) * 0.18
		var sample := int(clamp(wave * envelope * 0.34, -1.0, 1.0) * 32767.0)
		data.encode_s16(index * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream

func _spawn_item() -> void:
	var is_rate_limit := randf() < 0.24
	var path := "res://assets/sprites/rate_limit.png" if is_rate_limit else "res://assets/sprites/token.png"
	var item_sprite := make_sprite(path, ITEM_SIZE)
	item_sprite.name = "DynamicToken"
	item_sprite.position = Vector2(randf_range(SPAWN_MIN_X, SPAWN_MAX_X), 204)
	item_sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	item_sprite.gui_input.connect(_on_item_gui_input.bind(item_sprite))
	content_layer.add_child(item_sprite)
	items.append({
		"node": item_sprite,
		"kind": "rate" if is_rate_limit else "token",
		"speed": randf_range(ITEM_MIN_SPEED, ITEM_MAX_SPEED),
		"spin": randf_range(-0.45, 0.45)
	})

func _on_item_gui_input(event: InputEvent, node: Control) -> void:
	if not running:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragged = node
			node.z_index = 50
			node.scale = Vector2(1.08, 1.08)
		elif dragged == node:
			_stop_dragging(node)
	elif event is InputEventMouseMotion and dragged == node:
		node.position.x = _clamp_drag_x(node, node.position.x + event.relative.x)

func _stop_dragging(node: Control) -> void:
	node.z_index = 0
	node.scale = Vector2.ONE
	dragged = null

func _clamp_drag_x(node: Control, desired_x: float) -> float:
	var max_x := DRAG_MAX_X
	if _is_below_mouth(node):
		max_x = CPU_WALL_X - node.size.x * 0.72
	return clamp(desired_x, DRAG_MIN_X, max_x)

func _apply_cpu_wall(node: Control) -> void:
	if not _is_below_mouth(node):
		return
	var wall_limit := CPU_WALL_X - node.size.x * 0.72
	if node.position.x > wall_limit:
		node.position.x = wall_limit

func _is_below_mouth(node: Control) -> bool:
	return node.position.y + node.size.y * 0.5 > MOUTH_RECT.position.y + MOUTH_RECT.size.y

func _try_feed_item(item: Dictionary) -> bool:
	var node := item["node"] as Control
	if not mouth_sensor or not mouth_sensor.get_global_rect().intersects(node.get_global_rect()):
		return false

	if item["kind"] == "token":
		fed_tokens += 1
		score = fed_tokens
		if feed_bar:
			feed_bar.value = fed_tokens
		_show_happy_feedback()
		_play_happy_sound()
		_spawn_feedback(node.position, tr("TOKENS_TOKEN_POP"), Color("#11883a"))
		_remove_item(item)
		_update_status()
		if fed_tokens >= TARGET_TOKENS:
			_finish_success()
	else:
		misses += 2
		_spawn_feedback(node.position, tr("TOKENS_RATE_POP"), Color("#d91e18"))
		_remove_item(item)
		_update_status()
	return true

func _show_happy_feedback() -> void:
	happy_feedback_id += 1
	var feedback_id := happy_feedback_id
	if mouth_lip:
		mouth_lip.add_theme_stylebox_override("panel", make_style(Color("#ff9fd6"), Color("#1d1d1d"), 5, 12))
	if mouth:
		mouth.add_theme_stylebox_override("panel", make_style(Color("#17171d"), Color("#1d1d1d"), 5, 10))
		var mouth_tween := create_tween()
		mouth_tween.set_parallel(true)
		mouth_tween.tween_property(mouth_lip, "position", MOUTH_RECT.position + Vector2(-14, 16), 0.08)
		mouth_tween.tween_property(mouth_lip, "size", Vector2(MOUTH_RECT.size.x + 28, 48), 0.08)
		mouth_tween.tween_property(mouth, "position", MOUTH_RECT.position + Vector2(0, 31), 0.08)
		mouth_tween.tween_property(mouth, "size", Vector2(MOUTH_RECT.size.x, 20), 0.08)
	for tooth in mouth_teeth:
		if tooth:
			tooth.visible = false
	if tongue:
		tongue.visible = false
	if mouth_highlight:
		mouth_highlight.visible = false
	if pupil_left:
		pupil_left.visible = false
	if pupil_right:
		pupil_right.visible = false
	if happy_eye_left:
		happy_eye_left.visible = true
	if happy_eye_right:
		happy_eye_right.visible = true
	if cheek_left:
		cheek_left.color = Color("#ff69b4cc")
	if cheek_right:
		cheek_right.color = Color("#ff69b4cc")

	var tween := create_tween()
	if cpu_body:
		tween.tween_property(cpu_body, "scale", Vector2(1.035, 0.985), 0.08)
		tween.tween_property(cpu_body, "scale", Vector2.ONE, 0.12)

	get_tree().create_timer(0.36).timeout.connect(func() -> void:
		if feedback_id == happy_feedback_id:
			_reset_happy_feedback()
	)

func _reset_happy_feedback() -> void:
	if mouth_lip:
		mouth_lip.add_theme_stylebox_override("panel", make_style(Color("#ff5b5b"), Color("#1d1d1d"), 5, 12))
	if mouth:
		mouth.add_theme_stylebox_override("panel", make_style(Color("#111116"), Color("#1d1d1d"), 5, 10))
		var mouth_tween := create_tween()
		mouth_tween.set_parallel(true)
		mouth_tween.tween_property(mouth_lip, "position", MOUTH_RECT.position + Vector2(-14, -14), 0.12)
		mouth_tween.tween_property(mouth_lip, "size", MOUTH_RECT.size + Vector2(28, 28), 0.12)
		mouth_tween.tween_property(mouth, "position", MOUTH_RECT.position, 0.12)
		mouth_tween.tween_property(mouth, "size", MOUTH_RECT.size, 0.12)
	for tooth in mouth_teeth:
		if tooth:
			tooth.visible = true
	if tongue:
		tongue.visible = true
	if mouth_highlight:
		mouth_highlight.visible = true
	if pupil_left:
		pupil_left.visible = true
		pupil_left.position = Vector2(883, 534)
	if pupil_right:
		pupil_right.visible = true
		pupil_right.position = Vector2(1051, 534)
	if happy_eye_left:
		happy_eye_left.visible = false
	if happy_eye_right:
		happy_eye_right.visible = false
	if cheek_left:
		cheek_left.color = Color("#ff9fd680")
	if cheek_right:
		cheek_right.color = Color("#ff9fd680")

func _play_happy_sound() -> void:
	if happy_sound:
		happy_sound.stop()
		happy_sound.play()

func _finish_success() -> void:
	await finish_with_result(true, "TOKENS_SUCCESS", 0.45)

func _spawn_feedback(position: Vector2, text: String, color: Color) -> void:
	var pop := make_label(text, 28, color, HORIZONTAL_ALIGNMENT_CENTER)
	pop.position = position + Vector2(-10, -30)
	pop.size = Vector2(160, 42)
	pop.add_theme_color_override("font_outline_color", Color("#ffffff"))
	pop.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(pop)

	var tween := create_tween()
	tween.tween_property(pop, "position:y", pop.position.y - 44, 0.34)
	tween.parallel().tween_property(pop, "modulate:a", 0.0, 0.34)
	tween.tween_callback(Callable(pop, "queue_free"))

func _update_status() -> void:
	set_status(tr("TOKENS_STATUS") % [fed_tokens, TARGET_TOKENS, misses])

func _find_item(node: Control) -> Dictionary:
	for item in items:
		if item["node"] == node:
			return item
	return {}

func _remove_item(item: Dictionary) -> void:
	items.erase(item)
	var node := item["node"] as Control
	if is_instance_valid(node):
		if node == dragged:
			dragged = null
		node.queue_free()

func _clear_dynamic_items() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicToken":
			child.queue_free()

func on_timeout() -> void:
	var success := fed_tokens >= TARGET_TOKENS
	await finish_with_result(success, "TOKENS_TIMEOUT_SUCCESS" if success else "TOKENS_FAIL", 0.45)
