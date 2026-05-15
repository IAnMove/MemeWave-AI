extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TAB_COUNT := 12
const TAB_STRIP_POS := Vector2(72, 130)
const TAB_STRIP_WIDTH := 980.0
const TAB_STRIP_HEIGHT := 40.0
const TAB_GAP := 4.0
const ACTIVE_TAB_WEIGHT := 2.4
const CHROME_TOP := Color("#202124")
const CHROME_TOOLBAR := Color("#2f3035")
const CHROME_TAB := Color("#24262d")
const CHROME_ACTIVE_TAB := Color("#3c4043")
const CHROME_OMNIBOX := Color("#202124")
const CHROME_TEXT := Color("#f1f3f4")
const DANGER_COLOR := Color("#ff5b5b")
const OK_COLOR := Color("#66f28b")
const BROWSER_COMPUTER_BAD_PATH := "res://assets/sprites/browser_computer_bad.png"
const BROWSER_COMPUTER_GOOD_PATH := "res://assets/sprites/browser_computer_good.png"

const ACTIVE_TAB := {
	"title": "PROMPT",
	"icon": "AI",
	"color": "#ffcf22"
}

const JUNK_TABS := [
	{"title": "YouTube", "icon": "YT", "color": "#ff3030"},
	{"title": "GitHub", "icon": "GH", "color": "#f4f4f4"},
	{"title": "Reddit", "icon": "RD", "color": "#ff7a2d"},
	{"title": "Docs", "icon": "D", "color": "#66c6ff"},
	{"title": "Mail", "icon": "M", "color": "#fff06a"},
	{"title": "Stack", "icon": "SO", "color": "#ffb84a"},
	{"title": "Bench", "icon": "B", "color": "#a98cff"},
	{"title": "News", "icon": "N", "color": "#f4f4f4"},
	{"title": "Charts", "icon": "$", "color": "#66f28b"},
	{"title": "Cloud", "icon": "C", "color": "#8ae8ff"},
	{"title": "Issue", "icon": "!", "color": "#ff9fb5"},
	{"title": "Feed", "icon": "F", "color": "#ffb84a"},
	{"title": "Search", "icon": "G", "color": "#ffffff"},
	{"title": "Deploy", "icon": ">", "color": "#ffcf22"},
	{"title": "Metrics", "icon": "%", "color": "#dff8da"},
	{"title": "Chat", "icon": "#", "color": "#d7c6ff"},
	{"title": "Todo", "icon": "T", "color": "#fff7c7"},
	{"title": "Spec", "icon": "S", "color": "#dff8ff"},
	{"title": "Blog", "icon": "P", "color": "#ff9fb5"}
]

var active_tab := 0
var closed_count := 0
var panic := false
var pulse := 0.0
var tab_data: Array = []
var tabs: Array[Button] = []
var tab_close_buttons: Array[Button] = []
var closed_tabs: Array[bool] = []
var tab_icons: Array[PanelContainer] = []
var tab_icon_labels: Array[Label] = []
var tab_title_labels: Array[Label] = []
var message_box: Control
var message_items: Array[CanvasItem] = []
var page_title: Label
var page_subtitle: Label
var status_chip: Label
var ram_bar: ProgressBar
var ram_label: Label
var ram_percent_label: Label
var alarm_label: Label
var speech_label: Label
var computer_icon: Control
var alarm_overlay: ColorRect

func _ready() -> void:
	configure("GAME_THREAD_TITLE", "THREAD_INSTRUCTIONS", "GAME_THREAD_DESC", "")
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
	_assign_tab_data()
	_reset_tabs()
	_update_ram()
	_set_speech("THREAD_RAM_PANIC", DANGER_COLOR)
	_set_message_visible(true)
	status_chip.text = tr("THREAD_BROWSER_GOAL")
	alarm_overlay.visible = false

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	pulse += delta * 8.0
	_update_active_tab_pulse()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fbf7eb")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(bg)

	_sketch_panel(Vector2(42, 104), Vector2(1196, 536), Color("#fffdf8"), false, Color("#111111"), 5.0, 1)
	_make_plain_panel(Vector2(58, 118), Vector2(1164, 74), CHROME_TOP, Color("#111111"), 5, 10, 2)
	_build_browser_interaction()
	_build_page()
	_build_ram_status()

	alarm_overlay = ColorRect.new()
	alarm_overlay.position = Vector2.ZERO
	alarm_overlay.size = Vector2(1280, 720)
	alarm_overlay.color = Color("#ff000000")
	alarm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alarm_overlay.z_index = 50
	content_layer.add_child(alarm_overlay)

func _build_browser_interaction() -> void:
	tabs.clear()
	tab_icons.clear()
	tab_icon_labels.clear()
	tab_title_labels.clear()
	tab_close_buttons.clear()

	for index in range(TAB_COUNT):
		var tab := Button.new()
		tab.text = ""
		tab.focus_mode = Control.FOCUS_NONE
		tab.clip_contents = true
		tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tab.z_index = 10
		content_layer.add_child(tab)
		tabs.append(tab)

		var icon := PanelContainer.new()
		icon.position = Vector2(7, 10)
		icon.size = Vector2(23, 23)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tab.add_child(icon)
		tab_icons.append(icon)

		var icon_label := _outlined_label("", 10, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER, 1)
		icon_label.position = Vector2.ZERO
		icon_label.size = icon.size
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(icon_label)
		tab_icon_labels.append(icon_label)

		var title := _outlined_label("", 12, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT, 1)
		title.position = Vector2(35, 4)
		title.size = Vector2(62, 30)
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tab.add_child(title)
		tab_title_labels.append(title)

		var close := Button.new()
		close.text = "x"
		close.focus_mode = Control.FOCUS_NONE
		close.mouse_filter = Control.MOUSE_FILTER_STOP
		close.add_theme_font_size_override("font_size", 15)
		close.add_theme_color_override("font_color", CHROME_TEXT)
		close.add_theme_color_override("font_hover_color", CHROME_TEXT)
		close.add_theme_color_override("font_pressed_color", CHROME_TEXT)
		close.add_theme_stylebox_override("normal", make_style(Color("#00000000"), Color("#00000000"), 0, 8))
		close.add_theme_stylebox_override("hover", make_style(Color("#5f6368"), Color("#111111"), 1, 8))
		close.add_theme_stylebox_override("pressed", make_style(Color("#ff5b5b"), Color("#111111"), 1, 8))
		close.pressed.connect(_close_tab.bind(index))
		tab.add_child(close)
		tab_close_buttons.append(close)

	var new_tab := _outlined_label("+", 28, Color("#d7d7df"), HORIZONTAL_ALIGNMENT_CENTER, 1)
	new_tab.position = Vector2(1070, 133)
	new_tab.size = Vector2(36, 36)
	content_layer.add_child(new_tab)

	var controls := _outlined_label("-  []  x", 18, Color("#d7d7df"), HORIZONTAL_ALIGNMENT_CENTER, 1)
	controls.position = Vector2(1116, 132)
	controls.size = Vector2(88, 36)
	content_layer.add_child(controls)

	var nav := _make_plain_panel(Vector2(72, 202), Vector2(1136, 50), CHROME_TOOLBAR, Color("#111111"), 4, 10, 3)
	nav.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var back := _outlined_label("<", 28, Color("#d7d7df"), HORIZONTAL_ALIGNMENT_CENTER, 2)
	back.position = Vector2(88, 207)
	back.size = Vector2(30, 38)
	content_layer.add_child(back)

	var forward := _outlined_label(">", 28, Color("#d7d7df"), HORIZONTAL_ALIGNMENT_CENTER, 2)
	forward.position = Vector2(126, 207)
	forward.size = Vector2(30, 38)
	content_layer.add_child(forward)

	var reload := _outlined_label("O", 22, Color("#d7d7df"), HORIZONTAL_ALIGNMENT_CENTER, 2)
	reload.position = Vector2(166, 210)
	reload.size = Vector2(32, 34)
	content_layer.add_child(reload)

	_make_plain_panel(Vector2(216, 211), Vector2(816, 32), CHROME_OMNIBOX, Color("#111111"), 3, 14, 4)
	var url := _outlined_label("memewave.ai/session/prompt-final", 19, CHROME_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 1)
	url.position = Vector2(236, 211)
	url.size = Vector2(760, 32)
	content_layer.add_child(url)

	_add_toolbar_badge(Vector2(1046, 215), "AI", Color("#ffcf22"))
	_add_toolbar_badge(Vector2(1086, 215), "RAM", OK_COLOR)
	status_chip = _outlined_label("", 15, Color("#ffcf22"), HORIZONTAL_ALIGNMENT_CENTER, 2)
	status_chip.position = Vector2(1128, 207)
	status_chip.size = Vector2(74, 38)
	content_layer.add_child(status_chip)

func _build_page() -> void:
	_sketch_panel(Vector2(84, 274), Vector2(744, 292), Color("#eef7ff"), false, Color("#111111"), 5.0, 3)
	page_title = _outlined_label(tr("THREAD_PAGE_TITLE"), 29, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER, 3)
	page_title.position = Vector2(112, 294)
	page_title.size = Vector2(688, 70)
	content_layer.add_child(page_title)

	page_subtitle = _outlined_label(tr("THREAD_KEEP_OPEN"), 22, Color("#1f5fbf"), HORIZONTAL_ALIGNMENT_CENTER, 2)
	page_subtitle.position = Vector2(128, 350)
	page_subtitle.size = Vector2(656, 42)
	content_layer.add_child(page_subtitle)

	message_box = _sketch_panel(Vector2(156, 404), Vector2(602, 108), Color("#fffdf8"), false, Color("#111111"), 4.0, 4)
	message_items.clear()
	var lines := [
		tr("THREAD_PAGE_LINE_1"),
		tr("THREAD_PAGE_LINE_2"),
		tr("THREAD_PAGE_LINE_3")
	]
	for row in range(lines.size()):
		var label := _outlined_label(String(lines[row]), 20, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT, 1)
		label.position = Vector2(196, 420 + row * 28)
		label.size = Vector2(520, 28)
		label.z_index = 7
		content_layer.add_child(label)
		message_items.append(label)

func _build_ram_status() -> void:
	_sketch_panel(Vector2(872, 274), Vector2(300, 340), Color("#fff7c7"), false, Color("#111111"), 5.0, 3)
	var ram_title := _outlined_label("RAM", 42, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER, 3)
	ram_title.position = Vector2(902, 294)
	ram_title.size = Vector2(240, 58)
	content_layer.add_child(ram_title)

	computer_icon = make_sprite(BROWSER_COMPUTER_BAD_PATH, Vector2(170, 130))
	computer_icon.position = Vector2(936, 350)
	computer_icon.size = Vector2(170, 130)
	computer_icon.z_index = 5
	content_layer.add_child(computer_icon)

	ram_bar = ProgressBar.new()
	ram_bar.position = Vector2(920, 488)
	ram_bar.size = Vector2(204, 28)
	ram_bar.max_value = TAB_COUNT
	ram_bar.show_percentage = false
	ram_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ram_bar.add_theme_stylebox_override("background", make_style(Color("#ffffff"), Color("#111111"), 3, 6))
	content_layer.add_child(ram_bar)

	ram_percent_label = _outlined_label("", 20, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER, 2)
	ram_percent_label.position = Vector2(918, 520)
	ram_percent_label.size = Vector2(208, 34)
	content_layer.add_child(ram_percent_label)

	alarm_label = _outlined_label(tr("THREAD_RAM_ALARM"), 18, DANGER_COLOR, HORIZONTAL_ALIGNMENT_CENTER, 3)
	alarm_label.position = Vector2(884, 540)
	alarm_label.size = Vector2(278, 30)
	content_layer.add_child(alarm_label)

	speech_label = _outlined_label("", 15, DANGER_COLOR, HORIZONTAL_ALIGNMENT_CENTER, 3)
	speech_label.position = Vector2(884, 568)
	speech_label.size = Vector2(278, 44)
	content_layer.add_child(speech_label)

func _assign_tab_data() -> void:
	tab_data.clear()
	var pool := JUNK_TABS.duplicate(true)
	pool.shuffle()
	var pool_index := 0
	for index in range(TAB_COUNT):
		if index == active_tab:
			tab_data.append(ACTIVE_TAB.duplicate(true))
		else:
			tab_data.append((pool[pool_index % pool.size()] as Dictionary).duplicate(true))
			pool_index += 1

func _reset_tabs() -> void:
	_layout_tabs()
	for index in range(tabs.size()):
		var tab := tabs[index]
		tab.visible = true
		tab_close_buttons[index].disabled = false
		tab.scale = Vector2.ONE
		tab.rotation = sin(float(index) * 1.73) * 0.006
		tab.modulate = Color.WHITE
		_sync_tab_visual(index)

func _layout_tabs() -> void:
	var open_indexes := _open_tab_indexes()
	if open_indexes.is_empty():
		return

	var total_weight := 0.0
	for index in open_indexes:
		total_weight += ACTIVE_TAB_WEIGHT if index == active_tab else 1.0
	var unit_width := (TAB_STRIP_WIDTH - TAB_GAP * float(open_indexes.size() - 1)) / total_weight
	var cursor_x := TAB_STRIP_POS.x
	for index in open_indexes:
		var width := unit_width * (ACTIVE_TAB_WEIGHT if index == active_tab else 1.0)
		var tab := tabs[index]
		tab.position = Vector2(cursor_x, TAB_STRIP_POS.y)
		tab.size = Vector2(width, TAB_STRIP_HEIGHT)
		tab_icons[index].position = Vector2(9, 9) if index != active_tab else Vector2(10, 9)
		var show_title: bool = index == active_tab or width >= 92.0
		tab_title_labels[index].visible = show_title
		tab_title_labels[index].position = Vector2(40, 4)
		tab_title_labels[index].size = Vector2(maxf(0.0, width - 70.0), 30)
		tab_close_buttons[index].position = Vector2(width - 25.0, 7)
		tab_close_buttons[index].size = Vector2(20, 24)
		cursor_x += width + TAB_GAP

func _open_tab_indexes() -> Array:
	var open_indexes := []
	for index in range(tabs.size()):
		if index < closed_tabs.size() and closed_tabs[index]:
			continue
		open_indexes.append(index)
	return open_indexes

func _sync_tab_visual(index: int) -> void:
	var info: Dictionary = tab_data[index]
	var active := index == active_tab
	var fill := CHROME_ACTIVE_TAB if active else CHROME_TAB
	var border := Color("#5f6368") if active else Color("#111111")
	_set_tab_style(tabs[index], fill, border)
	tab_icon_labels[index].text = String(info.get("icon", "?"))
	tab_title_labels[index].text = String(info.get("title", ""))
	tab_title_labels[index].add_theme_color_override("font_color", CHROME_TEXT)
	tab_close_buttons[index].add_theme_color_override("font_color", CHROME_TEXT)
	tab_close_buttons[index].add_theme_color_override("font_hover_color", CHROME_TEXT)
	tab_close_buttons[index].add_theme_color_override("font_pressed_color", CHROME_TEXT)
	tab_icons[index].add_theme_stylebox_override("panel", make_style(Color(String(info.get("color", "#ffffff"))), Color("#111111"), 2, 12))

func _update_active_tab_pulse() -> void:
	if active_tab < 0 or active_tab >= tabs.size() or closed_tabs[active_tab]:
		return
	var glow := 0.92 + sin(pulse) * 0.08
	tabs[active_tab].modulate = Color(1.0, 1.0, glow, 1.0)

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
	_set_tab_style(tab, Color("#45414a"), Color("#111111"))
	tab_close_buttons[index].disabled = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(tab, "scale", Vector2(0.10, 0.10), 0.12)
	tween.tween_property(tab, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(func() -> void:
		tab.visible = false
		_layout_tabs()
	)
	_update_ram()

	if closed_count >= TAB_COUNT - 1:
		status_chip.text = tr("THREAD_HISTORY_OK")
		_set_speech("THREAD_SUCCESS", OK_COLOR)
		await get_tree().create_timer(0.35).timeout
		await finish_with_result(true, "THREAD_SUCCESS", 0.35)

func _lose_message() -> void:
	panic = true
	play_action_sound("bad")
	_set_message_visible(false)
	page_title.text = tr("THREAD_FAIL")
	page_title.add_theme_color_override("font_color", DANGER_COLOR)
	page_subtitle.text = tr("THREAD_LOST_MESSAGE")
	page_subtitle.add_theme_color_override("font_color", DANGER_COLOR)
	status_chip.text = tr("THREAD_HISTORY_BAD")
	_set_tab_style(tabs[active_tab], Color("#ff5b5b"), Color("#111111"))
	_set_speech("THREAD_LOST_MESSAGE", DANGER_COLOR)
	alarm_overlay.visible = true
	var tween := create_tween()
	tween.set_loops(4)
	tween.tween_property(alarm_overlay, "color", Color("#ff000055"), 0.09)
	tween.tween_property(alarm_overlay, "color", Color("#ff000000"), 0.09)
	await get_tree().create_timer(0.72).timeout
	await finish_with_result(false, "THREAD_FAIL", 0.45)

func _update_ram() -> void:
	if not ram_bar:
		return

	var open_tabs := TAB_COUNT - closed_count
	var percent := roundi(float(open_tabs) * 100.0 / float(TAB_COUNT))
	ram_bar.value = open_tabs
	ram_percent_label.text = "%d%% %s" % [percent, tr("THREAD_RAM_USED")]

	var fill := DANGER_COLOR
	if closed_count >= TAB_COUNT - 1:
		fill = OK_COLOR
	elif closed_count >= ceili(float(TAB_COUNT) * 0.55):
		fill = Color("#fff06a")
	ram_bar.add_theme_stylebox_override("fill", make_style(fill, fill, 0, 5))
	ram_bar.modulate = Color.WHITE

	if computer_icon:
		var path := BROWSER_COMPUTER_GOOD_PATH if closed_count >= TAB_COUNT - 1 else BROWSER_COMPUTER_BAD_PATH
		if ResourceLoader.exists(path) and computer_icon is TextureRect:
			(computer_icon as TextureRect).texture = load(path)

func _set_speech(key: String, color: Color) -> void:
	speech_label.text = tr(key)
	speech_label.add_theme_color_override("font_color", color)

func _set_message_visible(visible: bool) -> void:
	if message_box:
		message_box.visible = visible
	for item in message_items:
		item.visible = visible

func _set_tab_style(tab: Button, fill: Color, border: Color) -> void:
	tab.add_theme_stylebox_override("normal", make_style(fill, border, 3, 12))
	tab.add_theme_stylebox_override("hover", make_style(fill.lightened(0.12), border, 3, 12))
	tab.add_theme_stylebox_override("pressed", make_style(fill.darkened(0.10), border, 3, 12))
	tab.add_theme_stylebox_override("disabled", make_style(fill.darkened(0.15), border, 3, 12))

func _add_toolbar_badge(pos: Vector2, text: String, fill: Color) -> void:
	var badge: Control = SketchPanel.new()
	badge.position = pos
	badge.size = Vector2(34, 24)
	badge.z_index = 5
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_hatch := fill.lightened(0.22)
	badge_hatch.a = 0.26
	badge.call("configure", fill, Color("#111111"), 2.2, 1.3, true, badge_hatch)
	content_layer.add_child(badge)

	var label := _outlined_label(text, 10, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER, 1)
	label.position = Vector2.ZERO
	label.size = badge.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)

func _make_plain_panel(pos: Vector2, panel_size: Vector2, fill: Color, border: Color, border_width: int, _radius: int, z: int) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = z
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hatch_color := fill.lightened(0.34)
	hatch_color.a = 0.18
	panel.call("configure", fill, border, float(border_width), 2.0, true, hatch_color)
	content_layer.add_child(panel)
	return panel

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool, border: Color = Color("#111111"), width: float = 4.0, z: int = 0) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = z
	panel.call("configure", fill, border, width, 1.9, hatch, Color("#1f5fbf12"))
	content_layer.add_child(panel)
	return panel

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment, outline_size: int = 2) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", outline_size)
	return label

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
