extends Node
## Real player damage, hit protection, death and recovery drive the five-orb HUD.

var _app: Node
var _checks := 0
var _failures := 0
var _finished := 0
var _screenshots := false


func _ready() -> void:
	_screenshots = "--screenshots" in OS.get_cmdline_user_args()
	get_tree().create_timer(25.0).timeout.connect(func() -> void:
		push_error("Health acceptance timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	_app = preload("res://scenes/main.tscn").instantiate()
	add_child(_app)
	GameSession.run_finished.connect(func(_result: Dictionary) -> void: _finished += 1)
	GameSession.start_run()
	await _physics(12)
	_check(_orbs().get_half_count() == 10, "campaign starts with five full life orbs")
	_check(_hud().get_node("%HealthLabel").text == "生命", "health is displayed without a numeric fraction")
	await _capture("health-01-full")
	_player().hurt()
	_check(GameSession.health == 90, "one actual hit costs exactly half an orb")
	_check(_orbs().get_orb_halves(4) == 1 and _orbs().get_orb_halves(3) == 2, "rightmost orb empties before its neighbour")
	_player().hurt()
	_check(GameSession.health == 90, "multiple collisions during hit protection cannot cost extra life")
	await _capture("health-02-half")
	await _physics(54)
	_player().hurt()
	_check(GameSession.health == 80 and _orbs().get_orb_halves(4) == 0, "next hit after protection expires empties the same orb")
	await _capture("health-03-empty")
	for hit in range(3, 10):
		_player()._invulnerability = 0.0
		_player().hurt()
		_check(GameSession.health == 100 - hit * 10 and _orbs().get_half_count() == 10 - hit, "hit %d removes only one half from the HUD and real health" % hit)
		_check(GameSession.state == GameSession.State.PLAYING, "player survives hit %d" % hit)
	_check(_orbs().get_orb_halves(0) == 1 and _orbs().get_orb_halves(1) == 0, "ninth hit leaves half of the leftmost orb")
	await _capture("health-04-last-half")
	_player()._invulnerability = 0.0
	_player().hurt()
	await _physics(2)
	_check(GameSession.state == GameSession.State.GAME_OVER and _orbs().get_half_count() == 0, "tenth hit empties all five orbs and ends the run")
	_player().hurt()
	_check(_finished == 1, "collisions after death never finish the run twice")
	GameSession.resume_checkpoint()
	await _physics(12)
	_check(GameSession.state == GameSession.State.PLAYING and _orbs().get_half_count() == 10, "checkpoint recovery restores five full orbs")
	_player().hurt()
	_player()._invulnerability = 0.0
	_player().hurt()
	_player()._invulnerability = 0.0
	_player().hurt()
	_check(_orbs().get_half_count() == 7, "three hits leave three and a half orbs")
	_player().stats.heal(30)
	_check(_orbs().get_half_count() == 10, "checkpoint-sized healing restores one and a half orbs")
	await _capture("health-05-recovered")
	GameSession.return_to_menu()
	await _physics(2)
	GameSession.start_run()
	await _physics(8)
	_check(_orbs().get_half_count() == 10, "a fresh run starts with five full orbs")
	GameSession.return_to_menu()
	await _physics(2)
	SoundManager.stop_sfx()
	# The audio mixer releases stopped WAV playback on its own real-time thread.
	OS.delay_msec(150)
	print("HEALTH: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _player() -> CharacterBody2D:
	return _app.get_node("LevelRoot").get_child(0).player


func _hud() -> Control:
	return _app.get_node("UI/Root/HUD")


func _orbs() -> LifeOrbs:
	return _hud().get_node("%LifeOrbs") as LifeOrbs


func _capture(label: String) -> void:
	if not _screenshots:
		return
	await get_tree().create_timer(0.32).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	var error := get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/%s.png" % label)
	_check(error == OK, "capture " + label)


func _physics(count: int) -> void:
	for index in count:
		await get_tree().physics_frame
	await get_tree().process_frame


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("PASS: ", label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
