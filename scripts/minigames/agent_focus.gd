extends "res://scripts/minigames/base_minigame.gd"

const TARGET_PROGRESS := 100.0
const SPAWN_MIN := 0.48
const SPAWN_MAX := 0.88
const DISTRACTION_LIFETIME := 2.05
const DISTRACTIONS := [
	{"key": "AGENT_DISTRACTION_CSS", "penalty": 12, "boost": 12, "color": "#ff9fd6"},
	{"key": "AGENT_DISTRACTION_FILES", "penalty": 14, "boost": 13, "color": "#ffef5f"},
	{"key": "AGENT_DISTRACTION_REWRITE", "penalty": 16, "boost": 15, "color": "#ff7777"},
	{"key": "AGENT_DISTRACTION_FRAMEWORK", "penalty": 18, "boost": 16, "color": "#66c6ff"},
	{"key": "AGENT_DISTRACTION_NAMING", "penalty": 10, "boost": 10, "color": "#bdfb7f"},
	{"key": "AGENT_DISTRACTION_TABS", "penalty": 13, "boost": 12, "color": "#ffb25f"}
]

var distractions: Array[Dictionary] = []
var spawn_timer := 0.0
var task_progress := 0.0
var focus := 100.0
var cleared := 0
var mistakes := 0
var progress_bar: ProgressBar
var focus_bar: ProgressBar
var agent_mood: Label
var cleared_label: Label
var mistake_label: Label

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
	distractions.clear()
	spawn_timer = 0.0
	task_progress = 0.0
	focus = 100.0
	cleared = 0
	mistakes = 0
	score = 0
	_clear_distractions()
	_update_meters()
	_update_status()
	agent_mood.text = tr("AGENT_MOOD_WORKING")

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	var pressure := distractions.size()
	task_progress = min(TARGET_PROGRESS, task_progress + delta * (4.0 if pressure > 0 else 7.0))
	focus = clamp(focus - delta * pressure * 4.0, 0.0, 100.0)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(SPAWN_MIN, SPAWN_MAX)
		_spawn_distraction()

	for distraction in distractions.duplicate():
		distraction["life"] = float(distraction["life"]) - delta
		var node := distraction["node"] as Control
		node.rotation = sin(float(distraction["life"]) * 9.0) * 0.045
		if float(distraction["life"]) <= 0.0:
			_miss_distraction(distraction)

	_update_meters()

	if task_progress >= TARGET_PROGRESS:
		await finish_with_result(true, "AGENT_SUCCESS", 0.7)
	elif focus <= 0.0:
		await finish_with_result(false, "AGENT_FAIL_FOCUS", 0.55)

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#101926")
	add_child(bg)
	move_child(bg, 0)

	_build_agent_panel()
	_build_dashboard()

func _build_agent_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(320, 220)
	panel.size = Vector2(640, 398)
	panel.add_theme_stylebox_override("panel", make_style(Color("#f2f7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("AGENT_WORK_TITLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(350, 238)
	title.size = Vector2(580, 48)
	content_layer.add_child(title)

	var agent := make_sprite("res://assets/sprites/hungry_model.png", Vector2(170, 150))
	agent.position = Vector2(555, 306)
	content_layer.add_child(agent)

	agent_mood = make_label("", 30, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	agent_mood.position = Vector2(390, 464)
	agent_mood.size = Vector2(500, 45)
	agent_mood.add_theme_color_override("font_outline_color", Color("#ffffff"))
	agent_mood.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(agent_mood)

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(402, 532)
	progress_bar.size = Vector2(476, 34)
	progress_bar.min_value = 0
	progress_bar.max_value = TARGET_PROGRESS
	progress_bar.show_percentage = false
	content_layer.add_child(progress_bar)

	var progress_label := make_label(tr("AGENT_PROGRESS_LABEL"), 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	progress_label.position = Vector2(402, 566)
	progress_label.size = Vector2(476, 28)
	content_layer.add_child(progress_label)

func _build_dashboard() -> void:
	var left := PanelContainer.new()
	left.position = Vector2(54, 220)
	left.size = Vector2(226, 398)
	left.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(left)

	var focus_title := make_label(tr("AGENT_FOCUS_TITLE"), 30, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	focus_title.position = Vector2(75, 248)
	focus_title.size = Vector2(184, 40)
	content_layer.add_child(focus_title)

	focus_bar = ProgressBar.new()
	focus_bar.position = Vector2(84, 326)
	focus_bar.size = Vector2(166, 34)
	focus_bar.min_value = 0
	focus_bar.max_value = 100
	focus_bar.show_percentage = false
	content_layer.add_child(focus_bar)

	cleared_label = make_label("", 22, Color("#176c39"), HORIZONTAL_ALIGNMENT_CENTER)
	cleared_label.position = Vector2(76, 398)
	cleared_label.size = Vector2(182, 46)
	content_layer.add_child(cleared_label)

	mistake_label = make_label("", 22, Color("#bf2030"), HORIZONTAL_ALIGNMENT_CENTER)
	mistake_label.position = Vector2(76, 470)
	mistake_label.size = Vector2(182, 46)
	content_layer.add_child(mistake_label)

	var right := PanelContainer.new()
	right.position = Vector2(1000, 220)
	right.size = Vector2(226, 398)
	right.add_theme_stylebox_override("panel", make_style(Color("#fff0f7"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(right)

	var danger := make_label(tr("AGENT_DANGER_TITLE"), 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	danger.position = Vector2(1022, 250)
	danger.size = Vector2(182, 82)
	content_layer.add_child(danger)

	var hint := make_label(tr("AGENT_DANGER_HINT"), 21, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(1024, 418)
	hint.size = Vector2(178, 92)
	content_layer.add_child(hint)

func _spawn_distraction() -> void:
	if distractions.size() >= 6:
		return

	var def: Dictionary = DISTRACTIONS[randi_range(0, DISTRACTIONS.size() - 1)]
	var card := Button.new()
	card.name = "DynamicAgentDistraction"
	card.position = Vector2(randf_range(85, 1010), randf_range(290, 544))
	card.size = Vector2(190, 62)
	card.pivot_offset = Vector2(95, 31)
	card.text = tr(def["key"])
	card.focus_mode = Control.FOCUS_NONE
	card.add_theme_font_size_override("font_size", 16)
	card.add_theme_color_override("font_color", Color("#1d1d1d"))
	card.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
	card.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
	card.add_theme_color_override("font_outline_color", Color("#ffffff"))
	card.add_theme_constant_override("outline_size", 2)
	card.add_theme_stylebox_override("normal", make_style(Color(def["color"]), Color("#1d1d1d"), 4, 8))
	card.add_theme_stylebox_override("hover", make_style(Color(def["color"]).lightened(0.14), Color("#1d1d1d"), 4, 8))
	card.add_theme_stylebox_override("pressed", make_style(Color(def["color"]).darkened(0.12), Color("#1d1d1d"), 4, 8))
	card.pressed.connect(_on_distraction_pressed.bind(card))
	content_layer.add_child(card)
	distractions.append({
		"node": card,
		"life": DISTRACTION_LIFETIME,
		"penalty": int(def["penalty"]),
		"boost": int(def["boost"])
	})

func _on_distraction_pressed(node: Button) -> void:
	if not running:
		return

	var distraction := _find_distraction(node)
	if distraction.is_empty():
		return

	cleared += 1
	score = cleared
	task_progress = min(TARGET_PROGRESS, task_progress + int(distraction["boost"]))
	focus = min(100.0, focus + 7.0)
	agent_mood.text = tr("AGENT_MOOD_FOCUSED")
	_remove_distraction(distraction)
	_update_meters()
	_update_status()

func _miss_distraction(distraction: Dictionary) -> void:
	mistakes += 1
	focus = max(0.0, focus - int(distraction["penalty"]))
	agent_mood.text = tr("AGENT_MOOD_DISTRACTED")
	_remove_distraction(distraction)
	_update_meters()
	_update_status()

func _find_distraction(node: Button) -> Dictionary:
	for distraction in distractions:
		if distraction["node"] == node:
			return distraction
	return {}

func _remove_distraction(distraction: Dictionary) -> void:
	distractions.erase(distraction)
	var node := distraction["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_distractions() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicAgentDistraction":
			child.queue_free()
	distractions.clear()

func _update_meters() -> void:
	if progress_bar:
		progress_bar.value = task_progress
	if focus_bar:
		focus_bar.value = focus

func _update_status() -> void:
	if cleared_label:
		cleared_label.text = tr("AGENT_CLEARED") % cleared
	if mistake_label:
		mistake_label.text = tr("AGENT_MISTAKES") % mistakes
	set_status(tr("AGENT_STATUS") % [int(task_progress), int(focus), mistakes])

func on_timeout() -> void:
	var success := task_progress >= TARGET_PROGRESS and focus > 0.0
	await finish_with_result(success, "AGENT_TIMEOUT_SUCCESS" if success else "AGENT_FAIL", 0.45)
