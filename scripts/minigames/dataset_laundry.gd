extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_SORTED := 8
const DOCUMENTS := [
	{"key": "DATASET_DOC_API", "correct": "wash"},
	{"key": "DATASET_DOC_TESTS", "correct": "wash"},
	{"key": "DATASET_DOC_BUG", "correct": "wash"},
	{"key": "DATASET_DOC_LICENSED", "correct": "wash"},
	{"key": "DATASET_DOC_SCREENSHOT", "correct": "hold"},
	{"key": "DATASET_DOC_SECRET", "correct": "hold"},
	{"key": "DATASET_DOC_RANDOM", "correct": "hold"},
	{"key": "DATASET_DOC_FORUM", "correct": "hold"},
	{"key": "DATASET_DOC_PII", "correct": "hold"}
]
const OPTIONS := [
	{"id": "wash", "label_key": "QUICK_WASH", "color": "#66c6ff"},
	{"id": "hold", "label_key": "QUICK_QUARANTINE", "color": "#ff9fd6"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_DATASET_TITLE",
		"DATASET_INSTRUCTIONS",
		"GAME_DATASET_DESC",
		"DATASET_DOC_TITLE",
		"DATASET_WASHER",
		DOCUMENTS,
		OPTIONS,
		TARGET_SORTED,
		"DATASET_SUCCESS",
		"DATASET_FAIL",
		"DATASET_TIMEOUT_SUCCESS",
		"",
		Color("#eef7ff"),
		Color("#2d72af")
	)
	super._ready()
