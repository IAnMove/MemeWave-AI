extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_DECISIONS := 7
const EVALS := [
	{"key": "EVAL_REAL_HELDOUT", "honest": true, "score": 78},
	{"key": "EVAL_REAL_LATENCY", "honest": true, "score": 64},
	{"key": "EVAL_REAL_HUMAN", "honest": true, "score": 82},
	{"key": "EVAL_FAKE_TINY", "honest": false, "score": 99},
	{"key": "EVAL_FAKE_LEAKED", "honest": false, "score": 101},
	{"key": "EVAL_FAKE_POWERPOINT", "honest": false, "score": 120},
	{"key": "EVAL_REAL_COST", "honest": true, "score": 70},
	{"key": "EVAL_FAKE_CHERRY", "honest": false, "score": 999}
]

var queue: Array[int] = []
var current_eval := -1
var handled := 0
var mistakes := 0
var eval_label: Label
var bar_fill: ColorRect
var verdict_label: Label
var keep_button: Button
var trash_button: Button
var pips: Array[ColorRect] = []

func _ready() -> void:
	configure("GAME_EVAL_TITLE", "EVAL_INSTRUCTIONS", "GAME_EVAL_DESC", "res://assets/art/eval_cherry_picker_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(EVALS.size()):
		queue.append(index)
	queue.shuffle()
	current_eval = -1
	handled = 0
	mistakes = 0
	score = 0
	verdict_label.text = tr("EVAL_VERDICT_IDLE")
	_set_buttons_enabled(true)
	_reset_pips()
	_next_eval()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_on_decision_pressed("keep")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		get_viewport().set_input_as_handled()
		_on_decision_pressed("trash")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fff7dd")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(82, 214), Vector2(760, 405), Color("#fffdf8"), true)
	_sketch_panel(Vector2(884, 214), Vector2(300, 405), Color("#f1f8ff"), false)

	var title := _outlined_label(tr("EVAL_BOARD_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(112, 230)
	title.size = Vector2(700, 48)
	content_layer.add_child(title)

	_sketch_panel(Vector2(152, 310), Vector2(620, 128), Color("#f8fbff"), false, Color("#1f5fbf"))
	eval_label = _outlined_label("", 30, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	eval_label.position = Vector2(176, 320)
	eval_label.size = Vector2(572, 58)
	content_layer.add_child(eval_label)

	var track := ColorRect.new()
	track.position = Vector2(194, 386)
	track.size = Vector2(536, 24)
	track.color = Color("#dadada")
	content_layer.add_child(track)

	bar_fill = ColorRect.new()
	bar_fill.position = Vector2.ZERO
	bar_fill.size = Vector2(10, 24)
	bar_fill.color = Color("#63d471")
	track.add_child(bar_fill)

	trash_button = make_button(tr("EVAL_TRASH"), 30, Color("#ffe0dc"))
	trash_button.position = Vector2(150, 480)
	trash_button.size = Vector2(285, 78)
	trash_button.pressed.connect(_on_decision_pressed.bind("trash"))
	content_layer.add_child(trash_button)

	keep_button = make_button(tr("EVAL_KEEP"), 30, Color("#e4f4ff"))
	keep_button.position = Vector2(488, 480)
	keep_button.size = Vector2(285, 78)
	keep_button.pressed.connect(_on_decision_pressed.bind("keep"))
	content_layer.add_child(keep_button)

	_icon("star", Vector2(912, 244), Vector2(56, 56), Color("#ffe34d"))
	var side_title := _outlined_label(tr("EVAL_SIDE_TITLE"), 30, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	side_title.position = Vector2(975, 246)
	side_title.size = Vector2(174, 52)
	content_layer.add_child(side_title)

	verdict_label = _outlined_label("", 27, Color("#11883a"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(922, 332)
	verdict_label.size = Vector2(222, 92)
	content_layer.add_child(verdict_label)

	for index in range(TARGET_DECISIONS):
		var pip := ColorRect.new()
		pip.position = Vector2(914 + index * 32, 474)
		pip.size = Vector2(22, 42)
		pip.color = Color("#d9d9d9")
		content_layer.add_child(pip)
		pips.append(pip)

	var hint := _outlined_label(tr("EVAL_KEYS"), 18, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(904, 548)
	hint.size = Vector2(260, 42)
	content_layer.add_child(hint)

func _next_eval() -> void:
	if handled >= TARGET_DECISIONS:
		finish_with_result(true, "EVAL_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(EVALS.size()):
			queue.append(index)
		queue.shuffle()
	current_eval = queue.pop_back()
	var data: Dictionary = EVALS[current_eval]
	eval_label.text = tr(data["key"])
	bar_fill.size.x = clamp(float(data["score"]) / 120.0, 0.05, 1.0) * 536.0
	bar_fill.color = Color("#63d471") if bool(data["honest"]) else Color("#ff5b5b")

func _on_decision_pressed(decision: String) -> void:
	if not running or current_eval < 0:
		return
	var data: Dictionary = EVALS[current_eval]
	var correct := (decision == "keep") == bool(data["honest"])
	if correct:
		handled += 1
		score = handled
		verdict_label.text = tr("EVAL_VERDICT_GOOD")
		verdict_label.add_theme_color_override("font_color", Color("#11883a"))
		_mark_pip(handled - 1, Color("#63d471"))
	else:
		mistakes += 1
		verdict_label.text = tr("EVAL_VERDICT_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#d91e18"))
		_shake(eval_label)
		if mistakes >= 3:
			await finish_with_result(false, "EVAL_FAIL", 0.65)
			return
	_next_eval()
	_update_status()

func _mark_pip(index: int, color: Color) -> void:
	if index >= 0 and index < pips.size():
		pips[index].color = color

func _reset_pips() -> void:
	for pip in pips:
		pip.color = Color("#d9d9d9")

func _set_buttons_enabled(enabled: bool) -> void:
	if keep_button:
		keep_button.disabled = not enabled
	if trash_button:
		trash_button.disabled = not enabled

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.05)
	tween.tween_property(node, "position:x", original.x + 10, 0.05)
	tween.tween_property(node, "position", original, 0.06)

func _update_status() -> void:
	set_status(tr("EVAL_STATUS") % [handled, TARGET_DECISIONS, mistakes])

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
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(handled >= TARGET_DECISIONS, "EVAL_TIMEOUT_SUCCESS" if handled >= TARGET_DECISIONS else "EVAL_FAIL_TIMEOUT", 0.45)
