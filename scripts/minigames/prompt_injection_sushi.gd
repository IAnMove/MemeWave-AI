extends "res://scripts/minigames/base_minigame.gd"

const TARGET_BLOCKED := 8
const PLATE_SPEED := 260.0
const SPAWN_MIN := 0.38
const SPAWN_MAX := 0.68
const LANES := [292.0, 404.0, 516.0]
const PLATES := [
	{"key": "INJECTION_BAD_1", "bad": true},
	{"key": "INJECTION_BAD_2", "bad": true},
	{"key": "INJECTION_BAD_3", "bad": true},
	{"key": "INJECTION_BAD_4", "bad": true},
	{"key": "INJECTION_BAD_5", "bad": true},
	{"key": "INJECTION_GOOD_1", "bad": false},
	{"key": "INJECTION_GOOD_2", "bad": false},
	{"key": "INJECTION_GOOD_3", "bad": false},
	{"key": "INJECTION_GOOD_4", "bad": false}
]

var plates: Array[Dictionary] = []
var spawn_timer := 0.0
var blocked := 0
var mistakes := 0
var model_label: Label
var firewall_label: Label

func _ready() -> void:
	configure(
		"GAME_INJECTION_TITLE",
		"INJECTION_INSTRUCTIONS",
		"GAME_INJECTION_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	plates.clear()
	spawn_timer = 0.0
	blocked = 0
	mistakes = 0
	score = 0
	_clear_plates()
	_update_labels()
	model_label.text = tr("INJECTION_MODEL_IDLE")
	firewall_label.text = tr("INJECTION_FIREWALL_IDLE")

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(SPAWN_MIN, SPAWN_MAX)
		_spawn_plate()

	for plate in plates.duplicate():
		var node := plate["node"] as Control
		node.position.x += PLATE_SPEED * delta
		if node.position.x > 1090.0:
			if bool(plate["bad"]):
				mistakes += 1
				model_label.text = tr("INJECTION_MODEL_HIT")
			_remove_plate(plate)
			_update_labels()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#1a1724")
	add_child(bg)
	move_child(bg, 0)

	_build_conveyor()
	_build_left_panel()
	_build_model_panel()

func _build_conveyor() -> void:
	var belt := PanelContainer.new()
	belt.position = Vector2(205, 248)
	belt.size = Vector2(812, 352)
	belt.add_theme_stylebox_override("panel", make_style(Color("#2d2f36"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(belt)

	for lane_y in LANES:
		var lane := ColorRect.new()
		lane.position = Vector2(220, lane_y + 44)
		lane.size = Vector2(780, 14)
		lane.color = Color("#777777")
		content_layer.add_child(lane)

	var label := make_label(tr("INJECTION_BELT"), 30, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(238, 258)
	label.size = Vector2(744, 42)
	label.add_theme_color_override("font_outline_color", Color("#111111"))
	label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(label)

func _build_left_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(48, 248)
	panel.size = Vector2(130, 352)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var scanner := make_label(tr("INJECTION_SCANNER"), 23, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	scanner.position = Vector2(62, 272)
	scanner.size = Vector2(102, 82)
	content_layer.add_child(scanner)

	firewall_label = make_label("", 20, Color("#176c39"), HORIZONTAL_ALIGNMENT_CENTER)
	firewall_label.position = Vector2(62, 432)
	firewall_label.size = Vector2(102, 100)
	firewall_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	firewall_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(firewall_label)

func _build_model_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(1042, 248)
	panel.size = Vector2(186, 352)
	panel.add_theme_stylebox_override("panel", make_style(Color("#eff7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var model := make_sprite("res://assets/sprites/hungry_model.png", Vector2(146, 130))
	model.position = Vector2(1062, 286)
	content_layer.add_child(model)

	var title := make_label(tr("INJECTION_MODEL_TITLE"), 25, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(1058, 424)
	title.size = Vector2(154, 38)
	content_layer.add_child(title)

	model_label = make_label("", 21, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	model_label.position = Vector2(1060, 478)
	model_label.size = Vector2(150, 72)
	content_layer.add_child(model_label)

func _spawn_plate() -> void:
	if plates.size() >= 7:
		return

	var def: Dictionary = PLATES[randi_range(0, PLATES.size() - 1)]
	var plate := Button.new()
	plate.name = "DynamicInjectionPlate"
	plate.position = Vector2(214, LANES[randi_range(0, LANES.size() - 1)])
	plate.size = Vector2(230, 72)
	plate.pivot_offset = Vector2(115, 36)
	plate.text = tr(def["key"])
	plate.focus_mode = Control.FOCUS_NONE
	plate.add_theme_font_size_override("font_size", 16)
	plate.add_theme_color_override("font_color", Color("#1d1d1d"))
	plate.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
	plate.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
	plate.add_theme_color_override("font_outline_color", Color("#ffffff"))
	plate.add_theme_constant_override("outline_size", 2)
	plate.add_theme_stylebox_override("normal", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 12))
	plate.add_theme_stylebox_override("hover", make_style(Color("#fff7c7"), Color("#1d1d1d"), 4, 12))
	plate.add_theme_stylebox_override("pressed", make_style(Color("#ffd1dc"), Color("#1d1d1d"), 4, 12))
	plate.pressed.connect(_on_plate_pressed.bind(plate))
	content_layer.add_child(plate)
	plates.append({"node": plate, "bad": bool(def["bad"])})

func _on_plate_pressed(node: Button) -> void:
	if not running:
		return

	var plate := _find_plate(node)
	if plate.is_empty():
		return

	if bool(plate["bad"]):
		blocked += 1
		score = blocked
		firewall_label.text = tr("INJECTION_BLOCKED")
		model_label.text = tr("INJECTION_MODEL_SAFE")
		_remove_plate(plate)
		_update_labels()
		if blocked >= TARGET_BLOCKED:
			await finish_with_result(true, "INJECTION_SUCCESS", 0.65)
	else:
		mistakes += 1
		firewall_label.text = tr("INJECTION_FALSE_POSITIVE")
		_remove_plate(plate)
		_update_labels()

func _find_plate(node: Button) -> Dictionary:
	for plate in plates:
		if plate["node"] == node:
			return plate
	return {}

func _remove_plate(plate: Dictionary) -> void:
	plates.erase(plate)
	var node := plate["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_plates() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicInjectionPlate":
			child.queue_free()
	plates.clear()

func _update_labels() -> void:
	set_status(tr("INJECTION_STATUS") % [blocked, TARGET_BLOCKED, mistakes])

func on_timeout() -> void:
	var success := blocked >= TARGET_BLOCKED
	await finish_with_result(success, "INJECTION_TIMEOUT_SUCCESS" if success else "INJECTION_FAIL", 0.45)
