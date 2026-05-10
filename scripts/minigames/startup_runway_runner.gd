extends "res://scripts/minigames/base_minigame.gd"

const TARGET_CASH := 8
const MAX_BILLS := 3
const PLAYER_SPEED := 560.0
const PLAYER_MIN_X := 130.0
const PLAYER_MAX_X := 965.0

var items: Array[Dictionary] = []
var spawn_timer := 0.0
var cash := 0
var bills := 0
var missed := 0
var player: PanelContainer
var runway_bar: ProgressBar
var runway_label: Label

func _ready() -> void:
	configure("GAME_RUNWAY_TITLE", "RUNWAY_INSTRUCTIONS", "GAME_RUNWAY_DESC", "")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	items.clear()
	spawn_timer = 0.0
	cash = 0
	bills = 0
	missed = 0
	score = 0
	_clear_items()
	player.position = Vector2(555, 536)
	player.rotation = 0.0
	runway_bar.value = 0
	runway_label.text = tr("RUNWAY_IDLE")
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return
	_update_player(delta)
	_update_spawns(delta)
	_update_items(delta)

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#172335")
	add_child(bg)
	move_child(bg, 0)

	var stage := PanelContainer.new()
	stage.position = Vector2(80, 220)
	stage.size = Vector2(880, 398)
	stage.add_theme_stylebox_override("panel", make_style(Color("#f2f7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(stage)

	var title := make_label(tr("RUNWAY_STAGE_TITLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
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

	var player_label := make_label(tr("RUNWAY_PLAYER"), 22, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	player.add_child(player_label)

	var side := PanelContainer.new()
	side.position = Vector2(1000, 220)
	side.size = Vector2(220, 398)
	side.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(side)

	var sam := make_sprite("res://assets/sprites/sam_face.png", Vector2(136, 120))
	sam.position = Vector2(1042, 248)
	content_layer.add_child(sam)

	var stash := make_label(tr("RUNWAY_STASH"), 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	stash.position = Vector2(1024, 390)
	stash.size = Vector2(172, 42)
	content_layer.add_child(stash)

	runway_bar = ProgressBar.new()
	runway_bar.position = Vector2(1030, 450)
	runway_bar.size = Vector2(160, 34)
	runway_bar.min_value = 0
	runway_bar.max_value = TARGET_CASH
	runway_bar.show_percentage = false
	content_layer.add_child(runway_bar)

	runway_label = make_label("", 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	runway_label.position = Vector2(1024, 506)
	runway_label.size = Vector2(172, 70)
	content_layer.add_child(runway_label)

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
		spawn_timer = randf_range(0.34, 0.72)
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
				missed += 1
			_remove_item(item)
			_update_status()

func _spawn_item() -> void:
	var kind := "cash"
	var key := "RUNWAY_ITEM_CASH"
	var fill := Color("#bdfb7f")
	if randf() > 0.68:
		kind = "bill"
		key = "RUNWAY_ITEM_BILL"
		fill = Color("#ff7777")

	var card := PanelContainer.new()
	card.name = "DynamicRunwayItem"
	card.position = Vector2(randf_range(130, 846), 206)
	card.size = Vector2(124, 64)
	card.pivot_offset = Vector2(62, 32)
	card.add_theme_stylebox_override("panel", make_style(fill, Color("#1d1d1d"), 4, 8))
	content_layer.add_child(card)

	var label := make_label(tr(key), 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	card.add_child(label)
	items.append({"node": card, "kind": kind, "speed": randf_range(170.0, 310.0), "spin": randf_range(-1.1, 1.1)})

func _catch_item(item: Dictionary) -> void:
	if item["kind"] == "cash":
		cash += 1
		score = cash
		runway_bar.value = cash
		runway_label.text = tr("RUNWAY_CASH")
		play_action_sound("collect")
		_remove_item(item)
		if cash >= TARGET_CASH:
			await finish_with_result(true, "RUNWAY_SUCCESS", 0.7)
			return
	else:
		bills += 1
		runway_label.text = tr("RUNWAY_BILL")
		_remove_item(item)
		if bills >= MAX_BILLS:
			await finish_with_result(false, "RUNWAY_FAIL_BILLS", 0.55)
			return
		play_action_sound("bad")
	_update_status()

func _remove_item(item: Dictionary) -> void:
	items.erase(item)
	var node := item["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_items() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicRunwayItem":
			child.queue_free()
	items.clear()

func _update_status() -> void:
	set_status(tr("RUNWAY_STATUS") % [cash, TARGET_CASH, bills, missed])

func on_timeout() -> void:
	var success := cash >= TARGET_CASH
	await finish_with_result(success, "RUNWAY_TIMEOUT_SUCCESS" if success else "RUNWAY_FAIL", 0.45)
