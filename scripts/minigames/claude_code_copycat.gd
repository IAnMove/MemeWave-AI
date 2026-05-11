extends "res://scripts/minigames/copycat_base.gd"

func _ready() -> void:
	copy_title_key = "GAME_COPY_CODEX_TITLE"
	copy_description_key = "GAME_COPY_CODEX_DESC"
	copy_success_key = "COPY_CODEX_SUCCESS"
	source_name = "CLAUDE CODE"
	target_name = "CODEX"
	source_icon = "computer_good"
	target_icon = "computer_good"
	source_color = Color("#c7a7ff")
	target_color = Color("#74f28a")
	super._ready()
