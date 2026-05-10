extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_FRAGMENTS := 5
const MISTAKE_LIMIT := 3
const LAYERS := [
	{"key": "ARCHAEOLOGY_USEFUL_GOAL", "useful": true},
	{"key": "ARCHAEOLOGY_USEFUL_CONSTRAINT", "useful": true},
	{"key": "ARCHAEOLOGY_USEFUL_ERROR", "useful": true},
	{"key": "ARCHAEOLOGY_USEFUL_ACCEPTANCE", "useful": true},
	{"key": "ARCHAEOLOGY_USEFUL_FILE", "useful": true},
	{"key": "ARCHAEOLOGY_NOISE_PRAISE", "useful": false},
	{"key": "ARCHAEOLOGY_NOISE_LOGS", "useful": false},
	{"key": "ARCHAEOLOGY_NOISE_OLD_CHAT", "useful": false},
	{"key": "ARCHAEOLOGY_NOISE_VIBES", "useful": false},
	{"key": "ARCHAEOLOGY_NOISE_STACKTRACE", "useful": false}
]

var queue: Array[int] = []
var current_layer := -1
var found := 0
var handled := 0
var mistakes := 0
var layer_label: Label
var verdict_label: Label
var fragment_label: Label
var model_hint: Label
var fragment_bar: ProgressBar
var dig_button: Button
var toss_button: Button
var fragments: Array[ColorRect] = []
var noise_pips: Array[ColorRect] = []

func _ready() -> void:
	configure("GAME_ARCHAEOLOGY_TITLE", "ARCHAEOLOGY_INSTRUCTIONS", "GAME_ARCHAEOLOGY_DESC", "res://assets/sprites/token.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(LAYERS.size()):
		queue.append(index)
	queue.shuffle()
	current_layer = -1
	found = 0
	handled = 0
	mistakes = 0
	score = 0
	fragment_bar.value = 0
	verdict_label.text = tr("ARCHAEOLOGY_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#fff1c6"))
	model_hint.text = tr("ARCHAEOLOGY_MODEL_WAIT")
	_reset_fragments()
	_reset_noise()
	_set_buttons_enabled(true)
	_next_layer()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_on_layer_pressed("dig")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		get_viewport().set_input_as_handled()
		_on_layer_pressed("toss")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#13212b")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(68, 216), Vector2(760, 410), Color("#fff7d6"), true)
	_sketch_panel(Vector2(878, 216), Vector2(330, 410), Color("#1c2532"), false, Color("#1d1d1d"))

	var title := _outlined_label(tr("ARCHAEOLOGY_DIG_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(118, 238)
	title.size = Vector2(660, 52)
	content_layer.add_child(title)

	_sketch_panel(Vector2(140, 326), Vector2(616, 116), Color("#eff7ff"), false, Color("#1f5fbf"))
	layer_label = _outlined_label("", 30, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	layer_label.position = Vector2(166, 344)
	layer_label.size = Vector2(564, 78)
	content_layer.add_child(layer_label)

	toss_button = make_button(tr("ARCHAEOLOGY_TOSS"), 29, Color("#ffe0dc"))
	toss_button.position = Vector2(140, 502)
	toss_button.size = Vector2(292, 76)
	toss_button.pressed.connect(_on_layer_pressed.bind("toss"))
	content_layer.add_child(toss_button)

	dig_button = make_button(tr("ARCHAEOLOGY_DIG"), 29, Color("#dff8da"))
	dig_button.position = Vector2(496, 502)
	dig_button.size = Vector2(292, 76)
	dig_button.pressed.connect(_on_layer_pressed.bind("dig"))
	content_layer.add_child(dig_button)

	_icon("funnel", Vector2(916, 244), Vector2(58, 58), Color("#ffca3a"))
	var side_title := _outlined_label(tr("ARCHAEOLOGY_SIDE_TITLE"), 30, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT)
	side_title.position = Vector2(982, 246)
	side_title.size = Vector2(184, 52)
	content_layer.add_child(side_title)

	fragment_bar = ProgressBar.new()
	fragment_bar.position = Vector2(930, 332)
	fragment_bar.size = Vector2(230, 30)
	fragment_bar.min_value = 0
	fragment_bar.max_value = TARGET_FRAGMENTS
	fragment_bar.show_percentage = false
	content_layer.add_child(fragment_bar)

	fragment_label = _outlined_label("", 21, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	fragment_label.position = Vector2(920, 370)
	fragment_label.size = Vector2(250, 32)
	content_layer.add_child(fragment_label)

	for index in range(TARGET_FRAGMENTS):
		var frag := ColorRect.new()
		frag.position = Vector2(928 + index * 46, 420)
		frag.size = Vector2(34, 46)
		frag.color = Color("#3d4656")
		content_layer.add_child(frag)
		fragments.append(frag)

	for index in range(MISTAKE_LIMIT):
		var pip := ColorRect.new()
		pip.position = Vector2(958 + index * 54, 488)
		pip.size = Vector2(36, 16)
		pip.color = Color("#3d4656")
		content_layer.add_child(pip)
		noise_pips.append(pip)

	model_hint = _outlined_label("", 22, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	model_hint.position = Vector2(922, 520)
	model_hint.size = Vector2(246, 34)
	content_layer.add_child(model_hint)

	verdict_label = _outlined_label("", 24, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(916, 562)
	verdict_label.size = Vector2(258, 42)
	content_layer.add_child(verdict_label)

func _next_layer() -> void:
	if found >= TARGET_FRAGMENTS:
		await finish_with_result(true, "ARCHAEOLOGY_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(LAYERS.size()):
			queue.append(index)
		queue.shuffle()
	current_layer = queue.pop_back()
	layer_label.text = tr(LAYERS[current_layer]["key"])

func _on_layer_pressed(action: String) -> void:
	if not running or current_layer < 0:
		return

	var data: Dictionary = LAYERS[current_layer]
	var useful := bool(data["useful"])
	var correct := (action == "dig") == useful
	handled += 1

	if correct and useful:
		found += 1
		score = found
		fragment_bar.value = found
		_mark_fragment(found - 1)
		verdict_label.text = tr("ARCHAEOLOGY_FOUND")
		verdict_label.add_theme_color_override("font_color", Color("#5cff86"))
		model_hint.text = tr("ARCHAEOLOGY_MODEL_SIGNAL")
	elif correct:
		verdict_label.text = tr("ARCHAEOLOGY_CLEANED")
		verdict_label.add_theme_color_override("font_color", Color("#91c9e8"))
		model_hint.text = tr("ARCHAEOLOGY_MODEL_CLEAN")
	else:
		mistakes += 1
		_mark_noise()
		verdict_label.text = tr("ARCHAEOLOGY_WRONG")
		verdict_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		model_hint.text = tr("ARCHAEOLOGY_MODEL_NOISE")
		_shake(layer_label)
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "ARCHAEOLOGY_FAIL", 0.65)
			return

	_update_status()
	_next_layer()

func _mark_fragment(index: int) -> void:
	if index >= 0 and index < fragments.size():
		fragments[index].color = Color("#bdfb7f")

func _reset_fragments() -> void:
	for frag in fragments:
		frag.color = Color("#3d4656")

func _mark_noise() -> void:
	var index := int(clamp(mistakes - 1, 0, noise_pips.size() - 1))
	if index >= 0 and index < noise_pips.size():
		noise_pips[index].color = Color("#ff5b5b")

func _reset_noise() -> void:
	for pip in noise_pips:
		pip.color = Color("#3d4656")

func _set_buttons_enabled(enabled: bool) -> void:
	if dig_button:
		dig_button.disabled = not enabled
	if toss_button:
		toss_button.disabled = not enabled

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.04)
	tween.tween_property(node, "position:x", original.x + 10, 0.04)
	tween.tween_property(node, "position", original, 0.05)

func _update_status() -> void:
	fragment_label.text = tr("ARCHAEOLOGY_FRAGMENTS") % [found, TARGET_FRAGMENTS]
	set_status(tr("ARCHAEOLOGY_STATUS") % [found, TARGET_FRAGMENTS, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
	content_layer.add_child(panel)
	return panel

func _icon(name: String, pos: Vector2, icon_size: Vector2, color: Color) -> Control:
	var icon: Control = SketchIcon.new()
	icon.position = pos
	icon.size = icon_size
	icon.call("configure", name, color, Color("#ffffff"))
	content_layer.add_child(icon)
	return icon

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff") if color != Color("#ffffff") else Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	var success := found >= TARGET_FRAGMENTS
	await finish_with_result(success, "ARCHAEOLOGY_TIMEOUT_SUCCESS" if success else "ARCHAEOLOGY_TIMEOUT_FAIL", 0.45)
