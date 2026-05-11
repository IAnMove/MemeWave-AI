extends "res://scripts/minigames/base_minigame.gd"

const BG_PATH := "res://assets/art/red_button_bg.png"
const SCOLD_PATH := "res://assets/art/red_button_scold.png"
const WAIT_SECONDS := 4.2

var safe_time := 0.0
var pressed_red := false
var pulse := 0.0
var button_base: PanelContainer
var button_top: TextureButton
var button_label: Label
var progress_bar: ProgressBar
var alarm_overlay: ColorRect
var scold_sprite: TextureRect
var scold_label: Label
var sparks: Array[Line2D] = []

func _ready() -> void:
	configure("GAME_RENAME_TITLE", "RENAME_INSTRUCTIONS", "GAME_RENAME_DESC", BG_PATH)
	super._ready()
	hide_common_minigame_header()
	hide_base_status()
	_hide_base_header_panel()
	if tutorial_panel:
		tutorial_panel.visible = false
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	safe_time = 0.0
	pressed_red = false
	score = 0
	button_base.visible = true
	button_top.disabled = false
	button_top.scale = Vector2.ONE
	button_top.position = Vector2(396, 222)
	alarm_overlay.visible = false
	alarm_overlay.color = Color("#ff000000")
	scold_sprite.visible = false
	scold_label.visible = false
	progress_bar.value = 0
	for spark in sparks:
		spark.visible = true

func _process(delta: float) -> void:
	super._process(delta)
	if not running or pressed_red:
		return

	safe_time += delta
	score = roundi(safe_time * 100.0 / WAIT_SECONDS)
	progress_bar.value = safe_time
	pulse += delta * 18.0
	var shake := Vector2(sin(pulse) * 7.0, cos(pulse * 1.35) * 5.0)
	button_top.position = Vector2(396, 222) + shake
	button_top.scale = Vector2.ONE * (1.0 + sin(pulse * 0.7) * 0.035)
	for index in range(sparks.size()):
		sparks[index].modulate.a = 0.45 + sin(pulse + index) * 0.35

	if safe_time >= WAIT_SECONDS:
		_survive_button()

func _build_stage() -> void:
	_build_button()
	_build_safe_meter()
	_build_alarm()
	_build_scold()
	_build_sparks()

func _build_button() -> void:
	button_base = PanelContainer.new()
	button_base.position = Vector2(300, 310)
	button_base.size = Vector2(420, 210)
	button_base.add_theme_stylebox_override("panel", make_style(Color("#5f1616"), Color("#151515"), 8, 42))
	content_layer.add_child(button_base)

	button_top = TextureButton.new()
	button_top.position = Vector2(396, 222)
	button_top.size = Vector2(238, 238)
	button_top.ignore_texture_size = true
	button_top.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button_top.texture_normal = _make_button_texture(Color("#ff2727"), Color("#151515"))
	button_top.texture_hover = _make_button_texture(Color("#ff4a4a"), Color("#151515"))
	button_top.texture_pressed = _make_button_texture(Color("#b51620"), Color("#151515"))
	button_top.pivot_offset = Vector2(119, 119)
	button_top.pressed.connect(_press_red_button)
	content_layer.add_child(button_top)

	button_label = make_label(tr("RENAME_NO_PRESS"), 38, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	button_label.position = Vector2(402, 314)
	button_label.size = Vector2(226, 62)
	button_label.add_theme_color_override("font_outline_color", Color("#151515"))
	button_label.add_theme_constant_override("outline_size", 7)
	button_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(button_label)

func _build_safe_meter() -> void:
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(296, 552)
	progress_bar.size = Vector2(426, 28)
	progress_bar.max_value = WAIT_SECONDS
	progress_bar.show_percentage = false
	progress_bar.modulate = Color("#66f28b")
	content_layer.add_child(progress_bar)

func _build_alarm() -> void:
	alarm_overlay = ColorRect.new()
	alarm_overlay.position = Vector2.ZERO
	alarm_overlay.size = Vector2(1280, 720)
	alarm_overlay.color = Color("#ff000000")
	alarm_overlay.visible = false
	alarm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alarm_overlay.z_index = 40
	content_layer.add_child(alarm_overlay)

func _build_scold() -> void:
	scold_sprite = make_sprite(SCOLD_PATH, Vector2(300, 390))
	scold_sprite.position = Vector2(890, 184)
	scold_sprite.z_index = 45
	scold_sprite.visible = false
	scold_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(scold_sprite)

	scold_label = make_label(tr("RENAME_SCOLD"), 28, Color("#bf2030"), HORIZONTAL_ALIGNMENT_CENTER)
	scold_label.position = Vector2(862, 562)
	scold_label.size = Vector2(358, 78)
	scold_label.z_index = 46
	scold_label.visible = false
	scold_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	scold_label.add_theme_constant_override("outline_size", 6)
	content_layer.add_child(scold_label)

func _build_sparks() -> void:
	sparks.clear()
	var center := Vector2(515, 340)
	for index in range(14):
		var angle := TAU * float(index) / 14.0
		var spark := Line2D.new()
		spark.width = 6.0
		spark.default_color = Color("#ff5b5b")
		spark.points = PackedVector2Array([
			center + Vector2(cos(angle), sin(angle)) * 146.0,
			center + Vector2(cos(angle), sin(angle)) * 190.0
		])
		spark.z_index = 11
		content_layer.add_child(spark)
		sparks.append(spark)

func _make_button_texture(fill: Color, border: Color) -> ImageTexture:
	var image := Image.create(238, 238, false, Image.FORMAT_RGBA8)
	image.fill(Color("#00000000"))
	var center := Vector2(119, 119)
	for y in range(238):
		for x in range(238):
			var dist := center.distance_to(Vector2(x, y))
			if dist <= 108.0:
				var shade := 1.0 - dist / 180.0
				image.set_pixel(x, y, fill.lightened(shade * 0.24))
			elif dist <= 119.0:
				image.set_pixel(x, y, border)
	return ImageTexture.create_from_image(image)

func _press_red_button() -> void:
	if not running or pressed_red:
		return
	pressed_red = true
	button_top.disabled = true
	play_action_sound("bad")
	alarm_overlay.visible = true
	scold_sprite.visible = true
	scold_label.text = tr("RENAME_SCOLD")
	scold_label.visible = true
	for spark in sparks:
		spark.visible = false
	var tween := create_tween()
	tween.set_loops(5)
	tween.tween_property(alarm_overlay, "color", Color("#ff00005a"), 0.08)
	tween.tween_property(alarm_overlay, "color", Color("#ff000000"), 0.08)
	await get_tree().create_timer(0.82).timeout
	await finish_with_result(false, "RENAME_FAIL", 0.45)

func _survive_button() -> void:
	if not running:
		return
	play_action_sound("collect")
	button_top.disabled = true
	for spark in sparks:
		spark.visible = false
	await finish_with_result(true, "RENAME_SUCCESS", 0.45)

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
	await finish_with_result(not pressed_red, "RENAME_SUCCESS" if not pressed_red else "RENAME_FAIL", 0.45)
