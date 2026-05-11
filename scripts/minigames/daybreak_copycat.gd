extends "res://scripts/minigames/copycat_base.gd"

func _ready() -> void:
	copy_title_key = "GAME_COPY_DAYBREAK_TITLE"
	copy_description_key = "GAME_COPY_DAYBREAK_DESC"
	copy_success_key = "COPY_DAYBREAK_SUCCESS"
	source_name = "MYTHOS"
	target_name = "DAYBREAK"
	source_icon = "warning"
	target_icon = "spark"
	source_color = Color("#b9a4ff")
	target_color = Color("#76ddff")
	super._ready()
