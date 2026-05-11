extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const SAFE_BG_PATH := "res://assets/art/copycat_classroom_safe.png"
const DANGER_BG_PATH := "res://assets/art/copycat_classroom_danger.png"
const COPY_TARGET := 100.0
const COPY_RATE := 48.0
const DANGER_GRACE := 0.13

var copy_title_key := ""
var copy_description_key := ""
var copy_success_key := ""
var source_name := ""
var target_name := ""
var source_icon := "computer_good"
var target_icon := "computer_good"
var source_color := Color("#d8b7ff")
var target_color := Color("#a7ff8f")

var safe_bg: TextureRect
var danger_bg: TextureRect
var source_card: Control
var target_ghost: Control
var target_reveal: Control
var progress_fill: ColorRect
var warning_badge: Control
var pencil_tip: ColorRect

var copy_progress := 0.0
var phase_timer := 0.0
var dario_watching := false
var held_in_danger := 0.0
var caught := false
var forced_hold_enabled := false
var forced_hold := false

func _ready() -> void:
	configure(copy_title_key, "COPYCAT_INSTRUCTIONS", copy_description_key, "")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	copy_progress = 0.0
	phase_timer = 1.05
	dario_watching = false
	held_in_danger = 0.0
	caught = false
	forced_hold_enabled = false
	forced_hold = false
	score = 0
	_update_phase_visual()
	_update_copy_visual()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	_update_phase(delta)
	_update_copy(delta)

func _build_stage() -> void:
	safe_bg = _make_bg(SAFE_BG_PATH)
	danger_bg = _make_bg(DANGER_BG_PATH)
	danger_bg.visible = false

	source_card = _make_product_card(Vector2(748, 472), Vector2(286, 126), source_name, source_icon, source_color, 1.0)
	target_ghost = _make_product_card(Vector2(136, 468), Vector2(286, 126), target_name, target_icon, target_color, 0.18)

	target_reveal = Control.new()
	target_reveal.position = target_ghost.position
	target_reveal.size = Vector2(1, target_ghost.size.y)
	target_reveal.clip_contents = true
	target_reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(target_reveal)
	var target_full := _make_product_card(Vector2.ZERO, target_ghost.size, target_name, target_icon, target_color, 1.0, target_reveal)
	target_full.position = Vector2.ZERO

	_build_progress_bar()
	_build_warning_badge()

	pencil_tip = ColorRect.new()
	pencil_tip.size = Vector2(46, 8)
	pencil_tip.color = Color("#ffd447")
	pencil_tip.rotation = -0.45
	pencil_tip.visible = false
	content_layer.add_child(pencil_tip)

func _make_bg(path: String) -> TextureRect:
	var bg := TextureRect.new()
	set_full_rect(bg)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(path):
		bg.texture = load(path)
	add_child(bg)
	move_child(bg, 1)
	return bg

func _make_product_card(
		pos: Vector2,
		card_size: Vector2,
		name_text: String,
		icon_name: String,
		accent: Color,
		alpha: float,
		parent: Control = null
	) -> Control:
	if not parent:
		parent = content_layer
	var card: Control = SketchPanel.new()
	card.position = pos
	card.size = card_size
	card.modulate.a = alpha
	card.call("configure", Color("#fffdf4"), Color("#111111"), 4.0, 2.3, true, Color("#00000012"))
	parent.add_child(card)

	var icon: Control = SketchIcon.new()
	icon.position = Vector2(16, 18)
	icon.size = Vector2(78, 78)
	icon.call("configure", icon_name, accent, Color("#ffffff"), Color("#111111"))
	card.add_child(icon)

	var name_label := make_label(name_text, 27, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	name_label.position = Vector2(96, 20)
	name_label.size = Vector2(card_size.x - 114.0, 74)
	name_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	name_label.add_theme_constant_override("outline_size", 3)
	card.add_child(name_label)

	for index in range(3):
		var scribble := ColorRect.new()
		scribble.position = Vector2(112, 90 + index * 8)
		scribble.size = Vector2(128 - index * 22, 3)
		scribble.color = accent.darkened(0.2)
		card.add_child(scribble)

	return card

func _build_progress_bar() -> void:
	var track: Control = SketchPanel.new()
	track.position = Vector2(404, 610)
	track.size = Vector2(472, 42)
	track.call("configure", Color("#fff5c8"), Color("#111111"), 4.0, 2.0, false)
	content_layer.add_child(track)

	progress_fill = ColorRect.new()
	progress_fill.position = Vector2(8, 9)
	progress_fill.size = Vector2(1, 24)
	progress_fill.color = Color("#59d96d")
	track.add_child(progress_fill)

	var label := make_label(tr("COPYCAT_COPY_LABEL"), 22, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(0, 0)
	label.size = track.size
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	track.add_child(label)

func _build_warning_badge() -> void:
	warning_badge = SketchPanel.new()
	warning_badge.position = Vector2(544, 224)
	warning_badge.size = Vector2(192, 68)
	warning_badge.call("configure", Color("#ff595e"), Color("#111111"), 5.0, 2.8, true, Color("#ffffff18"))
	warning_badge.visible = false
	content_layer.add_child(warning_badge)

	var warning := make_label("!", 52, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	warning.position = Vector2(0, 0)
	warning.size = warning_badge.size
	warning.add_theme_color_override("font_outline_color", Color("#111111"))
	warning.add_theme_constant_override("outline_size", 8)
	warning_badge.add_child(warning)

func _update_phase(delta: float) -> void:
	phase_timer -= delta
	if phase_timer > 0.0:
		return

	dario_watching = not dario_watching
	phase_timer = randf_range(0.58, 0.82) if dario_watching else randf_range(0.82, 1.22)
	_update_phase_visual()

func _update_copy(delta: float) -> void:
	var holding := _is_holding()
	pencil_tip.visible = holding and not caught
	pencil_tip.position = Vector2(226 + copy_progress * 1.68, 560 - sin(copy_progress * 0.09) * 8.0)

	if holding and dario_watching:
		held_in_danger += delta
		if held_in_danger >= DANGER_GRACE:
			_fail_copy()
		return

	held_in_danger = 0.0
	if holding and not dario_watching:
		copy_progress = minf(COPY_TARGET, copy_progress + COPY_RATE * delta)
		score = int(copy_progress)
		_update_copy_visual()
		if copy_progress >= COPY_TARGET:
			await _finish_copy()

func _is_holding() -> bool:
	if forced_hold_enabled:
		return forced_hold
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)

func _update_phase_visual() -> void:
	safe_bg.visible = not dario_watching
	danger_bg.visible = dario_watching
	warning_badge.visible = dario_watching
	set_status(tr("COPYCAT_DANGER") if dario_watching else tr("COPYCAT_SAFE") % int(copy_progress))

func _update_copy_visual() -> void:
	var ratio := clampf(copy_progress / COPY_TARGET, 0.0, 1.0)
	target_reveal.size.x = target_ghost.size.x * ratio
	progress_fill.size.x = 456.0 * ratio
	if not dario_watching:
		set_status(tr("COPYCAT_SAFE") % int(copy_progress))

func _fail_copy() -> void:
	if caught or not running:
		return
	caught = true
	score = int(copy_progress)
	await finish_with_result(false, "COPYCAT_CAUGHT", 0.55)

func _finish_copy() -> void:
	if caught or not running:
		return
	await finish_with_result(true, copy_success_key, 0.72)

func _force_hold(value: bool) -> void:
	forced_hold_enabled = true
	forced_hold = value

func _force_dario_watching(value: bool) -> void:
	dario_watching = value
	phase_timer = 99.0
	_update_phase_visual()

func on_timeout() -> void:
	var success := copy_progress >= COPY_TARGET
	await finish_with_result(success, copy_success_key if success else "COPYCAT_TIMEOUT_FAIL", 0.45)
