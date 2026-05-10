extends SceneTree

const ClaudeRateLimit := preload("res://scripts/minigames/claude_rate_limit.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = ClaudeRateLimit.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	game.call("_on_response_pressed")
	await create_timer(0.4).timeout

	var width := float(game.get("session_fill").size.x)
	var expected := float(game.get("LIMIT_BAR_WIDTH"))
	if absf(width - expected) > 0.1:
		_fail("Claudio session bar did not fill to 100%.")
		return

	var dario_speech := game.get("dario_speech") as Label
	if dario_speech.text != "Pausa! Nos vemos en 5 horas!":
		_fail("Dario final speech did not match the requested text.")
		return

	await create_timer(1.0).timeout
	var overlay := game.get("overlay_label") as Label
	if overlay.visible:
		_fail("Claudio showed the large result overlay.")
		return

	game.queue_free()
	await process_frame
	print("Claudio rate limit logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
