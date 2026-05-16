extends SceneTree

const ThreadOfDoom := preload("res://scripts/minigames/thread_of_doom.gd")
const LicenseMaze := preload("res://scripts/minigames/license_maze.gd")
const TokenVacuum := preload("res://scripts/minigames/token_vacuum.gd")
const WakePet := preload("res://scripts/minigames/wake_pet.gd")
const RamenLocal := preload("res://scripts/minigames/prompt_injection_sushi.gd")
const EnvLeakPanic := preload("res://scripts/minigames/env_leak_panic.gd")
const VramHotSwap := preload("res://scripts/minigames/vram_hot_swap.gd")
const BenchmarkArena := preload("res://scripts/minigames/benchmark_arena.gd")
const EnergyLinks := preload("res://scripts/minigames/energy_links.gd")
const GpuSacrificeRitual := preload("res://scripts/minigames/gpu_sacrifice_ritual.gd")
const ContextTetris := preload("res://scripts/minigames/context_tetris.gd")
const MainScript := preload("res://scripts/main.gd")

const OUT_DIR := "res://visual_review"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _capture_main_menu()
	await _capture_ramen()
	await _capture_env_leak()
	await _capture_env_leak_result()
	await _capture_vram_hot_swap()
	await _capture_benchmark_arena()
	await _capture_energy_links()
	await _capture_gpu_ritual()
	await _capture_satellite_alignment()
	await _capture_thread()
	await _capture_license()
	await _capture_downgrade()
	await _capture_plug_server()
	print("Visual asset review captures saved.")
	quit()

func _capture_main_menu() -> void:
	var main := MainScript.new()
	root.add_child(main)
	await process_frame
	await process_frame
	_save_capture("main_menu.png")
	main.queue_free()
	await process_frame

func _capture_ramen() -> void:
	var game := RamenLocal.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_spawn_plate", "ram")
	game.call("_spawn_plate", "gpu")
	game.call("_spawn_plate", "chrome")
	await process_frame
	await process_frame
	_save_capture("ramen_local.png")
	game.queue_free()
	await process_frame

func _capture_env_leak() -> void:
	var game := EnvLeakPanic.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	await process_frame
	_save_capture("env_leak_panic.png")
	game.queue_free()
	await process_frame

func _capture_env_leak_result() -> void:
	var game := EnvLeakPanic.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_force_cover_all_leaks")
	await process_frame
	await process_frame
	_save_capture("env_leak_result.png")
	game.queue_free()
	await process_frame

func _capture_vram_hot_swap() -> void:
	var game := VramHotSwap.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_on_model_button_pressed", "whisper")
	await process_frame
	await process_frame
	_save_capture("vram_hot_swap.png")
	game.queue_free()
	await process_frame

func _capture_benchmark_arena() -> void:
	var game := BenchmarkArena.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	await process_frame
	_save_capture("benchmark_arena.png")
	game.queue_free()
	await process_frame

func _capture_energy_links() -> void:
	var game := EnergyLinks.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	await process_frame
	_save_capture("energy_links.png")
	game.queue_free()
	await process_frame

func _capture_gpu_ritual() -> void:
	var game := GpuSacrificeRitual.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	await process_frame
	_save_capture("gpu_ritual.png")
	game.queue_free()
	await process_frame

func _capture_satellite_alignment() -> void:
	var game := ContextTetris.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	await process_frame
	_save_capture("satellite_alignment.png")
	game.queue_free()
	await process_frame

func _capture_thread() -> void:
	var game := ThreadOfDoom.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	await process_frame
	_save_capture("tab_panic.png")
	game.queue_free()
	await process_frame

func _capture_license() -> void:
	var game := LicenseMaze.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	await process_frame
	await process_frame
	_save_capture("license_maze.png")
	game.queue_free()
	await process_frame

func _capture_downgrade() -> void:
	var game := TokenVacuum.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_force_usage", 82.0)
	for _index in range(12):
		game.call("_spawn_user", false)
	await process_frame
	await process_frame
	_save_capture("downgrade_crisis.png")
	game.queue_free()
	await process_frame

func _capture_plug_server() -> void:
	var game := WakePet.new()
	root.add_child(game)
	await process_frame
	game.start_minigame()
	game.call("_connect_plug")
	await process_frame
	await process_frame
	_save_capture("plug_server_on.png")
	game.queue_free()
	await process_frame

func _save_capture(file_name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUT_DIR, file_name]))
