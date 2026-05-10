extends "res://scripts/minigames/base_minigame.gd"

const LIMIT_BAR_WIDTH := 340.0

var session_fill: ColorRect
var session_percent: Label
var session_hint: Label
var session_warning: Label
var session_used: Label
var models_fill: ColorRect
var models_percent: Label
var models_hint: Label
var models_warning: Label
var models_used: Label
var response_button: Button
var typed_message: Label
var sent_label: Label
var dario_speech: Label
var consumed := false

func _ready() -> void:
	configure(
		"GAME_CLAUDE_TITLE",
		"CLAUDE_INSTRUCTIONS",
		"GAME_CLAUDE_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	consumed = false
	score = 0
	_set_limit_state(0, false)
	session_hint.text = tr("CLAUDE_SESSION_HINT")
	models_hint.text = tr("CLAUDE_MODELS_HINT")
	typed_message.text = tr("CLAUDE_TYPED_HELLO")
	sent_label.visible = false
	dario_speech.text = tr("CLAUDE_DARIO_IDLE")
	response_button.disabled = false
	response_button.text = tr("CLAUDE_REPLY")
	set_status("")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#0f141b")
	add_child(bg)
	move_child(bg, 0)

	_build_usage_panel()
	_build_chat_panel()
	_build_dario_panel()

func _build_usage_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(34, 220)
	panel.size = Vector2(342, 314)
	panel.add_theme_stylebox_override("panel", make_style(Color("#151b22"), Color("#2f3b47"), 2, 8))
	content_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var title := _dark_label(tr("CLAUDE_PLAN_TITLE"), 25, Color("#fff1d4"), HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size = Vector2(305, 42)
	box.add_child(title)

	var session := _add_limit_row(box, tr("CLAUDE_SESSION_TITLE"), tr("CLAUDE_SESSION_HINT"), Color("#f23b3b"))
	session_fill = session["fill"]
	session_percent = session["percent"]
	session_hint = session["hint"]
	session_warning = session["warning"]
	session_used = session["used"]

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(305, 2)
	divider.color = Color("#33404c")
	box.add_child(divider)

	var models := _add_limit_row(box, tr("CLAUDE_ALL_MODELS"), tr("CLAUDE_MODELS_HINT"), Color("#ff8f24"))
	models_fill = models["fill"]
	models_percent = models["percent"]
	models_hint = models["hint"]
	models_warning = models["warning"]
	models_used = models["used"]

func _add_limit_row(parent: VBoxContainer, row_title: String, hint: String, fill_color: Color) -> Dictionary:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)
	parent.add_child(wrapper)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	wrapper.add_child(top)

	var title := _dark_label(row_title, 19, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size = Vector2(214, 28)
	top.add_child(title)

	var percent := _dark_label(tr("CLAUDE_LIMIT_JUMP") % [0, 100], 17, Color("#ffd166"), HORIZONTAL_ALIGNMENT_RIGHT)
	percent.custom_minimum_size = Vector2(112, 28)
	top.add_child(percent)

	var hint_label := _dark_label(hint, 14, Color("#d9d0bf"), HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.custom_minimum_size = Vector2(LIMIT_BAR_WIDTH, 24)
	wrapper.add_child(hint_label)

	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(LIMIT_BAR_WIDTH, 34)
	track.color = Color("#303841")
	wrapper.add_child(track)

	var fill := ColorRect.new()
	fill.position = Vector2(0, 0)
	fill.size = Vector2(2, 34)
	fill.color = fill_color
	track.add_child(fill)

	var warning := _dark_label("!", 26, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	warning.position = Vector2(LIMIT_BAR_WIDTH - 38.0, 0)
	warning.size = Vector2(34, 34)
	warning.add_theme_color_override("font_outline_color", Color("#111111"))
	warning.add_theme_constant_override("outline_size", 4)
	warning.visible = false
	track.add_child(warning)

	var used := _dark_label(tr("CLAUDE_USED") % 0, 18, fill_color, HORIZONTAL_ALIGNMENT_LEFT)
	used.custom_minimum_size = Vector2(LIMIT_BAR_WIDTH, 28)
	wrapper.add_child(used)

	return {"fill": fill, "percent": percent, "hint": hint_label, "warning": warning, "used": used}

func _build_chat_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(394, 220)
	panel.size = Vector2(514, 390)
	panel.add_theme_stylebox_override("panel", make_style(Color("#151b22"), Color("#2f3b47"), 2, 8))
	content_layer.add_child(panel)

	var logo := _dark_label("*", 58, Color("#ff794a"), HORIZONTAL_ALIGNMENT_CENTER)
	logo.position = Vector2(424, 244)
	logo.size = Vector2(60, 70)
	content_layer.add_child(logo)

	var title := _dark_label(tr("CLAUDE_CHAT_TITLE"), 56, Color("#f3e6ce"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(485, 246)
	title.size = Vector2(360, 70)
	content_layer.add_child(title)

	var bubble := PanelContainer.new()
	bubble.position = Vector2(420, 326)
	bubble.size = Vector2(434, 72)
	bubble.add_theme_stylebox_override("panel", make_style(Color("#303236"), Color("#55585c"), 2, 12))
	content_layer.add_child(bubble)

	var bubble_text := _dark_label(tr("CLAUDE_GREETING"), 20, Color("#f4ead8"), HORIZONTAL_ALIGNMENT_CENTER)
	bubble.add_child(bubble_text)

	var input_panel := PanelContainer.new()
	input_panel.position = Vector2(420, 416)
	input_panel.size = Vector2(454, 118)
	input_panel.add_theme_stylebox_override("panel", make_style(Color("#1d232a"), Color("#d9aa72"), 2, 10))
	content_layer.add_child(input_panel)

	typed_message = _dark_label(tr("CLAUDE_TYPED_HELLO"), 30, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT)
	typed_message.position = Vector2(442, 435)
	typed_message.size = Vector2(240, 50)
	content_layer.add_child(typed_message)

	response_button = make_button(tr("CLAUDE_REPLY"), 22, Color("#5b554c"))
	response_button.position = Vector2(723, 474)
	response_button.size = Vector2(128, 48)
	response_button.add_theme_color_override("font_color", Color("#ffffff"))
	response_button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	response_button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
	response_button.add_theme_color_override("font_outline_color", Color("#111111"))
	response_button.pressed.connect(_on_response_pressed)
	content_layer.add_child(response_button)

	sent_label = _dark_label(tr("CLAUDE_REPLY_SENT"), 15, Color("#b7b0a6"), HORIZONTAL_ALIGNMENT_RIGHT)
	sent_label.position = Vector2(735, 526)
	sent_label.size = Vector2(120, 24)
	sent_label.visible = false
	content_layer.add_child(sent_label)

func _build_dario_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(932, 220)
	panel.size = Vector2(292, 390)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff1d7"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(panel)

	var sprite := make_sprite("res://assets/sprites/dario_amodei.png", Vector2(258, 258))
	sprite.position = Vector2(948, 236)
	content_layer.add_child(sprite)

	dario_speech = make_label(tr("CLAUDE_DARIO_IDLE"), 27, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	dario_speech.position = Vector2(956, 508)
	dario_speech.size = Vector2(242, 72)
	dario_speech.add_theme_color_override("font_outline_color", Color("#ffffff"))
	dario_speech.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(dario_speech)

func _build_cost_banner() -> void:
	var banner := PanelContainer.new()
	banner.position = Vector2(34, 628)
	banner.size = Vector2(1190, 64)
	banner.add_theme_stylebox_override("panel", make_style(Color("#111820"), Color("#2f3b47"), 2, 8))
	content_layer.add_child(banner)

func _on_response_pressed() -> void:
	if not running or consumed:
		return

	consumed = true
	score = 1
	response_button.disabled = true
	sent_label.visible = true
	session_hint.text = tr("CLAUDE_SESSION_AFTER")
	models_hint.text = tr("CLAUDE_MODELS_AFTER")
	dario_speech.text = tr("CLAUDE_DARIO_LOCK")
	set_status("")

	var tween := create_tween()
	tween.tween_property(session_fill, "size:x", LIMIT_BAR_WIDTH, 0.3)
	tween.parallel().tween_property(models_fill, "size:x", LIMIT_BAR_WIDTH, 0.3)
	await tween.finished
	_set_limit_state(100, true)
	await _finish_without_overlay(true, 1.05)

func _finish_without_overlay(success: bool, delay: float) -> void:
	if not running:
		return

	running = false
	play_result_sound(success)
	await get_tree().create_timer(delay).timeout
	emit_signal("finished", success, score)

func _set_limit_state(percent: int, show_warning: bool) -> void:
	var fill_width := LIMIT_BAR_WIDTH if percent >= 100 else 2.0
	if session_fill:
		session_fill.size.x = fill_width
	if models_fill:
		models_fill.size.x = fill_width
	if session_percent:
		session_percent.text = tr("CLAUDE_LIMIT_JUMP") % [0, percent]
	if models_percent:
		models_percent.text = tr("CLAUDE_LIMIT_JUMP") % [0, percent]
	if session_used:
		session_used.text = tr("CLAUDE_USED") % percent
	if models_used:
		models_used.text = tr("CLAUDE_USED") % percent
	if session_warning:
		session_warning.visible = show_warning
	if models_warning:
		models_warning.visible = show_warning

func on_timeout() -> void:
	await finish_with_result(false, "CLAUDE_FAIL", 0.45)

func _dark_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label
