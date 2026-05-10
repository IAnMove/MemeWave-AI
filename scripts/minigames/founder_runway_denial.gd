extends "res://scripts/minigames/base_minigame.gd"

const TARGET_SPINS := 6
const MAX_INVOICES := 3
const PLAYER_SPEED := 560.0
const PLAYER_MIN_X := 130.0
const PLAYER_MAX_X := 965.0

var items: Array[Dictionary] = []
var spawn_timer := 0.0
var runway := 64.0
var spin_count := 0
var invoices := 0
var missed_cash := 0
var player: PanelContainer
var runway_bar: ProgressBar
var spin_label: Label
var all_good_button: Button

func _ready() -> void:
	configure("GAME_DENIAL_TITLE", "DENIAL_INSTRUCTIONS", "GAME_DENIAL_DESC", "res://assets/sprites/dollar_bill.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	items.clear()
	spawn_timer = 0.0
	runway = 64.0
	spin_count = 0
	invoices = 0
	missed_cash = 0
	score = 0
	_clear_items()
	player.position = Vector2(555, 536)
	player.rotation = 0.0
	runway_bar.value = runway
	spin_label.text = tr("DENIAL_IDLE")
	all_good_button.disabled = false
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return
	runway = max(0.0, runway - delta * 4.5)
	runway_bar.value = runway
	if runway <= 0.0:
		await finish_with_result(false, "DENIAL_FAIL_RUNWAY", 0.55)
		return
	_update_player(delta)
	_update_spawns(delta)
	_update_items(delta)

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#172335")
	add_child(bg)
	move_child(bg, 0)

	var stage := PanelContainer.new()
	stage.position = Vector2(80, 220)
	stage.size = Vector2(880, 398)
	stage.add_theme_stylebox_override("panel", make_style(Color("#f2f7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(stage)

	var title := make_label(tr("DENIAL_STAGE_TITLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(112, 238)
	title.size = Vector2(816, 48)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(title)

	var floor := ColorRect.new()
	floor.position = Vector2(108, 598)
	floor.size = Vector2(824, 12)
	floor.color = Color("#1d1d1d")
	content_layer.add_child(floor)

	player = PanelContainer.new()
	player.position = Vector2(555, 536)
	player.size = Vector2(170, 62)
	player.pivot_offset = Vector2(85, 52)
	player.add_theme_stylebox_override("panel", make_style(Color("#bdfb7f"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(player)

	var player_label := make_label(tr("DENIAL_PLAYER"), 21, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	player.add_child(player_label)

	var side := PanelContainer.new()
	side.position = Vector2(1000, 220)
	side.size = Vector2(220, 398)
	side.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(side)

	var face := make_sprite("res://assets/sprites/sam_face.png", Vector2(136, 120))
	face.position = Vector2(1042, 248)
	content_layer.add_child(face)

	var runway_title := make_label(tr("DENIAL_RUNWAY_TITLE"), 27, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	runway_title.position = Vector2(1026, 388)
	runway_title.size = Vector2(168, 38)
	content_layer.add_child(runway_title)

	runway_bar = ProgressBar.new()
	runway_bar.position = Vector2(1030, 438)
	runway_bar.size = Vector2(160, 32)
	runway_bar.min_value = 0
	runway_bar.max_value = 100
	runway_bar.show_percentage = false
	content_layer.add_child(runway_bar)

	all_good_button = make_button(tr("DENIAL_ALL_GOOD"), 22, Color("#ffef5f"))
	all_good_button.position = Vector2(1026, 490)
	all_good_button.size = Vector2(168, 62)
	all_good_button.pressed.connect(_press_all_good)
	content_layer.add_child(all_good_button)

	spin_label = make_label("", 19, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	spin_label.position = Vector2(1024, 560)
	spin_label.size = Vector2(172, 38)
	content_layer.add_child(spin_label)

func _update_player(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	direction = clamp(direction, -1.0, 1.0)
	player.position.x = clamp(player.position.x + direction * PLAYER_SPEED * delta, PLAYER_MIN_X, PLAYER_MAX_X)
	player.rotation = lerp(player.rotation, direction * 0.08, 0.18)

func _update_spawns(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.34, 0.68)
		_spawn_item()

func _update_items(delta: float) -> void:
	for item in items.duplicate():
		var node := item["node"] as Control
		node.position.y += float(item["speed"]) * delta
		node.rotation += float(item["spin"]) * delta
		if player.get_global_rect().intersects(node.get_global_rect()):
			_catch_item(item)
		elif node.position.y > 638.0:
			if item["kind"] == "cash":
				missed_cash += 1
			_remove_item(item)
			_update_status()

func _spawn_item() -> void:
	var kind := "cash"
	var key := "DENIAL_ITEM_CASH"
	var fill := Color("#bdfb7f")
	if randf() > 0.66:
		kind = "invoice"
		key = "DENIAL_ITEM_INVOICE"
		fill = Color("#ff7777")

	var card := PanelContainer.new()
	card.name = "DynamicDenialItem"
	card.position = Vector2(randf_range(130, 846), 206)
	card.size = Vector2(128, 64)
	card.pivot_offset = Vector2(64, 32)
	card.add_theme_stylebox_override("panel", make_style(fill, Color("#1d1d1d"), 4, 8))
	content_layer.add_child(card)

	var label := make_label(tr(key), 19, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	card.add_child(label)
	items.append({"node": card, "kind": kind, "speed": randf_range(175.0, 315.0), "spin": randf_range(-1.1, 1.1)})

func _catch_item(item: Dictionary) -> void:
	if item["kind"] == "cash":
		runway = min(100.0, runway + 18.0)
		spin_label.text = tr("DENIAL_CASH")
		play_action_sound("collect")
	else:
		invoices += 1
		runway = max(0.0, runway - 22.0)
		spin_label.text = tr("DENIAL_INVOICE")
		if invoices >= MAX_INVOICES:
			await finish_with_result(false, "DENIAL_FAIL_INVOICES", 0.55)
			return
		play_action_sound("bad")
	runway_bar.value = runway
	_remove_item(item)
	_update_status()

func _press_all_good() -> void:
	if not running:
		return
	spin_count += 1
	score = spin_count
	runway = max(0.0, runway - 6.0)
	runway_bar.value = runway
	spin_label.text = tr("DENIAL_SPIN")
	play_action_sound("move")
	if spin_count >= TARGET_SPINS:
		await finish_with_result(true, "DENIAL_SUCCESS", 0.7)
		return
	_update_status()

func _remove_item(item: Dictionary) -> void:
	items.erase(item)
	var node := item["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_items() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicDenialItem":
			child.queue_free()
	items.clear()

func _update_status() -> void:
	set_status(tr("DENIAL_STATUS") % [spin_count, TARGET_SPINS, int(runway), invoices])

func on_timeout() -> void:
	await finish_with_result(spin_count >= TARGET_SPINS, "DENIAL_TIMEOUT_SUCCESS" if spin_count >= TARGET_SPINS else "DENIAL_TIMEOUT_FAIL", 0.45)
