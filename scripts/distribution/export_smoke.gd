extends Node
## Only installed by the explicit --export-smoke-test developer flag.
## No scene overrides, editor, source project or user save data are required.
var checks := 0
var failures := 0
var app: Node

func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func() -> void:
		push_error("Standalone export validation timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()

func _run() -> void:
	check(not OS.has_feature("editor"), "running the native exported runtime")
	check(not ResourceLoader.exists("res://tests/startup_test.gd"), "development tests are excluded")
	check(not ResourceLoader.exists("res://demo_capture/eden.gd"), "demo recording helpers are excluded")
	GameText.set_language("en", false)
	var opening: Node = get_tree().current_scene
	var cinematic: Control = opening.get_node("OpeningCinematic")
	check(cinematic.assets_ready, "all four opening illustrations are embedded")
	cinematic.reveal_duration = 0.02
	cinematic.final_reveal_duration = 0.02
	cinematic.dissolve_duration = 0.02
	await ticks(12)
	await capture("01-opening")
	for passage in 8:
		await key(KEY_ENTER)
		await ticks(8)
	await ticks(24)
	app = get_tree().current_scene
	check(app.scene_file_path == "res://scenes/main.tscn", "Enter through the prologue starts the real campaign")
	if app.get_node_or_null("LevelRoot") == null:
		finish()
		return
	check(active_level() is ScrapyardParkourLevel, "chapter one loads from the embedded pack")
	check(active_level().platforms.size() > 20 and active_level().crushers.size() == 2, "scrapyard mechanisms load")
	check(hero()._art.sprite.texture != null, "hero action sprite loads")
	hero().position = Vector2(230,476)
	hero().velocity = Vector2.ZERO
	await ticks(6)
	await key(KEY_E)
	await ticks(160)
	check(WorldProgress.has_ability(&"double_jump"), "real extraction unlocks double jump")
	await key(KEY_SPACE)
	await ticks(20)
	await key(KEY_SPACE)
	check(hero().velocity.y < 0 and hero()._jumps_used == 2, "double jump input works in the standalone build")
	await ticks(80)
	await capture("02-scrapyard")
	WorldProgress.enter_scene(&"grassland", Vector2.ZERO)
	await ticks(35)
	check(active_level().get_script().resource_path.contains("mine_challenge/level"), "chapter transition loads the mine")
	check(active_level().vents.size() == 25, "mine gas systems load")
	hero().position = Vector2(420,1778)
	hero().velocity = Vector2.ZERO
	await ticks(6)
	await key(KEY_E)
	await ticks(160)
	check(WorldProgress.has_ability(&"mineralization"), "mine extraction and action resources work")
	await capture("03-mine")
	WorldProgress.enter_scene(&"remnant_sea", EdenBlueprint.ENTRY)
	await ticks(35)
	check(active_level() is EdenChapterLevel, "chapter transition loads Eden")
	check(active_level().pods.size() == 3 and active_level().sources.size() == 2, "rescue pods and ability sources load")
	await capture("04-eden-garden")
	hero().reset_at_checkpoint(Vector2(1800,1038))
	await ticks(65)
	check(hero().position.y < 1350, "processing-floor capture remains on the upper factory deck")
	await capture("05-eden-processing")
	hero().reset_at_checkpoint(Vector2(540,598))
	await ticks(65)
	check(is_instance_valid(active_level().boss), "final boss resources load")
	await capture("06-eden-heart")
	GameSession.return_to_menu()
	await ticks(12)
	GameText.set_language("zh_CN", false)
	await ticks(6)
	check(GameText.t("开始游戏") == "开始游戏", "Chinese localization is available offline")
	await capture("07-menu-chinese")
	GameText.set_language("en", false)
	await ticks(6)
	check(GameText.t("开始游戏") != "开始游戏", "English localization is available offline")
	await capture("08-menu-english")
	SoundManager.stop_sfx()
	await ticks(8)
	finish()

func active_level() -> Node:
	return app.get_node("LevelRoot").get_child(0)

func hero() -> CharacterBody2D:
	return active_level().player

func ticks(count: int) -> void:
	for frame in count:
		await get_tree().physics_frame
	while WorldProgress.scene_transition_active or WorldProgress.transition_rearm_seconds > 0:
		await get_tree().physics_frame
	await get_tree().process_frame

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await ticks(1)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://export-smoke")
	check(get_viewport().get_texture().get_image().save_png("user://export-smoke/" + label + ".png") == OK, "rendered " + label)

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + message)

func finish() -> void:
	print("STANDALONE EXPORT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
