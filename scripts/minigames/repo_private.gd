extends "res://scripts/minigames/base_minigame.gd"

const TARGET_REPOS := 8
const ELON_ANGRY_PATH := "res://assets/sprites/elon_face.png"

var private_count := 0
var face_sprite: TextureRect
var speech_label: Label

func _ready() -> void:
	configure(
		"GAME_REPO_TITLE",
		"REPO_INSTRUCTIONS",
		"GAME_REPO_DESC",
		"res://assets/art/repo_private_bg.png"
	)
	super._ready()
	_build_repos()

func start_minigame() -> void:
	super.start_minigame()
	private_count = 0
	_show_sam()
	set_status(tr("REPO_STATUS") % [0, TARGET_REPOS])
	for child in content_layer.get_children():
		if child is TextureButton and child.name == "RepoButton":
			child.disabled = false
			if ResourceLoader.exists("res://assets/sprites/repo_open.png"):
				child.texture_normal = load("res://assets/sprites/repo_open.png")

func _build_repos() -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(118, 222)
	grid.size = Vector2(660, 360)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	content_layer.add_child(grid)

	for index in TARGET_REPOS:
		var repo := make_sprite_button("res://assets/sprites/repo_open.png", Vector2(150, 150))
		repo.name = "RepoButton"
		repo.custom_minimum_size = Vector2(150, 150)
		if ResourceLoader.exists("res://assets/sprites/repo_locked.png"):
			repo.texture_disabled = load("res://assets/sprites/repo_locked.png")
		repo.pressed.connect(_on_repo_pressed.bind(repo))
		grid.add_child(repo)

	var face_panel := PanelContainer.new()
	face_panel.position = Vector2(845, 215)
	face_panel.size = Vector2(300, 330)
	face_panel.add_theme_stylebox_override("panel", make_style(Color("#ffffff"), Color("#1d1d1d"), 5, 6))
	content_layer.add_child(face_panel)

	var face_box := VBoxContainer.new()
	face_box.alignment = BoxContainer.ALIGNMENT_CENTER
	face_box.add_theme_constant_override("separation", 8)
	face_panel.add_child(face_box)

	face_sprite = TextureRect.new()
	face_sprite.custom_minimum_size = Vector2(260, 230)
	face_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	face_box.add_child(face_sprite)

	speech_label = make_label(tr("REPO_SAM_SPEECH"), 25, Color("#1d1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	speech_label.custom_minimum_size = Vector2(260, 72)
	face_box.add_child(speech_label)
	_show_sam()

func _on_repo_pressed(button: TextureButton) -> void:
	if not running or button.disabled:
		return

	button.disabled = true
	private_count += 1
	score = private_count
	set_status(tr("REPO_STATUS") % [private_count, TARGET_REPOS])

	if private_count >= TARGET_REPOS:
		_show_elon()
		await finish_with_result(true, "REPO_SUCCESS", 0.85)

func on_timeout() -> void:
	await finish_with_result(false, "REPO_FAIL", 0.4)

func _show_sam() -> void:
	if face_sprite and ResourceLoader.exists("res://assets/sprites/sam_face.png"):
		face_sprite.texture = load("res://assets/sprites/sam_face.png")
	if speech_label:
		speech_label.text = tr("REPO_SAM_SPEECH")

func _show_elon() -> void:
	if face_sprite and ResourceLoader.exists(ELON_ANGRY_PATH):
		face_sprite.texture = load(ELON_ANGRY_PATH)
	if speech_label:
		speech_label.text = tr("REPO_ELON_SPEECH")
