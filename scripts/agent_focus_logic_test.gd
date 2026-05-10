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
	if _count_progress_bars(game) > 0:
		_fail("Agent Focus should not show a progress bar in the chat UI.")
		return
	var initial_messages := _visible_message_count(game)
	var total_messages := int((game.get("message_labels") as Array).size())
	if initial_messages >= total_messages:
		_fail("Agent Focus should not show every message at the start.")
		return

	game.set("time_left", 12.0)
	game.call("_process", 0.0)
	await process_frame
	var mid_messages := _visible_message_count(game)
	if mid_messages <= initial_messages or mid_messages >= total_messages:
		_fail("Agent Focus should reveal chat messages progressively.")
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
	if continue_button.text != "Yes, continue":
		_fail("Continue button should use the player reply copy.")
		return
	var message_labels: Array = game.get("message_labels")
	var final_message := message_labels[message_labels.size() - 1] as Label
	if not final_message.visible or final_message.text.find("Continue with the next task?") == -1:
		_fail("Agent Focus should ask the final question inside the chat messages.")
		return
	if String(game.get("status_label").text) != "":
		_fail("Agent Focus should not duplicate the prompt in the bottom status line.")
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

func _visible_message_count(game: Control) -> int:
	var labels: Array = game.get("message_labels")
	var count := 0
	for label_variant in labels:
		var label := label_variant as Label
		if label and label.visible:
			count += 1
	return count

func _count_progress_bars(node: Node) -> int:
	var count := 0
	if node is ProgressBar:
		count += 1
	for child in node.get_children():
		count += _count_progress_bars(child)
	return count
