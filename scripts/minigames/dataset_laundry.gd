extends "res://scripts/minigames/base_minigame.gd"

const TARGET_SORTED := 9
const DOCUMENTS := [
	{"key": "DATASET_DOC_API", "kind": "train"},
	{"key": "DATASET_DOC_TESTS", "kind": "train"},
	{"key": "DATASET_DOC_BUG", "kind": "train"},
	{"key": "DATASET_DOC_LICENSED", "kind": "train"},
	{"key": "DATASET_DOC_SCREENSHOT", "kind": "review"},
	{"key": "DATASET_DOC_SECRET", "kind": "review"},
	{"key": "DATASET_DOC_RANDOM", "kind": "review"},
	{"key": "DATASET_DOC_FORUM", "kind": "review"},
	{"key": "DATASET_DOC_PII", "kind": "review"}
]

var current_doc := -1
var sorted := 0
var mistakes := 0
var doc_label: Label
var doc_badge: Label
var train_button: Button
var review_button: Button
var model_mood: Label
var sorted_label: Label
var mistakes_label: Label
var washer_spin := 0.0
var washer_sprite: PanelContainer

func _ready() -> void:
	configure(
		"GAME_DATASET_TITLE",
		"DATASET_INSTRUCTIONS",
		"GAME_DATASET_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_doc = -1
	sorted = 0
	mistakes = 0
	score = 0
	washer_spin = 0.0
	model_mood.text = tr("DATASET_MODEL_IDLE")
	train_button.disabled = false
	review_button.disabled = false
	_spawn_document()
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return

	washer_spin += delta * (6.0 if mistakes == 0 else 10.0)
	washer_sprite.rotation = sin(washer_spin) * 0.035

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#18202a")
	add_child(bg)
	move_child(bg, 0)

	_build_document_panel()
	_build_action_buttons()
	_build_model_panel()

func _build_document_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(354, 230)
	panel.size = Vector2(572, 356)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("DATASET_DOC_TITLE"), 32, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(390, 252)
	title.size = Vector2(500, 42)
	content_layer.add_child(title)

	var doc_card := PanelContainer.new()
	doc_card.position = Vector2(426, 320)
	doc_card.size = Vector2(428, 132)
	doc_card.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(doc_card)

	doc_label = make_label("", 31, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	doc_label.position = Vector2(450, 338)
	doc_label.size = Vector2(380, 82)
	doc_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	doc_label.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(doc_label)

	doc_badge = make_label("", 20, Color("#3d3d3d"), HORIZONTAL_ALIGNMENT_CENTER)
	doc_badge.position = Vector2(450, 420)
	doc_badge.size = Vector2(380, 28)
	content_layer.add_child(doc_badge)

	washer_sprite = PanelContainer.new()
	washer_sprite.position = Vector2(555, 478)
	washer_sprite.size = Vector2(170, 78)
	washer_sprite.pivot_offset = Vector2(85, 39)
	washer_sprite.add_theme_stylebox_override("panel", make_style(Color("#66c6ff"), Color("#1d1d1d"), 5, 12))
	content_layer.add_child(washer_sprite)

	var washer_label := make_label(tr("DATASET_WASHER"), 23, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	washer_sprite.add_child(washer_label)

func _build_action_buttons() -> void:
	train_button = make_button(tr("DATASET_TRAIN"), 28, Color("#bdfb7f"))
	train_button.position = Vector2(96, 344)
	train_button.size = Vector2(226, 94)
	train_button.pressed.connect(_on_choice_pressed.bind("train"))
	content_layer.add_child(train_button)

	var train_hint := make_label(tr("DATASET_TRAIN_HINT"), 20, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	train_hint.position = Vector2(88, 452)
	train_hint.size = Vector2(242, 58)
	train_hint.add_theme_color_override("font_outline_color", Color("#111111"))
	train_hint.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(train_hint)

	review_button = make_button(tr("DATASET_REVIEW"), 28, Color("#ff9fd6"))
	review_button.position = Vector2(958, 344)
	review_button.size = Vector2(226, 94)
	review_button.pressed.connect(_on_choice_pressed.bind("review"))
	content_layer.add_child(review_button)

	var review_hint := make_label(tr("DATASET_REVIEW_HINT"), 20, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	review_hint.position = Vector2(950, 452)
	review_hint.size = Vector2(242, 58)
	review_hint.add_theme_color_override("font_outline_color", Color("#111111"))
	review_hint.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(review_hint)

func _build_model_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(86, 544)
	panel.size = Vector2(1108, 78)
	panel.add_theme_stylebox_override("panel", make_style(Color("#111820"), Color("#2f3b47"), 3, 8))
	content_layer.add_child(panel)

	model_mood = make_label("", 26, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	model_mood.position = Vector2(280, 560)
	model_mood.size = Vector2(720, 42)
	model_mood.add_theme_color_override("font_outline_color", Color("#111111"))
	model_mood.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(model_mood)

	sorted_label = make_label("", 22, Color("#5cff86"), HORIZONTAL_ALIGNMENT_LEFT)
	sorted_label.position = Vector2(120, 562)
	sorted_label.size = Vector2(180, 38)
	content_layer.add_child(sorted_label)

	mistakes_label = make_label("", 22, Color("#ff5b5b"), HORIZONTAL_ALIGNMENT_RIGHT)
	mistakes_label.position = Vector2(984, 562)
	mistakes_label.size = Vector2(180, 38)
	content_layer.add_child(mistakes_label)

func _spawn_document() -> void:
	var next := randi_range(0, DOCUMENTS.size() - 1)
	if DOCUMENTS.size() > 1:
		while next == current_doc:
			next = randi_range(0, DOCUMENTS.size() - 1)
	current_doc = next

	var doc: Dictionary = DOCUMENTS[current_doc]
	doc_label.text = tr(doc["key"])
	doc_badge.text = tr("DATASET_BADGE")

func _on_choice_pressed(choice: String) -> void:
	if not running or current_doc < 0:
		return

	var doc: Dictionary = DOCUMENTS[current_doc]
	if choice == String(doc["kind"]):
		sorted += 1
		score = sorted
		model_mood.text = tr("DATASET_MODEL_GOOD")
		if sorted >= TARGET_SORTED:
			await finish_with_result(true, "DATASET_SUCCESS", 0.7)
			return
		_spawn_document()
	else:
		mistakes += 1
		model_mood.text = tr("DATASET_MODEL_BAD")

	_update_status()

func _update_status() -> void:
	if sorted_label:
		sorted_label.text = tr("DATASET_SORTED") % [sorted, TARGET_SORTED]
	if mistakes_label:
		mistakes_label.text = tr("DATASET_MISTAKES") % mistakes
	set_status(tr("DATASET_STATUS") % [sorted, TARGET_SORTED, mistakes])

func on_timeout() -> void:
	var success := sorted >= TARGET_SORTED
	await finish_with_result(success, "DATASET_TIMEOUT_SUCCESS" if success else "DATASET_FAIL", 0.45)
