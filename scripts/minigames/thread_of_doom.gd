extends "res://scripts/minigames/base_minigame.gd"

const BG_PATH := "res://assets/art/chrome_ram_bg.png"
const TAB_COUNT := 20
const ACTIVE_COLOR := Color("#dff8ff")
const TAB_COLOR := Color("#fff7c7")
const CLOSED_COLOR := Color("#d6d0be")
const DANGER_COLOR := Color("#ff5b5b")
const OK_COLOR := Color("#66f28b")

var active_tab := 0
var closed_count := 0
var panic := false
var pulse := 0.0
var tabs: Array[Button] = []
var closed_tabs: Array[bool] = []
var ram_bar: ProgressBar
var speech_label: Label
var message_box: PanelContainer
var message_lines: Array[Line2D] = []
var computer_face: PanelContainer
var alarm_overlay: ColorRect

func _ready() -> void:
	configure("GAME_THREAD_TITLE", "THREAD_INSTRUCTIONS", "GAME_THREAD_DESC", BG_PATH)
	super._ready()
	hide_common_minigame_header()
	hide_base_status()
	_hide_base_header_panel()
	if tutorial_panel:
		tutorial_panel.visible = false
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	active_tab = randi_range(0, TAB_COUNT - 1)
	closed_count = 0
	panic = false
	score = 0
	closed_tabs.clear()
	for _index in range(TAB_COUNT):
		closed_tabs.append(false)
	_reset_tabs()
	_update_ram()
	_set_speech("THREAD_RAM_PANIC", DANGER_COLOR)
	_set_message_visible(true)
	alarm_overlay.visible = false

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	pulse += delta * 8.0
	for index in range(tabs.size()):
		var tab := tabs[index]
		if index == active_tab and tab.visible:
			tab.scale = Vector2.ONE * (1.0 + sin(pulse) * 0.025)
	_update_message_wiggle()

func _build_stage() -> void:
	_build_browser_interaction()
	_build_computer_status()

	alarm_overlay = ColorRect.new()
	alarm_overlay.position = Vector2.ZERO
	alarm_overlay.size = Vector2(1280, 720)
	alarm_overlay.color = Color("#ff000000")
	alarm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alarm_overlay.z_index = 50
	content_layer.add_child(alarm_overlay)

func _build_browser_interaction() -> void:
	tabs.clear()
	var start := Vector2(86, 146)
	var tab_size := Vector2(72, 36)
	for index in range(TAB_COUNT):
		var col := index % 10
		var row := index / 10
		var tab := make_button("x", 24, TAB_COLOR)
		tab.position = start + Vector2(col * 78, row * 44)
		tab.size = tab_size
		tab.z_index = 10
		tab.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		tab.pressed.connect(_close_tab.bind(index))
		content_layer.add_child(tab)
		tabs.append(tab)

	message_box = PanelContainer.new()
	message_box.position = Vector2(172, 344)
	message_box.size = Vector2(566, 142)
	message_box.add_theme_stylebox_override("panel", make_style(Color("#e9fff8"), Color("#151515"), 5, 10))
	content_layer.add_child(message_box)

	for row in range(4):
		var y := 374.0 + row * 29.0
		for col in range(6):
			var line := Line2D.new()
			line.width = 5.0
			line.default_color = [Color("#151515"), Color("#1f7ad1"), Color("#ff5fa8")][(row + col) % 3]
			line.points = PackedVector2Array([
				Vector2(212 + col * 78, y),
				Vector2(258 + col * 78, y + randf_range(-8.0, 8.0))
			])
			line.z_index = 8
			content_layer.add_child(line)
			message_lines.append(line)

func _build_computer_status() -> void:
	computer_face = PanelContainer.new()
	computer_face.position = Vector2(970, 250)
	computer_face.size = Vector2(200, 140)
	computer_face.add_theme_stylebox_override("panel", make_style(Color("#1b2d3b"), Color("#151515"), 5, 10))
	content_layer.add_child(computer_face)

	_add_eye(Vector2(1010, 300))
	_add_eye(Vector2(1095, 300))
	var mouth := Line2D.new()
	mouth.width = 7.0
	mouth.default_color = Color("#ff5b5b")
	mouth.points = PackedVector2Array([Vector2(1038, 360), Vector2(1070, 346), Vector2(1110, 360)])
	mouth.z_index = 9
	content_layer.add_child(mouth)

	ram_bar = ProgressBar.new()
	ram_bar.position = Vector2(972, 430)
	ram_bar.size = Vector2(196, 28)
	ram_bar.max_value = TAB_COUNT
	ram_bar.show_percentage = false
	content_layer.add_child(ram_bar)

	speech_label = make_label("", 24, DANGER_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	speech_label.position = Vector2(918, 464)
	speech_label.size = Vector2(310, 74)
	speech_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	speech_label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(speech_label)

func _add_eye(pos: Vector2) -> void:
	var eye := PanelContainer.new()
	eye.position = pos
	eye.size = Vector2(35, 38)
	eye.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#151515"), 4, 12))
	content_layer.add_child(eye)
	var pupil := ColorRect.new()
	pupil.position = pos + Vector2(14, 12)
	pupil.size = Vector2(11, 15)
	pupil.color = Color("#151515")
	content_layer.add_child(pupil)

func _reset_tabs() -> void:
	for index in range(tabs.size()):
		var tab := tabs[index]
		tab.visible = true
		tab.disabled = false
		tab.scale = Vector2.ONE
		tab.modulate = Color.WHITE
		tab.text = "x"
		_set_tab_style(tab, ACTIVE_COLOR if index == active_tab else TAB_COLOR)

func _close_tab(index: int) -> void:
	if not running or panic or index < 0 or index >= tabs.size() or closed_tabs[index]:
		return

	if index == active_tab:
		_lose_message()
		return

	closed_tabs[index] = true
	closed_count += 1
	score = closed_count
	play_action_sound("collect")
	var tab := tabs[index]
	_set_tab_style(tab, CLOSED_COLOR)
	tab.disabled = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(tab, "scale", Vector2(0.08, 0.08), 0.12)
	tween.tween_property(tab, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(func() -> void: tab.visible = false)
	_update_ram()

	if closed_count >= TAB_COUNT - 1:
		_set_speech("THREAD_SUCCESS", OK_COLOR)
		await get_tree().create_timer(0.35).timeout
		await finish_with_result(true, "THREAD_SUCCESS", 0.35)

func _lose_message() -> void:
	panic = true
	play_action_sound("bad")
	_set_message_visible(false)
	_set_speech("THREAD_LOST_MESSAGE", DANGER_COLOR)
	alarm_overlay.visible = true
	var tween := create_tween()
	tween.set_loops(4)
	tween.tween_property(alarm_overlay, "color", Color("#ff000055"), 0.09)
	tween.tween_property(alarm_overlay, "color", Color("#ff000000"), 0.09)
	await get_tree().create_timer(0.72).timeout
	await finish_with_result(false, "THREAD_FAIL", 0.45)

func _update_ram() -> void:
	if ram_bar:
		ram_bar.value = TAB_COUNT - closed_count
		ram_bar.modulate = Color("#ff7777") if closed_count < 10 else Color("#fff06a") if closed_count < 17 else OK_COLOR

func _set_speech(key: String, color: Color) -> void:
	speech_label.text = tr(key)
	speech_label.add_theme_color_override("font_color", color)

func _set_message_visible(visible: bool) -> void:
	if message_box:
		message_box.visible = visible
	for line in message_lines:
		line.visible = visible

func _update_message_wiggle() -> void:
	for index in range(message_lines.size()):
		var line := message_lines[index]
		line.position.x = sin(pulse * 0.7 + float(index)) * 1.8

func _set_tab_style(tab: Button, fill: Color) -> void:
	tab.add_theme_stylebox_override("normal", make_style(fill, Color("#151515"), 3, 7))
	tab.add_theme_stylebox_override("hover", make_style(fill.lightened(0.13), Color("#151515"), 3, 7))
	tab.add_theme_stylebox_override("pressed", make_style(fill.darkened(0.10), Color("#151515"), 3, 7))

func _hide_base_header_panel() -> void:
	if not title_label:
		return
	var node: Node = title_label
	for _step in range(3):
		node = node.get_parent()
		if not node:
			return
	if node is Control:
		(node as Control).visible = false

func on_timeout() -> void:
	await finish_with_result(closed_count >= TAB_COUNT - 1, "THREAD_SUCCESS" if closed_count >= TAB_COUNT - 1 else "THREAD_TIMEOUT_FAIL", 0.45)
