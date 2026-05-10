extends "res://scripts/minigames/base_minigame.gd"

const TARGET_PROGRESS := 100.0
const PROMPT_SECONDS_LEFT := 5.0
const WORK_STEPS := [
	"AGENT_STEP_REFACTOR",
	"AGENT_STEP_EDIT_FILE",
	"AGENT_STEP_TESTS",
	"AGENT_STEP_COMMIT",
	"AGENT_STEP_NEXT_TASK"
]

var task_progress := 0.0
var prompt_shown := false
var accepted := false
var current_step_index := -1
var progress_bar: ProgressBar
var agent_mood: Label
var prompt_panel: PanelContainer
var prompt_title: Label
var prompt_label: Label
var continue_button: Button
var countdown_label: Label
var task_log_labels: Array[Label] = []
var cursor: ColorRect
var cursor_timer := 0.0

func _ready() -> void:
	configure(
		"GAME_AGENT_TITLE",
		"AGENT_INSTRUCTIONS",
		"GAME_AGENT_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	task_progress = 0.0
	prompt_shown = false
	accepted = false
	current_step_index = -1
	cursor_timer = 0.0
	score = 0
	if prompt_panel:
		prompt_panel.visible = false
	if prompt_title:
		prompt_title.visible = false
	if continue_button:
		continue_button.disabled = true
		continue_button.visible = false
		continue_button.text = tr("AGENT_CONTINUE_BUTTON")
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = tr("AGENT_PROMPT")
	if countdown_label:
		countdown_label.visible = false
	if agent_mood:
		agent_mood.text = tr("AGENT_MOOD_WORKING")
	_reset_log()
	_update_meters()
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	cursor_timer += delta
	if cursor:
		cursor.visible = int(cursor_timer * 3.0) % 2 == 0

	if not prompt_shown and time_left <= PROMPT_SECONDS_LEFT:
		_show_continue_prompt()

	if prompt_shown:
		task_progress = max(task_progress, 90.0)
		_update_prompt_countdown()
	else:
		_update_work_progress()

	_update_meters()
	_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#101926")
	add_child(bg)
	move_child(bg, 0)

	_build_agent_panel()
	_build_task_log()
	_build_prompt_panel()

func _build_agent_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(354, 224)
	panel.size = Vector2(572, 392)
	panel.add_theme_stylebox_override("panel", make_style(Color("#f2f7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("AGENT_WORK_TITLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(390, 238)
	title.size = Vector2(500, 48)
	content_layer.add_child(title)

	var agent := make_sprite("res://assets/sprites/hungry_model.png", Vector2(170, 150))
	agent.position = Vector2(555, 306)
	content_layer.add_child(agent)

	agent_mood = make_label("", 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	agent_mood.position = Vector2(406, 464)
	agent_mood.size = Vector2(468, 45)
	agent_mood.add_theme_color_override("font_outline_color", Color("#ffffff"))
	agent_mood.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(agent_mood)

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(424, 532)
	progress_bar.size = Vector2(432, 34)
	progress_bar.min_value = 0
	progress_bar.max_value = TARGET_PROGRESS
	progress_bar.show_percentage = false
	content_layer.add_child(progress_bar)

	var progress_label := make_label(tr("AGENT_PROGRESS_LABEL"), 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	progress_label.position = Vector2(424, 566)
	progress_label.size = Vector2(432, 28)
	content_layer.add_child(progress_label)

func _build_task_log() -> void:
	var log_panel := PanelContainer.new()
	log_panel.position = Vector2(58, 224)
	log_panel.size = Vector2(260, 392)
	log_panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(log_panel)

	var title := make_label(tr("AGENT_LOG_TITLE"), 29, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(80, 244)
	title.size = Vector2(216, 42)
	content_layer.add_child(title)

	for index in range(WORK_STEPS.size()):
		var label := make_label("", 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(86, 306 + index * 50)
		label.size = Vector2(196, 42)
		label.add_theme_color_override("font_outline_color", Color("#ffffff"))
		label.add_theme_constant_override("outline_size", 2)
		content_layer.add_child(label)
		task_log_labels.append(label)

	cursor = ColorRect.new()
	cursor.position = Vector2(86, 560)
	cursor.size = Vector2(52, 7)
	cursor.color = Color("#1d1d1d")
	content_layer.add_child(cursor)

func _build_prompt_panel() -> void:
	prompt_panel = PanelContainer.new()
	prompt_panel.position = Vector2(966, 224)
	prompt_panel.size = Vector2(252, 392)
	prompt_panel.visible = false
	prompt_panel.add_theme_stylebox_override("panel", make_style(Color("#fff0f7"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(prompt_panel)

	prompt_title = make_label(tr("AGENT_NEXT_TASK_TITLE"), 30, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_title.position = Vector2(990, 248)
	prompt_title.size = Vector2(204, 45)
	prompt_title.visible = false
	content_layer.add_child(prompt_title)

	prompt_label = make_label(tr("AGENT_PROMPT"), 23, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.position = Vector2(994, 322)
	prompt_label.size = Vector2(196, 86)
	prompt_label.visible = false
	content_layer.add_child(prompt_label)

	countdown_label = make_label("", 24, Color("#bf2030"), HORIZONTAL_ALIGNMENT_CENTER)
	countdown_label.position = Vector2(994, 426)
	countdown_label.size = Vector2(196, 42)
	countdown_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	countdown_label.add_theme_constant_override("outline_size", 3)
	countdown_label.visible = false
	content_layer.add_child(countdown_label)

	continue_button = make_button(tr("AGENT_CONTINUE_BUTTON"), 25, Color("#bdfb7f"))
	continue_button.position = Vector2(1002, 506)
	continue_button.size = Vector2(180, 64)
	continue_button.disabled = true
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	content_layer.add_child(continue_button)

func _update_work_progress() -> void:
	var work_duration := ROUND_SECONDS - PROMPT_SECONDS_LEFT
	var elapsed := ROUND_SECONDS - time_left
	var work_ratio := clampf(elapsed / work_duration, 0.0, 1.0)
	task_progress = work_ratio * 88.0
	var step_index: int = min(WORK_STEPS.size() - 1, int(floor(work_ratio * WORK_STEPS.size())))
	if step_index != current_step_index:
		current_step_index = step_index
		agent_mood.text = tr(WORK_STEPS[current_step_index])
		_refresh_log()

func _show_continue_prompt() -> void:
	prompt_shown = true
	current_step_index = WORK_STEPS.size() - 1
	task_progress = 90.0
	agent_mood.text = tr("AGENT_MOOD_WAITING")
	if prompt_panel:
		prompt_panel.visible = true
	if prompt_title:
		prompt_title.visible = true
	if continue_button:
		continue_button.visible = true
		continue_button.disabled = false
	if prompt_label:
		prompt_label.visible = true
		prompt_label.text = tr("AGENT_PROMPT")
	if countdown_label:
		countdown_label.visible = true
	_refresh_log()
	_update_prompt_countdown()

func _on_continue_pressed() -> void:
	if not running or not prompt_shown or accepted:
		return

	accepted = true
	score = 1
	task_progress = TARGET_PROGRESS
	if continue_button:
		continue_button.disabled = true
		continue_button.text = tr("AGENT_CONFIRMED")
	if agent_mood:
		agent_mood.text = tr("AGENT_MOOD_CONFIRMED")
	play_action_sound("collect")
	_update_meters()
	_update_status()
	await finish_with_result(true, "AGENT_SUCCESS", 0.45)

func _update_prompt_countdown() -> void:
	if countdown_label:
		countdown_label.text = tr("AGENT_COUNTDOWN") % [int(ceil(time_left))]

func _reset_log() -> void:
	current_step_index = -1
	_refresh_log()

func _refresh_log() -> void:
	for index in range(task_log_labels.size()):
		var label: Label = task_log_labels[index]
		var text: String = tr(WORK_STEPS[index])
		if prompt_shown and index == WORK_STEPS.size() - 1:
			label.text = "> " + text
			label.add_theme_color_override("font_color", Color("#bf2030"))
		elif index < current_step_index:
			label.text = "OK " + text
			label.add_theme_color_override("font_color", Color("#176c39"))
		elif index == current_step_index:
			label.text = "> " + text
			label.add_theme_color_override("font_color", Color("#1d1d1d"))
		else:
			label.text = "... " + text
			label.add_theme_color_override("font_color", Color("#6b6b6b"))

func _update_meters() -> void:
	if progress_bar:
		progress_bar.value = task_progress

func _update_status() -> void:
	if prompt_shown:
		set_status(tr("AGENT_STATUS_WAITING") % [int(ceil(time_left))])
		return
	var seconds_to_prompt: int = max(0, int(ceil(time_left - PROMPT_SECONDS_LEFT)))
	set_status(tr("AGENT_STATUS_WORKING") % [int(task_progress), seconds_to_prompt])

func on_timeout() -> void:
	if accepted:
		return
	if agent_mood:
		agent_mood.text = tr("AGENT_MOOD_IDLE")
	await finish_with_result(false, "AGENT_FAIL", 0.45)
