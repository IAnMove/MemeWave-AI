extends "res://scripts/minigames/base_minigame.gd"

const TARGET_GOOD := 7
const INGREDIENTS := [
	{"key": "KITCHEN_GOOD_DOCS", "kind": "good"},
	{"key": "KITCHEN_GOOD_TESTS", "kind": "good"},
	{"key": "KITCHEN_GOOD_EXAMPLES", "kind": "good"},
	{"key": "KITCHEN_GOOD_FEEDBACK", "kind": "good"},
	{"key": "KITCHEN_BAD_SPAM", "kind": "trash"},
	{"key": "KITCHEN_BAD_SECRETS", "kind": "trash"},
	{"key": "KITCHEN_BAD_RUMORS", "kind": "trash"},
	{"key": "KITCHEN_BAD_PDF", "kind": "trash"}
]

var current_ingredient := -1
var good_added := 0
var mistakes := 0
var ingredient_label: Label
var pot_label: Label
var add_button: Button
var trash_button: Button
var pot: PanelContainer
var quality_bar: ProgressBar
var wobble := 0.0

func _ready() -> void:
	configure("GAME_KITCHEN_TITLE", "KITCHEN_INSTRUCTIONS", "GAME_KITCHEN_DESC", "")
	super._ready()
	_build_stage()

func start_minigame() -> void:
	super.start_minigame()
	current_ingredient = -1
	good_added = 0
	mistakes = 0
	score = 0
	wobble = 0.0
	quality_bar.value = 0
	pot_label.text = tr("KITCHEN_POT_IDLE")
	add_button.disabled = false
	trash_button.disabled = false
	_spawn_ingredient()
	_update_status()

func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return
	wobble += delta * (5.0 + mistakes)
	pot.rotation = sin(wobble) * 0.035

func _build_stage() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 720)
	bg.color = Color("#211827")
	add_child(bg)
	move_child(bg, 0)

	var panel := PanelContainer.new()
	panel.position = Vector2(348, 230)
	panel.size = Vector2(584, 370)
	panel.add_theme_stylebox_override("panel", make_style(Color("#fff7d6"), Color("#1d1d1d"), 5, 8))
	content_layer.add_child(panel)

	var title := make_label(tr("KITCHEN_TABLE"), 34, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(390, 250)
	title.size = Vector2(500, 46)
	content_layer.add_child(title)

	var ingredient_card := PanelContainer.new()
	ingredient_card.position = Vector2(430, 322)
	ingredient_card.size = Vector2(420, 110)
	ingredient_card.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 8))
	content_layer.add_child(ingredient_card)

	ingredient_label = make_label("", 32, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	ingredient_label.position = Vector2(454, 340)
	ingredient_label.size = Vector2(372, 72)
	ingredient_label.add_theme_color_override("font_outline_color", Color("#ffffff"))
	ingredient_label.add_theme_constant_override("outline_size", 2)
	content_layer.add_child(ingredient_label)

	pot = PanelContainer.new()
	pot.position = Vector2(548, 472)
	pot.size = Vector2(184, 78)
	pot.pivot_offset = Vector2(92, 39)
	pot.add_theme_stylebox_override("panel", make_style(Color("#66c6ff"), Color("#1d1d1d"), 5, 12))
	content_layer.add_child(pot)

	var pot_title := make_label(tr("KITCHEN_POT"), 24, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	pot.add_child(pot_title)

	add_button = make_button(tr("KITCHEN_ADD"), 30, Color("#bdfb7f"))
	add_button.position = Vector2(104, 354)
	add_button.size = Vector2(220, 90)
	add_button.pressed.connect(_on_choice_pressed.bind("good"))
	content_layer.add_child(add_button)

	trash_button = make_button(tr("KITCHEN_TRASH"), 30, Color("#ff7777"))
	trash_button.position = Vector2(956, 354)
	trash_button.size = Vector2(220, 90)
	trash_button.pressed.connect(_on_choice_pressed.bind("trash"))
	content_layer.add_child(trash_button)

	var side := PanelContainer.new()
	side.position = Vector2(90, 536)
	side.size = Vector2(1100, 68)
	side.add_theme_stylebox_override("panel", make_style(Color("#111820"), Color("#2f3b47"), 3, 8))
	content_layer.add_child(side)

	quality_bar = ProgressBar.new()
	quality_bar.position = Vector2(180, 554)
	quality_bar.size = Vector2(280, 30)
	quality_bar.min_value = 0
	quality_bar.max_value = TARGET_GOOD
	quality_bar.show_percentage = false
	content_layer.add_child(quality_bar)

	pot_label = make_label("", 26, Color("#fff1c6"), HORIZONTAL_ALIGNMENT_CENTER)
	pot_label.position = Vector2(500, 548)
	pot_label.size = Vector2(560, 42)
	pot_label.add_theme_color_override("font_outline_color", Color("#111111"))
	pot_label.add_theme_constant_override("outline_size", 4)
	content_layer.add_child(pot_label)

func _spawn_ingredient() -> void:
	var next := randi_range(0, INGREDIENTS.size() - 1)
	if INGREDIENTS.size() > 1:
		while next == current_ingredient:
			next = randi_range(0, INGREDIENTS.size() - 1)
	current_ingredient = next
	var ingredient: Dictionary = INGREDIENTS[current_ingredient]
	ingredient_label.text = tr(ingredient["key"])

func _on_choice_pressed(choice: String) -> void:
	if not running or current_ingredient < 0:
		return
	var ingredient: Dictionary = INGREDIENTS[current_ingredient]
	if choice == String(ingredient["kind"]):
		if choice == "good":
			good_added += 1
			score = good_added
			quality_bar.value = good_added
			pot_label.text = tr("KITCHEN_GOOD")
			if good_added >= TARGET_GOOD:
				await finish_with_result(true, "KITCHEN_SUCCESS", 0.7)
				return
		else:
			pot_label.text = tr("KITCHEN_TRASHED")
		_spawn_ingredient()
	else:
		mistakes += 1
		pot_label.text = tr("KITCHEN_BAD")
	_update_status()

func _update_status() -> void:
	set_status(tr("KITCHEN_STATUS") % [good_added, TARGET_GOOD, mistakes])

func on_timeout() -> void:
	var success := good_added >= TARGET_GOOD
	await finish_with_result(success, "KITCHEN_TIMEOUT_SUCCESS" if success else "KITCHEN_FAIL", 0.45)
