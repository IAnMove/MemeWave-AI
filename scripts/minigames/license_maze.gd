extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")

const BG_PATH := "res://assets/art/license_maze_bg.png"
const PLAYER_ICON_PATH := "res://assets/sprites/license_plane.png"
const GOAL_ICON_PATH := "res://assets/sprites/license_goal_computer.png"
const TRAP_ICON_PATH := "res://assets/sprites/license_warning.png"
const CELL_SIZE := 78
const GRID_ORIGIN := Vector2(145, 220)
const TARGET_STEPS := 10
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
var crumb_layer: Node2D
var visited_cells: Array[Vector2i] = []
var step_pips: Array[ColorRect] = []

func _ready() -> void:
	configure("GAME_LICENSE_TITLE", "LICENSE_INSTRUCTIONS", "GAME_LICENSE_DESC", BG_PATH)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	player_cell = Vector2i.ZERO
	steps = 0
	score = 0
	visited_cells = [player_cell]
	if player:
		player.position = _cell_to_position(player_cell) + Vector2(12, 12)
	if status_card:
		status_card.text = tr("LICENSE_STATUS_READY")
	if trap_label:
		trap_label.text = tr("LICENSE_TRAP_IDLE")
	_redraw_trail()
	_update_step_meter()
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
	var wash := ColorRect.new()
	set_full_rect(wash)
	wash.color = Color("#1b213044")
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(wash)

	_add_shadow(Vector2(92, 208), Vector2(682, 430))
	_add_shadow(Vector2(818, 208), Vector2(330, 430))
	_sketch_panel(content_layer, Vector2(84, 198), Vector2(680, 430), Color("#fff5d9df"), Color("#111111"), 4.0, true)
	_sketch_panel(content_layer, Vector2(810, 198), Vector2(330, 430), Color("#f0f7ffef"), Color("#111111"), 4.0, true)

	var board_art := make_sprite(BG_PATH, Vector2(CELL_SIZE * 7, CELL_SIZE * 5))
	board_art.position = GRID_ORIGIN
	board_art.stretch_mode = TextureRect.STRETCH_SCALE
	board_art.modulate = Color(1, 1, 1, 0.34)
	content_layer.add_child(board_art)

	for row in range(LAYOUT.size()):
		for col in range(String(LAYOUT[row]).length()):
			_build_cell(row, col, String(LAYOUT[row])[col])

	crumb_layer = Node2D.new()
	crumb_layer.z_index = 4
	content_layer.add_child(crumb_layer)

	player = _make_player()
	player.position = _cell_to_position(player_cell) + Vector2(12, 12)
	player.z_index = 8
	content_layer.add_child(player)

	_sprite_icon(GOAL_ICON_PATH, content_layer, Vector2(832, 224), Vector2(64, 64))
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

	_build_step_meter()

	var hint := _outlined_label(tr("LICENSE_MOVE_HINT"), 22, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(830, 555)
	hint.size = Vector2(290, 46)
	content_layer.add_child(hint)

func _build_cell(row: int, col: int, cell: String) -> void:
	var pos := _cell_to_position(Vector2i(col, row))
	var fill := Color("#fff8dbdd")
	var label_text := ""
	var label_color := Color("#151515")
	var icon_path := ""
	var hatch := true
	if cell == "#":
		fill = Color("#1966c6e6")
		hatch = true
	elif cell == "T":
		fill = Color("#ff6658e4")
		label_text = _trap_name(row, col)
		label_color = Color("#ffffff")
		icon_path = TRAP_ICON_PATH
	elif cell == "G":
		fill = Color("#c9ffc4e5")
		label_text = tr("LICENSE_GOAL")
		label_color = Color("#11883a")
		icon_path = GOAL_ICON_PATH
	elif cell == "S":
		fill = Color("#fff2aae5")
		label_text = tr("LICENSE_START")
		icon_path = PLAYER_ICON_PATH

	_sketch_panel(content_layer, pos, Vector2(CELL_SIZE, CELL_SIZE), fill, Color("#111111"), 2.8, hatch)
	if cell == "#":
		_add_wall_marks(pos)
	elif icon_path != "":
		_sprite_icon(icon_path, content_layer, pos + Vector2(16, 8), Vector2(46, 46))
	if label_text != "":
		var label := _outlined_label(label_text, 11 if cell == "T" else 15, label_color, HORIZONTAL_ALIGNMENT_CENTER)
		label.position = pos + Vector2(4, 47)
		label.size = Vector2(CELL_SIZE - 8, 26)
		content_layer.add_child(label)

func _make_player() -> Control:
	var node := Control.new()
	node.size = Vector2(54, 54)
	_sprite_icon(PLAYER_ICON_PATH, node, Vector2.ZERO, Vector2(54, 54))
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
	visited_cells.append(player_cell)
	_redraw_trail()
	_update_step_meter()
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

func _cell_center(cell: Vector2i) -> Vector2:
	return _cell_to_position(cell) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)

func _redraw_trail() -> void:
	if not crumb_layer:
		return
	for child in crumb_layer.get_children():
		child.queue_free()
	if visited_cells.is_empty():
		return

	if visited_cells.size() > 1:
		var points := PackedVector2Array()
		for cell in visited_cells:
			points.append(_cell_center(cell))
		var shadow := _make_trail_line(points, Color("#11111166"), 12.0, Vector2(0, 4))
		crumb_layer.add_child(shadow)
		var line := _make_trail_line(points, Color("#35b86b"), 7.0)
		crumb_layer.add_child(line)

	for cell in visited_cells:
		var dot := ColorRect.new()
		dot.position = _cell_center(cell) - Vector2(6, 6)
		dot.size = Vector2(12, 12)
		dot.color = Color("#fff05a")
		crumb_layer.add_child(dot)

func _make_trail_line(points: PackedVector2Array, color: Color, width: float, offset: Vector2 = Vector2.ZERO) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.position = offset
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	return line

func _build_step_meter() -> void:
	step_pips.clear()
	for index in range(TARGET_STEPS):
		var pip := ColorRect.new()
		pip.position = Vector2(848 + (index % 5) * 48, 536 + (index / 5) * 18)
		pip.size = Vector2(34, 10)
		pip.color = Color("#c4ced8")
		content_layer.add_child(pip)
		step_pips.append(pip)

func _update_step_meter() -> void:
	for index in range(step_pips.size()):
		step_pips[index].color = Color("#35d96b") if index < steps else Color("#c4ced8")

func _add_shadow(pos: Vector2, panel_size: Vector2) -> void:
	var shadow := ColorRect.new()
	shadow.position = pos
	shadow.size = panel_size
	shadow.color = Color("#00000042")
	content_layer.add_child(shadow)

func _add_wall_marks(pos: Vector2) -> void:
	for index in range(3):
		var scratch := ColorRect.new()
		scratch.position = pos + Vector2(16 + index * 16, 18 + index * 13)
		scratch.size = Vector2(36, 5)
		scratch.rotation = -0.35
		scratch.color = Color("#63b4ff88")
		content_layer.add_child(scratch)

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

func _sprite_icon(path: String, parent: Control, pos: Vector2, icon_size: Vector2) -> TextureRect:
	var icon := make_sprite(path, icon_size)
	icon.position = pos
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(false, "LICENSE_FAIL_TIMEOUT", 0.45)
