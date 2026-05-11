extends "res://scripts/minigames/base_minigame.gd"

const DANGER_START := 75.0
const LIMIT := 100.0
const SAFE_USAGE := 10.0
const START_USAGE := 22.0
const GROWTH_RATE := 18.5
const USER_INTERVAL := 0.22
const MAX_USERS := 46

var usage := START_USAGE
var user_count := 0
var spawn_timer := 0.0
var downgraded := false
var pulse := 0.0

var user_layer: Control
var users: Array[TextureRect] = []
var angry_marks: Array[Label] = []
var usage_bar: ProgressBar
var limit_marker: ColorRect
var usage_label: Label
var model_label: Label
var cpu_panel: PanelContainer
var cpu_blocks: Array[ColorRect] = []
var downgrade_button: Button
var crowd_state_label: Label

var user_texture: Texture2D
var angry_user_texture: Texture2D

func _ready() -> void:
	configure("GAME_VACUUM_TITLE", "VACUUM_INSTRUCTIONS", "GAME_VACUUM_DESC", "")
	super._ready()
	hide_common_minigame_header()
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
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#142234")
	add_child(bg)
	move_child(bg, 0)

	user_texture = _make_user_texture(false)
	angry_user_texture = _make_user_texture(true)
	_build_crowd_panel()
	_build_company_panel()
	_build_usage_panel()

func _build_crowd_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(48, 118)
	panel.size = Vector2(710, 388)
	panel.add_theme_stylebox_override("panel", make_style(Color("#f7f1d8"), Color("#151515"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("VACUUM_USERS_TITLE"), 30, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(76, 132)
	title.size = Vector2(654, 42)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(title)

	user_layer = Control.new()
	user_layer.position = Vector2(80, 190)
	user_layer.size = Vector2(650, 286)
	content_layer.add_child(user_layer)

	crowd_state_label = make_label("", 28, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	crowd_state_label.position = Vector2(98, 462)
	crowd_state_label.size = Vector2(614, 36)
	crowd_state_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	crowd_state_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(crowd_state_label)

func _build_company_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(806, 118)
	panel.size = Vector2(388, 388)
	panel.add_theme_stylebox_override("panel", make_style(Color("#eef7ff"), Color("#151515"), 5, 8))
	content_layer.add_child(panel)

	model_label = make_label("", 30, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	model_label.position = Vector2(834, 134)
	model_label.size = Vector2(332, 48)
	model_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	model_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(model_label)

	cpu_panel = PanelContainer.new()
	cpu_panel.position = Vector2(890, 206)
	cpu_panel.size = Vector2(218, 176)
	cpu_panel.add_theme_stylebox_override("panel", make_style(Color("#2d333a"), Color("#151515"), 5, 14))
	content_layer.add_child(cpu_panel)

	var screen := ColorRect.new()
	screen.position = Vector2(924, 238)
	screen.size = Vector2(150, 70)
	screen.color = Color("#0c1014")
	content_layer.add_child(screen)

	cpu_blocks.clear()
	for index in range(4):
		var block := ColorRect.new()
		block.position = Vector2(918 + index * 42, 332)
		block.size = Vector2(30, 30)
		block.color = Color("#56d364")
		content_layer.add_child(block)
		cpu_blocks.append(block)

	for index in range(3):
		var flame := Line2D.new()
		flame.name = "CpuFlame"
		flame.width = 8.0
		flame.default_color = Color("#ff5b5b")
		flame.points = PackedVector2Array([
			Vector2(936 + index * 55, 204),
			Vector2(956 + index * 55, 158),
			Vector2(978 + index * 55, 204)
		])
		flame.z_index = 3
		content_layer.add_child(flame)

	downgrade_button = make_button(tr("VACUUM_DOWNGRADE"), 31, Color("#ffef5f"))
	downgrade_button.position = Vector2(848, 414)
	downgrade_button.size = Vector2(304, 70)
	downgrade_button.pressed.connect(_on_downgrade_pressed)
	content_layer.add_child(downgrade_button)

func _build_usage_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(82, 540)
	panel.size = Vector2(1118, 104)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fffdf2"), Color("#151515"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("VACUUM_LIMIT_TITLE"), 28, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(112, 554)
	title.size = Vector2(270, 38)
	content_layer.add_child(title)

	usage_bar = ProgressBar.new()
	usage_bar.position = Vector2(356, 572)
	usage_bar.size = Vector2(714, 34)
	usage_bar.min_value = 0.0
	usage_bar.max_value = LIMIT
	usage_bar.show_percentage = false
	content_layer.add_child(usage_bar)

	limit_marker = ColorRect.new()
	limit_marker.position = Vector2(356 + 714 * DANGER_START / LIMIT, 562)
	limit_marker.size = Vector2(7, 54)
	limit_marker.color = Color("#ff3f45")
	content_layer.add_child(limit_marker)

	usage_label = make_label("", 34, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	usage_label.position = Vector2(1086, 552)
	usage_label.size = Vector2(82, 56)
	usage_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	usage_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(usage_label)

func _spawn_user(angry: bool) -> void:
	if user_count >= MAX_USERS or not user_layer:
		return
	var index := user_count
	user_count += 1
	var user := TextureRect.new()
	user.texture = angry_user_texture if angry else user_texture
	user.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	user.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	user.size = Vector2(54, 68)
	var col := index % 12
	var row := index / 12
	user.position = Vector2(14 + col * 52 + randf_range(-6, 6), 196 - row * 54 + randf_range(-4, 4))
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
		cpu_panel.add_theme_stylebox_override("panel", make_style(Color("#d9f7d1"), Color("#35d96b"), 5, 14))
	else:
		model_label.text = tr("VACUUM_BIG_MODEL")
		crowd_state_label.text = tr("VACUUM_USERS_JOINING")
		cpu_panel.add_theme_stylebox_override("panel", make_style(Color("#2d333a"), Color("#151515"), 5, 14))

func _update_ui() -> void:
	if usage_bar:
		usage_bar.value = usage
		usage_bar.modulate = Color("#56d364") if usage < DANGER_START else Color("#ff5b5b")
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
	if cpu_blocks:
		for index in range(cpu_blocks.size()):
			var hot := usage >= 70.0
			cpu_blocks[index].color = Color("#ff5b5b") if hot else Color("#56d364")
			cpu_blocks[index].scale.y = 0.45 + usage / LIMIT * 0.75
	for child in content_layer.get_children():
		if child.name == "CpuFlame":
			child.visible = usage >= 72.0 and not downgraded
			child.modulate.a = 0.45 + sin(pulse + child.get_index()) * 0.25
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
