extends SceneTree

const HallucinationHunt := preload("res://scripts/minigames/hallucination_hunt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := HallucinationHunt.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	var cards: Array = game.get("cards")
	if cards.size() != 4:
		_fail("Hallucination Hunt should show four fixed options.")
		return
	var current_fact := int(game.get("current_fact"))
	if current_fact < 0 or current_fact >= HallucinationHunt.FACT_ROUNDS.size():
		_fail("Hallucination Hunt should choose one of the generated portrait rounds.")
		return
	var portrait := game.get("portrait_sprite") as TextureRect
	if not portrait or not portrait.texture:
		_fail("Hallucination Hunt should show the selected character portrait.")
		return

	var real_node: Button
	var fake_node: Button
	for card in cards:
		var node := card["node"] as Button
		if bool(card["real"]):
			real_node = node
		else:
			fake_node = node

	if not real_node or not fake_node:
		_fail("Hallucination Hunt needs one real claim and hallucination options.")
		return

	game.call("_on_card_pressed", fake_node)
	await process_frame
	if int(game.get("mistakes")) != 1:
		_fail("Pressing a hallucination should count as a mistake.")
		return
	if not is_instance_valid(fake_node) or not fake_node.visible:
		_fail("Hallucination options should stay visible after a mistake.")
		return

	game.call("_on_card_pressed", real_node)
	await create_timer(1.05).timeout
	if int(game.get("hits")) != 1:
		_fail("Pressing the real claim should advance the score.")
		return
	if bool(game.get("running")):
		_fail("Pressing the real claim should resolve the microgame.")
		return

	game.queue_free()
	await process_frame

	for fact_index in range(HallucinationHunt.FACT_ROUNDS.size()):
		game = HallucinationHunt.new()
		root.add_child(game)
		await process_frame
		game.call("set_fact_round", fact_index)
		game.start_minigame()
		await process_frame
		if int(game.get("current_fact")) != fact_index:
			_fail("Hallucination Hunt did not honor the assigned fact round.")
			return
		game.finish(false)
		game.queue_free()
		await process_frame

	print("Hallucination Hunt logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
