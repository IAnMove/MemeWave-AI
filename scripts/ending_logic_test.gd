extends SceneTree

const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame

	_assert_tier(main, 0, 0, "bad")
	_assert_tier(main, 1, 5, "bad")
	_assert_tier(main, 2, 5, "medium")
	_assert_tier(main, 3, 5, "medium")
	_assert_tier(main, 3, 4, "good")
	_assert_tier(main, 5, 5, "good")
	_assert_score(main, 0, 0, 0)
	_assert_score(main, 2, 5, 40)
	_assert_score(main, 3, 4, 75)
	_assert_score_tier(main, 39, "bad")
	_assert_score_tier(main, 40, "medium")
	_assert_score_tier(main, 74, "medium")
	_assert_score_tier(main, 75, "good")

	TranslationServer.set_locale("es")
	var queue: Array[int] = [0, 1, 2, 3, 4]
	await _assert_summary_ending(main, queue, 1, 12, "bad", "Demo en llamas", "Final malo", "Rendimiento: 20%", "Puntuación meme: 12")
	await _assert_summary_ending(main, queue, 2, 45, "medium", "Beta privada eterna", "Final medio", "Rendimiento: 40%", "Puntuación meme: 45")
	await _assert_summary_ending(main, queue, 4, 123, "good", "Unicornio MemeWave", "Final bueno", "Rendimiento: 80%", "Puntuación meme: 123")

	main.queue_free()
	await process_frame
	print("Ending logic test passed.")
	quit()

func _assert_tier(main: Control, wins: int, rounds: int, expected: String) -> void:
	var actual := String(main.call("_ending_tier_for_result", wins, rounds))
	if actual != expected:
		_fail("Expected %s/%s to be %s, got %s." % [wins, rounds, expected, actual])

func _assert_score(main: Control, wins: int, rounds: int, expected: int) -> void:
	var actual := int(main.call("_performance_score_for_result", wins, rounds))
	if actual != expected:
		_fail("Expected %s/%s to score %d, got %d." % [wins, rounds, expected, actual])

func _assert_score_tier(main: Control, score: int, expected: String) -> void:
	var actual := String(main.call("_ending_tier_for_score", score))
	if actual != expected:
		_fail("Expected score %d to be %s, got %s." % [score, expected, actual])

func _assert_summary_ending(
		main: Control,
		queue: Array[int],
		wins: int,
		total_score: int,
		tier: String,
		title: String,
		rank: String,
		performance: String,
		points: String
	) -> void:
	main.set("wins", wins)
	main.set("total_score", total_score)
	main.set("round_queue", queue)
	main.call("show_summary")
	await process_frame

	if not _has_label_text(main, title):
		_fail("%s title was not rendered in the summary." % title)
		return
	if not _has_label_text(main, rank):
		_fail("%s rank was not rendered in the summary." % rank)
		return
	if not _has_label_text(main, performance):
		_fail("%s was not rendered in the summary." % performance)
		return
	if not _has_label_text(main, points):
		_fail("%s was not rendered in the summary." % points)
		return
	var expected_image_path := String(main.call("_ending_image_path", tier))
	if not _has_texture_path(main, expected_image_path):
		_fail("%s image was not rendered in the summary." % tier)
		return

func _has_label_text(node: Node, text: String) -> bool:
	if node is Label and String(node.get("text")).contains(text):
		return true

	for child in node.get_children():
		if _has_label_text(child, text):
			return true

	return false

func _has_texture_path(node: Node, path: String) -> bool:
	if node is TextureRect:
		var texture := (node as TextureRect).texture
		if texture and texture.resource_path == path:
			return true

	for child in node.get_children():
		if _has_texture_path(child, path):
			return true

	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
