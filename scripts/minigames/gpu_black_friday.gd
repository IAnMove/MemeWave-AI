extends "res://scripts/minigames/base_minigame.gd"

const SAM_CART_PATH := "res://assets/art/gpu_black_friday_sam_cart.png"
const GPU_PATH := "res://assets/art/gpu_black_friday_gpu.png"
const RAM_PATH := "res://assets/art/gpu_black_friday_ram.png"
const SHELF_PATH := "res://assets/art/gpu_black_friday_shelf.png"

const TARGET_ITEMS := 12
const TOTAL_STOCK := 15
const MAX_MISSED := 3
const CART_SPEED := 650.0
const CART_MIN_X := 38.0
const CART_MAX_X := 826.0
const ITEM_MIN_SPEED := 205.0
const ITEM_MAX_SPEED := 340.0
const ITEM_SIZES := {
	"gpu": Vector2(132, 94),
	"ram": Vector2(132, 80)
}

var items: Array[Dictionary] = []
var stock_queue: Array[String] = []
var stock_icons: Array[TextureRect] = []
var spawn_timer := 0.0
var collected := 0
var gpus := 0
var ram := 0
var missed := 0
var cart: TextureRect
var cart_shadow: ColorRect
var cart_hitbox := Rect2()
var market_label: Label
var stock_panel: PanelContainer
var sold_out_stamp: Label

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
	stock_queue = _make_stock_queue()
	spawn_timer = 0.12
	collected = 0
	gpus = 0
	ram = 0
	missed = 0
	score = 0
	_clear_items()
	_reset_stock_icons()
	cart.position = Vector2(134, 322)
	cart.rotation = 0.0
	cart_shadow.position = Vector2(256, 633)
	market_label.text = tr("GPU_MARKET_IDLE")
	sold_out_stamp.visible = false
	_update_cart_hitbox()
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	_update_cart(delta)
	_update_spawner(delta)
	_update_items(delta)

func _build_stage() -> void:
	var wall := ColorRect.new()
	wall.position = Vector2(0, 196)
	wall.size = Vector2(1280, 262)
	wall.color = Color("#2e6d78")
	content_layer.add_child(wall)

	var floor := ColorRect.new()
	floor.position = Vector2(0, 458)
	floor.size = Vector2(1280, 262)
	floor.color = Color("#e7c891")
	content_layer.add_child(floor)

	for index in range(9):
		var tile_line := ColorRect.new()
		tile_line.position = Vector2(40 + index * 148, 458)
		tile_line.size = Vector2(4, 262)
		tile_line.color = Color("#cfae78")
		tile_line.rotation = -0.17
		content_layer.add_child(tile_line)

	var horizon := ColorRect.new()
	horizon.position = Vector2(0, 456)
	horizon.size = Vector2(1280, 8)
	horizon.color = Color("#1d1d1d")
	content_layer.add_child(horizon)

	var shelf_shadow := ColorRect.new()
	shelf_shadow.position = Vector2(590, 256)
	shelf_shadow.size = Vector2(630, 344)
	shelf_shadow.color = Color("#00000055")
	content_layer.add_child(shelf_shadow)

	var shelf := make_sprite(SHELF_PATH, Vector2(618, 376))
	shelf.position = Vector2(570, 210)
	content_layer.add_child(shelf)

	_build_stock_strip()
	_build_cart()
	_build_labeling()
	status_label.position = Vector2(520, 640)
	status_label.size = Vector2(700, 45)

func _build_labeling() -> void:
	var title := make_label(tr("GPU_MARKET_TITLE"), 31, Color("#fff8cf"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(150, 216)
	title.size = Vector2(360, 46)
	title.add_theme_color_override("font_outline_color", Color("#111111"))
	title.add_theme_constant_override("outline_size", 7)
	content_layer.add_child(title)

	market_label = make_label("", 25, Color("#fff6b3"), HORIZONTAL_ALIGNMENT_CENTER)
	market_label.position = Vector2(160, 264)
	market_label.size = Vector2(350, 40)
	market_label.add_theme_color_override("font_outline_color", Color("#111111"))
	market_label.add_theme_constant_override("outline_size", 7)
	content_layer.add_child(market_label)

	sold_out_stamp = make_label(tr("GPU_SUCCESS"), 56, Color("#ff4e5c"), HORIZONTAL_ALIGNMENT_CENTER)
	sold_out_stamp.position = Vector2(632, 354)
	sold_out_stamp.size = Vector2(486, 96)
	sold_out_stamp.rotation = -0.13
	sold_out_stamp.add_theme_color_override("font_outline_color", Color("#ffffff"))
	sold_out_stamp.add_theme_constant_override("outline_size", 10)
	sold_out_stamp.visible = false
	sold_out_stamp.z_index = 25
	content_layer.add_child(sold_out_stamp)

func _build_stock_strip() -> void:
	stock_panel = PanelContainer.new()
	stock_panel.position = Vector2(52, 520)
	stock_panel.size = Vector2(238, 82)
	stock_panel.add_theme_stylebox_override("panel", make_style(Color("#fff6d7"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(stock_panel)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(10, 8)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	stock_panel.add_child(grid)

	stock_icons.clear()
	for index in range(TOTAL_STOCK):
		var kind := "gpu" if index % 2 == 0 else "ram"
		var icon := make_sprite(GPU_PATH if kind == "gpu" else RAM_PATH, Vector2(38, 24))
		icon.custom_minimum_size = Vector2(38, 20)
		icon.modulate = Color(1, 1, 1, 0.92)
		icon.set_meta("kind", kind)
		icon.set_meta("depleted", false)
		grid.add_child(icon)
		stock_icons.append(icon)

func _build_cart() -> void:
	cart_shadow = ColorRect.new()
	cart_shadow.position = Vector2(256, 633)
	cart_shadow.size = Vector2(260, 22)
	cart_shadow.color = Color("#00000042")
	cart_shadow.rotation = -0.02
	content_layer.add_child(cart_shadow)

	cart = make_sprite(SAM_CART_PATH, Vector2(374, 380))
	cart.position = Vector2(134, 322)
	cart.pivot_offset = Vector2(190, 332)
	cart.z_index = 18
	content_layer.add_child(cart)

func _update_cart(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	direction = clamp(direction, -1.0, 1.0)

	cart.position.x = clamp(cart.position.x + direction * CART_SPEED * delta, CART_MIN_X, CART_MAX_X)
	cart.rotation = lerp(cart.rotation, direction * 0.045, 0.18)
	cart_shadow.position.x = cart.position.x + 122.0
	_update_cart_hitbox()

func _update_cart_hitbox() -> void:
	cart_hitbox = Rect2(
		cart.global_position + Vector2(cart.size.x * 0.43, cart.size.y * 0.36),
		Vector2(cart.size.x * 0.48, cart.size.y * 0.32)
	)

func _update_spawner(delta: float) -> void:
	if stock_queue.is_empty():
		if items.is_empty() and collected < TARGET_ITEMS:
			call_deferred("_finish_out_of_stock")
		return

	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	spawn_timer = randf_range(0.38, 0.62)
	_spawn_item(stock_queue.pop_front())

func _update_items(delta: float) -> void:
	for item in items.duplicate():
		var node := item["node"] as Control
		node.position.y += float(item["speed"]) * delta
		node.position.x += sin(float(item["wiggle"]) + Time.get_ticks_msec() * 0.004) * 0.55
		node.rotation += float(item["spin"]) * delta

		if cart_hitbox.intersects(node.get_global_rect()):
			_catch_item(item)
		elif node.position.y > 636.0:
			_miss_item(item)

func _make_stock_queue() -> Array[String]:
	var queue: Array[String] = []
	for index in range(TOTAL_STOCK):
		queue.append("gpu" if index % 2 == 0 else "ram")
	queue.shuffle()
	return queue

func _spawn_item(kind: String) -> void:
	var item_size: Vector2 = ITEM_SIZES[kind]
	var item := Control.new()
	item.name = "DynamicGpuItem"
	item.position = Vector2(randf_range(520, 1040), 205)
	item.size = item_size
	item.pivot_offset = item_size * 0.5
	item.z_index = 14
	content_layer.add_child(item)

	var shadow := ColorRect.new()
	shadow.position = Vector2(8, item_size.y - 10)
	shadow.size = Vector2(item_size.x - 18, 12)
	shadow.color = Color("#00000032")
	item.add_child(shadow)

	var sprite := make_sprite(GPU_PATH if kind == "gpu" else RAM_PATH, item_size)
	sprite.position = Vector2.ZERO
	item.add_child(sprite)

	_deplete_next_stock_icon(kind)
	items.append({
		"node": item,
		"kind": kind,
		"speed": randf_range(ITEM_MIN_SPEED, ITEM_MAX_SPEED),
		"spin": randf_range(-0.9, 0.9),
		"wiggle": randf_range(0.0, TAU)
	})

func _deplete_next_stock_icon(kind: String) -> void:
	for icon in stock_icons:
		if not bool(icon.get_meta("depleted")) and String(icon.get_meta("kind")) == kind:
			icon.modulate = Color(1, 1, 1, 0.20)
			icon.set_meta("depleted", true)
			return
	for icon in stock_icons:
		if not bool(icon.get_meta("depleted")):
			icon.modulate = Color(1, 1, 1, 0.20)
			icon.set_meta("depleted", true)
			return

func _catch_item(item: Dictionary) -> void:
	var kind := String(item["kind"])
	_remove_item(item)
	_register_catch(kind)

func _register_catch(kind: String) -> void:
	collected += 1
	if kind == "gpu":
		gpus += 1
	else:
		ram += 1
	score = collected
	market_label.text = tr("GPU_CAUGHT")
	play_action_sound("collect")
	_update_status()
	if collected >= TARGET_ITEMS:
		_show_sold_out()
		call_deferred("_finish_success")

func _miss_item(item: Dictionary) -> void:
	missed += 1
	_remove_item(item)
	market_label.text = tr("GPU_FAIL_BILL")
	play_action_sound("bad")
	_update_status()
	if missed >= MAX_MISSED:
		call_deferred("_finish_out_of_stock")

func _show_sold_out() -> void:
	sold_out_stamp.visible = true
	for icon in stock_icons:
		icon.modulate = Color(1, 1, 1, 0.12)
		icon.set_meta("depleted", true)

func _finish_success() -> void:
	await finish_with_result(true, "GPU_SUCCESS", 0.72)

func _finish_out_of_stock() -> void:
	await finish_with_result(false, "GPU_FAIL", 0.58)

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

func _reset_stock_icons() -> void:
	for icon in stock_icons:
		icon.visible = true
		icon.modulate = Color(1, 1, 1, 0.92)
		icon.set_meta("depleted", false)

func _update_status() -> void:
	set_status(tr("GPU_STATUS") % [gpus, ram, missed, MAX_MISSED])

func on_timeout() -> void:
	var success := collected >= TARGET_ITEMS
	if success:
		_show_sold_out()
	await finish_with_result(success, "GPU_TIMEOUT_SUCCESS" if success else "GPU_FAIL", 0.45)
