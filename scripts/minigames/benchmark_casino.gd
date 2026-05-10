extends "res://scripts/minigames/base_minigame.gd"

const TARGET_LOCKS := 4
const LOW_GOOD := 88.0
const HIGH_GOOD := 95.0

var current_score := 50.0
var roll_timer := 0.0
var locks := 0
var mistakes := 0
var score_label: Label
var verdict_label: Label
var lock_button: Button
var lock_bar: ProgressBar

func _ready() -> void:
	configure("GAME_CASINO_TITLE", "CASINO_INSTRUCTIONS", "GAME_CASINO_DESC", "")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_score = 50.0
	roll_timer = 0.0
	locks = 0
	mistakes = 0
	score = 0
	lock_bar.value = 0
	verdict_label.text = tr("CASINO_IDLE")
	lock_button.disabled = false
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return
	roll_timer -= delta
	if roll_timer <= 0.0:
		roll_timer = 0.08
		current_score = randf_range(68.0, 99.4)
		score_label.text = "%.1f" % current_score
		if current_score >= LOW_GOOD and current_score <= HIGH_GOOD:
			score_label.add_theme_color_override("font_color", Color("#5cff86"))
		elif current_score > HIGH_GOOD:
			score_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		else:
			score_label.add_theme_color_override("font_color", Color("#fff06a"))

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#24152f")
	add_child(bg)
	move_child(bg, 0)

	var machine := PanelContainer.new()
	machine.position = Vector2(330, 226)
	machine.size = Vector2(620, 384)
	machine.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 6, 8))
	content_layer.add_child(machine)

	var title := make_label(tr("CASINO_MACHINE"), 36, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(370, 250)
	title.size = Vector2(540, 46)
	content_layer.add_child(title)

	var reel := PanelContainer.new()
	reel.position = Vector2(440, 326)
	reel.size = Vector2(400, 120)
	reel.add_theme_stylebox_override("panel", make_style(Color("#111820"), Color("#56d364"), 4, 8))
	content_layer.add_child(reel)

	score_label = make_label("0.0", 72, Color("#fff06a"), HORIZONTAL_ALIGNMENT_CENTER)
	score_label.position = Vector2(460, 338)
	score_label.size = Vector2(360, 92)
	score_label.add_theme_color_override("font_outline_color", Color("#000000"))
	score_label.add_theme_constant_override("outline_size", 8)
	content_layer.add_child(score_label)

	lock_button = make_button(tr("CASINO_LOCK"), 30, Color("#ffef5f"))
	lock_button.position = Vector2(478, 476)
	lock_button.size = Vector2(324, 64)
	lock_button.pressed.connect(_on_lock_pressed)
	content_layer.add_child(lock_button)

	lock_bar = ProgressBar.new()
	lock_bar.position = Vector2(478, 552)
	lock_bar.size = Vector2(324, 30)
	lock_bar.min_value = 0
	lock_bar.max_value = TARGET_LOCKS
	lock_bar.show_percentage = false
	content_layer.add_child(lock_bar)

	verdict_label = make_label("", 28, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(250, 624)
	verdict_label.size = Vector2(780, 42)
	verdict_label.add_theme_color_override("font_outline_color", Color("#111111"))
	verdict_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(verdict_label)

func _on_lock_pressed() -> void:
	if not running:
		return
	if current_score >= LOW_GOOD and current_score <= HIGH_GOOD:
		locks += 1
		score = locks
		lock_bar.value = locks
		verdict_label.text = tr("CASINO_GOOD")
		if locks >= TARGET_LOCKS:
			await finish_with_result(true, "CASINO_SUCCESS", 0.7)
			return
	elif current_score > HIGH_GOOD:
		mistakes += 1
		verdict_label.text = tr("CASINO_OVERFIT")
	else:
		mistakes += 1
		verdict_label.text = tr("CASINO_WEAK")
	_update_status()

func _update_status() -> void:
	set_status(tr("CASINO_STATUS") % [locks, TARGET_LOCKS, mistakes])

func on_timeout() -> void:
	var success := locks >= TARGET_LOCKS
	await finish_with_result(success, "CASINO_TIMEOUT_SUCCESS" if success else "CASINO_FAIL", 0.45)
