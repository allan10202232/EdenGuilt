extends Node
## Real E interactions verify the animation, individual oases and final world commit.

var _app: Node
var _checks := 0
var _failures := 0
var _absorbed: Dictionary = {}
var _screenshots := false


func _ready() -> void:
	_screenshots = "--screenshots" in OS.get_cmdline_user_args()
	get_tree().create_timer(50.0).timeout.connect(func() -> void:
		push_error("Extraction acceptance timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	GameText.set_language("en", false)
	_app = preload("res://scenes/main.tscn").instantiate()
	add_child(_app)
	WorldProgress.ability_absorbed.connect(func(id: StringName) -> void: _absorbed[id] = int(_absorbed.get(id, 0)) + 1)
	GameSession.start_run()
	await _physics(12)
	for path in ["oases/junkyard_oasis", "oases/mine_oasis", "oases/eden_oasis", "animations/hero_extract_actions"]:
		var texture := CampaignLevels.texture(path)
		_check(texture != null and texture.get_image().detect_alpha() != Image.ALPHA_NONE, "new artwork preserves transparency: " + path)
	await _extract_case(&"lone_tree", &"double_jump", "01-junkyard")
	GameSession.player_died()
	await _physics(2)
	GameSession.resume_checkpoint()
	await _physics(10)
	_check(_level().oases[&"double_jump"].vitality == 0.0 and WorldProgress.has_ability(&"double_jump"), "checkpoint reload preserves the depleted oasis and acquired skill")
	await _extract_case(&"grassland", &"mineralization", "02-mine")
	await _extract_case(&"remnant_sea", &"shield", "03-eden-shield")
	_check(_level().oases[&"black_pierce"].vitality == 1.0, "Eden's second oasis stays alive when its first is drained")
	await _extract_case(&"remnant_sea", &"black_pierce", "04-eden-pierce")
	var revealed := WorldProgress.reveal_truth()
	_app._truth.choice_a.pressed.emit()
	_check(revealed and WorldProgress.core_reversed, "story can continue after all extraction transactions")
	await _physics(2)
	await _tap(&"eden_return")
	_check(_level().oases[&"black_pierce"].vitality == 1.0 and not WorldProgress.has_ability(&"black_pierce"), "community repair and R restore the correct Eden oasis")
	await _at_source(&"shield")
	await _tap(&"eden_return")
	_check(_level().oases[&"shield"].vitality == 1.0, "returning the other ability restores its own oasis")
	await _capture("extraction-05-restored")
	GameSession.return_to_menu()
	await _physics(2)
	GameSession.start_run()
	await _physics(10)
	await _at_source(&"double_jump")
	await _tap(&"eden_absorb")
	_check(WorldProgress.extraction_active, "new run can begin a fresh extraction")
	GameSession.return_to_menu()
	await _physics(3)
	_check(not WorldProgress.extraction_active and not WorldProgress.has_ability(&"double_jump"), "leaving mid-action releases the guard without granting a skill")
	GameSession.start_run()
	await _physics(10)
	_check(WorldProgress.can_play() and _level().oases[&"double_jump"].vitality == 1.0, "cancelled extraction leaves the next run playable and its oasis alive")
	GameSession.return_to_menu()
	await _physics(3)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("EXTRACTION: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _extract_case(region: StringName, ability: StringName, label: String) -> void:
	if region != WorldProgress.current_scene:
		WorldProgress.enter_scene(region, Vector2(140, 596))
		await _physics(10)
	await _at_source(ability)
	var oasis: CampaignOasis = _level().oases[ability]
	_check(oasis.vitality == 1.0 and not WorldProgress.has_ability(ability), label + " begins with a living oasis")
	var supported := false
	for platform: Rect2 in _level().definition.platforms:
		if absf(platform.position.y - oasis.position.y) < 4.0 and oasis.position.x - CampaignOasis.WIDTH * 0.5 >= platform.position.x and oasis.position.x + CampaignOasis.WIDTH * 0.5 <= platform.end.x:
			supported = true
	_check(supported, label + " oasis is entirely rooted on a solid platform")
	await _capture("extraction-" + label + "-before")
	await _tap(&"eden_absorb")
	_check(WorldProgress.extraction_active and not WorldProgress.has_ability(ability), label + " E starts the action before granting a skill")
	_check(_player()._art.action == &"extract" and _player()._art.extraction_sprite.visible, label + " uses the new extraction animation")
	var position := _player().position
	var health := GameSession.health
	var score := GameSession.score
	var ledger_time := CarbonLedger.clock_seconds
	var run_time := GameSession.elapsed_seconds
	var emissions := CarbonLedger.gross_kg
	_player().hurt()
	GameSession.sync_health(0, GameSession.max_health)
	GameSession.sync_score(score + 999)
	GameSession.finish_run(false)
	_check(GameSession.state == GameSession.State.PLAYING and GameSession.health == health and GameSession.score == score, label + " external stat and death signals cannot interrupt extraction")
	_check(not WorldProgress.borrow_ability(ability) and not WorldProgress.enter_scene(&"lone_tree" if region != &"lone_tree" else &"grassland", Vector2.ZERO), "mid-action grants and scene changes are rejected")
	Input.action_press(&"eden_move_right")
	Input.action_press(&"eden_jump")
	await _physics(16)
	Input.action_release(&"eden_move_right")
	Input.action_release(&"eden_jump")
	_check(_player().position == position and GameSession.health == health, label + " movement and collision damage cannot interrupt the pose")
	_check(CarbonLedger.clock_seconds == ledger_time and GameSession.elapsed_seconds == run_time, label + " gameplay clocks pause during the action")
	await _physics(22)
	_check(_player()._art.extraction_sprite.frame == 2, label + " visibly kneels with the extractor near the ground")
	if ability == &"double_jump":
		_check(_level()._source_label.text.contains("Living oasis") and GameText.t(WorldProgress.notice).begins_with("Drawing life"), "new extraction labels and notices follow English selection")
		var vitality := oasis.vitality
		GameText.set_language("zh_CN", false)
		_check(_level()._source_label.text.contains("生命绿洲") and GameText.t(WorldProgress.notice).begins_with("正在抽取"), "active extraction labels and notices switch to Chinese")
		_check(oasis.vitality == vitality and WorldProgress.extraction_active, "changing language cannot reset the active oasis or grant its skill")
		await _capture("extraction-00-chinese")
		GameText.set_language("en", false)
	await _capture("extraction-" + label + "-kneel")
	await _physics(64)
	_check(_player()._art.extraction_sprite.frame in [3, 4] and oasis.vitality < 0.5, label + " raises the charging device as the oasis withers")
	await _capture("extraction-" + label + "-channel")
	await _wait_extraction()
	_check(WorldProgress.has_ability(ability) and oasis.vitality == 0.0, label + " commits the skill and depleted land together")
	_check(int(_absorbed.get(ability, 0)) == 1 and CarbonLedger.gross_kg == emissions, label + " grants exactly once without billing an unused skill")
	if ability == &"double_jump":
		_check(GameText.t(WorldProgress.notice).begins_with("Acquired Double Jump."), "completed extraction formats its localized ability name")
		GameText.set_language("zh_CN", false)
		_check(GameText.t(WorldProgress.notice).begins_with("获得二段跳。"), "completed extraction notice switches language without losing the ability")
		GameText.set_language("en", false)
	await _tap(&"eden_absorb")
	_check(not WorldProgress.extraction_active and int(_absorbed.get(ability, 0)) == 1, label + " spent land cannot be extracted twice")
	await _capture("extraction-" + label + "-after")


func _at_source(ability: StringName) -> void:
	var point: Vector2 = _level().definition.source if ability == _level().definition.ability else _level().definition.secondary_source
	_player().position = point + Vector2(0, 6)
	_player().velocity = Vector2.ZERO
	_player().get_node("Camera2D").reset_smoothing()
	await _physics(10)


func _wait_extraction() -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while WorldProgress.extraction_active and Time.get_ticks_msec() < deadline:
		await _physics(1)
	_check(not WorldProgress.extraction_active and WorldProgress.can_play(), "extraction finishes and releases gameplay")


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _physics(2)
	Input.action_release(action)
	await _physics(1)


func _level() -> CampaignLevel:
	return _app.get_node("LevelRoot").get_child(0) as CampaignLevel


func _player() -> CharacterBody2D:
	return _level().player


func _physics(count: int) -> void:
	for index in count:
		await get_tree().physics_frame
	await get_tree().process_frame


func _capture(label: String) -> void:
	if not _screenshots:
		return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	_check(get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/%s.png" % label) == OK, "capture " + label)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("PASS: ", label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
