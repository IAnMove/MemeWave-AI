extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_REVIEWS := 8
const COMMENTS := [
	{"key": "PR_USEFUL_NULL", "correct": "apply"},
	{"key": "PR_USEFUL_TEST", "correct": "apply"},
	{"key": "PR_USEFUL_AUTH", "correct": "apply"},
	{"key": "PR_USEFUL_SQL", "correct": "apply"},
	{"key": "PR_NOISE_COLOR", "correct": "ignore"},
	{"key": "PR_NOISE_TABS", "correct": "ignore"},
	{"key": "PR_NOISE_REWRITE", "correct": "ignore"},
	{"key": "PR_NOISE_NIT", "correct": "ignore"}
]
const OPTIONS := [
	{"id": "apply", "label_key": "QUICK_APPLY", "color": "#bdfb7f"},
	{"id": "ignore", "label_key": "QUICK_IGNORE", "color": "#ff9fd6"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_PR_TITLE",
		"PR_INSTRUCTIONS",
		"GAME_PR_DESC",
		"PR_COMMENT_TITLE",
		"QUICK_PROGRESS",
		COMMENTS,
		OPTIONS,
		TARGET_REVIEWS,
		"PR_SUCCESS",
		"PR_FAIL",
		"PR_TIMEOUT_SUCCESS",
		"",
		Color("#eff7ff"),
		Color("#1f5fbf")
	)
	super._ready()
