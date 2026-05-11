extends SceneTree

const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame

	main.show_collection(false)
	await process_frame

	main.show_developer_menu()
	await process_frame

	main.show_collection(true)
	await process_frame

	if int(main.get("GAME_DEFS").size()) != 44:
		_fail("Expected 44 minigames in navigation flow")
		return

	main.start_direct_game(0, true)
	await create_timer(2.1).timeout
	main.queue_free()
	await process_frame

	print("Navigation test passed: menu, collection, developer grid, and direct launch build.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
