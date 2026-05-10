extends "res://scripts/minigames/model_choice_base.gd"

func _ready() -> void:
	initialize_choice(
		"GAME_CHOICE_COMPLEX_TITLE",
		"CHOICE_INSTRUCTIONS",
		"GAME_CHOICE_COMPLEX_DESC",
		"CHOICE_COMPLEX_SCENARIO",
		"codex",
		"CHOICE_COMPLEX_SUCCESS",
		"CHOICE_COMPLEX_FAIL",
		"CHOICE_COMPLEX_CLAUDE",
		"CHOICE_COMPLEX_CODEX"
	)
	super._ready()
	build_choice_stage()
