extends SceneTree

const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MainScript.new()
	root.add_child(main)
	await process_frame

	var game_defs: Array = main.get("GAME_DEFS")
	var hallu_index := -1
	for index in game_defs.size():
		if String(game_defs[index]["title_key"]) == "GAME_HALLU_TITLE":
			hallu_index = index
			break
	if hallu_index == -1:
		_fail("Hallucination Hunt is missing from GAME_DEFS.")
		return

	var queue: Array = main.call("_make_random_round_queue")
	var count := 0
	for game_index in queue:
		if bool(main.call("_is_game_retired", int(game_index))):
			_fail("Round queue should not include retired minigames.")
			return
		if int(game_index) == hallu_index:
			count += 1
	if count != 3:
		_fail("Hallucination Hunt should appear three times in normal random runs.")
		return

	main.queue_free()
	await process_frame
	print("Round queue logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
