extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_TASKS := 8
const TASKS := [
	{"task": "SWARM_TASK_UI_HERO", "file": "SWARM_FILE_UI"},
	{"task": "SWARM_TASK_API_AUTH", "file": "SWARM_FILE_API"},
	{"task": "SWARM_TASK_UI_BUTTON", "file": "SWARM_FILE_UI"},
	{"task": "SWARM_TASK_DB_MIGRATION", "file": "SWARM_FILE_DB"},
	{"task": "SWARM_TASK_API_RETRY", "file": "SWARM_FILE_API"},
	{"task": "SWARM_TASK_DOCS", "file": "SWARM_FILE_DOCS"},
	{"task": "SWARM_TASK_DB_INDEX", "file": "SWARM_FILE_DB"},
	{"task": "SWARM_TASK_TESTS", "file": "SWARM_FILE_TESTS"},
	{"task": "SWARM_TASK_DOCS_TYPO", "file": "SWARM_FILE_DOCS"},
	{"task": "SWARM_TASK_INPUT", "file": "SWARM_FILE_INPUT"}
]

var current_index := 0
var handled := 0
var mistakes := 0
var active_files: Array[String] = []
var task_label: Label
var file_label: Label
var board_label: Label
var agent_buttons: Array[Button] = []
var queue_button: Button
var file_tags: Array[Label] = []
var active_steps: Array[int] = []

func _ready() -> void:
	configure("GAME_SWARM_TITLE", "SWARM_INSTRUCTIONS", "GAME_SWARM_DESC", "res://assets/art/agent_task_swarm_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_index = 0
	handled = 0
	mistakes = 0
	score = 0
	active_files.clear()
	active_steps.clear()
	_set_buttons_enabled(true)
	board_label.text = tr("SWARM_BOARD_IDLE")
	board_label.add_theme_color_override("font_color", Color("#151515"))
	_update_file_tags()
	_show_task()
	_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#f4f6ff")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(76, 210), Vector2(760, 410), Color("#fffdf8"), true)
	_sketch_panel(Vector2(876, 210), Vector2(330, 410), Color("#fff7d6"), false)

	_icon("robot", Vector2(112, 236), Vector2(56, 56), Color("#91c9e8"))
	var title := _outlined_label(tr("SWARM_ROUTER_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(178, 232)
	title.size = Vector2(610, 58)
	content_layer.add_child(title)

	_sketch_panel(Vector2(132, 316), Vector2(650, 118), Color("#eef7ff"), false, Color("#1f5fbf"))
	task_label = _outlined_label("", 31, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	task_label.position = Vector2(154, 326)
	task_label.size = Vector2(606, 56)
	content_layer.add_child(task_label)

	file_label = _outlined_label("", 24, Color("#1f5fbf"), HORIZONTAL_ALIGNMENT_CENTER)
	file_label.position = Vector2(180, 384)
	file_label.size = Vector2(554, 34)
	content_layer.add_child(file_label)

	var positions := [Vector2(126, 492), Vector2(342, 492), Vector2(558, 492)]
	for index in range(3):
		var button := make_button(tr("SWARM_AGENT") % (index + 1), 24, Color("#dff8da"))
		button.position = positions[index]
		button.size = Vector2(176, 70)
		button.pressed.connect(_on_agent_pressed.bind(index))
		content_layer.add_child(button)
		agent_buttons.append(button)

	queue_button = make_button(tr("SWARM_QUEUE"), 24, Color("#ffe0dc"))
	queue_button.position = Vector2(330, 575)
	queue_button.size = Vector2(248, 58)
	queue_button.pressed.connect(_on_queue_pressed)
	content_layer.add_child(queue_button)

	var board_title := _outlined_label(tr("SWARM_BOARD_TITLE"), 31, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	board_title.position = Vector2(904, 232)
	board_title.size = Vector2(270, 52)
	content_layer.add_child(board_title)

	for index in range(6):
		var tag := _outlined_label("", 19, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
		tag.position = Vector2(920, 308 + index * 38)
		tag.size = Vector2(242, 30)
		content_layer.add_child(tag)
		file_tags.append(tag)

	board_label = _outlined_label("", 26, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	board_label.position = Vector2(908, 548)
	board_label.size = Vector2(256, 48)
	content_layer.add_child(board_label)

func _show_task() -> void:
	if handled >= TARGET_TASKS or current_index >= TASKS.size():
		finish_with_result(true, "SWARM_SUCCESS", 0.75)
		return
	var data: Dictionary = TASKS[current_index]
	task_label.text = tr(data["task"])
	file_label.text = tr("SWARM_FILE_LABEL") % tr(data["file"])

func _on_agent_pressed(agent_index: int) -> void:
	if not running:
		return
	var file_key := String(TASKS[current_index]["file"])
	if active_files.has(file_key):
		mistakes += 1
		board_label.text = tr("SWARM_CONFLICT")
		board_label.add_theme_color_override("font_color", Color("#d91e18"))
		if mistakes >= 3:
			await finish_with_result(false, "SWARM_FAIL_CONFLICT", 0.75)
			return
	else:
		active_files.append(file_key)
		active_steps.append(2)
		if active_files.size() > 3:
			active_files.pop_front()
			active_steps.pop_front()
		handled += 1
		score = handled
		board_label.text = tr("SWARM_ASSIGNED") % (agent_index + 1)
		board_label.add_theme_color_override("font_color", Color("#11883a"))
		_update_file_tags()
		_advance_task()
		return
	_advance_task()

func _on_queue_pressed() -> void:
	if not running:
		return
	var file_key := String(TASKS[current_index]["file"])
	if active_files.has(file_key):
		handled += 1
		score = handled
		board_label.text = tr("SWARM_QUEUED")
		board_label.add_theme_color_override("font_color", Color("#11883a"))
	else:
		mistakes += 1
		board_label.text = tr("SWARM_WASTED")
		board_label.add_theme_color_override("font_color", Color("#d91e18"))
	_advance_task()

func _advance_task() -> void:
	_tick_active_files()
	current_index += 1
	_update_status()
	_show_task()

func _tick_active_files() -> void:
	for index in range(active_steps.size() - 1, -1, -1):
		active_steps[index] -= 1
		if active_steps[index] <= 0:
			active_steps.remove_at(index)
			active_files.remove_at(index)
	_update_file_tags()

func _update_file_tags() -> void:
	for index in range(file_tags.size()):
		var label := file_tags[index]
		if index < active_files.size():
			label.text = tr(active_files[index])
			label.add_theme_color_override("font_color", Color("#1f5fbf"))
		else:
			label.text = "-"
			label.add_theme_color_override("font_color", Color("#a0a0a0"))

func _set_buttons_enabled(enabled: bool) -> void:
	for button in agent_buttons:
		button.disabled = not enabled
	if queue_button:
		queue_button.disabled = not enabled

func _update_status() -> void:
	set_status(tr("SWARM_STATUS") % [handled, TARGET_TASKS, mistakes])

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
	await finish_with_result(handled >= TARGET_TASKS, "SWARM_TIMEOUT_SUCCESS" if handled >= TARGET_TASKS else "SWARM_FAIL_TIMEOUT", 0.45)
