extends "res://scripts/minigames/base_minigame.gd"

const TARGET_HITS := 5

var track: Panel
var green_zone: ColorRect
var cursor: TextureRect
var run_button: Button
var hits := 0
var overfits := 0
var phase := 0.0

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
	set_status(tr("BENCH_STATUS") % [0, TARGET_HITS, 0])
	run_button.disabled = false

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	phase += delta * 4.2
	var t := (sin(phase) + 1.0) * 0.5
	cursor.position.x = track.position.x + (track.size.x - cursor.size.x) * t

func _build_arena() -> void:
	var board := PanelContainer.new()
	board.position = Vector2(160, 220)
	board.size = Vector2(960, 330)
	board.add_theme_stylebox_override("panel", make_style(Color("#f4f7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(board)

	var label_left := make_label(tr("BENCH_MODEL_A"), 38, Color("#3b4cc0"), HORIZONTAL_ALIGNMENT_CENTER)
	label_left.position = Vector2(210, 258)
	label_left.size = Vector2(240, 70)
	content_layer.add_child(label_left)

	var label_right := make_label(tr("BENCH_MODEL_B"), 38, Color("#b83535"), HORIZONTAL_ALIGNMENT_CENTER)
	label_right.position = Vector2(830, 258)
	label_right.size = Vector2(240, 70)
	content_layer.add_child(label_right)

	var leaderboard := make_sprite("res://assets/sprites/leaderboard.png", Vector2(180, 160))
	leaderboard.position = Vector2(550, 220)
	content_layer.add_child(leaderboard)

	track = Panel.new()
	track.position = Vector2(248, 360)
	track.size = Vector2(784, 70)
	track.add_theme_stylebox_override("panel", make_style(Color("#2b2b34"), Color("#111111"), 4, 4))
	content_layer.add_child(track)

	green_zone = ColorRect.new()
	green_zone.position = Vector2(520, 360)
	green_zone.size = Vector2(215, 70)
	green_zone.color = Color("#46d86f")
	content_layer.add_child(green_zone)

	cursor = make_sprite("res://assets/sprites/benchmark_cursor.png", Vector2(72, 96))
	cursor.position = Vector2(248, 347)
	content_layer.add_child(cursor)

	run_button = make_button(tr("BENCH_RUN_BUTTON"), 34, Color("#ff7bd5"))
	run_button.position = Vector2(440, 490)
	run_button.size = Vector2(400, 86)
	run_button.pressed.connect(_on_run_pressed)
	content_layer.add_child(run_button)

func _on_run_pressed() -> void:
	if not running:
		return

	var cursor_center := cursor.global_position.x + cursor.size.x * 0.5
	var zone_rect := green_zone.get_global_rect()
	if cursor_center >= zone_rect.position.x and cursor_center <= zone_rect.position.x + zone_rect.size.x:
		hits += 1
		score = hits
		set_status(tr("BENCH_STATUS") % [hits, TARGET_HITS, overfits])
		if hits >= TARGET_HITS:
			run_button.disabled = true
			await finish_with_result(true, "BENCH_SUCCESS", 0.45)
	else:
		overfits += 1
		set_status(tr("BENCH_STATUS") % [hits, TARGET_HITS, overfits])
		if overfits >= 3:
			run_button.disabled = true
			await finish_with_result(false, "BENCH_OVERFIT_FAIL", 0.45)

func on_timeout() -> void:
	var success := hits >= TARGET_HITS
	await finish_with_result(success, "BENCH_TIMEOUT_SUCCESS" if success else "BENCH_FAIL", 0.45)
