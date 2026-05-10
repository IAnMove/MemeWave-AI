extends "res://scripts/minigames/base_minigame.gd"

const TARGET_DECISIONS := 9
const SUGGESTIONS := [
	{"key": "COPILOT_GOOD_NULL", "kind": "accept"},
	{"key": "COPILOT_GOOD_TEST", "kind": "accept"},
	{"key": "COPILOT_GOOD_RETURN", "kind": "accept"},
	{"key": "COPILOT_GOOD_CACHE", "kind": "accept"},
	{"key": "COPILOT_BAD_DELETE", "kind": "reject"},
	{"key": "COPILOT_BAD_ANY", "kind": "reject"},
	{"key": "COPILOT_BAD_SLEEP", "kind": "reject"},
	{"key": "COPILOT_BAD_SECRET", "kind": "reject"},
	{"key": "COPILOT_BAD_CATCH", "kind": "reject"}
]

var current_suggestion := -1
var decisions := 0
var mistakes := 0
var suggestion_label: Label
var verdict_label: Label
var accept_button: Button
var reject_button: Button
var decision_bar: ProgressBar
var editor_mood: Label

func _ready() -> void:
	configure(
		"GAME_COPILOT_TITLE",
		"COPILOT_INSTRUCTIONS",
		"GAME_COPILOT_DESC",
		""
	)
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_suggestion = -1
	decisions = 0
	mistakes = 0
	score = 0
	decision_bar.value = 0
	verdict_label.text = tr("COPILOT_VERDICT_IDLE")
	editor_mood.text = tr("COPILOT_EDITOR_IDLE")
	accept_button.disabled = false
	reject_button.disabled = false
	_spawn_suggestion()
	_update_status()

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#121826")
	add_child(bg)
	move_child(bg, 0)

	_build_editor_panel()
	_build_action_buttons()
	_build_side_panel()

func _build_editor_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(292, 226)
	panel.size = Vector2(696, 386)
	panel.add_theme_stylebox_override("panel", make_style(Color("#1b2533"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var file_label := make_label("src/vibe_feature.ts", 24, Color("#9ee2ff"), HORIZONTAL_ALIGNMENT_LEFT)
	file_label.position = Vector2(326, 246)
	file_label.size = Vector2(310, 34)
	content_layer.add_child(file_label)

	var suggestion_title := make_label(tr("COPILOT_SUGGESTION_TITLE"), 28, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_RIGHT)
	suggestion_title.position = Vector2(650, 246)
	suggestion_title.size = Vector2(300, 34)
	content_layer.add_child(suggestion_title)

	var code_card := PanelContainer.new()
	code_card.position = Vector2(342, 318)
	code_card.size = Vector2(596, 152)
	code_card.add_theme_stylebox_override("panel", make_style(Color("#0e141b"), Color("#56d364"), 3, 6))
	content_layer.add_child(code_card)

	suggestion_label = make_label("", 28, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	suggestion_label.position = Vector2(374, 342)
	suggestion_label.size = Vector2(532, 104)
	suggestion_label.add_theme_color_override("font_outline_color", Color("#000000"))
	suggestion_label.add_theme_constant_override("outline_size", 5)
	content_layer.add_child(suggestion_label)

	decision_bar = ProgressBar.new()
	decision_bar.position = Vector2(426, 506)
	decision_bar.size = Vector2(428, 32)
	decision_bar.min_value = 0
	decision_bar.max_value = TARGET_DECISIONS
	decision_bar.show_percentage = false
	content_layer.add_child(decision_bar)

	verdict_label = make_label("", 27, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	verdict_label.position = Vector2(342, 552)
	verdict_label.size = Vector2(596, 42)
	verdict_label.add_theme_color_override("font_outline_color", Color("#111111"))
	verdict_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(verdict_label)

func _build_action_buttons() -> void:
	accept_button = make_button(tr("COPILOT_ACCEPT"), 31, Color("#bdfb7f"))
	accept_button.position = Vector2(92, 356)
	accept_button.size = Vector2(220, 88)
	accept_button.pressed.connect(_on_choice_pressed.bind("accept"))
	content_layer.add_child(accept_button)

	var accept_hint := make_label(tr("COPILOT_ACCEPT_HINT"), 20, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	accept_hint.position = Vector2(82, 460)
	accept_hint.size = Vector2(240, 60)
	accept_hint.add_theme_color_override("font_outline_color", Color("#111111"))
	accept_hint.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(accept_hint)

	reject_button = make_button(tr("COPILOT_REJECT"), 31, Color("#ff7777"))
	reject_button.position = Vector2(968, 356)
	reject_button.size = Vector2(220, 88)
	reject_button.pressed.connect(_on_choice_pressed.bind("reject"))
	content_layer.add_child(reject_button)

	var reject_hint := make_label(tr("COPILOT_REJECT_HINT"), 20, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	reject_hint.position = Vector2(958, 460)
	reject_hint.size = Vector2(240, 60)
	reject_hint.add_theme_color_override("font_outline_color", Color("#111111"))
	reject_hint.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(reject_hint)

func _build_side_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(84, 544)
	panel.size = Vector2(1112, 70)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(panel)

	editor_mood = make_label("", 26, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	editor_mood.position = Vector2(132, 558)
	editor_mood.size = Vector2(1016, 40)
	content_layer.add_child(editor_mood)

func _spawn_suggestion() -> void:
	var next := randi_range(0, SUGGESTIONS.size() - 1)
	if SUGGESTIONS.size() > 1:
		while next == current_suggestion:
			next = randi_range(0, SUGGESTIONS.size() - 1)
	current_suggestion = next

	var suggestion: Dictionary = SUGGESTIONS[current_suggestion]
	suggestion_label.text = tr(suggestion["key"])

func _on_choice_pressed(choice: String) -> void:
	if not running or current_suggestion < 0:
		return

	var suggestion: Dictionary = SUGGESTIONS[current_suggestion]
	if choice == String(suggestion["kind"]):
		decisions += 1
		score = decisions
		decision_bar.value = decisions
		verdict_label.text = tr("COPILOT_GOOD")
		verdict_label.add_theme_color_override("font_color", Color("#5cff86"))
		editor_mood.text = tr("COPILOT_EDITOR_GOOD")
		if decisions >= TARGET_DECISIONS:
			await finish_with_result(true, "COPILOT_SUCCESS", 0.7)
			return
		_spawn_suggestion()
	else:
		mistakes += 1
		verdict_label.text = tr("COPILOT_BAD")
		verdict_label.add_theme_color_override("font_color", Color("#ff5b5b"))
		editor_mood.text = tr("COPILOT_EDITOR_BAD")

	_update_status()

func _update_status() -> void:
	set_status(tr("COPILOT_STATUS") % [decisions, TARGET_DECISIONS, mistakes])

func on_timeout() -> void:
	var success := decisions >= TARGET_DECISIONS
	await finish_with_result(success, "COPILOT_TIMEOUT_SUCCESS" if success else "COPILOT_FAIL", 0.45)
