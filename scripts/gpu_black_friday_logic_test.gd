extends SceneTree

const GpuBlackFriday := preload("res://scripts/minigames/gpu_black_friday.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_collects_gpu_and_ram()
	await _test_missing_stock_fails()
	print("GPU Black Friday logic test passed.")
	quit()

func _test_collects_gpu_and_ram() -> void:
	var game := GpuBlackFriday.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	game.call("_spawn_item", "gpu")
	await process_frame
	var spawned: Array = game.get("items")
	if spawned.is_empty():
		_fail("GPU Black Friday did not spawn a falling item")
		return
	var item: Dictionary = spawned[0]
	var node := item["node"] as Control
	if not node or node.get_child_count() < 2:
		_fail("GPU Black Friday item did not render as a sprite with shadow")
		return

	game.call("_catch_item", item)
	await process_frame
	if int(game.get("gpus")) != 1 or int(game.get("score")) != 1:
		_fail("GPU Black Friday did not count a caught GPU")
		return

	for index in range(11):
		game.call("_register_catch", "ram" if index % 2 == 0 else "gpu")
	await create_timer(0.85).timeout
	if bool(game.get("running")):
		_fail("GPU Black Friday did not finish after filling the cart")
		return
	if int(game.get("score")) < 12:
		_fail("GPU Black Friday did not keep the final cart score")
		return
	game.queue_free()
	await process_frame

func _test_missing_stock_fails() -> void:
	var game := GpuBlackFriday.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	for index in range(3):
		var fake := Control.new()
		root.add_child(fake)
		game.call("_miss_item", {"node": fake, "kind": "gpu"})
	await create_timer(0.72).timeout
	if bool(game.get("running")):
		_fail("GPU Black Friday did not fail after too much stock was missed")
		return
	game.queue_free()
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
