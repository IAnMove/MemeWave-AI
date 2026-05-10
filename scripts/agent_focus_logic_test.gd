extends SceneTree

const AgentFocus := preload("res://scripts/minigames/agent_focus.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TranslationServer.set_locale("en")

	var game: Control = AgentFocus.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	var continue_button := game.get("continue_button") as Button
	if not continue_button:
		_fail("Agent Focus should build a Continue button.")
		return
	if continue_button.visible or not continue_button.disabled:
		_fail("Continue button should stay hidden until the last 5 seconds.")
		return

	game.set("time_left", 4.8)
	game.call("_process", 0.0)
	await process_frame
	if not bool(game.get("prompt_shown")):
		_fail("Agent Focus should ask for confirmation when 5 seconds remain.")
		return
	if not continue_button.visible or continue_button.disabled:
		_fail("Continue button should become clickable during the final prompt.")
		return
	if float(game.get("task_progress")) < 90.0:
		_fail("Agent Focus should pause near completion while waiting for Continue.")
		return

	var success_result: Array = []
	game.finished.connect(func(success: bool, score: int) -> void:
		success_result.append(success)
		success_result.append(score)
	)
	continue_button.pressed.emit()
	await create_timer(0.55).timeout
	if success_result.is_empty() or success_result[0] != true or success_result[1] != 1:
		_fail("Clicking Continue should finish Agent Focus successfully.")
		return

	game.queue_free()
	await process_frame

	var timeout_game: Control = AgentFocus.new()
	root.add_child(timeout_game)
	await process_frame
	var timeout_result: Array = []
	timeout_game.finished.connect(func(success: bool, score: int) -> void:
		timeout_result.append(success)
		timeout_result.append(score)
	)
	timeout_game.start_minigame()
	await process_frame
	timeout_game.set("time_left", 0.01)
	timeout_game.call("_process", 0.02)
	await create_timer(0.55).timeout
	if timeout_result.is_empty() or timeout_result[0] != false:
		_fail("Agent Focus should fail if Continue is not clicked before timeout.")
		return

	timeout_game.queue_free()
	await process_frame
	print("Agent Focus logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
