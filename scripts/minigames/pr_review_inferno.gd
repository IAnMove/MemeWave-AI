extends "res://scripts/minigames/base_minigame.gd"

const TARGET_REVIEWS := 8
const COMMENTS := [
	{"key": "PR_USEFUL_NULL", "kind": "apply"},
	{"key": "PR_USEFUL_TEST", "kind": "apply"},
	{"key": "PR_USEFUL_AUTH", "kind": "apply"},
	{"key": "PR_USEFUL_SQL", "kind": "apply"},
	{"key": "PR_NOISE_COLOR", "kind": "ignore"},
	{"key": "PR_NOISE_TABS", "kind": "ignore"},
	{"key": "PR_NOISE_REWRITE", "kind": "ignore"},
	{"key": "PR_NOISE_NIT", "kind": "ignore"}
]

var current_comment := -1
var reviewed := 0
var mistakes := 0
var comment_label: Label
var status_card: Label
var apply_button: Button
var ignore_button: Button
var review_bar: ProgressBar

func _ready() -> void:
	configure("GAME_PR_TITLE", "PR_INSTRUCTIONS", "GAME_PR_DESC", "")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_comment = -1
	reviewed = 0
	mistakes = 0
	score = 0
	review_bar.value = 0
	status_card.text = tr("PR_STATUS_IDLE")
	_spawn_comment()
	_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#1a202c")
	add_child(bg)
	move_child(bg, 0)

	var panel := PanelContainer.new()
	panel.position = Vector2(286, 226)
	panel.size = Vector2(708, 384)
	panel.add_theme_stylebox_override("panel", make_style(Color("#eff7ff"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("PR_COMMENT_TITLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(330, 250)
	title.size = Vector2(620, 46)
	content_layer.add_child(title)

	var bubble := PanelContainer.new()
	bubble.position = Vector2(360, 332)
	bubble.size = Vector2(560, 126)
	bubble.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(bubble)

	comment_label = make_label("", 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	comment_label.position = Vector2(388, 350)
	comment_label.size = Vector2(504, 88)
	comment_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	comment_label.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(comment_label)

	apply_button = make_button(tr("PR_APPLY"), 28, Color("#bdfb7f"))
	apply_button.position = Vector2(120, 370)
	apply_button.size = Vector2(210, 78)
	apply_button.pressed.connect(_on_choice_pressed.bind("apply"))
	content_layer.add_child(apply_button)

	ignore_button = make_button(tr("PR_IGNORE"), 28, Color("#ff9fd6"))
	ignore_button.position = Vector2(950, 370)
	ignore_button.size = Vector2(210, 78)
	ignore_button.pressed.connect(_on_choice_pressed.bind("ignore"))
	content_layer.add_child(ignore_button)

	review_bar = ProgressBar.new()
	review_bar.position = Vector2(440, 494)
	review_bar.size = Vector2(400, 32)
	review_bar.min_value = 0
	review_bar.max_value = TARGET_REVIEWS
	review_bar.show_percentage = false
	content_layer.add_child(review_bar)

	status_card = make_label("", 27, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	status_card.position = Vector2(332, 540)
	status_card.size = Vector2(616, 42)
	status_card.add_theme_color_override("font_outline_color", Color("#111111"))
	status_card.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(status_card)

func _spawn_comment() -> void:
	var next := randi_range(0, COMMENTS.size() - 1)
	if COMMENTS.size() > 1:
		while next == current_comment:
			next = randi_range(0, COMMENTS.size() - 1)
	current_comment = next
	var comment: Dictionary = COMMENTS[current_comment]
	comment_label.text = tr(comment["key"])

func _on_choice_pressed(choice: String) -> void:
	if not running or current_comment < 0:
		return
	var comment: Dictionary = COMMENTS[current_comment]
	if choice == String(comment["kind"]):
		reviewed += 1
		score = reviewed
		review_bar.value = reviewed
		status_card.text = tr("PR_GOOD")
		if reviewed >= TARGET_REVIEWS:
			await finish_with_result(true, "PR_SUCCESS", 0.7)
			return
		_spawn_comment()
	else:
		mistakes += 1
		status_card.text = tr("PR_BAD")
	_update_status()

func _update_status() -> void:
	set_status(tr("PR_STATUS") % [reviewed, TARGET_REVIEWS, mistakes])

func on_timeout() -> void:
	var success := reviewed >= TARGET_REVIEWS
	await finish_with_result(success, "PR_TIMEOUT_SUCCESS" if success else "PR_FAIL", 0.45)
