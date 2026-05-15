extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_FRAGMENTS := 5
const LAYERS := [
	{"key": "ARCHAEOLOGY_USEFUL_GOAL", "correct": "dig"},
	{"key": "ARCHAEOLOGY_USEFUL_CONSTRAINT", "correct": "dig"},
	{"key": "ARCHAEOLOGY_USEFUL_ERROR", "correct": "dig"},
	{"key": "ARCHAEOLOGY_USEFUL_ACCEPTANCE", "correct": "dig"},
	{"key": "ARCHAEOLOGY_USEFUL_FILE", "correct": "dig"},
	{"key": "ARCHAEOLOGY_NOISE_PRAISE", "correct": "toss"},
	{"key": "ARCHAEOLOGY_NOISE_LOGS", "correct": "toss"},
	{"key": "ARCHAEOLOGY_NOISE_OLD_CHAT", "correct": "toss"},
	{"key": "ARCHAEOLOGY_NOISE_VIBES", "correct": "toss"},
	{"key": "ARCHAEOLOGY_NOISE_STACKTRACE", "correct": "toss"}
]
const OPTIONS := [
	{"id": "dig", "label_key": "QUICK_DIG", "color": "#ffef5f"},
	{"id": "toss", "label_key": "QUICK_TOSS", "color": "#ff9fd6"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_ARCHAEOLOGY_TITLE",
		"ARCHAEOLOGY_INSTRUCTIONS",
		"GAME_ARCHAEOLOGY_DESC",
		"ARCHAEOLOGY_DIG_TITLE",
		"ARCHAEOLOGY_SIDE_TITLE",
		LAYERS,
		OPTIONS,
		TARGET_FRAGMENTS,
		"ARCHAEOLOGY_SUCCESS",
		"ARCHAEOLOGY_FAIL",
		"ARCHAEOLOGY_TIMEOUT_SUCCESS",
		"",
		Color("#fff7d6"),
		Color("#ad7a28")
	)
	super._ready()
