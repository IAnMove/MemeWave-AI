extends "res://scripts/minigames/quick_sort_base.gd"

const PROMPTS := [
	{"key": "PROMPT_GATE_REFACTOR", "correct": "send"},
	{"key": "PROMPT_GATE_FEATURE", "correct": "send"},
	{"key": "PROMPT_GATE_API_KEY", "correct": "discard"},
	{"key": "PROMPT_GATE_DELETE_USERS", "correct": "discard"},
	{"key": "PROMPT_GATE_RM_STAR", "correct": "discard"}
]
const OPTIONS := [
	{"id": "send", "label_key": "QUICK_SEND", "color": "#bdfb7f"},
	{"id": "discard", "label_key": "QUICK_DISCARD", "color": "#ff7777"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_PROMPT_GATE_TITLE",
		"PROMPT_GATE_INSTRUCTIONS",
		"GAME_PROMPT_GATE_DESC",
		"PROMPT_GATE_PANEL_TITLE",
		"QUICK_PROGRESS",
		PROMPTS,
		OPTIONS,
		PROMPTS.size(),
		"PROMPT_GATE_SUCCESS",
		"PROMPT_GATE_FAIL",
		"PROMPT_GATE_TIMEOUT_SUCCESS",
		"",
		Color("#fbfdff"),
		Color("#11883a")
	)
	super._ready()
