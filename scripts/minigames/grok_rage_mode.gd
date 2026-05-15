extends "res://scripts/minigames/quick_sort_base.gd"

const TARGET_DRAMA := 6
const PROMPTS := [
	{"key": "GROK_RAGE_POLITE_EMAIL", "correct": "mute"},
	{"key": "GROK_RAGE_SUMMARY", "correct": "mute"},
	{"key": "GROK_RAGE_UNIT_TEST", "correct": "mute"},
	{"key": "GROK_RAGE_THANKS", "correct": "mute"},
	{"key": "GROK_RAGE_CEO_FIGHT", "correct": "feed"},
	{"key": "GROK_RAGE_BENCH_WAR", "correct": "feed"},
	{"key": "GROK_RAGE_MODEL_DRAMA", "correct": "feed"},
	{"key": "GROK_RAGE_OPEN_SOURCE_TAKE", "correct": "feed"}
]
const OPTIONS := [
	{"id": "feed", "label_key": "QUICK_FEED", "color": "#ff7777"},
	{"id": "mute", "label_key": "QUICK_MUTE", "color": "#66c6ff"}
]

func _ready() -> void:
	setup_quick_sort(
		"GAME_GROK_RAGE_TITLE",
		"GROK_RAGE_INSTRUCTIONS",
		"GAME_GROK_RAGE_DESC",
		"GROK_RAGE_FEED_TITLE",
		"GROK_RAGE_DRAMA_TITLE",
		PROMPTS,
		OPTIONS,
		TARGET_DRAMA,
		"GROK_RAGE_SUCCESS",
		"GROK_RAGE_FAIL",
		"GROK_RAGE_TIMEOUT_SUCCESS",
		"res://assets/art/sycophancy_whack_bg.png",
		Color("#fff3f8"),
		Color("#d91e18")
	)
	super._ready()
