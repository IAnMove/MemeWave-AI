extends SceneTree

const PromptGatekeeper := preload("res://scripts/minigames/prompt_gatekeeper.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var minigame: Control = PromptGatekeeper.new()
	root.add_child(minigame)
	await process_frame

	minigame.start_minigame()
	await process_frame

	if not bool(minigame.get("running")):
		_fail("Prompt gatekeeper did not start.")
		return

	var prompt_def: Dictionary = minigame.get("PROMPTS")[int(minigame.get("current_prompt"))]
	var expected := String(prompt_def["kind"])
	minigame.call("_on_choice_pressed", expected)
	minigame.call("_on_choice_pressed", expected)
	await process_frame

	if int(minigame.get("handled")) != 1:
		_fail("Prompt gatekeeper accepted duplicate input during feedback.")
		return

	if not bool(minigame.get("choice_locked")):
		_fail("Prompt gatekeeper did not lock choices during feedback.")
		return

	await create_timer(0.35).timeout
	if bool(minigame.get("running")):
		minigame.finish(false)
	minigame.queue_free()
	await process_frame
	print("Prompt gatekeeper input test passed: duplicate choices are locked.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
