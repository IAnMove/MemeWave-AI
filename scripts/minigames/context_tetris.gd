extends "res://scripts/minigames/base_minigame.gd"

const WINDOW_LIMIT := 100
const TARGET_SIGNAL := 62
const BLOCKS := [
	{"key": "CONTEXT_BLOCK_REPRO", "tokens": 18, "signal": 18, "color": "#bdfb7f"},
	{"key": "CONTEXT_BLOCK_LOGS", "tokens": 22, "signal": 22, "color": "#bdfb7f"},
	{"key": "CONTEXT_BLOCK_ERROR", "tokens": 16, "signal": 16, "color": "#bdfb7f"},
	{"key": "CONTEXT_BLOCK_TEST", "tokens": 20, "signal": 20, "color": "#bdfb7f"},
	{"key": "CONTEXT_BLOCK_TWEET", "tokens": 24, "signal": -8, "color": "#ff9fd6"},
	{"key": "CONTEXT_BLOCK_NODE_MODULES", "tokens": 52, "signal": -15, "color": "#ff7777"},
	{"key": "CONTEXT_BLOCK_OLD_CHAT", "tokens": 36, "signal": 2, "color": "#ffef5f"},
	{"key": "CONTEXT_BLOCK_VIBES", "tokens": 14, "signal": -4, "color": "#ffb25f"}
]

var block_buttons: Array[Button] = []
var placed_blocks: Array[Control] = []
var tokens_used := 0
var signal_score := 0
var mistakes := 0
var context_bar: ProgressBar
var signal_bar: ProgressBar
var context_label: Label
var signal_label: Label
var verdict_label: Label
var placed_area: Control

func _ready() -> void:
	configure(
		"GAME_CONTEXT_TITLE",
		"CONTEXT_INSTRUCTIONS",
		"GAME_CONTEXT_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	tokens_used = 0
	signal_score = 0
	mistakes = 0
	_clear_placed_blocks()
	_reset_buttons()
	_update_meters()
	_update_status()
	verdict_label.text = tr("CONTEXT_VERDICT_EMPTY")
	verdict_label.add_theme_color_override("font_color", Color("#fff1c6"))

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#13212b")
	add_child(bg)
	move_child(bg, 0)

	_build_blocks_panel()
	_build_context_panel()
	_build_model_panel()

func _build_blocks_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(42, 220)
	panel.size = Vector2(410, 398)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("CONTEXT_BLOCKS_TITLE"), 30, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(68, 238)
	title.size = Vector2(358, 42)
	content_layer.add_child(title)

	block_buttons.clear()
	for index in range(BLOCKS.size()):
		var block: Dictionary = BLOCKS[index]
		var col := index % 2
		var row := index / 2
		var button := make_button(_block_text(block), 17, Color(block["color"]))
		button.position = Vector2(66 + col * 186, 302 + row * 72)
		button.size = Vector2(166, 58)
		button.pressed.connect(_on_block_pressed.bind(index))
		content_layer.add_child(button)
		block_buttons.append(button)

func _build_context_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(488, 220)
	panel.size = Vector2(420, 398)
	panel.add_theme_stylebox_override("panel", make_style(Color("#eff7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("CONTEXT_WINDOW_TITLE"), 31, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(514, 238)
	title.size = Vector2(368, 42)
	content_layer.add_child(title)

	context_label = make_label("", 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
	context_label.position = Vector2(526, 294)
	context_label.size = Vector2(340, 26)
	content_layer.add_child(context_label)

	context_bar = ProgressBar.new()
	context_bar.position = Vector2(526, 326)
	context_bar.size = Vector2(340, 32)
	context_bar.min_value = 0
	context_bar.max_value = WINDOW_LIMIT
	context_bar.show_percentage = false
	content_layer.add_child(context_bar)

	signal_label = make_label("", 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
	signal_label.position = Vector2(526, 374)
	signal_label.size = Vector2(340, 26)
	content_layer.add_child(signal_label)

	signal_bar = ProgressBar.new()
	signal_bar.position = Vector2(526, 406)
	signal_bar.size = Vector2(340, 32)
	signal_bar.min_value = 0
	signal_bar.max_value = TARGET_SIGNAL
	signal_bar.show_percentage = false
	content_layer.add_child(signal_bar)

	placed_area = Control.new()
	placed_area.position = Vector2(526, 458)
	placed_area.size = Vector2(340, 100)
	content_layer.add_child(placed_area)

	verdict_label = make_label("", 23, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(512, 570)
	verdict_label.size = Vector2(372, 40)
	verdict_label.add_theme_color_override("font_outline_color", Color("#111111"))
	verdict_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(verdict_label)

func _build_model_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(944, 220)
	panel.size = Vector2(280, 398)
	panel.add_theme_stylebox_override("panel", make_style(Color("#1c2532"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var model := make_sprite("res://assets/sprites/hungry_model.png", Vector2(178, 160))
	model.position = Vector2(995, 260)
	content_layer.add_child(model)

	var title := make_label(tr("CONTEXT_MODEL_TITLE"), 29, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(972, 430)
	title.size = Vector2(224, 44)
	title.add_theme_color_override("font_outline_color", Color("#111111"))
	title.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(title)

	var hint := make_label(tr("CONTEXT_MODEL_HINT"), 21, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(974, 492)
	hint.size = Vector2(220, 74)
	hint.add_theme_color_override("font_outline_color", Color("#111111"))
	hint.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(hint)

func _on_block_pressed(index: int) -> void:
	if not running or index < 0 or index >= BLOCKS.size():
		return

	var block: Dictionary = BLOCKS[index]
	var button := block_buttons[index]
	button.disabled = true
	button.modulate = Color(0.55, 0.55, 0.55, 1.0)

	tokens_used += int(block["tokens"])
	signal_score += int(block["signal"])
	if int(block["signal"]) <= 0:
		mistakes += 1

	_add_placed_block(block)
	_update_meters()
	_update_status()

	if tokens_used > WINDOW_LIMIT:
		verdict_label.text = tr("CONTEXT_VERDICT_OVERFLOW")
		verdict_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		await finish_with_result(false, "CONTEXT_FAIL_OVERFLOW", 0.65)
		return

	if signal_score >= TARGET_SIGNAL:
		verdict_label.text = tr("CONTEXT_VERDICT_GOOD")
		verdict_label.add_theme_color_override("font_color", Color("#5cff86"))
		await finish_with_result(true, "CONTEXT_SUCCESS", 0.7)

func _add_placed_block(block: Dictionary) -> void:
	var index := placed_blocks.size()
	var chip := PanelContainer.new()
	chip.position = Vector2((index % 2) * 172, (index / 2) * 34)
	chip.size = Vector2(160, 28)
	chip.add_theme_stylebox_override("panel", make_style(Color(block["color"]), Color("#1d1d1d"), 3, 5))
	placed_area.add_child(chip)
	placed_blocks.append(chip)

	var label := make_label("%s tk" % int(block["tokens"]), 15, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	chip.add_child(label)

func _update_meters() -> void:
	if context_bar:
		context_bar.value = min(tokens_used, WINDOW_LIMIT)
	if signal_bar:
		signal_bar.value = clamp(signal_score, 0, TARGET_SIGNAL)
	if context_label:
		context_label.text = tr("CONTEXT_TOKENS") % [tokens_used, WINDOW_LIMIT]
	if signal_label:
		signal_label.text = tr("CONTEXT_SIGNAL") % [max(signal_score, 0), TARGET_SIGNAL]

func _update_status() -> void:
	set_status(tr("CONTEXT_STATUS") % [tokens_used, WINDOW_LIMIT, max(signal_score, 0), mistakes])

func _reset_buttons() -> void:
	for button in block_buttons:
		button.disabled = false
		button.modulate = Color.WHITE

func _clear_placed_blocks() -> void:
	for block in placed_blocks:
		if is_instance_valid(block):
			block.queue_free()
	placed_blocks.clear()

func _block_text(block: Dictionary) -> String:
	return "%s\n%d tk" % [tr(block["key"]), int(block["tokens"])]

func on_timeout() -> void:
	var success := signal_score >= TARGET_SIGNAL and tokens_used <= WINDOW_LIMIT
	await finish_with_result(success, "CONTEXT_TIMEOUT_SUCCESS" if success else "CONTEXT_FAIL", 0.45)
