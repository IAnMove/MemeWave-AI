extends SceneTree

const EnergyLinks := preload("res://scripts/minigames/energy_links.gd")
const GpuSacrificeRitual := preload("res://scripts/minigames/gpu_sacrifice_ritual.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_energy_links()
	await _test_gpu_ritual()
	print("Pair matching logic test passed.")
	quit()

func _test_energy_links() -> void:
	var game := EnergyLinks.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	_assert_columns_shuffled(game, "Model Power Grid")
	game.call("_select_socket", _find_pair(game, true)[0])
	await process_frame
	if not game.get("dangling_cable"):
		_fail("Model Power Grid should show a dangling cable after selecting a socket.")
		return

	var wrong_pair := _find_pair(game, false)
	game.call("_try_connect", wrong_pair[0], wrong_pair[1])
	await process_frame
	if int(game.get("mistakes")) < 1:
		_fail("Model Power Grid should count a bad cable.")
		return
	var cable_layer := game.get("cable_layer") as Node
	if not cable_layer or cable_layer.get_child_count() < 1:
		_fail("Model Power Grid should drop a visible cable after a bad match.")
		return

	game.queue_free()
	await process_frame

	game = EnergyLinks.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	var correct_pair := _find_pair(game, true)
	game.call("_try_connect", correct_pair[0], correct_pair[1])
	await process_frame
	if int(game.get("connected")) != 1:
		_fail("Model Power Grid should connect a matching pair.")
		return
	while int(game.get("connected")) < 4:
		correct_pair = _find_unconnected_pair(game)
		if correct_pair.is_empty():
			_fail("Model Power Grid should still have an unconnected matching pair.")
			return
		game.call("_try_connect", correct_pair[0], correct_pair[1])
		await process_frame
	var monitor_glow := game.get("monitor_glow") as ColorRect
	var computer_light := game.get("computer_light") as ColorRect
	if not monitor_glow or monitor_glow.color == Color("#05070a") or not computer_light or computer_light.color != Color("#5cff86"):
		_fail("Model Power Grid should turn on the monitor and computer after all links connect.")
		return
	game.queue_free()
	await process_frame

func _test_gpu_ritual() -> void:
	var game := GpuSacrificeRitual.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	_assert_columns_shuffled(game, "GPU Sacrifice Ritual")
	game.call("_select_socket", _find_pair(game, true)[0])
	await process_frame
	if not game.get("dangling_cable"):
		_fail("GPU Sacrifice Ritual should show a dangling cable after selecting a socket.")
		return

	var correct_pair := _find_pair(game, true)
	game.call("_try_connect", correct_pair[0], correct_pair[1])
	await process_frame
	if int(game.get("connected")) != 1:
		_fail("GPU Sacrifice Ritual should connect a matching pair.")
		return

	game.queue_free()
	await process_frame

func _assert_columns_shuffled(game: Control, label: String) -> void:
	var sockets: Array = game.get("sockets")
	var left_y_by_id := {}
	var right_y_by_id := {}
	for socket_variant in sockets:
		var socket: Dictionary = socket_variant
		var node := socket["node"] as Control
		if String(socket["side"]) == "left":
			left_y_by_id[String(socket["id"])] = node.position.y
		else:
			right_y_by_id[String(socket["id"])] = node.position.y

	var found_misaligned := false
	for id in left_y_by_id.keys():
		if not right_y_by_id.has(id):
			continue
		if not is_equal_approx(float(left_y_by_id[id]), float(right_y_by_id[id])):
			found_misaligned = true
			break
	if not found_misaligned:
		_fail("%s should not align every matching pair on the same row." % label)

func _find_pair(game: Control, should_match: bool) -> Array[int]:
	var sockets: Array = game.get("sockets")
	for first_index in range(sockets.size()):
		var first: Dictionary = sockets[first_index]
		for second_index in range(sockets.size()):
			if first_index == second_index:
				continue
			var second: Dictionary = sockets[second_index]
			if String(first["side"]) == String(second["side"]):
				continue
			var matches := String(first["id"]) == String(second["id"])
			if matches == should_match:
				return [first_index, second_index]
	return []

func _find_unconnected_pair(game: Control) -> Array[int]:
	var sockets: Array = game.get("sockets")
	for first_index in range(sockets.size()):
		var first: Dictionary = sockets[first_index]
		if bool(first["connected"]):
			continue
		for second_index in range(sockets.size()):
			if first_index == second_index:
				continue
			var second: Dictionary = sockets[second_index]
			if bool(second["connected"]):
				continue
			if String(first["side"]) == String(second["side"]):
				continue
			if String(first["id"]) == String(second["id"]):
				return [first_index, second_index]
	return []

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
