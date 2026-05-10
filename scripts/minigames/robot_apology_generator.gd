extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const PARTS := [
	{"kind": "safety", "label": "APOLOGY_PART_SAFETY"},
	{"kind": "iteration", "label": "APOLOGY_PART_ITERATION"},
	{"kind": "alignment", "label": "APOLOGY_PART_ALIGNMENT"},
	{"kind": "learning", "label": "APOLOGY_PART_LEARNING"}
]
const DECOYS := [
	{"kind": "blame", "label": "APOLOGY_PART_BLAME"},
	{"kind": "vibes", "label": "APOLOGY_PART_VIBES"},
	{"kind": "silence", "label": "APOLOGY_PART_SILENCE"},
	{"kind": "legal", "label": "APOLOGY_PART_LEGAL"}
]
const MISTAKE_LIMIT := 3

var current_slot := 0
var mistakes := 0
var card_buttons: Array[Button] = []
var slot_labels: Array[Label] = []
var verdict_label: Label
var apology_bar: ProgressBar

func _ready() -> void:
	configure("GAME_APOLOGY_TITLE", "APOLOGY_INSTRUCTIONS", "GAME_APOLOGY_DESC", "res://assets/sprites/hungry_model.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_slot = 0
	mistakes = 0
	score = 0
	apology_bar.value = 0
	for label in slot_labels:
		label.text = tr("APOLOGY_EMPTY_SLOT")
		label.add_theme_color_override("font_color", Color("#3d3d3d"))
	verdict_label.text = tr("APOLOGY_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#151515"))
	_deal_cards()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_3:
		var index := int(event.keycode - KEY_1)
		if index >= 0 and index < card_buttons.size():
			_on_card_pressed(String(card_buttons[index].get_meta("kind")))

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fbf7eb")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(76, 214), Vector2(770, 408), Color("#fffdf8"), true)
	_sketch_panel(Vector2(890, 214), Vector2(306, 408), Color("#f1f8ff"), false)

	var title := _outlined_label(tr("APOLOGY_BOARD_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(118, 236)
	title.size = Vector2(686, 52)
	content_layer.add_child(title)

	card_buttons.clear()
	for index in range(3):
		var button := make_button("", 22, Color("#fff7c7"))
		button.position = Vector2(120 + index * 232, 326)
		button.size = Vector2(196, 82)
		button.pressed.connect(_on_button_pressed.bind(button))
		content_layer.add_child(button)
		card_buttons.append(button)

	slot_labels.clear()
	for index in range(PARTS.size()):
		var slot := _outlined_label("", 20, Color("#3d3d3d"), HORIZONTAL_ALIGNMENT_CENTER)
		slot.position = Vector2(122 + index * 174, 486)
		slot.size = Vector2(150, 58)
		content_layer.add_child(slot)
		slot_labels.append(slot)

	_icon("robot", Vector2(940, 252), Vector2(90, 86), Color("#91c9e8"))
	var side_title := _outlined_label(tr("APOLOGY_SIDE_TITLE"), 27, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(1028, 260)
	side_title.size = Vector2(132, 58)
	content_layer.add_child(side_title)

	apology_bar = ProgressBar.new()
	apology_bar.position = Vector2(928, 370)
	apology_bar.size = Vector2(230, 30)
	apology_bar.min_value = 0
	apology_bar.max_value = PARTS.size()
	apology_bar.show_percentage = false
	content_layer.add_child(apology_bar)

	verdict_label = _outlined_label("", 24, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(920, 452)
	verdict_label.size = Vector2(246, 86)
	content_layer.add_child(verdict_label)

func _deal_cards() -> void:
	if current_slot >= PARTS.size():
		await finish_with_result(true, "APOLOGY_SUCCESS", 0.7)
		return
	var options: Array[Dictionary] = [PARTS[current_slot]]
	var decoy_indices: Array[int] = []
	for index in range(DECOYS.size()):
		decoy_indices.append(index)
	decoy_indices.shuffle()
	options.append(DECOYS[decoy_indices[0]])
	options.append(DECOYS[decoy_indices[1]])
	options.shuffle()

	for index in range(card_buttons.size()):
		var data: Dictionary = options[index]
		card_buttons[index].text = tr(data["label"])
		card_buttons[index].set_meta("kind", data["kind"])

func _on_button_pressed(button: Button) -> void:
	_on_card_pressed(String(button.get_meta("kind")))

func _on_card_pressed(kind: String) -> void:
	if not running or current_slot >= PARTS.size():
		return
	var expected := String(PARTS[current_slot]["kind"])
	if kind == expected:
		slot_labels[current_slot].text = tr(PARTS[current_slot]["label"])
		slot_labels[current_slot].add_theme_color_override("font_color", Color("#11883a"))
		current_slot += 1
		score = current_slot
		apology_bar.value = current_slot
		verdict_label.text = tr("APOLOGY_GOOD")
		verdict_label.add_theme_color_override("font_color", Color("#11883a"))
		if current_slot >= PARTS.size():
			await finish_with_result(true, "APOLOGY_SUCCESS", 0.7)
			return
		_deal_cards()
	else:
		mistakes += 1
		verdict_label.text = tr("APOLOGY_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#d91e18"))
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "APOLOGY_FAIL", 0.6)
			return
	_update_status()

func _update_status() -> void:
	set_status(tr("APOLOGY_STATUS") % [current_slot, PARTS.size(), mistakes])

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
	await finish_with_result(current_slot >= PARTS.size(), "APOLOGY_TIMEOUT_SUCCESS" if current_slot >= PARTS.size() else "APOLOGY_TIMEOUT_FAIL", 0.45)
