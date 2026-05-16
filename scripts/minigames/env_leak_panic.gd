extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const LEAK_SECONDS := 12.0
const TARGET_LEAKS := 4
const TAPE_SIZE := Vector2(92, 38)
const TAPE_STARTS := [
	Vector2(738, 610),
	Vector2(834, 610),
	Vector2(930, 610),
	Vector2(1026, 610),
	Vector2(1122, 610)
]
const LEAK_DEFS := [
	{
		"id": "openai",
		"rect": Rect2(286, 380, 350, 30),
		"label": "OPENAI_API_KEY=sk-live-vibec0ding-8K..."
	},
	{
		"id": "github",
		"rect": Rect2(286, 448, 330, 30),
		"label": "GITHUB_TOKEN=ghp_agent_push_prod..."
	},
	{
		"id": "db",
		"rect": Rect2(636, 414, 238, 30),
		"label": "prod:secret@db.internal"
	},
	{
		"id": "url",
		"rect": Rect2(930, 420, 244, 30),
		"label": "admin.local/private"
	}
]

var leaks: Array[Dictionary] = []
var tapes: Array[Dictionary] = []
var covered_count := 0
var pulse := 0.0
var dragging := false
var active_tape_index := -1
var drag_offset := Vector2.ZERO

var upload_bar: ProgressBar
var cover_label: Label
var warning_label: Label
var tweet_button: Control

func _ready() -> void:
	configure("GAME_ENV_TITLE", "ENV_INSTRUCTIONS", "GAME_ENV_DESC", "")
	super._ready()
	if overlay_label:
		overlay_label.z_index = 200
	if tutorial_panel:
		tutorial_panel.visible = false
	hide_base_status()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	time_left = LEAK_SECONDS
	emit_signal("time_changed", time_left)
	score = 0
	covered_count = 0
	dragging = false
	active_tape_index = -1
	pulse = 0.0
	_reset_leaks()
	_reset_tapes()
	_update_status("ENV_READY")

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	pulse += delta * 8.0
	if upload_bar:
		upload_bar.value = clampf((LEAK_SECONDS - time_left) / LEAK_SECONDS * 100.0, 0.0, 100.0)
		upload_bar.modulate = Color("#ffffff") if covered_count >= TARGET_LEAKS else Color("#ffb0b0")
	if tweet_button:
		tweet_button.scale = Vector2.ONE * (1.0 + sin(pulse) * 0.018)
	for leak in leaks:
		var marker := leak["marker"] as Control
		if marker and not bool(leak["covered"]):
			marker.modulate.a = 0.54 + sin(pulse + float(leak["phase"])) * 0.18

func _input(event: InputEvent) -> void:
	if not dragging or active_tape_index < 0:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_move_active_tape(content_layer.get_local_mouse_position() - drag_offset)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_active_tape()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		_release_active_tape()
		get_viewport().set_input_as_handled()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#111827")
	content_layer.add_child(bg)

	_add_desktop_marks()
	_build_screenshot()
	_build_tweet_popup()
	_build_tape_tray()

func _add_desktop_marks() -> void:
	var taskbar := ColorRect.new()
	taskbar.position = Vector2(0, 664)
	taskbar.size = Vector2(1280, 56)
	taskbar.color = Color("#0a0f1c")
	content_layer.add_child(taskbar)

	for index in range(9):
		var chip := ColorRect.new()
		chip.position = Vector2(26 + index * 54, 678)
		chip.size = Vector2(34, 24)
		chip.color = Color("#243142") if index % 2 == 0 else Color("#1b2a3d")
		content_layer.add_child(chip)

	var wallpaper_glow := ColorRect.new()
	wallpaper_glow.position = Vector2(0, 196)
	wallpaper_glow.size = Vector2(1280, 468)
	wallpaper_glow.color = Color("#12345a44")
	content_layer.add_child(wallpaper_glow)

	for index in range(6):
		var slash := ColorRect.new()
		slash.position = Vector2(42 + index * 230, 232 + (index % 3) * 86)
		slash.size = Vector2(8, 96)
		slash.rotation = -0.45
		slash.color = Color("#66dbff33") if index % 2 == 0 else Color("#ff8fd233")
		content_layer.add_child(slash)

func _build_screenshot() -> void:
	var frame := _sketch_panel(Vector2(54, 224), Vector2(832, 396), Color("#f2f7ffe8"), Color("#111111"), 4.0, true)
	frame.z_index = 0

	var topbar := ColorRect.new()
	topbar.position = Vector2(74, 244)
	topbar.size = Vector2(792, 34)
	topbar.color = Color("#202938")
	topbar.z_index = 2
	content_layer.add_child(topbar)

	for index in range(3):
		var dot := ColorRect.new()
		dot.position = Vector2(92 + index * 26, 254)
		dot.size = Vector2(14, 14)
		dot.color = [Color("#ff5b5b"), Color("#ffdf2e"), Color("#56d364")][index]
		dot.z_index = 3
		content_layer.add_child(dot)

	var title := _outlined_label("vibecoding-app  /  .env.local", 18, Color("#d9e8ff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(228, 246)
	title.size = Vector2(420, 28)
	content_layer.add_child(title)

	_build_file_tree()
	_build_editor()
	_build_terminal()

func _build_file_tree() -> void:
	var file_panel := _sketch_panel(Vector2(76, 288), Vector2(142, 290), Color("#172032"), Color("#111111"), 3.0, false)
	file_panel.z_index = 2
	var files := [
		"src/",
		"app.tsx",
		"agent.py",
		".env.local",
		"tweet.png"
	]
	for index in range(files.size()):
		var row := _outlined_label(String(files[index]), 15, Color("#e7eefc"), HORIZONTAL_ALIGNMENT_LEFT)
		row.position = Vector2(96, 312 + index * 42)
		row.size = Vector2(104, 30)
		if String(files[index]) == ".env.local":
			row.add_theme_color_override("font_color", Color("#ffef5f"))
		content_layer.add_child(row)

func _build_editor() -> void:
	var editor_panel := _sketch_panel(Vector2(228, 288), Vector2(424, 290), Color("#101923"), Color("#111111"), 3.0, false)
	editor_panel.z_index = 2
	var lines := [
		{"n": "01", "text": "# .env.local", "pos": Vector2(244, 312), "color": "#7ee787"},
		{"n": "02", "text": "APP_ENV=production", "pos": Vector2(244, 346), "color": "#e7eefc"},
		{"n": "03", "text": String(LEAK_DEFS[0]["label"]), "pos": Vector2(244, 380), "color": "#ffef5f", "leak": 0},
		{"n": "04", "text": "OLLAMA_HOST=http://127.0.0.1", "pos": Vector2(244, 414), "color": "#e7eefc"},
		{"n": "05", "text": String(LEAK_DEFS[1]["label"]), "pos": Vector2(244, 448), "color": "#ff9fd6", "leak": 1},
		{"n": "06", "text": "PUBLIC_BUILD=vibe-friday", "pos": Vector2(244, 482), "color": "#e7eefc"},
		{"n": "07", "text": "SCREENSHOT=ready_to_post.png", "pos": Vector2(244, 516), "color": "#8bd0ff"}
	]
	for line in lines:
		var pos := line["pos"] as Vector2
		var number := _outlined_label(String(line["n"]), 13, Color("#77869a"), HORIZONTAL_ALIGNMENT_RIGHT)
		number.position = Vector2(232, pos.y + 2)
		number.size = Vector2(28, 24)
		content_layer.add_child(number)
		if line.has("leak"):
			_add_leak_marker(int(line["leak"]))
		var label := _code_label(String(line["text"]), 16, Color(String(line["color"])))
		label.position = pos + Vector2(42, 0)
		label.size = Vector2(338, 30)
		content_layer.add_child(label)

func _build_terminal() -> void:
	var terminal_panel := _sketch_panel(Vector2(668, 288), Vector2(198, 290), Color("#060a12"), Color("#111111"), 3.0, false)
	terminal_panel.z_index = 2
	var title := _outlined_label("TERMINAL", 16, Color("#66dbff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(690, 302)
	title.size = Vector2(152, 26)
	content_layer.add_child(title)

	var terminal_lines := [
		{"text": "$ git add screenshot.png", "y": 340, "color": "#e7eefc"},
		{"text": "$ cat .env | tail", "y": 374, "color": "#e7eefc"},
		{"text": String(LEAK_DEFS[2]["label"]), "y": 414, "color": "#ff7777", "leak": 2},
		{"text": "$ post --now", "y": 458, "color": "#56d364"},
		{"text": "uploading...", "y": 492, "color": "#ffef5f"}
	]
	for line in terminal_lines:
		if line.has("leak"):
			_add_leak_marker(int(line["leak"]))
		var label := _code_label(String(line["text"]), 14, Color(String(line["color"])))
		label.position = Vector2(688, int(line["y"]))
		label.size = Vector2(164, 28)
		content_layer.add_child(label)

func _build_tweet_popup() -> void:
	var popup := _sketch_panel(Vector2(910, 232), Vector2(306, 314), Color("#fffdf8ef"), Color("#111111"), 4.0, true)
	popup.z_index = 2

	var robot: Control = SketchIcon.new()
	robot.position = Vector2(940, 252)
	robot.size = Vector2(56, 52)
	robot.call("configure", "robot", Color("#66dbff"), Color("#ffffff"), Color("#111111"))
	content_layer.add_child(robot)

	var title := _outlined_label(tr("ENV_TWEET_TITLE"), 24, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(1004, 254)
	title.size = Vector2(174, 42)
	content_layer.add_child(title)

	var preview := _sketch_panel(Vector2(934, 320), Vector2(250, 150), Color("#182332"), Color("#111111"), 3.0, false)
	preview.z_index = 3
	var image_band := ColorRect.new()
	image_band.position = Vector2(952, 342)
	image_band.size = Vector2(214, 34)
	image_band.color = Color("#28384d")
	image_band.z_index = 4
	content_layer.add_child(image_band)
	var image_text := _code_label("screenshot.png", 15, Color("#e7eefc"))
	image_text.position = Vector2(962, 346)
	image_text.size = Vector2(186, 28)
	content_layer.add_child(image_text)

	_add_leak_marker(3)
	var leak_text := _code_label(String(LEAK_DEFS[3]["label"]), 15, Color("#ffef5f"))
	leak_text.position = Vector2(940, 420)
	leak_text.size = Vector2(228, 28)
	content_layer.add_child(leak_text)

	upload_bar = ProgressBar.new()
	upload_bar.position = Vector2(940, 492)
	upload_bar.size = Vector2(238, 22)
	upload_bar.max_value = 100.0
	upload_bar.show_percentage = false
	upload_bar.add_theme_stylebox_override("background", make_style(Color("#172032"), Color("#111111"), 2, 6))
	upload_bar.add_theme_stylebox_override("fill", make_style(Color("#ff5b5b"), Color("#ff5b5b"), 0, 6))
	content_layer.add_child(upload_bar)

	tweet_button = _sketch_panel(Vector2(1010, 504), Vector2(110, 42), Color("#66dbff"), Color("#111111"), 3.0, false)
	var post := _outlined_label("POST", 20, Color("#111111"), HORIZONTAL_ALIGNMENT_CENTER)
	post.position = Vector2(1018, 510)
	post.size = Vector2(94, 28)
	content_layer.add_child(post)

func _build_tape_tray() -> void:
	var tray := _sketch_panel(Vector2(724, 560), Vector2(492, 98), Color("#fff7d6ee"), Color("#111111"), 4.0, false)
	tray.z_index = 5
	var title := _outlined_label(tr("ENV_TAPE_TRAY"), 22, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(740, 564)
	title.size = Vector2(454, 32)
	title.z_index = 8
	content_layer.add_child(title)

	tapes.clear()
	for index in range(TAPE_STARTS.size()):
		var tape := PanelContainer.new()
		tape.position = TAPE_STARTS[index]
		tape.size = TAPE_SIZE
		tape.z_index = 20
		tape.mouse_filter = Control.MOUSE_FILTER_STOP
		tape.add_theme_stylebox_override("panel", make_style(Color("#111111"), Color("#050505"), 3, 4))
		tape.gui_input.connect(_on_tape_gui_input.bind(index))
		content_layer.add_child(tape)

		var shine := ColorRect.new()
		shine.position = Vector2(8, 7)
		shine.size = Vector2(76, 4)
		shine.color = Color("#ffffff22")
		shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tape.add_child(shine)

		var label := _outlined_label(tr("ENV_TAPE_LABEL"), 13, Color("#d8d8d8"), HORIZONTAL_ALIGNMENT_CENTER)
		label.position = Vector2(0, 5)
		label.size = TAPE_SIZE - Vector2(0, 12)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tape.add_child(label)

		tapes.append({
			"node": tape,
			"start": TAPE_STARTS[index],
			"used": false
		})

	cover_label = _outlined_label("", 22, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	cover_label.position = Vector2(66, 618)
	cover_label.size = Vector2(270, 32)
	content_layer.add_child(cover_label)

	warning_label = _outlined_label("", 22, Color("#ffef5f"), HORIZONTAL_ALIGNMENT_CENTER)
	warning_label.position = Vector2(366, 618)
	warning_label.size = Vector2(314, 32)
	content_layer.add_child(warning_label)

func _add_leak_marker(leak_index: int) -> void:
	var def: Dictionary = LEAK_DEFS[leak_index]
	var rect: Rect2 = def["rect"]
	var marker := ColorRect.new()
	marker.position = rect.position
	marker.size = rect.size
	marker.color = Color("#ff4d5a7d")
	marker.z_index = 8
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(marker)

	var tag := _outlined_label(tr("ENV_SECRET_TAG"), 10, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	tag.position = rect.position + Vector2(rect.size.x - 62, -16)
	tag.size = Vector2(60, 18)
	tag.z_index = 9
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(tag)

	leaks.append({
		"id": String(def["id"]),
		"rect": rect,
		"marker": marker,
		"tag": tag,
		"covered": false,
		"phase": randf_range(0.0, TAU)
	})

func _on_tape_gui_input(event: InputEvent, tape_index: int) -> void:
	if not running:
		return
	if tape_index < 0 or tape_index >= tapes.size():
		return
	if bool(tapes[tape_index]["used"]):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_drag(tape_index, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_start_drag(tape_index, event.position)
		get_viewport().set_input_as_handled()

func _start_drag(tape_index: int, local_point: Vector2) -> void:
	dragging = true
	active_tape_index = tape_index
	drag_offset = local_point
	var tape := tapes[tape_index]["node"] as Control
	tape.z_index = 60
	tape.scale = Vector2(1.05, 1.05)
	play_action_sound("move")
	_update_status("ENV_DRAGGING")

func _move_active_tape(top_left: Vector2) -> void:
	if active_tape_index < 0:
		return
	var tape := tapes[active_tape_index]["node"] as Control
	tape.position = Vector2(
		clampf(top_left.x, 40.0, 1180.0),
		clampf(top_left.y, 214.0, 638.0)
	)

func _release_active_tape() -> void:
	if active_tape_index < 0:
		return

	var tape_index := active_tape_index
	var tape := tapes[tape_index]["node"] as Control
	dragging = false
	active_tape_index = -1
	tape.scale = Vector2.ONE
	var target_index := _target_for_tape(tape)
	if target_index >= 0:
		_cover_leak(target_index, tape_index)
	else:
		_return_tape(tape_index)

func _target_for_tape(tape: Control) -> int:
	var tape_rect := Rect2(tape.position, tape.size)
	var tape_center := tape.position + tape.size * 0.5
	for index in range(leaks.size()):
		var leak: Dictionary = leaks[index]
		if bool(leak["covered"]):
			continue
		var rect: Rect2 = leak["rect"]
		if rect.grow(28.0).has_point(tape_center) or tape_rect.intersects(rect.grow(18.0)):
			return index
	return -1

func _cover_leak(leak_index: int, tape_index: int) -> void:
	var leak: Dictionary = leaks[leak_index]
	var tape_info: Dictionary = tapes[tape_index]
	var tape := tape_info["node"] as Control
	var rect: Rect2 = leak["rect"]

	leak["covered"] = true
	leaks[leak_index] = leak
	tape_info["used"] = true
	tapes[tape_index] = tape_info

	tape.position = rect.position + Vector2(-10, -5)
	tape.size = rect.size + Vector2(20, 10)
	tape.rotation = randf_range(-0.025, 0.025)
	tape.z_index = 45
	(leak["marker"] as Control).visible = false
	(leak["tag"] as Control).visible = false
	covered_count += 1
	score = covered_count
	play_action_sound("collect")
	_spawn_stamp(rect.position + rect.size * 0.5)
	_update_status("ENV_COVERED")
	if covered_count >= TARGET_LEAKS:
		_complete_success()

func _return_tape(tape_index: int) -> void:
	var tape_info: Dictionary = tapes[tape_index]
	var tape := tape_info["node"] as Control
	play_action_sound("bad")
	_update_status("ENV_MISSED")
	var tween := create_tween()
	tween.tween_property(tape, "position", tape_info["start"], 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(tape, "rotation", randf_range(-0.08, 0.08), 0.08)
	tween.chain().tween_property(tape, "rotation", 0.0, 0.10)
	tape.z_index = 20

func _complete_success() -> void:
	if not running:
		return
	_update_status("ENV_SAFE")
	await finish_with_result(true, "ENV_SUCCESS", 0.55)

func _spawn_stamp(center: Vector2) -> void:
	var stamp := _outlined_label(tr("ENV_STAMP_COVERED"), 18, Color("#56d364"), HORIZONTAL_ALIGNMENT_CENTER)
	stamp.position = center - Vector2(70, 38)
	stamp.size = Vector2(140, 34)
	stamp.z_index = 70
	content_layer.add_child(stamp)
	var tween := create_tween()
	tween.tween_property(stamp, "position:y", stamp.position.y - 18.0, 0.22)
	tween.parallel().tween_property(stamp, "modulate:a", 0.0, 0.35).set_delay(0.08)
	tween.tween_callback(stamp.queue_free)

func _reset_leaks() -> void:
	for index in range(leaks.size()):
		var leak: Dictionary = leaks[index]
		leak["covered"] = false
		leaks[index] = leak
		var marker := leak["marker"] as Control
		var tag := leak["tag"] as Control
		if marker:
			marker.visible = true
		if tag:
			tag.visible = true

func _reset_tapes() -> void:
	for index in range(tapes.size()):
		var tape_info: Dictionary = tapes[index]
		var tape := tape_info["node"] as Control
		tape_info["used"] = false
		tapes[index] = tape_info
		tape.position = tape_info["start"]
		tape.size = TAPE_SIZE
		tape.scale = Vector2.ONE
		tape.rotation = 0.0
		tape.z_index = 20
		tape.visible = true

func _update_status(feedback_key: String) -> void:
	set_status(tr("ENV_STATUS") % [covered_count, TARGET_LEAKS])
	if cover_label:
		cover_label.text = tr("ENV_COVER_COUNT") % [covered_count, TARGET_LEAKS]
	if warning_label:
		warning_label.text = tr(feedback_key)

func _force_cover_all_leaks() -> void:
	for index in range(leaks.size()):
		if index >= tapes.size():
			return
		if not bool(leaks[index]["covered"]):
			_cover_leak(index, index)

func on_timeout() -> void:
	var success := covered_count >= TARGET_LEAKS
	await finish_with_result(success, "ENV_TIMEOUT_SUCCESS" if success else "ENV_FAIL", 0.45)

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, border: Color, width: float, hatch: bool) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = 1
	panel.call("configure", fill, border, width, 1.4, hatch, Color("#ffffff14"))
	content_layer.add_child(panel)
	return panel

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.z_index = 6
	label.add_theme_color_override("font_outline_color", Color("#111111") if color != Color("#151515") else Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _code_label(text: String, font_size: int, color: Color) -> Label:
	var label := make_label(text, font_size, color, HORIZONTAL_ALIGNMENT_LEFT)
	label.z_index = 6
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override("font_outline_color", Color("#000000"))
	label.add_theme_constant_override("outline_size", 2)
	return label
