extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_REPOS := 8
const MISTAKE_LIMIT := 3
const REPOS := [
	{"key": "FUNERAL_REPO_DOCS", "dest": "community"},
	{"key": "FUNERAL_REPO_PLUGIN", "dest": "community"},
	{"key": "FUNERAL_REPO_WEIGHTS", "dest": "research"},
	{"key": "FUNERAL_REPO_PAPER", "dest": "research"},
	{"key": "FUNERAL_REPO_CORE", "dest": "vault"},
	{"key": "FUNERAL_REPO_TRAINING", "dest": "vault"},
	{"key": "FUNERAL_REPO_DEMO", "dest": "community"},
	{"key": "FUNERAL_REPO_SAFETY", "dest": "research"},
	{"key": "FUNERAL_REPO_SECRET", "dest": "vault"}
]

var queue: Array[int] = []
var current_repo := -1
var sorted := 0
var mistakes := 0
var repo_label: Label
var verdict_label: Label
var progress_bar: ProgressBar
var zone_buttons: Dictionary = {}

func _ready() -> void:
	configure("GAME_FUNERAL_TITLE", "FUNERAL_INSTRUCTIONS", "GAME_FUNERAL_DESC", "res://assets/art/repo_private_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(REPOS.size()):
		queue.append(index)
	queue.shuffle()
	current_repo = -1
	sorted = 0
	mistakes = 0
	score = 0
	progress_bar.value = 0
	verdict_label.text = tr("FUNERAL_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#fff1c6"))
	_next_repo()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_1:
		_on_zone_pressed("community")
	elif event.keycode == KEY_2:
		_on_zone_pressed("research")
	elif event.keycode == KEY_3:
		_on_zone_pressed("vault")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#161820")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(70, 216), Vector2(760, 406), Color("#fffdf8"), true)
	_sketch_panel(Vector2(880, 216), Vector2(330, 406), Color("#20242a"), false, Color("#111111"))

	var title := _outlined_label(tr("FUNERAL_BELT_TITLE"), 36, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(112, 236)
	title.size = Vector2(676, 54)
	content_layer.add_child(title)

	_sketch_panel(Vector2(166, 330), Vector2(568, 112), Color("#eef7ff"), false, Color("#1f5fbf"))
	repo_label = _outlined_label("", 32, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	repo_label.position = Vector2(194, 348)
	repo_label.size = Vector2(512, 76)
	content_layer.add_child(repo_label)

	zone_buttons["community"] = _make_zone_button("FUNERAL_COMMUNITY", Vector2(102, 510), Color("#dff8da"), "community")
	zone_buttons["research"] = _make_zone_button("FUNERAL_RESEARCH", Vector2(356, 510), Color("#fff7c7"), "research")
	zone_buttons["vault"] = _make_zone_button("FUNERAL_VAULT", Vector2(610, 510), Color("#ffe0dc"), "vault")

	_icon("funnel", Vector2(928, 252), Vector2(70, 70), Color("#ffca3a"))
	var side_title := _outlined_label(tr("FUNERAL_SIDE_TITLE"), 30, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(992, 252)
	side_title.size = Vector2(168, 64)
	content_layer.add_child(side_title)

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(932, 382)
	progress_bar.size = Vector2(230, 30)
	progress_bar.min_value = 0
	progress_bar.max_value = TARGET_REPOS
	progress_bar.show_percentage = false
	content_layer.add_child(progress_bar)

	verdict_label = _outlined_label("", 25, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(918, 462)
	verdict_label.size = Vector2(260, 72)
	content_layer.add_child(verdict_label)

func _make_zone_button(text_key: String, pos: Vector2, fill: Color, dest: String) -> Button:
	var button := make_button(tr(text_key), 23, fill)
	button.position = pos
	button.size = Vector2(206, 76)
	button.pressed.connect(_on_zone_pressed.bind(dest))
	content_layer.add_child(button)
	return button

func _next_repo() -> void:
	if sorted >= TARGET_REPOS:
		await finish_with_result(true, "FUNERAL_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(REPOS.size()):
			queue.append(index)
		queue.shuffle()
	current_repo = queue.pop_back()
	repo_label.text = tr(REPOS[current_repo]["key"])

func _on_zone_pressed(dest: String) -> void:
	if not running or current_repo < 0:
		return
	var repo: Dictionary = REPOS[current_repo]
	if dest == String(repo["dest"]):
		sorted += 1
		score = sorted
		progress_bar.value = sorted
		verdict_label.text = tr("FUNERAL_GOOD")
		verdict_label.add_theme_color_override("font_color", Color("#5cff86"))
	else:
		mistakes += 1
		verdict_label.text = tr("FUNERAL_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		_shake(repo_label)
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "FUNERAL_FAIL", 0.6)
			return
	_update_status()
	_next_repo()

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.04)
	tween.tween_property(node, "position:x", original.x + 10, 0.04)
	tween.tween_property(node, "position", original, 0.05)

func _update_status() -> void:
	set_status(tr("FUNERAL_STATUS") % [sorted, TARGET_REPOS, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
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
	label.add_theme_color_override("font_outline_color", Color("#ffffff") if color != Color("#ffffff") else Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(sorted >= TARGET_REPOS, "FUNERAL_TIMEOUT_SUCCESS" if sorted >= TARGET_REPOS else "FUNERAL_TIMEOUT_FAIL", 0.45)
