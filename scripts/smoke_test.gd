extends SceneTree

const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame

	var game_defs: Array = main.get("GAME_DEFS")
	for index in range(game_defs.size()):
		var game_def: Dictionary = game_defs[index]
		var minigame_script: GDScript = game_def["script"] as GDScript
		var minigame: Control = minigame_script.new()
		root.add_child(minigame)
		await process_frame

		if not minigame.has_method("start_minigame"):
			_fail("Minigame %d missing start_minigame" % index)
			return

		minigame.start_minigame()
		await process_frame

		if not bool(minigame.get("running")):
			_fail("Minigame %d did not enter running state" % index)
			return

		minigame.finish(false)
		minigame.queue_free()
		await process_frame

	main.queue_free()
	await process_frame

	print("Smoke test passed: all %d catalog minigames instantiate and start." % game_defs.size())
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
