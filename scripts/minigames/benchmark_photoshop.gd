extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")

const TARGET_BARS := 7
const MISTAKE_LIMIT := 3
const BARS := [
	{"key": "PHOTOSHOP_REAL_LATENCY", "fake": false, "value": 64},
	{"key": "PHOTOSHOP_REAL_COST", "fake": false, "value": 70},
	{"key": "PHOTOSHOP_REAL_HUMAN", "fake": false, "value": 82},
	{"key": "PHOTOSHOP_FAKE_PRIVATE", "fake": true, "value": 99},
	{"key": "PHOTOSHOP_FAKE_LEAKED", "fake": true, "value": 112},
	{"key": "PHOTOSHOP_FAKE_SLIDE", "fake": true, "value": 120},
	{"key": "PHOTOSHOP_REAL_HELDOUT", "fake": false, "value": 78},
	{"key": "PHOTOSHOP_FAKE_CHERRY", "fake": true, "value": 140}
]

var queue: Array[int] = []
var current_bar := -1
var edited := 0
var mistakes := 0
var bar_label: Label
var bar_fill: ColorRect
var verdict_label: Label
var edit_bar: ProgressBar
var stretch_button: Button
var crop_button: Button

func _ready() -> void:
	configure("GAME_PHOTOSHOP_TITLE", "PHOTOSHOP_INSTRUCTIONS", "GAME_PHOTOSHOP_DESC", "res://assets/art/benchmark_arena_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(BARS.size()):
		queue.append(index)
	queue.shuffle()
	current_bar = -1
	edited = 0
	mistakes = 0
	score = 0
	edit_bar.value = 0
	verdict_label.text = tr("PHOTOSHOP_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#151515"))
	_next_bar()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_on_tool_pressed("stretch")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		_on_tool_pressed("crop")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fff7dd")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(82, 214), Vector2(760, 408), Color("#fffdf8"), true)
	_sketch_panel(Vector2(888, 214), Vector2(298, 408), Color("#f1f8ff"), false)

	var title := _outlined_label(tr("PHOTOSHOP_BOARD_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(122, 236)
	title.size = Vector2(680, 52)
	content_layer.add_child(title)

	_sketch_panel(Vector2(154, 322), Vector2(620, 118), Color("#f8fbff"), false, Color("#1f5fbf"))
	bar_label = _outlined_label("", 29, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	bar_label.position = Vector2(178, 330)
	bar_label.size = Vector2(572, 54)
	content_layer.add_child(bar_label)

	var track := ColorRect.new()
	track.position = Vector2(198, 390)
	track.size = Vector2(532, 26)
	track.color = Color("#d9d9d9")
	content_layer.add_child(track)

	bar_fill = ColorRect.new()
	bar_fill.position = Vector2.ZERO
	bar_fill.size = Vector2(10, 26)
	bar_fill.color = Color("#63d471")
	track.add_child(bar_fill)

	crop_button = make_button(tr("PHOTOSHOP_CROP"), 28, Color("#e4f4ff"))
	crop_button.position = Vector2(150, 500)
	crop_button.size = Vector2(286, 76)
	crop_button.pressed.connect(_on_tool_pressed.bind("crop"))
	content_layer.add_child(crop_button)

	stretch_button = make_button(tr("PHOTOSHOP_STRETCH"), 28, Color("#ffe0dc"))
	stretch_button.position = Vector2(488, 500)
	stretch_button.size = Vector2(286, 76)
	stretch_button.pressed.connect(_on_tool_pressed.bind("stretch"))
	content_layer.add_child(stretch_button)

	var side_title := _outlined_label(tr("PHOTOSHOP_SIDE_TITLE"), 29, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(918, 246)
	side_title.size = Vector2(238, 50)
	content_layer.add_child(side_title)

	edit_bar = ProgressBar.new()
	edit_bar.position = Vector2(926, 348)
	edit_bar.size = Vector2(230, 30)
	edit_bar.min_value = 0
	edit_bar.max_value = TARGET_BARS
	edit_bar.show_percentage = false
	content_layer.add_child(edit_bar)

	verdict_label = _outlined_label("", 25, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(918, 430)
	verdict_label.size = Vector2(246, 90)
	content_layer.add_child(verdict_label)

func _next_bar() -> void:
	if edited >= TARGET_BARS:
		await finish_with_result(true, "PHOTOSHOP_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(BARS.size()):
			queue.append(index)
		queue.shuffle()
	current_bar = queue.pop_back()
	var data: Dictionary = BARS[current_bar]
	bar_label.text = tr(data["key"])
	bar_fill.size.x = clamp(float(data["value"]) / 140.0, 0.05, 1.0) * 532.0
	bar_fill.color = Color("#ff5b5b") if bool(data["fake"]) else Color("#63d471")

func _on_tool_pressed(tool: String) -> void:
	if not running or current_bar < 0:
		return
	var data: Dictionary = BARS[current_bar]
	var fake := bool(data["fake"])
	var correct := (tool == "stretch") == fake
	if correct:
		edited += 1
		score = edited
		edit_bar.value = edited
		verdict_label.text = tr("PHOTOSHOP_GOOD_FAKE") if fake else tr("PHOTOSHOP_GOOD_REAL")
		verdict_label.add_theme_color_override("font_color", Color("#11883a"))
	else:
		mistakes += 1
		verdict_label.text = tr("PHOTOSHOP_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#d91e18"))
		_shake(bar_label)
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "PHOTOSHOP_FAIL", 0.6)
			return
	_update_status()
	_next_bar()

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.04)
	tween.tween_property(node, "position:x", original.x + 10, 0.04)
	tween.tween_property(node, "position", original, 0.05)

func _update_status() -> void:
	set_status(tr("PHOTOSHOP_STATUS") % [edited, TARGET_BARS, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
	content_layer.add_child(panel)
	return panel

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(edited >= TARGET_BARS, "PHOTOSHOP_TIMEOUT_SUCCESS" if edited >= TARGET_BARS else "PHOTOSHOP_TIMEOUT_FAIL", 0.45)
