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
	bg.color = Color("#121212")
	add_child(bg)
	move_child(bg, 0)

	_build_sidebar()
	_build_agent_panel()
	_build_task_log()
	_build_prompt_panel()

func _build_sidebar() -> void:
	var sidebar := PanelContainer.new()
	sidebar.position = Vector2(44, 212)
	sidebar.size = Vector2(256, 410)
	sidebar.add_theme_stylebox_override("panel", make_style(Color("#222222"), Color("#3a3a3a"), 3, 8))
	content_layer.add_child(sidebar)

	var tools := make_label("Codex", 25, Color("#f1f1f1"), HORIZONTAL_ALIGNMENT_LEFT)
	tools.position = Vector2(66, 230)
	tools.size = Vector2(200, 34)
	content_layer.add_child(tools)

	var section := make_label(tr("AGENT_PROJECTS"), 18, Color("#8f8f8f"), HORIZONTAL_ALIGNMENT_LEFT)
	section.position = Vector2(66, 288)
	section.size = Vector2(190, 28)
	content_layer.add_child(section)

	var selected := PanelContainer.new()
	selected.position = Vector2(62, 322)
	selected.size = Vector2(214, 42)
	selected.add_theme_stylebox_override("panel", make_style(Color("#343434"), Color("#343434"), 2, 8))
	content_layer.add_child(selected)

	var selected_text := make_label("wario-wave-ai", 21, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT)
	selected_text.position = Vector2(82, 326)
	selected_text.size = Vector2(164, 34)
	content_layer.add_child(selected_text)

	for index in range(4):
		var line := make_label(tr("AGENT_THREAD_%d" % (index + 1)), 17, Color("#c7c7c7"), HORIZONTAL_ALIGNMENT_LEFT)
		line.position = Vector2(82, 384 + index * 42)
		line.size = Vector2(180, 30)
		content_layer.add_child(line)

	var footer := PanelContainer.new()
	footer.position = Vector2(66, 570)
	footer.size = Vector2(196, 34)
	footer.add_theme_stylebox_override("panel", make_style(Color("#2b2b2b"), Color("#505050"), 2, 8))
	content_layer.add_child(footer)

	var footer_text := make_label("5.5  dev", 17, Color("#bdbdbd"), HORIZONTAL_ALIGNMENT_CENTER)
	footer_text.position = Vector2(76, 573)
	footer_text.size = Vector2(176, 28)
	content_layer.add_child(footer_text)

func _build_agent_panel() -> void:
	var workspace := PanelContainer.new()
	workspace.position = Vector2(326, 212)
	workspace.size = Vector2(900, 410)
	workspace.add_theme_stylebox_override("panel", make_style(Color("#181818"), Color("#343434"), 3, 8))
	content_layer.add_child(workspace)

	var tab := PanelContainer.new()
	tab.position = Vector2(356, 226)
	tab.size = Vector2(176, 30)
	tab.add_theme_stylebox_override("panel", make_style(Color("#2d2d2d"), Color("#2d2d2d"), 2, 8))
	content_layer.add_child(tab)

	var tab_text := make_label("agent_focus.gd", 17, Color("#f4f4f4"), HORIZONTAL_ALIGNMENT_CENTER)
	tab_text.position = Vector2(368, 226)
	tab_text.size = Vector2(152, 28)
	content_layer.add_child(tab_text)

	var branch := make_label(tr("AGENT_BRANCH"), 16, Color("#9f9f9f"), HORIZONTAL_ALIGNMENT_RIGHT)
	branch.position = Vector2(982, 228)
	branch.size = Vector2(208, 28)
	content_layer.add_child(branch)

	var title := make_label(tr("AGENT_WORK_TITLE"), 26, Color("#f2f2f2"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(358, 270)
	title.size = Vector2(500, 38)
	content_layer.add_child(title)

	var message := PanelContainer.new()
	message.position = Vector2(356, 312)
	message.size = Vector2(836, 112)
	message.add_theme_stylebox_override("panel", make_style(Color("#242424"), Color("#333333"), 2, 8))
	content_layer.add_child(message)

	var agent := make_sprite("res://assets/sprites/hungry_model.png", Vector2(98, 92))
	agent.position = Vector2(382, 322)
	content_layer.add_child(agent)

	var role := make_label("Codex", 18, Color("#bdbdbd"), HORIZONTAL_ALIGNMENT_LEFT)
	role.position = Vector2(504, 326)
	role.size = Vector2(120, 28)
	content_layer.add_child(role)

	agent_mood = make_label("", 24, Color("#f2f2f2"), HORIZONTAL_ALIGNMENT_LEFT)
	agent_mood.position = Vector2(504, 356)
	agent_mood.size = Vector2(630, 42)
	agent_mood.add_theme_color_override("font_outline_color", Color("#111111"))
	agent_mood.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(agent_mood)

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(506, 398)
	progress_bar.size = Vector2(500, 16)
	progress_bar.min_value = 0
	progress_bar.max_value = TARGET_PROGRESS
	progress_bar.show_percentage = false
	content_layer.add_child(progress_bar)

	var progress_label := make_label(tr("AGENT_PROGRESS_LABEL"), 17, Color("#a8a8a8"), HORIZONTAL_ALIGNMENT_LEFT)
	progress_label.position = Vector2(1018, 391)
	progress_label.size = Vector2(150, 26)
	content_layer.add_child(progress_label)

func _build_task_log() -> void:
	task_log_labels.clear()

	var changes := PanelContainer.new()
	changes.position = Vector2(356, 436)
	changes.size = Vector2(836, 112)
	changes.add_theme_stylebox_override("panel", make_style(Color("#222222"), Color("#383838"), 2, 8))
	content_layer.add_child(changes)

	var title := make_label(tr("AGENT_LOG_TITLE"), 21, Color("#f2f2f2"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(378, 448)
	title.size = Vector2(260, 30)
	content_layer.add_child(title)

	var diff_stats := make_label("+42  -3", 19, Color("#35d68a"), HORIZONTAL_ALIGNMENT_RIGHT)
	diff_stats.position = Vector2(1040, 448)
	diff_stats.size = Vector2(124, 30)
	content_layer.add_child(diff_stats)

	for index in range(WORK_STEPS.size()):
		var label := make_label("", 16, Color("#d8d8d8"), HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(378 + (index % 2) * 390, 482 + int(index / 2) * 22)
		label.size = Vector2(350, 22)
		label.add_theme_color_override("font_outline_color", Color("#111111"))
		label.add_theme_constant_override("outline_size", 2)
		content_layer.add_child(label)
		task_log_labels.append(label)

	cursor = ColorRect.new()
	cursor.position = Vector2(1138, 388)
	cursor.size = Vector2(18, 5)
	cursor.color = Color("#ff8a3d")
	content_layer.add_child(cursor)

func _build_prompt_panel() -> void:
	prompt_panel = PanelContainer.new()
	prompt_panel.position = Vector2(356, 558)
	prompt_panel.size = Vector2(836, 50)
	prompt_panel.visible = false
	prompt_panel.add_theme_stylebox_override("panel", make_style(Color("#2a2a2a"), Color("#3d3d3d"), 2, 10))
	content_layer.add_child(prompt_panel)

	prompt_title = make_label(tr("AGENT_NEXT_TASK_TITLE"), 16, Color("#a8a8a8"), HORIZONTAL_ALIGNMENT_LEFT)
	prompt_title.position = Vector2(376, 562)
	prompt_title.size = Vector2(160, 22)
	prompt_title.visible = false
	content_layer.add_child(prompt_title)

	prompt_label = make_label(tr("AGENT_PROMPT"), 20, Color("#f4f4f4"), HORIZONTAL_ALIGNMENT_LEFT)
	prompt_label.position = Vector2(376, 584)
	prompt_label.size = Vector2(430, 24)
	prompt_label.visible = false
	content_layer.add_child(prompt_label)

	countdown_label = make_label("", 18, Color("#ff8a3d"), HORIZONTAL_ALIGNMENT_RIGHT)
	countdown_label.position = Vector2(792, 576)
	countdown_label.size = Vector2(110, 26)
	countdown_label.add_theme_color_override("font_outline_color", Color("#111111"))
	countdown_label.add_theme_constant_override("outline_size", 3)
	countdown_label.visible = false
	content_layer.add_child(countdown_label)

	continue_button = make_button(tr("AGENT_CONTINUE_BUTTON"), 20, Color("#bdfb7f"))
	continue_button.position = Vector2(928, 568)
	continue_button.size = Vector2(238, 34)
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
