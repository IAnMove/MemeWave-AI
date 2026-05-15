extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_TASKS := 8
const TASKS := [
	{"key": "SWARM_TASK_UI_HERO", "correct": "agent"},
	{"key": "SWARM_TASK_UI_BUTTON", "correct": "queue"},
	{"key": "SWARM_TASK_API_AUTH", "correct": "agent"},
	{"key": "SWARM_TASK_API_RETRY", "correct": "queue"},
	{"key": "SWARM_TASK_DB_MIGRATION", "correct": "agent"},
	{"key": "SWARM_TASK_DB_INDEX", "correct": "queue"},
	{"key": "SWARM_TASK_DOCS", "correct": "agent"},
	{"key": "SWARM_TASK_DOCS_TYPO", "correct": "queue"},
	{"key": "SWARM_TASK_TESTS", "correct": "agent"},
	{"key": "SWARM_TASK_INPUT", "correct": "agent"}
]
const OPTIONS := [
	{"id": "agent", "label_key": "QUICK_AGENT", "color": "#bdfb7f"},
	{"id": "queue", "label_key": "QUICK_QUEUE", "color": "#ffe0dc"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_SWARM_TITLE",
		"SWARM_INSTRUCTIONS",
		"GAME_SWARM_DESC",
		"SWARM_ROUTER_TITLE",
		"SWARM_BOARD_TITLE",
		TASKS,
		OPTIONS,
		TARGET_TASKS,
		"SWARM_SUCCESS",
		"SWARM_FAIL_CONFLICT",
		"SWARM_TIMEOUT_SUCCESS",
		"res://assets/art/agent_task_swarm_bg.png",
		Color("#fffdf8"),
		Color("#5a7cff")
	)
	shuffle_items = false
	super._ready()

func _on_agent_pressed(_agent_index: int) -> void:
	_choose_action("agent")

func _on_queue_pressed() -> void:
	_choose_action("queue")
