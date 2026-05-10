extends "res://scripts/minigames/model_choice_base.gd"

func _ready() -> void:
	initialize_choice(
		"GAME_CHOICE_PLAN_TITLE",
		"CHOICE_INSTRUCTIONS",
		"GAME_CHOICE_PLAN_DESC",
		"CHOICE_PLAN_SCENARIO",
		"claude",
		"CHOICE_PLAN_SUCCESS",
		"CHOICE_PLAN_FAIL",
		"CHOICE_PLAN_CLAUDE",
		"CHOICE_PLAN_CODEX"
	)
	super._ready()
	build_choice_stage()
