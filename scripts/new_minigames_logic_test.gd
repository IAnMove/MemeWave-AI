extends SceneTree

const LicenseMaze := preload("res://scripts/minigames/license_maze.gd")
const EvalCherryPicker := preload("res://scripts/minigames/eval_cherry_picker.gd")
const DeployFriday := preload("res://scripts/minigames/deploy_friday.gd")
const SycophancyWhack := preload("res://scripts/minigames/sycophancy_whack.gd")
const TokenBurner := preload("res://scripts/minigames/token_burner.gd")
const TokenVacuum := preload("res://scripts/minigames/token_vacuum.gd")
const ClaudeCodeCopycat := preload("res://scripts/minigames/claude_code_copycat.gd")
const DaybreakCopycat := preload("res://scripts/minigames/daybreak_copycat.gd")
const ModelRouter := preload("res://scripts/minigames/model_router.gd")
const ContextTetris := preload("res://scripts/minigames/context_tetris.gd")
const AgentMergeConflict := preload("res://scripts/minigames/agent_merge_conflict.gd")
const DatasetLaundry := preload("res://scripts/minigames/dataset_laundry.gd")
const PrReviewInferno := preload("res://scripts/minigames/pr_review_inferno.gd")
const PromptGatekeeper := preload("res://scripts/minigames/prompt_gatekeeper.gd")
const AgentTaskSwarm := preload("res://scripts/minigames/agent_task_swarm.gd")
const GrokRageMode := preload("res://scripts/minigames/grok_rage_mode.gd")
const VibeDeployProd := preload("res://scripts/minigames/vibe_deploy_prod.gd")
const GpuSacrificeRitual := preload("res://scripts/minigames/gpu_sacrifice_ritual.gd")
const PromptArchaeologist := preload("res://scripts/minigames/prompt_archaeologist.gd")
const ElonRenameButton := preload("res://scripts/minigames/elon_rename_button.gd")
const OpenSourceFuneral := preload("res://scripts/minigames/open_source_funeral.gd")
const ThreadOfDoom := preload("res://scripts/minigames/thread_of_doom.gd")
const BenchmarkPhotoshop := preload("res://scripts/minigames/benchmark_photoshop.gd")
const FounderRunwayDenial := preload("res://scripts/minigames/founder_runway_denial.gd")
const RobotApologyGenerator := preload("res://scripts/minigames/robot_apology_generator.gd")
const WakePet := preload("res://scripts/minigames/wake_pet.gd")
const RamenLocal := preload("res://scripts/minigames/prompt_injection_sushi.gd")
const VramHotSwap := preload("res://scripts/minigames/vram_hot_swap.gd")
const EnvLeakPanic := preload("res://scripts/minigames/env_leak_panic.gd")
const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame

	if int(main.get("GAME_DEFS").size()) != 46:
		_fail("Expected 46 minigames in GAME_DEFS")
		return
	if int((main.call("_active_game_indexes") as Array).size()) != 22:
		_fail("Expected 22 active minigames after retiring discarded games")
		return
	main.queue_free()

	await _test_ramen_local()
	await _test_vram_hot_swap()
	await _test_env_leak_panic()
	await _test_license()
	await _test_syco()
	await _test_gpu_ritual()
	await _test_denial()
	await _test_ollama_gpu()
	await _test_downgrade_crisis()
	await _test_copycat("Claude Code Copycat", ClaudeCodeCopycat, true)
	await _test_copycat("Daybreak Copycat", DaybreakCopycat, false)
	await _test_quick_sort("Model Router", ModelRouter)
	await _test_satellite_alignment()
	await _test_quick_sort("Agent Merge Conflict", AgentMergeConflict)
	await _test_quick_sort("Dataset Laundry", DatasetLaundry)
	await _test_quick_sort("PR Review Inferno", PrReviewInferno)
	await _test_quick_sort("Prompt Gatekeeper", PromptGatekeeper)
	await _test_quick_sort("Friday Deploy", DeployFriday)
	await _test_quick_sort("Agent Task Swarm", AgentTaskSwarm)
	await _test_quick_sort("Grok Rage Mode", GrokRageMode)
	await _test_quick_sort("Prompt Archaeologist", PromptArchaeologist)
	await _test_red_button()
	await _test_quick_sort("Open Source Funeral", OpenSourceFuneral)
	await _test_chrome_ram()
	await _test_quick_sort("Benchmark Photoshop", BenchmarkPhotoshop)
	await _test_quick_sort("Robot Apology Generator", RobotApologyGenerator)
	await _test_wake_pet()

	print("New minigames logic test passed.")
	quit()

func _test_license() -> void:
	var game := LicenseMaze.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_try_move", Vector2i.RIGHT)
	await process_frame
	if int(game.get("steps")) != 1:
		_fail("License Maze did not move right once")
		return
	game.queue_free()
	await process_frame

func _test_eval() -> void:
	var game := EvalCherryPicker.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_on_decision_pressed", "keep")
	await process_frame
	if int(game.get("handled")) + int(game.get("mistakes")) < 1:
		_fail("Eval Cherry Picker did not process a decision")
		return
	game.queue_free()
	await process_frame

func _test_deploy() -> void:
	var game := DeployFriday.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_on_action_pressed", "block")
	await process_frame
	if int(game.get("shipped")) + int(game.get("mistakes")) < 1 and bool(game.get("running")):
		_fail("Deploy Friday did not process an action")
		return
	game.queue_free()
	await process_frame

func _test_syco() -> void:
	var game := SycophancyWhack.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_spawn_bubble")
	await process_frame
	if int(game.get("bubbles").size()) < 1:
		_fail("Sycophancy Whack did not spawn a bubble")
		return
	game.queue_free()
	await process_frame

func _test_swarm() -> void:
	var game := AgentTaskSwarm.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_on_agent_pressed", 0)
	await process_frame
	if int(game.get("handled")) + int(game.get("mistakes")) < 1:
		_fail("Agent Task Swarm did not process assignment")
		return
	game.queue_free()
	await process_frame

func _test_grok_rage() -> void:
	var game := GrokRageMode.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var prompts: Array = game.get("PROMPTS")
	var current := int(game.get("current_prompt"))
	var correct_action := "feed" if bool(prompts[current]["rage"]) else "mute"
	game.call("_on_choice_pressed", correct_action)
	await process_frame
	if int(game.get("handled")) + int(game.get("mistakes")) < 1:
		_fail("Grok Rage Mode did not process a decision")
		return
	var before_mistakes := int(game.get("mistakes"))
	current = int(game.get("current_prompt"))
	correct_action = "feed" if bool(prompts[current]["rage"]) else "mute"
	var wrong_action := "mute" if correct_action == "feed" else "feed"
	game.call("_on_choice_pressed", wrong_action)
	await process_frame
	if int(game.get("mistakes")) <= before_mistakes and bool(game.get("running")):
		_fail("Grok Rage Mode did not process a wrong decision")
		return
	game.queue_free()
	await process_frame

func _test_vibe_deploy() -> void:
	var game := VibeDeployProd.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var cards: Array = game.get("CARDS")
	var current := int(game.get("current_card"))
	var correct_action := "deploy" if bool(cards[current]["safe"]) else "block"
	game.call("_on_action_pressed", correct_action)
	await process_frame
	if int(game.get("handled")) < 1:
		_fail("Vibe Deploy to Prod did not process a correct decision")
		return
	var before_mistakes := int(game.get("mistakes"))
	current = int(game.get("current_card"))
	correct_action = "deploy" if bool(cards[current]["safe"]) else "block"
	var wrong_action := "block" if correct_action == "deploy" else "deploy"
	game.call("_on_action_pressed", wrong_action)
	await process_frame
	if int(game.get("mistakes")) <= before_mistakes and bool(game.get("running")):
		_fail("Vibe Deploy to Prod did not process a wrong decision")
		return
	await create_timer(0.16).timeout
	game.queue_free()
	await process_frame

func _test_gpu_ritual() -> void:
	var game := GpuSacrificeRitual.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var good_pair := _find_socket_pair(game, true)
	game.call("_try_connect", good_pair[0], good_pair[1])
	await process_frame
	if int(game.get("connected")) + int(game.get("mistakes")) < 1:
		_fail("GPU Sacrifice Ritual did not process a cable")
		return
	game.queue_free()
	await process_frame

	game = GpuSacrificeRitual.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var bad_pair := _find_socket_pair(game, false)
	game.call("_try_connect", bad_pair[0], bad_pair[1])
	await process_frame
	if int(game.get("mistakes")) < 1:
		_fail("GPU Sacrifice Ritual did not process a bad cable")
		return
	await create_timer(0.22).timeout
	game.queue_free()
	await process_frame

func _find_socket_pair(game: Control, should_match: bool) -> Array[int]:
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

func _test_archaeologist() -> void:
	var game := PromptArchaeologist.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var layers: Array = game.get("LAYERS")
	var current := int(game.get("current_layer"))
	var correct_action := "dig" if bool(layers[current]["useful"]) else "toss"
	game.call("_on_layer_pressed", correct_action)
	await process_frame
	if int(game.get("handled")) + int(game.get("mistakes")) < 1:
		_fail("Prompt Archaeologist did not process a layer")
		return
	var before_mistakes := int(game.get("mistakes"))
	current = int(game.get("current_layer"))
	correct_action = "dig" if bool(layers[current]["useful"]) else "toss"
	var wrong_action := "toss" if correct_action == "dig" else "dig"
	game.call("_on_layer_pressed", wrong_action)
	await process_frame
	if int(game.get("mistakes")) <= before_mistakes and bool(game.get("running")):
		_fail("Prompt Archaeologist did not process a wrong layer")
		return
	await create_timer(0.16).timeout
	game.queue_free()
	await process_frame

func _test_rename() -> void:
	var game := ElonRenameButton.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var current := int(game.get("current_product"))
	var products: Array = game.get("PRODUCTS")
	game.call("_on_option_pressed", String(products[current]["new_key"]))
	await process_frame
	if int(game.get("rename_count")) < 1:
		_fail("Elon Rename Button did not process a rename")
		return
	current = int(game.get("current_product"))
	products = game.get("PRODUCTS")
	game.call("_on_option_pressed", String(products[current]["wrong"][0]))
	await process_frame
	if int(game.get("mistakes")) < 1:
		_fail("Elon Rename Button did not process a wrong rename")
		return
	await create_timer(0.16).timeout
	game.queue_free()
	await process_frame

func _test_funeral() -> void:
	var game := OpenSourceFuneral.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var current := int(game.get("current_repo"))
	var repos: Array = game.get("REPOS")
	game.call("_on_zone_pressed", String(repos[current]["dest"]))
	await process_frame
	if int(game.get("sorted")) < 1:
		_fail("Open Source Funeral did not sort a repo")
		return
	current = int(game.get("current_repo"))
	repos = game.get("REPOS")
	var wrong_dest := "community"
	if String(repos[current]["dest"]) == wrong_dest:
		wrong_dest = "vault"
	game.call("_on_zone_pressed", wrong_dest)
	await process_frame
	if int(game.get("mistakes")) < 1:
		_fail("Open Source Funeral did not process a wrong repo sort")
		return
	await create_timer(0.16).timeout
	game.queue_free()
	await process_frame

func _test_thread() -> void:
	var game := ThreadOfDoom.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var posts: Array = game.get("POSTS")
	var current := int(game.get("current_post"))
	var correct_action := "reply" if bool(posts[current]["safe"]) else "mute"
	game.call("_on_action_pressed", correct_action)
	await process_frame
	if int(game.get("handled")) < 1:
		_fail("Thread of Doom did not process a correct action")
		return
	var before_mistakes := int(game.get("mistakes"))
	current = int(game.get("current_post"))
	correct_action = "reply" if bool(posts[current]["safe"]) else "mute"
	var wrong_action := "mute" if correct_action == "reply" else "reply"
	game.call("_on_action_pressed", wrong_action)
	await process_frame
	if int(game.get("mistakes")) <= before_mistakes and bool(game.get("running")):
		_fail("Thread of Doom did not process a wrong action")
		return
	await create_timer(0.16).timeout
	game.queue_free()
	await process_frame

func _test_photoshop() -> void:
	var game := BenchmarkPhotoshop.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	var bars: Array = game.get("BARS")
	var current := int(game.get("current_bar"))
	var correct_tool := "stretch" if bool(bars[current]["fake"]) else "crop"
	game.call("_on_tool_pressed", correct_tool)
	await process_frame
	if int(game.get("edited")) < 1:
		_fail("Benchmark Photoshop did not process a correct edit")
		return
	var before_mistakes := int(game.get("mistakes"))
	current = int(game.get("current_bar"))
	correct_tool = "stretch" if bool(bars[current]["fake"]) else "crop"
	var wrong_tool := "crop" if correct_tool == "stretch" else "stretch"
	game.call("_on_tool_pressed", wrong_tool)
	await process_frame
	if int(game.get("mistakes")) <= before_mistakes and bool(game.get("running")):
		_fail("Benchmark Photoshop did not process a wrong edit")
		return
	await create_timer(0.16).timeout
	game.queue_free()
	await process_frame

func _test_denial() -> void:
	var game := FounderRunwayDenial.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_press_all_good")
	await process_frame
	if int(game.get("spin_count")) < 1:
		_fail("Founder Runway Denial did not process all-good spin")
		return
	var invoice := PanelContainer.new()
	root.add_child(invoice)
	game.call("_catch_item", {"node": invoice, "kind": "invoice"})
	await process_frame
	if int(game.get("invoices")) < 1:
		_fail("Founder Runway Denial did not process an invoice")
		return
	game.queue_free()
	await process_frame

func _test_apology() -> void:
	var game := RobotApologyGenerator.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_on_card_pressed", "safety")
	await process_frame
	if int(game.get("current_slot")) < 1:
		_fail("Robot Apology Generator did not accept a card")
		return
	var before_mistakes := int(game.get("mistakes"))
	game.call("_on_card_pressed", "blame")
	await process_frame
	if int(game.get("mistakes")) <= before_mistakes:
		_fail("Robot Apology Generator did not reject a bad card")
		return
	game.queue_free()
	await process_frame

func _test_wake_pet() -> void:
	var game := WakePet.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	game.call("_move_plug_to", Vector2(520, 360))
	await process_frame
	if bool(game.get("plug_connected")):
		_fail("Plug Server connected before snap")
		return

	game.call("_connect_plug")
	await process_frame
	if not bool(game.get("plug_connected")):
		_fail("Plug Server did not snap the plug")
		return
	if int(game.get("score")) != 1:
		_fail("Plug Server did not award completion score")
		return
	var powered_screen := game.get("computer_on") as TextureRect
	if not powered_screen or not powered_screen.visible:
		_fail("Plug Server did not switch to powered-on computer art")
		return

	await create_timer(0.75).timeout
	if bool(game.get("running")):
		_fail("Plug Server did not finish after powering on")
		return
	game.queue_free()
	await process_frame

func _test_ramen_local() -> void:
	var game := RamenLocal.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	game.set("spawn_timer", 99.0)
	game.call("_clear_plates")
	game.call("_spawn_plate", "ram")
	await process_frame
	var plates: Array = game.get("plates")
	if plates.is_empty():
		_fail("RAMen Local did not spawn a RAM plate")
		return
	game.call("_on_plate_pressed", _plate_node_for_id(plates, "ram"))
	await process_frame
	if int(game.get("served")) != 1 or int(game.get("score")) != 1:
		_fail("RAMen Local did not serve a good ingredient")
		return

	game.call("_spawn_plate", "chrome")
	await process_frame
	plates = game.get("plates")
	game.call("_on_plate_pressed", _plate_node_for_id(plates, "chrome"))
	await process_frame
	if int(game.get("mistakes")) != 1:
		_fail("RAMen Local did not punish clicked junk")
		return
	if not bool(game.get("running")):
		_fail("RAMen Local ended too early after one junk click")
		return

	game.queue_free()
	await process_frame

func _plate_node_for_id(plates: Array, plate_id: String) -> Button:
	for plate_variant in plates:
		var plate: Dictionary = plate_variant
		if String(plate.get("id", "")) == plate_id:
			return plate["node"] as Button
	return null

func _test_vram_hot_swap() -> void:
	var game := VramHotSwap.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	game.call("_on_model_button_pressed", "whisper")
	await process_frame
	if int(game.get("jobs_done")) != 1 or int(game.get("used_vram")) != 6:
		_fail("VRAM Hot Swap did not load Whisper and finish the audio job")
		return

	game.call("_on_model_button_pressed", "gemma4")
	await process_frame
	if int(game.get("jobs_done")) != 2 or int(game.get("used_vram")) != 16:
		_fail("VRAM Hot Swap did not keep loaded models across jobs")
		return

	game.call("_on_model_button_pressed", "flux")
	await process_frame
	if int(game.get("mistakes")) != 1:
		_fail("VRAM Hot Swap did not reject an over-capacity load")
		return

	game.call("_eject_model", "gemma4")
	game.call("_eject_model", "whisper")
	await process_frame
	game.call("_on_model_button_pressed", "flux")
	await process_frame
	if int(game.get("jobs_done")) != 3 or int(game.get("used_vram")) != 20:
		_fail("VRAM Hot Swap did not recover after ejecting models")
		return

	game.queue_free()
	await process_frame

func _test_env_leak_panic() -> void:
	var game := EnvLeakPanic.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	if float(game.get("time_left")) < 11.5:
		_fail("ENV Leak Panic should start with 12 seconds on the timer")
		return

	game.call("_force_cover_all_leaks")
	await process_frame
	if int(game.get("covered_count")) != 4 or int(game.get("score")) != 4:
		_fail("ENV Leak Panic did not cover all exposed secrets")
		return
	var leaks: Array = game.get("leaks")
	for leak_variant in leaks:
		var leak: Dictionary = leak_variant
		if not bool(leak.get("covered", false)):
			_fail("ENV Leak Panic left a leak uncovered")
			return

	await create_timer(0.70).timeout
	if bool(game.get("running")):
		_fail("ENV Leak Panic did not finish after all secrets were covered")
		return
	game.queue_free()
	await process_frame

func _test_chrome_ram() -> void:
	var game := ThreadOfDoom.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	var active := int(game.get("active_tab"))
	var tab_count := ThreadOfDoom.TAB_COUNT
	var inactive := 0 if active != 0 else 1
	game.call("_close_tab", inactive)
	await create_timer(0.16).timeout
	if int(game.get("closed_count")) < 1:
		_fail("Chrome RAM did not close an inactive tab")
		return

	game.call("_close_tab", active)
	await create_timer(0.80).timeout
	if bool(game.get("running")):
		_fail("Chrome RAM did not fail after closing the active tab")
		return

	game.queue_free()
	await process_frame

	game = ThreadOfDoom.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	active = int(game.get("active_tab"))
	tab_count = ThreadOfDoom.TAB_COUNT
	for index in range(tab_count):
		if index != active:
			game.call("_close_tab", index)
	await create_timer(0.90).timeout
	if bool(game.get("running")):
		_fail("Chrome RAM did not finish after closing extra tabs")
		return
	if int(game.get("score")) < tab_count - 1:
		_fail("Chrome RAM did not count all closed tabs")
		return
	game.queue_free()
	await process_frame

func _test_ollama_gpu() -> void:
	var game := TokenBurner.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	var before := float(game.get("temperature"))
	game.call("_move_fan_to", Vector2(310, 306))
	await create_timer(0.45).timeout
	if not bool(game.get("cooling")):
		_fail("Cool Ollama did not cool when the fan overlaps the laptop")
		return
	if float(game.get("temperature")) >= before:
		_fail("Cool Ollama temperature did not go down")
		return

	game.set("temperature", 3.0)
	await create_timer(0.25).timeout
	if bool(game.get("running")):
		_fail("Cool Ollama did not finish after cooling")
		return
	game.queue_free()
	await process_frame

func _test_downgrade_crisis() -> void:
	var game := TokenVacuum.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	game.call("_force_usage", 80.0)
	game.call("_spawn_user", false)
	game.call("_spawn_user", false)
	game.call("_on_downgrade_pressed")
	await create_timer(0.20).timeout
	if not bool(game.get("downgraded")):
		_fail("Downgrade Crisis did not enter downgraded state")
		return
	if float(game.get("usage")) > 11.0:
		_fail("Downgrade Crisis did not drop token usage after downgrade")
		return
	var users: Array = game.get("users")
	if users.is_empty() or not (users[0] as TextureRect).texture:
		_fail("Downgrade Crisis did not render users")
		return
	await create_timer(1.0).timeout
	game.queue_free()
	await process_frame

func _test_copycat(game_name: String, script: GDScript, test_success: bool) -> void:
	var game: Control = script.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	game.call("_force_dario_watching", false)
	game.call("_force_hold", true)
	await create_timer(0.35).timeout
	if float(game.get("copy_progress")) <= 8.0:
		_fail("%s did not copy while holding in safe state" % game_name)
		return

	var before_alert := float(game.get("copy_progress"))
	game.call("_force_dario_alert")
	await create_timer(0.20).timeout
	if not bool(game.get("running")):
		_fail("%s failed during Dario's front-facing warning phase" % game_name)
		return
	if bool(game.get("dario_watching")):
		_fail("%s treated Dario's front-facing warning phase as watching" % game_name)
		return
	if float(game.get("copy_progress")) > before_alert + 1.0:
		_fail("%s advanced copying during Dario's front-facing warning phase" % game_name)
		return
	var alert_bg := game.get("alert_bg") as TextureRect
	if not alert_bg or not alert_bg.visible:
		_fail("%s did not show the front-facing Dario warning background" % game_name)
		return
	game.call("_force_dario_watching", false)

	if test_success:
		game.set("copy_progress", 98.0)
		game.call("_update_copy_visual")
		await create_timer(0.20).timeout
		if bool(game.get("running")):
			_fail("%s did not finish after completing the copy" % game_name)
			return
	else:
		game.call("_force_dario_watching", true)
		await create_timer(0.24).timeout
		if bool(game.get("running")):
			_fail("%s did not fail when copying while Dario watches" % game_name)
			return

	game.queue_free()
	await process_frame

func _test_red_button() -> void:
	var game := ElonRenameButton.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	game.call("_press_red_button")
	await create_timer(0.90).timeout
	if bool(game.get("running")):
		_fail("Red Button did not fail after pressing")
		return
	if not bool((game.get("scold_sprite") as TextureRect).visible):
		_fail("Red Button did not show the scolding character")
		return

	game.queue_free()
	await process_frame

	game = ElonRenameButton.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await create_timer(4.45).timeout
	if bool(game.get("running")):
		_fail("Red Button did not finish after waiting")
		return
	game.queue_free()
	await process_frame

func _test_satellite_alignment() -> void:
	var game := ContextTetris.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	if not bool(game.get("running")):
		_fail("Satellite Alignment did not start")
		return
	game.call("_set_satellite_x", ContextTetris.TARGET_SATELLITE_X)
	await create_timer(0.80).timeout
	if bool(game.get("running")):
		_fail("Satellite Alignment did not finish after locking signal")
		return
	game.queue_free()
	await process_frame

func _test_quick_sort(game_name: String, script: GDScript) -> void:
	var game: Control = script.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame

	var item_defs: Array = game.get("item_defs")
	var option_defs: Array = game.get("option_defs")
	var current := int(game.get("current_item"))
	if current < 0 or current >= item_defs.size():
		_fail("%s did not spawn an item" % game_name)
		return

	var correct := String((item_defs[current] as Dictionary)["correct"])
	game.call("_choose_action", correct)
	await create_timer(0.24).timeout
	if int(game.get("handled")) < 1:
		_fail("%s did not process a correct action" % game_name)
		return

	if bool(game.get("running")):
		current = int(game.get("current_item"))
		correct = String((item_defs[current] as Dictionary)["correct"])
		var wrong := _wrong_quick_action(option_defs, correct)
		var before_mistakes := int(game.get("mistakes"))
		game.call("_choose_action", wrong)
		await create_timer(0.24).timeout
		if int(game.get("mistakes")) <= before_mistakes and bool(game.get("running")):
			_fail("%s did not process a wrong action" % game_name)
			return
		if bool(game.get("running")):
			game.finish(false)

	game.queue_free()
	await process_frame

func _wrong_quick_action(option_defs: Array, correct: String) -> String:
	for option_variant in option_defs:
		var option: Dictionary = option_variant
		var action := String(option["id"])
		if action != correct:
			return action
	return "__wrong__"

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
