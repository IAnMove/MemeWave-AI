extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")

const TARGET_HITS := 5

var track: Control
var green_zone: ColorRect
var cursor: Control
var run_button: Button
var bench_fill: ColorRect
var skill_fill: ColorRect
var score_label: Label
var feedback_label: Label
var memory_pips: Array[ColorRect] = []
var hits := 0
var overfits := 0
var phase := 0.0

class BenchDoodleIcon:
	extends Control

	var kind := "model"
	var accent := Color("#66dbff")

	func configure(new_kind: String, new_accent: Color) -> void:
		kind = new_kind
		accent = new_accent
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 8

	func _draw() -> void:
		match kind:
			"model":
				_draw_model()
			"exam":
				_draw_exam()
			"board":
				_draw_board()
			_:
				_draw_exam()

	func _draw_model() -> void:
		var body := Rect2(Vector2(size.x * 0.20, size.y * 0.22), Vector2(size.x * 0.60, size.y * 0.54))
		draw_rect(body, accent.lightened(0.25), true)
		_wobbly_rect(body, Color("#111111"), 5.0)
		draw_line(Vector2(size.x * 0.50, size.y * 0.22), Vector2(size.x * 0.50, size.y * 0.08), Color("#111111"), 4.0, true)
		draw_circle(Vector2(size.x * 0.50, size.y * 0.08), size.x * 0.05, Color("#ff5b5b"))
		draw_circle(Vector2(size.x * 0.39, size.y * 0.45), size.x * 0.035, Color("#111111"))
		draw_circle(Vector2(size.x * 0.61, size.y * 0.45), size.x * 0.035, Color("#111111"))
		draw_arc(Vector2(size.x * 0.50, size.y * 0.53), size.x * 0.16, 0.2, 2.9, 14, Color("#111111"), 3.0, true)
		for index in range(3):
			var y := size.y * (0.33 + float(index) * 0.15)
			draw_line(Vector2(size.x * 0.10, y), Vector2(size.x * 0.20, y), Color("#111111"), 4.0, true)
			draw_line(Vector2(size.x * 0.80, y), Vector2(size.x * 0.90, y), Color("#111111"), 4.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.27, size.y * 0.94), "BENCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#111111"))

	func _draw_exam() -> void:
		var back := Rect2(Vector2(size.x * 0.24, size.y * 0.16), Vector2(size.x * 0.54, size.y * 0.60))
		var front := Rect2(Vector2(size.x * 0.18, size.y * 0.25), Vector2(size.x * 0.58, size.y * 0.58))
		draw_rect(back, Color("#dff4ff"), true)
		_wobbly_rect(back, Color("#111111"), 3.0)
		draw_rect(front, Color("#fffdf8"), true)
		_wobbly_rect(front, Color("#111111"), 5.0)
		for index in range(3):
			var y := front.position.y + 18.0 + float(index) * 17.0
			draw_rect(Rect2(front.position + Vector2(10, y - front.position.y - 8), Vector2(10, 10)), Color("#ffef5f"), true)
			draw_line(Vector2(front.position.x + 28, y), Vector2(front.position.x + front.size.x - 10, y), accent, 4.0, true)

	func _draw_board() -> void:
		var board := Rect2(Vector2(size.x * 0.14, size.y * 0.18), Vector2(size.x * 0.72, size.y * 0.62))
		draw_rect(board, Color("#172032"), true)
		_wobbly_rect(board, Color("#111111"), 5.0)
		for index in range(3):
			var bar_height := 18.0 + float(index) * 12.0
			var x := board.position.x + 16.0 + float(index) * 24.0
			draw_rect(Rect2(Vector2(x, board.position.y + board.size.y - bar_height - 10.0), Vector2(16, bar_height)), [Color("#66dbff"), Color("#ffef5f"), Color("#56d364")][index], true)
		draw_line(board.position + Vector2(12, board.size.y - 8), board.position + Vector2(board.size.x - 12, board.size.y - 8), Color("#fffdf8"), 3.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(board.position.x + 18, board.position.y + 26), "SOTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fffdf8"))

	func _wobbly_rect(rect: Rect2, color: Color, width: float) -> void:
		var points := PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 1.0),
			rect.position + rect.size,
			rect.position + Vector2(1.0, rect.size.y),
			rect.position
		])
		draw_polyline(points, color, width, true)
		var offset_points := PackedVector2Array()
		var offsets := [
			Vector2(2, -1),
			Vector2(-1, 2),
			Vector2(-2, 1),
			Vector2(1, -2),
			Vector2(2, -1)
		]
		for index in range(points.size()):
			offset_points.append(points[index] + offsets[index])
		draw_polyline(offset_points, color, maxf(1.5, width - 2.0), true)

class BenchPointer:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 16

	func _draw() -> void:
		var head := PackedVector2Array([
			Vector2(size.x * 0.50, size.y * 0.08),
			Vector2(size.x * 0.88, size.y * 0.48),
			Vector2(size.x * 0.58, size.y * 0.48),
			Vector2(size.x * 0.58, size.y * 0.92),
			Vector2(size.x * 0.42, size.y * 0.92),
			Vector2(size.x * 0.42, size.y * 0.48),
			Vector2(size.x * 0.12, size.y * 0.48)
		])
		draw_colored_polygon(head, Color("#ffef5f"))
		head.append(head[0])
		draw_polyline(head, Color("#111111"), 5.0, true)
		draw_line(Vector2(size.x * 0.50, size.y * 0.18), Vector2(size.x * 0.50, size.y * 0.82), Color("#ffffff"), 3.0, true)

func _ready() -> void:
	configure(
		"GAME_BENCH_TITLE",
		"BENCH_INSTRUCTIONS",
		"GAME_BENCH_DESC",
		"res://assets/art/benchmark_arena_bg.png"
	)
	super._ready()
	_build_arena()

func start_minigame() -> void:
	super.start_minigame()
	hits = 0
	overfits = 0
	phase = 0.0
	run_button.disabled = false
	_refresh_ui("BENCH_FEEDBACK_READY")

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	phase += delta * 4.2
	var t := (sin(phase) + 1.0) * 0.5
	cursor.position.x = track.position.x + (track.size.x - cursor.size.x) * t

func _build_arena() -> void:
	var board := _sketch_panel(Vector2(52, 218), Vector2(1176, 400), Color("#fff7d6e6"), Color("#111111"), 5.0, true)
	board.z_index = 0

	_build_model_panel()
	_build_training_panel()
	_build_score_panel()

func _build_model_panel() -> void:
	var panel := _sketch_panel(Vector2(78, 238), Vector2(292, 348), Color("#f2fbffe8"), Color("#111111"), 4.0, false)
	panel.z_index = 1

	var title := _outlined_label(tr("BENCH_MODEL_A"), 30, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(102, 254)
	title.size = Vector2(244, 42)
	content_layer.add_child(title)

	var model_icon := BenchDoodleIcon.new()
	model_icon.position = Vector2(162, 306)
	model_icon.size = Vector2(124, 124)
	model_icon.configure("model", Color("#66dbff"))
	content_layer.add_child(model_icon)

	var note := _outlined_label(tr("BENCH_TRAINING_NOTE"), 18, Color("#1f5fbf"), HORIZONTAL_ALIGNMENT_CENTER)
	note.position = Vector2(104, 438)
	note.size = Vector2(240, 42)
	content_layer.add_child(note)

	var skill_title := _outlined_label(tr("BENCH_REAL_SKILL"), 19, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	skill_title.position = Vector2(104, 492)
	skill_title.size = Vector2(240, 30)
	content_layer.add_child(skill_title)

	_sketch_panel(Vector2(112, 528), Vector2(224, 28), Color("#172032"), Color("#111111"), 3.0, false)
	skill_fill = ColorRect.new()
	skill_fill.position = Vector2(120, 536)
	skill_fill.size = Vector2(12, 12)
	skill_fill.color = Color("#ff5b5b")
	skill_fill.z_index = 8
	content_layer.add_child(skill_fill)

	var zero := _outlined_label("0%", 18, Color("#ffef5f"), HORIZONTAL_ALIGNMENT_RIGHT)
	zero.position = Vector2(270, 525)
	zero.size = Vector2(56, 30)
	content_layer.add_child(zero)

func _build_training_panel() -> void:
	var panel := _sketch_panel(Vector2(404, 238), Vector2(472, 348), Color("#fdfcf2eb"), Color("#111111"), 4.0, false)
	panel.z_index = 1

	var title := _outlined_label(tr("BENCH_LEAK_TITLE"), 27, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(432, 254)
	title.size = Vector2(416, 40)
	content_layer.add_child(title)

	for index in range(3):
		_add_exam_card(Vector2(434 + index * 138, 306), "Q%d = %s" % [17 + index * 9, ["A", "C", "B"][index]])

	track = _sketch_panel(Vector2(450, 420), Vector2(380, 62), Color("#243142"), Color("#111111"), 4.0, false)
	track.z_index = 2

	var left_label := _outlined_label(tr("BENCH_REAL_WORLD"), 14, Color("#d7e6ff"), HORIZONTAL_ALIGNMENT_CENTER)
	left_label.position = Vector2(458, 438)
	left_label.size = Vector2(112, 26)
	content_layer.add_child(left_label)

	var right_label := _outlined_label(tr("BENCH_REAL_WORLD"), 14, Color("#d7e6ff"), HORIZONTAL_ALIGNMENT_CENTER)
	right_label.position = Vector2(708, 438)
	right_label.size = Vector2(112, 26)
	content_layer.add_child(right_label)

	green_zone = ColorRect.new()
	green_zone.position = Vector2(588, 425)
	green_zone.size = Vector2(104, 52)
	green_zone.color = Color("#56d364")
	green_zone.z_index = 5
	content_layer.add_child(green_zone)

	var zone_label := _outlined_label(tr("BENCH_ANSWER_KEY"), 14, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	zone_label.position = Vector2(588, 438)
	zone_label.size = Vector2(104, 24)
	content_layer.add_child(zone_label)

	cursor = BenchPointer.new()
	cursor.position = Vector2(450, 400)
	cursor.size = Vector2(54, 92)
	content_layer.add_child(cursor)

	run_button = make_button(tr("BENCH_RUN_BUTTON"), 30, Color("#ffef5f"))
	run_button.position = Vector2(492, 500)
	run_button.size = Vector2(296, 68)
	run_button.z_index = 10
	run_button.pressed.connect(_on_run_pressed)
	content_layer.add_child(run_button)

func _build_score_panel() -> void:
	var panel := _sketch_panel(Vector2(910, 238), Vector2(292, 348), Color("#f3f6ffea"), Color("#111111"), 4.0, false)
	panel.z_index = 1

	var title := _outlined_label(tr("BENCH_MODEL_B"), 28, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(936, 254)
	title.size = Vector2(240, 40)
	content_layer.add_child(title)

	var board_icon := BenchDoodleIcon.new()
	board_icon.position = Vector2(992, 306)
	board_icon.size = Vector2(128, 114)
	board_icon.configure("board", Color("#ffef5f"))
	content_layer.add_child(board_icon)

	score_label = _outlined_label("0 / %d" % TARGET_HITS, 35, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	score_label.position = Vector2(942, 426)
	score_label.size = Vector2(230, 48)
	content_layer.add_child(score_label)

	_sketch_panel(Vector2(946, 486), Vector2(220, 28), Color("#172032"), Color("#111111"), 3.0, false)
	bench_fill = ColorRect.new()
	bench_fill.position = Vector2(954, 494)
	bench_fill.size = Vector2(0, 12)
	bench_fill.color = Color("#56d364")
	bench_fill.z_index = 8
	content_layer.add_child(bench_fill)

	memory_pips.clear()
	for index in range(TARGET_HITS):
		var pip := ColorRect.new()
		pip.position = Vector2(964 + index * 38, 532)
		pip.size = Vector2(26, 18)
		pip.color = Color("#384456")
		pip.z_index = 8
		content_layer.add_child(pip)
		memory_pips.append(pip)

	feedback_label = _outlined_label("", 16, Color("#1f5fbf"), HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.position = Vector2(922, 552)
	feedback_label.size = Vector2(268, 28)
	content_layer.add_child(feedback_label)

func _add_exam_card(pos: Vector2, text: String) -> void:
	var card := _sketch_panel(pos, Vector2(112, 72), Color("#ffffff"), Color("#111111"), 3.0, false)
	card.z_index = 2
	var icon := BenchDoodleIcon.new()
	icon.position = pos + Vector2(4, -8)
	icon.size = Vector2(64, 62)
	icon.configure("exam", Color("#66dbff"))
	content_layer.add_child(icon)
	var label := _outlined_label(text, 17, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = pos + Vector2(10, 44)
	label.size = Vector2(92, 24)
	content_layer.add_child(label)

func _on_run_pressed() -> void:
	if not running:
		return

	var cursor_center := cursor.global_position.x + cursor.size.x * 0.5
	var zone_rect := green_zone.get_global_rect()
	if cursor_center >= zone_rect.position.x and cursor_center <= zone_rect.position.x + zone_rect.size.x:
		hits += 1
		score = hits
		_refresh_ui("BENCH_FEEDBACK_HIT")
		if hits >= TARGET_HITS:
			run_button.disabled = true
			await finish_with_result(true, "BENCH_SUCCESS", 0.45)
	else:
		overfits += 1
		_refresh_ui("BENCH_FEEDBACK_MISS")
		if overfits >= 3:
			run_button.disabled = true
			await finish_with_result(false, "BENCH_OVERFIT_FAIL", 0.45)

func _refresh_ui(feedback_key: String = "") -> void:
	set_status(tr("BENCH_STATUS") % [hits, TARGET_HITS, overfits])
	if score_label:
		score_label.text = "%d / %d" % [hits, TARGET_HITS]
	if bench_fill:
		bench_fill.size.x = 204.0 * float(hits) / float(TARGET_HITS)
	if skill_fill:
		skill_fill.size.x = 12.0
	for index in range(memory_pips.size()):
		memory_pips[index].color = Color("#56d364") if index < hits else Color("#384456")
	if feedback_label and feedback_key != "":
		feedback_label.text = tr(feedback_key)
		feedback_label.add_theme_color_override("font_color", Color("#1f5fbf") if feedback_key != "BENCH_FEEDBACK_MISS" else Color("#ff5b5b"))

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, border: Color, width: float, hatch: bool) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = 1
	panel.call("configure", fill, border, width, 1.4, hatch, Color("#ffffff18"))
	content_layer.add_child(panel)
	return panel

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.z_index = 8
	label.add_theme_color_override("font_outline_color", Color("#ffffff") if color != Color("#ffffff") else Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	var success := hits >= TARGET_HITS
	await finish_with_result(success, "BENCH_TIMEOUT_SUCCESS" if success else "BENCH_FAIL", 0.45)
