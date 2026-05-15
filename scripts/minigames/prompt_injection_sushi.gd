extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const RAM_PATH := "res://assets/art/gpu_black_friday_ram.png"
const GPU_PATH := "res://assets/art/gpu_black_friday_gpu.png"
const FAN_PATH := "res://assets/art/ollama_fan.png"
const TOKEN_PATH := "res://assets/sprites/token.png"
const MODEL_PATH := "res://assets/sprites/hungry_model.png"

const TARGET_SERVINGS := 8
const MISTAKE_LIMIT := 3
const PLATE_SPEED := 270.0
const SPAWN_MIN := 0.34
const SPAWN_MAX := 0.58
const LANES := [292.0, 410.0, 528.0]
const BOWL_SLOTS := [
	{"pos": Vector2(18, 18), "size": Vector2(70, 44), "rotation": -0.06},
	{"pos": Vector2(92, 18), "size": Vector2(70, 44), "rotation": 0.05},
	{"pos": Vector2(18, 68), "size": Vector2(70, 44), "rotation": 0.04},
	{"pos": Vector2(92, 68), "size": Vector2(70, 44), "rotation": -0.05},
	{"pos": Vector2(162, 20), "size": Vector2(46, 42), "rotation": 0.08},
	{"pos": Vector2(162, 70), "size": Vector2(46, 42), "rotation": -0.08},
	{"pos": Vector2(50, 116), "size": Vector2(68, 32), "rotation": 0.02},
	{"pos": Vector2(122, 116), "size": Vector2(68, 32), "rotation": -0.02}
]
const PLATES := [
	{"id": "ram", "key": "RAMEN_GOOD_RAM", "good": true, "sprite": RAM_PATH, "fill": "#bdfb7f"},
	{"id": "gpu", "key": "RAMEN_GOOD_GPU", "good": true, "sprite": GPU_PATH, "fill": "#8bd0ff"},
	{"id": "fan", "key": "RAMEN_GOOD_FAN", "good": true, "sprite": FAN_PATH, "fill": "#c7f7ff"},
	{"id": "token", "key": "RAMEN_GOOD_TOKEN", "good": true, "sprite": TOKEN_PATH, "fill": "#ffef5f"},
	{"id": "chrome", "key": "RAMEN_BAD_CHROME", "good": false, "icon": "computer_bad", "fill": "#ff9aa8"},
	{"id": "heat", "key": "RAMEN_BAD_HEAT", "good": false, "icon": "warning", "fill": "#ffbe6e"},
	{"id": "pdf", "key": "RAMEN_BAD_PDF", "good": false, "icon": "trash", "fill": "#d7ccff"},
	{"id": "miner", "key": "RAMEN_BAD_MINER", "good": false, "icon": "spark", "fill": "#ff7777"},
	{"id": "junk", "key": "RAMEN_BAD_JUNK", "good": false, "icon": "funnel", "fill": "#e8e0d6"}
]

var plates: Array[Dictionary] = []
var spawn_timer := 0.0
var served := 0
var mistakes := 0
var wobble := 0.0
var bowl_layer: Control
var model_label: Label
var kitchen_label: Label
var verdict_label: Label
var heat_bar: ProgressBar
var steam_lines: Array[Line2D] = []

func _ready() -> void:
	configure(
		"GAME_RAMEN_TITLE",
		"RAMEN_INSTRUCTIONS",
		"GAME_RAMEN_DESC",
		""
	)
	super._ready()
	if overlay_label:
		overlay_label.z_index = 200
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	plates.clear()
	spawn_timer = 0.04
	served = 0
	mistakes = 0
	wobble = 0.0
	score = 0
	_clear_plates()
	_clear_bowl()
	_update_heat()
	_update_labels("RAMEN_IDLE")
	_set_steam(false)

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	wobble += delta * 6.0
	_animate_steam()

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(SPAWN_MIN, SPAWN_MAX)
		_spawn_plate()

	for plate in plates.duplicate():
		var node := plate["node"] as Control
		node.position.x += PLATE_SPEED * delta
		node.rotation = sin(wobble + float(plate["wiggle"])) * 0.025
		if node.position.x > 1090.0:
			if bool(plate["good"]):
				_update_labels("RAMEN_MISSED")
			else:
				_update_labels("RAMEN_SKIPPED")
			_remove_plate(plate)

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#161821")
	add_child(bg)
	move_child(bg, 0)

	var back_wall := ColorRect.new()
	back_wall.position = Vector2(0, 196)
	back_wall.size = Vector2(1280, 164)
	back_wall.color = Color("#223246")
	content_layer.add_child(back_wall)

	for index in range(8):
		var rack := ColorRect.new()
		rack.position = Vector2(40 + index * 154, 216)
		rack.size = Vector2(88, 116)
		rack.color = Color("#101923")
		content_layer.add_child(rack)
		for light_index in range(4):
			var led := ColorRect.new()
			led.position = rack.position + Vector2(16 + light_index * 16, 16)
			led.size = Vector2(8, 8)
			led.color = Color("#5cff86") if (index + light_index) % 2 == 0 else Color("#ffef5f")
			content_layer.add_child(led)

	var counter := ColorRect.new()
	counter.position = Vector2(0, 360)
	counter.size = Vector2(1280, 360)
	counter.color = Color("#e8bd76")
	content_layer.add_child(counter)

	for index in range(9):
		var stripe := ColorRect.new()
		stripe.position = Vector2(12 + index * 152, 366)
		stripe.size = Vector2(5, 360)
		stripe.color = Color("#d6a665")
		stripe.rotation = -0.15
		content_layer.add_child(stripe)

	_build_conveyor()
	_build_kitchen_panel()
	_build_bowl_panel()
	_build_heat_meter()
	status_label.position = Vector2(418, 650)
	status_label.size = Vector2(440, 40)

func _build_conveyor() -> void:
	var belt: Control = SketchPanel.new()
	belt.position = Vector2(190, 246)
	belt.size = Vector2(704, 370)
	belt.call("configure", Color("#3a3e48"), Color("#111111"), 4.0, 1.2, true, Color("#ffffff14"))
	content_layer.add_child(belt)

	var sign := make_label(tr("RAMEN_BELT"), 30, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	sign.position = Vector2(238, 258)
	sign.size = Vector2(610, 42)
	sign.add_theme_color_override("font_outline_color", Color("#111111"))
	sign.add_theme_constant_override("outline_size", 6)
	content_layer.add_child(sign)

	for lane_y in LANES:
		var lane_shadow := ColorRect.new()
		lane_shadow.position = Vector2(222, lane_y + 42)
		lane_shadow.size = Vector2(636, 20)
		lane_shadow.color = Color("#111111")
		content_layer.add_child(lane_shadow)

		var lane := ColorRect.new()
		lane.position = Vector2(222, lane_y + 36)
		lane.size = Vector2(636, 16)
		lane.color = Color("#8b8f9a")
		content_layer.add_child(lane)

		for mark in range(9):
			var tick := ColorRect.new()
			tick.position = Vector2(250 + mark * 70, lane_y + 30)
			tick.size = Vector2(20, 28)
			tick.color = Color("#565b65")
			tick.rotation = 0.18
			content_layer.add_child(tick)

func _build_kitchen_panel() -> void:
	var panel: Control = SketchPanel.new()
	panel.position = Vector2(42, 260)
	panel.size = Vector2(124, 332)
	panel.call("configure", Color("#fff7d6"), Color("#111111"), 4.0, 1.2, false)
	content_layer.add_child(panel)

	var title := make_label(tr("RAMEN_PANTRY"), 20, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(54, 280)
	title.size = Vector2(100, 58)
	content_layer.add_child(title)

	kitchen_label = make_label("", 19, Color("#176c39"), HORIZONTAL_ALIGNMENT_CENTER)
	kitchen_label.position = Vector2(56, 486)
	kitchen_label.size = Vector2(96, 82)
	kitchen_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	kitchen_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(kitchen_label)

	_add_small_icon("check", Vector2(70, 360), Vector2(56, 56), Color("#8ac926"))
	_add_small_icon("warning", Vector2(70, 424), Vector2(56, 56), Color("#ff595e"))

func _build_bowl_panel() -> void:
	var panel: Control = SketchPanel.new()
	panel.position = Vector2(926, 230)
	panel.size = Vector2(304, 386)
	panel.call("configure", Color("#eef7ffe8"), Color("#111111"), 4.0, 1.2, true, Color("#66dbff18"))
	content_layer.add_child(panel)

	var model := make_sprite(MODEL_PATH, Vector2(124, 112))
	model.position = Vector2(1016, 248)
	content_layer.add_child(model)

	var rig: Control = SketchPanel.new()
	rig.position = Vector2(958, 382)
	rig.size = Vector2(224, 160)
	rig.call("configure", Color("#172032"), Color("#111111"), 4.0, 1.4, false)
	content_layer.add_child(rig)

	var display := ColorRect.new()
	display.position = Vector2(982, 406)
	display.size = Vector2(176, 30)
	display.color = Color("#08111d")
	content_layer.add_child(display)

	for index in range(4):
		var slot := ColorRect.new()
		slot.position = Vector2(984 + (index % 2) * 82, 454 + int(index / 2) * 44)
		slot.size = Vector2(72, 30)
		slot.color = Color("#253449")
		content_layer.add_child(slot)

	bowl_layer = Control.new()
	bowl_layer.position = Vector2(966, 384)
	bowl_layer.size = Vector2(212, 154)
	bowl_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(bowl_layer)

	for index in range(5):
		var steam := Line2D.new()
		steam.width = 4.0
		steam.default_color = Color("#66dbff")
		steam.points = PackedVector2Array([Vector2(978 + index * 44, 382), Vector2(1018 + index * 30, 342)])
		steam.visible = false
		content_layer.add_child(steam)
		steam_lines.append(steam)

	var bowl_title := make_label(tr("RAMEN_BOWL_TITLE"), 24, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	bowl_title.position = Vector2(954, 542)
	bowl_title.size = Vector2(232, 36)
	content_layer.add_child(bowl_title)

	model_label = make_label("", 22, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	model_label.position = Vector2(954, 574)
	model_label.size = Vector2(232, 40)
	model_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	model_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(model_label)

func _build_heat_meter() -> void:
	var heat_title := make_label("POWER", 21, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	heat_title.position = Vector2(458, 612)
	heat_title.size = Vector2(96, 30)
	heat_title.add_theme_color_override("font_outline_color", Color("#111111"))
	heat_title.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(heat_title)

	heat_bar = ProgressBar.new()
	heat_bar.position = Vector2(560, 618)
	heat_bar.size = Vector2(256, 24)
	heat_bar.max_value = TARGET_SERVINGS
	heat_bar.show_percentage = false
	content_layer.add_child(heat_bar)

	verdict_label = make_label("", 24, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(412, 204)
	verdict_label.size = Vector2(420, 40)
	verdict_label.add_theme_color_override("font_outline_color", Color("#111111"))
	verdict_label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(verdict_label)

func _spawn_plate(forced_id: String = "") -> void:
	if plates.size() >= 7:
		return

	var def := _plate_def(forced_id)
	var plate := Button.new()
	plate.name = "DynamicRamenPlate"
	plate.position = Vector2(198, LANES[randi_range(0, LANES.size() - 1)])
	plate.size = Vector2(154, 76)
	plate.pivot_offset = Vector2(77, 38)
	plate.focus_mode = Control.FOCUS_NONE
	plate.text = ""
	plate.add_theme_stylebox_override("normal", make_style(Color(String(def["fill"])), Color("#1d1d1d"), 4, 18))
	plate.add_theme_stylebox_override("hover", make_style(Color(String(def["fill"])).lightened(0.12), Color("#1d1d1d"), 4, 18))
	plate.add_theme_stylebox_override("pressed", make_style(Color(String(def["fill"])).darkened(0.12), Color("#1d1d1d"), 4, 18))
	plate.pressed.connect(_on_plate_pressed.bind(plate))
	content_layer.add_child(plate)

	var saucer := ColorRect.new()
	saucer.position = Vector2(10, 58)
	saucer.size = Vector2(132, 8)
	saucer.color = Color("#ffffff88")
	saucer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(saucer)

	if def.has("sprite"):
		var sprite := make_sprite(String(def["sprite"]), Vector2(58, 46))
		sprite.position = Vector2(8, 14)
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(sprite)
	else:
		var icon: Control = SketchIcon.new()
		icon.position = Vector2(12, 10)
		icon.size = Vector2(54, 54)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.call("configure", String(def["icon"]), Color("#bf2030"), Color("#ffffff"))
		plate.add_child(icon)

	var label := make_label(tr(String(def["key"])), 15, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(66, 8)
	label.size = Vector2(84, 58)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(label)

	plates.append({
		"node": plate,
		"id": String(def["id"]),
		"good": bool(def["good"]),
		"key": String(def["key"]),
		"sprite": String(def.get("sprite", "")),
		"fill": String(def["fill"]),
		"wiggle": randf_range(0.0, TAU)
	})

func _plate_def(forced_id: String) -> Dictionary:
	if forced_id != "":
		for plate_variant in PLATES:
			var plate: Dictionary = plate_variant
			if String(plate["id"]) == forced_id:
				return plate
	return PLATES[randi_range(0, PLATES.size() - 1)]

func _on_plate_pressed(node: Button) -> void:
	if not running:
		return

	var plate := _find_plate(node)
	if plate.is_empty():
		return

	if bool(plate["good"]):
		serve_plate(plate)
	else:
		_register_mistake("RAMEN_JUNK_CLICKED")
		_remove_plate(plate)

func serve_plate(plate: Dictionary) -> void:
	served += 1
	score = served
	_add_bowl_item(plate)
	play_action_sound("collect")
	_update_heat()
	_update_labels("RAMEN_SERVED")
	_remove_plate(plate)
	if served >= TARGET_SERVINGS:
		_set_steam(true)
		await finish_with_result(true, "RAMEN_SUCCESS", 0.65)

func _register_mistake(feedback_key: String) -> void:
	mistakes += 1
	play_action_sound("bad")
	_update_heat()
	_update_labels(feedback_key)
	if mistakes >= MISTAKE_LIMIT:
		_set_steam(false)
		await finish_with_result(false, "RAMEN_FAIL", 0.55)

func _add_bowl_item(plate: Dictionary) -> void:
	if not bowl_layer:
		return
	var slot_index := mini(served - 1, BOWL_SLOTS.size() - 1)
	var slot: Dictionary = BOWL_SLOTS[slot_index]
	var item: Control
	if String(plate.get("sprite", "")) != "":
		item = make_sprite(String(plate["sprite"]), slot["size"])
	else:
		var icon: Control = SketchIcon.new()
		icon.size = slot["size"]
		icon.call("configure", "star", Color(String(plate["fill"])), Color("#ffffff"))
		item = icon
	item.name = "BowlIngredient"
	item.position = slot["pos"]
	item.rotation = float(slot["rotation"])
	item.pivot_offset = item.size * 0.5
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bowl_layer.add_child(item)

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
		if child.name == "DynamicRamenPlate":
			child.queue_free()
	plates.clear()

func _clear_bowl() -> void:
	if not bowl_layer:
		return
	for child in bowl_layer.get_children():
		child.queue_free()

func _update_heat() -> void:
	if heat_bar:
		heat_bar.value = served
		if mistakes == 0:
			heat_bar.modulate = Color("#66dbff")
		elif mistakes == 1:
			heat_bar.modulate = Color("#ffef5f")
		else:
			heat_bar.modulate = Color("#ff7b7b")

func _update_labels(feedback_key: String) -> void:
	set_status(tr("RAMEN_STATUS") % [served, TARGET_SERVINGS, mistakes, MISTAKE_LIMIT])
	if kitchen_label:
		kitchen_label.text = tr(feedback_key)
	if verdict_label:
		verdict_label.text = tr(feedback_key)
	if model_label:
		if mistakes >= MISTAKE_LIMIT:
			model_label.text = tr("RAMEN_MODEL_HIT")
		elif served >= TARGET_SERVINGS:
			model_label.text = tr("RAMEN_MODEL_SAFE")
		else:
			model_label.text = tr("RAMEN_MODEL_IDLE")

func _set_steam(active: bool) -> void:
	for line in steam_lines:
		line.visible = active

func _animate_steam() -> void:
	for index in range(steam_lines.size()):
		var line := steam_lines[index]
		if not line.visible:
			continue
		var x := 1000.0 + float(index) * 38.0
		line.points = PackedVector2Array([
			Vector2(x, 382),
			Vector2(x + sin(wobble + index) * 18.0, 360),
			Vector2(x - cos(wobble * 0.8 + index) * 16.0, 338)
		])
		line.modulate.a = 0.58 + sin(wobble + index) * 0.22

func _add_small_icon(name: String, pos: Vector2, icon_size: Vector2, color: Color) -> Control:
	var icon: Control = SketchIcon.new()
	icon.position = pos
	icon.size = icon_size
	icon.call("configure", name, color, Color("#ffffff"))
	content_layer.add_child(icon)
	return icon

func on_timeout() -> void:
	var success := served >= TARGET_SERVINGS
	if success:
		_set_steam(true)
	await finish_with_result(success, "RAMEN_TIMEOUT_SUCCESS" if success else "RAMEN_FAIL", 0.45)
