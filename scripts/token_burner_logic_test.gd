extends SceneTree

const TokenBurner := preload("res://scripts/minigames/token_burner.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = TokenBurner.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	if String(game.call("_resolve_tutorial_action_kind")) != "drag":
		_fail("Cool Ollama should show drag tutorial art.")
		return
	if not game.get("fan") or not game.get("laptop_hot") or not game.get("laptop_cool"):
		_fail("Cool Ollama did not build fan and laptop sprites.")
		return
	if bool(game.call("_fan_over_gpu")):
		_fail("Cool Ollama fan should start away from the GPU.")
		return

	var before := float(game.get("temperature"))
	game.call("_move_fan_to", Vector2(310, 306))
	await create_timer(0.45).timeout
	if not bool(game.get("cooling")):
		_fail("Cool Ollama did not detect fan over GPU.")
		return
	if float(game.get("temperature")) >= before:
		_fail("Cool Ollama did not lower temperature while fan overlaps laptop.")
		return

	game.set("temperature", 4.0)
	await create_timer(0.25).timeout
	if bool(game.get("running")):
		_fail("Cool Ollama did not finish when the GPU cooled.")
		return

	game.queue_free()
	await process_frame
	print("Token Burner logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
