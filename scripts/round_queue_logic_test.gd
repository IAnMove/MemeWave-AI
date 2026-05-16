extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const HallucinationHunt := preload("res://scripts/minigames/hallucination_hunt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MainScript.new()
	root.add_child(main)
	await process_frame

	var game_defs: Array = main.get("GAME_DEFS")
	var hallu_index := -1
	for index in game_defs.size():
		if String(game_defs[index]["title_key"]) == "GAME_HALLU_TITLE":
			hallu_index = index
			break
	if hallu_index == -1:
		_fail("Hallucination Hunt is missing from GAME_DEFS.")
		return

	var queue: Array = main.call("_make_random_round_queue")
	var opening_title_keys: Array = main.get("OPENING_GAME_TITLE_KEYS")
	var high_quality_title_keys: Array = main.get("HIGH_QUALITY_GAME_TITLE_KEYS")
	var mid_quality_title_keys: Array = main.get("MID_QUALITY_GAME_TITLE_KEYS")
	var repeat_counts: Dictionary = main.get("ROUND_REPEAT_COUNTS")
	var queue_title_keys: Array[String] = []
	var count := 0
	for game_index in queue:
		if bool(main.call("_is_game_retired", int(game_index))):
			_fail("Round queue should not include retired minigames.")
			return
		queue_title_keys.append(String(game_defs[int(game_index)]["title_key"]))
		if int(game_index) == hallu_index:
			count += 1
	if count != 3:
		_fail("Hallucination Hunt should appear three times in normal random runs.")
		return

	var funeral_index := int(main.call("_game_index_for_title_key", "GAME_FUNERAL_TITLE"))
	if funeral_index == -1 or not bool(main.call("_is_game_retired", funeral_index)):
		_fail("Open Source Funeral should be disabled for the game jam sequence.")
		return
	if queue_title_keys.has("GAME_FUNERAL_TITLE"):
		_fail("Open Source Funeral should not appear in the normal game jam queue.")
		return

	var opening_count := _expected_round_count(main, opening_title_keys, repeat_counts, {})
	for index in range(opening_count):
		if queue_title_keys[index] != String(opening_title_keys[index]):
			_fail("Round queue should start with the curated showcase games.")
			return

	var scheduled := {}
	for title_key in opening_title_keys:
		scheduled[String(title_key)] = true
	var high_quality_count := _expected_round_count(main, high_quality_title_keys, repeat_counts, scheduled)
	var high_quality_lookup := {}
	for title_key in high_quality_title_keys:
		high_quality_lookup[String(title_key)] = true
	for index in range(opening_count, opening_count + high_quality_count):
		if not high_quality_lookup.has(queue_title_keys[index]):
			_fail("High quality minigames should appear before the middle and lower-priority blocks.")
			return

	for title_key in high_quality_title_keys:
		scheduled[String(title_key)] = true
	var mid_quality_count := _expected_round_count(main, mid_quality_title_keys, repeat_counts, scheduled)
	var mid_quality_lookup := {}
	for title_key in mid_quality_title_keys:
		mid_quality_lookup[String(title_key)] = true
	for index in range(opening_count + high_quality_count, opening_count + high_quality_count + mid_quality_count):
		if not mid_quality_lookup.has(queue_title_keys[index]):
			_fail("Middle priority minigames should appear before the lower-priority random block.")
			return

	var developer_groups: Array = main.call("_build_developer_gamejam_groups")
	if developer_groups.size() != 4:
		_fail("Developer jam view should show opening, good, middle, and final random groups.")
		return
	if String(developer_groups[0]["title_key"]) != "GAMEPLAY_JAM_OPENING" or String(developer_groups[1]["title_key"]) != "GAMEPLAY_JAM_GOOD" or String(developer_groups[2]["title_key"]) != "GAMEPLAY_JAM_MID" or String(developer_groups[3]["title_key"]) != "GAMEPLAY_JAM_LOW":
		_fail("Developer jam view should show quality groups in review order.")
		return

	var developer_opening_titles := _title_keys_for_indexes(game_defs, developer_groups[0]["indexes"])
	for index in opening_title_keys.size():
		if developer_opening_titles[index] != String(opening_title_keys[index]):
			_fail("Developer opening group should match the curated game jam opener order.")
			return

	var developer_good_titles := _title_keys_for_indexes(game_defs, developer_groups[0]["indexes"])
	developer_good_titles.append_array(_title_keys_for_indexes(game_defs, developer_groups[1]["indexes"]))
	for title_key in ["GAME_WAKE_PET_TITLE", "GAME_CONTEXT_TITLE", "GAME_HALLU_TITLE", "GAME_TOKENS_TITLE", "GAME_CLAUDE_TITLE", "GAME_AGENT_TITLE", "GAME_RENAME_TITLE"]:
		if not developer_good_titles.has(title_key):
			_fail("Developer good group should include %s." % title_key)
			return

	var developer_mid_titles := _title_keys_for_indexes(game_defs, developer_groups[2]["indexes"])
	for title_key in ["GAME_GPU_TITLE", "GAME_MEMORY_TITLE", "GAME_VACUUM_TITLE"]:
		if not developer_mid_titles.has(title_key):
			_fail("Developer middle group should include %s." % title_key)
			return

	var developer_low_titles := _title_keys_for_indexes(game_defs, developer_groups[3]["indexes"])
	if not developer_low_titles.has("GAME_RAMEN_TITLE") or not developer_low_titles.has("GAME_CODEX_TITLE") or not developer_low_titles.has("GAME_VRAM_TITLE"):
		_fail("Developer low priority group should include the weaker examples.")
		return
	if developer_low_titles.has("GAME_FUNERAL_TITLE"):
		_fail("Disabled games should not appear in the developer jam groups.")
		return

	main.call("_reset_hallucination_fact_queue")
	var seen_facts := {}
	for index in range(HallucinationHunt.FACT_ROUNDS.size()):
		var fact_index := int(main.call("_next_hallucination_fact_index"))
		if seen_facts.has(fact_index):
			_fail("Hallucination Hunt should not repeat a character before every character has appeared once.")
			return
		seen_facts[fact_index] = true
	if seen_facts.size() != HallucinationHunt.FACT_ROUNDS.size():
		_fail("Hallucination Hunt should schedule every character once per cycle.")
		return

	main.queue_free()
	await process_frame
	print("Round queue logic test passed.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _expected_round_count(main: Control, title_keys: Array, repeat_counts: Dictionary, already_scheduled: Dictionary) -> int:
	var count := 0
	for title_key_variant in title_keys:
		var title_key := String(title_key_variant)
		if already_scheduled.has(title_key):
			continue
		var game_index := int(main.call("_game_index_for_title_key", title_key))
		if game_index == -1 or bool(main.call("_is_game_retired", game_index)):
			continue
		count += int(repeat_counts.get(title_key, 1))
	return count

func _title_keys_for_indexes(game_defs: Array, indexes: Array) -> Array[String]:
	var title_keys: Array[String] = []
	for game_index_variant in indexes:
		var game_index := int(game_index_variant)
		title_keys.append(String(game_defs[game_index]["title_key"]))
	return title_keys
