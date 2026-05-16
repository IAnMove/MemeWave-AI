extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")

const TARGET_HITS := 5
const INK := Color("#141414")
const PAPER := Color("#fffdf3")
const NAVY := Color("#172033")
const BLUE := Color("#65cfff")
const YELLOW := Color("#ffef5f")
const GREEN := Color("#58d96b")
const RED := Color("#ff595e")

var track: Control
var green_zone: Control
var cursor: Control
var run_button: Button
var bench_fill: ColorRect
var skill_fill: ColorRect
var score_label: Label
var feedback_label: Label
var memory_pips: Array = []
var hits := 0
var overfits := 0
var phase := 0.0

class BenchDoodleIcon:
	extends Control

	var kind := "model"
	var accent := BLUE

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
		var body := Rect2(Vector2(size.x * 0.18, size.y * 0.23), Vector2(size.x * 0.64, size.y * 0.56))
		draw_rect(body.grow(5.0), Color("#00000018"), true)
		draw_rect(body, accent.lightened(0.34), true)
		_scribble_rect(body.grow(-4.0), accent.darkened(0.07), 7.0, 1.2)
		_wobbly_rect(body, INK, 5.0)
		var face := body.grow(-size.x * 0.09)
		face.size.y *= 0.70
		draw_rect(face, Color("#c8f5ff"), true)
		_wobbly_rect(face, INK, 2.0)
		draw_line(Vector2(size.x * 0.50, body.position.y), Vector2(size.x * 0.50, size.y * 0.08), INK, 4.0, true)
		draw_circle(Vector2(size.x * 0.50, size.y * 0.08), size.x * 0.055, RED)
		draw_circle(Vector2(size.x * 0.38, size.y * 0.47), size.x * 0.036, INK)
		draw_circle(Vector2(size.x * 0.62, size.y * 0.47), size.x * 0.036, INK)
		draw_arc(Vector2(size.x * 0.50, size.y * 0.55), size.x * 0.16, 0.2, 2.9, 14, INK, 3.0, true)
		draw_line(Vector2(size.x * 0.30, size.y * 0.31), Vector2(size.x * 0.70, size.y * 0.31), Color("#ffffff8e"), 3.0, true)
		for index in range(3):
			var y := size.y * (0.33 + float(index) * 0.15)
			draw_line(Vector2(size.x * 0.08, y), Vector2(size.x * 0.18, y), INK, 4.0, true)
			draw_line(Vector2(size.x * 0.82, y), Vector2(size.x * 0.92, y), INK, 4.0, true)
			draw_circle(Vector2(size.x * 0.08, y), size.x * 0.015, YELLOW if index == 1 else GREEN)
		var badge := Rect2(Vector2(size.x * 0.28, size.y * 0.80), Vector2(size.x * 0.44, size.y * 0.12))
		draw_rect(badge, YELLOW, true)
		_wobbly_rect(badge, INK, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.33, size.y * 0.90), "BENCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)

	func _draw_exam() -> void:
		var back := Rect2(Vector2(size.x * 0.26, size.y * 0.12), Vector2(size.x * 0.54, size.y * 0.62))
		var front := Rect2(Vector2(size.x * 0.15, size.y * 0.22), Vector2(size.x * 0.60, size.y * 0.62))
		draw_rect(back.grow(3.0), Color("#00000015"), true)
		draw_rect(back, Color("#dff4ff"), true)
		_scribble_rect(back.grow(-3.0), Color("#9edcff66"), 9.0, 1.0)
		_wobbly_rect(back, INK, 3.0)
		draw_rect(front, PAPER, true)
		_scribble_rect(front.grow(-4.0), Color("#ffe66a74"), 8.0, 1.0)
		_wobbly_rect(front, INK, 5.0)
		for index in range(3):
			var y := front.position.y + 18.0 + float(index) * 17.0
			draw_rect(Rect2(front.position + Vector2(10, y - front.position.y - 8), Vector2(11, 11)), YELLOW, true)
			draw_line(Vector2(front.position.x + 28, y), Vector2(front.position.x + front.size.x - 10, y), accent, 4.0, true)
		draw_line(Vector2(front.position.x + 45, front.position.y + 9), Vector2(front.position.x + 55, front.position.y + 20), RED, 3.0, true)
		draw_line(Vector2(front.position.x + 55, front.position.y + 9), Vector2(front.position.x + 45, front.position.y + 20), RED, 3.0, true)

	func _draw_board() -> void:
		var board := Rect2(Vector2(size.x * 0.11, size.y * 0.15), Vector2(size.x * 0.78, size.y * 0.66))
		draw_rect(board.grow(5.0), Color("#00000020"), true)
		draw_rect(board, NAVY, true)
		_wobbly_rect(board, INK, 5.0)
		for index in range(4):
			var y := board.position.y + 28.0 + float(index) * 16.0
			draw_line(Vector2(board.position.x + 12.0, y), Vector2(board.position.x + board.size.x - 12.0, y), Color("#ffffff21"), 1.5, true)
		for index in range(3):
			var bar_height := 20.0 + float(index) * 13.0
			var x := board.position.x + 18.0 + float(index) * 25.0
			var bar := Rect2(Vector2(x, board.position.y + board.size.y - bar_height - 11.0), Vector2(17, bar_height))
			draw_rect(bar, [BLUE, YELLOW, GREEN][index], true)
			_wobbly_rect(bar, INK, 1.8)
		draw_line(board.position + Vector2(12, board.size.y - 8), board.position + Vector2(board.size.x - 12, board.size.y - 8), PAPER, 3.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(board.position.x + 17, board.position.y + 25), "SOTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PAPER)
		draw_circle(Vector2(board.position.x + board.size.x - 19.0, board.position.y + 19.0), 6.0, GREEN)

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

	func _scribble_rect(rect: Rect2, color: Color, spacing: float, width: float) -> void:
		var start := int(rect.position.x - rect.size.y)
		var stop := int(rect.position.x + rect.size.x)
		for offset in range(start, stop, int(spacing)):
			draw_line(
				Vector2(float(offset), rect.position.y + rect.size.y),
				Vector2(float(offset) + rect.size.y, rect.position.y),
				color,
				width,
				true
			)

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
		var shadow := PackedVector2Array()
		for point in head:
			shadow.append(point + Vector2(4, 4))
		draw_colored_polygon(shadow, Color("#00000024"))
		draw_colored_polygon(head, YELLOW)
		var hatch := PackedVector2Array([
			Vector2(size.x * 0.34, size.y * 0.36),
			Vector2(size.x * 0.58, size.y * 0.18),
			Vector2(size.x * 0.45, size.y * 0.50),
			Vector2(size.x * 0.58, size.y * 0.74)
		])
		draw_polyline(hatch, Color("#ffffff9a"), 3.0, true)
		head.append(head[0])
		draw_polyline(head, INK, 5.0, true)
		draw_circle(Vector2(size.x * 0.50, size.y * 0.48), size.x * 0.085, RED)
		draw_circle(Vector2(size.x * 0.50, size.y * 0.48), size.x * 0.040, PAPER)

class BenchTrack:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 2

	func _draw() -> void:
		var outer := Rect2(Vector2(0, 0), size)
		var inner := outer.grow(-6.0)
		draw_rect(Rect2(outer.position + Vector2(4, 5), outer.size), Color("#0000001f"), true)
		draw_rect(outer, NAVY, true)
		_wobbly_rect(outer.grow(-2.0), INK, 4.0)
		draw_rect(Rect2(inner.position + Vector2(0, 7), Vector2(inner.size.x, inner.size.y - 14.0)), Color("#223049"), true)
		var left := Rect2(inner.position + Vector2(8, 13), Vector2(inner.size.x * 0.29, inner.size.y - 26.0))
		var right := Rect2(Vector2(inner.position.x + inner.size.x * 0.69, inner.position.y + 13), Vector2(inner.size.x * 0.25, inner.size.y - 26.0))
		draw_rect(left, Color("#0f1726"), true)
		draw_rect(right, Color("#0f1726"), true)
		for index in range(8):
			var x := inner.position.x + 18.0 + float(index) * ((inner.size.x - 36.0) / 7.0)
			draw_line(Vector2(x, inner.position.y + inner.size.y - 14.0), Vector2(x, inner.position.y + inner.size.y - 5.0), Color("#fffdf36f"), 2.0, true)

	func _wobbly_rect(rect: Rect2, color: Color, width: float) -> void:
		var points := PackedVector2Array([
			rect.position + Vector2(0, 1),
			rect.position + Vector2(rect.size.x, 0),
			rect.position + rect.size + Vector2(0, -1),
			rect.position + Vector2(1, rect.size.y),
			rect.position + Vector2(0, 1)
		])
		draw_polyline(points, color, width, true)

class BenchTargetZone:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 5

	func _draw() -> void:
		var rect := Rect2(Vector2(0, 0), size)
		draw_rect(rect, GREEN, true)
		for offset in range(-int(size.y), int(size.x), 10):
			draw_line(Vector2(float(offset), size.y), Vector2(float(offset) + size.y, 0), Color("#d8ffd080"), 1.6, true)
		_wobbly_rect(rect.grow(-2.0), INK, 2.0)
		draw_line(Vector2(8, 6), Vector2(size.x - 8, 6), Color("#ffffff95"), 3.0, true)

	func _wobbly_rect(rect: Rect2, color: Color, width: float) -> void:
		var points := PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 1),
			rect.position + rect.size,
			rect.position + Vector2(1, rect.size.y),
			rect.position
		])
		draw_polyline(points, color, width, true)

class BenchMemoryPip:
	extends Control

	var lit := false

	func set_lit(new_lit: bool) -> void:
		lit = new_lit
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 8

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var fill := GREEN if lit else Color("#384456")
		draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size), Color("#00000022"), true)
		draw_rect(rect, fill, true)
		_wobbly_rect(rect.grow(-1.0), INK, 2.0)
		if lit:
			draw_circle(Vector2(size.x * 0.50, size.y * 0.50), minf(size.x, size.y) * 0.18, YELLOW)
		else:
			draw_line(Vector2(size.x * 0.25, size.y * 0.50), Vector2(size.x * 0.75, size.y * 0.50), Color("#ffffff45"), 2.0, true)

	func _wobbly_rect(rect: Rect2, color: Color, width: float) -> void:
		var points := PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 1),
			rect.position + rect.size,
			rect.position + Vector2(1, rect.size.y),
			rect.position
		])
		draw_polyline(points, color, width, true)

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
	var board := _sketch_panel(Vector2(50, 214), Vector2(1180, 406), Color("#fff2c7d8"), INK, 5.0, true)
	board.z_index = 0

	_build_model_panel()
	_build_training_panel()
	_build_score_panel()

func _build_model_panel() -> void:
	var panel := _sketch_panel(Vector2(78, 238), Vector2(292, 348), Color("#eaffffe8"), INK, 4.0, false)
	panel.z_index = 1
	_add_tape(Vector2(174, 226), Vector2(100, 22), Color("#ffef5faa"))

	var title := _outlined_label(tr("BENCH_MODEL_A"), 30, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(102, 254)
	title.size = Vector2(244, 42)
	content_layer.add_child(title)

	var model_icon := BenchDoodleIcon.new()
	model_icon.position = Vector2(162, 306)
	model_icon.size = Vector2(124, 124)
	model_icon.configure("model", BLUE)
	content_layer.add_child(model_icon)

	var note := _outlined_label(tr("BENCH_TRAINING_NOTE"), 18, Color("#1f5fbf"), HORIZONTAL_ALIGNMENT_CENTER)
	note.position = Vector2(104, 438)
	note.size = Vector2(240, 42)
	content_layer.add_child(note)

	var skill_title := _outlined_label(tr("BENCH_REAL_SKILL"), 19, INK, HORIZONTAL_ALIGNMENT_CENTER)
	skill_title.position = Vector2(104, 492)
	skill_title.size = Vector2(240, 30)
	content_layer.add_child(skill_title)

	_sketch_panel(Vector2(112, 528), Vector2(224, 28), NAVY, INK, 3.0, false)
	skill_fill = ColorRect.new()
	skill_fill.position = Vector2(120, 536)
	skill_fill.size = Vector2(12, 12)
	skill_fill.color = RED
	skill_fill.z_index = 8
	content_layer.add_child(skill_fill)

	var zero := _outlined_label("0%", 18, YELLOW, HORIZONTAL_ALIGNMENT_RIGHT)
	zero.position = Vector2(270, 525)
	zero.size = Vector2(56, 30)
	content_layer.add_child(zero)

func _build_training_panel() -> void:
	var panel := _sketch_panel(Vector2(404, 238), Vector2(472, 348), Color("#fffdf0ec"), INK, 4.0, false)
	panel.z_index = 1
	_add_tape(Vector2(584, 226), Vector2(112, 22), Color("#65cfff99"))

	var title := _outlined_label(tr("BENCH_LEAK_TITLE"), 27, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(432, 254)
	title.size = Vector2(416, 40)
	content_layer.add_child(title)

	for index in range(3):
		_add_exam_card(Vector2(434 + index * 138, 306), "Q%d = %s" % [17 + index * 9, ["A", "C", "B"][index]])

	track = BenchTrack.new()
	track.position = Vector2(450, 420)
	track.size = Vector2(380, 62)
	content_layer.add_child(track)

	var left_label := _outlined_label(tr("BENCH_REAL_WORLD"), 14, Color("#d7e6ff"), HORIZONTAL_ALIGNMENT_CENTER)
	left_label.position = Vector2(458, 438)
	left_label.size = Vector2(112, 26)
	content_layer.add_child(left_label)

	var right_label := _outlined_label(tr("BENCH_REAL_WORLD"), 14, Color("#d7e6ff"), HORIZONTAL_ALIGNMENT_CENTER)
	right_label.position = Vector2(708, 438)
	right_label.size = Vector2(112, 26)
	content_layer.add_child(right_label)

	green_zone = BenchTargetZone.new()
	green_zone.position = Vector2(588, 425)
	green_zone.size = Vector2(104, 52)
	content_layer.add_child(green_zone)

	var zone_label := _outlined_label(tr("BENCH_ANSWER_KEY"), 14, INK, HORIZONTAL_ALIGNMENT_CENTER)
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
	var panel := _sketch_panel(Vector2(910, 238), Vector2(292, 348), Color("#f1f5ffea"), INK, 4.0, false)
	panel.z_index = 1
	_add_tape(Vector2(1006, 226), Vector2(100, 22), Color("#ff8a6faa"))

	var title := _outlined_label(tr("BENCH_MODEL_B"), 28, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(936, 254)
	title.size = Vector2(240, 40)
	content_layer.add_child(title)

	var board_icon := BenchDoodleIcon.new()
	board_icon.position = Vector2(992, 306)
	board_icon.size = Vector2(128, 114)
	board_icon.configure("board", YELLOW)
	content_layer.add_child(board_icon)

	score_label = _outlined_label("0 / %d" % TARGET_HITS, 35, INK, HORIZONTAL_ALIGNMENT_CENTER)
	score_label.position = Vector2(942, 426)
	score_label.size = Vector2(230, 48)
	content_layer.add_child(score_label)

	_sketch_panel(Vector2(946, 486), Vector2(220, 28), NAVY, INK, 3.0, false)
	bench_fill = ColorRect.new()
	bench_fill.position = Vector2(954, 494)
	bench_fill.size = Vector2(0, 12)
	bench_fill.color = GREEN
	bench_fill.z_index = 8
	content_layer.add_child(bench_fill)

	memory_pips.clear()
	for index in range(TARGET_HITS):
		var pip := BenchMemoryPip.new()
		pip.position = Vector2(960 + index * 39, 532)
		pip.size = Vector2(30, 20)
		content_layer.add_child(pip)
		memory_pips.append(pip)

	feedback_label = _outlined_label("", 16, Color("#1f5fbf"), HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.position = Vector2(922, 552)
	feedback_label.size = Vector2(268, 28)
	content_layer.add_child(feedback_label)

func _add_exam_card(pos: Vector2, text: String) -> void:
	var card := _sketch_panel(pos, Vector2(112, 72), PAPER, INK, 3.0, false)
	card.z_index = 2
	_add_tape(pos + Vector2(38, -9), Vector2(38, 12), Color("#ffef5f99"))
	var icon := BenchDoodleIcon.new()
	icon.position = pos + Vector2(4, -8)
	icon.size = Vector2(64, 62)
	icon.configure("exam", BLUE)
	content_layer.add_child(icon)
	var label := _outlined_label(text, 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
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
		if memory_pips[index].has_method("set_lit"):
			memory_pips[index].call("set_lit", index < hits)
	if feedback_label and feedback_key != "":
		feedback_label.text = tr(feedback_key)
		feedback_label.add_theme_color_override("font_color", Color("#1f5fbf") if feedback_key != "BENCH_FEEDBACK_MISS" else RED)

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, border: Color, width: float, hatch: bool) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = 1
	panel.call("configure", fill, border, width, 1.4, hatch, Color("#ffffff18"))
	content_layer.add_child(panel)
	return panel

func _add_tape(pos: Vector2, panel_size: Vector2, fill: Color) -> void:
	var tape := _sketch_panel(pos, panel_size, fill, Color("#11111144"), 1.5, true)
	tape.z_index = 7

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.z_index = 8
	label.add_theme_color_override("font_outline_color", Color("#ffffff") if color != Color("#ffffff") else Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	var success := hits >= TARGET_HITS
	await finish_with_result(success, "BENCH_TIMEOUT_SUCCESS" if success else "BENCH_FAIL", 0.45)
