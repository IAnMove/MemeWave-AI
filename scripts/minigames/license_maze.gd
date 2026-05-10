extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const CELL_SIZE := 78
const GRID_ORIGIN := Vector2(145, 220)
const TARGET_STEPS := 9
const LAYOUT := [
	"S..#..G",
	".#.#.T.",
	".#...#.",
	".T##.#.",
	"......T"
]

var player_cell := Vector2i.ZERO
var steps := 0
var player: Control
var status_card: Label
var trap_label: Label

func _ready() -> void:
	configure("GAME_LICENSE_TITLE", "LICENSE_INSTRUCTIONS", "GAME_LICENSE_DESC", "res://assets/art/license_maze_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	player_cell = Vector2i.ZERO
	steps = 0
	score = 0
	if player:
		player.position = _cell_to_position(player_cell) + Vector2(12, 12)
	if status_card:
		status_card.text = tr("LICENSE_STATUS_READY")
	if trap_label:
		trap_label.text = tr("LICENSE_TRAP_IDLE")
	set_status(tr("LICENSE_STATUS") % [steps, TARGET_STEPS])

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return

	var direction := Vector2i.ZERO
	match event.keycode:
		KEY_LEFT, KEY_A:
			direction = Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			direction = Vector2i.RIGHT
		KEY_UP, KEY_W:
			direction = Vector2i.UP
		KEY_DOWN, KEY_S:
			direction = Vector2i.DOWN
		_:
			return
	get_viewport().set_input_as_handled()
	_try_move(direction)

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#f9f2df")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(content_layer, Vector2(84, 198), Vector2(680, 430), Color("#fffdf8"), Color("#111111"), 4.0, true)
	_sketch_panel(content_layer, Vector2(810, 198), Vector2(330, 430), Color("#f0f7ff"), Color("#111111"), 4.0, false)

	var title := _outlined_label(tr("LICENSE_BOARD_TITLE"), 34, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(112, 206)
	title.size = Vector2(610, 44)
	content_layer.add_child(title)

	for row in range(LAYOUT.size()):
		for col in range(String(LAYOUT[row]).length()):
			_build_cell(row, col, String(LAYOUT[row])[col])

	player = _make_player()
	player.position = _cell_to_position(player_cell) + Vector2(12, 12)
	content_layer.add_child(player)

	_icon("funnel", Vector2(832, 224), Vector2(64, 64), Color("#ffe34d"))
	var side_title := _outlined_label(tr("LICENSE_SIDE_TITLE"), 31, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	side_title.position = Vector2(900, 224)
	side_title.size = Vector2(208, 64)
	content_layer.add_child(side_title)

	status_card = _outlined_label("", 29, Color("#0b8842"), HORIZONTAL_ALIGNMENT_CENTER)
	status_card.position = Vector2(842, 320)
	status_card.size = Vector2(266, 86)
	content_layer.add_child(status_card)

	trap_label = _outlined_label("", 23, Color("#d91e18"), HORIZONTAL_ALIGNMENT_CENTER)
	trap_label.position = Vector2(840, 438)
	trap_label.size = Vector2(270, 92)
	content_layer.add_child(trap_label)

	var hint := _outlined_label(tr("LICENSE_MOVE_HINT"), 22, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(830, 555)
	hint.size = Vector2(290, 46)
	content_layer.add_child(hint)

func _build_cell(row: int, col: int, cell: String) -> void:
	var pos := _cell_to_position(Vector2i(col, row))
	var fill := Color("#ffffff")
	var label_text := ""
	var label_color := Color("#151515")
	if cell == "#":
		fill = Color("#353535")
	elif cell == "T":
		fill = Color("#ffe0dc")
		label_text = _trap_name(row, col)
		label_color = Color("#d91e18")
	elif cell == "G":
		fill = Color("#ddffe1")
		label_text = tr("LICENSE_GOAL")
		label_color = Color("#11883a")
	elif cell == "S":
		fill = Color("#e8f4ff")
		label_text = tr("LICENSE_START")

	_sketch_panel(content_layer, pos, Vector2(CELL_SIZE, CELL_SIZE), fill, Color("#111111"), 2.8, cell != "#")
	if label_text != "":
		var label := _outlined_label(label_text, 13 if cell == "T" else 16, label_color, HORIZONTAL_ALIGNMENT_CENTER)
		label.position = pos + Vector2(4, 6)
		label.size = Vector2(CELL_SIZE - 8, CELL_SIZE - 12)
		content_layer.add_child(label)

func _make_player() -> Control:
	var node := Control.new()
	node.size = Vector2(54, 54)
	_icon_to(node, "robot", Vector2.ZERO, Vector2(54, 54), Color("#91c9e8"))
	return node

func _try_move(direction: Vector2i) -> void:
	var next_cell := player_cell + direction
	if next_cell.y < 0 or next_cell.y >= LAYOUT.size():
		_bump_player()
		return
	if next_cell.x < 0 or next_cell.x >= String(LAYOUT[next_cell.y]).length():
		_bump_player()
		return

	var cell := String(LAYOUT[next_cell.y])[next_cell.x]
	if cell == "#":
		_bump_player()
		return

	player_cell = next_cell
	steps += 1
	score = steps
	play_action_sound("move")
	var tween := create_tween()
	tween.tween_property(player, "position", _cell_to_position(player_cell) + Vector2(12, 12), 0.12)
	set_status(tr("LICENSE_STATUS") % [steps, TARGET_STEPS])

	if cell == "T":
		trap_label.text = tr("LICENSE_TRAP_HIT")
		await finish_with_result(false, "LICENSE_FAIL_TRAP", 0.65)
	elif cell == "G":
		status_card.text = tr("LICENSE_STATUS_GOAL")
		await finish_with_result(true, "LICENSE_SUCCESS", 0.75)

func _bump_player() -> void:
	if not player:
		return
	play_action_sound("bad")
	var original := player.position
	var tween := create_tween()
	tween.tween_property(player, "position", original + Vector2(randf_range(-10, 10), randf_range(-8, 8)), 0.06)
	tween.tween_property(player, "position", original, 0.08)

func _cell_to_position(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func _trap_name(row: int, col: int) -> String:
	if row == 1 and col == 5:
		return tr("LICENSE_TRAP_OPENISH")
	if row == 3 and col == 1:
		return tr("LICENSE_TRAP_RESEARCH")
	return tr("LICENSE_TRAP_TERMS")

func _sketch_panel(parent: Control, pos: Vector2, panel_size: Vector2, fill: Color, border: Color, width: float, hatch: bool) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, width, 1.6, hatch, Color("#0000000c"))
	parent.add_child(panel)
	return panel

func _icon(name: String, pos: Vector2, icon_size: Vector2, color: Color) -> Control:
	return _icon_to(content_layer, name, pos, icon_size, color)

func _icon_to(parent: Control, name: String, pos: Vector2, icon_size: Vector2, color: Color) -> Control:
	var icon: Control = SketchIcon.new()
	icon.position = pos
	icon.size = icon_size
	icon.call("configure", name, color, Color("#ffffff"))
	parent.add_child(icon)
	return icon

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(false, "LICENSE_FAIL_TIMEOUT", 0.45)
