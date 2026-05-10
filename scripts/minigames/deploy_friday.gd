extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_CHANGES := 6
const CHANGES := [
	{"key": "DEPLOY_FIX_TYPO", "safe": true},
	{"key": "DEPLOY_ADD_TEST", "safe": true},
	{"key": "DEPLOY_ROLLBACK_BUTTON", "safe": true},
	{"key": "DEPLOY_NO_TESTS", "safe": false},
	{"key": "DEPLOY_FRIDAY_PROD", "safe": false},
	{"key": "DEPLOY_SECRET_LOGS", "safe": false},
	{"key": "DEPLOY_REMOVE_AUTH", "safe": false},
	{"key": "DEPLOY_PATCH_COPY", "safe": true}
]

var queue: Array[int] = []
var current_change := -1
var shipped := 0
var mistakes := 0
var change_label: Label
var server_label: Label
var server_icon: Control
var deploy_button: Button
var block_button: Button

func _ready() -> void:
	configure("GAME_DEPLOY_TITLE", "DEPLOY_INSTRUCTIONS", "GAME_DEPLOY_DESC", "res://assets/art/deploy_friday_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(CHANGES.size()):
		queue.append(index)
	queue.shuffle()
	current_change = -1
	shipped = 0
	mistakes = 0
	score = 0
	_set_server("good", "DEPLOY_SERVER_IDLE", Color("#11883a"))
	deploy_button.disabled = false
	block_button.disabled = false
	_next_change()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_on_action_pressed("deploy")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		get_viewport().set_input_as_handled()
		_on_action_pressed("block")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fbf7eb")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(78, 208), Vector2(780, 416), Color("#fffdf8"), true)
	_sketch_panel(Vector2(900, 208), Vector2(300, 416), Color("#fff2e8"), false)

	_icon("robot", Vector2(114, 236), Vector2(58, 58), Color("#91c9e8"))
	var title := _outlined_label(tr("DEPLOY_CHAT_TITLE"), 36, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(180, 234)
	title.size = Vector2(620, 58)
	content_layer.add_child(title)

	_sketch_panel(Vector2(140, 328), Vector2(650, 104), Color("#eef7ff"), false, Color("#1f5fbf"))
	change_label = _outlined_label("", 32, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	change_label.position = Vector2(166, 346)
	change_label.size = Vector2(598, 64)
	content_layer.add_child(change_label)

	block_button = make_button(tr("DEPLOY_BLOCK"), 30, Color("#ffe0dc"))
	block_button.position = Vector2(140, 500)
	block_button.size = Vector2(295, 78)
	block_button.pressed.connect(_on_action_pressed.bind("block"))
	content_layer.add_child(block_button)

	deploy_button = make_button(tr("DEPLOY_SHIP"), 30, Color("#dff8da"))
	deploy_button.position = Vector2(495, 500)
	deploy_button.size = Vector2(295, 78)
	deploy_button.pressed.connect(_on_action_pressed.bind("deploy"))
	content_layer.add_child(deploy_button)

	var side_title := _outlined_label(tr("DEPLOY_SERVER_TITLE"), 32, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(920, 232)
	side_title.size = Vector2(260, 54)
	content_layer.add_child(side_title)

	server_icon = _icon("computer_good", Vector2(962, 310), Vector2(176, 136), Color("#dff8da"))
	server_label = _outlined_label("", 26, Color("#11883a"), HORIZONTAL_ALIGNMENT_CENTER)
	server_label.position = Vector2(934, 485)
	server_label.size = Vector2(236, 80)
	content_layer.add_child(server_label)

func _next_change() -> void:
	if shipped >= TARGET_CHANGES:
		finish_with_result(true, "DEPLOY_SUCCESS", 0.75)
		return
	if queue.is_empty():
		for index in range(CHANGES.size()):
			queue.append(index)
		queue.shuffle()
	current_change = queue.pop_back()
	change_label.text = tr(CHANGES[current_change]["key"])

func _on_action_pressed(action: String) -> void:
	if not running or current_change < 0:
		return
	var data: Dictionary = CHANGES[current_change]
	var safe := bool(data["safe"])
	if action == "deploy" and safe:
		shipped += 1
		score = shipped
		_set_server("good", "DEPLOY_SERVER_OK", Color("#11883a"))
	elif action == "block" and not safe:
		shipped += 1
		score = shipped
		_set_server("good", "DEPLOY_SERVER_BLOCKED", Color("#11883a"))
	elif action == "deploy" and not safe:
		_set_server("bad", "DEPLOY_SERVER_FIRE", Color("#d91e18"))
		await finish_with_result(false, "DEPLOY_FAIL_FIRE", 0.75)
		return
	else:
		mistakes += 1
		_set_server("bad", "DEPLOY_SERVER_WASTED", Color("#d91e18"))
	_next_change()
	_update_status()

func _set_server(icon_name: String, text_key: String, text_color: Color) -> void:
	if server_icon:
		server_icon.call("configure", "computer_bad" if icon_name == "bad" else "computer_good", Color("#444444") if icon_name == "bad" else Color("#dff8da"), Color("#ffffff"))
	if server_label:
		server_label.text = tr(text_key)
		server_label.add_theme_color_override("font_color", text_color)

func _update_status() -> void:
	set_status(tr("DEPLOY_STATUS") % [shipped, TARGET_CHANGES, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.6, hatch, Color("#0000000d"))
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
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(shipped >= TARGET_CHANGES, "DEPLOY_TIMEOUT_SUCCESS" if shipped >= TARGET_CHANGES else "DEPLOY_FAIL_TIMEOUT", 0.45)
