extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")

const TARGET_POSTS := 8
const MISTAKE_LIMIT := 3
const POSTS := [
	{"key": "THREAD_SAFE_BUG", "safe": true},
	{"key": "THREAD_SAFE_DOC", "safe": true},
	{"key": "THREAD_SAFE_TEST", "safe": true},
	{"key": "THREAD_SAFE_REVIEW", "safe": true},
	{"key": "THREAD_DOOM_TAKE", "safe": false},
	{"key": "THREAD_DOOM_BENCH", "safe": false},
	{"key": "THREAD_DOOM_CEO", "safe": false},
	{"key": "THREAD_DOOM_FLAME", "safe": false},
	{"key": "THREAD_DOOM_THREAD", "safe": false}
]

var queue: Array[int] = []
var current_post := -1
var handled := 0
var mistakes := 0
var focus := 100
var post_label: Label
var verdict_label: Label
var focus_bar: ProgressBar
var reply_button: Button
var mute_button: Button
var history: Array[Label] = []

func _ready() -> void:
	configure("GAME_THREAD_TITLE", "THREAD_INSTRUCTIONS", "GAME_THREAD_DESC", "res://assets/art/agent_task_swarm_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(POSTS.size()):
		queue.append(index)
	queue.shuffle()
	current_post = -1
	handled = 0
	mistakes = 0
	focus = 100
	score = 0
	focus_bar.value = focus
	verdict_label.text = tr("THREAD_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#151515"))
	_clear_history()
	_next_post()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_on_action_pressed("reply")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		_on_action_pressed("mute")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#eef3f8")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(176, 210), Vector2(620, 420), Color("#fffdf8"), false)
	_sketch_panel(Vector2(858, 210), Vector2(260, 420), Color("#fff7d6"), true)

	var title := _outlined_label(tr("THREAD_FEED_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(220, 232)
	title.size = Vector2(532, 52)
	content_layer.add_child(title)

	_sketch_panel(Vector2(230, 324), Vector2(512, 104), Color("#f8fbff"), false, Color("#1f5fbf"))
	post_label = _outlined_label("", 28, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	post_label.position = Vector2(256, 340)
	post_label.size = Vector2(460, 72)
	content_layer.add_child(post_label)

	mute_button = make_button(tr("THREAD_MUTE"), 29, Color("#ffe0dc"))
	mute_button.position = Vector2(228, 510)
	mute_button.size = Vector2(220, 72)
	mute_button.pressed.connect(_on_action_pressed.bind("mute"))
	content_layer.add_child(mute_button)

	reply_button = make_button(tr("THREAD_REPLY"), 29, Color("#dff8da"))
	reply_button.position = Vector2(522, 510)
	reply_button.size = Vector2(220, 72)
	reply_button.pressed.connect(_on_action_pressed.bind("reply"))
	content_layer.add_child(reply_button)

	var side_title := _outlined_label(tr("THREAD_FOCUS_TITLE"), 28, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(890, 234)
	side_title.size = Vector2(196, 42)
	content_layer.add_child(side_title)

	focus_bar = ProgressBar.new()
	focus_bar.position = Vector2(900, 306)
	focus_bar.size = Vector2(176, 30)
	focus_bar.min_value = 0
	focus_bar.max_value = 100
	focus_bar.show_percentage = false
	content_layer.add_child(focus_bar)

	verdict_label = _outlined_label("", 24, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(886, 358)
	verdict_label.size = Vector2(204, 58)
	content_layer.add_child(verdict_label)

	for index in range(4):
		var label := _outlined_label("", 18, Color("#3d3d3d"), HORIZONTAL_ALIGNMENT_CENTER)
		label.position = Vector2(886, 448 + index * 36)
		label.size = Vector2(204, 28)
		content_layer.add_child(label)
		history.append(label)

func _next_post() -> void:
	if handled >= TARGET_POSTS:
		await finish_with_result(true, "THREAD_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(POSTS.size()):
			queue.append(index)
		queue.shuffle()
	current_post = queue.pop_back()
	post_label.text = tr(POSTS[current_post]["key"])

func _on_action_pressed(action: String) -> void:
	if not running or current_post < 0:
		return
	var post: Dictionary = POSTS[current_post]
	var safe := bool(post["safe"])
	var correct := (action == "reply") == safe
	if correct:
		handled += 1
		score = handled
		focus = min(100, focus + 3)
		verdict_label.text = tr("THREAD_GOOD_REPLY") if safe else tr("THREAD_GOOD_MUTE")
		verdict_label.add_theme_color_override("font_color", Color("#11883a"))
		_push_history("THREAD_HISTORY_OK")
	else:
		mistakes += 1
		focus = max(0, focus - 24)
		verdict_label.text = tr("THREAD_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#d91e18"))
		_push_history("THREAD_HISTORY_BAD")
		_shake(post_label)
		if mistakes >= MISTAKE_LIMIT or focus <= 0:
			await finish_with_result(false, "THREAD_FAIL", 0.6)
			return
	focus_bar.value = focus
	_update_status()
	_next_post()

func _push_history(key: String) -> void:
	for index in range(history.size() - 1, 0, -1):
		history[index].text = history[index - 1].text
	history[0].text = tr(key)

func _clear_history() -> void:
	for label in history:
		label.text = ""

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.04)
	tween.tween_property(node, "position:x", original.x + 10, 0.04)
	tween.tween_property(node, "position", original, 0.05)

func _update_status() -> void:
	set_status(tr("THREAD_STATUS") % [handled, TARGET_POSTS, focus, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
	content_layer.add_child(panel)
	return panel

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(handled >= TARGET_POSTS, "THREAD_TIMEOUT_SUCCESS" if handled >= TARGET_POSTS else "THREAD_TIMEOUT_FAIL", 0.45)
