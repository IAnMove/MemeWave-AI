extends SceneTree

const MemoryCast := preload("res://scripts/minigames/memory_cast.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := MemoryCast.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	var cards: Array = game.get("cards")
	if cards.size() != 16:
		_fail("Memory Cast should build a 4x4 grid.")
		return

	var counts := {}
	for card in cards:
		var id := String(card["id"])
		counts[id] = int(counts.get(id, 0)) + 1
	if counts.size() != 8:
		_fail("Memory Cast should have eight unique identities.")
		return
	for id in counts.keys():
		if int(counts[id]) != 2:
			_fail("Memory Cast should deal exactly two cards for %s." % id)
			return

	var pair := _find_matching_pair(cards)
	if pair.is_empty():
		_fail("Memory Cast could not find a matching pair.")
		return

	game.call("_on_card_pressed", int(pair[0]))
	game.call("_on_card_pressed", int(pair[1]))
	await process_frame

	if int(game.get("matches")) != 1:
		_fail("Matching pair should increment matches.")
		return
	if not bool(cards[int(pair[0])]["matched"]) or not bool(cards[int(pair[1])]["matched"]):
		_fail("Matching cards should stay marked as matched.")
		return

	game.queue_free()
	await process_frame
	print("Memory Cast logic test passed.")
	quit()

func _find_matching_pair(cards: Array) -> Array[int]:
	for first in range(cards.size()):
		for second in range(first + 1, cards.size()):
			if String(cards[first]["id"]) == String(cards[second]["id"]):
				return [first, second]
	return []

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
