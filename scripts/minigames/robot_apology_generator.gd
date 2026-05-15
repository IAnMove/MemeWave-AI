extends "res://scripts/minigames/quick_sort_base.gd"

const PARTS := [
	{"key": "APOLOGY_PART_SAFETY", "correct": "safety"},
	{"key": "APOLOGY_PART_ITERATION", "correct": "iteration"},
	{"key": "APOLOGY_PART_ALIGNMENT", "correct": "alignment"},
	{"key": "APOLOGY_PART_LEARNING", "correct": "learning"}
]
const DECOYS := [
	{"kind": "blame", "label": "APOLOGY_PART_BLAME"},
	{"kind": "vibes", "label": "APOLOGY_PART_VIBES"},
	{"kind": "silence", "label": "APOLOGY_PART_SILENCE"},
	{"kind": "legal", "label": "APOLOGY_PART_LEGAL"}
]
const OPTIONS := [
	{"id": "safety", "label_key": "APOLOGY_PART_SAFETY", "color": "#bdfb7f"},
	{"id": "iteration", "label_key": "APOLOGY_PART_ITERATION", "color": "#ffef5f"},
	{"id": "alignment", "label_key": "APOLOGY_PART_ALIGNMENT", "color": "#66c6ff"},
	{"id": "learning", "label_key": "APOLOGY_PART_LEARNING", "color": "#ff9fd6"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_APOLOGY_TITLE",
		"APOLOGY_INSTRUCTIONS",
		"GAME_APOLOGY_DESC",
		"APOLOGY_BOARD_TITLE",
		"APOLOGY_SIDE_TITLE",
		PARTS,
		OPTIONS,
		PARTS.size(),
		"APOLOGY_SUCCESS",
		"APOLOGY_FAIL",
		"APOLOGY_TIMEOUT_SUCCESS",
		"",
		Color("#fffdf8"),
		Color("#2d72af")
	)
	shuffle_items = false
	super._ready()

func _on_card_pressed(kind: String) -> void:
	_choose_action(kind)
