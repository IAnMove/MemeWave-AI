extends SceneTree

const BaseMinigame := preload("res://scripts/minigames/base_minigame.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := BaseMinigame.new()
	root.add_child(game)
	await process_frame

	var player := game.get("action_sound_player") as AudioStreamPlayer
	var collect_stream := game.get("action_collect_stream") as AudioStream
	var bad_stream := game.get("action_bad_stream") as AudioStream
	var move_stream := game.get("action_move_stream") as AudioStream
	if not player:
		_fail("Missing action sound player")
		return
	if not collect_stream:
		_fail("Missing collect action sound stream")
		return
	if not bad_stream:
		_fail("Missing bad action sound stream")
		return
	if not move_stream:
		_fail("Missing move action sound stream")
		return

	game.call("play_action_sound", "collect")
	if player.stream != collect_stream:
		_fail("Collect action sound did not select collect stream")
		return
	game.call("play_action_sound", "bad")
	if player.stream != bad_stream:
		_fail("Bad action sound did not select bad stream")
		return
	game.call("play_action_sound", "move")
	if player.stream != move_stream:
		_fail("Move action sound did not select move stream")
		return

	player.stop()
	player.stream = null
	game.queue_free()
	await process_frame
	player = null
	collect_stream = null
	bad_stream = null
	move_stream = null
	game = null
	print("Action sound logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
