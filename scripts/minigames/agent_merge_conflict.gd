extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_RESOLVED := 6
const CONFLICTS := [
	{"key": "MERGE_TASK_TESTS", "left_key": "MERGE_LEFT_KEEP_TEST", "right_key": "MERGE_RIGHT_DELETE_TEST", "correct": "left"},
	{"key": "MERGE_TASK_AUTH", "left_key": "MERGE_LEFT_SKIP_AUTH", "right_key": "MERGE_RIGHT_CHECK_AUTH", "correct": "right"},
	{"key": "MERGE_TASK_CSS", "left_key": "MERGE_LEFT_CENTER_DIV", "right_key": "MERGE_RIGHT_REWRITE_UI", "correct": "left"},
	{"key": "MERGE_TASK_RATE", "left_key": "MERGE_LEFT_BACKOFF", "right_key": "MERGE_RIGHT_SLEEP", "correct": "left"},
	{"key": "MERGE_TASK_CONFIG", "left_key": "MERGE_LEFT_ENV", "right_key": "MERGE_RIGHT_HARDCODE", "correct": "left"},
	{"key": "MERGE_TASK_LOGS", "left_key": "MERGE_LEFT_PRINT", "right_key": "MERGE_RIGHT_STRUCTURED", "correct": "right"},
	{"key": "MERGE_TASK_PROMPT", "left_key": "MERGE_LEFT_SYSTEM", "right_key": "MERGE_RIGHT_USER", "correct": "right"}
]
const OPTIONS := [
	{"id": "left", "label_field": "left_key", "color": "#bdfb7f"},
	{"id": "right", "label_field": "right_key", "color": "#66c6ff"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_MERGE_TITLE",
		"MERGE_INSTRUCTIONS",
		"GAME_MERGE_DESC",
		"MERGE_REVIEW_TITLE",
		"QUICK_PROGRESS",
		CONFLICTS,
		OPTIONS,
		TARGET_RESOLVED,
		"MERGE_SUCCESS",
		"MERGE_FAIL",
		"MERGE_TIMEOUT_SUCCESS",
		"",
		Color("#fffdf8"),
		Color("#7c5cff")
	)
	super._ready()
