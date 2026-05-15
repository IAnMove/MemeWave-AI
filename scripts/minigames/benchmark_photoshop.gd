extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_BARS := 7
const BARS := [
	{"key": "PHOTOSHOP_REAL_LATENCY", "correct": "crop"},
	{"key": "PHOTOSHOP_REAL_COST", "correct": "crop"},
	{"key": "PHOTOSHOP_REAL_HUMAN", "correct": "crop"},
	{"key": "PHOTOSHOP_REAL_HELDOUT", "correct": "crop"},
	{"key": "PHOTOSHOP_FAKE_PRIVATE", "correct": "stretch"},
	{"key": "PHOTOSHOP_FAKE_LEAKED", "correct": "stretch"},
	{"key": "PHOTOSHOP_FAKE_SLIDE", "correct": "stretch"},
	{"key": "PHOTOSHOP_FAKE_CHERRY", "correct": "stretch"}
]
const OPTIONS := [
	{"id": "stretch", "label_key": "QUICK_STRETCH", "color": "#ff7777"},
	{"id": "crop", "label_key": "QUICK_CROP", "color": "#66c6ff"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_PHOTOSHOP_TITLE",
		"PHOTOSHOP_INSTRUCTIONS",
		"GAME_PHOTOSHOP_DESC",
		"PHOTOSHOP_BOARD_TITLE",
		"PHOTOSHOP_SIDE_TITLE",
		BARS,
		OPTIONS,
		TARGET_BARS,
		"PHOTOSHOP_SUCCESS",
		"PHOTOSHOP_FAIL",
		"PHOTOSHOP_TIMEOUT_SUCCESS",
		"res://assets/art/benchmark_arena_bg.png",
		Color("#fffdf8"),
		Color("#d91e18")
	)
	super._ready()
