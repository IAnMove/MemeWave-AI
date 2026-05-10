extends "res://scripts/minigames/base_minigame.gd"

const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")

const TARGET_POPPED := 8
const BUBBLES := [
	{"key": "SYCOPHANT_YES_BOSS", "bad": true},
	{"key": "SYCOPHANT_GENIUS", "bad": true},
	{"key": "SYCOPHANT_DELETE_PROD", "bad": true},
	{"key": "SYCOPHANT_BENCHMARK", "bad": true},
	{"key": "SYCOPHANT_CONTEXT", "bad": false},
	{"key": "SYCOPHANT_RISK", "bad": false},
	{"key": "SYCOPHANT_TEST_FIRST", "bad": false},
	{"key": "SYCOPHANT_NOT_SURE", "bad": false}
]

var bubbles: Array[Dictionary] = []
var spawn_timer := 0.0
var popped := 0
var mistakes := 0
var honesty_fill: ColorRect
var user_label: Label

func _ready() -> void:
	configure("GAME_SYCO_TITLE", "SYCO_INSTRUCTIONS", "GAME_SYCO_DESC", "res://assets/art/sycophancy_whack_bg.png")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	_clear_bubbles()
	spawn_timer = 0.0
	popped = 0
	mistakes = 0
	score = 0
	if honesty_fill:
		honesty_fill.size.x = 0
	if user_label:
		user_label.text = tr("SYCO_USER_IDLE")
		user_label.add_theme_color_override("font_color", Color("#151515"))
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.42, 0.72)
		_spawn_bubble()
	for bubble in bubbles.duplicate():
		var node := bubble["node"] as Button
		node.position.y -= float(bubble["speed"]) * delta
		node.rotation = sin(Time.get_ticks_msec() * 0.004 + float(bubble["phase"])) * 0.04
		if node.position.y < 205.0:
			if bool(bubble["bad"]):
				mistakes += 1
				user_label.text = tr("SYCO_USER_FOOLED")
				user_label.add_theme_color_override("font_color", Color("#d91e18"))
			_remove_bubble(bubble)
			_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#eef7ff")
	add_child(bg)
	move_child(bg, 0)

	_sketch_panel(Vector2(76, 210), Vector2(816, 410), Color("#fffdf8"), true)
	_sketch_panel(Vector2(928, 210), Vector2(252, 410), Color("#fff7d6"), false)

	var chat_title := _outlined_label(tr("SYCO_CHAT_TITLE"), 35, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	chat_title.position = Vector2(110, 224)
	chat_title.size = Vector2(748, 50)
	content_layer.add_child(chat_title)

	var lane := ColorRect.new()
	lane.position = Vector2(118, 292)
	lane.size = Vector2(730, 250)
	lane.color = Color("#f8fbff")
	content_layer.add_child(lane)

	var track := ColorRect.new()
	track.position = Vector2(150, 565)
	track.size = Vector2(660, 18)
	track.color = Color("#d9d9d9")
	content_layer.add_child(track)

	honesty_fill = ColorRect.new()
	honesty_fill.position = Vector2.ZERO
	honesty_fill.size = Vector2.ZERO
	honesty_fill.color = Color("#63d471")
	track.add_child(honesty_fill)

	_icon("robot", Vector2(984, 242), Vector2(124, 124), Color("#91c9e8"))
	user_label = _outlined_label("", 27, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	user_label.position = Vector2(960, 395)
	user_label.size = Vector2(188, 110)
	content_layer.add_child(user_label)

	var hint := _outlined_label(tr("SYCO_HINT"), 20, Color("#151515"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(948, 542)
	hint.size = Vector2(220, 48)
	content_layer.add_child(hint)

func _spawn_bubble() -> void:
	if bubbles.size() >= 7:
		return
	var data: Dictionary = BUBBLES[randi_range(0, BUBBLES.size() - 1)]
	var bubble := Button.new()
	bubble.name = "DynamicSycoBubble"
	bubble.position = Vector2(randf_range(126, 682), 532)
	bubble.size = Vector2(168, 70)
	bubble.text = tr(data["key"])
	bubble.focus_mode = Control.FOCUS_NONE
	bubble.add_theme_font_size_override("font_size", 15)
	bubble.add_theme_color_override("font_color", Color("#151515"))
	bubble.add_theme_color_override("font_hover_color", Color("#151515"))
	bubble.add_theme_color_override("font_pressed_color", Color("#151515"))
	bubble.add_theme_color_override("font_outline_color", Color("#ffffff"))
	bubble.add_theme_constant_override("outline_size", 2)
	var fill := Color("#ffe0f2") if bool(data["bad"]) else Color("#e6ffe8")
	bubble.add_theme_stylebox_override("normal", make_style(fill, Color("#111111"), 3, 18))
	bubble.add_theme_stylebox_override("hover", make_style(fill.lightened(0.12), Color("#111111"), 3, 18))
	bubble.pressed.connect(_on_bubble_pressed.bind(bubble))
	content_layer.add_child(bubble)
	bubbles.append({"node": bubble, "bad": bool(data["bad"]), "speed": randf_range(80.0, 135.0), "phase": randf_range(0.0, TAU)})

func _on_bubble_pressed(node: Button) -> void:
	if not running:
		return
	var bubble := _find_bubble(node)
	if bubble.is_empty():
		return
	if bool(bubble["bad"]):
		popped += 1
		score = popped
		user_label.text = tr("SYCO_USER_HONEST")
		user_label.add_theme_color_override("font_color", Color("#11883a"))
		_update_honesty()
		_remove_bubble(bubble)
		if popped >= TARGET_POPPED:
			await finish_with_result(true, "SYCO_SUCCESS", 0.75)
			return
	else:
		mistakes += 1
		user_label.text = tr("SYCO_USER_HIT_TRUTH")
		user_label.add_theme_color_override("font_color", Color("#d91e18"))
		_remove_bubble(bubble)
	_update_status()

func _find_bubble(node: Button) -> Dictionary:
	for bubble in bubbles:
		if bubble["node"] == node:
			return bubble
	return {}

func _remove_bubble(bubble: Dictionary) -> void:
	bubbles.erase(bubble)
	var node := bubble["node"] as Control
	if is_instance_valid(node):
		node.queue_free()

func _clear_bubbles() -> void:
	for child in content_layer.get_children():
		if child.name == "DynamicSycoBubble":
			child.queue_free()
	bubbles.clear()

func _update_honesty() -> void:
	if honesty_fill:
		honesty_fill.size.x = 660.0 * min(1.0, float(popped) / float(TARGET_POPPED))

func _update_status() -> void:
	set_status(tr("SYCO_STATUS") % [popped, TARGET_POPPED, mistakes])

func _sketch_panel(pos: Vector2, panel_size: Vector2, fill: Color, hatch: bool) -> Control:
	var panel: Control = SketchPanel.new()
	panel.position = pos
	panel.size = panel_size
	panel.call("configure", fill, Color("#111111"), 4.0, 1.7, hatch, Color("#0000000d"))
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
	await finish_with_result(popped >= TARGET_POPPED, "SYCO_TIMEOUT_SUCCESS" if popped >= TARGET_POPPED else "SYCO_FAIL", 0.45)
