extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_DRAMA := 6
const MISTAKE_LIMIT := 3
const PROMPTS := [
	{"key": "GROK_RAGE_POLITE_EMAIL", "rage": false},
	{"key": "GROK_RAGE_SUMMARY", "rage": false},
	{"key": "GROK_RAGE_UNIT_TEST", "rage": false},
	{"key": "GROK_RAGE_CEO_FIGHT", "rage": true},
	{"key": "GROK_RAGE_BENCH_WAR", "rage": true},
	{"key": "GROK_RAGE_MODEL_DRAMA", "rage": true},
	{"key": "GROK_RAGE_OPEN_SOURCE_TAKE", "rage": true},
	{"key": "GROK_RAGE_THANKS", "rage": false}
]

var queue: Array[int] = []
var current_prompt := -1
var drama := 0
var handled := 0
var mistakes := 0
var prompt_label: Label
var verdict_label: Label
var meter_label: Label
var drama_bar: ProgressBar
var feed_button: Button
var mute_button: Button
var pips: Array[ColorRect] = []
var grok_icon: Control

func _ready() -> void:
	configure("GAME_GROK_RAGE_TITLE", "GROK_RAGE_INSTRUCTIONS", "GAME_GROK_RAGE_DESC", "res://assets/art/sycophancy_whack_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(PROMPTS.size()):
		queue.append(index)
	queue.shuffle()
	current_prompt = -1
	drama = 0
	handled = 0
	mistakes = 0
	score = 0
	drama_bar.value = 0
	verdict_label.text = tr("GROK_RAGE_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#fff1c6"))
	_set_grok_state(false)
	_set_buttons_enabled(true)
	_reset_pips()
	_next_prompt()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_on_choice_pressed("feed")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		get_viewport().set_input_as_handled()
		_on_choice_pressed("mute")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#241826")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(62, 220), Vector2(770, 390), Color("#fffdf8"), true)
	_sketch_panel(Vector2(878, 220), Vector2(330, 390), Color("#201620"), false, Color("#ff5b7e"))

	_icon("robot", Vector2(100, 242), Vector2(58, 58), Color("#91c9e8"))
	var title := _outlined_label(tr("GROK_RAGE_FEED_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(170, 242)
	title.size = Vector2(610, 54)
	content_layer.add_child(title)

	_sketch_panel(Vector2(128, 330), Vector2(638, 112), Color("#fff3f8"), false, Color("#d91e18"))
	prompt_label = _outlined_label("", 30, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.position = Vector2(152, 346)
	prompt_label.size = Vector2(590, 78)
	content_layer.add_child(prompt_label)

	mute_button = make_button(tr("GROK_RAGE_MUTE"), 29, Color("#e8f1ff"))
	mute_button.position = Vector2(128, 500)
	mute_button.size = Vector2(290, 76)
	mute_button.pressed.connect(_on_choice_pressed.bind("mute"))
	content_layer.add_child(mute_button)

	feed_button = make_button(tr("GROK_RAGE_FEED"), 29, Color("#ffd7df"))
	feed_button.position = Vector2(476, 500)
	feed_button.size = Vector2(290, 76)
	feed_button.pressed.connect(_on_choice_pressed.bind("feed"))
	content_layer.add_child(feed_button)

	var side_title := _outlined_label(tr("GROK_RAGE_DRAMA_TITLE"), 31, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(912, 240)
	side_title.size = Vector2(260, 44)
	content_layer.add_child(side_title)

	grok_icon = _icon("robot", Vector2(972, 300), Vector2(150, 132), Color("#49424f"))
	drama_bar = ProgressBar.new()
	drama_bar.position = Vector2(930, 466)
	drama_bar.size = Vector2(230, 30)
	drama_bar.min_value = 0
	drama_bar.max_value = TARGET_DRAMA
	drama_bar.show_percentage = false
	content_layer.add_child(drama_bar)

	meter_label = _outlined_label("", 22, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	meter_label.position = Vector2(916, 508)
	meter_label.size = Vector2(260, 34)
	content_layer.add_child(meter_label)

	verdict_label = _outlined_label("", 25, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(916, 552)
	verdict_label.size = Vector2(260, 46)
	content_layer.add_child(verdict_label)

	for index in range(MISTAKE_LIMIT):
		var pip := ColorRect.new()
		pip.position = Vector2(954 + index * 56, 438)
		pip.size = Vector2(38, 16)
		pip.color = Color("#3d3442")
		content_layer.add_child(pip)
		pips.append(pip)

func _next_prompt() -> void:
	if drama >= TARGET_DRAMA:
		await finish_with_result(true, "GROK_RAGE_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(PROMPTS.size()):
			queue.append(index)
		queue.shuffle()
	current_prompt = queue.pop_back()
	prompt_label.text = tr(PROMPTS[current_prompt]["key"])

func _on_choice_pressed(action: String) -> void:
	if not running or current_prompt < 0:
		return

	var data: Dictionary = PROMPTS[current_prompt]
	var is_rage := bool(data["rage"])
	var correct := (action == "feed") == is_rage
	handled += 1

	if correct and is_rage:
		drama += 1
		score = drama
		verdict_label.text = tr("GROK_RAGE_AMPLIFIED")
		verdict_label.add_theme_color_override("font_color", Color("#ff9fb0"))
		_set_grok_state(true)
	elif correct:
		verdict_label.text = tr("GROK_RAGE_MUTED")
		verdict_label.add_theme_color_override("font_color", Color("#91c9e8"))
		_set_grok_state(false)
	else:
		mistakes += 1
		drama = max(0, drama - 1)
		_mark_mistake()
		verdict_label.text = tr("GROK_RAGE_WRONG")
		verdict_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		_set_grok_state(false)
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "GROK_RAGE_FAIL", 0.65)
			return

	drama_bar.value = drama
	_update_status()
	_next_prompt()

func _set_grok_state(hyped: bool) -> void:
	if grok_icon:
		grok_icon.call("configure", "robot", Color("#ff5b7e") if hyped else Color("#49424f"), Color("#ffffff"))

func _mark_mistake() -> void:
	var index := int(clamp(mistakes - 1, 0, pips.size() - 1))
	if index >= 0 and index < pips.size():
		pips[index].color = Color("#ff5b5b")

func _reset_pips() -> void:
	for pip in pips:
		pip.color = Color("#3d3442")

func _set_buttons_enabled(enabled: bool) -> void:
	if feed_button:
		feed_button.disabled = not enabled
	if mute_button:
		mute_button.disabled = not enabled

func _update_status() -> void:
	meter_label.text = tr("GROK_RAGE_METER") % [drama, TARGET_DRAMA]
	set_status(tr("GROK_RAGE_STATUS") % [drama, TARGET_DRAMA, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.6, hatch, Color("#0000000c"))
	content_layer.add_child(panel)
	return panel

func _icon(name: String, pos: Vector2, icon_size: Vector2, color: Color) -> Control:
	var icon: Control = SketchIcon.new()
	icon.position = pos
	icon.size = icon_size
	icon.call("configure", name, color, Color("#ffffff"))
	content_layer.add_child(icon)
	return icon

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#111111") if color == Color("#ffffff") else Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	var success := drama >= TARGET_DRAMA
	await finish_with_result(success, "GROK_RAGE_TIMEOUT_SUCCESS" if success else "GROK_RAGE_TIMEOUT_FAIL", 0.45)
