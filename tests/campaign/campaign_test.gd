extends Node
## Actual skills, physics, climate feedback, moral choice and exported audit UI.

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
	_app=preload("res://scenes/main.tscn").instantiate()
	add_child(_app)
	await _frames(4)
	await _capture("carbon-00-menu")
	await _click(_app.get_node("UI/Root/MainMenu/%StartButton"))
	await _physics(24)
	_check(_level().definition.title=="垃圾场" and CarbonLedger.enabled,"main menu starts in junkyard with ledger enabled")
	_check(_player().is_on_floor() and _player().campaign_character,"artist character lands at junkyard home")
	_check(CarbonLedger.gross_kg==0.0 and WorldProgress.has_ability(&"light_blade"),"learning weapon and spawning do not fabricate carbon costs")
	for path in ["backgrounds/junkyard","backgrounds/mine","backgrounds/eden_garden","terrain/biome_atlas"]:
		_check(CampaignLevels.texture(path)!=null,"game asset imported: "+path)
	await _capture("carbon-01-junkyard")
	await _teleport(Vector2(350,445))
	_check(WorldProgress.is_collected(&"lone_tree/shard_0") and GameSession.score==100,"optional upper branch contains real collectible")
	await _source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"double_jump") and CarbonLedger.gross_kg==0.0,"E learns double jump without charging until used")
	await _source(&"eden_return")
	_check(WorldProgress.has_ability(&"double_jump"),"cannot unload before truth and reversal")
	await _teleport(Vector2(590,596))
	var victim: CampaignEnemy=_level().enemies[0]
	victim.position=Vector2(655,596)
	victim.set_physics_process(false)
	_player().face_direction(1)
	_check(_player().combat.try_close(1.0),"campaign close melee is accepted")
	var attack_carbon:=CarbonLedger.gross_kg
	_check(not _player().combat.try_reach(1.0) and CarbonLedger.gross_kg==attack_carbon,"shared recovery rejects alternate attack without emission charge")
	await _physics(18)
	_check(WorldProgress.is_enemy_defeated(&"lone_tree/mob_0") and GameSession.score==150,"real melee defeats mechanical junkyard enemy and awards score")
	await _teleport(Vector2(880,596))
	var before:=CarbonLedger.gross_kg
	Input.action_press(&"eden_move_right")
	await _action(&"eden_jump")
	_check(CarbonLedger.gross_kg==before,"ordinary first jump is carbon free")
	await _physics(21)
	await _action(&"eden_jump")
	_check(is_equal_approx(CarbonLedger.gross_kg-before,5.0),"only actual air jump adds exactly 5 kg")
	await _physics(56)
	Input.action_release(&"eden_move_right")
	await _physics(10)
	_check(_player().position.x>1208 and _player().is_on_floor(),"double jump reaches junkyard raised landing")
	await _teleport(Vector2(1100,650))
	await _physics(10)
	before=CarbonLedger.gross_kg
	await _action(&"eden_jump")
	_check(is_equal_approx(CarbonLedger.gross_kg-before,5.0),"expired ledge grace cannot disguise an air jump as a carbon-free ground jump")
	await _teleport(Vector2(1320,476))
	_check(WorldProgress.checkpoint_name()=="垃圾场 · 02","internal checkpoint has current scene name")
	before=CarbonLedger.gross_kg
	_player().stats.take_damage(100)
	await _frames(4)
	_check(GameSession.state==GameSession.State.GAME_OVER,"death opens checkpoint modal")
	GameSession.resume_checkpoint()
	await _frames(5)
	await _physics(8)
	_check(GameSession.health==100 and CarbonLedger.gross_kg==before,"checkpoint restores health without carbon rollback")
	_check(_player().position.distance_to(Vector2(1320,476))<8 and _level().enemies.size()==4,"checkpoint keeps position and defeated enemy history")
	await _teleport(Vector2(1500,470))
	await _action(&"eden_recycle")
	_check(CarbonLedger.recycled_nodes==1,"V circular dismantling records material recovery")
	await _action(&"eden_recycle")
	_check(CarbonLedger.recycled_nodes==1,"same scrap cannot be credited twice")
	await _exit()
	_check(_level().definition.title=="毒雾矿场","junkyard exit enters toxic mine")
	await _source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"mineralization") and not WorldProgress.has_ability(&"dash"),"mine teaches carbon mineralization instead of legacy dash")
	await _teleport(Vector2(1150,596))
	before=CarbonLedger.gross_kg
	await _action(&"eden_mineralize")
	_check(is_equal_approx(CarbonLedger.gross_kg-before,1.0),"successful C mineralization charges 1 kg")
	_check(CarbonLedger.stored_kg==15.0 and _level()._mineral_platforms.size()==1,"mineral node stores separate carbon and creates solid bridge")
	before=CarbonLedger.gross_kg
	_check(not _player().try_mineralize() and CarbonLedger.gross_kg==before,"mineralization recovery cannot be spammed or double credited")
	Input.action_press(&"eden_move_right")
	await _physics(70)
	Input.action_release(&"eden_move_right")
	_check(_player().position.x>1440 and _player().is_on_floor(),"mineral bridge physically crosses toxic mine gap")
	await _teleport(Vector2(1825,596))
	_player()._invulnerability=0.0
	var hazard: CampaignHazard=_level().hazards[0]
	hazard._clock=2.3
	var health_before:=GameSession.health
	await _physics(3)
	_check(GameSession.health==health_before-10,"unprocessed toxic vent removes half a life orb")
	_player()._mineral_recovery=0.0
	await _action(&"eden_mineralize")
	_check(hazard.neutralized and hazard.phase()==0,"mineralization converts local toxic hazard to safe crystal")
	await _capture("carbon-02-toxic-mine")
	await _exit()
	_check(_level().definition.title=="伊甸园","mine exit enters apparently pristine Eden")
	await _source(&"eden_absorb")
	_check(WorldProgress.has_ability(&"shield"),"Eden primary source teaches shield")
	await _teleport(_level().definition.secondary_source+Vector2(0,6))
	await _action(&"eden_absorb")
	_check(WorldProgress.has_ability(&"black_pierce"),"Eden secondary source teaches black pierce")
	var spawn_query:=PhysicsShapeQueryParameters2D.new()
	spawn_query.shape=_player().get_node("Collision").shape
	spawn_query.collision_mask=16
	var safe_checkpoints:=true
	for point: Vector2 in _level().definition.checkpoints:
		spawn_query.transform=Transform2D(0,point)
		safe_checkpoints=safe_checkpoints and _player().get_world_2d().direct_space_state.intersect_shape(spawn_query).is_empty()
	_check(safe_checkpoints,"all Eden checkpoint spawn volumes are outside special walls")
	await _teleport(Vector2(1635,596))
	before=CarbonLedger.gross_kg
	await _action(&"eden_shield",true)
	_check(is_equal_approx(CarbonLedger.gross_kg-before,20.0),"shield activation charges exactly 20 kg")
	_player()._invulnerability=0.0
	health_before=GameSession.health
	_player().hurt()
	_check(GameSession.health==health_before and WorldProgress.shield_active,"shield still blocks damage")
	await _physics(89)
	_check(not WorldProgress.shield_active and is_equal_approx(CarbonLedger.gross_kg-before,20.0),"holding key cannot create endless shield or repeated frame costs")
	Input.action_release(&"eden_shield")
	await _physics(60)
	await _action(&"eden_shield",true)
	Input.action_release(&"eden_shield")
	await _physics(2)
	before=CarbonLedger.gross_kg
	await _action(&"eden_shield",true)
	_check(not WorldProgress.shield_active and CarbonLedger.gross_kg==before,"release and re-press during shield cooldown cannot reactivate a free shield")
	Input.action_release(&"eden_shield")
	await _teleport(Vector2(3390,596))
	var wall_target: CampaignEnemy=_level().enemies[0]
	var original_position:=wall_target.position
	wall_target.position=Vector2(3560,596)
	wall_target.set_physics_process(false)
	_player().combat.try_reach(1.0)
	await _physics(35)
	_check(is_instance_valid(wall_target) and wall_target.health==1,"special dark wall blocks ordinary melee before black pierce")
	if is_instance_valid(wall_target):
		wall_target.position=original_position
		wall_target.set_physics_process(true)
	await _teleport(Vector2(3460,596))
	_player().face_direction(1)
	before=CarbonLedger.gross_kg
	await _action(&"eden_black_pierce")
	_check(_player().position.x>3542 and _player().collision_mask==17,"F passes special dark wall and restores normal collision mask")
	_check(is_equal_approx(CarbonLedger.gross_kg-before,200.0),"successful black pierce charges 200 kg")
	_check(CarbonLedger.climate_stage()>=1,"first black pierce creates haze after separately credited mineral storage")
	before=CarbonLedger.gross_kg
	_check(not _player().try_black_pierce() and CarbonLedger.gross_kg==before,"cooldown rejects repeated black pierce without cost")
	await _capture("carbon-03-eden-haze")
	var wall: StaticBody2D=_level()._add_platform(Rect2(4000,350,20,300))
	await _teleport(Vector2(3940,596))
	_player()._pierce_recovery=0.0
	_player().face_direction(1)
	_check(_player().try_black_pierce() and _player().position.x<3987,"ordinary terrain blocks black pierce")
	_check(CarbonLedger.climate_stage()>=2 and _level().enemies[0].is_enraged(),"additional high footprint triggers enemy frenzy in real scene")
	wall.queue_free()
	await _physics(3)
	await _exit()
	_check(not WorldProgress.truth_revealed,"truth archive remains locked until guardian defeated")
	await _teleport(Vector2(3670,596))
	var boss: CampaignEnemy=_level().enemies[-1]
	boss.position=Vector2(3810,576)
	boss._attack_cooldown=0
	_player()._invulnerability=0
	health_before=GameSession.health
	await _physics(3)
	_check(boss._windup>0,"live guardian AI telegraphs its attack")
	await _physics(48)
	_check(GameSession.health==health_before-10,"live guardian strike removes half a life orb")
	_player().stats.heal(100)
	_player()._invulnerability=0
	boss._attack_cooldown=0
	await _physics(3)
	health_before=GameSession.health
	await _action(&"eden_jump")
	await _physics(18)
	await _action(&"eden_jump")
	await _physics(30)
	_check(GameSession.health==health_before,"actual double jump evades guardian attack height")
	await _teleport(Vector2(3670,596))
	boss.set_physics_process(false)
	boss.position=Vector2(3810,576)
	await _physics(3)
	await _capture("carbon-eden-guardian")
	for index in 6:
		await _physics(42)
		if is_instance_valid(boss): boss.position=Vector2(3810,576)
		_check(_player().combat.try_reach(1.0),"reach melee guardian hit %d"%(index+1))
		await _physics(40)
	_check(WorldProgress.is_enemy_defeated(&"remnant_sea/boss"),"guardian is defeated through real hurtbox")
	await _exit()
	_check(WorldProgress.narrative_active and _app._truth.visible,"truth archive opens A/B dialogue")
	var actor_position:=_player().position
	var seconds:=GameSession.elapsed_seconds
	Input.action_press(&"eden_move_left")
	await _physics(10)
	Input.action_release(&"eden_move_left")
	_check(_player().position==actor_position and GameSession.elapsed_seconds==seconds,"moral choice freezes gameplay and timer")
	await _capture("carbon-04-truth-choice")
	await _click(_app._truth.choice_a)
	_check(WorldProgress.core_reversed and WorldProgress.returning and CarbonLedger.rescued_people==3,"actual A button reverses core and rescues residents")
	_check(_player()._art.green_form and _player()._art.sprite.texture==HeroActionVisual.GREEN,"A choice is green transformation point")
	await _action(&"eden_return")
	await _physics(4)
	_check(WorldProgress.repaired_regions.has(&"remnant_sea") and _level()._dark_bodies[0].get_child(0).disabled,"rescued residents open public return route at archive without another costly black pierce")
	for vent: CampaignHazard in _level().hazards: vent._clock=2.3-vent.offset
	_check(_level().hazards.all(func(vent: CampaignHazard) -> bool: return vent.neutralized and vent.phase()==0),"archive community repair neutralizes vents before shield is unloaded")
	await _teleport(Vector2(2000,596))
	_player()._invulnerability=0
	health_before=GameSession.health
	await _physics(4)
	_check(GameSession.health==health_before,"community-repaired spikes cannot damage the return journey")
	before=CarbonLedger.gross_kg
	await _source(&"eden_return")
	await _teleport(_level().definition.secondary_source+Vector2(0,6))
	await _action(&"eden_return")
	await _physics(4)
	_check(not WorldProgress.has_ability(&"shield") and not WorldProgress.has_ability(&"black_pierce"),"community repairs Eden and unloads both skills")
	_check(_level()._route_platforms.size()==2 and _level()._dark_bodies[0].get_child(0).disabled,"community bridges and removes dark wall before return")
	_check(CarbonLedger.gross_kg==before and CarbonLedger.restored_regions==1,"community work preserves gross emissions and records repair")
	await _capture("carbon-05-eden-restored")
	await _entrance()
	await _source(&"eden_return")
	await _physics(4)
	_check(WorldProgress.route_open(&"mineralization") and _level().hazards[1].phase()==0,"mine community route works after losing mineralization")
	await _entrance()
	await _source(&"eden_return")
	await _physics(4)
	_check(WorldProgress.required_returns_complete() and CarbonLedger.restored_regions==3,"four skills returned through three repaired regions")
	await _teleport(Vector2(1240,476))
	Input.action_press(&"eden_move_left")
	await _physics(95)
	Input.action_release(&"eden_move_left")
	_check(_player().position.x<850 and _player().position.y<650,"community ramp remains walkable after losing double jump")
	await _capture("carbon-06-junkyard-restored")
	await _entrance()
	_check(GameSession.state==GameSession.State.VICTORY and _app._audit.visible,"A ends with sustainability audit rather than generic result")
	_check(_app._audit.exported_paths.get("ok",false),"A audit auto-generates export files")
	_check(GameSession.last_result.audit.gross_kg>0.0 and GameSession.last_result.audit.restored_regions==3,"A audit contains actual play data")
	await _capture("carbon-07-audit-A")
	GameSession.restart_run()
	await _frames(6)
	_check(CarbonLedger.gross_kg==0.0 and not WorldProgress.core_reversed,"new run clears footprint and resets red form")
	WorldProgress.enter_scene(&"remnant_sea",Vector2(4320,596))
	await _frames(6)
	await _physics(4)
	# Isolated portal fixture: the full normal-input walkthrough covers the fight.
	WorldProgress.borrow_ability(&"shield")
	WorldProgress.borrow_ability(&"black_pierce")
	_level()._on_exit(_player())
	_check(not WorldProgress.narrative_active,"archive remains guarded while player is already inside its trigger")
	var portal_guard: CampaignEnemy=_level().enemies[-1]
	portal_guard.set_physics_process(false)
	for hit in 6: portal_guard.receive_melee_hit({"damage":1})
	await _frames(3)
	await _physics(2)
	_check(WorldProgress.narrative_active,"defeating guardian while inside archive trigger opens story without backtracking")
	_check(WorldProgress.narrative_active and _app._truth.visible,"second run opens truth dialogue before B input")
	await _click(_app._truth.choice_b)
	_check(GameSession.state==GameSession.State.VICTORY and GameSession.last_result.ending=="B","actual B button ends in greenwashed enclave")
	_check(not WorldProgress.core_reversed and GameSession.last_result.audit.people==0,"B does not transform or invent rescue achievements")
	_check(_app._audit.exported_paths.get("ok",false),"B also exports audit")
	await _capture("carbon-08-audit-B")
	GameSession.return_to_menu()
	await _frames(4)
	SoundManager.stop_sfx()
	await _physics(10)
	OS.delay_msec(150)
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
	_player()._invulnerability=2.0
	await _physics(6)


func _action(action: StringName,held: bool=false) -> void:
	Input.action_press(action)
	await _physics(2)
	if not held:
		Input.action_release(action)
		await _physics(1)


func _physics(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame


func _frames(count: int) -> void:
	for index in count: await get_tree().process_frame


func _click(button: Button) -> void:
	await _frames(2)
	var point:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new()
	motion.position=point
	get_viewport().push_input(motion,true)
	await _frames(2)
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=point
		event.pressed=pressed
		get_viewport().push_input(event,true)
		await _frames(1)
	await _frames(3)


func _check(condition: bool,label: String) -> void:
	_checks+=1
	if condition: print("PASS: ",label)
	else:
		_failures+=1
		push_error("FAIL: "+label)


func _capture(label: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args(): return
	await _frames(4)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	_check(get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/"+label+".png")==OK,"capture "+label)
