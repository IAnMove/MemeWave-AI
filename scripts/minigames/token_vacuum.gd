extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const BG_PATH := "res://assets/art/token_vacuum_bg.png"
const USER_ICON_PATH := "res://assets/sprites/downgrade_user_normal.png"
const ANGRY_USER_ICON_PATH := "res://assets/sprites/downgrade_user_angry.png"
const MODEL_ICON_PATH := "res://assets/sprites/downgrade_model_icon.png"
const SPEAKER_ICON_PATH := "res://assets/sprites/downgrade_speaker.png"
const DANGER_START := 75.0
const LIMIT := 100.0
const SAFE_USAGE := 10.0
const START_USAGE := 22.0
const GROWTH_RATE := 18.5
const USER_INTERVAL := 0.22
const MAX_USERS := 36
const USER_COLUMNS := 12

var usage := START_USAGE
var user_count := 0
var spawn_timer := 0.0
var downgraded := false
var pulse := 0.0

var user_layer: Control
var users: Array[TextureRect] = []
var angry_marks: Array[Label] = []
var crowd_panel: Control
var company_panel: Control
var usage_bar: ProgressBar
var limit_marker: ColorRect
var usage_label: Label
var model_label: Label
var cpu_icon: Control
var downgrade_button: Button
var crowd_state_label: Label

var user_texture: Texture2D
var angry_user_texture: Texture2D

class CpuBurnIcon:
	extends Control

	var usage := 0.0
	var downgraded := false

	func set_state(new_usage: float, is_downgraded: bool) -> void:
		usage = new_usage
		downgraded = is_downgraded
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var hot := usage >= 70.0 and not downgraded
		var body := Rect2(Vector2(10, 20), Vector2(size.x - 20, size.y - 28))
		var body_fill := Color("#26313d") if hot else Color("#dff8da")
		var edge := Color("#111111")
		draw_rect(body, body_fill, true)
		_draw_wobbly_rect(body, edge, 5.0)

		var screen := Rect2(body.position + Vector2(16, 13), Vector2(body.size.x - 32, 16))
		draw_rect(screen, Color("#0c1014"), true)
		_draw_wobbly_rect(screen, edge, 2.0)
		var graph_color := Color("#ff5b5b") if hot else Color("#35d96b")
		var graph := PackedVector2Array([
			screen.position + Vector2(6, 11),
			screen.position + Vector2(22, 5),
			screen.position + Vector2(37, 12),
			screen.position + Vector2(53, 4),
			screen.position + Vector2(70, 10)
		])
		draw_polyline(graph, graph_color, 3.0, true)

		for index in range(4):
			var chip := Rect2(body.position + Vector2(17 + index * 27, body.size.y - 16), Vector2(18, 12))
			draw_rect(chip, Color("#ff5b5b") if hot else Color("#56d364"), true)
			_draw_wobbly_rect(chip, edge, 1.8)

		for index in range(3):
			var x := body.position.x + body.size.x - 24 + index * 6
			draw_line(Vector2(x, body.position.y + 10), Vector2(x, body.position.y + body.size.y - 8), Color("#ffffff30"), 2.0, true)

		if hot:
			for index in range(3):
				var x := body.position.x + 42 + index * 34
				var flame := PackedVector2Array([
					Vector2(x, body.position.y - 2),
					Vector2(x + 11, body.position.y - 28),
					Vector2(x + 26, body.position.y - 2)
				])
				draw_polyline(flame, Color("#ff8f24"), 6.0, true)
				draw_polyline(flame, Color("#ffef5f"), 2.0, true)

	func _draw_wobbly_rect(rect: Rect2, color: Color, width: float) -> void:
		var points := PackedVector2Array([
			rect.position + Vector2(0, 1),
			rect.position + Vector2(rect.size.x, -1),
			rect.position + rect.size + Vector2(1, 0),
			rect.position + Vector2(-1, rect.size.y),
			rect.position + Vector2(0, 1)
		])
		draw_polyline(points, color, width, true)

func _ready() -> void:
	configure("GAME_VACUUM_TITLE", "VACUUM_INSTRUCTIONS", "GAME_VACUUM_DESC", BG_PATH)
	super._ready()
	hide_common_minigame_header()
	hide_base_status()
	_hide_base_header_panel()
	if tutorial_panel:
		tutorial_panel.visible = false
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	usage = START_USAGE
	user_count = 0
	spawn_timer = 0.0
	downgraded = false
	score = 0
	_clear_users()
	_set_model_state(false)
	_update_ui()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	pulse += delta * 8.0
	if downgraded:
		usage = lerpf(usage, SAFE_USAGE, minf(delta * 7.5, 1.0))
		_update_angry_marks()
	else:
		usage = minf(LIMIT, usage + GROWTH_RATE * delta)
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = USER_INTERVAL
			_spawn_user(false)
		if usage >= LIMIT:
			await finish_with_result(false, "VACUUM_FAIL_EMPTY", 0.45)
			return

	_update_ui()

func _build_stage() -> void:
	var tint := ColorRect.new()
	set_full_rect(tint)
	tint.color = Color("#06102144")
	content_layer.add_child(tint)

	user_texture = _load_icon_texture(USER_ICON_PATH, false)
	angry_user_texture = _load_icon_texture(ANGRY_USER_ICON_PATH, true)
	_build_crowd_panel()
	_build_company_panel()
	_build_usage_panel()

func _build_crowd_panel() -> void:
	crowd_panel = _sketch_panel(Vector2(42, 414), Vector2(552, 188), Color("#fff7dce8"), false, Color("#111111"))

	var speaker := _make_icon_texture(SPEAKER_ICON_PATH, Vector2(66, 428), Vector2(62, 62))
	content_layer.add_child(speaker)

	var title := _outlined_label(tr("VACUUM_USERS_TITLE"), 23, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(136, 444)
	title.size = Vector2(420, 38)
	content_layer.add_child(title)

	user_layer = Control.new()
	user_layer.position = Vector2(74, 490)
	user_layer.size = Vector2(488, 76)
	content_layer.add_child(user_layer)

	crowd_state_label = _outlined_label("", 23, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	crowd_state_label.position = Vector2(84, 560)
	crowd_state_label.size = Vector2(470, 36)
	content_layer.add_child(crowd_state_label)

func _build_company_panel() -> void:
	company_panel = _sketch_panel(Vector2(812, 414), Vector2(386, 188), Color("#eef7ffe8"), true, Color("#111111"))

	var model_icon := _make_icon_texture(MODEL_ICON_PATH, Vector2(828, 424), Vector2(88, 88))
	content_layer.add_child(model_icon)

	model_label = _outlined_label("", 28, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	model_label.position = Vector2(914, 434)
	model_label.size = Vector2(252, 56)
	content_layer.add_child(model_label)

	cpu_icon = CpuBurnIcon.new()
	cpu_icon.position = Vector2(846, 516)
	cpu_icon.size = Vector2(150, 70)
	cpu_icon.call("set_state", usage, downgraded)
	content_layer.add_child(cpu_icon)

	downgrade_button = make_button(tr("VACUUM_DOWNGRADE"), 27, Color("#ffef5f"))
	downgrade_button.position = Vector2(1008, 518)
	downgrade_button.size = Vector2(150, 56)
	downgrade_button.pressed.connect(_on_downgrade_pressed)
	content_layer.add_child(downgrade_button)

func _build_usage_panel() -> void:
	_sketch_panel(Vector2(82, 612), Vector2(1118, 80), Color("#fffdf2e8"), false, Color("#111111"))

	var title := _outlined_label(tr("VACUUM_LIMIT_TITLE"), 25, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(116, 628)
	title.size = Vector2(252, 34)
	content_layer.add_child(title)

	usage_bar = ProgressBar.new()
	usage_bar.position = Vector2(358, 634)
	usage_bar.size = Vector2(650, 28)
	usage_bar.min_value = 0.0
	usage_bar.max_value = LIMIT
	usage_bar.show_percentage = false
	usage_bar.add_theme_stylebox_override("background", make_style(Color("#172032"), Color("#111111"), 2, 7))
	usage_bar.add_theme_stylebox_override("fill", make_style(Color("#56d364"), Color("#56d364"), 0, 7))
	content_layer.add_child(usage_bar)

	limit_marker = ColorRect.new()
	limit_marker.position = Vector2(358 + 650 * DANGER_START / LIMIT, 626)
	limit_marker.size = Vector2(7, 44)
	limit_marker.color = Color("#ff3f45")
	content_layer.add_child(limit_marker)

	usage_label = _outlined_label("", 33, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	usage_label.position = Vector2(1034, 622)
	usage_label.size = Vector2(122, 52)
	content_layer.add_child(usage_label)

func _spawn_user(angry: bool) -> void:
	if user_count >= MAX_USERS or not user_layer:
		return
	var index := user_count
	user_count += 1
	var user := TextureRect.new()
	user.texture = angry_user_texture if angry else user_texture
	user.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	user.stretch_mode = TextureRect.STRETCH_SCALE
	user.size = Vector2(38, 46)
	var col := index % USER_COLUMNS
	var row := int(index / USER_COLUMNS)
	user.position = Vector2(0 + col * 40 + randf_range(-3, 3), 42 - row * 24 + randf_range(-2, 2))
	user.rotation = randf_range(-0.08, 0.08)
	user.modulate.a = 0.0
	user_layer.add_child(user)
	users.append(user)
	var tween := create_tween()
	tween.tween_property(user, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(user, "position:y", user.position.y - 18.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_downgrade_pressed() -> void:
	if not running or downgraded:
		return
	if usage < DANGER_START or usage >= LIMIT:
		return

	downgraded = true
	usage = SAFE_USAGE
	score = 100
	_set_model_state(true)
	play_action_sound("collect")
	for user in users:
		user.texture = angry_user_texture
		user.rotation = randf_range(-0.18, 0.18)
	_add_angry_marks()
	_update_ui()
	await get_tree().create_timer(0.55).timeout
	await finish_with_result(true, "VACUUM_SUCCESS", 0.55)

func _set_model_state(is_downgraded: bool) -> void:
	if is_downgraded:
		model_label.text = tr("VACUUM_CHEAP_MODEL")
		crowd_state_label.text = tr("VACUUM_ANGRY")
		if cpu_icon and cpu_icon.has_method("set_state"):
			cpu_icon.call("set_state", usage, true)
		if company_panel and company_panel.has_method("configure"):
			company_panel.call("configure", Color("#eaffdce8"), Color("#35d96b"), 4.0, 1.5, true, Color("#0000000b"))
	else:
		model_label.text = tr("VACUUM_BIG_MODEL")
		crowd_state_label.text = tr("VACUUM_USERS_JOINING")
		if cpu_icon and cpu_icon.has_method("set_state"):
			cpu_icon.call("set_state", usage, false)
		if company_panel and company_panel.has_method("configure"):
			company_panel.call("configure", Color("#eef7ffe8"), Color("#111111"), 4.0, 1.5, true, Color("#0000000b"))

func _update_ui() -> void:
	if usage_bar:
		usage_bar.value = usage
		var fill_color := Color("#56d364") if usage < DANGER_START else Color("#ff5b5b")
		usage_bar.add_theme_stylebox_override("fill", make_style(fill_color, fill_color.darkened(0.16), 0, 7))
	if usage_label:
		usage_label.text = "%d%%" % roundi(usage)
	if downgrade_button:
		var enabled := usage >= DANGER_START and usage < LIMIT and not downgraded
		downgrade_button.disabled = not enabled
		downgrade_button.modulate = Color("#ffffff") if enabled else Color("#ffffff80")
		if enabled:
			downgrade_button.scale = Vector2.ONE * (1.0 + sin(pulse) * 0.04)
		else:
			downgrade_button.scale = Vector2.ONE
	if cpu_icon and cpu_icon.has_method("set_state"):
		cpu_icon.call("set_state", usage, downgraded)
	set_status(tr("VACUUM_STATUS") % [user_count, roundi(usage)])

func _add_angry_marks() -> void:
	for mark in angry_marks:
		if is_instance_valid(mark):
			mark.queue_free()
	angry_marks.clear()
	for index in range(mini(users.size(), 16)):
		var user := users[index]
		var mark := make_label("!", 28, Color("#ff3f45"), HORIZONTAL_ALIGNMENT_CENTER)
		mark.position = user_layer.position + user.position + Vector2(12, -30)
		mark.size = Vector2(30, 30)
		mark.add_theme_color_override("font_outline_color", Color("#ffffff"))
		mark.add_theme_constant_override("outline_size", 3)
		content_layer.add_child(mark)
		angry_marks.append(mark)

func _update_angry_marks() -> void:
	for index in range(angry_marks.size()):
		var mark := angry_marks[index]
		if is_instance_valid(mark):
			mark.position.y += sin(pulse + index) * 0.12

func _clear_users() -> void:
	for user in users:
		if is_instance_valid(user):
			user.queue_free()
	users.clear()
	for mark in angry_marks:
		if is_instance_valid(mark):
			mark.queue_free()
	angry_marks.clear()

func _make_user_texture(angry: bool) -> Texture2D:
	var img := Image.create(64, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color("#00000000"))
	var head := Color("#ffd8a8") if not angry else Color("#ff9a8c")
	var shirt := Color("#6ec8ff") if not angry else Color("#ff5b5b")
	_fill_circle(img, Vector2(32, 20), 15, Color("#151515"))
	_fill_circle(img, Vector2(32, 20), 11, head)
	_fill_round_rect(img, Rect2i(17, 34, 30, 32), shirt, Color("#151515"))
	if angry:
		_draw_line(img, Vector2(22, 17), Vector2(29, 19), Color("#151515"), 3)
		_draw_line(img, Vector2(42, 17), Vector2(35, 19), Color("#151515"), 3)
		_draw_line(img, Vector2(25, 29), Vector2(39, 27), Color("#151515"), 3)
	else:
		_draw_line(img, Vector2(25, 27), Vector2(39, 27), Color("#151515"), 3)
	_fill_circle(img, Vector2(26, 22), 2, Color("#151515"))
	_fill_circle(img, Vector2(39, 22), 2, Color("#151515"))
	_draw_line(img, Vector2(20, 67), Vector2(12, 76), Color("#151515"), 4)
	_draw_line(img, Vector2(44, 67), Vector2(52, 76), Color("#151515"), 4)
	return ImageTexture.create_from_image(img)

func _fill_round_rect(img: Image, rect: Rect2i, fill: Color, border: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			img.set_pixel(x, y, fill)
	for width in range(3):
		_draw_line(img, Vector2(rect.position.x, rect.position.y + width), Vector2(rect.position.x + rect.size.x, rect.position.y + width), border, 1)
		_draw_line(img, Vector2(rect.position.x, rect.position.y + rect.size.y - width), Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y - width), border, 1)
		_draw_line(img, Vector2(rect.position.x + width, rect.position.y), Vector2(rect.position.x + width, rect.position.y + rect.size.y), border, 1)
		_draw_line(img, Vector2(rect.position.x + rect.size.x - width, rect.position.y), Vector2(rect.position.x + rect.size.x - width, rect.position.y + rect.size.y), border, 1)

func _fill_circle(img: Image, center: Vector2, radius: int, color: Color) -> void:
	for y in range(int(center.y) - radius, int(center.y) + radius + 1):
		for x in range(int(center.x) - radius, int(center.x) + radius + 1):
			if center.distance_to(Vector2(x, y)) <= radius:
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
					img.set_pixel(x, y, color)

func _draw_line(img: Image, a: Vector2, b: Vector2, color: Color, width: int) -> void:
	var steps := maxi(1, int(a.distance_to(b)))
	for i in range(steps + 1):
		var p := a.lerp(b, float(i) / float(steps))
		_fill_circle(img, p, width, color)

func _make_icon_texture(path: String, pos: Vector2, icon_size: Vector2) -> Sprite2D:
	var texture := _load_icon_texture(path, false)
	var icon := Sprite2D.new()
	icon.texture = texture
	icon.centered = true
	icon.position = pos + icon_size * 0.5
	if texture:
		icon.scale = Vector2(icon_size.x / float(texture.get_width()), icon_size.y / float(texture.get_height()))
	return icon

func _load_icon_texture(path: String, angry: bool) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return _make_user_texture(angry)

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
	content_layer.add_child(panel)
	return panel

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff") if color != Color("#ffffff") else Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _force_usage(value: float) -> void:
	usage = value
	_update_ui()

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
	await finish_with_result(downgraded, "VACUUM_TIMEOUT_SUCCESS" if downgraded else "VACUUM_FAIL", 0.45)
