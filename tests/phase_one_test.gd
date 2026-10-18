extends Node
## End-to-end B acceptance: real UI input, scene exits, progression and checkpoint reload.

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
	_app.campaign_mode = false
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
	_check(WorldProgress.current_scene == &"lone_tree" and WorldProgress.checkpoint_name() == "垃圾场", "initial scene checkpoint")
	_check(not WorldProgress.has_ability(&"double_jump") and not WorldProgress.has_ability(&"light_blade"), "abilities start unavailable")
	await _physics_frames(24)
	_check(_player().is_on_floor(), "placeholder actor lands on floor")
	var start_x := _player().position.x
	Input.action_press(&"eden_move_right")
	await _physics_frames(12)
	Input.action_release(&"eden_move_right")
	_check(_player().position.x > start_x + 20.0, "horizontal movement works")
	await _action(&"eden_jump")
	_check(_player().velocity.y < 0.0, "jump has upward velocity")
	_player().hurt()
	_check(GameSession.health == 90 and _hud().get_node("%LifeOrbs").get_half_count() == 9, "one hit removes half a life orb")
	_check(_hud().get_node("%HealthLabel").text == "生命", "health label has no numeric fraction")
	_stats().heal(10)
	_stats().add_score(150)
	_check(GameSession.health == 100 and "0150" in _hud().get_node("%ScoreLabel").text, "heal and score signals update")
	await _at_source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"double_jump"), "E absorbs double jump in lone tree")
	_check(WorldProgress.land_state(&"lone_tree") == &"wasted", "absorption wastes source land")
	_check("可用" in _hud().get_node("%DoubleJump").text, "ability HUD follows absorption")
	_check(not WorldProgress.borrow_ability(&"double_jump"), "cannot absorb twice")
	_check(not WorldProgress.borrow_ability(&"dash"), "cannot absorb at wrong region")
	await _physics_frames(8)
	await _action(&"eden_jump")
	_player().velocity.y = 100.0
	await _action(&"eden_jump")
	_check(_player().velocity.y < 0.0, "borrowed double jump allows one extra air jump")
	_player().velocity.y = 100.0
	await _action(&"eden_jump")
	_check(_player().velocity.y > 0.0, "third jump is rejected")
	await _action(&"eden_trial_blade")
	_check(WorldProgress.has_ability(&"light_blade"), "F1 explicitly trials pending-location light blade")
	await _teleport(Vector2(680, 596))
	await _action(&"eden_move_right")
	await _world_click(Vector2(700, 450))
	await _physics_frames(8)
	_check(WorldProgress.is_enemy_defeated(&"lone_tree/mob_0"), "one mouse slash defeats placeholder mob")
	_check(not WorldProgress.mark_enemy_defeated(&"lone_tree/mob_0"), "same mob cannot be defeated twice")
	await _teleport(Vector2(380, 470))
	_check(GameSession.score == 250, "physical shard pickup adds 100")
	await _physics_frames(4)
	_check(GameSession.score == 250, "shard scores only once")
	await _capture("02-gameplay")
	await _teleport(Vector2(540, 580))
	_check(GameSession.health == 90, "spike collision removes exactly half an orb")
	_stats().take_damage(1000)
	await _frames(2)
	_check(GameSession.state == GameSession.State.GAME_OVER and _result().visible, "zero health opens death dialog")
	_check(_finished_count == 1, "health zero and died signal finish only once")
	_check(_hud().get_node("%MenuButton").disabled, "death modal disables background buttons")
	_check(_level().process_mode == Node.PROCESS_MODE_DISABLED, "finished level stops simulation")
	GameSession.sync_score(9999)
	GameSession.complete_level()
	_check(GameSession.score == 250 and GameSession.state == GameSession.State.GAME_OVER, "late events cannot replace result")
	_check(not WorldProgress.borrow_ability(&"shield"), "progression is locked while dead")
	await _capture("03-game-over")
	await _click(_result().get_node("%CheckpointButton"))
	_check(GameSession.state == GameSession.State.PLAYING and GameSession.health == 100, "checkpoint button revives at full health")
	_check(GameSession.score == 250 and WorldProgress.has_ability(&"double_jump"), "checkpoint preserves score and abilities")
	_check(not _level().has_node("Mob") and not _level().has_node("Shard0"), "checkpoint does not respawn killed mob or collected shard")
	_check(not _hud().get_node("%MenuButton").disabled, "resume restores HUD interaction")
	_check(GameSession.last_result.is_empty(), "resume clears terminal snapshot")
	await _test_bridge()
	WorldProgress.scene_requested.connect(_test_transition_guard, CONNECT_ONE_SHOT)
	await _teleport(Vector2(2530, 575))
	_check(WorldProgress.current_scene == &"grassland", "right exit changes to grassland")
	_check(WorldProgress.checkpoint_name() == "毒雾矿场" and _level().region_id == &"grassland", "scene entry updates checkpoint and scene together")
	_check(GameSession.score == 250 and GameSession.health == 100, "scene change preserves stat source data")
	_check(_app.get_node("LevelRoot").get_child_count() == 1, "scene replacement leaves exactly one active level")
	_check(not WorldProgress.return_ability(&"double_jump") and WorldProgress.has_ability(&"double_jump"), "ability cannot be returned in another region")
	await _at_source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"dash") and WorldProgress.land_state(&"grassland") == &"wasted", "grassland absorbs dash and becomes wasted")
	await _action(&"eden_run")
	_check(absf(_player().velocity.x) > 500.0, "borrowed dash has placeholder motion")
	GameSession.player_died(&"fall")
	await _click(_result().get_node("%CheckpointButton"))
	_check(WorldProgress.current_scene == &"grassland" and _player().position.x < 130.0, "death restores latest scene entry position")
	_check(WorldProgress.has_ability(&"dash") and WorldProgress.is_enemy_defeated(&"lone_tree/mob_0"), "death retains acquired abilities and defeated history")
	await _teleport(Vector2(2530, 575))
	_check(WorldProgress.current_scene == &"remnant_sea" and WorldProgress.checkpoint_name() == "伊甸园", "second exit updates checkpoint to remnant sea")
	await _at_source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"shield"), "remnant sea absorbs shield")
	Input.action_press(&"eden_shield")
	await _physics_frames(3)
	var before := GameSession.health
	_player().hurt()
	_check(WorldProgress.shield_active and GameSession.health == before, "active shield blocks placeholder damage")
	_check("防御中" in _hud().get_node("%Shield").text, "HUD indicates active shield")
	Input.action_release(&"eden_shield")
	await _physics_frames(3)
	_player().hurt()
	_check(not WorldProgress.shield_active and GameSession.health == before - 10, "shield release restores half-orb damage")
	await _teleport(Vector2(2530, 575))
	_check(WorldProgress.returning and "返程" in _hud().get_node("%RegionLabel").text, "far end starts return journey")
	await _at_source(&"eden_return")
	_check(not WorldProgress.has_ability(&"shield") and WorldProgress.route_open(&"shield"), "shield return opens protective route before removing ability")
	_check(WorldProgress.land_state(&"remnant_sea") == &"restored", "shield return restores source environment")
	await _action(&"eden_shield")
	_check(not WorldProgress.shield_active, "returned shield cannot be activated")
	await _teleport(Vector2(540, 580))
	_check(GameSession.health == before - 10, "restored sea barrier protects route from spikes")
	_check(not WorldProgress.return_ability(&"light_blade") and WorldProgress.has_ability(&"light_blade"), "light blade return requires escape route confirmation")
	WorldProgress.set_light_blade_escape_ready(true)
	_check(WorldProgress.return_ability(&"light_blade") and not WorldProgress.report_ability_used(&"light_blade"), "safe blade return removes attack capability")
	await _teleport(Vector2(680, 596))
	await _action(&"eden_move_right")
	await _world_click(Vector2(700, 450))
	await _physics_frames(8)
	_check(not WorldProgress.is_enemy_defeated(&"remnant_sea/mob_0"), "returned blade no longer defeats mobs on mouse click")
	await _capture("05-return-route")
	GameSession.player_died()
	await _click(_result().get_node("%CheckpointButton"))
	_check(WorldProgress.ability_state(&"shield") == WorldProgress.AbilityState.RETURNED and WorldProgress.route_open(&"shield"), "checkpoint preserves returned ability and protective route")
	_check(not WorldProgress.has_ability(&"light_blade") and WorldProgress.returning, "checkpoint preserves weapon return and journey phase")
	await _teleport(Vector2(40, 575))
	_check(WorldProgress.current_scene == &"grassland" and _player().position.x > 2400.0, "left exit returns to previous region from its right entrance")
	await _at_source(&"eden_return")
	_check(WorldProgress.route_open(&"dash") and not WorldProgress.has_ability(&"dash"), "grassland return replaces dash with walkable route")
	_check(not WorldProgress.borrow_ability(&"dash"), "returned abilities cannot be reabsorbed")
	Input.action_press(&"eden_move_right")
	Input.action_press(&"eden_run")
	await _physics_frames(2)
	var run_speed := absf(_player().velocity.x)
	Input.action_release(&"eden_run")
	Input.action_release(&"eden_move_right")
	_check(run_speed > 270.0 and run_speed < 500.0, "returning dash preserves basic fast run without dash boost")
	await _teleport(Vector2(900, 580))
	await _physics_frames(24)
	_check(_player().is_on_floor() and GameSession.state == GameSession.State.PLAYING, "returned route has physical walkable bridge")
	await _teleport(Vector2(40, 575))
	_check(WorldProgress.current_scene == &"lone_tree" and not _level().has_node("Mob"), "revisit still does not respawn defeated mob")
	await _at_source(&"eden_return")
	_check(WorldProgress.route_open(&"double_jump") and WorldProgress.required_returns_complete(), "lone tree return completes required returns")
	_check("已交还" in _hud().get_node("%DoubleJump").text, "HUD indicates returned ability")
	_check(not WorldProgress.report_ability_used(&"double_jump"), "returned double jump cannot be used")
	await _physics_frames(8)
	await _action(&"eden_jump")
	_player().velocity.y = 100.0
	await _action(&"eden_jump")
	_check(_player().velocity.y > 0.0, "returned double jump rejects second air jump")
	await _teleport(Vector2(40, 575))
	_check(GameSession.state == GameSession.State.VICTORY and _result().visible, "return home exit opens victory")
	_check("VICTORY" in _result().get_node("%Subtitle").text, "victory content shown")
	_check(not _result().get_node("%CheckpointButton").visible, "victory offers new run rather than checkpoint revival")
	await _capture("04-victory")
	await _click(_result().get_node("%RestartButton"))
	_check(GameSession.health == 100 and GameSession.score == 0 and WorldProgress.current_scene == &"lone_tree", "new run resets stats and scene")
	_check(not WorldProgress.has_ability(&"double_jump") and not WorldProgress.route_open(&"double_jump"), "new run resets abilities and routes")
	_check(not WorldProgress.is_enemy_defeated(&"lone_tree/mob_0") and not WorldProgress.is_collected(&"lone_tree/shard_0"), "new run resets one-shot world flags")
	_check(_level().has_node("Mob") and _level().has_node("Shard0"), "new run restores mob and collectibles")
	await _teleport(Vector2(900, 850))
	_check(GameSession.state == GameSession.State.GAME_OVER and GameSession.last_result.death_reason == &"fall", "actual abyss fall routes to checkpoint death")
	await _click(_result().get_node("%MenuButton"))
	_check(GameSession.state == GameSession.State.MAIN_MENU and _menu().visible, "death result can return to menu")
	_check(_app.get_node("LevelRoot").get_child_count() == 0, "menu releases level")
	await _test_audio()
	SoundManager.stop_sfx()
	await get_tree().create_timer(0.15).timeout
	print("PHASE_ONE: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_transition_guard(_scene_id: StringName) -> void:
	var previous_health := GameSession.health
	var previous_score := GameSession.score
	GameSession.sync_health(0, 100)
	GameSession.sync_score(9999)
	GameSession.player_died(&"fall")
	_check(GameSession.state == GameSession.State.PLAYING and GameSession.health == previous_health and GameSession.score == previous_score, "scene transition rejects stale death and stat signals")
	_check(not WorldProgress.enter_scene(&"remnant_sea", Vector2.ZERO), "scene transition rejects overlapping scene request")


func _test_bridge() -> void:
	var bridge: GameplayBridge = _level().get_node("GameplayBridge")
	var replacement := PlaceholderStats.new()
	replacement.max_health = 160
	add_child(replacement)
	replacement.add_score(75)
	_check(bridge.bind_source(replacement), "bridge accepts external A-style source")
	_check(GameSession.health == 160 and GameSession.score == 75, "bridge reads source snapshot")
	_stats().take_damage(50)
	_check(GameSession.health == 160, "rebind disconnects old source")
	replacement.take_damage(40)
	_check(_hud().get_node("%LifeOrbs").max_value == 160.0 and _hud().get_node("%LifeOrbs").value == 120.0, "life orbs bind changed maximum health")
	bridge.unbind_source()
	replacement.take_damage(20)
	_check(GameSession.health == 120, "unbind stops updates")
	replacement.queue_free()
	_stats().restore_stats({"health": 100, "max_health": 100, "score": 250})
	bridge.bind_source(_stats())


func _test_audio() -> void:
	await _click(_menu().get_node("%MuteButton"))
	_check(SoundManager.muted and AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "mute applies to SFX bus")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")), "mute applies to music bus")
	await _click(_menu().get_node("%StartButton"))
	_check("关闭" in _hud().get_node("%MuteButton").text, "audio state survives scene flow")
	await _click(_hud().get_node("%MuteButton"))
	_check(not SoundManager.muted, "HUD can unmute")
	await _click(_hud().get_node("%MenuButton"))
	_check(GameSession.state == GameSession.State.MAIN_MENU, "HUD menu button works")
	for id: StringName in [&"pickup", &"absorb", &"return", &"double_jump", &"dash", &"shield", &"slash", &"enemy_down", &"checkpoint"]:
		_check(SoundManager.has_sound(id) and SoundManager.play_sfx(id), "registered sound: " + id)
	_check(not SoundManager.play_sfx(&"unregistered"), "missing audio safely returns false")
	var stream := AudioStreamWAV.new()
	SoundManager.register_sound(&"custom", stream)
	_check(SoundManager.has_sound(&"custom"), "custom stream registration")
	SoundManager.play_music(stream)
	_check(SoundManager.get_node("MusicPlayer").stream == stream, "BGM accepts stream")
	SoundManager.stop_music()
	_check(SoundManager.get_node("MusicPlayer").stream == null, "BGM stop clears stream")
	SoundManager.set_music_volume(0.5)
	SoundManager.set_sfx_volume(0.5)
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"SFX")), 0.5), "volume setter applies to bus")


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", label)
	else:
		_failures += 1
		push_error("FAIL: " + label)


func _click(button: Button) -> void:
	await _frames(2)
	await _world_click(button.get_global_rect().get_center())


func _world_click(point: Vector2) -> void:
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
	await _frames(3)


func _action(action: StringName) -> void:
	Input.action_press(action)
	await _physics_frames(2)
	Input.action_release(action)
	await _physics_frames(1)


func _teleport(point: Vector2) -> void:
	_player().position = point
	_player().velocity = Vector2.ZERO
	await _physics_frames(6)


func _at_source(action: StringName) -> void:
	await _teleport(Vector2(220, 580))
	await _action(action)


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


func _player() -> CharacterBody2D:
	return _level().get_node("Player")


func _stats() -> PlaceholderStats:
	return _player().get_node("Stats")


func _menu() -> Control:
	return _app.get_node("UI/Root/MainMenu")


func _hud() -> Control:
	return _app.get_node("UI/Root/HUD")


func _result() -> Control:
	return _app.get_node("UI/Root/ResultDialog")
