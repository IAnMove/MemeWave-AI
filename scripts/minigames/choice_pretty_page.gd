extends "res://scripts/minigames/model_choice_base.gd"

func _ready() -> void:
	initialize_choice(
		"GAME_CHOICE_PAGE_TITLE",
		"CHOICE_INSTRUCTIONS",
		"GAME_CHOICE_PAGE_DESC",
		"CHOICE_PAGE_SCENARIO",
		"claude",
		"CHOICE_PAGE_SUCCESS",
		"CHOICE_PAGE_FAIL",
		"CHOICE_PAGE_CLAUDE",
		"CHOICE_PAGE_CODEX"
	)
	super._ready()
	build_choice_stage()
