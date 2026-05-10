extends "res://scripts/minigames/base_minigame.gd"

var scenario_key := ""
var winner_id := ""
var success_text_key := ""
var fail_text_key := ""
var claude_reason_key := ""
var codex_reason_key := ""
var choice_made := false
var claude_button: Button
var codex_button: Button
var result_label: Label
var winner_label: Label

func initialize_choice(
	title_key: String,
	instructions_key: String,
	description_key: String,
	new_scenario_key: String,
	new_winner_id: String,
	new_success_text_key: String,
	new_fail_text_key: String,
	new_claude_reason_key: String,
	new_codex_reason_key: String
) -> void:
	scenario_key = new_scenario_key
	winner_id = new_winner_id
	success_text_key = new_success_text_key
	fail_text_key = new_fail_text_key
	claude_reason_key = new_claude_reason_key
	codex_reason_key = new_codex_reason_key
	configure(title_key, instructions_key, description_key, "")

func start_minigame() -> void:
	super.start_minigame()
	choice_made = false
	score = 0
	result_label.visible = false
	winner_label.text = tr("CHOICE_WINNER_LABEL") + " " + _winner_name()
	_set_button_style(claude_button, Color("#ff9fd6"))
	_set_button_style(codex_button, Color("#66c6ff"))
	claude_button.disabled = false
	codex_button.disabled = false
	set_status(tr("CHOICE_STATUS"))

func build_choice_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#121a27")
	add_child(bg)
	move_child(bg, 0)

	_build_prompt_panel()
	_build_model_card(
		Vector2(86, 266),
		tr("CHOICE_CLAUDE_BUTTON"),
		tr(claude_reason_key),
		"res://assets/sprites/dario_amodei.png",
		Color("#ff9fd6"),
		"claude"
	)
	_build_model_card(
		Vector2(846, 266),
		tr("CHOICE_CODEX_BUTTON"),
		tr(codex_reason_key),
		"res://assets/sprites/sam_face.png",
		Color("#66c6ff"),
		"codex"
	)

	result_label = make_label("", 37, Color("#fff06a"), HORIZONTAL_ALIGNMENT_CENTER)
	result_label.position = Vector2(330, 574)
	result_label.size = Vector2(620, 58)
	result_label.add_theme_color_override("font_outline_color", Color("#111111"))
	result_label.add_theme_constant_override("outline_size", 7)
	result_label.visible = false
	content_layer.add_child(result_label)

	winner_label = make_label("", 22, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	winner_label.position = Vector2(380, 638)
	winner_label.size = Vector2(520, 38)
	winner_label.add_theme_color_override("font_outline_color", Color("#111111"))
	winner_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(winner_label)

func _build_prompt_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(356, 242)
	panel.size = Vector2(568, 300)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var prompt_title := make_label(tr("CHOICE_PROMPT_LABEL"), 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_title.position = Vector2(388, 268)
	prompt_title.size = Vector2(504, 42)
	content_layer.add_child(prompt_title)

	var scenario := make_label(tr(scenario_key), 38, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	scenario.position = Vector2(406, 326)
	scenario.size = Vector2(468, 120)
	scenario.add_theme_color_override("font_outline_color", Color("#ffffff"))
	scenario.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(scenario)

	var hint := make_label(tr("CHOICE_TAP_HINT"), 22, Color("#3d3d3d"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(412, 470)
	hint.size = Vector2(456, 42)
	content_layer.add_child(hint)

func _build_model_card(position: Vector2, model_name: String, reason: String, sprite_path: String, color: Color, model_id: String) -> void:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = Vector2(300, 312)
	panel.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var sprite := make_sprite(sprite_path, Vector2(180, 150))
	sprite.position = position + Vector2(60, 18)
	content_layer.add_child(sprite)

	var title := make_label(model_name, 29, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = position + Vector2(20, 164)
	title.size = Vector2(260, 42)
	content_layer.add_child(title)

	var reason_label := make_label(reason, 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	reason_label.position = position + Vector2(24, 208)
	reason_label.size = Vector2(252, 54)
	content_layer.add_child(reason_label)

	var button := make_button(tr("CHOICE_PICK"), 24, color)
	button.position = position + Vector2(48, 264)
	button.size = Vector2(204, 52)
	button.pressed.connect(_on_choice_pressed.bind(model_id))
	content_layer.add_child(button)

	if model_id == "claude":
		claude_button = button
	else:
		codex_button = button

func _on_choice_pressed(model_id: String) -> void:
	if not running or choice_made:
		return

	choice_made = true
	claude_button.disabled = true
	codex_button.disabled = true
	var success := model_id == winner_id
	score = 1 if success else 0
	result_label.visible = true
	result_label.text = tr("CHOICE_CORRECT") if success else tr("CHOICE_WRONG")
	result_label.add_theme_color_override("font_color", Color("#5cff86") if success else Color("#ff5b5b"))
	_highlight_result()
	await finish_with_result(success, success_text_key if success else fail_text_key, 0.75)

func _highlight_result() -> void:
	_set_button_style(claude_button, Color("#bdfb7f") if winner_id == "claude" else Color("#ff7777"))
	_set_button_style(codex_button, Color("#bdfb7f") if winner_id == "codex" else Color("#ff7777"))

func _set_button_style(button: Button, color: Color) -> void:
	if not button:
		return
	button.add_theme_stylebox_override("normal", make_style(color, Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("hover", make_style(color.lightened(0.15), Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("pressed", make_style(color.darkened(0.13), Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("disabled", make_style(color, Color("#1d1d1d"), 4, 8))

func _winner_name() -> String:
	return tr("CHOICE_CLAUDE_BUTTON") if winner_id == "claude" else tr("CHOICE_CODEX_BUTTON")

func on_timeout() -> void:
	await finish_with_result(false, "CHOICE_TIMEOUT", 0.45)
