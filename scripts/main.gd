extends Control

const RepoPrivate := preload("res://scripts/minigames/repo_private.gd")
const TokenBurner := preload("res://scripts/minigames/token_burner.gd")
const BenchmarkArena := preload("res://scripts/minigames/benchmark_arena.gd")
const CodexInvestment := preload("res://scripts/minigames/codex_investment.gd")
const ClaudeRateLimit := preload("res://scripts/minigames/claude_rate_limit.gd")
const EnergyLinks := preload("res://scripts/minigames/energy_links.gd")
const ModelRouter := preload("res://scripts/minigames/model_router.gd")
const HallucinationHunt := preload("res://scripts/minigames/hallucination_hunt.gd")
const MemoryCast := preload("res://scripts/minigames/memory_cast.gd")
const ContextTetris := preload("res://scripts/minigames/context_tetris.gd")
const PromptInjectionSushi := preload("res://scripts/minigames/prompt_injection_sushi.gd")
const AgentFocus := preload("res://scripts/minigames/agent_focus.gd")
const ChoiceCodePlanning := preload("res://scripts/minigames/choice_code_planning.gd")
const ChoicePrettyPage := preload("res://scripts/minigames/choice_pretty_page.gd")
const ChoiceComplexTasks := preload("res://scripts/minigames/choice_complex_tasks.gd")
const AgentMergeConflict := preload("res://scripts/minigames/agent_merge_conflict.gd")
const TokenVacuum := preload("res://scripts/minigames/token_vacuum.gd")
const GpuBlackFriday := preload("res://scripts/minigames/gpu_black_friday.gd")
const DatasetLaundry := preload("res://scripts/minigames/dataset_laundry.gd")
const StartupRunwayRunner := preload("res://scripts/minigames/startup_runway_runner.gd")
const FinetuneKitchen := preload("res://scripts/minigames/finetune_kitchen.gd")
const PrReviewInferno := preload("res://scripts/minigames/pr_review_inferno.gd")
const BenchmarkCasino := preload("res://scripts/minigames/benchmark_casino.gd")
const TosNinja := preload("res://scripts/minigames/tos_ninja.gd")
const CopilotSuggestions := preload("res://scripts/minigames/copilot_suggestions.gd")
const PromptGatekeeper := preload("res://scripts/minigames/prompt_gatekeeper.gd")
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
const SketchPanel := preload("res://scripts/ui/sketch_panel.gd")
const SketchIcon := preload("res://scripts/ui/sketch_icon.gd")
const VolumeBar := preload("res://scripts/ui/volume_bar.gd")

const DEFAULT_LOCALE := "es"
const LOCALE_SEQUENCE := ["es", "en"]
const SAVE_PATH := "user://progress.cfg"
const UI_CLICK_SOUND_PATH := "res://assets/sounds/ui_click.wav"
const ROUND_TRANSITION_SOUND_PATH := "res://assets/sounds/round_transition.wav"
const MENU_MUSIC_PATH := "res://assets/sounds/Meme Mayhem_ Maximum Chaos.mp3"
const GAME_MUSIC_PATH := "res://assets/sounds/Meme Micro Mayhem_ Extended Instrumental..mp3"
const ROUND_REPEAT_COUNTS := {
	"GAME_HALLU_TITLE": 3
}
const DEV_GAMEPLAY_GROUPS := [
	{
		"title_key": "GAMEPLAY_CLICK_TARGETS",
		"game_title_keys": [
			"GAME_REPO_TITLE",
			"GAME_CLAUDE_TITLE",
			"GAME_HALLU_TITLE",
			"GAME_INJECTION_TITLE",
			"GAME_AGENT_TITLE",
			"GAME_TOS_TITLE",
			"GAME_SYCO_TITLE",
			"GAME_MERGE_TITLE",
			"GAME_PR_TITLE",
			"GAME_PROMPT_GATE_TITLE",
			"GAME_GROK_RAGE_TITLE",
			"GAME_ARCHAEOLOGY_TITLE",
			"GAME_RENAME_TITLE",
			"GAME_THREAD_TITLE",
			"GAME_PHOTOSHOP_TITLE",
			"GAME_APOLOGY_TITLE"
		]
	},
	{
		"title_key": "GAMEPLAY_DRAG_DROP",
		"game_title_keys": [
			"GAME_TOKENS_TITLE",
			"GAME_ROUTER_TITLE",
			"GAME_CONTEXT_TITLE",
			"GAME_DATASET_TITLE",
			"GAME_FUNERAL_TITLE",
			"GAME_WAKE_PET_TITLE"
		]
	},
	{
		"title_key": "GAMEPLAY_MOVE_CATCH",
		"game_title_keys": [
			"GAME_CODEX_TITLE",
			"GAME_GPU_TITLE",
			"GAME_RUNWAY_TITLE",
			"GAME_LICENSE_TITLE",
			"GAME_DENIAL_TITLE",
			"GAME_DEPLOY_TITLE"
		]
	},
	{
		"title_key": "GAMEPLAY_TIMING",
		"game_title_keys": [
			"GAME_BENCH_TITLE",
			"GAME_VACUUM_TITLE",
			"GAME_CASINO_TITLE"
		]
	},
	{
		"title_key": "GAMEPLAY_PAIR_MATCHING",
		"game_title_keys": [
			"GAME_ENERGY_TITLE",
			"GAME_GPU_RITUAL_TITLE",
			"GAME_SWARM_TITLE"
		]
	},
	{
		"title_key": "GAMEPLAY_MEMORY",
		"game_title_keys": [
			"GAME_MEMORY_TITLE"
		]
	}
]
const PENDING_DELETE_GAME_TITLE_KEYS := [
	"GAME_ROUTER_TITLE",
	"GAME_MERGE_TITLE",
	"GAME_DATASET_TITLE",
	"GAME_DEPLOY_TITLE",
	"GAME_CASINO_TITLE",
	"GAME_PR_TITLE",
	"GAME_TOS_TITLE",
	"GAME_PROMPT_GATE_TITLE",
	"GAME_SWARM_TITLE",
	"GAME_GROK_RAGE_TITLE",
	"GAME_ARCHAEOLOGY_TITLE",
	"GAME_FUNERAL_TITLE",
	"GAME_PHOTOSHOP_TITLE",
	"GAME_APOLOGY_TITLE"
]

const GAME_DEFS := [
	{
		"title_key": "GAME_REPO_TITLE",
		"script": RepoPrivate,
		"description_key": "GAME_REPO_DESC",
		"thumbnail": "res://assets/art/repo_private_bg.png"
	},
	{
		"title_key": "GAME_TOKENS_TITLE",
		"script": TokenBurner,
		"description_key": "GAME_TOKENS_DESC",
		"thumbnail": "res://assets/art/ollama_laptop_hot.png"
	},
	{
		"title_key": "GAME_BENCH_TITLE",
		"script": BenchmarkArena,
		"description_key": "GAME_BENCH_DESC",
		"thumbnail": "res://assets/art/benchmark_arena_bg.png"
	},
	{
		"title_key": "GAME_CODEX_TITLE",
		"script": CodexInvestment,
		"description_key": "GAME_CODEX_DESC",
		"thumbnail": "res://assets/art/codex_investment_bg.png"
	},
	{
		"title_key": "GAME_CLAUDE_TITLE",
		"script": ClaudeRateLimit,
		"description_key": "GAME_CLAUDE_DESC",
		"thumbnail": "res://assets/sprites/dario_amodei.png"
	},
	{
		"title_key": "GAME_ENERGY_TITLE",
		"script": EnergyLinks,
		"description_key": "GAME_ENERGY_DESC",
		"thumbnail": "res://assets/art/object_spritesheet.png"
	},
	{
		"title_key": "GAME_ROUTER_TITLE",
		"script": ModelRouter,
		"description_key": "GAME_ROUTER_DESC",
		"thumbnail": "res://assets/sprites/leaderboard.png"
	},
	{
		"title_key": "GAME_HALLU_TITLE",
		"script": HallucinationHunt,
		"description_key": "GAME_HALLU_DESC",
		"thumbnail": "res://assets/sprites/rate_limit.png"
	},
	{
		"title_key": "GAME_MEMORY_TITLE",
		"script": MemoryCast,
		"description_key": "GAME_MEMORY_DESC",
		"instruction_key": "MEMORY_INSTRUCTIONS",
		"thumbnail": "res://assets/sprites/sam_face.png"
	},
	{
		"title_key": "GAME_CONTEXT_TITLE",
		"script": ContextTetris,
		"description_key": "GAME_CONTEXT_DESC",
		"thumbnail": "res://assets/art/satellite_signal_bg.png"
	},
	{
		"title_key": "GAME_INJECTION_TITLE",
		"script": PromptInjectionSushi,
		"description_key": "GAME_INJECTION_DESC",
		"thumbnail": "res://assets/sprites/hungry_model.png"
	},
	{
		"title_key": "GAME_AGENT_TITLE",
		"script": AgentFocus,
		"description_key": "GAME_AGENT_DESC",
		"thumbnail": "res://assets/sprites/sam_face.png"
	},
	{
		"title_key": "GAME_CHOICE_PLAN_TITLE",
		"script": ChoiceCodePlanning,
		"description_key": "GAME_CHOICE_PLAN_DESC",
		"thumbnail": "res://assets/sprites/dario_amodei.png",
		"retired": true
	},
	{
		"title_key": "GAME_CHOICE_PAGE_TITLE",
		"script": ChoicePrettyPage,
		"description_key": "GAME_CHOICE_PAGE_DESC",
		"thumbnail": "res://assets/art/title.png",
		"retired": true
	},
	{
		"title_key": "GAME_CHOICE_COMPLEX_TITLE",
		"script": ChoiceComplexTasks,
		"description_key": "GAME_CHOICE_COMPLEX_DESC",
		"thumbnail": "res://assets/sprites/sam_face.png",
		"retired": true
	},
	{
		"title_key": "GAME_MERGE_TITLE",
		"script": AgentMergeConflict,
		"description_key": "GAME_MERGE_DESC",
		"thumbnail": "res://assets/sprites/leaderboard.png"
	},
	{
		"title_key": "GAME_VACUUM_TITLE",
		"script": TokenVacuum,
		"description_key": "GAME_VACUUM_DESC",
		"thumbnail": "res://assets/sprites/token.png"
	},
	{
		"title_key": "GAME_GPU_TITLE",
		"script": GpuBlackFriday,
		"description_key": "GAME_GPU_DESC",
		"thumbnail": "res://assets/art/gpu_black_friday_sam_cart.png"
	},
	{
		"title_key": "GAME_DATASET_TITLE",
		"script": DatasetLaundry,
		"description_key": "GAME_DATASET_DESC",
		"thumbnail": "res://assets/sprites/hungry_model.png"
	},
	{
		"title_key": "GAME_RUNWAY_TITLE",
		"script": StartupRunwayRunner,
		"description_key": "GAME_RUNWAY_DESC",
		"thumbnail": "res://assets/sprites/dollar_bill.png"
	},
	{
		"title_key": "GAME_KITCHEN_TITLE",
		"script": FinetuneKitchen,
		"description_key": "GAME_KITCHEN_DESC",
		"thumbnail": "res://assets/sprites/token.png",
		"retired": true
	},
	{
		"title_key": "GAME_PR_TITLE",
		"script": PrReviewInferno,
		"description_key": "GAME_PR_DESC",
		"thumbnail": "res://assets/sprites/leaderboard.png"
	},
	{
		"title_key": "GAME_CASINO_TITLE",
		"script": BenchmarkCasino,
		"description_key": "GAME_CASINO_DESC",
		"thumbnail": "res://assets/art/benchmark_arena_bg.png"
	},
	{
		"title_key": "GAME_TOS_TITLE",
		"script": TosNinja,
		"description_key": "GAME_TOS_DESC",
		"thumbnail": "res://assets/art/object_spritesheet.png"
	},
	{
		"title_key": "GAME_COPILOT_TITLE",
		"script": CopilotSuggestions,
		"description_key": "GAME_COPILOT_DESC",
		"thumbnail": "res://assets/sprites/leaderboard.png",
		"retired": true
	},
	{
		"title_key": "GAME_PROMPT_GATE_TITLE",
		"script": PromptGatekeeper,
		"description_key": "GAME_PROMPT_GATE_DESC",
		"instruction_key": "PROMPT_GATE_INSTRUCTIONS",
		"rich_instruction_key": "PROMPT_GATE_INSTRUCTIONS_RICH",
		"thumbnail": "res://assets/sprites/rate_limit.png"
	},
	{
		"title_key": "GAME_LICENSE_TITLE",
		"script": LicenseMaze,
		"description_key": "GAME_LICENSE_DESC",
		"instruction_key": "LICENSE_INSTRUCTIONS",
		"thumbnail": "res://assets/art/license_maze_bg.png"
	},
	{
		"title_key": "GAME_EVAL_TITLE",
		"script": EvalCherryPicker,
		"description_key": "GAME_EVAL_DESC",
		"instruction_key": "EVAL_INSTRUCTIONS",
		"thumbnail": "res://assets/art/eval_cherry_picker_bg.png",
		"retired": true
	},
	{
		"title_key": "GAME_DEPLOY_TITLE",
		"script": DeployFriday,
		"description_key": "GAME_DEPLOY_DESC",
		"instruction_key": "DEPLOY_INSTRUCTIONS",
		"thumbnail": "res://assets/art/deploy_friday_bg.png"
	},
	{
		"title_key": "GAME_SYCO_TITLE",
		"script": SycophancyWhack,
		"description_key": "GAME_SYCO_DESC",
		"instruction_key": "SYCO_INSTRUCTIONS",
		"thumbnail": "res://assets/art/sycophancy_whack_bg.png"
	},
	{
		"title_key": "GAME_SWARM_TITLE",
		"script": AgentTaskSwarm,
		"description_key": "GAME_SWARM_DESC",
		"instruction_key": "SWARM_INSTRUCTIONS",
		"thumbnail": "res://assets/art/agent_task_swarm_bg.png"
	},
	{
		"title_key": "GAME_GROK_RAGE_TITLE",
		"script": GrokRageMode,
		"description_key": "GAME_GROK_RAGE_DESC",
		"instruction_key": "GROK_RAGE_INSTRUCTIONS",
		"thumbnail": "res://assets/art/sycophancy_whack_bg.png"
	},
	{
		"title_key": "GAME_VIBE_DEPLOY_TITLE",
		"script": VibeDeployProd,
		"description_key": "GAME_VIBE_DEPLOY_DESC",
		"instruction_key": "VIBE_DEPLOY_INSTRUCTIONS",
		"thumbnail": "res://assets/art/deploy_friday_bg.png",
		"retired": true
	},
	{
		"title_key": "GAME_GPU_RITUAL_TITLE",
		"script": GpuSacrificeRitual,
		"description_key": "GAME_GPU_RITUAL_DESC",
		"instruction_key": "GPU_RITUAL_INSTRUCTIONS",
		"thumbnail": "res://assets/art/object_spritesheet.png"
	},
	{
		"title_key": "GAME_ARCHAEOLOGY_TITLE",
		"script": PromptArchaeologist,
		"description_key": "GAME_ARCHAEOLOGY_DESC",
		"instruction_key": "ARCHAEOLOGY_INSTRUCTIONS",
		"thumbnail": "res://assets/sprites/token.png"
	},
	{
		"title_key": "GAME_RENAME_TITLE",
		"script": ElonRenameButton,
		"description_key": "GAME_RENAME_DESC",
		"instruction_key": "RENAME_INSTRUCTIONS",
		"thumbnail": "res://assets/art/red_button_bg.png"
	},
	{
		"title_key": "GAME_FUNERAL_TITLE",
		"script": OpenSourceFuneral,
		"description_key": "GAME_FUNERAL_DESC",
		"instruction_key": "FUNERAL_INSTRUCTIONS",
		"thumbnail": "res://assets/art/repo_private_bg.png"
	},
	{
		"title_key": "GAME_THREAD_TITLE",
		"script": ThreadOfDoom,
		"description_key": "GAME_THREAD_DESC",
		"instruction_key": "THREAD_INSTRUCTIONS",
		"thumbnail": "res://assets/art/chrome_ram_bg.png"
	},
	{
		"title_key": "GAME_PHOTOSHOP_TITLE",
		"script": BenchmarkPhotoshop,
		"description_key": "GAME_PHOTOSHOP_DESC",
		"instruction_key": "PHOTOSHOP_INSTRUCTIONS",
		"thumbnail": "res://assets/art/benchmark_arena_bg.png"
	},
	{
		"title_key": "GAME_DENIAL_TITLE",
		"script": FounderRunwayDenial,
		"description_key": "GAME_DENIAL_DESC",
		"instruction_key": "DENIAL_INSTRUCTIONS",
		"thumbnail": "res://assets/sprites/dollar_bill.png"
	},
	{
		"title_key": "GAME_APOLOGY_TITLE",
		"script": RobotApologyGenerator,
		"description_key": "GAME_APOLOGY_DESC",
		"instruction_key": "APOLOGY_INSTRUCTIONS",
		"thumbnail": "res://assets/sprites/hungry_model.png"
	},
	{
		"title_key": "GAME_WAKE_PET_TITLE",
		"script": WakePet,
		"description_key": "GAME_WAKE_PET_DESC",
		"thumbnail": "res://assets/art/server_computer_on.png"
	}
]

var current_view: Control
var current_screen := ""
var current_index := 0
var active_game_index := 0
var wins := 0
var total_score := 0
var timer_label: Label
var round_label: Label
var round_queue: Array[int] = []
var direct_launch := false
var direct_developer := false
var unlocked_minigames: Array[bool] = []
var view_generation := 0
var ui_click_player: AudioStreamPlayer
var round_transition_player: AudioStreamPlayer
var menu_music_player: AudioStreamPlayer
var game_music_player: AudioStreamPlayer
var active_music_mode := ""
var sound_volume := 0.8

func _ready() -> void:
	randomize()
	_set_full_rect(self)
	_set_initial_locale()
	_load_progress()
	_build_global_sounds()
	show_main_menu()

func _input(event: InputEvent) -> void:
	if _is_primary_click(event):
		_play_ui_click()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if current_screen == "menu" and event.keycode == KEY_D:
		show_developer_menu()
		return

	if current_screen == "game" and direct_launch and direct_developer and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		show_collection(true)
		return

	if current_screen == "developer" or current_screen == "developer_grid":
		var digit := _digit_for_key(event.keycode)
		var active_indexes := _active_game_indexes()
		if digit > 0 and digit <= active_indexes.size():
			start_direct_game(active_indexes[digit - 1], true)

func show_main_menu() -> void:
	_clear_view()
	current_screen = "menu"
	_set_music_mode("menu")
	var menu := _make_screen(Color("#f4ead8"))
	current_view = menu

	var paper: Control = SketchPanel.new()
	paper.position = Vector2(8, 8)
	paper.size = Vector2(1264, 704)
	paper.call("configure", Color("#fffaf0"), Color("#111111"), 4.0, 2.0, true, Color("#4aa3df18"))
	menu.add_child(paper)

	_add_menu_doodles(menu)

	var art := _make_texture("res://assets/art/title.png")
	art.position = Vector2(46, 206)
	art.size = Vector2(330, 300)
	menu.add_child(art)

	var title_main := _make_label("MemeWave", 88, Color("#ffcf22"), HORIZONTAL_ALIGNMENT_LEFT)
	title_main.position = Vector2(154, 28)
	title_main.size = Vector2(610, 100)
	title_main.add_theme_color_override("font_outline_color", Color("#111111"))
	title_main.add_theme_constant_override("outline_size", 8)
	menu.add_child(title_main)

	var title_ai := _make_label("AI", 88, Color("#a542ff"), HORIZONTAL_ALIGNMENT_LEFT)
	title_ai.position = Vector2(744, 28)
	title_ai.size = Vector2(150, 100)
	title_ai.add_theme_color_override("font_outline_color", Color("#111111"))
	title_ai.add_theme_constant_override("outline_size", 8)
	menu.add_child(title_ai)

	var subtitle_highlight := ColorRect.new()
	subtitle_highlight.position = Vector2(326, 154)
	subtitle_highlight.size = Vector2(430, 18)
	subtitle_highlight.color = Color("#ffef5faa")
	menu.add_child(subtitle_highlight)

	var subtitle := _make_label(tr("MENU_SUBTITLE"), 23, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.position = Vector2(318, 132)
	subtitle.size = Vector2(456, 96)
	subtitle.add_theme_color_override("font_outline_color", Color("#fffaf0"))
	subtitle.add_theme_constant_override("outline_size", 2)
	menu.add_child(subtitle)

	var subtitle_underline := ColorRect.new()
	subtitle_underline.position = Vector2(340, 230)
	subtitle_underline.size = Vector2(390, 5)
	subtitle_underline.color = Color("#ff5fa8")
	menu.add_child(subtitle_underline)

	_add_menu_action_button(menu, tr("MENU_START"), Vector2(446, 270), Color("#ffdf2e"), "plane", Callable(self, "start_game"), 34)
	_add_menu_action_button(menu, tr("MENU_COLLECTION"), Vector2(446, 348), Color("#b9f56a"), "robot", func() -> void: show_collection(false), 29)
	_add_menu_action_button(menu, tr("MENU_DESCRIPTIONS"), Vector2(446, 424), Color("#ff8fd2"), "funnel", Callable(self, "show_descriptions"), 28)
	_add_menu_action_button(menu, tr("MENU_QUIT"), Vector2(446, 500), Color("#ff9a37"), "trash", func() -> void: get_tree().quit(), 28)

	var language_button := _make_button(_language_button_text(), 20, Color("#fffdf8"))
	language_button.position = Vector2(918, 54)
	language_button.size = Vector2(242, 44)
	language_button.pressed.connect(_toggle_locale)
	menu.add_child(language_button)

	var dev_button := _make_button(tr("MENU_DEV_HINT"), 19, Color("#fffdf8"))
	dev_button.position = Vector2(918, 110)
	dev_button.size = Vector2(242, 44)
	dev_button.pressed.connect(show_developer_menu)
	menu.add_child(dev_button)

	var gear := _make_button("⚙", 31, Color("#fffdf8"))
	gear.position = Vector2(1194, 24)
	gear.size = Vector2(52, 52)
	gear.pressed.connect(func() -> void: _play_ui_click())
	menu.add_child(gear)

	_add_volume_control(menu)
	_add_menu_computer_preview(menu)
	_add_menu_note(menu)

func show_descriptions() -> void:
	_clear_view()
	current_screen = "descriptions"
	_set_music_mode("menu")
	var screen := _make_screen(Color("#fff4b8"))
	current_view = screen

	var title := _make_label(tr("DESCRIPTIONS_TITLE"), 47, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(65, 34)
	title.size = Vector2(1150, 70)
	screen.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(105, 118)
	scroll.size = Vector2(1070, 458)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(1070, 458)
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for index in _active_game_indexes():
		var def: Dictionary = GAME_DEFS[index]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(1070, 78)
		card.add_theme_stylebox_override("panel", _make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 8))
		list.add_child(card)

		var text := "%s: %s" % [tr(def["title_key"]), tr(def["description_key"])]
		var label := _make_label(text, 21, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
		label.custom_minimum_size = Vector2(1030, 70)
		card.add_child(label)

	var back := _make_button(tr("MENU_BACK"), 32, Color("#ffef5f"))
	back.position = Vector2(460, 598)
	back.size = Vector2(360, 70)
	back.pressed.connect(show_main_menu)
	screen.add_child(back)

func show_developer_menu() -> void:
	_clear_view()
	current_screen = "developer"
	_set_music_mode("menu")
	var screen := _make_screen(Color("#202025"))

	var title := _make_label(tr("DEV_TITLE"), 62, Color("#fff06a"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, 96)
	title.size = Vector2(1280, 90)
	title.add_theme_color_override("font_outline_color", Color("#000000"))
	title.add_theme_constant_override("outline_size", 9)
	screen.add_child(title)

	var panel := PanelContainer.new()
	panel.position = Vector2(370, 230)
	panel.size = Vector2(540, 255)
	panel.add_theme_stylebox_override("panel", _make_style(Color("#ffffff"), Color("#1d1d1d"), 5, 8))
	screen.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var description := _make_label(tr("DEV_SUBTITLE"), 25, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	description.custom_minimum_size = Vector2(500, 70)
	box.add_child(description)

	var grid_button := _make_button(tr("DEV_GRID"), 32, Color("#ffef5f"))
	grid_button.custom_minimum_size = Vector2(420, 72)
	grid_button.pressed.connect(func() -> void: show_collection(true))
	box.add_child(grid_button)

	var back := _make_button(tr("MENU_BACK"), 28, Color("#ff9fd6"))
	back.custom_minimum_size = Vector2(420, 58)
	back.pressed.connect(show_main_menu)
	box.add_child(back)

func show_collection(developer: bool) -> void:
	_clear_view()
	current_screen = "developer_grid" if developer else "collection"
	_set_music_mode("menu")
	var screen := _make_screen(Color("#111827") if developer else Color("#fff4b8"))

	var title_key := "COLLECTION_DEV_TITLE" if developer else "COLLECTION_TITLE"
	var title_color := Color("#fff06a") if developer else Color("#1d1d1d")
	var title := _make_label(tr(title_key), 52, title_color, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, 34)
	title.size = Vector2(1280, 68)
	title.add_theme_color_override("font_outline_color", Color("#000000") if developer else Color("#ffffff"))
	title.add_theme_constant_override("outline_size", 5)
	screen.add_child(title)

	var hint_key := "COLLECTION_DEV_HINT" if developer else "COLLECTION_HINT"
	var hint := _make_label(tr(hint_key), 22, Color("#e7eefc") if developer else Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(105, 98)
	hint.size = Vector2(1070, 44)
	screen.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(78, 150) if developer else Vector2(92, 158)
	scroll.size = Vector2(1124, 442) if developer else Vector2(1096, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(scroll)

	if developer:
		var list := VBoxContainer.new()
		list.custom_minimum_size = Vector2(1124, 442)
		list.add_theme_constant_override("separation", 16)
		scroll.add_child(list)

		for group in _build_developer_gameplay_groups():
			list.add_child(_make_developer_gameplay_section(String(group["title_key"]), group["indexes"]))
	else:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.custom_minimum_size = Vector2(1096, 420)
		grid.add_theme_constant_override("h_separation", 22)
		grid.add_theme_constant_override("v_separation", 18)
		scroll.add_child(grid)

		for index in _active_game_indexes():
			grid.add_child(_make_game_card(index, developer))

	var back := _make_button(tr("MENU_BACK"), 30, Color("#ffef5f"))
	back.position = Vector2(460, 612)
	back.size = Vector2(360, 64)
	if developer:
		back.pressed.connect(show_developer_menu)
	else:
		back.pressed.connect(show_main_menu)
	screen.add_child(back)

func _make_game_card(game_index: int, developer: bool) -> PanelContainer:
	var unlocked := developer or _is_unlocked(game_index)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(350, 185)
	card.add_theme_stylebox_override("panel", _make_style(Color("#ffffff"), Color("#1d1d1d"), 4, 8))

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 6)
	card.add_child(stack)

	var thumb_button := TextureButton.new()
	thumb_button.custom_minimum_size = Vector2(320, 112)
	thumb_button.ignore_texture_size = true
	thumb_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(GAME_DEFS[game_index]["thumbnail"]):
		thumb_button.texture_normal = load(GAME_DEFS[game_index]["thumbnail"])
	thumb_button.modulate = Color.WHITE if unlocked else Color(0.28, 0.28, 0.28, 1.0)
	thumb_button.disabled = not unlocked
	if unlocked:
		thumb_button.pressed.connect(start_direct_game.bind(game_index, developer))
	stack.add_child(thumb_button)

	var title_text := "%d. %s" % [game_index + 1, tr(GAME_DEFS[game_index]["title_key"])]
	var title := _make_label(title_text if unlocked else "%d. ???" % [game_index + 1], 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size = Vector2(320, 32)
	stack.add_child(title)

	var status_key := "COLLECTION_PLAY" if unlocked else "COLLECTION_LOCKED"
	var status_color := Color("#176c39") if unlocked else Color("#666666")
	var status := _make_label(tr(status_key), 16, status_color, HORIZONTAL_ALIGNMENT_CENTER)
	status.custom_minimum_size = Vector2(320, 24)
	stack.add_child(status)

	return card

func _build_developer_gameplay_groups() -> Array:
	var title_to_index := {}
	for index in GAME_DEFS.size():
		if _is_game_retired(index):
			continue
		title_to_index[String(GAME_DEFS[index]["title_key"])] = index

	var pending_indexes := []
	var pending_lookup := {}
	for game_title_key in PENDING_DELETE_GAME_TITLE_KEYS:
		var key := String(game_title_key)
		if not title_to_index.has(key):
			continue
		var game_index := int(title_to_index[key])
		pending_lookup[game_index] = true
		pending_indexes.append(game_index)

	var used := {}
	var groups := []
	for group_def in DEV_GAMEPLAY_GROUPS:
		var indexes := []
		for game_title_key in group_def["game_title_keys"]:
			var key := String(game_title_key)
			if not title_to_index.has(key):
				continue

			var game_index := int(title_to_index[key])
			if used.has(game_index):
				continue
			if pending_lookup.has(game_index):
				continue

			used[game_index] = true
			indexes.append(game_index)

		if not indexes.is_empty():
			groups.append({"title_key": group_def["title_key"], "indexes": indexes})

	var other_indexes := []
	for index in _active_game_indexes():
		if not used.has(index) and not pending_lookup.has(index):
			other_indexes.append(index)

	if not other_indexes.is_empty():
		groups.append({"title_key": "GAMEPLAY_OTHER", "indexes": other_indexes})

	if not pending_indexes.is_empty():
		groups.append({"title_key": "GAMEPLAY_PENDING_DELETE", "indexes": pending_indexes})

	return groups

func _make_developer_gameplay_section(title_key: String, game_indexes: Array) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.custom_minimum_size = Vector2(1124, 0)
	section.add_theme_constant_override("separation", 8)

	var header := _make_label("%s  (%d)" % [tr(title_key), game_indexes.size()], 28, Color("#fff06a"), HORIZONTAL_ALIGNMENT_LEFT)
	header.custom_minimum_size = Vector2(1088, 38)
	header.add_theme_color_override("font_outline_color", Color("#000000"))
	header.add_theme_constant_override("outline_size", 5)
	section.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.custom_minimum_size = Vector2(1124, 0)
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	section.add_child(grid)

	for game_index in game_indexes:
		grid.add_child(_make_developer_game_button(int(game_index)))

	return section

func _make_developer_game_button(game_index: int) -> Button:
	var title_text := "%02d. %s" % [game_index + 1, tr(GAME_DEFS[game_index]["title_key"])]
	var button := _make_button(title_text, 19, Color("#fffdf8"))
	button.custom_minimum_size = Vector2(360, 48)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(start_direct_game.bind(game_index, true))
	return button

func start_game() -> void:
	current_index = 0
	wins = 0
	total_score = 0
	direct_launch = false
	direct_developer = false
	round_queue = _make_random_round_queue()
	_start_next_round()

func start_direct_game(game_index: int, developer: bool) -> void:
	if _is_game_retired(game_index):
		show_collection(developer)
		return

	current_index = 0
	wins = 0
	total_score = 0
	direct_launch = true
	direct_developer = developer
	round_queue = [game_index]
	_start_next_round()

func _start_next_round() -> void:
	if current_index >= round_queue.size():
		if direct_launch:
			show_collection(direct_developer)
			return
		show_summary()
		return

	_clear_view()
	current_screen = "game"
	_set_music_mode("game")
	_play_round_transition()
	var runner := _make_screen(Color("#151515"))
	current_view = runner

	var hud: Control = SketchPanel.new()
	hud.position = Vector2(22, 14)
	hud.size = Vector2(1236, 64)
	hud.call("configure", Color("#fffdf8"), Color("#1d1d1d"), 3.8, 1.3, false)
	runner.add_child(hud)

	var hud_box := HBoxContainer.new()
	hud_box.position = Vector2(18, 4)
	hud_box.size = Vector2(1174, 56)
	hud_box.add_theme_constant_override("separation", 22)
	hud.add_child(hud_box)

	var hud_font := SystemFont.new()
	hud_font.font_names = PackedStringArray(["Segoe Print", "Comic Sans MS", "Comic Sans", "Arial"])

	active_game_index = round_queue[current_index]
	if not direct_developer:
		_unlock_game(active_game_index)

	round_label = _make_label(tr("HUD_ROUND") % [current_index + 1, round_queue.size()], 28, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
	round_label.custom_minimum_size = Vector2(260, 56)
	round_label.add_theme_font_override("font", hud_font)
	hud_box.add_child(round_label)

	var active_def: Dictionary = GAME_DEFS[active_game_index]
	var title_column := VBoxContainer.new()
	title_column.custom_minimum_size = Vector2(600, 56)
	title_column.alignment = BoxContainer.ALIGNMENT_CENTER
	title_column.add_theme_constant_override("separation", -2)
	hud_box.add_child(title_column)

	var has_instruction := active_def.has("instruction_key")
	if has_instruction:
		var title_row := HBoxContainer.new()
		title_row.alignment = BoxContainer.ALIGNMENT_CENTER
		title_row.custom_minimum_size = Vector2(600, 34)
		title_row.add_theme_constant_override("separation", 8)
		title_column.add_child(title_row)

		var funnel: Control = SketchIcon.new()
		funnel.custom_minimum_size = Vector2(34, 34)
		funnel.call("configure", "funnel", Color("#ffe34d"), Color("#ffffff"))
		title_row.add_child(funnel)

		var name_label := _make_label(tr(active_def["title_key"]), 27, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
		name_label.custom_minimum_size = Vector2(330, 34)
		name_label.add_theme_font_override("font", hud_font)
		title_row.add_child(name_label)
	else:
		var name_label := _make_label(tr(active_def["title_key"]), 30, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
		name_label.custom_minimum_size = Vector2(600, 56)
		name_label.add_theme_font_override("font", hud_font)
		title_column.add_child(name_label)

	if has_instruction:
		if active_def.has("rich_instruction_key"):
			var subtitle_rich := RichTextLabel.new()
			subtitle_rich.bbcode_enabled = true
			subtitle_rich.text = "[center]%s[/center]" % tr(active_def["rich_instruction_key"])
			subtitle_rich.custom_minimum_size = Vector2(600, 22)
			subtitle_rich.fit_content = true
			subtitle_rich.scroll_active = false
			subtitle_rich.add_theme_font_override("normal_font", hud_font)
			subtitle_rich.add_theme_font_size_override("normal_font_size", 16)
			title_column.add_child(subtitle_rich)
		else:
			var subtitle_label := _make_label(tr(active_def["instruction_key"]), 16, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
			subtitle_label.custom_minimum_size = Vector2(600, 20)
			subtitle_label.add_theme_font_override("font", hud_font)
			title_column.add_child(subtitle_label)

	timer_label = _make_label("15.0", 36, Color("#bf2030"), HORIZONTAL_ALIGNMENT_RIGHT)
	timer_label.custom_minimum_size = Vector2(220, 56)
	timer_label.add_theme_font_override("font", hud_font)
	hud_box.add_child(timer_label)

	if has_instruction:
		var star: Control = SketchIcon.new()
		star.position = Vector2(1184, 15)
		star.size = Vector2(34, 34)
		star.call("configure", "star", Color("#ffe34d"), Color("#ffffff"))
		hud.add_child(star)

	var minigame: Control = GAME_DEFS[active_game_index]["script"].new()
	minigame.position = Vector2.ZERO
	minigame.size = Vector2(1280, 720)
	minigame.finished.connect(_on_minigame_finished)
	minigame.time_changed.connect(_on_time_changed)
	runner.add_child(minigame)
	runner.move_child(minigame, 1)

	_show_countdown(minigame)

func _show_countdown(minigame: Control) -> void:
	var generation := view_generation
	var overlay := Label.new()
	overlay.position = Vector2(0, 205)
	overlay.size = Vector2(1280, 220)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_theme_font_size_override("font_size", 112)
	overlay.add_theme_color_override("font_color", Color("#fff06a"))
	overlay.add_theme_color_override("font_outline_color", Color("#1d1d1d"))
	overlay.add_theme_constant_override("outline_size", 14)
	current_view.add_child(overlay)

	_countdown_async(overlay, minigame, generation)

func _countdown_async(overlay: Label, minigame: Control, generation: int) -> void:
	for text in ["3", "2", "1", tr("COUNTDOWN_GO")]:
		if generation != view_generation or not is_instance_valid(overlay):
			return
		overlay.text = text
		await get_tree().create_timer(0.48).timeout

	if generation != view_generation:
		return

	if is_instance_valid(overlay):
		overlay.queue_free()
	if is_instance_valid(minigame) and minigame.has_method("start_minigame"):
		minigame.start_minigame()

func _on_time_changed(time_left: float) -> void:
	if timer_label:
		timer_label.text = "%.1f" % time_left

func _on_minigame_finished(success: bool, score: int) -> void:
	if success:
		wins += 1
	total_score += score
	current_index += 1

	await get_tree().create_timer(0.8).timeout
	_start_next_round()

func show_summary() -> void:
	_clear_view()
	current_screen = "summary"
	_set_music_mode("menu")
	var screen := _make_screen(Color("#101729"))
	current_view = screen

	var title := _make_label(tr("SUMMARY_TITLE"), 66, Color("#fff06a"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, 85)
	title.size = Vector2(1280, 90)
	title.add_theme_color_override("font_outline_color", Color("#000000"))
	title.add_theme_constant_override("outline_size", 10)
	screen.add_child(title)

	var result_text := "%s\n%s" % [tr("SUMMARY_WINS") % [wins, round_queue.size()], tr("SUMMARY_POINTS") % total_score]
	var result := _make_label(result_text, 46, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	result.position = Vector2(250, 220)
	result.size = Vector2(780, 160)
	result.add_theme_color_override("font_outline_color", Color("#000000"))
	result.add_theme_constant_override("outline_size", 7)
	screen.add_child(result)

	var note := _make_label(tr("SUMMARY_NOTE"), 25, Color("#cfe8ff"), HORIZONTAL_ALIGNMENT_CENTER)
	note.position = Vector2(180, 410)
	note.size = Vector2(920, 70)
	screen.add_child(note)

	var again := _make_button(tr("SUMMARY_AGAIN"), 34, Color("#ffef5f"))
	again.position = Vector2(310, 535)
	again.size = Vector2(300, 72)
	again.pressed.connect(start_game)
	screen.add_child(again)

	var menu := _make_button(tr("SUMMARY_MENU"), 34, Color("#ff9fd6"))
	menu.position = Vector2(670, 535)
	menu.size = Vector2(300, 72)
	menu.pressed.connect(show_main_menu)
	screen.add_child(menu)

func _set_initial_locale() -> void:
	var locale := TranslationServer.get_locale().substr(0, 2)
	if not LOCALE_SEQUENCE.has(locale):
		locale = DEFAULT_LOCALE
	TranslationServer.set_locale(locale)

func _load_progress() -> void:
	unlocked_minigames.clear()
	for index in GAME_DEFS.size():
		unlocked_minigames.append(false)

	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return

	for index in GAME_DEFS.size():
		unlocked_minigames[index] = bool(config.get_value("unlocked", str(index), false))
	sound_volume = clampf(float(config.get_value("audio", "sound_volume", sound_volume)), 0.0, 1.0)

func _save_progress() -> void:
	var config := ConfigFile.new()
	for index in unlocked_minigames.size():
		config.set_value("unlocked", str(index), unlocked_minigames[index])
	config.set_value("audio", "sound_volume", sound_volume)
	config.save(SAVE_PATH)

func _unlock_game(game_index: int) -> void:
	if game_index < 0 or game_index >= unlocked_minigames.size():
		return

	if unlocked_minigames[game_index]:
		return

	unlocked_minigames[game_index] = true
	_save_progress()

func _is_unlocked(game_index: int) -> bool:
	if game_index < 0 or game_index >= unlocked_minigames.size():
		return false
	return unlocked_minigames[game_index]

func _is_game_retired(game_index: int) -> bool:
	if game_index < 0 or game_index >= GAME_DEFS.size():
		return true
	return bool(GAME_DEFS[game_index].get("retired", false))

func _active_game_indexes() -> Array[int]:
	var indexes: Array[int] = []
	for index in GAME_DEFS.size():
		if not _is_game_retired(index):
			indexes.append(index)
	return indexes

func _make_random_round_queue() -> Array[int]:
	var queue: Array[int] = []
	for index in _active_game_indexes():
		queue.append(index)
		var title_key := String(GAME_DEFS[index]["title_key"])
		var repeat_count := int(ROUND_REPEAT_COUNTS.get(title_key, 1))
		for extra in range(maxi(0, repeat_count - 1)):
			queue.append(index)
	queue.shuffle()
	return queue

func _toggle_locale() -> void:
	var locale := TranslationServer.get_locale().substr(0, 2)
	var index := LOCALE_SEQUENCE.find(locale)
	if index == -1:
		index = 0
	var next_locale: String = LOCALE_SEQUENCE[(index + 1) % LOCALE_SEQUENCE.size()]
	TranslationServer.set_locale(next_locale)
	show_main_menu()

func _language_button_text() -> String:
	var locale := TranslationServer.get_locale().substr(0, 2).to_upper()
	return "%s: %s" % [tr("MENU_LANGUAGE"), locale]

func _digit_for_key(keycode: Key) -> int:
	match keycode:
		KEY_1:
			return 1
		KEY_2:
			return 2
		KEY_3:
			return 3
		KEY_4:
			return 4
		KEY_5:
			return 5
		KEY_6:
			return 6
		KEY_7:
			return 7
		KEY_8:
			return 8
		KEY_9:
			return 9
		KEY_0:
			return 10
		_:
			return 0

func _clear_view() -> void:
	view_generation += 1
	if current_view and is_instance_valid(current_view):
		current_view.queue_free()
	current_view = null

func _build_global_sounds() -> void:
	ui_click_player = AudioStreamPlayer.new()
	ui_click_player.name = "UiClickSound"
	ui_click_player.stream = _load_audio_stream(UI_CLICK_SOUND_PATH)
	ui_click_player.volume_db = -12.0
	add_child(ui_click_player)

	round_transition_player = AudioStreamPlayer.new()
	round_transition_player.name = "RoundTransitionSound"
	round_transition_player.stream = _load_audio_stream(ROUND_TRANSITION_SOUND_PATH)
	round_transition_player.volume_db = -10.0
	add_child(round_transition_player)

	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.name = "MenuMusic"
	menu_music_player.stream = _load_audio_stream(MENU_MUSIC_PATH)
	_enable_audio_loop(menu_music_player.stream)
	menu_music_player.volume_db = -8.0
	add_child(menu_music_player)

	game_music_player = AudioStreamPlayer.new()
	game_music_player.name = "GameMusic"
	game_music_player.stream = _load_audio_stream(GAME_MUSIC_PATH)
	_enable_audio_loop(game_music_player.stream)
	game_music_player.volume_db = -10.0
	add_child(game_music_player)

	_apply_sound_volume()

func _load_audio_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _enable_audio_loop(stream: AudioStream) -> void:
	if not stream:
		return
	for property: Dictionary in stream.get_property_list():
		if String(property.get("name", "")) == "loop":
			stream.set("loop", true)
			return

func _set_music_mode(mode: String) -> void:
	if active_music_mode == mode:
		_ensure_current_music()
		return

	active_music_mode = mode
	if mode == "game":
		_stop_music(menu_music_player)
		_play_music(game_music_player)
	else:
		_stop_music(game_music_player)
		_play_music(menu_music_player)

func _ensure_current_music() -> void:
	if active_music_mode == "game":
		_play_music(game_music_player)
	else:
		_play_music(menu_music_player)

func _play_music(player: AudioStreamPlayer) -> void:
	if not player or not player.stream:
		return
	if not player.playing:
		player.play()

func _stop_music(player: AudioStreamPlayer) -> void:
	if player and player.playing:
		player.stop()

func _set_sound_volume(value: float, persist: bool = false) -> void:
	sound_volume = clampf(value, 0.0, 1.0)
	_apply_sound_volume()
	if persist:
		_save_progress()

func _apply_sound_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return
	AudioServer.set_bus_mute(master_bus, sound_volume <= 0.001)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(sound_volume, 0.001)))

func _volume_label_text() -> String:
	return "%s: %d%%" % [tr("MENU_VOLUME"), roundi(sound_volume * 100.0)]

func _add_menu_doodles(menu: Control) -> void:
	var left_spark: Control = SketchIcon.new()
	left_spark.position = Vector2(42, 174)
	left_spark.size = Vector2(62, 94)
	left_spark.call("configure", "spark", Color("#8b4cff"), Color("#ffffff"), Color("#8b4cff"))
	menu.add_child(left_spark)

	var star_a: Control = SketchIcon.new()
	star_a.position = Vector2(36, 292)
	star_a.size = Vector2(38, 38)
	star_a.call("configure", "spark", Color("#ffcf22"), Color("#ffffff"), Color("#ffcf22"))
	menu.add_child(star_a)

	var title_spark: Control = SketchIcon.new()
	title_spark.position = Vector2(822, 54)
	title_spark.size = Vector2(64, 54)
	title_spark.call("configure", "spark", Color("#42a9ff"), Color("#ffffff"), Color("#42a9ff"))
	menu.add_child(title_spark)

	var pink_mark := ColorRect.new()
	pink_mark.position = Vector2(96, 44)
	pink_mark.size = Vector2(8, 44)
	pink_mark.rotation = -0.55
	pink_mark.color = Color("#ff5fa8")
	menu.add_child(pink_mark)

	var blue_mark := ColorRect.new()
	blue_mark.position = Vector2(850, 42)
	blue_mark.size = Vector2(7, 38)
	blue_mark.rotation = 0.78
	blue_mark.color = Color("#42a9ff")
	menu.add_child(blue_mark)

func _add_menu_action_button(
		menu: Control,
		text: String,
		position: Vector2,
		fill: Color,
		icon_name: String,
		action: Callable,
		font_size: int
	) -> void:
	var button := _make_button(text, font_size, fill)
	button.position = position
	button.size = Vector2(386, 58)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(action)
	menu.add_child(button)

	var icon: Control = SketchIcon.new()
	icon.position = Vector2(18, 11)
	icon.size = Vector2(38, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.call("configure", icon_name, Color("#ffcf22") if icon_name == "plane" else fill.darkened(0.25), Color("#ffffff"))
	button.add_child(icon)

func _add_menu_computer_preview(menu: Control) -> void:
	var panel: Control = SketchPanel.new()
	panel.position = Vector2(900, 330)
	panel.size = Vector2(316, 196)
	panel.call("configure", Color("#8bc6ff"), Color("#1d5fa7"), 4.0, 1.8, true, Color("#ffffff30"))
	menu.add_child(panel)

	var cloud_a: Control = SketchIcon.new()
	cloud_a.position = Vector2(916, 390)
	cloud_a.size = Vector2(44, 44)
	cloud_a.call("configure", "spark", Color("#fffdf8"), Color("#ffffff"), Color("#ffffff"))
	menu.add_child(cloud_a)

	var computer: Control = SketchIcon.new()
	computer.position = Vector2(952, 354)
	computer.size = Vector2(190, 150)
	computer.call("configure", "computer_good", Color("#e8d9bd"), Color("#dff8da"), Color("#1d1d1d"))
	menu.add_child(computer)

	var bolt_a: Control = SketchIcon.new()
	bolt_a.position = Vector2(930, 344)
	bolt_a.size = Vector2(42, 58)
	bolt_a.call("configure", "spark", Color("#ffcf22"), Color("#ffffff"), Color("#ffcf22"))
	menu.add_child(bolt_a)

	var bolt_b: Control = SketchIcon.new()
	bolt_b.position = Vector2(1148, 346)
	bolt_b.size = Vector2(42, 58)
	bolt_b.call("configure", "spark", Color("#ffcf22"), Color("#ffffff"), Color("#ffcf22"))
	menu.add_child(bolt_b)

func _add_menu_note(menu: Control) -> void:
	var panel: Control = SketchPanel.new()
	panel.position = Vector2(28, 614)
	panel.size = Vector2(1216, 74)
	panel.call("configure", Color("#eedbff"), Color("#7445c7"), 4.0, 1.6, false)
	menu.add_child(panel)

	var star: Control = SketchIcon.new()
	star.position = Vector2(118, 628)
	star.size = Vector2(54, 48)
	star.call("configure", "star", Color("#ffdf2e"), Color("#ffffff"), Color("#111111"))
	menu.add_child(star)

	var note := _make_label(tr("MENU_NOTE"), 23, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
	note.position = Vector2(238, 622)
	note.size = Vector2(720, 58)
	menu.add_child(note)

	var trophy := _make_label("🏆", 40, Color("#ffcf22"), HORIZONTAL_ALIGNMENT_CENTER)
	trophy.position = Vector2(1064, 624)
	trophy.size = Vector2(74, 56)
	menu.add_child(trophy)

func _add_volume_control(menu: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(900, 184)
	panel.size = Vector2(316, 114)
	panel.add_theme_stylebox_override("panel", _make_style(Color("#e9f6ff"), Color("#2d72af"), 4, 12))
	menu.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	var speaker: Control = SketchIcon.new()
	speaker.custom_minimum_size = Vector2(38, 34)
	speaker.call("configure", "speaker", Color("#111111"), Color("#ffffff"), Color("#111111"))
	row.add_child(speaker)

	var label := _make_label(_volume_label_text(), 20, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_LEFT)
	label.custom_minimum_size = Vector2(226, 34)
	row.add_child(label)

	var slider := VolumeBar.new()
	slider.custom_minimum_size = Vector2(278, 38)
	slider.call("set_value", sound_volume, false)
	slider.value_changed.connect(func(value: float) -> void:
		_set_sound_volume(value, true)
		label.text = _volume_label_text()
	)
	box.add_child(slider)

func _play_ui_click() -> void:
	if not ui_click_player or not ui_click_player.stream:
		return
	ui_click_player.stop()
	ui_click_player.play()

func _play_round_transition() -> void:
	if not round_transition_player or not round_transition_player.stream:
		return
	round_transition_player.stop()
	round_transition_player.play()

func _is_primary_click(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return event.pressed
	return false

func _make_screen(color: Color) -> Control:
	var screen := Control.new()
	_set_full_rect(screen)
	add_child(screen)

	var bg := ColorRect.new()
	_set_full_rect(bg)
	bg.color = color
	screen.add_child(bg)

	return screen

func _add_menu_marks(screen: Control) -> void:
	var stripe_a := ColorRect.new()
	stripe_a.position = Vector2(-90, 542)
	stripe_a.size = Vector2(1470, 78)
	stripe_a.rotation = -0.08
	stripe_a.color = Color("#fff06a")
	screen.add_child(stripe_a)

	var stripe_b := ColorRect.new()
	stripe_b.position = Vector2(900, -42)
	stripe_b.size = Vector2(96, 780)
	stripe_b.rotation = 0.16
	stripe_b.color = Color("#ff9fd6")
	screen.add_child(stripe_b)

	var stripe_c := ColorRect.new()
	stripe_c.position = Vector2(-50, -20)
	stripe_c.size = Vector2(90, 780)
	stripe_c.rotation = -0.12
	stripe_c.color = Color("#bdfb7f")
	screen.add_child(stripe_c)

func _make_texture(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists(path):
		rect.texture = load(path)
	return rect

func _make_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_button(text: String, font_size: int, fill: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_hover_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_pressed_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_focus_color", Color("#1d1d1d"))
	button.add_theme_color_override("font_disabled_color", Color("#6b6b6b"))
	button.add_theme_color_override("font_outline_color", Color("#ffffff"))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _make_style(fill, Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.17), Color("#1d1d1d"), 4, 8))
	button.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.15), Color("#1d1d1d"), 4, 8))
	return button

func _make_style(fill: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	return style

func _set_full_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
