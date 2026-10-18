extends Node
## Test actual loaded campaign scenes, physics combat, travel and persistent return paths.

var _app: Node
var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func() -> void:
		push_error("Campaign acceptance timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	_app = preload("res://scenes/main.tscn").instantiate()
	add_child(_app)
	await _frames(4)
	await _capture("campaign-00-menu")
	_app.get_node("UI/Root/MainMenu/%StartButton").pressed.emit()
	await _frames(5)
	await _physics(24)
	_check(_level() is CampaignLevel and _level().region_id==&"lone_tree","menu starts forest campaign by default")
	_check(_player().is_on_floor(),"campaign spawn lands on authored collision floor")
	_check(_player().campaign_character and not _player().get_node("Body").visible,"artist character replaces placeholder polygon")
	_check(WorldProgress.has_ability(&"light_blade"),"campaign provides starting melee weapon")
	for id in ["characters/hero_red","characters/hero_green","enemies/forest_crawler","enemies/scrap_scavenger","enemies/crystal_miner"]:
		var art:=CampaignLevels.texture(id)
		_check(art!=null and art.get_image().detect_alpha()!=Image.ALPHA_NONE,"transparent game art: "+id)
	for id in ["forest","junkyard","mine"]:
		_check(CampaignLevels.texture("backgrounds/"+id)!=null,"background imported: "+id)
	_check(CampaignLevels.texture("terrain/biome_atlas")!=null,"three biome terrain atlas imported")
	_check(_level().enemies.size()==5 and _level().definition.width>=3800,"forest has authored encounters and scrolling space")
	await _capture("campaign-forest-entry")
	await _teleport(Vector2(350,445))
	_check(WorldProgress.is_collected(&"lone_tree/shard_0") and GameSession.score==100,"optional elevated shard updates HUD and persistence")
	await _source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"double_jump"),"forest source grants double jump with E")
	await _physics(3)
	_check(_level()._gate.get_child(0).disabled,"forest ability gate opens")
	await _source(&"eden_return")
	_check(WorldProgress.has_ability(&"double_jump"),"cannot discard traversal ability before rescue")
	await _teleport(Vector2(590,596))
	var victim: CampaignEnemy=_level().enemies[0]
	victim.position=Vector2(655,596)
	victim.set_physics_process(false)
	_player().face_direction(1)
	_check(_player().combat.try_close(1.0),"close melee can begin in campaign")
	await _physics(18)
	_check(WorldProgress.is_enemy_defeated(&"lone_tree/mob_0") and GameSession.score==150,"physical melee hit kills forest enemy once and awards score")
	await _teleport(Vector2(880,596))
	Input.action_press(&"eden_move_right")
	await _action(&"eden_jump")
	await _physics(21)
	await _action(&"eden_jump")
	await _physics(56)
	Input.action_release(&"eden_move_right")
	await _physics(10)
	_check(_player().position.x>1208 and _player().position.y<510 and _player().is_on_floor(),"double jump crosses forest ravine onto raised landing")
	await _teleport(Vector2(2355,596))
	Input.action_press(&"eden_move_right")
	await _action(&"eden_jump")
	await _physics(21)
	await _action(&"eden_jump")
	await _physics(65)
	Input.action_release(&"eden_move_right")
	await _physics(8)
	_check(_player().position.x>2715 and _player().is_on_floor(),"forest far ravine is reachable before obtaining dash")
	await _teleport(Vector2(1320,476))
	_check(WorldProgress.checkpoint_name()=="森林 · 02","internal lamp sets named checkpoint")
	var score_before:=GameSession.score
	_player().stats.take_damage(100)
	await _frames(4)
	_check(GameSession.state==GameSession.State.GAME_OVER,"campaign death opens result dialog")
	GameSession.resume_checkpoint()
	await _frames(5)
	await _physics(8)
	_check(GameSession.health==100 and GameSession.score==score_before,"checkpoint restores health and preserves score")
	_check(_player().position.distance_to(Vector2(1320,476))<8 and _level().enemies.size()==4,"checkpoint restores position and keeps slain enemies absent")
	_check(WorldProgress.is_collected(&"lone_tree/shard_0") and WorldProgress.has_ability(&"double_jump"),"death preserves discoveries and abilities")
	await _teleport(Vector2(2050,596))
	await _capture("campaign-01-forest")
	await _exit()
	_check(_level().region_id==&"grassland","forest exit loads junkyard")
	_check(_level().enemies.size()==6 and _level().hazards.size()==2,"junkyard contains mechanical encounters and timed arcs")
	await _source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"dash"),"junkyard source grants dash")
	await _teleport(Vector2(1000,596))
	await _action(&"eden_run")
	_check(_player()._dash_remaining>0 and absf(_player().velocity.x)>700,"Shift starts fast dash")
	var health_before:=GameSession.health
	_player().hurt(20)
	_check(GameSession.health==health_before,"active dash grants hazard immunity")
	Input.action_press(&"eden_move_right")
	await _action(&"eden_jump")
	await _physics(12)
	Input.action_release(&"eden_move_right")
	await _physics(45)
	await _teleport(Vector2(1170,596))
	Input.action_press(&"eden_move_right")
	await _action(&"eden_run",true)
	await _action(&"eden_jump")
	await _physics(52)
	Input.action_release(&"eden_run")
	Input.action_release(&"eden_move_right")
	await _physics(6)
	_check(_player().position.x>1454 and _player().is_on_floor(),"dash jump crosses junkyard scrap gap")
	await _teleport(Vector2(1550,596))
	var mech: CampaignEnemy=_level().enemies[0]
	mech.position=Vector2(1810,596)
	mech.patrol=Vector2(1700,1850)
	mech._attack_cooldown=0.0
	await _physics(2)
	_check(mech._windup>0.0,"mechanical enemy telegraphs ranged shot")
	await _physics(35)
	var has_projectile:=false
	for child in _level().get_children():
		if child.get_script()==preload("res://scripts/campaign/projectile.gd"):
			has_projectile=true
	_check(has_projectile,"mechanical enemy spawns live projectile")
	await _teleport(Vector2(1960,596))
	_level().hazards[0]._clock=1.7
	await _capture("campaign-02-junkyard")
	await _exit()
	_check(_level().region_id==&"remnant_sea" and _level().definition.width==4400.0,"junkyard exit loads full mine map")
	await _source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"shield"),"mine source grants shield")
	await _teleport(Vector2(970,596))
	Input.action_press(&"eden_move_right")
	await _action(&"eden_jump")
	await _physics(21)
	await _action(&"eden_jump")
	await _physics(68)
	Input.action_release(&"eden_move_right")
	await _physics(8)
	_check(_player().position.x>1295 and _player().is_on_floor(),"retained double jump crosses mine entry gap")
	await _teleport(Vector2(1635,596))
	_player()._invulnerability=0.0
	var beam: CampaignHazard=_level().hazards[0]
	beam._clock=2.3
	await _action(&"eden_shield",true)
	health_before=GameSession.health
	await _physics(12)
	_check(WorldProgress.shield_active and GameSession.health==health_before,"held shield blocks active mine steam")
	Input.action_release(&"eden_shield")
	await _physics(2)
	health_before=GameSession.health
	beam._clock=2.3
	_player()._invulnerability=0.0
	await _physics(3)
	_check(GameSession.health==health_before-20,"unshielded steam damages player")
	await _teleport(Vector2(2215,596))
	Input.action_press(&"eden_move_right")
	await _action(&"eden_jump")
	await _physics(19)
	await _action(&"eden_jump")
	await _physics(32)
	Input.action_release(&"eden_move_right")
	await _physics(12)
	_check(_player().position.x>2460 and _player().position.y<540,"mine ascent is reachable with retained double jump")
	await _exit()
	_check(not WorldProgress.returning,"mine rescue stays locked while boss lives")
	await _teleport(Vector2(3670,596))
	var boss: CampaignEnemy=_level().enemies[-1]
	_check(boss.boss and boss.health==6,"mine ends with six-hit guardian")
	boss.set_physics_process(false)
	boss.position=Vector2(3810,576)
	await _physics(3)
	await _capture("campaign-03-mine-boss")
	for index in 6:
		await _physics(42)
		if is_instance_valid(boss):
			boss.position=Vector2(3810,576)
		_check(_player().combat.try_reach(1.0),"reach attack accepted for boss hit %d"%(index+1))
		await _physics(40)
	_check(WorldProgress.is_enemy_defeated(&"remnant_sea/boss"),"reach melee defeats guardian through real hurtbox")
	await _capture("campaign-03-mine")
	await _exit()
	_check(WorldProgress.returning and _level()._companions.size()==3,"rescue starts return journey with three followers")
	_check(_player()._art.texture==CampaignLevels.trimmed_texture("characters/hero_green"),"rescue changes hero to green artist form")
	Input.action_press(&"eden_move_left")
	await _physics(70)
	Input.action_release(&"eden_move_left")
	_check(_level()._companions[0].distance_to(_player().position)>30.0 and _level()._companions[0].distance_to(_level()._companions[2])>50.0,"rescued companions follow in spaced chain")
	await _capture("campaign-return-companions")
	await _source(&"eden_return")
	await _physics(4)
	_check(WorldProgress.route_open(&"shield") and not WorldProgress.has_ability(&"shield"),"returning shield removes skill and opens safe mine route")
	_check(_level()._route_platforms.size()==2 and _level().hazards[0].phase()==0,"mine return installs bridges and disables steam")
	await _entrance()
	_check(_level().region_id==&"grassland","mine entrance backtracks to junkyard")
	await _source(&"eden_return")
	await _physics(4)
	_check(_level()._route_platforms.size()==1 and _level()._route_ramps.size()==1 and not WorldProgress.has_ability(&"dash"),"junkyard return replaces dash gap with bridge and ramp")
	await _entrance()
	_check(_level().region_id==&"lone_tree","junkyard entrance backtracks to forest")
	await _source(&"eden_return")
	await _physics(4)
	_check(WorldProgress.required_returns_complete() and not WorldProgress.has_ability(&"double_jump"),"all three traversal gifts returned")
	_check(_level()._route_platforms.size()==1 and _level()._route_ramps.size()==1,"forest removes double-jump dependency on return")
	await _teleport(Vector2(1240,476))
	Input.action_press(&"eden_move_left")
	await _physics(95)
	Input.action_release(&"eden_move_left")
	_check(_player().position.x<850 and _player().position.y<650,"forest restored ramp traverses without double jump")
	await _entrance()
	_check(GameSession.state==GameSession.State.VICTORY,"returning home completes the three-level campaign")
	await _capture("campaign-04-victory")
	GameSession.start_run()
	await _frames(5)
	_check(not WorldProgress.returning and not WorldProgress.is_enemy_defeated(&"remnant_sea/boss") and GameSession.score==0,"new run resets campaign, enemies and score")
	GameSession.return_to_menu()
	await _frames(4)
	print("CAMPAIGN: %d checks, %d failures"%[_checks,_failures])
	get_tree().quit(0 if _failures==0 else 1)


func _level() -> CampaignLevel:
	return _app.get_node("LevelRoot").get_child(0) as CampaignLevel


func _player() -> CharacterBody2D:
	return _level().player


func _source(action: StringName) -> void:
	await _teleport(_level().definition.source+Vector2(0,6))
	await _action(action)


func _exit() -> void:
	await _teleport(_level().definition.exit)
	await _frames(5)


func _entrance() -> void:
	await _teleport(Vector2(36,570))
	await _frames(5)


func _teleport(point: Vector2) -> void:
	_player().position=point
	_player().velocity=Vector2.ZERO
	await _physics(6)


func _action(action: StringName,held: bool=false) -> void:
	Input.action_press(action)
	await _physics(2)
	if not held:
		Input.action_release(action)
		await _physics(1)


func _physics(count: int) -> void:
	for index in count:
		await get_tree().physics_frame
	await get_tree().process_frame


func _frames(count: int) -> void:
	for index in count:
		await get_tree().process_frame


func _check(condition: bool,label: String) -> void:
	_checks+=1
	if condition:
		print("PASS: ",label)
	else:
		_failures+=1
		push_error("FAIL: "+label)


func _capture(label: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	await _frames(4)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	_check(get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/"+label+".png")==OK,"capture "+label)
