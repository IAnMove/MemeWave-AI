extends "res://scripts/minigames/base_minigame.gd"

const TARGET_FACTS := 1
const FACT_ROUNDS := [
	{
		"person_key": "HALLU_PERSON_CURIE",
		"portrait": "res://assets/sprites/marie_curie.png",
		"claims": [
			{"key": "HALLU_CURIE_TRUE", "real": true},
			{"key": "HALLU_CURIE_FALSE_1", "real": false},
			{"key": "HALLU_CURIE_FALSE_2", "real": false},
			{"key": "HALLU_CURIE_FALSE_3", "real": false}
		]
	},
	{
		"person_key": "HALLU_PERSON_EINSTEIN",
		"portrait": "res://assets/sprites/einstein.png",
		"claims": [
			{"key": "HALLU_EINSTEIN_TRUE", "real": true},
			{"key": "HALLU_EINSTEIN_FALSE_1", "real": false},
			{"key": "HALLU_EINSTEIN_FALSE_2", "real": false},
			{"key": "HALLU_EINSTEIN_FALSE_3", "real": false}
		]
	},
	{
		"person_key": "HALLU_PERSON_CLEOPATRA",
		"portrait": "res://assets/sprites/cleopatra.png",
		"claims": [
			{"key": "HALLU_CLEOPATRA_TRUE", "real": true},
			{"key": "HALLU_CLEOPATRA_FALSE_1", "real": false},
			{"key": "HALLU_CLEOPATRA_FALSE_2", "real": false},
			{"key": "HALLU_CLEOPATRA_FALSE_3", "real": false}
		]
	}
]

var cards: Array[Dictionary] = []
var current_fact := 0
var forced_fact_index := -1
var hits := 0
var mistakes := 0
var person_label: Label
var detector_label: Label
var prompt_label: Label
var portrait_sprite: TextureRect

func _ready() -> void:
	configure(
		"GAME_HALLU_TITLE",
		"HALLU_INSTRUCTIONS",
		"GAME_HALLU_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	if forced_fact_index >= 0:
		current_fact = forced_fact_index % FACT_ROUNDS.size()
	else:
		current_fact = randi_range(0, FACT_ROUNDS.size() - 1)
	hits = 0
	mistakes = 0
	_show_fact_round()
	_update_detector("idle")
	_update_status()

func set_fact_round(fact_index: int) -> void:
	forced_fact_index = fact_index

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#24152f")
	add_child(bg)
	move_child(bg, 0)

	var file_panel := PanelContainer.new()
	file_panel.position = Vector2(74, 220)
	file_panel.size = Vector2(1128, 392)
	file_panel.add_theme_stylebox_override("panel", make_style(Color("#fff0f7"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(file_panel)

	var portrait := PanelContainer.new()
	portrait.position = Vector2(112, 252)
	portrait.size = Vector2(250, 292)
	portrait.add_theme_stylebox_override("panel", make_style(Color("#f8ffe8"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(portrait)

	portrait_sprite = make_sprite("", Vector2(210, 150))
	portrait_sprite.position = Vector2(132, 266)
	content_layer.add_child(portrait_sprite)

	person_label = make_label("", 30, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	person_label.position = Vector2(126, 426)
	person_label.size = Vector2(222, 56)
	person_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	person_label.add_theme_constant_override("outline_size", 3)
	content_layer.add_child(person_label)

	detector_label = make_label("", 25, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	detector_label.position = Vector2(124, 486)
	detector_label.size = Vector2(226, 44)
	content_layer.add_child(detector_label)

	prompt_label = make_label(tr("HALLU_QUESTION"), 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.position = Vector2(410, 238)
	prompt_label.size = Vector2(736, 46)
	content_layer.add_child(prompt_label)

	_build_option_cards()

func _build_option_cards() -> void:
	var positions := [
		Vector2(404, 304), Vector2(780, 304),
		Vector2(404, 452), Vector2(780, 452)
	]

	for index in positions.size():
		var card := Button.new()
		card.name = "DynamicHallucination"
		card.position = positions[index]
		card.size = Vector2(330, 110)
		card.focus_mode = Control.FOCUS_NONE
		card.add_theme_font_size_override("font_size", 20)
		card.add_theme_color_override("font_color", Color("#1d1d1d"))
		card.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
		card.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
		card.add_theme_color_override("font_disabled_color", Color("#1d1d1d"))
		card.add_theme_color_override("font_outline_color", Color("#ffffff"))
		card.add_theme_constant_override("outline_size", 2)
		_set_card_style(card, "normal")
		card.pressed.connect(_on_card_pressed.bind(card))
		content_layer.add_child(card)
		cards.append({"node": card, "real": false})

func _show_fact_round() -> void:
	if current_fact >= FACT_ROUNDS.size():
		return

	var round_data: Dictionary = FACT_ROUNDS[current_fact]
	person_label.text = tr(round_data["person_key"])
	prompt_label.text = tr("HALLU_QUESTION")
	if portrait_sprite and ResourceLoader.exists(round_data["portrait"]):
		portrait_sprite.texture = load(round_data["portrait"])
	var claims: Array = (round_data["claims"] as Array).duplicate()
	claims.shuffle()
	for index in cards.size():
		var claim: Dictionary = claims[index]
		var card := cards[index]["node"] as Button
		cards[index]["real"] = bool(claim["real"])
		card.text = tr(claim["key"])
		card.disabled = false
		card.scale = Vector2.ONE
		_set_card_style(card, "normal")

func _on_card_pressed(node: Button) -> void:
	if not running:
		return

	var card := _find_card(node)
	if card.is_empty() or bool(node.disabled):
		return

	if bool(card["real"]):
		hits += 1
		score = hits
		play_action_sound("collect")
		_update_detector("good")
		_set_card_style(node, "good")
		_set_cards_disabled(true)
		await get_tree().create_timer(0.35).timeout
		await finish_with_result(true, "HALLU_SUCCESS", 0.65)
		return
	else:
		mistakes += 1
		play_action_sound("bad")
		_update_detector("bad")
		_set_card_style(node, "bad")
		node.disabled = true

	_update_status()

func _find_card(node: Button) -> Dictionary:
	for card in cards:
		if card["node"] == node:
			return card
	return {}

func _set_cards_disabled(disabled: bool) -> void:
	for card in cards:
		var node := card["node"] as Button
		if is_instance_valid(node):
			node.disabled = disabled

func _set_card_style(card: Button, state: String) -> void:
	var fill := Color("#ffffff")
	if state == "good":
		fill = Color("#bdfb7f")
	elif state == "bad":
		fill = Color("#ff9f9f")
	card.add_theme_stylebox_override("normal", make_style(fill, Color("#1d1d1d"), 4, 8))
	card.add_theme_stylebox_override("hover", make_style(fill.lightened(0.12), Color("#1d1d1d"), 4, 8))
	card.add_theme_stylebox_override("pressed", make_style(fill.darkened(0.12), Color("#1d1d1d"), 4, 8))
	card.add_theme_stylebox_override("disabled", make_style(fill, Color("#1d1d1d"), 4, 8))

func _update_detector(state: String) -> void:
	if state == "good":
		detector_label.text = tr("HALLU_DETECTOR_GOOD")
		detector_label.add_theme_color_override("font_color", Color("#176c39"))
	elif state == "bad":
		detector_label.text = tr("HALLU_DETECTOR_BAD")
		detector_label.add_theme_color_override("font_color", Color("#bf2030"))
	else:
		detector_label.text = tr("HALLU_DETECTOR_IDLE")
		detector_label.add_theme_color_override("font_color", Color("#1d1d1d"))

func _update_status() -> void:
	set_status(tr("HALLU_STATUS") % [hits, TARGET_FACTS, mistakes])

func on_timeout() -> void:
	var success := hits >= TARGET_FACTS
	await finish_with_result(success, "HALLU_TIMEOUT_SUCCESS" if success else "HALLU_FAIL", 0.45)
