extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

var quick_title_key := ""
var quick_instructions_key := ""
var quick_description_key := ""
var quick_background_path := ""
var board_title_key := ""
var side_title_key := ""
var item_defs: Array = []
var option_defs: Array = []
var target_count := 6
var mistake_limit := 3
var shuffle_items := true
var quick_success_key := ""
var quick_fail_key := ""
var quick_timeout_success_key := ""
var theme_color := Color("#fffdf8")
var accent_color := Color("#1f5fbf")

var queue: Array[int] = []
var current_item := -1
var handled := 0
var mistakes := 0
var choice_locked := false
var option_buttons: Array[Button] = []
var item_label: Label
var verdict_label: Label
var progress_label: Label
var mistakes_label: Label
var progress_bar: ProgressBar
var side_icon: Control
var card_panel: Control
var wobble := 0.0

func setup_quick_sort(
		title_key: String,
		instructions_key: String,
		description_key: String,
		new_board_title_key: String,
		new_side_title_key: String,
		new_items: Array,
		new_options: Array,
		new_target_count: int,
		success_key: String,
		fail_key: String,
		timeout_success_key: String = "",
		background_path: String = "",
		new_theme_color: Color = Color("#fffdf8"),
		new_accent_color: Color = Color("#1f5fbf")
	) -> void:
	quick_title_key = title_key
	quick_instructions_key = instructions_key
	quick_description_key = description_key
	quick_background_path = background_path
	board_title_key = new_board_title_key
	side_title_key = new_side_title_key
	item_defs = new_items
	option_defs = new_options
	target_count = new_target_count
	quick_success_key = success_key
	quick_fail_key = fail_key
	quick_timeout_success_key = timeout_success_key
	theme_color = new_theme_color
	accent_color = new_accent_color

func _ready() -> void:
	configure(quick_title_key, quick_instructions_key, quick_description_key, quick_background_path)
	super._ready()
	hide_common_minigame_header()
	hide_base_status()
	_build_quick_stage()

func start_minigame() -> void:
	super.start_minigame()
	queue.clear()
	for index in range(item_defs.size()):
		queue.append(index)
	if shuffle_items:
		queue.shuffle()
	current_item = -1
	handled = 0
	mistakes = 0
	score = 0
	choice_locked = false
	wobble = 0.0
	progress_bar.value = 0
	_set_buttons_enabled(true)
	_set_verdict(quick_instructions_key, Color("#151515"))
	_next_item()
	_update_counters()

func _process(delta: float) -> void:
	super._process(delta)
	if not running or not card_panel:
		return

	wobble += delta * 6.0
	card_panel.rotation = sin(wobble) * 0.018

func _unhandled_input(event: InputEvent) -> void:
	if not running or choice_locked or not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		var index := int(event.keycode - KEY_1)
		if index >= 0 and index < option_buttons.size():
			get_viewport().set_input_as_handled()
			_choose_action(String(option_buttons[index].get_meta("action_id")))
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		if not option_buttons.is_empty():
			get_viewport().set_input_as_handled()
			_choose_action(String(option_buttons[0].get_meta("action_id")))
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		if option_buttons.size() > 1:
			get_viewport().set_input_as_handled()
			_choose_action(String(option_buttons[1].get_meta("action_id")))

func _build_quick_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#141b26")
	add_child(bg)
	move_child(bg, 0)

	var play_panel: Control = SketchPanel.new()
	play_panel.position = Vector2(76, 178)
	play_panel.size = Vector2(790, 470)
	play_panel.call("configure", theme_color, Color("#1d1d1d"), 4.0, 1.4, true, accent_color.lightened(0.45))
	content_layer.add_child(play_panel)

	var side_panel: Control = SketchPanel.new()
	side_panel.position = Vector2(906, 178)
	side_panel.size = Vector2(290, 470)
	side_panel.call("configure", Color("#fff7d6"), Color("#1d1d1d"), 4.0, 1.2, false)
	content_layer.add_child(side_panel)

	var title := make_label(tr(board_title_key), 37, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(116, 204)
	title.size = Vector2(710, 54)
	title.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(title)

	card_panel = SketchPanel.new()
	card_panel.position = Vector2(184, 310)
	card_panel.size = Vector2(574, 120)
	card_panel.pivot_offset = Vector2(287, 60)
	card_panel.call("configure", Color("#fbfdff"), accent_color, 3.2, 1.1, false)
	content_layer.add_child(card_panel)

	item_label = make_label("", 34, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	item_label.position = Vector2(214, 328)
	item_label.size = Vector2(514, 82)
	item_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	item_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(item_label)

	option_buttons.clear()
	var button_count := maxi(1, option_defs.size())
	var button_width := minf(220.0, 690.0 / float(button_count) - 12.0)
	var total_width := float(button_count) * button_width + float(button_count - 1) * 16.0
	var start_x := 471.0 - total_width * 0.5
	for index in range(button_count):
		var option: Dictionary = option_defs[index]
		var button := make_button("", 23, Color(String(option.get("color", "#ffef5f"))))
		button.position = Vector2(start_x + float(index) * (button_width + 16.0), 504)
		button.size = Vector2(button_width, 72)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(_on_button_pressed.bind(button))
		content_layer.add_child(button)
		option_buttons.append(button)

	side_icon = SketchIcon.new()
	side_icon.position = Vector2(980, 226)
	side_icon.size = Vector2(130, 118)
	side_icon.call("configure", "robot", Color("#91c9e8"), Color("#ffffff"))
	content_layer.add_child(side_icon)

	var side_title := make_label(tr(side_title_key), 28, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	side_title.position = Vector2(938, 362)
	side_title.size = Vector2(226, 46)
	content_layer.add_child(side_title)

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(950, 428)
	progress_bar.size = Vector2(202, 28)
	progress_bar.max_value = target_count
	progress_bar.value = 0
	progress_bar.show_percentage = false
	content_layer.add_child(progress_bar)

	progress_label = make_label("", 24, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	progress_label.position = Vector2(938, 466)
	progress_label.size = Vector2(226, 34)
	content_layer.add_child(progress_label)

	mistakes_label = make_label("", 23, Color("#bf2030"), HORIZONTAL_ALIGNMENT_CENTER)
	mistakes_label.position = Vector2(938, 506)
	mistakes_label.size = Vector2(226, 34)
	content_layer.add_child(mistakes_label)

	verdict_label = make_label("", 25, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(918, 552)
	verdict_label.size = Vector2(266, 52)
	verdict_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	verdict_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(verdict_label)

func _on_button_pressed(button: Button) -> void:
	_choose_action(String(button.get_meta("action_id")))

func _choose_action(action: String) -> void:
	if not running or choice_locked or current_item < 0:
		return

	choice_locked = true
	_set_buttons_enabled(false)
	var item: Dictionary = item_defs[current_item]
	var success := action == _correct_action_for_item(item)
	if success:
		handled += 1
		score = handled
		play_action_sound("collect")
		_set_verdict(_good_feedback_key(item), Color("#0b8842"))
	else:
		mistakes += 1
		play_action_sound("bad")
		_set_verdict(_bad_feedback_key(item), Color("#bf2030"))

	_update_counters()
	await get_tree().create_timer(0.18).timeout

	if not running:
		return
	if handled >= target_count:
		await finish_with_result(true, quick_success_key, 0.35)
		return
	if mistakes >= mistake_limit:
		await finish_with_result(false, quick_fail_key, 0.35)
		return

	choice_locked = false
	_set_buttons_enabled(true)
	_next_item()

func _next_item() -> void:
	if queue.is_empty():
		queue.clear()
		for index in range(item_defs.size()):
			queue.append(index)
		if shuffle_items:
			queue.shuffle()

	current_item = int(queue.pop_front())
	var item: Dictionary = item_defs[current_item]
	item_label.text = _item_text(item)
	_update_option_buttons(item)
	_animate_card_in()

func _update_option_buttons(item: Dictionary) -> void:
	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		var option: Dictionary = option_defs[index]
		button.text = _option_text(option, item)
		button.set_meta("action_id", String(option.get("id", "")))

func _option_text(option: Dictionary, item: Dictionary) -> String:
	if option.has("label_field"):
		return tr(String(item[String(option["label_field"])]))
	return tr(String(option.get("label_key", "")))

func _item_text(item: Dictionary) -> String:
	return tr(String(item.get("key", "")))

func _correct_action_for_item(item: Dictionary) -> String:
	if item.has("correct"):
		return String(item["correct"])
	if item.has("kind"):
		return String(item["kind"])
	return ""

func _good_feedback_key(item: Dictionary) -> String:
	return String(item.get("good_key", "QUICK_SORT_GOOD"))

func _bad_feedback_key(item: Dictionary) -> String:
	return String(item.get("bad_key", "QUICK_SORT_BAD"))

func _set_verdict(key: String, color: Color) -> void:
	if not verdict_label:
		return
	verdict_label.text = tr(key)
	verdict_label.add_theme_color_override("font_color", color)

func _update_counters() -> void:
	if progress_bar:
		progress_bar.max_value = target_count
		progress_bar.value = handled
	if progress_label:
		progress_label.text = "%d/%d" % [handled, target_count]
	if mistakes_label:
		mistakes_label.text = "X %d/%d" % [mistakes, mistake_limit]

func _set_buttons_enabled(enabled: bool) -> void:
	for button in option_buttons:
		button.disabled = not enabled

func _animate_card_in() -> void:
	if not card_panel:
		return
	card_panel.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.tween_property(card_panel, "scale", Vector2.ONE, 0.10)

func _on_choice_pressed(choice: String) -> void:
	_choose_action(choice)

func _on_action_pressed(action: String) -> void:
	_choose_action(action)

func _on_decision_pressed(decision: String) -> void:
	_choose_action(decision)

func _on_tool_pressed(tool: String) -> void:
	_choose_action(tool)

func _on_layer_pressed(action: String) -> void:
	_choose_action(action)

func _on_zone_pressed(dest: String) -> void:
	_choose_action(dest)

func _on_model_pressed(model_id: String) -> void:
	_choose_action(model_id)

func on_timeout() -> void:
	if handled > 0 and quick_timeout_success_key != "":
		await finish_with_result(true, quick_timeout_success_key, 0.35)
	else:
		await finish_with_result(false, quick_fail_key, 0.35)
