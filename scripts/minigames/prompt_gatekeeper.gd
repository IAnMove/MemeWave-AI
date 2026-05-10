extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const PROMPTS := [
	{"key": "PROMPT_GATE_REFACTOR", "kind": "send"},
	{"key": "PROMPT_GATE_FEATURE", "kind": "send"},
	{"key": "PROMPT_GATE_API_KEY", "kind": "discard"},
	{"key": "PROMPT_GATE_DELETE_USERS", "kind": "discard"},
	{"key": "PROMPT_GATE_RM_STAR", "kind": "discard"}
]

var queue: Array[int] = []
var current_prompt := -1
var handled := 0
var mistakes := 0
var hand_font: SystemFont

var prompt_label: Label
var user_bubble_label: Label
var bot_feedback_label: Label
var progress_count_label: Label
var mistake_count_label: Label
var send_button: Button
var discard_button: Button
var progress_bar: ProgressBar
var feedback_icon: Control
var safe_glow: ColorRect
var danger_glow: ColorRect
var prompt_flash: ColorRect
var progress_marks: Array[Control] = []
var progress_check_icons: Array[Control] = []
var mistake_warning_icon: Control
var history_stamps: Array[Control] = []
var history_stamp_labels: Array[Label] = []
var history_count := 0
var live_badge_panel: Control
var live_badge_label: Label
var choice_locked := false
var prompt_badge_panel: Control
var prompt_badge_label: Label
var prompt_decision_line: Line2D
var good_computer_icon: Control
var bad_computer_icon: Control

func _ready() -> void:
	hand_font = SystemFont.new()
	hand_font.font_names = PackedStringArray(["Segoe Print", "Comic Sans MS", "Comic Sans", "Arial"])
	configure(
		"GAME_PROMPT_GATE_TITLE",
		"PROMPT_GATE_INSTRUCTIONS",
		"GAME_PROMPT_GATE_DESC",
		""
	)
	super._ready()
	_hide_common_minigame_header()
	_hide_base_status()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(PROMPTS.size()):
		queue.append(index)
	queue.shuffle()
	current_prompt = -1
	handled = 0
	mistakes = 0
	history_count = 0
	score = 0
	progress_bar.value = 0
	_set_choices_enabled(true)
	_reset_history_stamps()
	_set_feedback("PROMPT_GATE_CHAT_WAITING", Color("#1d1d1d"), "robot")
	_set_computer_state("idle")
	if prompt_flash:
		prompt_flash.visible = false
	_next_prompt()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not running or current_prompt < 0 or choice_locked:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_choice_pressed("send")
	elif event.is_action_pressed("ui_text_backspace") or event.is_action_pressed("ui_text_delete"):
		get_viewport().set_input_as_handled()
		_on_choice_pressed("discard")

func _hide_common_minigame_header() -> void:
	if not title_label:
		return

	var header_box := title_label.get_parent()
	var header := header_box.get_parent() as Control
	header.visible = false

func _hide_base_status() -> void:
	if status_label:
		status_label.visible = false

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#fbf7eb")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(content_layer, Vector2(24, 88), Vector2(1232, 610), Color("#fffdf8"), Color("#111111"), 3.5, 1.4, true, Color("#f6dd5f12"))
	_build_chat_panel()
	_build_computer_panel()
	_build_footer()

	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	progress_bar.min_value = 0
	progress_bar.max_value = PROMPTS.size()
	content_layer.add_child(progress_bar)

func _build_chat_panel() -> void:
	_sketch_panel(content_layer, Vector2(36, 100), Vector2(846, 510), Color("#fffdf8"), Color("#111111"), 4.4, 2.0, false)

	_icon("robot", Vector2(282, 111), Vector2(48, 48), Color("#91c9e8"), Color("#ffffff"))
	var title := _sketch_label(tr("PROMPT_GATE_BOT_NAME"), 36, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(328, 104)
	title.size = Vector2(250, 60)
	content_layer.add_child(title)
	_icon("star", Vector2(583, 121), Vector2(34, 34), Color("#ffe34d"), Color("#ffffff"))

	_sketch_panel(content_layer, Vector2(78, 154), Vector2(760, 234), Color("#fbfdff"), Color("#111111"), 3.0, 1.4, false)
	_notebook_lines(Vector2(106, 198), 690, 6, 28.0)
	_sketch_line(Vector2(128, 166), Vector2(128, 378), Color("#ff7b7b55"), 1.4)

	_icon("robot", Vector2(88, 174), Vector2(48, 48), Color("#91c9e8"), Color("#ffffff"))
	_sketch_panel(content_layer, Vector2(146, 166), Vector2(392, 56), Color("#ffffff"), Color("#111111"), 2.4, 1.1, true, Color("#00000008"))
	_bubble_tail(PackedVector2Array([Vector2(148, 189), Vector2(130, 199), Vector2(148, 209)]), Color("#ffffff"), Color("#111111"), 2.0)
	var bot_rule := _sketch_label(tr("PROMPT_GATE_CHAT_RULE"), 19, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	bot_rule.position = Vector2(164, 174)
	bot_rule.size = Vector2(350, 38)
	content_layer.add_child(bot_rule)

	var time_a := _sketch_label("10:00", 14, Color("#555555"), HORIZONTAL_ALIGNMENT_CENTER)
	time_a.position = Vector2(654, 218)
	time_a.size = Vector2(62, 24)
	content_layer.add_child(time_a)

	_sketch_panel(content_layer, Vector2(462, 238), Vector2(292, 56), Color("#edf6ff"), Color("#1f5fbf"), 2.4, 1.1, true, Color("#1f5fbf10"))
	_bubble_tail(PackedVector2Array([Vector2(752, 258), Vector2(771, 268), Vector2(752, 278)]), Color("#edf6ff"), Color("#1f5fbf"), 2.0)
	user_bubble_label = _sketch_label("", 20, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	user_bubble_label.position = Vector2(474, 246)
	user_bubble_label.size = Vector2(268, 38)
	content_layer.add_child(user_bubble_label)

	var sam := make_sprite("res://assets/sprites/sam_face.png", Vector2(58, 58))
	sam.position = Vector2(754, 232)
	content_layer.add_child(sam)

	var time_b := _sketch_label("10:01", 14, Color("#555555"), HORIZONTAL_ALIGNMENT_CENTER)
	time_b.position = Vector2(646, 293)
	time_b.size = Vector2(62, 24)
	content_layer.add_child(time_b)

	_build_history_stamps()

	_icon("robot", Vector2(88, 309), Vector2(48, 48), Color("#91c9e8"), Color("#ffffff"))
	_sketch_panel(content_layer, Vector2(146, 304), Vector2(320, 58), Color("#f0ffe9"), Color("#11883a"), 2.4, 1.1, true, Color("#11883a10"))
	_bubble_tail(PackedVector2Array([Vector2(148, 324), Vector2(130, 335), Vector2(148, 346)]), Color("#f0ffe9"), Color("#11883a"), 2.0)
	feedback_icon = _icon("robot", Vector2(160, 315), Vector2(36, 36), Color("#91c9e8"), Color("#ffffff"))
	bot_feedback_label = _sketch_label("", 21, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	bot_feedback_label.position = Vector2(204, 313)
	bot_feedback_label.size = Vector2(246, 40)
	content_layer.add_child(bot_feedback_label)

	_icon("spark", Vector2(268, 393), Vector2(26, 26), Color("#f1c40f"), Color("#ffffff"))
	var prompt_title := _sketch_label(tr("PROMPT_GATE_NEW_PROMPT"), 21, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_title.position = Vector2(298, 390)
	prompt_title.size = Vector2(320, 34)
	content_layer.add_child(prompt_title)
	_icon("spark", Vector2(630, 393), Vector2(26, 26), Color("#f1c40f"), Color("#ffffff"))

	_sketch_panel(content_layer, Vector2(80, 428), Vector2(758, 58), Color("#fbfdff"), Color("#1f5fbf"), 2.6, 1.2, true, Color("#1f5fbf0f"))
	prompt_flash = ColorRect.new()
	prompt_flash.position = Vector2(74, 422)
	prompt_flash.size = Vector2(770, 70)
	prompt_flash.color = Color("#ffe34d33")
	prompt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_flash.visible = false
	content_layer.add_child(prompt_flash)
	prompt_label = _sketch_label("", 25, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	prompt_label.position = Vector2(98, 436)
	prompt_label.size = Vector2(600, 42)
	content_layer.add_child(prompt_label)
	_build_prompt_badge()

	discard_button = _build_action_button(
		Vector2(80, 500),
		Vector2(360, 88),
		"PROMPT_GATE_DISCARD",
		"PROMPT_GATE_DISCARD_HINT",
		"PROMPT_GATE_KEY_DELETE",
		"trash",
		Color("#d91e18"),
		Color("#fff3f1")
	)
	discard_button.pressed.connect(_on_choice_pressed.bind("discard"))

	send_button = _build_action_button(
		Vector2(478, 500),
		Vector2(360, 88),
		"PROMPT_GATE_SEND",
		"PROMPT_GATE_SEND_HINT",
		"PROMPT_GATE_KEY_ENTER",
		"plane",
		Color("#123e93"),
		Color("#eef7ff")
	)
	send_button.pressed.connect(_on_choice_pressed.bind("send"))

func _build_computer_panel() -> void:
	_sketch_panel(content_layer, Vector2(898, 100), Vector2(346, 510), Color("#fffdf8"), Color("#111111"), 4.4, 2.0, false)

	safe_glow = _section_glow(Vector2(916, 118), Vector2(306, 218), Color("#dff8da55"))
	danger_glow = _section_glow(Vector2(916, 348), Vector2(306, 218), Color("#ffe1dd66"))

	_icon("check", Vector2(918, 120), Vector2(52, 52), Color("#16a34a"), Color("#ffffff"))
	var safe_title := _sketch_label(tr("PROMPT_GATE_RIGHT_SAFE"), 19, Color("#11883a"), HORIZONTAL_ALIGNMENT_LEFT)
	safe_title.position = Vector2(976, 116)
	safe_title.size = Vector2(226, 56)
	content_layer.add_child(safe_title)

	good_computer_icon = _icon("computer_good", Vector2(972, 172), Vector2(168, 126), Color("#dff8da"), Color("#ffffff"))
	_icon("plant", Vector2(1140, 238), Vector2(48, 56), Color("#0b8842"), Color("#ffffff"))
	_attention_marks(Vector2(984, 190), Vector2(952, 214), Vector2(942, 246), Color("#11883a"))
	_attention_marks(Vector2(1124, 190), Vector2(1162, 214), Vector2(1174, 246), Color("#11883a"))

	_build_live_badge()

	var divider := Line2D.new()
	divider.width = 2.4
	divider.default_color = Color("#111111")
	divider.points = PackedVector2Array([Vector2(928, 342), Vector2(1214, 342)])
	content_layer.add_child(divider)

	_icon("warning", Vector2(918, 354), Vector2(52, 52), Color("#ff3b30"), Color("#ffffff"))
	var danger_title := _sketch_label(tr("PROMPT_GATE_RIGHT_DANGER"), 18, Color("#d91e18"), HORIZONTAL_ALIGNMENT_LEFT)
	danger_title.position = Vector2(976, 350)
	danger_title.size = Vector2(230, 58)
	content_layer.add_child(danger_title)

	bad_computer_icon = _icon("computer_bad", Vector2(964, 406), Vector2(188, 126), Color("#333333"), Color("#ffffff"))
	_icon("spark", Vector2(941, 480), Vector2(26, 26), Color("#f1c40f"), Color("#ffffff"))
	_icon("spark", Vector2(1154, 480), Vector2(26, 26), Color("#f1c40f"), Color("#ffffff"))
	_attention_marks(Vector2(956, 414), Vector2(934, 438), Vector2(930, 470), Color("#5b5b5b"))
	_attention_marks(Vector2(1158, 414), Vector2(1180, 438), Vector2(1188, 470), Color("#5b5b5b"))

	var danger_note := _sketch_label(tr("PROMPT_GATE_COMPUTER_BURNED"), 20, Color("#d91e18"), HORIZONTAL_ALIGNMENT_CENTER)
	danger_note.position = Vector2(930, 530)
	danger_note.size = Vector2(286, 42)
	content_layer.add_child(danger_note)

func _build_footer() -> void:
	_sketch_panel(content_layer, Vector2(36, 626), Vector2(1208, 62), Color("#fffdf8"), Color("#111111"), 3.6, 1.6, false)
	_icon("star", Vector2(218, 633), Vector2(44, 44), Color("#ffe34d"), Color("#ffffff"))

	var footer_text := _sketch_label(tr("PROMPT_GATE_FOOTER"), 22, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	footer_text.position = Vector2(274, 634)
	footer_text.size = Vector2(510, 42)
	content_layer.add_child(footer_text)

	progress_count_label = _sketch_label("", 17, Color("#123e93"), HORIZONTAL_ALIGNMENT_CENTER)
	progress_count_label.position = Vector2(790, 636)
	progress_count_label.size = Vector2(92, 38)
	content_layer.add_child(progress_count_label)

	progress_marks.clear()
	progress_check_icons.clear()
	for index in range(PROMPTS.size()):
		var mark := _sketch_panel(content_layer, Vector2(888 + index * 34, 642), Vector2(28, 28), Color("#fffdf8"), Color("#777777"), 2.2, 1.0, false)
		progress_marks.append(mark)
		var check := _icon("check", Vector2(884 + index * 34, 638), Vector2(36, 36), Color("#16a34a"), Color("#ffffff"))
		check.visible = false
		progress_check_icons.append(check)

	mistake_count_label = _sketch_label("", 17, Color("#d91e18"), HORIZONTAL_ALIGNMENT_CENTER)
	mistake_count_label.position = Vector2(1064, 636)
	mistake_count_label.size = Vector2(84, 38)
	content_layer.add_child(mistake_count_label)

	mistake_warning_icon = _icon("warning", Vector2(1142, 638), Vector2(34, 34), Color("#d91e18"), Color("#ffffff"))
	mistake_warning_icon.visible = false

	_icon("computer_bad", Vector2(1170, 624), Vector2(60, 58), Color("#333333"), Color("#ffffff"))

func _build_action_button(pos: Vector2, size: Vector2, title_key: String, hint_key: String, key_key: String, icon_name: String, accent: Color, fill: Color) -> Button:
	var hatch_tint := accent.lightened(0.25)
	hatch_tint.a = 0.12
	_sketch_panel(content_layer, pos, size, fill, accent, 3.4, 1.4, true, hatch_tint)
	var hover := ColorRect.new()
	hover.position = pos + Vector2(5, 5)
	hover.size = size - Vector2(10, 10)
	hover.color = Color("#ffffff45")
	hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover.visible = false
	content_layer.add_child(hover)
	_icon(icon_name, pos + Vector2(18, 15), Vector2(60, 58), accent, Color("#ffffff"))

	var title := _sketch_label(tr(title_key), 27, accent, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = pos + Vector2(90, 14)
	title.size = Vector2(size.x - 112, 34)
	content_layer.add_child(title)

	var hint := _sketch_label(tr(hint_key), 16, accent, HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = pos + Vector2(86, 48)
	hint.size = Vector2(size.x - 108, 26)
	content_layer.add_child(hint)

	_build_key_chip(pos + Vector2(size.x - 91, size.y - 32), tr(key_key), accent)

	var button := Button.new()
	button.position = pos
	button.size = size
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.mouse_entered.connect(_set_hover_visible.bind(hover, true))
	button.mouse_exited.connect(_set_hover_visible.bind(hover, false))
	button.button_down.connect(_press_button_visual.bind(hover, true))
	button.button_up.connect(_press_button_visual.bind(hover, false))
	content_layer.add_child(button)
	return button

func _build_key_chip(pos: Vector2, text: String, accent: Color) -> void:
	var chip_fill := Color("#fffdf8")
	var chip_border := accent.darkened(0.1)
	_sketch_panel(content_layer, pos, Vector2(70, 25), chip_fill, chip_border, 1.8, 0.8, true, Color("#00000008"))
	var chip := _sketch_label(text, 12, chip_border, HORIZONTAL_ALIGNMENT_CENTER)
	chip.position = pos + Vector2(3, 1)
	chip.size = Vector2(64, 22)
	content_layer.add_child(chip)

func _next_prompt() -> void:
	if queue.is_empty():
		_set_computer_state("success")
		_set_choices_enabled(false)
		_finish_success()
		return

	current_prompt = queue.pop_front()
	var prompt_def: Dictionary = PROMPTS[current_prompt]
	var prompt_text := tr(prompt_def["key"])
	prompt_label.text = prompt_text
	user_bubble_label.text = prompt_text
	_set_computer_state("idle")
	_set_choices_enabled(true)
	_set_prompt_badge("PROMPT_GATE_BADGE_PENDING", Color("#fffdf8"), Color("#777777"))
	_hide_prompt_strike()
	_nudge_prompt_in()
	_flash_prompt()

func _finish_success() -> void:
	await finish_with_result(true, "PROMPT_GATE_SUCCESS", 0.75)

func _on_choice_pressed(choice: String) -> void:
	if not running or current_prompt < 0 or choice_locked:
		return

	_set_choices_enabled(false)
	var prompt_def: Dictionary = PROMPTS[current_prompt]
	var expected := String(prompt_def["kind"])
	_set_prompt_badge(
		"PROMPT_GATE_BADGE_SAFE" if expected == "send" else "PROMPT_GATE_BADGE_DANGER",
		Color("#e7ffe4") if expected == "send" else Color("#ffe1dd"),
		Color("#11883a") if expected == "send" else Color("#d91e18")
	)
	if choice == expected:
		handled += 1
		score = handled
		progress_bar.value = handled
		if choice == "send":
			_set_feedback("PROMPT_GATE_CHAT_SENT", Color("#11883a"), "check")
			_set_computer_state("sent")
			_flash_state_panel(safe_glow)
			_record_history_stamp("PROMPT_GATE_STAMP_SENT", Color("#e7ffe4"), Color("#11883a"))
			_pop_node(good_computer_icon)
		else:
			_set_feedback("PROMPT_GATE_CHAT_DISCARDED", Color("#11883a"), "check")
			_set_computer_state("discarded")
			_flash_state_panel(safe_glow)
			_record_history_stamp("PROMPT_GATE_STAMP_BLOCKED", Color("#fff8d8"), Color("#b88400"))
			_show_prompt_strike(Color("#d91e18"))
			_pop_node(bad_computer_icon)
		_update_status()
		_pop_progress_check(handled - 1)
		await get_tree().create_timer(0.22).timeout
		if running:
			_next_prompt()
	else:
		mistakes += 1
		if choice == "send":
			_set_feedback("PROMPT_GATE_CHAT_BURNED", Color("#d91e18"), "warning")
			_set_computer_state("burned")
			_flash_state_panel(danger_glow)
			_record_history_stamp("PROMPT_GATE_STAMP_BURNED", Color("#ffe1dd"), Color("#d91e18"))
			_shake_node(bad_computer_icon)
			_update_status()
			await finish_with_result(false, "PROMPT_GATE_FAIL_BURNED", 0.8)
		else:
			_set_feedback("PROMPT_GATE_CHAT_DROPPED", Color("#d07c00"), "warning")
			_set_computer_state("wrong")
			_flash_state_panel(danger_glow)
			_record_history_stamp("PROMPT_GATE_STAMP_DROPPED", Color("#fff0d6"), Color("#d07c00"))
			_show_prompt_strike(Color("#d07c00"))
			_shake_node(good_computer_icon)
			_update_status()
			await finish_with_result(false, "PROMPT_GATE_FAIL_DROP", 0.7)

func _set_feedback(text_key: String, color: Color, icon_name: String) -> void:
	bot_feedback_label.text = tr(text_key)
	bot_feedback_label.add_theme_color_override("font_color", color)
	if feedback_icon and feedback_icon.has_method("configure"):
		var icon_color := color if icon_name != "robot" else Color("#91c9e8")
		feedback_icon.call("configure", icon_name, icon_color, Color("#ffffff"))

func _set_choices_enabled(enabled: bool) -> void:
	choice_locked = not enabled
	if send_button:
		send_button.disabled = not enabled
	if discard_button:
		discard_button.disabled = not enabled

func _build_prompt_badge() -> void:
	prompt_badge_panel = _sketch_panel(content_layer, Vector2(718, 440), Vector2(98, 34), Color("#fffdf8"), Color("#777777"), 2.0, 1.0, true, Color("#00000008"))
	prompt_badge_label = _sketch_label("", 14, Color("#777777"), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_badge_label.position = Vector2(724, 445)
	prompt_badge_label.size = Vector2(86, 24)
	content_layer.add_child(prompt_badge_label)

	prompt_decision_line = Line2D.new()
	prompt_decision_line.points = PackedVector2Array([Vector2(100, 456), Vector2(690, 456)])
	prompt_decision_line.width = 4.0
	prompt_decision_line.default_color = Color("#d91e18")
	prompt_decision_line.visible = false
	content_layer.add_child(prompt_decision_line)

func _set_prompt_badge(text_key: String, fill: Color, border: Color) -> void:
	if prompt_badge_panel and prompt_badge_panel.has_method("configure"):
		var hatch := border.lightened(0.3)
		hatch.a = 0.12
		prompt_badge_panel.call("configure", fill, border, 2.0, 1.0, true, hatch)
	if prompt_badge_label:
		prompt_badge_label.text = tr(text_key)
		prompt_badge_label.add_theme_color_override("font_color", border)

func _show_prompt_strike(color: Color) -> void:
	if not prompt_decision_line:
		return
	prompt_decision_line.default_color = color
	prompt_decision_line.visible = true

func _hide_prompt_strike() -> void:
	if prompt_decision_line:
		prompt_decision_line.visible = false

func _set_computer_state(state: String) -> void:
	safe_glow.visible = state in ["sent", "discarded", "success"]
	danger_glow.visible = state in ["burned", "wrong"]
	match state:
		"sent":
			_set_live_badge("PROMPT_GATE_LIVE_SENT", Color("#e7ffe4"), Color("#11883a"))
		"discarded":
			_set_live_badge("PROMPT_GATE_LIVE_BLOCKED", Color("#fff8d8"), Color("#b88400"))
		"burned":
			_set_live_badge("PROMPT_GATE_LIVE_BURNED", Color("#ffe1dd"), Color("#d91e18"))
		"wrong":
			_set_live_badge("PROMPT_GATE_LIVE_DROPPED", Color("#fff0d6"), Color("#d07c00"))
		"success":
			_set_live_badge("PROMPT_GATE_LIVE_CLEAN", Color("#e7ffe4"), Color("#11883a"))
		_:
			_set_live_badge("PROMPT_GATE_LIVE_READY", Color("#fffdf8"), Color("#777777"))

func _update_status() -> void:
	progress_count_label.text = tr("PROMPT_GATE_PROGRESS_SHORT")
	mistake_count_label.text = tr("PROMPT_GATE_MISTAKES") % mistakes
	for index in range(progress_marks.size()):
		var mark := progress_marks[index]
		if mark and mark.has_method("configure"):
			var done := index < handled
			var fill := Color("#e7ffe4") if done else Color("#fffdf8")
			var border := Color("#16a34a") if done else Color("#777777")
			mark.call("configure", fill, border, 2.2, 1.0, false)
	if mistake_warning_icon:
		mistake_warning_icon.visible = mistakes > 0
	for index in range(progress_check_icons.size()):
		progress_check_icons[index].visible = index < handled
	set_status("")

func _section_glow(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var glow := ColorRect.new()
	glow.position = pos
	glow.size = size
	glow.color = color
	glow.visible = false
	content_layer.add_child(glow)
	return glow

func _build_live_badge() -> void:
	live_badge_panel = _sketch_panel(content_layer, Vector2(954, 300), Vector2(250, 40), Color("#fffdf8"), Color("#777777"), 2.0, 1.0, true, Color("#00000008"))
	var badge_title := _sketch_label(tr("PROMPT_GATE_LIVE_TITLE"), 11, Color("#555555"), HORIZONTAL_ALIGNMENT_CENTER)
	badge_title.position = Vector2(962, 299)
	badge_title.size = Vector2(234, 14)
	content_layer.add_child(badge_title)

	live_badge_label = _sketch_label("", 18, Color("#777777"), HORIZONTAL_ALIGNMENT_CENTER)
	live_badge_label.position = Vector2(962, 314)
	live_badge_label.size = Vector2(234, 24)
	content_layer.add_child(live_badge_label)

func _set_live_badge(text_key: String, fill: Color, border: Color) -> void:
	if live_badge_panel and live_badge_panel.has_method("configure"):
		var hatch := border.lightened(0.3)
		hatch.a = 0.12
		live_badge_panel.call("configure", fill, border, 2.0, 1.0, true, hatch)
	if live_badge_label:
		live_badge_label.text = tr(text_key)
		live_badge_label.add_theme_color_override("font_color", border)

func _build_history_stamps() -> void:
	history_stamps.clear()
	history_stamp_labels.clear()
	for index in range(PROMPTS.size()):
		var pos := Vector2(492 + index * 62, 318)
		var stamp := _sketch_panel(content_layer, pos, Vector2(50, 30), Color("#fffdf8"), Color("#b9b9b9"), 1.8, 0.8, true, Color("#00000007"))
		history_stamps.append(stamp)
		var label := _sketch_label("", 13, Color("#777777"), HORIZONTAL_ALIGNMENT_CENTER)
		label.position = pos + Vector2(3, 2)
		label.size = Vector2(44, 24)
		content_layer.add_child(label)
		history_stamp_labels.append(label)

func _reset_history_stamps() -> void:
	for index in range(history_stamps.size()):
		var stamp := history_stamps[index]
		if stamp and stamp.has_method("configure"):
			stamp.call("configure", Color("#fffdf8"), Color("#b9b9b9"), 1.8, 0.8, true, Color("#00000007"))
		if index < history_stamp_labels.size():
			history_stamp_labels[index].text = ""
			history_stamp_labels[index].add_theme_color_override("font_color", Color("#777777"))

func _record_history_stamp(text_key: String, fill: Color, border: Color) -> void:
	if history_count >= history_stamps.size():
		return
	var stamp := history_stamps[history_count]
	if stamp and stamp.has_method("configure"):
		var hatch := border.lightened(0.3)
		hatch.a = 0.12
		stamp.call("configure", fill, border, 2.2, 1.0, true, hatch)
	var label := history_stamp_labels[history_count]
	label.text = tr(text_key)
	label.add_theme_color_override("font_color", border)
	_pop_node(stamp)
	_pop_node(label)
	history_count += 1

func _sketch_panel(
		parent: Node,
		pos: Vector2,
		panel_size: Vector2,
		fill: Color,
		border: Color,
		border_width: float,
		roughness: float,
		hatch: bool = false,
		hatch_color: Color = Color("#00000010")
	) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, border, border_width, roughness, hatch, hatch_color)
	parent.add_child(panel)
	return panel

func _icon(icon_name: String, pos: Vector2, icon_size: Vector2, accent: Color, secondary: Color) -> Control:
	var icon: Control = SketchIcon.new()
	icon.position = pos
	icon.size = icon_size
	icon.call("configure", icon_name, accent, secondary)
	content_layer.add_child(icon)
	return icon

func _bubble_tail(points: PackedVector2Array, fill: Color, border: Color, width: float) -> void:
	var tail := Polygon2D.new()
	tail.polygon = points
	tail.color = fill
	content_layer.add_child(tail)

	var outline := Line2D.new()
	outline.points = PackedVector2Array([points[0], points[1], points[2]])
	outline.width = width
	outline.default_color = border
	content_layer.add_child(outline)

func _notebook_lines(start: Vector2, line_width: float, count: int, gap: float) -> void:
	for index in range(count):
		var y := start.y + float(index) * gap
		_sketch_line(Vector2(start.x, y), Vector2(start.x + line_width, y + sin(float(index)) * 1.5), Color("#8bb7dd30"), 1.2)

func _attention_marks(first: Vector2, second: Vector2, third: Vector2, color: Color) -> void:
	var first_dir := -18.0 if first.x < second.x else 18.0
	var second_dir := -22.0 if second.x < third.x else 22.0
	var third_dir := -16.0 if second.x < third.x else 16.0
	_sketch_line(first, first + Vector2(first_dir, -18.0), color, 2.0)
	_sketch_line(second, second + Vector2(second_dir, 0.0), color, 2.0)
	_sketch_line(third, third + Vector2(third_dir, 16.0), color, 2.0)

func _sketch_line(from: Vector2, to: Vector2, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, (from + to) * 0.5 + Vector2(0.0, sin(from.x + to.y) * 1.4), to])
	line.width = width
	line.default_color = color
	content_layer.add_child(line)
	return line

func _set_hover_visible(hover: ColorRect, visible: bool) -> void:
	if is_instance_valid(hover):
		hover.visible = visible

func _press_button_visual(hover: ColorRect, pressed: bool) -> void:
	if not is_instance_valid(hover):
		return
	hover.color = Color("#ffe34d55") if pressed else Color("#ffffff45")

func _flash_prompt() -> void:
	if not prompt_flash:
		return
	prompt_flash.visible = true
	prompt_flash.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(prompt_flash, "modulate:a", 0.0, 0.38)
	tween.tween_callback(func() -> void:
		if is_instance_valid(prompt_flash):
			prompt_flash.visible = false
	)

func _flash_state_panel(panel: ColorRect) -> void:
	if not panel:
		return
	panel.visible = true
	panel.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.35, 0.12)
	tween.tween_property(panel, "modulate:a", 1.0, 0.12)

func _nudge_prompt_in() -> void:
	var base_label_pos := Vector2(98, 436)
	var base_badge_pos := Vector2(718, 440)
	prompt_label.position = base_label_pos + Vector2(-18, 0)
	prompt_label.modulate.a = 0.0
	if prompt_badge_panel:
		prompt_badge_panel.position = base_badge_pos + Vector2(18, 0)
	if prompt_badge_label:
		prompt_badge_label.position = Vector2(724, 445) + Vector2(18, 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(prompt_label, "position", base_label_pos, 0.16)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.16)
	if prompt_badge_panel:
		tween.tween_property(prompt_badge_panel, "position", base_badge_pos, 0.16)
	if prompt_badge_label:
		tween.tween_property(prompt_badge_label, "position", Vector2(724, 445), 0.16)

func _pop_progress_check(index: int) -> void:
	if index < 0 or index >= progress_check_icons.size():
		return
	_pop_node(progress_check_icons[index])

func _pop_node(node: Control) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector2(1.16, 1.16), 0.08)
	tween.tween_property(node, "scale", Vector2.ONE, 0.10)

func _shake_node(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var base_pos := node.position
	var tween := create_tween()
	tween.tween_property(node, "position", base_pos + Vector2(-7, 0), 0.04)
	tween.tween_property(node, "position", base_pos + Vector2(7, 0), 0.04)
	tween.tween_property(node, "position", base_pos + Vector2(-5, 0), 0.04)
	tween.tween_property(node, "position", base_pos + Vector2(5, 0), 0.04)
	tween.tween_property(node, "position", base_pos, 0.04)

func _sketch_label(text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_font_override("font", hand_font)
	label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	label.add_theme_constant_override("outline_size", 1)
	return label

func on_timeout() -> void:
	var success := handled >= PROMPTS.size()
	await finish_with_result(success, "PROMPT_GATE_TIMEOUT_SUCCESS" if success else "PROMPT_GATE_FAIL", 0.45)
