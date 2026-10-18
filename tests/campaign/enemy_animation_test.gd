extends Node
## Verify animation against actual physics, projectile and damage events.
var app: Node
var checks := 0
var failures := 0


func _ready() -> void:
	get_tree().create_timer(40).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()


func _run() -> void:
	GameText.set_language("zh_CN",false)
	app = preload("res://scenes/main.tscn").instantiate()
	# Historical horizontal Eden fixture; production four-floor Eden has its own route suite.
	app.eden_scene=preload("res://tests/fixtures/legacy_eden_room.tscn")
	# Isolate enemy animation against the campaign combat controller; production
	# mine parkour uses its own player and is exercised by mine_challenge_test.
	app.mine_scene=preload("res://tests/fixtures/legacy_mineralization_room.tscn")
	add_child(app)
	await _ticks(4)
	GameSession.start_run()
	await _ticks(25)
	WorldProgress.enter_scene(&"grassland",Vector2(140,596))
	await _ticks(10)
	var level: CampaignLevel = app.get_node("LevelRoot").get_child(0)
	var player: CharacterBody2D = level.player
	for other: CampaignEnemy in level.enemies:
		other.set_physics_process(false)
	player.position = Vector2(850, 596)
	player.set_physics_process(false)
	for species in ["scrap_scavenger", "crystal_miner", "forest_crawler", "eden_warden"]:
		var sheet: Texture2D = load("res://assets/art/generated/animations/%s_actions.png" % species)
		var art := sheet.get_image()
		_check(art.get_width() >= 1530 and art.get_height() == 1024, species+" has a six by four action sheet")
		var complete := art.get_pixel(0, 0).a == 0.0
		for index in 24:
			var x := int(index % 6 * art.get_width() / 6.0)
			var cell := art.get_region(Rect2i(x, int(index / 6.0)*256, int(art.get_width()/6.0), 256))
			complete = complete and cell.get_used_rect().size.x > 32 and cell.get_used_rect().size.y > 32
		_check(complete, species+" contains all poses with real transparency")
	var enemy := _spawn(level, player, false, "scrap_scavenger")
	enemy._attack_cooldown = 100.0
	enemy._direction = 1.0
	var frames: Dictionary = {}
	for index in 55:
		await _ticks(1)
		if enemy._actions.pose == &"walk": frames[enemy._skin.frame] = true
	_check(frames.size() == 6, "patrolling articulates all six walking poses")
	enemy._direction = -1.0
	await _ticks(2)
	_check(enemy._skin.flip_h, "left movement faces left")
	var shots := [0]
	enemy.projectile_fired.connect(func(_origin: Vector2, _direction: float) -> void: shots[0] += 1)
	enemy._windup = 0.55
	var anticipation: Dictionary = {}
	var strikes: Dictionary = {}
	for index in 56:
		await _ticks(1)
		if enemy._actions.pose == &"windup":
			anticipation[enemy._skin.frame] = true
			if index == 15:
				_check(shots[0] == 0, "projectile waits for anticipation")
		if enemy._actions.pose == &"strike": strikes[enemy._skin.frame] = true
	_check(anticipation.size() == 3 and strikes.size() == 4, "three anticipation poses lead to four strike/recovery poses")
	_check(shots[0] == 1, "one attack animation emits exactly one projectile")
	WorldProgress.narrative_active = true
	var frozen_frame := enemy._skin.frame
	var frozen_position := enemy.position
	await _ticks(15)
	_check(enemy._skin.frame == frozen_frame and enemy.position == frozen_position, "story pauses AI and animation together")
	WorldProgress.narrative_active = false
	var ghost := enemy._actions
	var location := ghost.global_position
	var score := GameSession.score
	enemy.receive_melee_hit({"damage":1})
	await _ticks(2)
	_check(not is_instance_valid(enemy) and ghost.pose == &"death", "death removes collision actor immediately and leaves a visual corpse")
	_check(ghost.global_position.distance_to(location) < 0.1, "detached death stays at the original location")
	_check(GameSession.score == score+50, "death awards score once")
	WorldProgress.narrative_active = true
	await _ticks(45)
	_check(not is_instance_valid(ghost), "death visual cleans up even during story pause")
	WorldProgress.narrative_active = false
	var boss := _spawn(level, player, true, "forest_crawler")
	boss.position = Vector2(600, 576)
	boss.patrol = Vector2(580, 660)
	boss._attack_cooldown = 100.0
	player.position = Vector2(740, 596)
	await _ticks(10)
	_check(boss._skin.texture.resource_path.ends_with("eden_warden_actions.png"), "guardian uses its own armored warden art")
	boss.receive_melee_hit({"damage":1})
	await _ticks(2)
	_check(boss._actions.pose == &"hurt" and boss.health == 5, "surviving hit plays recoil without extra damage")
	await _ticks(20)
	boss._windup = 0.75
	player._invulnerability = 0.0
	var before: int = GameSession.health
	await _ticks(30)
	_check(GameSession.health == before and boss._actions.pose == &"windup", "guardian telegraph does not inflict early damage")
	await _ticks(17)
	_check(GameSession.health == before-10 and boss._actions.pose == &"strike", "guardian impact animation removes half an orb with real damage")
	_check(boss._recovery > 0.0 and is_zero_approx(boss.velocity.x), "guardian plants its feet while recovering")
	boss.queue_free()
	var crawler := _spawn(level, player, false, "forest_crawler")
	crawler._hop_cooldown = 0.0
	await _ticks(3)
	_check(crawler._actions.pose == &"crouch" and crawler.is_on_floor(), "crawler crouches before pouncing")
	await _ticks(10)
	_check(crawler._actions.pose == &"jump" and crawler.velocity.y < 0.0, "pounce leaves the ground after anticipation")
	crawler.queue_free()
	GameSession.return_to_menu()
	await _ticks(4)
	SoundManager.stop_sfx()
	await _ticks(10)
	OS.delay_msec(150)
	print("ENEMY_ACTIONS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _spawn(level: CampaignLevel, player: CharacterBody2D, boss: bool, species: String) -> CampaignEnemy:
	var enemy := CampaignEnemy.new()
	enemy.boss = boss
	enemy.kind = species
	enemy.persistent_id = StringName("animation/"+species)
	enemy.position = Vector2(500, 600)
	enemy.patrol = Vector2(300, 800)
	enemy.player = player
	level.add_child(enemy)
	return enemy


func _ticks(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: "+label)
