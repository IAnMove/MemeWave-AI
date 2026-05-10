extends SceneTree

const MainScript := preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var probe := Node.new()
	root.add_child(probe)

	TranslationServer.set_locale("es")
	if probe.tr("MENU_START") != "EMPEZAR":
		_fail("Spanish translation failed for MENU_START")
		return

	TranslationServer.set_locale("en")
	if probe.tr("MENU_START") != "START":
		_fail("English translation failed for MENU_START")
		return

	TranslationServer.set_locale("es")
	if probe.tr("REPO_SUCCESS") != "ESTO YA NO ES OPEN!":
		_fail("Spanish translation failed for REPO_SUCCESS")
		return

	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame

	var game_defs: Array = main.get("GAME_DEFS")
	for game_def_variant in game_defs:
		var game_def: Dictionary = game_def_variant
		for key_name in ["title_key", "description_key", "instruction_key", "rich_instruction_key"]:
			if not game_def.has(key_name):
				continue
			var key := String(game_def[key_name])
			_assert_translated(probe, key, "es")
			_assert_translated(probe, key, "en")

	main.queue_free()
	probe.queue_free()
	await process_frame

	print("Localization test passed: es/en translations resolve for catalog metadata.")
	quit()

func _assert_translated(probe: Node, key: String, locale: String) -> void:
	TranslationServer.set_locale(locale)
	var translated := probe.tr(key)
	if translated == key or translated.strip_edges() == "":
		_fail("Missing %s translation for %s" % [locale, key])

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
