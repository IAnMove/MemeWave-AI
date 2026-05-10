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
var agent_mood: Label
var prompt_panel: PanelContainer
var prompt_title: Label
var prompt_label: Label
var continue_button: Button
var countdown_label: Label
var message_bubbles: Array[PanelContainer] = []
var message_labels: Array[Label] = []
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
		prompt_label.text = tr("AGENT_REPLY_PLACEHOLDER")
	if countdown_label:
		countdown_label.visible = false
	if agent_mood:
		agent_mood.text = tr("AGENT_MOOD_WORKING")
	_reset_messages()
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

	_build_agent_panel()
	_build_task_log()
	_build_prompt_panel()

func _build_agent_panel() -> void:
	var workspace := PanelContainer.new()
	workspace.position = Vector2(46, 212)
	workspace.size = Vector2(1188, 410)
	workspace.add_theme_stylebox_override("panel", make_style(Color("#181818"), Color("#343434"), 3, 8))
	content_layer.add_child(workspace)

	var tab := PanelContainer.new()
	tab.position = Vector2(82, 226)
	tab.size = Vector2(176, 30)
	tab.add_theme_stylebox_override("panel", make_style(Color("#2d2d2d"), Color("#2d2d2d"), 2, 8))
	content_layer.add_child(tab)

	var tab_text := make_label("agent_focus.gd", 17, Color("#f4f4f4"), HORIZONTAL_ALIGNMENT_CENTER)
	tab_text.position = Vector2(94, 226)
	tab_text.size = Vector2(152, 28)
	content_layer.add_child(tab_text)

	var branch := make_label(tr("AGENT_BRANCH"), 16, Color("#9f9f9f"), HORIZONTAL_ALIGNMENT_RIGHT)
	branch.position = Vector2(976, 228)
	branch.size = Vector2(208, 28)
	content_layer.add_child(branch)

	var title := make_label(tr("AGENT_WORK_TITLE"), 26, Color("#f2f2f2"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(82, 270)
	title.size = Vector2(500, 38)
	content_layer.add_child(title)

	var message := PanelContainer.new()
	message.position = Vector2(82, 312)
	message.size = Vector2(1098, 112)
	message.add_theme_stylebox_override("panel", make_style(Color("#242424"), Color("#333333"), 2, 8))
	content_layer.add_child(message)

	var agent := make_sprite("res://assets/sprites/hungry_model.png", Vector2(98, 92))
	agent.position = Vector2(108, 322)
	content_layer.add_child(agent)

	var role := make_label("Codex", 18, Color("#bdbdbd"), HORIZONTAL_ALIGNMENT_LEFT)
	role.position = Vector2(230, 326)
	role.size = Vector2(120, 28)
	content_layer.add_child(role)

	agent_mood = make_label("", 24, Color("#f2f2f2"), HORIZONTAL_ALIGNMENT_LEFT)
	agent_mood.position = Vector2(230, 356)
	agent_mood.size = Vector2(760, 54)
	agent_mood.add_theme_color_override("font_outline_color", Color("#111111"))
	agent_mood.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(agent_mood)

	cursor = ColorRect.new()
	cursor.position = Vector2(1138, 388)
	cursor.size = Vector2(18, 5)
	cursor.color = Color("#ff8a3d")
	content_layer.add_child(cursor)

func _build_task_log() -> void:
	message_bubbles.clear()
	message_labels.clear()

	var chat_panel := PanelContainer.new()
	chat_panel.position = Vector2(82, 436)
	chat_panel.size = Vector2(1098, 112)
	chat_panel.add_theme_stylebox_override("panel", make_style(Color("#222222"), Color("#383838"), 2, 8))
	content_layer.add_child(chat_panel)

	for index in range(WORK_STEPS.size()):
		var bubble := PanelContainer.new()
		bubble.size = Vector2(820, 22)
		bubble.visible = false
		bubble.add_theme_stylebox_override("panel", make_style(Color("#2c2c2c"), Color("#333333"), 1, 8))
		content_layer.add_child(bubble)
		message_bubbles.append(bubble)

		var label := make_label("", 16, Color("#d8d8d8"), HORIZONTAL_ALIGNMENT_LEFT)
		label.visible = false
		label.add_theme_color_override("font_outline_color", Color("#111111"))
		label.add_theme_constant_override("outline_size", 2)
		content_layer.add_child(label)
		message_labels.append(label)

func _build_prompt_panel() -> void:
	prompt_panel = PanelContainer.new()
	prompt_panel.position = Vector2(82, 558)
	prompt_panel.size = Vector2(1098, 50)
	prompt_panel.visible = false
	prompt_panel.add_theme_stylebox_override("panel", make_style(Color("#2a2a2a"), Color("#3d3d3d"), 2, 10))
	content_layer.add_child(prompt_panel)

	prompt_title = make_label(tr("AGENT_NEXT_TASK_TITLE"), 16, Color("#a8a8a8"), HORIZONTAL_ALIGNMENT_LEFT)
	prompt_title.position = Vector2(106, 562)
	prompt_title.size = Vector2(160, 22)
	prompt_title.visible = false
	content_layer.add_child(prompt_title)

	prompt_label = make_label(tr("AGENT_REPLY_PLACEHOLDER"), 20, Color("#8f8f8f"), HORIZONTAL_ALIGNMENT_LEFT)
	prompt_label.position = Vector2(106, 584)
	prompt_label.size = Vector2(500, 24)
	prompt_label.visible = false
	content_layer.add_child(prompt_label)

	countdown_label = make_label("", 18, Color("#ff8a3d"), HORIZONTAL_ALIGNMENT_RIGHT)
	countdown_label.position = Vector2(748, 576)
	countdown_label.size = Vector2(110, 26)
	countdown_label.add_theme_color_override("font_outline_color", Color("#111111"))
	countdown_label.add_theme_constant_override("outline_size", 3)
	countdown_label.visible = false
	content_layer.add_child(countdown_label)

	continue_button = make_button(tr("AGENT_CONTINUE_BUTTON"), 20, Color("#bdfb7f"))
	continue_button.position = Vector2(888, 568)
	continue_button.size = Vector2(270, 34)
	continue_button.disabled = true
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	content_layer.add_child(continue_button)

func _update_work_progress() -> void:
	var work_duration := ROUND_SECONDS - PROMPT_SECONDS_LEFT
	var elapsed := ROUND_SECONDS - time_left
	var work_ratio := clampf(elapsed / work_duration, 0.0, 1.0)
	task_progress = work_ratio * 88.0
	var step_index: int = min(WORK_STEPS.size() - 2, int(floor(work_ratio * float(WORK_STEPS.size() - 1))))
	if step_index != current_step_index:
		current_step_index = step_index
		agent_mood.text = tr("AGENT_MOOD_WORKING")
		_refresh_messages()

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
		prompt_label.text = tr("AGENT_REPLY_PLACEHOLDER")
	if countdown_label:
		countdown_label.visible = true
	_refresh_messages()
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

func _reset_messages() -> void:
	current_step_index = -1
	_refresh_messages()

func _refresh_messages() -> void:
	var shown_indices: Array[int] = []
	for index in range(message_labels.size()):
		if index <= current_step_index:
			shown_indices.append(index)
		else:
			message_bubbles[index].visible = false
			message_labels[index].visible = false

	var bottom_y := 516.0
	var gap := 24.0
	for display_index in range(shown_indices.size()):
		var message_index := shown_indices[display_index]
		var y := bottom_y - float(shown_indices.size() - 1 - display_index) * gap
		var bubble := message_bubbles[message_index]
		var label := message_labels[message_index]
		bubble.position = Vector2(106, y)
		bubble.visible = true
		label.position = Vector2(122, y - 1)
		label.size = Vector2(790, 22)
		label.visible = true
		if prompt_shown and message_index == WORK_STEPS.size() - 1:
			bubble.add_theme_stylebox_override("panel", make_style(Color("#35292d"), Color("#4d3036"), 1, 8))
			label.text = "Codex: " + tr("AGENT_PROMPT")
			label.add_theme_color_override("font_color", Color("#ff8a3d"))
		else:
			bubble.add_theme_stylebox_override("panel", make_style(Color("#2c2c2c"), Color("#333333"), 1, 8))
			label.text = "Codex: " + tr(WORK_STEPS[message_index])
			label.add_theme_color_override("font_color", Color("#e9e9e9"))

func _update_meters() -> void:
	pass

func _update_status() -> void:
	set_status("")

func on_timeout() -> void:
	if accepted:
		return
	if agent_mood:
		agent_mood.text = tr("AGENT_MOOD_IDLE")
	await finish_with_result(false, "AGENT_FAIL", 0.45)
