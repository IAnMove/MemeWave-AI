extends "res://scripts/minigames/base_minigame.gd"

const TARGET_MATCHES := 8
const MEMORY_SECONDS := 30.0
const GRID_COLUMNS := 4
const GRID_ORIGIN := Vector2(258, 210)
const CARD_SIZE := Vector2(176, 94)
const CARD_GAP := Vector2(18, 16)
const CAST := [
	{"id": "sam", "name_key": "MEMORY_SAM", "sprite": "res://assets/sprites/sam_face.png"},
	{"id": "elon", "name_key": "MEMORY_ELON", "sprite": "res://assets/sprites/elon_face.png"},
	{"id": "dario", "name_key": "MEMORY_DARIO", "sprite": "res://assets/sprites/dario_amodei.png"},
	{"id": "investor", "name_key": "MEMORY_INVESTOR", "sprite": "res://assets/sprites/investor.png"},
	{"id": "model", "name_key": "MEMORY_MODEL", "sprite": "res://assets/sprites/hungry_model.png"},
	{"id": "cursor", "name_key": "MEMORY_CURSOR", "sprite": "res://assets/sprites/benchmark_cursor.png"},
	{"id": "limit", "name_key": "MEMORY_LIMIT", "sprite": "res://assets/sprites/rate_limit.png"},
	{"id": "token", "name_key": "MEMORY_TOKEN", "sprite": "res://assets/sprites/token.png"}
]

var cards: Array[Dictionary] = []
var first_pick := -1
var matches := 0
var mistakes := 0
var resolving := false
var cast_label: Label

func _ready() -> void:
	configure(
		"GAME_MEMORY_TITLE",
		"MEMORY_INSTRUCTIONS",
		"GAME_MEMORY_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	time_left = MEMORY_SECONDS
	emit_signal("time_changed", time_left)
	first_pick = -1
	matches = 0
	mistakes = 0
	resolving = false
	_deal_cards()
	_update_status()
	if cast_label:
		cast_label.text = tr("MEMORY_CAST_NOTE")

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.color = Color("#19324b")
	add_child(bg)
	move_child(bg, 0)

	var board := PanelContainer.new()
	board.position = Vector2(218, 198)
	board.size = Vector2(844, 456)
	board.add_theme_stylebox_override("panel", make_style(Color("#fff7df"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(board)

	cast_label = make_label("", 22, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	cast_label.position = Vector2(312, 604)
	cast_label.size = Vector2(656, 34)
	content_layer.add_child(cast_label)

	_build_card_grid()

func _build_card_grid() -> void:
	for index in range(TARGET_MATCHES * 2):
		var button := Button.new()
		button.name = "DynamicMemoryCard"
		button.position = _card_position(index)
		button.size = CARD_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 42)
		button.add_theme_color_override("font_color", Color("#1d1d1d"))
		button.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
		button.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
		button.add_theme_color_override("font_disabled_color", Color("#1d1d1d"))
		button.add_theme_color_override("font_outline_color", Color("#ffffff"))
		button.add_theme_constant_override("outline_size", 4)
		button.pressed.connect(_on_card_pressed.bind(index))
		content_layer.add_child(button)

		var image := make_sprite("", Vector2(84, 58))
		image.position = Vector2(46, 7)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(image)

		var name := make_label("", 17, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
		name.position = Vector2(8, 62)
		name.size = Vector2(160, 26)
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name.add_theme_color_override("font_outline_color", Color("#ffffff"))
		name.add_theme_constant_override("outline_size", 2)
		button.add_child(name)

		cards.append({
			"node": button,
			"image": image,
			"label": name,
			"id": "",
			"name_key": "",
			"sprite": "",
			"revealed": false,
			"matched": false
		})
		_set_card_hidden(index)

func _deal_cards() -> void:
	var deck: Array[Dictionary] = []
	for entry in CAST:
		deck.append((entry as Dictionary).duplicate())
		deck.append((entry as Dictionary).duplicate())
	deck.shuffle()

	for index in cards.size():
		var data: Dictionary = deck[index]
		cards[index]["id"] = String(data["id"])
		cards[index]["name_key"] = String(data["name_key"])
		cards[index]["sprite"] = String(data["sprite"])
		cards[index]["revealed"] = false
		cards[index]["matched"] = false
		var button := cards[index]["node"] as Button
		button.disabled = false
		_set_card_hidden(index)

func _on_card_pressed(index: int) -> void:
	if not running or resolving:
		return
	if index < 0 or index >= cards.size():
		return
	if bool(cards[index]["matched"]) or bool(cards[index]["revealed"]):
		return

	play_action_sound("move")
	_set_card_revealed(index)
	if first_pick == -1:
		first_pick = index
		return

	var other := first_pick
	first_pick = -1
	if String(cards[index]["id"]) == String(cards[other]["id"]):
		_set_card_matched(index)
		_set_card_matched(other)
		matches += 1
		score = matches
		play_action_sound("collect")
		_update_status()
		if matches >= TARGET_MATCHES:
			await finish_with_result(true, "MEMORY_SUCCESS", 0.65)
		return

	mistakes += 1
	resolving = true
	play_action_sound("bad")
	_update_status()
	_set_card_wrong(index)
	_set_card_wrong(other)
	await get_tree().create_timer(0.42).timeout
	if is_instance_valid(self):
		_set_card_hidden(index)
		_set_card_hidden(other)
		resolving = false

func _set_card_hidden(index: int) -> void:
	cards[index]["revealed"] = false
	var button := cards[index]["node"] as Button
	button.text = "?"
	_set_card_style(button, Color("#8ec8ff"), Color("#1d1d1d"))
	(cards[index]["image"] as CanvasItem).visible = false
	(cards[index]["label"] as CanvasItem).visible = false

func _set_card_revealed(index: int) -> void:
	cards[index]["revealed"] = true
	var button := cards[index]["node"] as Button
	button.text = ""
	_set_card_style(button, Color("#ffffff"), Color("#1d1d1d"))
	var image := cards[index]["image"] as TextureRect
	image.texture = load(String(cards[index]["sprite"])) if ResourceLoader.exists(String(cards[index]["sprite"])) else null
	image.visible = true
	var label := cards[index]["label"] as Label
	label.text = tr(cards[index]["name_key"])
	label.visible = true

func _set_card_matched(index: int) -> void:
	cards[index]["matched"] = true
	var button := cards[index]["node"] as Button
	button.disabled = true
	_set_card_style(button, Color("#bdfb7f"), Color("#1d1d1d"))

func _set_card_wrong(index: int) -> void:
	var button := cards[index]["node"] as Button
	_set_card_style(button, Color("#ff9f9f"), Color("#1d1d1d"))

func _set_card_style(button: Button, fill: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", make_style(fill, border, 4, 8))
	button.add_theme_stylebox_override("hover", make_style(fill.lightened(0.12), border, 4, 8))
	button.add_theme_stylebox_override("pressed", make_style(fill.darkened(0.12), border, 4, 8))
	button.add_theme_stylebox_override("disabled", make_style(fill, border, 4, 8))

func _card_position(index: int) -> Vector2:
	var col := index % GRID_COLUMNS
	var row := index / GRID_COLUMNS
	return GRID_ORIGIN + Vector2(col * (CARD_SIZE.x + CARD_GAP.x), row * (CARD_SIZE.y + CARD_GAP.y))

func _update_status() -> void:
	set_status(tr("MEMORY_STATUS") % [matches, TARGET_MATCHES, mistakes])

func on_timeout() -> void:
	await finish_with_result(matches >= TARGET_MATCHES, "MEMORY_TIMEOUT_SUCCESS" if matches >= TARGET_MATCHES else "MEMORY_FAIL", 0.45)
