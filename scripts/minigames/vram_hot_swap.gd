extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")

const VRAM_LIMIT := 24
const TARGET_JOBS := 6
const MISTAKE_LIMIT := 4
const MODELS := [
	{"id": "whisper", "key": "VRAM_MODEL_WHISPER", "gb": 6, "color": "#66dbff", "icon": "speaker"},
	{"id": "qwen14", "key": "VRAM_MODEL_QWEN14", "gb": 9, "color": "#bdfb7f", "icon": "computer_good"},
	{"id": "gemma4", "key": "VRAM_MODEL_GEMMA4", "gb": 10, "color": "#ffef5f", "icon": "robot"},
	{"id": "gemma31", "key": "VRAM_MODEL_GEMMA31", "gb": 20, "color": "#ff9fd6", "icon": "star"},
	{"id": "flux", "key": "VRAM_MODEL_FLUX", "gb": 20, "color": "#8b4cff", "icon": "spark"},
	{"id": "wan", "key": "VRAM_MODEL_WAN", "gb": 24, "color": "#ff8f24", "icon": "plane"}
]
const TASKS := [
	{"key": "VRAM_TASK_AUDIO", "needs": ["whisper"], "icon": "speaker"},
	{"key": "VRAM_TASK_SUMMARY", "needs": ["gemma4"], "icon": "robot"},
	{"key": "VRAM_TASK_IMAGE", "needs": ["flux"], "icon": "spark"},
	{"key": "VRAM_TASK_SUBTITLES", "needs": ["whisper", "gemma4"], "icon": "computer_good"},
	{"key": "VRAM_TASK_AGENT", "needs": ["gemma31"], "icon": "star"},
	{"key": "VRAM_TASK_VIDEO", "needs": ["wan"], "icon": "plane"},
	{"key": "VRAM_TASK_CODE", "needs": ["qwen14"], "icon": "computer_good"}
]
const TASK_ICON_PATHS := {
	"VRAM_TASK_AUDIO": "res://assets/sprites/vram_task_audio.png",
	"VRAM_TASK_SUMMARY": "res://assets/sprites/vram_task_summary.png",
	"VRAM_TASK_IMAGE": "res://assets/sprites/vram_task_image.png",
	"VRAM_TASK_SUBTITLES": "res://assets/sprites/vram_task_subtitles.png",
	"VRAM_TASK_AGENT": "res://assets/sprites/vram_task_agent.png",
	"VRAM_TASK_VIDEO": "res://assets/sprites/vram_task_video.png",
	"VRAM_TASK_CODE": "res://assets/sprites/vram_task_code.png"
}
const MODEL_ICON_PATHS := {
	"whisper": "res://assets/sprites/vram_model_whisper.png",
	"qwen14": "res://assets/sprites/vram_model_qwen14.png",
	"gemma4": "res://assets/sprites/vram_model_gemma4.png",
	"gemma31": "res://assets/sprites/vram_model_gemma31.png",
	"flux": "res://assets/sprites/vram_model_flux.png",
	"wan": "res://assets/sprites/vram_model_wan.png"
}
const MODEL_SHORT_NAMES := {
	"whisper": "Whisper",
	"qwen14": "Qwen3",
	"gemma4": "Gemma4",
	"gemma31": "Gemma31",
	"flux": "FLUX.1",
	"wan": "Wan2.2"
}
const MODEL_TINY_NAMES := {
	"whisper": "Whis",
	"qwen14": "Qwen",
	"gemma4": "G4",
	"gemma31": "G31",
	"flux": "Flux",
	"wan": "Wan"
}
const GPU_ICON_PATH := "res://assets/sprites/vram_gpu_icon.png"

var loaded_models: Array[String] = []
var task_queue: Array = []
var current_task: Dictionary = {}
var current_step := 0
var jobs_done := 0
var mistakes := 0
var used_vram := 0
var model_buttons: Dictionary = {}
var loaded_rows: Control
var task_label: Label
var task_step_label: Label
var verdict_label: Label
var usage_label: Label
var queue_label: Label
var task_icon: TextureRect
var vram_tiles: Array[ColorRect] = []
var pips: Array[ColorRect] = []
var gpu_panel: Control

func _ready() -> void:
	configure(
		"GAME_VRAM_TITLE",
		"VRAM_INSTRUCTIONS",
		"GAME_VRAM_DESC",
		"res://assets/art/server_room_bg.png"
	)
	super._ready()
	if overlay_label:
		overlay_label.z_index = 200
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	loaded_models.clear()
	task_queue = TASKS.duplicate(true)
	current_task = {}
	current_step = 0
	jobs_done = 0
	mistakes = 0
	used_vram = 0
	score = 0
	_reset_pips()
	_next_task()
	_render_loaded_models()
	_update_vram()
	_update_status()
	_set_verdict("VRAM_READY", Color("#fff1c6"))

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#101729")
	add_child(bg)
	move_child(bg, 0)

	var glow := ColorRect.new()
	glow.position = Vector2(0, 196)
	glow.size = Vector2(1280, 524)
	glow.color = Color("#08203a88")
	content_layer.add_child(glow)

	_build_task_panel()
	_build_gpu_panel()
	_build_model_dock()
	_build_status_panel()
	status_label.position = Vector2(280, 646)
	status_label.size = Vector2(720, 54)

func _build_task_panel() -> void:
	var panel: Control = SketchPanel.new()
	panel.position = Vector2(42, 222)
	panel.size = Vector2(318, 390)
	panel.call("configure", Color("#fff7d6"), Color("#111111"), 4.0, 1.2, false)
	content_layer.add_child(panel)

	var title := _outlined_label(tr("VRAM_JOB_TITLE"), 29, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(68, 242)
	title.size = Vector2(266, 42)
	content_layer.add_child(title)

	task_icon = _sprite_icon(_task_icon_path("VRAM_TASK_AUDIO"), Vector2(128, 128))
	task_icon.name = "TaskIcon"
	task_icon.position = Vector2(133, 286)
	content_layer.add_child(task_icon)

	task_label = _outlined_label("", 28, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	task_label.position = Vector2(72, 410)
	task_label.size = Vector2(258, 66)
	content_layer.add_child(task_label)

	task_step_label = _outlined_label("", 20, Color("#1f5fbf"), HORIZONTAL_ALIGNMENT_CENTER)
	task_step_label.position = Vector2(72, 486)
	task_step_label.size = Vector2(258, 54)
	content_layer.add_child(task_step_label)

	queue_label = make_label("", 18, Color("#3d3d3d"), HORIZONTAL_ALIGNMENT_CENTER)
	queue_label.position = Vector2(70, 548)
	queue_label.size = Vector2(260, 36)
	content_layer.add_child(queue_label)

func _build_gpu_panel() -> void:
	gpu_panel = SketchPanel.new()
	gpu_panel.position = Vector2(398, 218)
	gpu_panel.size = Vector2(470, 402)
	gpu_panel.call("configure", Color("#182332"), Color("#66dbff"), 4.0, 1.6, true, Color("#66dbff18"))
	content_layer.add_child(gpu_panel)

	var title := _outlined_label(tr("VRAM_GPU_TITLE"), 32, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(470, 238)
	title.size = Vector2(342, 46)
	content_layer.add_child(title)

	var gpu_icon := _sprite_icon(GPU_ICON_PATH, Vector2(56, 56))
	gpu_icon.position = Vector2(420, 230)
	content_layer.add_child(gpu_icon)

	var tile_origin := Vector2(430, 306)
	vram_tiles.clear()
	for index in range(VRAM_LIMIT):
		var tile := ColorRect.new()
		tile.position = tile_origin + Vector2((index % 6) * 62, int(index / 6) * 42)
		tile.size = Vector2(52, 32)
		tile.color = Color("#243142")
		content_layer.add_child(tile)
		vram_tiles.append(tile)

	usage_label = _outlined_label("", 30, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	usage_label.position = Vector2(434, 486)
	usage_label.size = Vector2(398, 42)
	content_layer.add_child(usage_label)

	loaded_rows = Control.new()
	loaded_rows.position = Vector2(432, 532)
	loaded_rows.size = Vector2(398, 70)
	content_layer.add_child(loaded_rows)

func _build_model_dock() -> void:
	var panel: Control = SketchPanel.new()
	panel.position = Vector2(900, 222)
	panel.size = Vector2(330, 390)
	panel.call("configure", Color("#f3f6ff"), Color("#111111"), 4.0, 1.2, false)
	content_layer.add_child(panel)

	var title := _outlined_label(tr("VRAM_DOCK_TITLE"), 24, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(924, 238)
	title.size = Vector2(282, 58)
	content_layer.add_child(title)

	model_buttons.clear()
	for index in range(MODELS.size()):
		var model: Dictionary = MODELS[index]
		var button := _add_model_card(
			Vector2(924 + (index % 2) * 150, 314 + int(index / 2) * 84),
			Vector2(132, 70),
			model,
			_on_model_button_pressed.bind(String(model["id"]))
		)
		model_buttons[String(model["id"])] = button

func _build_status_panel() -> void:
	verdict_label = _outlined_label("", 25, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(442, 196)
	verdict_label.size = Vector2(380, 38)
	content_layer.add_child(verdict_label)

	for index in range(MISTAKE_LIMIT):
		var pip := ColorRect.new()
		pip.position = Vector2(574 + index * 36, 612)
		pip.size = Vector2(26, 14)
		pip.color = Color("#384456")
		content_layer.add_child(pip)
		pips.append(pip)

func _on_model_button_pressed(model_id: String) -> void:
	if not running or current_task.is_empty():
		return

	var needed := _needed_model_id()
	if model_id != needed:
		_register_mistake("VRAM_WRONG_MODEL")
		return

	if not loaded_models.has(model_id):
		if not _try_load_model(model_id):
			return

	_process_current_step(model_id)

func _try_load_model(model_id: String) -> bool:
	var model := _model_for_id(model_id)
	if model.is_empty():
		return false

	var gb := int(model["gb"])
	if used_vram + gb > VRAM_LIMIT:
		_register_mistake("VRAM_OOM")
		_shake_gpu()
		return false

	loaded_models.append(model_id)
	used_vram += gb
	play_action_sound("move")
	_set_verdict("VRAM_LOADED", Color("#5cff86"))
	_render_loaded_models()
	_update_vram()
	return true

func _process_current_step(model_id: String) -> void:
	if current_task.is_empty():
		return
	var needs: Array = current_task["needs"]
	if current_step >= needs.size() or String(needs[current_step]) != model_id:
		_register_mistake("VRAM_WRONG_MODEL")
		return

	current_step += 1
	play_action_sound("collect")
	_set_verdict("VRAM_STEP_DONE", Color("#5cff86"))

	if current_step >= needs.size():
		jobs_done += 1
		score = jobs_done
		if jobs_done >= TARGET_JOBS:
			await finish_with_result(true, "VRAM_SUCCESS", 0.62)
			return
		_next_task()
	else:
		_update_task_ui()
	_update_status()

func _eject_model(model_id: String) -> void:
	if not running:
		return
	if not loaded_models.has(model_id):
		return

	loaded_models.erase(model_id)
	used_vram = maxi(0, used_vram - int(_model_for_id(model_id)["gb"]))
	play_action_sound("bad")
	_set_verdict("VRAM_UNLOADED", Color("#ffef5f"))
	_render_loaded_models()
	_update_vram()
	_update_status()

func _register_mistake(feedback_key: String) -> void:
	mistakes += 1
	play_action_sound("bad")
	_mark_mistake()
	_set_verdict(feedback_key, Color("#ff7777"))
	_update_status()
	if mistakes >= MISTAKE_LIMIT:
		await finish_with_result(false, "VRAM_FAIL", 0.55)

func _next_task() -> void:
	if task_queue.is_empty():
		task_queue = TASKS.duplicate(true)
	current_task = task_queue.pop_front()
	current_step = 0
	_update_task_ui()
	_update_status()

func _update_task_ui() -> void:
	if current_task.is_empty():
		return
	task_label.text = tr(String(current_task["key"]))
	if task_icon:
		task_icon.texture = load(_task_icon_path(String(current_task["key"])))

	var needs: Array = current_task["needs"]
	var step_parts: Array[String] = []
	for index in range(needs.size()):
		var model := _model_for_id(String(needs[index]))
		var prefix := ">"
		if index < current_step:
			prefix = "OK"
		elif index > current_step:
			prefix = "-"
		step_parts.append("%s %s" % [prefix, tr(String(model["key"]))])
	task_step_label.text = "\n".join(step_parts)

	var next_names: Array[String] = []
	for index in range(mini(2, task_queue.size())):
		next_names.append(tr(String(task_queue[index]["key"])))
	queue_label.text = tr("VRAM_NEXT") % " / ".join(next_names) if not next_names.is_empty() else ""

func _render_loaded_models() -> void:
	if not loaded_rows:
		return
	for child in loaded_rows.get_children():
		child.queue_free()

	for index in range(loaded_models.size()):
		var model := _model_for_id(loaded_models[index])
		var button := _add_model_card(
			Vector2(index * 100, 0),
			Vector2(92, 58),
			model,
			_eject_model.bind(String(model["id"])),
			loaded_rows,
			true
		)
		button.tooltip_text = tr("VRAM_EJECT")

func _update_vram() -> void:
	for tile in vram_tiles:
		tile.color = Color("#243142")

	var cursor := 0
	for model_id in loaded_models:
		var model := _model_for_id(model_id)
		var color := Color(String(model["color"]))
		for _slot in range(int(model["gb"])):
			if cursor >= vram_tiles.size():
				break
			vram_tiles[cursor].color = color
			cursor += 1

	if usage_label:
		usage_label.text = "%d / %d GB" % [used_vram, VRAM_LIMIT]

func _update_status() -> void:
	set_status(tr("VRAM_STATUS") % [jobs_done, TARGET_JOBS, used_vram, mistakes])

func _needed_model_id() -> String:
	if current_task.is_empty():
		return ""
	var needs: Array = current_task["needs"]
	if current_step < 0 or current_step >= needs.size():
		return ""
	return String(needs[current_step])

func _model_for_id(model_id: String) -> Dictionary:
	for model_variant in MODELS:
		var model: Dictionary = model_variant
		if String(model["id"]) == model_id:
			return model
	return {}

func _set_verdict(key: String, color: Color) -> void:
	if not verdict_label:
		return
	verdict_label.text = tr(key)
	verdict_label.add_theme_color_override("font_color", color)

func _mark_mistake() -> void:
	var index := int(clamp(mistakes - 1, 0, pips.size() - 1))
	if index >= 0 and index < pips.size():
		pips[index].color = Color("#ff5b5b")

func _reset_pips() -> void:
	for pip in pips:
		pip.color = Color("#384456")

func _shake_gpu() -> void:
	if not gpu_panel:
		return
	var original := gpu_panel.position
	var tween := create_tween()
	tween.tween_property(gpu_panel, "position", original + Vector2(10, 0), 0.04)
	tween.tween_property(gpu_panel, "position", original + Vector2(-10, 0), 0.04)
	tween.tween_property(gpu_panel, "position", original, 0.04)

func _outlined_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := make_label(text, font_size, color, align)
	label.add_theme_color_override("font_outline_color", Color("#ffffff") if color != Color("#ffffff") else Color("#111111"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _task_icon_path(task_key: String) -> String:
	return String(TASK_ICON_PATHS.get(task_key, TASK_ICON_PATHS["VRAM_TASK_SUMMARY"]))

func _model_icon_path(model_id: String) -> String:
	return String(MODEL_ICON_PATHS.get(model_id, MODEL_ICON_PATHS["gemma4"]))

func _model_short_label(model: Dictionary, compact: bool = false) -> String:
	var model_id := String(model["id"])
	if compact:
		return String(MODEL_TINY_NAMES.get(model_id, MODEL_SHORT_NAMES.get(model_id, tr(String(model["key"])))))
	return String(MODEL_SHORT_NAMES.get(model_id, tr(String(model["key"]))))

func _sprite_icon(path: String, icon_size: Vector2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.size = icon_size
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	return sprite

func _empty_button_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

func _add_model_card(
		pos: Vector2,
		card_size: Vector2,
		model: Dictionary,
		callback: Callable,
		parent: Control = null,
		compact: bool = false
	) -> Button:
	if not parent:
		parent = content_layer

	var card: Control = SketchPanel.new()
	card.position = pos
	card.size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.call("configure", Color(String(model["color"])), Color("#111111"), 4.0, 1.0, false)
	parent.add_child(card)

	var icon_size := Vector2(42, 42) if compact else Vector2(48, 48)
	var icon := _sprite_icon(_model_icon_path(String(model["id"])), icon_size)
	icon.position = pos + (Vector2(4, 8) if compact else Vector2(6, 12))
	parent.add_child(icon)

	var name_label := _outlined_label(_model_short_label(model, compact), 12 if compact else 13, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	name_label.position = pos + (Vector2(48, 4) if compact else Vector2(58, 8))
	name_label.size = Vector2(card_size.x - (52 if compact else 64), 30)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(name_label)

	var gb_label := _outlined_label(("%dGB" if compact else "%d GB") % int(model["gb"]), 13 if compact else 16, Color("#151515"), HORIZONTAL_ALIGNMENT_LEFT)
	gb_label.position = pos + (Vector2(50, 31) if compact else Vector2(58, 42))
	gb_label.size = Vector2(card_size.x - (54 if compact else 64), 24)
	gb_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(gb_label)

	var button := Button.new()
	button.position = pos
	button.size = card_size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("normal", _empty_button_style())
	button.add_theme_stylebox_override("hover", _empty_button_style())
	button.add_theme_stylebox_override("pressed", _empty_button_style())
	button.add_theme_stylebox_override("focus", _empty_button_style())
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func on_timeout() -> void:
	var success := jobs_done >= maxi(2, TARGET_JOBS - 1)
	await finish_with_result(success, "VRAM_TIMEOUT_SUCCESS" if success else "VRAM_TIMEOUT_FAIL", 0.45)
