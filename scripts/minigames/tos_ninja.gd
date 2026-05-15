extends "res://scripts/minigames/base_minigame.gd"

const TARGET_BLOCKS := 8
const SPAWN_DELAY_MIN := 0.82
const SPAWN_DELAY_MAX := 1.20
const FALL_SPEED_MIN := 57.5
const FALL_SPEED_MAX := 95.0
const CLAUSES := [
	{"key": "TOS_BAD_DATA", "bad": true},
	{"key": "TOS_BAD_SOUL", "bad": true},
	{"key": "TOS_BAD_GPU", "bad": true},
	{"key": "TOS_BAD_FOREVER", "bad": true},
	{"key": "TOS_GOOD_BUGS", "bad": false},
	{"key": "TOS_GOOD_COOKIES", "bad": false},
	{"key": "TOS_GOOD_EXPORT", "bad": false},
	{"key": "TOS_GOOD_DELETE", "bad": false}
]

var clauses: Array[Dictionary] = []
var spawn_timer := 0.0
var blocked := 0
var mistakes := 0
var ninja_label: Label

func _ready() -> void:
	configure("GAME_TOS_TITLE", "TOS_INSTRUCTIONS", "GAME_TOS_DESC", "")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	clauses.clear()
	spawn_timer = 0.0
	blocked = 0
	mistakes = 0
	score = 0
	_clear_clauses()
	ninja_label.text = tr("TOS_IDLE")
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(SPAWN_DELAY_MIN, SPAWN_DELAY_MAX)
		_spawn_clause()
	for clause in clauses.duplicate():
		var node := clause["node"] as Control
		node.position.y += float(clause["speed"]) * delta
		if node.position.y > 635.0:
			if bool(clause["bad"]):
				mistakes += 1
				ninja_label.text = tr("TOS_MISSED")
			_remove_clause(clause)
			_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#171b2a")
	add_child(bg)
	move_child(bg, 0)

	var panel := PanelContainer.new()
	panel.position = Vector2(118, 220)
	panel.size = Vector2(820, 398)
	panel.add_theme_stylebox_override("panel", make_style(Color("#eff7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("TOS_STAGE_TITLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(152, 238)
	title.size = Vector2(752, 48)
	content_layer.add_child(title)

	var side := PanelContainer.new()
	side.position = Vector2(980, 220)
	side.size = Vector2(220, 398)
	side.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(side)

	var icon := make_label("NINJA\nLEGAL", 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	icon.position = Vector2(1010, 270)
	icon.size = Vector2(160, 100)
	content_layer.add_child(icon)

	ninja_label = make_label("", 23, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	ninja_label.position = Vector2(1008, 438)
	ninja_label.size = Vector2(164, 96)
	content_layer.add_child(ninja_label)

func _spawn_clause() -> void:
	if clauses.size() >= 6:
		return
	var def: Dictionary = CLAUSES[randi_range(0, CLAUSES.size() - 1)]
	var card := Button.new()
	card.name = "DynamicTosClause"
	card.position = Vector2(randf_range(145, 635), 292)
	card.size = Vector2(250, 82)
	card.text = tr(def["key"])
	card.focus_mode = Control.FOCUS_NONE
	card.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_theme_font_size_override("font_size", 18)
	card.add_theme_color_override("font_color", Color("#1d1d1d"))
	card.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
	card.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
	card.add_theme_color_override("font_outline_color", Color("#ffffff"))
	card.add_theme_constant_override("outline_size", 2)
	card.add_theme_stylebox_override("normal", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 8))
	card.add_theme_stylebox_override("hover", make_style(Color("#fff7c7"), Color("#1d1d1d"), 4, 8))
	card.pressed.connect(_on_clause_pressed.bind(card))
	content_layer.add_child(card)
	clauses.append({"node": card, "bad": bool(def["bad"]), "speed": randf_range(FALL_SPEED_MIN, FALL_SPEED_MAX)})

func _on_clause_pressed(node: Button) -> void:
	if not running:
		return
	var clause := _find_clause(node)
	if clause.is_empty():
		return
	if bool(clause["bad"]):
		blocked += 1
		score = blocked
		ninja_label.text = tr("TOS_BLOCKED")
		_remove_clause(clause)
		if blocked >= TARGET_BLOCKS:
			await finish_with_result(true, "TOS_SUCCESS", 0.7)
			return
	else:
		mistakes += 1
		ninja_label.text = tr("TOS_FALSE")
		_remove_clause(clause)
	_update_status()

func _find_clause(node: Button) -> Dictionary:
	for clause in clauses:
		if clause["node"] == node:
			return clause
	return {}

func _remove_clause(clause: Dictionary) -> void:
	clauses.erase(clause)
	var node := clause["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_clauses() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicTosClause":
			child.queue_free()
	clauses.clear()

func _update_status() -> void:
	set_status(tr("TOS_STATUS") % [blocked, TARGET_BLOCKS, mistakes])

func on_timeout() -> void:
	var success := blocked >= TARGET_BLOCKS
	await finish_with_result(success, "TOS_TIMEOUT_SUCCESS" if success else "TOS_FAIL", 0.45)
