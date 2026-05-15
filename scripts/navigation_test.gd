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

	if int(main.get("GAME_DEFS").size()) != 46:
		_fail("Expected 46 minigames in navigation flow")
		return
	if int((main.call("_active_game_indexes") as Array).size()) != 22:
		_fail("Expected 22 active minigames in navigation flow")
		return

	main.start_direct_game(0, true)
	await process_frame
	if String(main.get("current_screen")) != "game":
		_fail("Direct launch did not enter game screen")
		return

	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	main.call("_unhandled_input", escape)
	await process_frame
	if String(main.get("current_screen")) != "developer_grid":
		_fail("Escape should return developer-launched games to the developer grid")
		return

	main.queue_free()
	await process_frame

	print("Navigation test passed: menu, collection, developer grid, and direct launch build.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
