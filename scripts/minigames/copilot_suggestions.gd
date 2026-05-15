extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_DECISIONS := 9
const SUGGESTIONS := [
	{"key": "COPILOT_GOOD_NULL", "correct": "accept"},
	{"key": "COPILOT_GOOD_TEST", "correct": "accept"},
	{"key": "COPILOT_GOOD_RETURN", "correct": "accept"},
	{"key": "COPILOT_GOOD_CACHE", "correct": "accept"},
	{"key": "COPILOT_BAD_DELETE", "correct": "reject"},
	{"key": "COPILOT_BAD_ANY", "correct": "reject"},
	{"key": "COPILOT_BAD_SLEEP", "correct": "reject"},
	{"key": "COPILOT_BAD_SECRET", "correct": "reject"},
	{"key": "COPILOT_BAD_CATCH", "correct": "reject"}
]
const OPTIONS := [
	{"id": "accept", "label_key": "QUICK_ACCEPT", "color": "#bdfb7f"},
	{"id": "reject", "label_key": "QUICK_REJECT", "color": "#ff7777"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_COPILOT_TITLE",
		"COPILOT_INSTRUCTIONS",
		"GAME_COPILOT_DESC",
		"COPILOT_SUGGESTION_TITLE",
		"QUICK_PROGRESS",
		SUGGESTIONS,
		OPTIONS,
		TARGET_DECISIONS,
		"COPILOT_SUCCESS",
		"COPILOT_FAIL",
		"COPILOT_TIMEOUT_SUCCESS",
		"",
		Color("#eef7ff"),
		Color("#56d364")
	)
	super._ready()
