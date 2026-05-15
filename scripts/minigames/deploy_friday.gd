extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_CHANGES := 7
const CHANGES := [
	{"key": "DEPLOY_FIX_TYPO", "correct": "deploy"},
	{"key": "DEPLOY_ADD_TEST", "correct": "deploy"},
	{"key": "DEPLOY_ROLLBACK_BUTTON", "correct": "deploy"},
	{"key": "DEPLOY_PATCH_COPY", "correct": "deploy"},
	{"key": "DEPLOY_NO_TESTS", "correct": "block"},
	{"key": "DEPLOY_FRIDAY_PROD", "correct": "block"},
	{"key": "DEPLOY_SECRET_LOGS", "correct": "block"},
	{"key": "DEPLOY_REMOVE_AUTH", "correct": "block"}
]
const OPTIONS := [
	{"id": "deploy", "label_key": "QUICK_DEPLOY", "color": "#bdfb7f"},
	{"id": "block", "label_key": "QUICK_BLOCK", "color": "#ff7777"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_DEPLOY_TITLE",
		"DEPLOY_INSTRUCTIONS",
		"GAME_DEPLOY_DESC",
		"DEPLOY_CHAT_TITLE",
		"DEPLOY_SERVER_TITLE",
		CHANGES,
		OPTIONS,
		TARGET_CHANGES,
		"DEPLOY_SUCCESS",
		"DEPLOY_FAIL_FIRE",
		"DEPLOY_TIMEOUT_SUCCESS",
		"res://assets/art/deploy_friday_bg.png",
		Color("#fffdf8"),
		Color("#ff8a3d")
	)
	super._ready()
