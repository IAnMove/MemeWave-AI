extends "res://scripts/minigames/base_minigame.gd"

const TARGET_ROUTES := 7
const MODEL_DEFS := [
	{"id": "code", "name_key": "ROUTER_MODEL_CODE", "color": "#66c6ff"},
	{"id": "image", "name_key": "ROUTER_MODEL_IMAGE", "color": "#ff9fd6"},
	{"id": "summary", "name_key": "ROUTER_MODEL_SUMMARY", "color": "#bdfb7f"},
	{"id": "gossip", "name_key": "ROUTER_MODEL_GOSSIP", "color": "#ffef5f"}
]
const TASKS := [
	{"prompt_key": "ROUTER_TASK_CODE_1", "model": "code"},
	{"prompt_key": "ROUTER_TASK_CODE_2", "model": "code"},
	{"prompt_key": "ROUTER_TASK_IMAGE_1", "model": "image"},
	{"prompt_key": "ROUTER_TASK_IMAGE_2", "model": "image"},
	{"prompt_key": "ROUTER_TASK_SUMMARY_1", "model": "summary"},
	{"prompt_key": "ROUTER_TASK_SUMMARY_2", "model": "summary"},
	{"prompt_key": "ROUTER_TASK_GOSSIP_1", "model": "gossip"},
	{"prompt_key": "ROUTER_TASK_GOSSIP_2", "model": "gossip"}
]

var model_buttons: Dictionary = {}
var task_label: Label
var task_type_label: Label
var routed_label: Label
var mistake_label: Label
var current_task_index := -1
var routed := 0
var mistakes := 0

func _ready() -> void:
	configure(
		"GAME_ROUTER_TITLE",
		"ROUTER_INSTRUCTIONS",
		"GAME_ROUTER_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	routed = 0
	mistakes = 0
	score = 0
	_reset_button_styles()
	_update_counters()
	_spawn_task()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#18202e")
	add_child(bg)
	move_child(bg, 0)

	_build_rules_panel()
	_build_task_panel()
	_build_model_panel()

func _build_rules_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(48, 230)
	panel.size = Vector2(270, 370)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("ROUTER_RULES_TITLE"), 29, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(70, 246)
	title.size = Vector2(226, 42)
	content_layer.add_child(title)

	var y := 308
	for def in MODEL_DEFS:
		var model_def: Dictionary = def
		var chip := PanelContainer.new()
		chip.position = Vector2(72, y)
		chip.size = Vector2(222, 48)
		chip.add_theme_stylebox_override("panel", make_style(Color(model_def["color"]), Color("#1d1d1d"), 4, 7))
		content_layer.add_child(chip)

		var label := make_label(tr(model_def["name_key"]), 18, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
		chip.add_child(label)
		y += 62

func _build_task_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(356, 236)
	panel.size = Vector2(500, 360)
	panel.add_theme_stylebox_override("panel", make_style(Color("#f2f7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("ROUTER_INCOMING"), 31, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(384, 260)
	title.size = Vector2(444, 44)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(title)

	var terminal := PanelContainer.new()
	terminal.position = Vector2(398, 326)
	terminal.size = Vector2(416, 166)
	terminal.add_theme_stylebox_override("panel", make_style(Color("#111820"), Color("#56d364"), 3, 6))
	content_layer.add_child(terminal)

	task_label = make_label("", 31, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	task_label.position = Vector2(422, 342)
	task_label.size = Vector2(368, 132)
	task_label.add_theme_color_override("font_outline_color", Color("#000000"))
	task_label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(task_label)

	task_type_label = make_label("", 22, Color("#fff06a"), HORIZONTAL_ALIGNMENT_CENTER)
	task_type_label.position = Vector2(422, 502)
	task_type_label.size = Vector2(368, 38)
	task_type_label.add_theme_color_override("font_outline_color", Color("#111111"))
	task_type_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(task_type_label)

	routed_label = make_label("", 22, Color("#176c39"), HORIZONTAL_ALIGNMENT_LEFT)
	routed_label.position = Vector2(398, 548)
	routed_label.size = Vector2(210, 34)
	content_layer.add_child(routed_label)

	mistake_label = make_label("", 22, Color("#bf2030"), HORIZONTAL_ALIGNMENT_RIGHT)
	mistake_label.position = Vector2(604, 548)
	mistake_label.size = Vector2(210, 34)
	content_layer.add_child(mistake_label)

func _build_model_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(900, 230)
	panel.size = Vector2(320, 370)
	panel.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("ROUTER_MODELS_TITLE"), 31, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(925, 246)
	title.size = Vector2(270, 42)
	content_layer.add_child(title)

	var y := 308
	for def in MODEL_DEFS:
		var model_def: Dictionary = def
		var button := make_button(tr(model_def["name_key"]), 20, Color(model_def["color"]))
		button.position = Vector2(930, y)
		button.size = Vector2(260, 54)
		button.pressed.connect(_on_model_pressed.bind(String(model_def["id"])))
		content_layer.add_child(button)
		model_buttons[model_def["id"]] = button
		y += 66

func _spawn_task() -> void:
	var next_index := randi_range(0, TASKS.size() - 1)
	if TASKS.size() > 1:
		while next_index == current_task_index:
			next_index = randi_range(0, TASKS.size() - 1)
	current_task_index = next_index

	var task: Dictionary = TASKS[current_task_index]
	task_label.text = tr(task["prompt_key"])
	task_type_label.text = tr("ROUTER_TASK_HINT")

func _on_model_pressed(model_id: String) -> void:
	if not running or current_task_index < 0:
		return

	var task: Dictionary = TASKS[current_task_index]
	if model_id == String(task["model"]):
		routed += 1
		score = routed
		_update_counters()
		_flash_model(model_id, true)
		if routed >= TARGET_ROUTES:
			await finish_with_result(true, "ROUTER_SUCCESS", 0.7)
			return
		_spawn_task()
	else:
		mistakes += 1
		_update_counters()
		_flash_model(model_id, false)

func _flash_model(model_id: String, success: bool) -> void:
	if not model_buttons.has(model_id):
		return
	var button := model_buttons[model_id] as Button
	var fill := Color("#bdfb7f") if success else Color("#ff7777")
	button.add_theme_stylebox_override("normal", make_style(fill, Color("#1d1d1d"), 5, 8))
	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(button) and running:
		_set_model_button_style(model_id)

func _reset_button_styles() -> void:
	for def in MODEL_DEFS:
		var model_def: Dictionary = def
		_set_model_button_style(String(model_def["id"]))

func _set_model_button_style(model_id: String) -> void:
	if not model_buttons.has(model_id):
		return
	var button := model_buttons[model_id] as Button
	var color := Color("#ffffff")
	for def in MODEL_DEFS:
		var model_def: Dictionary = def
		if String(model_def["id"]) == model_id:
			color = Color(model_def["color"])
			break
	button.add_theme_stylebox_override("normal", make_style(color, Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("hover", make_style(color.lightened(0.16), Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("pressed", make_style(color.darkened(0.14), Color("#1d1d1d"), 4, 8))

func _update_counters() -> void:
	if routed_label:
		routed_label.text = tr("ROUTER_ROUTED") % [routed, TARGET_ROUTES]
	if mistake_label:
		mistake_label.text = tr("ROUTER_MISSES") % mistakes
	set_status(tr("ROUTER_STATUS") % [routed, TARGET_ROUTES, mistakes])

func on_timeout() -> void:
	var success := routed >= TARGET_ROUTES
	await finish_with_result(success, "ROUTER_TIMEOUT_SUCCESS" if success else "ROUTER_FAIL", 0.45)
