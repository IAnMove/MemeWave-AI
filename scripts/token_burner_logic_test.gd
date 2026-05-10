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
	if String(game.call("_resolve_tutorial_action_kind")) != "drag_right":
		_fail("Token Burner should show click-and-drag-right tutorial art.")
		return
	var background := (game.get("content_layer") as Control).get_node_or_null("TokenWhiteBackground") as ColorRect
	if not background or background.color != Color("#ffffff"):
		_fail("Token Burner playfield background should be white.")
		return
	game.call("_spawn_item")
	await process_frame
	var spawned_items := game.get("items") as Array
	if spawned_items.is_empty():
		_fail("Token Burner should spawn items in the drop lane.")
		return
	var spawned_item := spawned_items[0] as Dictionary
	var spawned_node := spawned_item["node"] as Control
	if spawned_node.position.x < 348.0 or spawned_node.position.x + spawned_node.size.x > 666.0:
		_fail("Token Burner items should spawn to the right of Sam, inside the drop lane.")
		return
	game.call("_remove_item", spawned_item)
	await process_frame

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
	await create_timer(0.1).timeout
	var mouth := game.get("mouth") as PanelContainer
	if not mouth or mouth.size.y > 32.0:
		_fail("Token Burner mouth should visually close after feeding a token.")
		return
	var happy_eye_left := game.get("happy_eye_left") as Line2D
	if not happy_eye_left or not happy_eye_left.visible:
		_fail("Token Burner should show happy eyes after feeding a token.")
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
