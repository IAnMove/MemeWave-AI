extends Control

signal finished(success: bool, score: int)
signal time_changed(time_left: float)

const ROUND_SECONDS := 15.0
const TUTORIAL_ACTION_IMAGES := {
	"click": [
		"res://assets/tutorial_actions/click_1_mouse.png",
		"res://assets/tutorial_actions/click_2_press.png",
		"res://assets/tutorial_actions/click_3_done.png"
	],
	"drag": [
		"res://assets/tutorial_actions/drag_1_grab.png",
		"res://assets/tutorial_actions/drag_2_move.png",
		"res://assets/tutorial_actions/drag_3_drop.png"
	],
	"drag_right": [
		"res://assets/tutorial_actions/drag_right_1_click.png",
		"res://assets/tutorial_actions/drag_right_2_drag.png",
		"res://assets/tutorial_actions/drag_right_3_drop.png"
	],
	"move": [
		"res://assets/tutorial_actions/move_1_keys.png",
		"res://assets/tutorial_actions/move_2_left.png",
		"res://assets/tutorial_actions/move_3_right.png"
	]
}
const RESULT_SUCCESS_SOUND_PATH := "res://assets/sounds/result_success.wav"
const RESULT_FAIL_SOUND_PATH := "res://assets/sounds/result_fail.wav"
const ACTION_COLLECT_SOUND_PATH := "res://assets/sounds/action_collect.wav"
const ACTION_BAD_SOUND_PATH := "res://assets/sounds/action_bad.wav"
const ACTION_MOVE_SOUND_PATH := "res://assets/sounds/action_move.wav"
const RESULT_OVERLAY_Z := 1000

var running := false
var time_left := ROUND_SECONDS
var score := 0
var title := ""
var instructions := ""
var intention := ""
var background_path := ""

var title_label: Label
var instruction_label: Label
var status_label: Label
var content_layer: Control
var overlay_label: Label
var result_backdrop: PanelContainer
var tutorial_panel: PanelContainer
var result_sound_player: AudioStreamPlayer
var result_success_stream: AudioStream
var result_fail_stream: AudioStream
var action_sound_player: AudioStreamPlayer
var action_collect_stream: AudioStream
var action_bad_stream: AudioStream
var action_move_stream: AudioStream

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_full_rect(self)
	_build_common_ui()

func configure(new_title: String, new_instructions: String, new_intention: String, new_background_path: String = "") -> void:
	title = new_title
	instructions = new_instructions
	intention = new_intention
	background_path = new_background_path
	if is_node_ready():
		_build_common_ui()

func start_minigame() -> void:
	running = true
	time_left = ROUND_SECONDS
	score = 0
	overlay_label.visible = false
	if result_backdrop:
		result_backdrop.visible = false
	set_status("")
	emit_signal("time_changed", time_left)

func _process(delta: float) -> void:
	if not running:
		return

	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		emit_signal("time_changed", time_left)
		on_timeout()
		return

	emit_signal("time_changed", time_left)

func on_timeout() -> void:
	finish(false)

func finish(success: bool) -> void:
	if not running:
		return

	running = false
	play_result_sound(success)
	emit_signal("finished", success, score)

func finish_with_result(success: bool, text: String, delay: float = 0.45) -> void:
	if not running:
		return

	running = false
	play_result_sound(success)
	show_result(tr(text), success)
	await get_tree().create_timer(delay).timeout
	emit_signal("finished", success, score)

func set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func show_result(text: String, success: bool) -> void:
	if result_backdrop:
		result_backdrop.visible = true
		result_backdrop.z_index = RESULT_OVERLAY_Z - 1
		result_backdrop.add_theme_stylebox_override(
			"panel",
			make_style(Color("#101923df") if success else Color("#23101bdf"), Color("#fff6d1"), 5, 8)
		)
		result_backdrop.move_to_front()
	overlay_label.text = text
	overlay_label.add_theme_color_override("font_color", Color("#fff6d1") if success else Color("#ffffff"))
	overlay_label.add_theme_color_override("font_outline_color", Color("#111111"))
	overlay_label.z_index = RESULT_OVERLAY_Z
	overlay_label.visible = true
	overlay_label.move_to_front()

func _build_common_ui() -> void:
	for child in get_children():
		child.queue_free()

	var background := TextureRect.new()
	set_full_rect(background)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if background_path != "" and ResourceLoader.exists(background_path):
		background.texture = load(background_path)
	add_child(background)

	var tint := ColorRect.new()
	set_full_rect(tint)
	tint.color = Color(0.04, 0.035, 0.045, 0.16)
	add_child(tint)

	var header := PanelContainer.new()
	header.position = Vector2(32, 92)
	header.size = Vector2(1216, 104)
	header.z_index = 20
	header.add_theme_stylebox_override("panel", make_style(Color("#fff7c7"), Color("#1d1d1d"), 5, 6))
	add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 230)
	header_margin.add_theme_constant_override("margin_right", 210)
	header_margin.add_theme_constant_override("margin_top", 2)
	header_margin.add_theme_constant_override("margin_bottom", 2)
	header.add_child(header_margin)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header_margin.add_child(header_box)

	title_label = make_label(tr(title), 42, Color("#1b1b1b"), HORIZONTAL_ALIGNMENT_CENTER)
	title_label.custom_minimum_size = Vector2(760, 48)
	title_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	title_label.add_theme_constant_override("outline_size", 2)
	header_box.add_child(title_label)

	instruction_label = make_label(tr(instructions), 21, Color("#222222"), HORIZONTAL_ALIGNMENT_CENTER)
	instruction_label.custom_minimum_size = Vector2(760, 44)
	header_box.add_child(instruction_label)

	content_layer = Control.new()
	content_layer.position = Vector2.ZERO
	content_layer.size = Vector2(1280, 720)
	content_layer.z_index = 0
	add_child(content_layer)

	_build_action_tutorial()

	status_label = make_label("", 28, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	status_label.position = Vector2(40, 645)
	status_label.size = Vector2(1200, 45)
	status_label.z_index = 25
	status_label.add_theme_color_override("font_outline_color", Color("#151515"))
	status_label.add_theme_constant_override("outline_size", 8)
	add_child(status_label)

	result_backdrop = PanelContainer.new()
	result_backdrop.position = Vector2(180, 262)
	result_backdrop.size = Vector2(920, 164)
	result_backdrop.z_index = RESULT_OVERLAY_Z - 1
	result_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_backdrop.visible = false
	result_backdrop.add_theme_stylebox_override("panel", make_style(Color("#101923df"), Color("#fff6d1"), 5, 8))
	add_child(result_backdrop)

	overlay_label = make_label("", 74, Color("#fff6d1"), HORIZONTAL_ALIGNMENT_CENTER)
	overlay_label.position = Vector2(0, 272)
	overlay_label.size = Vector2(1280, 140)
	overlay_label.z_index = RESULT_OVERLAY_Z
	overlay_label.add_theme_constant_override("outline_size", 12)
	overlay_label.add_theme_color_override("font_outline_color", Color("#129447"))
	overlay_label.visible = false
	add_child(overlay_label)

	_build_result_sounds()
	_build_action_sounds()

func play_result_sound(success: bool) -> void:
	if not result_sound_player:
		return

	result_sound_player.stop()
	result_sound_player.stream = result_success_stream if success else result_fail_stream
	result_sound_player.play()

func play_action_sound(kind: String = "collect") -> void:
	if not action_sound_player:
		return

	var stream := action_collect_stream
	if kind == "bad":
		stream = action_bad_stream
	elif kind == "move":
		stream = action_move_stream
	if not stream:
		return

	action_sound_player.stop()
	action_sound_player.stream = stream
	action_sound_player.play()

func _build_result_sounds() -> void:
	result_success_stream = _load_sound_stream(RESULT_SUCCESS_SOUND_PATH)
	if not result_success_stream:
		result_success_stream = _make_result_sound(true)
	result_fail_stream = _load_sound_stream(RESULT_FAIL_SOUND_PATH)
	if not result_fail_stream:
		result_fail_stream = _make_result_sound(false)
	result_sound_player = AudioStreamPlayer.new()
	result_sound_player.name = "ResultSound"
	result_sound_player.volume_db = -6.0
	add_child(result_sound_player)

func _build_action_sounds() -> void:
	action_collect_stream = _load_sound_stream(ACTION_COLLECT_SOUND_PATH)
	if not action_collect_stream:
		action_collect_stream = result_success_stream
	action_bad_stream = _load_sound_stream(ACTION_BAD_SOUND_PATH)
	if not action_bad_stream:
		action_bad_stream = result_fail_stream
	action_move_stream = _load_sound_stream(ACTION_MOVE_SOUND_PATH)
	if not action_move_stream:
		action_move_stream = action_collect_stream

	action_sound_player = AudioStreamPlayer.new()
	action_sound_player.name = "ActionSound"
	action_sound_player.volume_db = -8.0
	add_child(action_sound_player)

func _load_sound_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _make_result_sound(success: bool) -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 0.36 if success else 0.32
	var sample_count := int(float(mix_rate) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t: float = float(index) / float(mix_rate)
		var progress: float = t / duration
		var attack: float = clampf(t / 0.025, 0.0, 1.0)
		var release: float = clampf(1.0 - progress, 0.0, 1.0)
		var envelope: float = attack * release * release
		var freq: float
		var wave: float
		var gain: float

		if success:
			if progress < 0.34:
				freq = 523.25
			elif progress < 0.68:
				freq = 659.25
			else:
				freq = 783.99
			wave = sin(TAU * freq * t) + sin(TAU * freq * 2.0 * t) * 0.12
			gain = 0.30
		else:
			freq = lerpf(246.94, 130.81, progress)
			wave = sin(TAU * freq * t) + sin(TAU * freq * 0.5 * t) * 0.28 + sin(TAU * freq * 3.0 * t) * 0.10
			gain = 0.26

		var sample := int(clamp(wave * envelope * gain, -1.0, 1.0) * 32767.0)
		data.encode_s16(index * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream

func _build_action_tutorial() -> void:
	var action_kind := _resolve_tutorial_action_kind()
	var image_paths: Array = TUTORIAL_ACTION_IMAGES.get(action_kind, [])
	if image_paths.is_empty():
		return

	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "ActionTutorial"
	tutorial_panel.position = Vector2(52, 108)
	tutorial_panel.size = Vector2(202, 72)
	tutorial_panel.z_index = 60
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.add_theme_stylebox_override("panel", make_style(Color("#fffdf8d8"), Color("#1d1d1d"), 3, 6))
	add_child(tutorial_panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(196, 66)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	tutorial_panel.add_child(row)

	for path in image_paths:
		var frame := make_sprite(String(path), Vector2(58, 58))
		frame.custom_minimum_size = Vector2(58, 58)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(frame)

func _resolve_tutorial_action_kind() -> String:
	var text := "%s %s" % [instructions, tr(instructions)]
	text = text.to_lower()
	if (
		(text.find("drag") != -1 or text.find("arrastra") != -1)
		and (text.find("right") != -1 or text.find("derecha") != -1)
	):
		return "drag_right"
	if text.find("drag") != -1 or text.find("arrastra") != -1:
		return "drag"
	if (
		text.find("move") != -1
		or text.find("mueve") != -1
		or text.find("a/d") != -1
		or text.find("arrows") != -1
		or text.find("flechas") != -1
	):
		return "move"
	return "click"

func hide_common_minigame_header() -> void:
	if not title_label:
		return

	var header_box := title_label.get_parent()
	if not header_box:
		return

	var header := header_box.get_parent() as Control
	if header:
		header.visible = false

func hide_base_status() -> void:
	if status_label:
		status_label.visible = false

func set_full_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0

func make_label(text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func make_style(fill: Color, border: Color, border_width: int = 4, corner_radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	return style

func make_button(text: String, font_size: int = 28, fill: Color = Color("#ffdd57")) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_focus_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_disabled_color", Color("#6b6b6b"))
	button.add_theme_color_override("font_outline_color", Color("#ffffff"))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", make_style(fill, Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("hover", make_style(fill.lightened(0.18), Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("pressed", make_style(fill.darkened(0.16), Color("#1d1d1d"), 4, 8))
	return button

func make_sprite(path: String, size: Vector2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.size = size
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	return sprite

func make_sprite_button(path: String, size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):
		button.texture_normal = load(path)
	return button
