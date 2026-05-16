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
	if probe.tr("QUICK_PROGRESS") != "Progreso":
		_fail("Spanish translation failed for QUICK_PROGRESS")
		return
	if probe.tr("HUD_SCORE") != "Puntos: %d":
		_fail("Spanish translation failed for HUD_SCORE")
		return
	if probe.tr("SUMMARY_PERFORMANCE") != "Rendimiento: %d%%":
		_fail("Spanish translation failed for SUMMARY_PERFORMANCE")
		return
	if probe.tr("SUMMARY_GOOD_TITLE") != "Unicornio MemeWave":
		_fail("Spanish translation failed for SUMMARY_GOOD_TITLE")
		return

	var main: Control = MainScript.new()
	root.add_child(main)
	await process_frame
	if TranslationServer.get_locale().substr(0, 2) != "en":
		_fail("Game should default to English on startup.")
		return

	var game_defs: Array = main.get("GAME_DEFS")
	for game_def_variant in game_defs:
		var game_def: Dictionary = game_def_variant
		for key_name in ["title_key", "description_key", "instruction_key", "rich_instruction_key"]:
			if not game_def.has(key_name):
				continue
			var key := String(game_def[key_name])
			_assert_translated(probe, key, "es")
			_assert_translated(probe, key, "en")

	for key in [
		"HUD_SCORE",
		"SUMMARY_PERFORMANCE",
		"SUMMARY_BAD_TITLE",
		"SUMMARY_BAD_RANK",
		"SUMMARY_BAD_BODY",
		"SUMMARY_MEDIUM_TITLE",
		"SUMMARY_MEDIUM_RANK",
		"SUMMARY_MEDIUM_BODY",
		"SUMMARY_GOOD_TITLE",
		"SUMMARY_GOOD_RANK",
		"SUMMARY_GOOD_BODY",
		"GAMEPLAY_JAM_OPENING",
		"GAMEPLAY_JAM_GOOD",
		"GAMEPLAY_JAM_MID",
		"GAMEPLAY_JAM_LOW"
	]:
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
