extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_ROUTES := 7
const MODEL_DEFS := [
	{"id": "code", "label_key": "ROUTER_MODEL_CODE", "color": "#66c6ff"},
	{"id": "image", "label_key": "ROUTER_MODEL_IMAGE", "color": "#ff9fd6"},
	{"id": "summary", "label_key": "ROUTER_MODEL_SUMMARY", "color": "#bdfb7f"},
	{"id": "gossip", "label_key": "ROUTER_MODEL_GOSSIP", "color": "#ffef5f"}
]
const TASKS := [
	{"key": "ROUTER_TASK_CODE_1", "correct": "code"},
	{"key": "ROUTER_TASK_CODE_2", "correct": "code"},
	{"key": "ROUTER_TASK_IMAGE_1", "correct": "image"},
	{"key": "ROUTER_TASK_IMAGE_2", "correct": "image"},
	{"key": "ROUTER_TASK_SUMMARY_1", "correct": "summary"},
	{"key": "ROUTER_TASK_SUMMARY_2", "correct": "summary"},
	{"key": "ROUTER_TASK_GOSSIP_1", "correct": "gossip"},
	{"key": "ROUTER_TASK_GOSSIP_2", "correct": "gossip"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_ROUTER_TITLE",
		"ROUTER_INSTRUCTIONS",
		"GAME_ROUTER_DESC",
		"ROUTER_INCOMING",
		"QUICK_PROGRESS",
		TASKS,
		MODEL_DEFS,
		TARGET_ROUTES,
		"ROUTER_SUCCESS",
		"ROUTER_FAIL",
		"ROUTER_TIMEOUT_SUCCESS",
		"",
		Color("#eef7ff"),
		Color("#2d72af")
	)
	super._ready()
