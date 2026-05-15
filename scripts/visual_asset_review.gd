extends SceneTree

const ThreadOfDoom := preload("res://scripts/minigames/thread_of_doom.gd")
const LicenseMaze := preload("res://scripts/minigames/license_maze.gd")
const TokenVacuum := preload("res://scripts/minigames/token_vacuum.gd")
const WakePet := preload("res://scripts/minigames/wake_pet.gd")
const RamenLocal := preload("res://scripts/minigames/prompt_injection_sushi.gd")
const EnvLeakPanic := preload("res://scripts/minigames/env_leak_panic.gd")
const MainScript := preload("res://scripts/main.gd")

const OUT_DIR := "I:/vibecoding/wariowave/wario-wave-ai/visual_review"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await _capture_main_menu()
	await _capture_ramen()
	await _capture_env_leak()
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
	image.save_png("%s/%s" % [OUT_DIR, file_name])
