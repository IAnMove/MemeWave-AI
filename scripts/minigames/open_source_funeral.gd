extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_REPOS := 8
const REPOS := [
	{"key": "FUNERAL_REPO_DOCS", "correct": "community"},
	{"key": "FUNERAL_REPO_PLUGIN", "correct": "community"},
	{"key": "FUNERAL_REPO_WEIGHTS", "correct": "research"},
	{"key": "FUNERAL_REPO_PAPER", "correct": "research"},
	{"key": "FUNERAL_REPO_CORE", "correct": "vault"},
	{"key": "FUNERAL_REPO_TRAINING", "correct": "vault"},
	{"key": "FUNERAL_REPO_DEMO", "correct": "community"},
	{"key": "FUNERAL_REPO_SAFETY", "correct": "research"},
	{"key": "FUNERAL_REPO_SECRET", "correct": "vault"}
]
const OPTIONS := [
	{"id": "community", "label_key": "FUNERAL_COMMUNITY", "color": "#dff8da"},
	{"id": "research", "label_key": "FUNERAL_RESEARCH", "color": "#fff7c7"},
	{"id": "vault", "label_key": "FUNERAL_VAULT", "color": "#ffe0dc"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_FUNERAL_TITLE",
		"FUNERAL_INSTRUCTIONS",
		"GAME_FUNERAL_DESC",
		"FUNERAL_BELT_TITLE",
		"FUNERAL_SIDE_TITLE",
		REPOS,
		OPTIONS,
		TARGET_REPOS,
		"FUNERAL_SUCCESS",
		"FUNERAL_FAIL",
		"FUNERAL_TIMEOUT_SUCCESS",
		"res://assets/art/repo_private_bg.png",
		Color("#fffdf8"),
		Color("#1f5fbf")
	)
	super._ready()
