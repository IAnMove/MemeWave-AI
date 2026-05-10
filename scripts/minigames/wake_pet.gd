extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_WAKE := 6
const MISTAKE_LIMIT := 3
const ITEMS := [
	{"key": "WAKE_PET_ALARM", "wake": true},
	{"key": "WAKE_PET_COFFEE", "wake": true},
	{"key": "WAKE_PET_TOKEN_SNACK", "wake": true},
	{"key": "WAKE_PET_SUNBEAM", "wake": true},
	{"key": "WAKE_PET_DEBUG_WALK", "wake": true},
	{"key": "WAKE_PET_BLANKET", "wake": false},
	{"key": "WAKE_PET_LULLABY", "wake": false},
	{"key": "WAKE_PET_SNOOZE", "wake": false},
	{"key": "WAKE_PET_WARM_CACHE", "wake": false}
]

var queue: Array[int] = []
var current_item := -1
var wake_level := 0
var handled := 0
var mistakes := 0
var item_label: Label
var pet_label: Label
var verdict_label: Label
var wake_bar: ProgressBar
var use_button: Button
var tuck_button: Button
var pet_icon: Control
var pips: Array[ColorRect] = []

func _ready() -> void:
	configure("GAME_WAKE_PET_TITLE", "WAKE_PET_INSTRUCTIONS", "GAME_WAKE_PET_DESC", "res://assets/sprites/hungry_model.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(ITEMS.size()):
		queue.append(index)
	queue.shuffle()
	current_item = -1
	wake_level = 0
	handled = 0
	mistakes = 0
	score = 0
	wake_bar.value = 0
	_set_pet_state(false)
	_reset_pips()
	_set_buttons_enabled(true)
	verdict_label.text = tr("WAKE_PET_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#151515"))
	_next_item()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_on_choice_pressed("use")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		get_viewport().set_input_as_handled()
		_on_choice_pressed("tuck")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#eef3f8")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(74, 216), Vector2(770, 408), Color("#fffdf8"), true)
	_sketch_panel(Vector2(888, 216), Vector2(310, 408), Color("#fff7d6"), false)

	_icon("spark", Vector2(116, 244), Vector2(50, 50), Color("#ffca3a"))
	var title := _outlined_label(tr("WAKE_PET_BOARD_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(178, 238)
	title.size = Vector2(610, 58)
	content_layer.add_child(title)

	_sketch_panel(Vector2(144, 330), Vector2(620, 108), Color("#f8fbff"), false, Color("#1f5fbf"))
	item_label = _outlined_label("", 31, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	item_label.position = Vector2(168, 346)
	item_label.size = Vector2(572, 74)
	content_layer.add_child(item_label)

	tuck_button = make_button(tr("WAKE_PET_TUCK"), 28, Color("#e8f1ff"))
	tuck_button.position = Vector2(144, 504)
	tuck_button.size = Vector2(288, 76)
	tuck_button.pressed.connect(_on_choice_pressed.bind("tuck"))
	content_layer.add_child(tuck_button)

	use_button = make_button(tr("WAKE_PET_USE"), 28, Color("#dff8da"))
	use_button.position = Vector2(496, 504)
	use_button.size = Vector2(288, 76)
	use_button.pressed.connect(_on_choice_pressed.bind("use"))
	content_layer.add_child(use_button)

	pet_icon = _icon("robot", Vector2(966, 258), Vector2(152, 128), Color("#8c91a1"))
	pet_label = _outlined_label("", 26, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	pet_label.position = Vector2(922, 398)
	pet_label.size = Vector2(240, 44)
	content_layer.add_child(pet_label)

	wake_bar = ProgressBar.new()
	wake_bar.position = Vector2(928, 464)
	wake_bar.size = Vector2(230, 30)
	wake_bar.min_value = 0
	wake_bar.max_value = TARGET_WAKE
	wake_bar.show_percentage = false
	content_layer.add_child(wake_bar)

	for index in range(MISTAKE_LIMIT):
		var pip := ColorRect.new()
		pip.position = Vector2(956 + index * 54, 506)
		pip.size = Vector2(36, 14)
		pip.color = Color("#d6d0be")
		content_layer.add_child(pip)
		pips.append(pip)

	verdict_label = _outlined_label("", 24, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(920, 542)
	verdict_label.size = Vector2(246, 48)
	content_layer.add_child(verdict_label)

func _next_item() -> void:
	if wake_level >= TARGET_WAKE:
		await finish_with_result(true, "WAKE_PET_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(ITEMS.size()):
			queue.append(index)
		queue.shuffle()
	current_item = queue.pop_back()
	item_label.text = tr(ITEMS[current_item]["key"])

func _on_choice_pressed(action: String) -> void:
	if not running or current_item < 0:
		return

	var item: Dictionary = ITEMS[current_item]
	var wakes_pet := bool(item["wake"])
	var correct := (action == "use") == wakes_pet
	handled += 1

	if correct and wakes_pet:
		wake_level += 1
		score = wake_level
		wake_bar.value = wake_level
		verdict_label.text = tr("WAKE_PET_GOOD_WAKE")
		verdict_label.add_theme_color_override("font_color", Color("#11883a"))
		_set_pet_state(wake_level >= TARGET_WAKE)
	elif correct:
		verdict_label.text = tr("WAKE_PET_GOOD_TUCK")
		verdict_label.add_theme_color_override("font_color", Color("#1f5fbf"))
	else:
		mistakes += 1
		wake_level = max(0, wake_level - 1)
		wake_bar.value = wake_level
		_mark_mistake()
		verdict_label.text = tr("WAKE_PET_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#d91e18"))
		_set_pet_state(false)
		_shake(item_label)
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "WAKE_PET_FAIL", 0.6)
			return

	_update_status()
	_next_item()

func _set_pet_state(awake: bool) -> void:
	if pet_icon:
		pet_icon.call("configure", "robot", Color("#bdfb7f") if awake else Color("#8c91a1"), Color("#ffffff"))
	if pet_label:
		pet_label.text = tr("WAKE_PET_AWAKE") if awake else tr("WAKE_PET_ASLEEP")

func _mark_mistake() -> void:
	var index := int(clamp(mistakes - 1, 0, pips.size() - 1))
	if index >= 0 and index < pips.size():
		pips[index].color = Color("#ff5b5b")

func _reset_pips() -> void:
	for pip in pips:
		pip.color = Color("#d6d0be")

func _set_buttons_enabled(enabled: bool) -> void:
	if use_button:
		use_button.disabled = not enabled
	if tuck_button:
		tuck_button.disabled = not enabled

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.04)
	tween.tween_property(node, "position:x", original.x + 10, 0.04)
	tween.tween_property(node, "position", original, 0.05)

func _update_status() -> void:
	set_status(tr("WAKE_PET_STATUS") % [wake_level, TARGET_WAKE, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111")) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, 4.0, 1.5, hatch, Color("#0000000b"))
	content_layer.add_child(panel)
	return panel

func _icon(name: String, pos: Vector2, icon_size: Vector2, color: Color) -> Control:
	var icon: Control = SketchIcon.new()
	icon.position = pos
	icon.size = icon_size
	icon.call("configure", name, color, Color("#ffffff"))
	content_layer.add_child(icon)
	return icon

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func on_timeout() -> void:
	await finish_with_result(wake_level >= TARGET_WAKE, "WAKE_PET_TIMEOUT_SUCCESS" if wake_level >= TARGET_WAKE else "WAKE_PET_TIMEOUT_FAIL", 0.45)
