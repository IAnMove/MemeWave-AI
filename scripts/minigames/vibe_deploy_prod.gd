extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_DECISIONS := 7
const MISTAKE_LIMIT := 3
const CARDS := [
	{"key": "VIBE_DEPLOY_LOCAL_TESTED", "safe": true},
	{"key": "VIBE_DEPLOY_LOGS_READY", "safe": true},
	{"key": "VIBE_DEPLOY_ROLLBACK", "safe": true},
	{"key": "VIBE_DEPLOY_SMALL_FIX", "safe": true},
	{"key": "VIBE_DEPLOY_MY_MACHINE", "safe": false},
	{"key": "VIBE_DEPLOY_NO_LOGS", "safe": false},
	{"key": "VIBE_DEPLOY_WE_WILL_SEE", "safe": false},
	{"key": "VIBE_DEPLOY_FRIDAY", "safe": false},
	{"key": "VIBE_DEPLOY_MAIN_DIRECT", "safe": false}
]

var queue: Array[int] = []
var current_card := -1
var handled := 0
var mistakes := 0
var card_panel: Control
var card_label: Label
var verdict_label: Label
var server_label: Label
var server_icon: Control
var deploy_button: Button
var block_button: Button
var pips: Array[ColorRect] = []

func _ready() -> void:
	configure("GAME_VIBE_DEPLOY_TITLE", "VIBE_DEPLOY_INSTRUCTIONS", "GAME_VIBE_DEPLOY_DESC", "res://assets/art/deploy_friday_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(CARDS.size()):
		queue.append(index)
	queue.shuffle()
	current_card = -1
	handled = 0
	mistakes = 0
	score = 0
	verdict_label.text = tr("VIBE_DEPLOY_IDLE")
	verdict_label.add_theme_color_override("font_color", Color("#151515"))
	_set_server("computer_good", "VIBE_DEPLOY_SERVER_IDLE", Color("#11883a"))
	_reset_pips()
	_set_buttons_enabled(true)
	_next_card()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_on_action_pressed("deploy")
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		get_viewport().set_input_as_handled()
		_on_action_pressed("block")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fbf7eb")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(76, 212), Vector2(770, 412), Color("#fffdf8"), true)
	_sketch_panel(Vector2(890, 212), Vector2(306, 412), Color("#fff2e8"), false)

	var title := _outlined_label(tr("VIBE_DEPLOY_QUEUE_TITLE"), 36, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(118, 234)
	title.size = Vector2(686, 52)
	content_layer.add_child(title)

	card_panel = _sketch_panel(Vector2(182, 318), Vector2(558, 120), Color("#eef7ff"), false, Color("#1f5fbf"))
	card_label = _outlined_label("", 32, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	card_label.position = Vector2(212, 336)
	card_label.size = Vector2(498, 82)
	content_layer.add_child(card_label)

	block_button = make_button(tr("VIBE_DEPLOY_BLOCK"), 30, Color("#ffe0dc"))
	block_button.position = Vector2(140, 500)
	block_button.size = Vector2(292, 78)
	block_button.pressed.connect(_on_action_pressed.bind("block"))
	content_layer.add_child(block_button)

	deploy_button = make_button(tr("VIBE_DEPLOY_SHIP"), 30, Color("#dff8da"))
	deploy_button.position = Vector2(496, 500)
	deploy_button.size = Vector2(292, 78)
	deploy_button.pressed.connect(_on_action_pressed.bind("deploy"))
	content_layer.add_child(deploy_button)

	var side_title := _outlined_label(tr("VIBE_DEPLOY_PROD_TITLE"), 31, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(918, 236)
	side_title.size = Vector2(250, 50)
	content_layer.add_child(side_title)

	server_icon = _icon("computer_good", Vector2(954, 308), Vector2(178, 136), Color("#dff8da"))
	server_label = _outlined_label("", 25, Color("#11883a"), HORIZONTAL_ALIGNMENT_CENTER)
	server_label.position = Vector2(924, 480)
	server_label.size = Vector2(238, 72)
	content_layer.add_child(server_label)

	verdict_label = _outlined_label("", 24, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(924, 552)
	verdict_label.size = Vector2(238, 46)
	content_layer.add_child(verdict_label)

	for index in range(TARGET_DECISIONS):
		var pip := ColorRect.new()
		pip.position = Vector2(916 + index * 34, 456)
		pip.size = Vector2(22, 14)
		pip.color = Color("#d9d9d9")
		content_layer.add_child(pip)
		pips.append(pip)

func _next_card() -> void:
	if handled >= TARGET_DECISIONS:
		await finish_with_result(true, "VIBE_DEPLOY_SUCCESS", 0.7)
		return
	if queue.is_empty():
		for index in range(CARDS.size()):
			queue.append(index)
		queue.shuffle()
	current_card = queue.pop_back()
	card_label.text = tr(CARDS[current_card]["key"])
	_deal_card()

func _deal_card() -> void:
	if not card_panel:
		return
	card_panel.position = Vector2(182, 268)
	card_panel.modulate = Color(1, 1, 1, 0)
	card_label.position = Vector2(212, 286)
	card_label.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.parallel().tween_property(card_panel, "position", Vector2(182, 318), 0.12)
	tween.parallel().tween_property(card_panel, "modulate", Color.WHITE, 0.12)
	tween.parallel().tween_property(card_label, "position", Vector2(212, 336), 0.12)
	tween.parallel().tween_property(card_label, "modulate", Color.WHITE, 0.12)

func _on_action_pressed(action: String) -> void:
	if not running or current_card < 0:
		return

	var data: Dictionary = CARDS[current_card]
	var safe := bool(data["safe"])
	var correct := (action == "deploy") == safe
	if correct:
		handled += 1
		score = handled
		_mark_pip(handled - 1, Color("#63d471"))
		verdict_label.text = tr("VIBE_DEPLOY_GOOD")
		verdict_label.add_theme_color_override("font_color", Color("#11883a"))
		_set_server("computer_good", "VIBE_DEPLOY_SERVER_OK" if safe else "VIBE_DEPLOY_SERVER_BLOCKED", Color("#11883a"))
	else:
		mistakes += 1
		verdict_label.text = tr("VIBE_DEPLOY_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#d91e18"))
		_set_server("computer_bad", "VIBE_DEPLOY_SERVER_FIRE" if action == "deploy" else "VIBE_DEPLOY_SERVER_WASTED", Color("#d91e18"))
		_shake(card_label)
		if mistakes >= MISTAKE_LIMIT:
			await finish_with_result(false, "VIBE_DEPLOY_FAIL", 0.65)
			return

	_update_status()
	_next_card()

func _set_server(icon_name: String, text_key: String, text_color: Color) -> void:
	if server_icon:
		server_icon.call("configure", icon_name, Color("#444444") if icon_name == "computer_bad" else Color("#dff8da"), Color("#ffffff"))
	if server_label:
		server_label.text = tr(text_key)
		server_label.add_theme_color_override("font_color", text_color)

func _mark_pip(index: int, color: Color) -> void:
	if index >= 0 and index < pips.size():
		pips[index].color = color

func _reset_pips() -> void:
	for pip in pips:
		pip.color = Color("#d9d9d9")

func _set_buttons_enabled(enabled: bool) -> void:
	if deploy_button:
		deploy_button.disabled = not enabled
	if block_button:
		block_button.disabled = not enabled

func _shake(node: Control) -> void:
	var original := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original.x - 10, 0.04)
	tween.tween_property(node, "position:x", original.x + 10, 0.04)
	tween.tween_property(node, "position", original, 0.05)

func _update_status() -> void:
	set_status(tr("VIBE_DEPLOY_STATUS") % [handled, TARGET_DECISIONS, mistakes])

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
	var success := handled >= TARGET_DECISIONS
	await finish_with_result(success, "VIBE_DEPLOY_TIMEOUT_SUCCESS" if success else "VIBE_DEPLOY_TIMEOUT_FAIL", 0.45)
