extends Node
## Real scene/UI/physics acceptance checks. No editor addon or test dependency.

var _failures: int = 0
var _checks: int = 0
var _app: Node
var _finished_count: int = 0


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(func() -> void:
		push_error("Acceptance test timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	_app = preload("res://scenes/main.tscn").instantiate()
	add_child(_app)
	GameSession.run_finished.connect(func(_result: Dictionary) -> void: _finished_count += 1)
	await _frames(3)
	_check(GameSession.state == GameSession.State.MAIN_MENU, "starts at main menu")
	_check(_menu().visible and not _hud().visible and not _result().visible, "initial UI visibility")
	await _capture("01-main-menu")
	await _click(_menu().get_node("%StartButton"))
	_check(GameSession.state == GameSession.State.PLAYING, "start button enters level")
	if GameSession.state != GameSession.State.PLAYING:
		get_tree().quit(1)
		return
	_check(_app.get_node("LevelRoot").get_child_count() == 1, "exactly one level instance")
	_check(_hud().visible and not _menu().visible, "HUD shown in gameplay")
	var level: Node = _level()
	var player: CharacterBody2D = level.get_node("Player")
	var stats: PlaceholderStats = player.get_node("Stats")
	await _physics_frames(24)
	_check(player.is_on_floor(), "placeholder actor lands on side-view floor")
	var start_x := player.position.x
	Input.action_press(&"eden_move_right")
	await _physics_frames(12)
	Input.action_release(&"eden_move_right")
	_check(player.position.x > start_x + 20.0, "horizontal movement works")
	Input.action_press(&"eden_jump")
	await _physics_frames(2)
	Input.action_release(&"eden_jump")
	_check(player.velocity.y < 0.0, "jump has upward velocity")
	stats.take_damage(25)
	_check(GameSession.health == 75, "A-style health signal reaches session")
	_check(_hud().get_node("%HealthBar").value == 75.0, "health bar updates synchronously")
	_check("75 / 100" in _hud().get_node("%HealthLabel").text, "health text updates")
	stats.heal(10)
	_check(GameSession.health == 85, "healing is reflected")
	stats.add_score(150)
	_check(GameSession.score == 150 and "0150" in _hud().get_node("%ScoreLabel").text, "score signal updates HUD")
	await _capture("02-gameplay")
	# Use actual Area2D overlap, not direct callbacks, to verify pickup integration.
	player.position = Vector2(380, 470)
	player.velocity = Vector2.ZERO
	await _physics_frames(4)
	_check(GameSession.score == 250, "pickup collision adds 100 points")
	await _physics_frames(3)
	_check(GameSession.score == 250, "a shard scores only once")
	player.position = Vector2(540, 580)
	player.velocity = Vector2.ZERO
	await _physics_frames(8)
	_check(GameSession.health == 60, "spike collision damages actor and HUD")
	stats.take_damage(1000)
	_check(GameSession.state == GameSession.State.GAME_OVER, "zero health opens game over")
	_check(_result().visible, "death dialog visible")
	_check(_hud().get_node("%MenuButton").disabled, "result modal disables background buttons")
	_check(_finished_count == 1, "health zero plus died emits one terminal result")
	await _frames(2)
	_check(level.process_mode == Node.PROCESS_MODE_DISABLED, "finished level stops simulation")
	var finished_score := GameSession.score
	GameSession.sync_score(9999)
	GameSession.complete_level()
	_check(GameSession.state == GameSession.State.GAME_OVER and GameSession.score == finished_score, "late events cannot change result")
	await _capture("03-game-over")
	await _click(_result().get_node("%RestartButton"))
	_check(GameSession.state == GameSession.State.PLAYING, "restart button enters fresh level")
	_check(GameSession.health == 100 and GameSession.score == 0, "restart resets health and score")
	_check(GameSession.last_result.is_empty(), "restart clears terminal snapshot")
	_check(_app.get_node("LevelRoot").get_child_count() == 1 and _level() != level, "restart replaces old level")
	_check(not _hud().get_node("%MenuButton").disabled, "restart restores HUD interaction")
	# The test room's first elevated platform must be reachable using real input.
	player = _level().get_node("Player")
	player.position = Vector2(240, 596)
	player.velocity = Vector2.ZERO
	await _physics_frames(3)
	Input.action_press(&"eden_move_right")
	Input.action_press(&"eden_jump")
	await _physics_frames(30)
	Input.action_release(&"eden_jump")
	Input.action_release(&"eden_move_right")
	await _physics_frames(10)
	_check(player.is_on_floor() and player.position.y < 500.0, "jump reaches elevated platform")
	# Data source replacement must disconnect the old A-style emitter.
	var bridge: GameplayBridge = _level().get_node("GameplayBridge")
	var replacement := PlaceholderStats.new()
	replacement.max_health = 160
	add_child(replacement)
	replacement.add_score(75)
	_check(bridge.bind_source(replacement), "bridge accepts external A-style source")
	_check(GameSession.health == 160 and GameSession.max_health == 160 and GameSession.score == 75, "bind reads initial snapshot")
	_level().get_node("Player/Stats").take_damage(50)
	_check(GameSession.health == 160, "rebind disconnects old source")
	replacement.take_damage(40)
	_check(_hud().get_node("%HealthBar").max_value == 160.0 and _hud().get_node("%HealthBar").value == 120.0, "non-default max health is bound")
	bridge.unbind_source()
	replacement.take_damage(20)
	_check(GameSession.health == 120, "unbind stops updates")
	replacement.queue_free()
	bridge.bind_source(_level().get_node("Player/Stats"))
	# Physical exit overlap exercises victory rather than calling finish directly.
	player = _level().get_node("Player")
	player.position = Vector2(2530, 575)
	player.velocity = Vector2.ZERO
	await _physics_frames(5)
	_check(GameSession.state == GameSession.State.VICTORY, "exit collision opens victory")
	_check(_result().visible and "VICTORY" in _result().get_node("%Subtitle").text, "victory content shown")
	_check(_finished_count == 2, "one result for victory")
	await _capture("04-victory")
	await _click(_result().get_node("%RestartButton"))
	_check(GameSession.state == GameSession.State.PLAYING and GameSession.health == 100, "victory also supports restart")
	player = _level().get_node("Player")
	player.position = Vector2(900, 850)
	await _physics_frames(3)
	_check(GameSession.state == GameSession.State.GAME_OVER, "falling into abyss triggers death")
	await _click(_result().get_node("%MenuButton"))
	_check(GameSession.state == GameSession.State.MAIN_MENU and _menu().visible, "result can return to menu")
	_check(_app.get_node("LevelRoot").get_child_count() == 0, "menu releases level")
	await _click(_menu().get_node("%MuteButton"))
	_check(SoundManager.muted, "mute button toggles audio")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "SFX bus mute applied")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")), "music bus mute applied")
	await _click(_menu().get_node("%StartButton"))
	_check("关闭" in _hud().get_node("%MuteButton").text, "audio state survives scene flow")
	await _click(_hud().get_node("%MuteButton"))
	_check(not SoundManager.muted, "HUD can unmute")
	await _click(_hud().get_node("%MenuButton"))
	_check(GameSession.state == GameSession.State.MAIN_MENU, "HUD menu button works")
	_check(SoundManager.has_sound(&"pickup") and SoundManager.play_sfx(&"pickup"), "registered sound plays")
	_check(not SoundManager.play_sfx(&"unregistered"), "missing audio safely returns false")
	var stream := AudioStreamWAV.new()
	SoundManager.register_sound(&"custom", stream)
	_check(SoundManager.has_sound(&"custom"), "custom audio can replace placeholders")
	SoundManager.play_music(stream)
	_check(SoundManager.get_node("MusicPlayer").stream == stream, "BGM interface accepts stream")
	SoundManager.stop_music()
	_check(SoundManager.get_node("MusicPlayer").stream == null, "BGM stop clears stream")
	SoundManager.set_music_volume(0.5)
	SoundManager.set_sfx_volume(0.5)
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"SFX")), 0.5), "volume setter applies to bus")
	SoundManager.stop_sfx()
	# Let the audio thread release stopped playbacks before the process exits.
	await get_tree().create_timer(0.15).timeout
	print("PHASE_ONE: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", label)
	else:
		_failures += 1
		push_error("FAIL: " + label)


func _click(button: Button) -> void:
	await _frames(2)
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await _frames(1)
	await _frames(2)


func _frames(count: int) -> void:
	for _index in count:
		await get_tree().process_frame


func _physics_frames(count: int) -> void:
	for _index in count:
		await get_tree().physics_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	await _frames(3)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	var error := get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/%s.png" % label)
	_check(error == OK, "capture " + label)


func _level() -> Node:
	return _app.get_node("LevelRoot").get_child(0)


func _menu() -> Control:
	return _app.get_node("UI/Root/MainMenu")


func _hud() -> Control:
	return _app.get_node("UI/Root/HUD")


func _result() -> Control:
	return _app.get_node("UI/Root/ResultDialog")
