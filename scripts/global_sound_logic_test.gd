extends SceneTree

const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame

	var ui_click_player := main.get("ui_click_player") as AudioStreamPlayer
	if not ui_click_player or not ui_click_player.stream:
		_fail("Global UI click sound was not loaded.")
		return

	var round_transition_player := main.get("round_transition_player") as AudioStreamPlayer
	if not round_transition_player or not round_transition_player.stream:
		_fail("Round transition sound was not loaded.")
		return

	var menu_music_player := main.get("menu_music_player") as AudioStreamPlayer
	if not menu_music_player or not menu_music_player.stream:
		_fail("Menu music was not loaded.")
		return
	if not menu_music_player.playing:
		_fail("Menu music did not start on the main menu.")
		return

	var game_music_player := main.get("game_music_player") as AudioStreamPlayer
	if not game_music_player or not game_music_player.stream:
		_fail("Game music was not loaded.")
		return

	main.call("_play_ui_click")
	main.call("_play_round_transition")
	main.call("_set_music_mode", "game")
	await process_frame
	if not game_music_player.playing:
		_fail("Game music did not start in game mode.")
		return

	main.call("_set_sound_volume", 0.45, false)
	if abs(float(main.get("sound_volume")) - 0.45) > 0.001:
		_fail("Sound volume did not update.")
		return

	ui_click_player.stop()
	ui_click_player.stream = null
	round_transition_player.stop()
	round_transition_player.stream = null
	menu_music_player.stop()
	menu_music_player.stream = null
	game_music_player.stop()
	game_music_player.stream = null
	main.queue_free()
	await process_frame
	await process_frame
	print("Global sound logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
