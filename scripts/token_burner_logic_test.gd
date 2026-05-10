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

	var happy_sound := game.get("happy_sound") as AudioStreamPlayer
	if not happy_sound or not happy_sound.stream:
		_fail("Token Burner feed sound was not loaded.")
		return

	var token := game.call("make_sprite", "res://assets/sprites/token.png", Vector2(94, 94)) as Control
	token.position = Vector2(860, 390)
	game.get("content_layer").add_child(token)
	var token_item := {"node": token, "kind": "token", "speed": 0.0, "spin": 0.0}
	game.get("items").append(token_item)
	game.call("_try_feed_item", token_item)
	await process_frame
	if int(game.get("fed_tokens")) != 1:
		_fail("Token Burner did not feed a token intersecting the mouth.")
		return
	await create_timer(0.45).timeout

	var rate := game.call("make_sprite", "res://assets/sprites/rate_limit.png", Vector2(94, 94)) as Control
	rate.position = Vector2(860, 390)
	game.get("content_layer").add_child(rate)
	var rate_item := {"node": rate, "kind": "rate", "speed": 0.0, "spin": 0.0}
	game.get("items").append(rate_item)
	game.call("_try_feed_item", rate_item)
	await process_frame
	if int(game.get("misses")) < 2:
		_fail("Token Burner did not penalize feeding a 429.")
		return

	var late_token := game.call("make_sprite", "res://assets/sprites/token.png", Vector2(94, 94)) as Control
	late_token.position = Vector2(920, 520)
	game.call("_apply_cpu_wall", late_token)
	await process_frame
	if late_token.position.x >= 740.0:
		_fail("Token Burner CPU wall did not block a low token.")
		return
	late_token.queue_free()

	game.finish(false)
	game.queue_free()
	await process_frame
	print("Token Burner logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
