extends SceneTree

const LicenseMaze := preload("res://scripts/minigames/license_maze.gd")
const EvalCherryPicker := preload("res://scripts/minigames/eval_cherry_picker.gd")
const DeployFriday := preload("res://scripts/minigames/deploy_friday.gd")
const SycophancyWhack := preload("res://scripts/minigames/sycophancy_whack.gd")
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
const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame

	if int(main.get("GAME_DEFS").size()) != 42:
		_fail("Expected 42 minigames in GAME_DEFS")
		return
	main.queue_free()

	await _test_license()
	await _test_eval()
	await _test_deploy()
	await _test_syco()
	await _test_swarm()
	await _test_grok_rage()
	await _test_vibe_deploy()
	await _test_gpu_ritual()
	await _test_archaeologist()
	await _test_rename()
	await _test_funeral()
	await _test_thread()
	await _test_photoshop()
	await _test_denial()
	await _test_apology()
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
	game.call("_try_connect", 0, 1)
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
	game.call("_try_connect", 0, 3)
	await process_frame
	if int(game.get("mistakes")) < 1:
		_fail("GPU Sacrifice Ritual did not process a bad cable")
		return
	await create_timer(0.22).timeout
	game.queue_free()
	await process_frame

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
	var items: Array = game.get("ITEMS")
	var current := int(game.get("current_item"))
	var correct_action := "use" if bool(items[current]["wake"]) else "tuck"
	game.call("_on_choice_pressed", correct_action)
	await process_frame
	if int(game.get("handled")) < 1:
		_fail("Wake Pet did not process a correct action")
		return
	var before_mistakes := int(game.get("mistakes"))
	current = int(game.get("current_item"))
	correct_action = "use" if bool(items[current]["wake"]) else "tuck"
	var wrong_action := "tuck" if correct_action == "use" else "use"
	game.call("_on_choice_pressed", wrong_action)
	await process_frame
	if int(game.get("mistakes")) <= before_mistakes and bool(game.get("running")):
		_fail("Wake Pet did not process a wrong action")
		return
	await create_timer(0.16).timeout
	game.queue_free()
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
