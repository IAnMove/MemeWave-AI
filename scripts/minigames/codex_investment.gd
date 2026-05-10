extends "res://scripts/minigames/base_minigame.gd"

const TARGET_BILLS := 7
const PLAYER_SPEED := 520.0
const BILL_MIN_SPEED := 175.0
const BILL_MAX_SPEED := 285.0
const SLIDER_MIN_X := 140.0
const SLIDER_MAX_X := 805.0

var items: Array[Dictionary] = []
var spawn_timer := 0.0
var collected := 0
var misses := 0
var sam_rig: Control
var slider_fill: ColorRect
var limit_bars: Array[ProgressBar] = []

func _ready() -> void:
	configure(
		"GAME_CODEX_TITLE",
		"CODEX_INSTRUCTIONS",
		"GAME_CODEX_DESC",
		"res://assets/art/codex_investment_bg.png"
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	items.clear()
	spawn_timer = 0.0
	collected = 0
	misses = 0
	score = 0
	_clear_dynamic_items()
	if sam_rig:
		sam_rig.position = Vector2((SLIDER_MIN_X + SLIDER_MAX_X) * 0.5, 438)
		sam_rig.rotation = 0.0
	if slider_fill:
		slider_fill.size.x = 0.0
	for bar in limit_bars:
		bar.value = 10
	set_status(tr("CODEX_STATUS") % [0, TARGET_BILLS, 0])

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	_update_sam(delta)
	_update_spawner(delta)
	_update_bills(delta)

func _build_stage() -> void:
	limit_bars.clear()
	_build_catch_zone()
	_build_limits_panel()

func _build_catch_zone() -> void:
	var play_panel := PanelContainer.new()
	play_panel.position = Vector2(86, 220)
	play_panel.size = Vector2(795, 392)
	play_panel.add_theme_stylebox_override("panel", make_style(Color("#fff6ce"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(play_panel)

	var title := make_label(tr("CODEX_SAM_PLATFORM"), 30, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(118, 235)
	title.size = Vector2(720, 42)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(title)

	var track := PanelContainer.new()
	track.position = Vector2(130, 548)
	track.size = Vector2(740, 42)
	track.add_theme_stylebox_override("panel", make_style(Color("#262626"), Color("#1d1d1d"), 3, 8))
	content_layer.add_child(track)

	var rail := ColorRect.new()
	rail.position = Vector2(18, 18)
	rail.size = Vector2(704, 8)
	rail.color = Color("#5f5f5f")
	track.add_child(rail)

	slider_fill = ColorRect.new()
	slider_fill.position = Vector2(18, 18)
	slider_fill.size = Vector2(0, 8)
	slider_fill.color = Color("#61d45d")
	track.add_child(slider_fill)

	sam_rig = Control.new()
	sam_rig.name = "SamSlider"
	sam_rig.position = Vector2((SLIDER_MIN_X + SLIDER_MAX_X) * 0.5, 438)
	sam_rig.size = Vector2(132, 140)
	sam_rig.pivot_offset = Vector2(66, 116)
	content_layer.add_child(sam_rig)

	var sam_sprite := make_sprite("res://assets/sprites/sam_face.png", Vector2(120, 116))
	sam_sprite.position = Vector2(6, 0)
	sam_rig.add_child(sam_sprite)

	var platform := PanelContainer.new()
	platform.position = Vector2(0, 104)
	platform.size = Vector2(132, 34)
	platform.add_theme_stylebox_override("panel", make_style(Color("#66c6ff"), Color("#1d1d1d"), 4, 7))
	sam_rig.add_child(platform)

	var platform_label := make_label("SAM", 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	platform.add_child(platform_label)

func _build_limits_panel() -> void:
	var bars_panel := PanelContainer.new()
	bars_panel.position = Vector2(918, 220)
	bars_panel.size = Vector2(278, 392)
	bars_panel.add_theme_stylebox_override("panel", make_style(Color("#e9fbff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(bars_panel)

	var bars := VBoxContainer.new()
	bars.alignment = BoxContainer.ALIGNMENT_CENTER
	bars.add_theme_constant_override("separation", 13)
	bars_panel.add_child(bars)

	var title_bar := make_label(tr("CODEX_LIMITS"), 32, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title_bar.custom_minimum_size = Vector2(238, 52)
	bars.add_child(title_bar)

	for label_key in ["CODEX_LIMIT_RUNS", "CODEX_LIMIT_CONTEXT", "CODEX_LIMIT_PATIENCE"]:
		var label := make_label(tr(label_key), 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
		label.custom_minimum_size = Vector2(238, 26)
		bars.add_child(label)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(238, 32)
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 10
		bar.show_percentage = false
		limit_bars.append(bar)
		bars.add_child(bar)

func _update_sam(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	direction = clamp(direction, -1.0, 1.0)

	sam_rig.position.x = clamp(sam_rig.position.x + direction * PLAYER_SPEED * delta, SLIDER_MIN_X, SLIDER_MAX_X)
	sam_rig.rotation = lerp(sam_rig.rotation, direction * 0.11, 0.18)

	var progress := inverse_lerp(SLIDER_MIN_X, SLIDER_MAX_X, sam_rig.position.x)
	if slider_fill:
		slider_fill.size.x = 704.0 * progress

func _update_spawner(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	spawn_timer = randf_range(0.42, 0.82)
	_spawn_bill()

func _update_bills(delta: float) -> void:
	for item in items.duplicate():
		var node := item["node"] as Control
		node.position.y += float(item["speed"]) * delta
		node.rotation += float(item["spin"]) * delta

		if sam_rig.get_global_rect().intersects(node.get_global_rect()):
			_collect_bill(item)
		elif node.position.y > 630.0:
			misses += 1
			_remove_item(item)
			set_status(tr("CODEX_STATUS") % [collected, TARGET_BILLS, misses])

func _spawn_bill() -> void:
	var bill := make_sprite("res://assets/sprites/dollar_bill.png", Vector2(92, 92))
	bill.name = "DynamicInvestment"
	bill.position = Vector2(randf_range(130, 810), 200)
	bill.rotation = randf_range(-0.14, 0.14)
	content_layer.add_child(bill)
	items.append({
		"node": bill,
		"speed": randf_range(BILL_MIN_SPEED, BILL_MAX_SPEED),
		"spin": randf_range(-1.4, 1.4)
	})

func _collect_bill(item: Dictionary) -> void:
	collected += 1
	score = collected
	play_action_sound("collect")
	_spawn_collect_feedback(item["node"] as Control)
	_remove_item(item)
	_update_limit_bars()
	set_status(tr("CODEX_STATUS") % [collected, TARGET_BILLS, misses])
	if collected >= TARGET_BILLS:
		await finish_with_result(true, "CODEX_SUCCESS", 0.75)

func _update_limit_bars() -> void:
	for index in range(limit_bars.size()):
		limit_bars[index].value = min(100, 10 + collected * 13 + index * 5)

func _spawn_collect_feedback(source: Control) -> void:
	var pop := make_label(tr("CODEX_COLLECT_POP"), 28, Color("#fff35d"), HORIZONTAL_ALIGNMENT_CENTER)
	pop.position = source.position + Vector2(-18, -24)
	pop.size = Vector2(130, 42)
	pop.add_theme_color_override("font_outline_color", Color("#111111"))
	pop.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(pop)

	var tween := create_tween()
	tween.tween_property(pop, "position:y", pop.position.y - 42, 0.35)
	tween.parallel().tween_property(pop, "modulate:a", 0.0, 0.35)
	tween.tween_callback(Callable(pop, "queue_free"))

func _remove_item(item: Dictionary) -> void:
	items.erase(item)
	var node := item["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_dynamic_items() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicInvestment":
			child.queue_free()

func on_timeout() -> void:
	var success := collected >= TARGET_BILLS
	await finish_with_result(success, "CODEX_TIMEOUT_SUCCESS" if success else "CODEX_FAIL", 0.45)
