extends "res://scripts/minigames/base_minigame.gd"

const TARGET_GPUS := 8
const MAX_BAD_CATCHES := 3
const CART_SPEED := 560.0
const CART_MIN_X := 120.0
const CART_MAX_X := 980.0
const ITEM_MIN_SPEED := 170.0
const ITEM_MAX_SPEED := 310.0

var items: Array[Dictionary] = []
var spawn_timer := 0.0
var gpus := 0
var bad_catches := 0
var missed := 0
var cart: PanelContainer
var gpu_bar: ProgressBar
var cart_label: Label
var market_label: Label

func _ready() -> void:
	configure(
		"GAME_GPU_TITLE",
		"GPU_INSTRUCTIONS",
		"GAME_GPU_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	items.clear()
	spawn_timer = 0.0
	gpus = 0
	bad_catches = 0
	missed = 0
	score = 0
	_clear_items()
	cart.position = Vector2(555, 536)
	cart.rotation = 0.0
	gpu_bar.value = 0
	cart_label.text = tr("GPU_CART")
	market_label.text = tr("GPU_MARKET_IDLE")
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	_update_cart(delta)
	_update_spawner(delta)
	_update_items(delta)

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#17202e")
	add_child(bg)
	move_child(bg, 0)

	_build_market()
	_build_cart()
	_build_score_panel()

func _build_market() -> void:
	var market := PanelContainer.new()
	market.position = Vector2(80, 220)
	market.size = Vector2(880, 398)
	market.add_theme_stylebox_override("panel", make_style(Color("#f2f7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(market)

	var title := make_label(tr("GPU_MARKET_TITLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
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

	market_label = make_label("", 24, Color("#fff06a"), HORIZONTAL_ALIGNMENT_CENTER)
	market_label.position = Vector2(198, 294)
	market_label.size = Vector2(640, 38)
	market_label.add_theme_color_override("font_outline_color", Color("#111111"))
	market_label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(market_label)

func _build_cart() -> void:
	cart = PanelContainer.new()
	cart.position = Vector2(555, 536)
	cart.size = Vector2(170, 62)
	cart.pivot_offset = Vector2(85, 52)
	cart.add_theme_stylebox_override("panel", make_style(Color("#bdfb7f"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(cart)

	cart_label = make_label(tr("GPU_CART"), 23, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	cart.add_child(cart_label)

func _build_score_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(1000, 220)
	panel.size = Vector2(220, 398)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var sam := make_sprite("res://assets/sprites/sam_face.png", Vector2(142, 126))
	sam.position = Vector2(1039, 248)
	content_layer.add_child(sam)

	var title := make_label(tr("GPU_STASH_TITLE"), 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(1022, 390)
	title.size = Vector2(176, 42)
	content_layer.add_child(title)

	gpu_bar = ProgressBar.new()
	gpu_bar.position = Vector2(1030, 450)
	gpu_bar.size = Vector2(160, 34)
	gpu_bar.min_value = 0
	gpu_bar.max_value = TARGET_GPUS
	gpu_bar.show_percentage = false
	content_layer.add_child(gpu_bar)

	var hint := make_label(tr("GPU_AVOID_HINT"), 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(1022, 512)
	hint.size = Vector2(176, 64)
	content_layer.add_child(hint)

func _update_cart(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	direction = clamp(direction, -1.0, 1.0)

	cart.position.x = clamp(cart.position.x + direction * CART_SPEED * delta, CART_MIN_X, CART_MAX_X)
	cart.rotation = lerp(cart.rotation, direction * 0.09, 0.18)

func _update_spawner(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	spawn_timer = randf_range(0.34, 0.68)
	_spawn_item()

func _update_items(delta: float) -> void:
	for item in items.duplicate():
		var node := item["node"] as Control
		node.position.y += float(item["speed"]) * delta
		node.rotation += float(item["spin"]) * delta

		if cart.get_global_rect().intersects(node.get_global_rect()):
			_catch_item(item)
		elif node.position.y > 638.0:
			if item["kind"] == "gpu":
				missed += 1
			_remove_item(item)
			_update_status()

func _spawn_item() -> void:
	var roll := randf()
	var kind := "gpu"
	var label_key := "GPU_ITEM_GPU"
	var fill := Color("#66c6ff")
	if roll > 0.66 and roll <= 0.83:
		kind = "invoice"
		label_key = "GPU_ITEM_INVOICE"
		fill = Color("#ff7777")
	elif roll > 0.83:
		kind = "hype"
		label_key = "GPU_ITEM_HYPE"
		fill = Color("#ffef5f")

	var item_panel := PanelContainer.new()
	item_panel.name = "DynamicGpuItem"
	item_panel.position = Vector2(randf_range(130, 846), 206)
	item_panel.size = Vector2(116, 64)
	item_panel.pivot_offset = Vector2(58, 32)
	item_panel.add_theme_stylebox_override("panel", make_style(fill, Color("#1d1d1d"), 4, 8))
	content_layer.add_child(item_panel)

	var label := make_label(tr(label_key), 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	item_panel.add_child(label)

	items.append({
		"node": item_panel,
		"kind": kind,
		"speed": randf_range(ITEM_MIN_SPEED, ITEM_MAX_SPEED),
		"spin": randf_range(-1.1, 1.1)
	})

func _catch_item(item: Dictionary) -> void:
	if item["kind"] == "gpu":
		gpus += 1
		score = gpus
		gpu_bar.value = gpus
		market_label.text = tr("GPU_CAUGHT")
		play_action_sound("collect")
		_remove_item(item)
		_update_status()
		if gpus >= TARGET_GPUS:
			await finish_with_result(true, "GPU_SUCCESS", 0.7)
	else:
		bad_catches += 1
		market_label.text = tr("GPU_BAD_CATCH")
		_remove_item(item)
		_update_status()
		if bad_catches >= MAX_BAD_CATCHES:
			await finish_with_result(false, "GPU_FAIL_BILL", 0.55)
		else:
			play_action_sound("bad")

func _remove_item(item: Dictionary) -> void:
	items.erase(item)
	var node := item["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_items() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicGpuItem":
			child.queue_free()
	items.clear()

func _update_status() -> void:
	set_status(tr("GPU_STATUS") % [gpus, TARGET_GPUS, bad_catches, missed])

func on_timeout() -> void:
	var success := gpus >= TARGET_GPUS
	await finish_with_result(success, "GPU_TIMEOUT_SUCCESS" if success else "GPU_FAIL", 0.45)
