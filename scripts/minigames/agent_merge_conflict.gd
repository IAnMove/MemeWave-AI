extends "res://scripts/minigames/base_minigame.gd"

const TARGET_RESOLVED := 6
const CONFLICTS := [
	{
		"task_key": "MERGE_TASK_TESTS",
		"left_key": "MERGE_LEFT_KEEP_TEST",
		"right_key": "MERGE_RIGHT_DELETE_TEST",
		"correct": "left"
	},
	{
		"task_key": "MERGE_TASK_AUTH",
		"left_key": "MERGE_LEFT_SKIP_AUTH",
		"right_key": "MERGE_RIGHT_CHECK_AUTH",
		"correct": "right"
	},
	{
		"task_key": "MERGE_TASK_CSS",
		"left_key": "MERGE_LEFT_CENTER_DIV",
		"right_key": "MERGE_RIGHT_REWRITE_UI",
		"correct": "left"
	},
	{
		"task_key": "MERGE_TASK_RATE",
		"left_key": "MERGE_LEFT_BACKOFF",
		"right_key": "MERGE_RIGHT_SLEEP",
		"correct": "left"
	},
	{
		"task_key": "MERGE_TASK_CONFIG",
		"left_key": "MERGE_LEFT_ENV",
		"right_key": "MERGE_RIGHT_HARDCODE",
		"correct": "left"
	},
	{
		"task_key": "MERGE_TASK_LOGS",
		"left_key": "MERGE_LEFT_PRINT",
		"right_key": "MERGE_RIGHT_STRUCTURED",
		"correct": "right"
	},
	{
		"task_key": "MERGE_TASK_PROMPT",
		"left_key": "MERGE_LEFT_SYSTEM",
		"right_key": "MERGE_RIGHT_USER",
		"correct": "right"
	}
]

var current_conflict := -1
var resolved := 0
var mistakes := 0
var task_label: Label
var left_button: Button
var right_button: Button
var ci_label: Label
var conflict_counter: Label

func _ready() -> void:
	configure(
		"GAME_MERGE_TITLE",
		"MERGE_INSTRUCTIONS",
		"GAME_MERGE_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_conflict = -1
	resolved = 0
	mistakes = 0
	score = 0
	left_button.disabled = false
	right_button.disabled = false
	ci_label.text = tr("MERGE_CI_IDLE")
	ci_label.add_theme_color_override("font_color", Color("#fff1c6"))
	_spawn_conflict()
	_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#111827")
	add_child(bg)
	move_child(bg, 0)

	_build_conflict_panel()
	_build_side_panel()

func _build_conflict_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(70, 218)
	panel.size = Vector2(820, 406)
	panel.add_theme_stylebox_override("panel", make_style(Color("#1b2533"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var file_label := make_label("app/agent_output.gd", 24, Color("#9ee2ff"), HORIZONTAL_ALIGNMENT_LEFT)
	file_label.position = Vector2(102, 236)
	file_label.size = Vector2(360, 32)
	content_layer.add_child(file_label)

	conflict_counter = make_label("", 22, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_RIGHT)
	conflict_counter.position = Vector2(512, 236)
	conflict_counter.size = Vector2(330, 32)
	content_layer.add_child(conflict_counter)

	var marker_a := make_label("<<<<<<< AGENT A", 25, Color("#ff9fd6"), HORIZONTAL_ALIGNMENT_LEFT)
	marker_a.position = Vector2(112, 284)
	marker_a.size = Vector2(720, 30)
	content_layer.add_child(marker_a)

	left_button = _make_code_button(Vector2(112, 320), Color("#fff0f7"))
	left_button.pressed.connect(_on_choice_pressed.bind("left"))
	content_layer.add_child(left_button)

	var marker_mid := make_label("=======", 25, Color("#fff06a"), HORIZONTAL_ALIGNMENT_LEFT)
	marker_mid.position = Vector2(112, 418)
	marker_mid.size = Vector2(720, 30)
	content_layer.add_child(marker_mid)

	right_button = _make_code_button(Vector2(112, 454), Color("#eff7ff"))
	right_button.pressed.connect(_on_choice_pressed.bind("right"))
	content_layer.add_child(right_button)

	var marker_b := make_label(">>>>>>> AGENT B", 25, Color("#66c6ff"), HORIZONTAL_ALIGNMENT_LEFT)
	marker_b.position = Vector2(112, 552)
	marker_b.size = Vector2(720, 30)
	content_layer.add_child(marker_b)

func _build_side_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(930, 218)
	panel.size = Vector2(270, 406)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("MERGE_REVIEW_TITLE"), 31, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(952, 242)
	title.size = Vector2(226, 46)
	content_layer.add_child(title)

	task_label = make_label("", 26, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	task_label.position = Vector2(958, 316)
	task_label.size = Vector2(214, 112)
	task_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	task_label.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(task_label)

	var ci_title := make_label(tr("MERGE_CI_TITLE"), 25, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	ci_title.position = Vector2(962, 462)
	ci_title.size = Vector2(206, 36)
	content_layer.add_child(ci_title)

	ci_label = make_label("", 25, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	ci_label.position = Vector2(956, 512)
	ci_label.size = Vector2(214, 66)
	ci_label.add_theme_color_override("font_outline_color", Color("#111111"))
	ci_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(ci_label)

func _make_code_button(position: Vector2, fill: Color) -> Button:
	var button := make_button("", 22, fill)
	button.position = position
	button.size = Vector2(720, 82)
	button.add_theme_color_override("font_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button

func _spawn_conflict() -> void:
	var next := randi_range(0, CONFLICTS.size() - 1)
	if CONFLICTS.size() > 1:
		while next == current_conflict:
			next = randi_range(0, CONFLICTS.size() - 1)
	current_conflict = next

	var conflict: Dictionary = CONFLICTS[current_conflict]
	task_label.text = tr(conflict["task_key"])
	left_button.text = "  " + tr(conflict["left_key"])
	right_button.text = "  " + tr(conflict["right_key"])
	conflict_counter.text = tr("MERGE_COUNTER") % [resolved, TARGET_RESOLVED]
	_set_button_colors(Color("#fff0f7"), Color("#eff7ff"))

func _on_choice_pressed(choice: String) -> void:
	if not running or current_conflict < 0:
		return

	var conflict: Dictionary = CONFLICTS[current_conflict]
	if choice == String(conflict["correct"]):
		resolved += 1
		score = resolved
		ci_label.text = tr("MERGE_CI_GREEN")
		ci_label.add_theme_color_override("font_color", Color("#5cff86"))
		_flash_choice(choice, true)
		if resolved >= TARGET_RESOLVED:
			await finish_with_result(true, "MERGE_SUCCESS", 0.75)
			return
		_spawn_conflict()
	else:
		mistakes += 1
		ci_label.text = tr("MERGE_CI_RED")
		ci_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		_flash_choice(choice, false)

	_update_status()

func _flash_choice(choice: String, success: bool) -> void:
	var good := Color("#bdfb7f")
	var bad := Color("#ff7777")
	if choice == "left":
		_set_button_colors(good if success else bad, Color("#eff7ff"))
	else:
		_set_button_colors(Color("#fff0f7"), good if success else bad)

func _set_button_colors(left_color: Color, right_color: Color) -> void:
	_set_single_button_color(left_button, left_color)
	_set_single_button_color(right_button, right_color)

func _set_single_button_color(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("normal", make_style(color, Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("hover", make_style(color.lightened(0.14), Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("pressed", make_style(color.darkened(0.12), Color("#1d1d1d"), 4, 8))

func _update_status() -> void:
	if conflict_counter:
		conflict_counter.text = tr("MERGE_COUNTER") % [resolved, TARGET_RESOLVED]
	set_status(tr("MERGE_STATUS") % [resolved, TARGET_RESOLVED, mistakes])

func on_timeout() -> void:
	var success := resolved >= TARGET_RESOLVED
	await finish_with_result(success, "MERGE_TIMEOUT_SUCCESS" if success else "MERGE_FAIL", 0.45)
