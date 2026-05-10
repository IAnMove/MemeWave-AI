extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_RENAMES := 6
const MISTAKE_LIMIT := 3
const PRODUCTS := [
	{"old_key": "RENAME_OLD_TWITTER", "new_key": "RENAME_NEW_X", "wrong": ["RENAME_WRONG_BIRDAPP", "RENAME_WRONG_POSTY"]},
	{"old_key": "RENAME_OLD_ROCKET", "new_key": "RENAME_NEW_STARPIPE", "wrong": ["RENAME_WRONG_MOONBUS", "RENAME_WRONG_BOOMTUBE"]},
	{"old_key": "RENAME_OLD_AI_CHAT", "new_key": "RENAME_NEW_TRUTH_BLENDER", "wrong": ["RENAME_WRONG_HELPBOT", "RENAME_WRONG_CALMBOX"]},
	{"old_key": "RENAME_OLD_CAR", "new_key": "RENAME_NEW_WHEEL_X", "wrong": ["RENAME_WRONG_ROADPOD", "RENAME_WRONG_AUTOCUBE"]},
	{"old_key": "RENAME_OLD_BUTTON", "new_key": "RENAME_NEW_MEGA_X", "wrong": ["RENAME_WRONG_OK_BUTTON", "RENAME_WRONG_NORMAL_NAME"]},
	{"old_key": "RENAME_OLD_COMPANY", "new_key": "RENAME_NEW_X_EVERYTHING", "wrong": ["RENAME_WRONG_OPEN_THING", "RENAME_WRONG_CLOUDCHAT"]}
]

var queue: Array[int] = []
var current_product := -1
var rename_count := 0
var mistakes := 0
var product_label: Label
var verdict_label: Label
var rename_bar: ProgressBar
var option_buttons: Array[Button] = []

func _ready() -> void:
	configure("GAME_RENAME_TITLE", "RENAME_INSTRUCTIONS", "GAME_RENAME_DESC", "res://assets/sprites/elon_face.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(PRODUCTS.size()):
		queue.append(index)
	queue.shuffle()
	current_product = -1
	rename_count = 0
	mistakes = 0
	score = 0
	rename_bar.value = 0
	verdict_label.text = tr("RENAME_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#151515"))
	_set_buttons_enabled(true)
	_next_product()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_3:
		var index := int(event.keycode - KEY_1)
		if index >= 0 and index < option_buttons.size():
			get_viewport().set_input_as_handled()
			_on_option_pressed(String(option_buttons[index].get_meta("name_key")))

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fbf7eb")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(70, 214), Vector2(760, 410), Color("#fffdf8"), true)
	_sketch_panel(Vector2(884, 214), Vector2(320, 410), Color("#f2f7ff"), false)

	var title := _outlined_label(tr("RENAME_BOARD_TITLE"), 36, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(112, 238)
	title.size = Vector2(676, 52)
	content_layer.add_child(title)

	_sketch_panel(Vector2(150, 326), Vector2(600, 104), Color("#fff7d6"), false, Color("#1d1d1d"))
	product_label = _outlined_label("", 34, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	product_label.position = Vector2(176, 344)
	product_label.size = Vector2(548, 68)
	content_layer.add_child(product_label)

	option_buttons.clear()
	for index in range(3):
		var button := make_button("", 25, Color("#ffef5f"))
		button.position = Vector2(110 + index * 236, 504)
		button.size = Vector2(196, 76)
		button.pressed.connect(_on_button_pressed.bind(button))
		content_layer.add_child(button)
		option_buttons.append(button)

	var face := make_sprite("res://assets/sprites/elon_face.png", Vector2(140, 132))
	face.position = Vector2(974, 248)
	content_layer.add_child(face)

	var side_title := _outlined_label(tr("RENAME_SIDE_TITLE"), 30, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(918, 390)
	side_title.size = Vector2(250, 46)
	content_layer.add_child(side_title)

	rename_bar = ProgressBar.new()
	rename_bar.position = Vector2(930, 460)
	rename_bar.size = Vector2(230, 30)
	rename_bar.min_value = 0
	rename_bar.max_value = TARGET_RENAMES
	rename_bar.show_percentage = false
	content_layer.add_child(rename_bar)

	verdict_label = _outlined_label("", 25, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(922, 520)
	verdict_label.size = Vector2(246, 54)
	content_layer.add_child(verdict_label)

func _next_product() -> void:
	if rename_count >= TARGET_RENAMES:
		await finish_with_result(true, "RENAME_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(PRODUCTS.size()):
			queue.append(index)
		queue.shuffle()

	current_product = queue.pop_back()
	var data: Dictionary = PRODUCTS[current_product]
	product_label.text = tr(data["old_key"])
	var options: Array[String] = [String(data["new_key"])]
	for wrong_key in data["wrong"]:
		options.append(String(wrong_key))
	options.shuffle()
	for index in range(option_buttons.size()):
		option_buttons[index].text = tr(options[index])
		option_buttons[index].set_meta("name_key", options[index])

func _on_button_pressed(button: Button) -> void:
	_on_option_pressed(String(button.get_meta("name_key")))

func _on_option_pressed(name_key: String) -> void:
	if not running or current_product < 0:
		return
	var data: Dictionary = PRODUCTS[current_product]
	if name_key == String(data["new_key"]):
		rename_count += 1
		score = rename_count
		rename_bar.value = rename_count
		verdict_label.text = tr("RENAME_GOOD")
		verdict_label.add_theme_color_override("font_color", Color("#11883a"))
	else:
		mistakes += 1
		verdict_label.text = tr("RENAME_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#d91e18"))
		_shake(product_label)
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "RENAME_FAIL", 0.6)
			return
	_update_status()
	_next_product()

func _set_buttons_enabled(enabled: bool) -> void:
	for button in option_buttons:
		button.disabled = not enabled

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.04)
	tween.tween_property(node, "position:x", original.x + 10, 0.04)
	tween.tween_property(node, "position", original, 0.05)

func _update_status() -> void:
	set_status(tr("RENAME_STATUS") % [rename_count, TARGET_RENAMES, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
	content_layer.add_child(panel)
	return panel

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(rename_count >= TARGET_RENAMES, "RENAME_TIMEOUT_SUCCESS" if rename_count >= TARGET_RENAMES else "RENAME_TIMEOUT_FAIL", 0.45)
