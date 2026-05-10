extends SceneTree

const BaseMinigame := preload("res://scripts/minigames/base_minigame.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = BaseMinigame.new()
	root.add_child(game)
	await process_frame

	var player := game.get("result_sound_player") as AudioStreamPlayer
	var success_stream := game.get("result_success_stream") as AudioStream
	var fail_stream := game.get("result_fail_stream") as AudioStream
	if not player or not success_stream or not fail_stream:
		_fail("Result sound streams were not built.")
		return

	game.start_minigame()
	game.finish(true)
	if player.stream != success_stream:
		_fail("Success did not select the good result sound.")
		return

	game.start_minigame()
	game.finish(false)
	if player.stream != fail_stream:
		_fail("Failure did not select the bad result sound.")
		return

	player.stop()
	player.stream = null
	game.set("result_success_stream", null)
	game.set("result_fail_stream", null)
	game.queue_free()
	await process_frame
	await process_frame
	print("Result sound logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
