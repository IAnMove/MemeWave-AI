extends "res://scripts/minigames/base_minigame.gd"

const TARGET_STOPS := 6
const START_BUDGET := 100.0
const RAMBLE_DRAIN := 28.0
const FALSE_STOP_COST := 8.0
const RAMBLE_KEYS := [
	"VACUUM_RAMBLE_1",
	"VACUUM_RAMBLE_2",
	"VACUUM_RAMBLE_3",
	"VACUUM_RAMBLE_4"
]

var token_budget := START_BUDGET
var stops := 0
var mistakes := 0
var rambling := false
var event_timer := 0.0
var visual_timer := 0.0
var token_visuals: Array[Dictionary] = []
var budget_bar: ProgressBar
var output_label: Label
var stop_button: Button
var vacuum_label: Label
var saved_label: Label
var mistake_label: Label

func _ready() -> void:
	configure(
		"GAME_VACUUM_TITLE",
		"VACUUM_INSTRUCTIONS",
		"GAME_VACUUM_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	token_budget = START_BUDGET
	stops = 0
	mistakes = 0
	score = 0
	event_timer = 0.65
	visual_timer = 0.0
	_clear_token_visuals()
	_set_rambling(false)
	_update_meters()
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	event_timer -= delta
	if rambling:
		token_budget = max(0.0, token_budget - RAMBLE_DRAIN * delta)
		visual_timer -= delta
		if visual_timer <= 0.0:
			visual_timer = 0.12
			_spawn_token_visual()
		if token_budget <= 0.0:
			await finish_with_result(false, "VACUUM_FAIL_EMPTY", 0.55)
			return

	if event_timer <= 0.0:
		if rambling:
			mistakes += 1
			_set_rambling(false)
		else:
			_set_rambling(true)

	_update_token_visuals(delta)
	_update_meters()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#15202b")
	add_child(bg)
	move_child(bg, 0)

	_build_budget_panel()
	_build_output_panel()
	_build_vacuum_panel()

func _build_budget_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(58, 230)
	panel.size = Vector2(260, 370)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("VACUUM_BUDGET_TITLE"), 31, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(82, 258)
	title.size = Vector2(212, 46)
	content_layer.add_child(title)

	var token := make_sprite("res://assets/sprites/token.png", Vector2(120, 120))
	token.position = Vector2(128, 326)
	content_layer.add_child(token)

	budget_bar = ProgressBar.new()
	budget_bar.position = Vector2(94, 484)
	budget_bar.size = Vector2(188, 34)
	budget_bar.min_value = 0
	budget_bar.max_value = START_BUDGET
	budget_bar.show_percentage = false
	content_layer.add_child(budget_bar)

	saved_label = make_label("", 22, Color("#176c39"), HORIZONTAL_ALIGNMENT_CENTER)
	saved_label.position = Vector2(84, 536)
	saved_label.size = Vector2(208, 34)
	content_layer.add_child(saved_label)

func _build_output_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(362, 230)
	panel.size = Vector2(506, 370)
	panel.add_theme_stylebox_override("panel", make_style(Color("#eff7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("VACUUM_OUTPUT_TITLE"), 32, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(392, 252)
	title.size = Vector2(446, 46)
	content_layer.add_child(title)

	var terminal := PanelContainer.new()
	terminal.position = Vector2(408, 326)
	terminal.size = Vector2(414, 136)
	terminal.add_theme_stylebox_override("panel", make_style(Color("#111820"), Color("#56d364"), 3, 6))
	content_layer.add_child(terminal)

	output_label = make_label("", 24, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	output_label.position = Vector2(432, 344)
	output_label.size = Vector2(366, 100)
	output_label.add_theme_color_override("font_outline_color", Color("#000000"))
	output_label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(output_label)

	stop_button = make_button(tr("VACUUM_STOP"), 38, Color("#ff5b5b"))
	stop_button.position = Vector2(472, 496)
	stop_button.size = Vector2(286, 72)
	stop_button.pressed.connect(_on_stop_pressed)
	content_layer.add_child(stop_button)

func _build_vacuum_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(928, 230)
	panel.size = Vector2(260, 370)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff0f7"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var model := make_sprite("res://assets/sprites/hungry_model.png", Vector2(142, 128))
	model.position = Vector2(986, 272)
	content_layer.add_child(model)

	var mouth := PanelContainer.new()
	mouth.position = Vector2(978, 422)
	mouth.size = Vector2(160, 64)
	mouth.add_theme_stylebox_override("panel", make_style(Color("#231329"), Color("#ffffff"), 5, 12))
	content_layer.add_child(mouth)

	var mouth_label := make_label(tr("VACUUM_MOUTH"), 22, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	mouth.add_child(mouth_label)

	vacuum_label = make_label("", 24, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	vacuum_label.position = Vector2(956, 514)
	vacuum_label.size = Vector2(204, 48)
	vacuum_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	vacuum_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(vacuum_label)

	mistake_label = make_label("", 20, Color("#bf2030"), HORIZONTAL_ALIGNMENT_CENTER)
	mistake_label.position = Vector2(956, 560)
	mistake_label.size = Vector2(204, 28)
	content_layer.add_child(mistake_label)

func _on_stop_pressed() -> void:
	if not running:
		return

	if rambling:
		stops += 1
		score = stops
		token_budget = min(START_BUDGET, token_budget + 5.0)
		_set_rambling(false)
		if stops >= TARGET_STOPS:
			await finish_with_result(true, "VACUUM_SUCCESS", 0.7)
			return
	else:
		mistakes += 1
		token_budget = max(0.0, token_budget - FALSE_STOP_COST)
		output_label.text = tr("VACUUM_TOO_EARLY")
		vacuum_label.text = tr("VACUUM_WASTED")

	_update_meters()
	_update_status()

func _set_rambling(is_rambling: bool) -> void:
	rambling = is_rambling
	if rambling:
		event_timer = randf_range(1.35, 1.95)
		output_label.text = tr(RAMBLE_KEYS[randi_range(0, RAMBLE_KEYS.size() - 1)])
		output_label.add_theme_color_override("font_color", Color("#ffef5f"))
		vacuum_label.text = tr("VACUUM_ON")
	else:
		event_timer = randf_range(0.55, 1.05)
		output_label.text = tr("VACUUM_SHORT")
		output_label.add_theme_color_override("font_color", Color("#ffffff"))
		vacuum_label.text = tr("VACUUM_IDLE")

func _spawn_token_visual() -> void:
	var token := make_sprite("res://assets/sprites/token.png", Vector2(42, 42))
	token.name = "DynamicVacuumToken"
	token.position = Vector2(randf_range(142, 218), randf_range(352, 430))
	token.z_index = 4
	content_layer.add_child(token)
	token_visuals.append({
		"node": token,
		"life": 0.0,
		"start": token.position,
		"end": Vector2(1018, 430) + Vector2(randf_range(-18, 18), randf_range(-14, 14))
	})

func _update_token_visuals(delta: float) -> void:
	for token_info in token_visuals.duplicate():
		token_info["life"] = float(token_info["life"]) + delta * 1.65
		var node := token_info["node"] as Control
		var progress: float = clamp(float(token_info["life"]), 0.0, 1.0)
		node.position = (token_info["start"] as Vector2).lerp(token_info["end"] as Vector2, progress)
		node.rotation += delta * 4.0
		node.modulate.a = 1.0 - progress * 0.45
		if progress >= 1.0:
			token_visuals.erase(token_info)
			if is_instance_valid(node):
				node.queue_free()

func _clear_token_visuals() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicVacuumToken":
			child.queue_free()
	token_visuals.clear()

func _update_meters() -> void:
	if budget_bar:
		budget_bar.value = token_budget
	if saved_label:
		saved_label.text = tr("VACUUM_STOPS") % [stops, TARGET_STOPS]
	if mistake_label:
		mistake_label.text = tr("VACUUM_MISTAKES") % mistakes

func _update_status() -> void:
	set_status(tr("VACUUM_STATUS") % [int(token_budget), stops, TARGET_STOPS, mistakes])

func on_timeout() -> void:
	var success := stops >= TARGET_STOPS and token_budget > 0.0
	await finish_with_result(success, "VACUUM_TIMEOUT_SUCCESS" if success else "VACUUM_FAIL", 0.45)
