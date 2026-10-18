extends Node
## Component fixtures use real input, collisions, reflection and melee. Physical
## navigation is covered separately by eden_route_test; no simulated wins here.
var app: Node
var level: EdenChapterLevel
var hero: EdenChapterPlayer
var checks:=0
var failures:=0
var screenshots:=false

func _ready() -> void:
	screenshots="--screenshots" in OS.get_cmdline_user_args()
	get_tree().create_timer(180).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("en",false)
	GameSession.start_run()
	WorldProgress.borrow_ability(&"double_jump")
	WorldProgress.borrow_ability(&"light_blade")
	WorldProgress.current_scene=&"grassland"
	WorldProgress.borrow_ability(&"mineralization")
	WorldProgress.current_scene=&"remnant_sea"
	GameSession.sync_health(90,100)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	await ticks(12)
	level=app.get_node("LevelRoot").get_child(0)
	hero=level.player
	check(level is EdenChapterLevel and hero.position.distance_to(EdenBlueprint.ENTRY)<2,"production Eden enters at bottom-right node 01")
	check(level.interaction_hints.visible_keys().is_empty(),"new Eden keeps distant interaction medallions hidden")
	await place(Vector2(1800,2378))
	check(level.interaction_hints.visible_keys().has("T"),"approaching a city display shows the preserved circular T hint")
	await place(EdenBlueprint.ENTRY)
	check(hero.health==90 and hero.stats.health==90 and level.chapter_status.life_orbs.get_half_count()==9,"mine injuries survive the chapter handoff and match the shared HUD")
	check(level.chapter_status.life_orbs.position==Vector2(24,22) and not app._hud.visible,"Eden keeps the shared leaf health display without a duplicate HUD")
	check(EdenBlueprint.NODES.size()==12 and level.pods.size()==3 and level.vents.size()==9,"four floors contain twelve numbered nodes, exactly three pods and nine temporary gas relays")
	check(hero.speed==260 and hero.gravity==980 and hero.jump_velocity== -420 and hero.double_jump_velocity== -390 and hero.coyote_time==0.12 and hero.jump_buffer==0.12,"Eden physics use the requested independent chapter configuration")
	check(WorldProgress.has_ability(&"double_jump") and WorldProgress.has_ability(&"mineralization") and not WorldProgress.has_ability(&"shield") and not WorldProgress.has_ability(&"black_pierce"),"previous skills are retained while the two Eden skills must be extracted")
	check(not WorldProgress.reveal_truth(),"truth cannot skip the live extraction core")
	await mouse(MOUSE_BUTTON_RIGHT)
	check(hero.combat.reach_attack.is_busy() and not hero.guard_held,"actual RMB starts the heavy attack before Shield is acquired")
	await ticks(12)
	check(hero._art.action==&"reach_melee" and not hero.combat.reach_attack.show_hitbox and not hero.combat.reach_attack.show_placeholder_weapon,"heavy slash has its animated pose and blade trail without a judgment rectangle")
	await capture("heavy-slash")
	await ticks(35)
	Input.action_press(&"eden3_guard")
	await ticks(8)
	check(not hero.guard_held and hero.shield_energy==100,"unacquired Shield cannot block or drain energy")
	Input.action_release(&"eden3_guard")
	await capture("01-promise")
	for turret in level.turrets: turret.active=false
	hero._invulnerability=0
	hero.hurt()
	hero.position.y=2600
	await ticks(16)
	check(GameSession.health==60 and hero.stats.health==60 and hero.respawn_seconds==0,"half-orb injury followed by a fall costs exactly another full orb without refilling")
	await place(Vector2(350,1898))
	check(level.interaction_hints.visible_keys().has("E"),"new Eden skill source uses the shared nearby E medallion")
	await action(&"eden_absorb")
	await ticks(151)
	check(WorldProgress.has_ability(&"shield") and level.sources[0].vitality==0,"real extraction grants Shield only after the source is depleted")
	var shield_before_heavy:=hero.shield_energy
	await mouse(MOUSE_BUTTON_RIGHT)
	await ticks(18)
	check(hero.combat.reach_attack.is_busy() and not hero.guard_held and hero.shield_energy>=shield_before_heavy,"RMB remains a heavy slash after Shield is acquired and does not consume shield energy")
	await ticks(30)
	await capture("02-shield-source")
	Input.action_press(&"eden3_guard")
	Input.action_press(&"eden_move_right")
	await ticks(30)
	check(hero.guard_held and absf(hero.velocity.x-169)<1 and hero.shield_energy<87,"holding Shield drains 28 per second and slows movement to 65 percent")
	Input.action_release(&"eden_move_right")
	Input.action_release(&"eden3_guard")
	await ticks(65)
	check(hero.shield_energy>85,"Shield energy regenerates after the release delay")
	await place(Vector2(650,1898))
	var receiver:=level._receiver(Vector2(850,1898),&"test_reflection")
	var energy_before:=hero.shield_energy
	var shot:=level.fire(hero.position+Vector2(58,0),Vector2.LEFT,220)
	Input.action_press(&"eden3_guard")
	await ticks(14)
	check(is_instance_valid(shot) and shot.reflected and is_equal_approx(shot.speed,352),"a timed press reflects a real projectile at 1.6 times speed")
	check(hero.shield_energy>energy_before and level.parry_flashes==1,"perfect parry restores energy and emits the hitstop flash")
	Input.action_release(&"eden3_guard")
	await ticks(48)
	check(receiver.lit,"reflected projectile travels forward and powers a physical receiver")
	check(hero.impact_pause==0,"the real parry hitstop releases instead of freezing the hero indefinitely")
	var run_frames: Dictionary={}
	Input.action_press(&"eden_move_right")
	for frame in 20:
		await ticks(1)
		run_frames[hero._art.sprite.frame]=true
	Input.action_release(&"eden_move_right")
	check(hero._art.action==&"run" and run_frames.size()>=3,"movement after a parry advances the original running animation")
	await ticks(4)
	await mouse(MOUSE_BUTTON_LEFT)
	await ticks(6)
	check(hero._art.action==&"close_melee","a fresh attack after a parry shows its own animation")
	await ticks(30)
	check(not hero.combat.is_busy() and hero._art.action==&"idle" and hero._art._effects.is_empty(),"the post-parry slash returns to idle and clears its lingering trails")
	receiver.queue_free()
	await place(Vector2(650,1898))
	Input.action_press(&"eden3_guard")
	await ticks(20)
	energy_before=hero.shield_energy
	var hp:=hero.health
	level.fire(hero.position+Vector2(58,0),Vector2.LEFT,220)
	await ticks(14)
	check(hero.health==hp and hero.shield_energy<energy_before-8,"late held block destroys the shot and pays the per-shot energy cost")
	level.fire(hero.position-Vector2(58,0),Vector2.RIGHT,220)
	hero._invulnerability=0
	await ticks(14)
	check(hero.health==hp-10,"a frontal shield does not block a shot arriving from behind")
	hero.shield_energy=2
	await ticks(10)
	check(hero.guard_overheat>1 and not hero.guard_held,"zero energy breaks the guard for 1.5 seconds")
	Input.action_release(&"eden3_guard")
	await ticks(145)
	check(hero.guard_overheat==0 and hero.shield_energy>10,"release and recovery make a broken shield usable again")
	# Each elevated corridor target receives an actual reflected orb.
	for receiver_index in 3:
		var point:=level.corridor_receivers[receiver_index].position
		await parry_toward(point,Vector2(850,point.y))
	check(level.corridor_gate.opened and WorldProgress.eden_chapter.get("mirror",false),"all three mirror receivers unlock the garden bridge")
	await capture("03-mirror")
	level.steward.active=true
	level.steward._cycle=100
	await parry_toward(level.steward.position+Vector2(0,-10),Vector2(1480,1876))
	check(not level.steward.shield_broken and level.steward.shield_hits==1 and level._notice.text.contains("one more"),"first parry says one more reflection is required instead of incorrectly promising a damage window")
	await place(level.steward.position+Vector2(-140,22))
	hero.facing=1
	await mouse(MOUSE_BUTTON_RIGHT)
	await ticks(15)
	check(level.steward.health==3 and level.steward._armor_flash>0,"armored heavy hits produce explicit blocked-hit feedback without pretending to damage health")
	await ticks(32)
	await parry_toward(level.steward.position+Vector2(0,-10),Vector2(1480,1876))
	check(level.steward.shield_broken and level.steward._stun>0,"two reflected orbs shatter and stun the Steward's armor")
	for index in 3:
		await place(level.steward.position+Vector2(-72,0))
		hero.facing=1
		await mouse(MOUSE_BUTTON_RIGHT if index%2==0 else MOUSE_BUTTON_LEFT)
		await ticks(46)
	check(WorldProgress.eden_chapter.get("steward",false) and level.current_node==4,"actual left and right mouse hits defeat the exposed mini-boss and unlock node 04")
	await place(Vector2(2240,1898))
	level.interact()
	await wait_lift()
	check(level.current_node==5 and hero.position.y<1350,"the ascension elevator physically delivers the player to processing floor 3F")
	await action(&"eden_absorb")
	await ticks(151)
	check(WorldProgress.has_ability(&"black_pierce") and level.sources[1].vitality==0,"Dark Dash is earned from its own extraction source")
	check(level.ecology.amount>0.99,"the two Eden extractions retain the campaign's gradual scene depletion")
	await place(Vector2(2130,1298))
	Input.action_press(&"eden_move_left")
	await ticks(30)
	check(hero.position.x>2070,"normal movement collides with the phase wall")
	await action(&"eden3_dash")
	var before_dash:=hero.health
	hero._invulnerability=0
	hero.hurt(&"body")
	check(hero.health==before_dash,"Dark Dash grants full enemy body-contact immunity")
	await ticks(17)
	Input.action_release(&"eden_move_left")
	check(hero.position.x<2040 and hero.get_collision_mask_value(5),"dash crosses the purple wall and restores its collision mask")
	await place(Vector2(1910,1038))
	hero.facing=1
	hero.combat.request_attack(false,1)
	await ticks(30)
	check(WorldProgress.eden_chapter.get("oren",false),"a real melee hit severs Oren's supply conduit")
	await capture("04-processing")
	level.advance(7,Vector2(1450,1038))
	await parry_toward(level.dual_receiver.position,Vector2(1430,1015))
	check(level.dual_gate.opened and level.dual_seconds>4,"a reflected shot energizes the first timed security door")
	await place(Vector2(1170,1038))
	hero.facing=-1
	await action(&"eden3_dash")
	await ticks(18)
	check(hero.position.x<1080 and level.current_node==8,"the second phase barrier can be crossed within the same charge window")
	await place(Vector2(210,1298))
	hero.cooldown=0
	var stored:=CarbonLedger.stored_kg
	await action(&"eden3_mineral")
	check(is_instance_valid(level.vents[0].platform) and CarbonLedger.stored_kg==stored+150,"E solidifies real gas into a temporary platform and records one storage batch")
	await ticks(246)
	check(not is_instance_valid(level.vents[0].platform),"mineralized ledges expire after four seconds")
	await place(Vector2(540,598))
	await ticks(3)
	check(level.current_node==10 and level.boss.active,"ascending the shaft starts the real final boss")
	level.boss._shots=100
	for index in 3: await parry_toward(level.boss.position,Vector2(950,598))
	check(level.boss.exposed>0 and level.boss.core_lock.hits==3,"three real reflections expose the extraction device")
	await capture("05-heart-exposed")
	for index in 3:
		await place(Vector2(1120,360))
		hero.facing=1
		await mouse(MOUSE_BUTTON_RIGHT if index%2==0 else MOUSE_BUTTON_LEFT)
		await ticks(46)
	check(level.boss.phase==2 and is_instance_valid(level.boss.guard),"actual left and right mouse hits damage the exposed core and transition to Predation Protocol")
	var guard:=level.boss.guard
	guard.position=Vector2(1000,576)
	guard._windup=0
	guard._direction=1
	guard.charge_left=2
	await place(Vector2(1110,598))
	hero.facing=-1
	await action(&"eden3_dash")
	hp=hero.health
	await ticks(17)
	check(hero.position.x<guard.position.x and hero.health==hp,"a live full-floor charge can be passed through without body damage")
	check(guard._actions.pose==&"charge" and not guard._skin.flip_h,"guardian maintains its charging pose and facing after passing the player")
	for index in 140:
		await ticks(1)
		if guard._recovery>1.7: break
	check(guard._recovery>0,"the charging guardian exposes its weak point after hitting the wall")
	await ticks(2)
	check(guard._recovery>5 and guard._actions.pose==&"stagger" and level._boss_text.text.contains("WEAK POINT"),"wall impact gives a clear 5.4-second stagger animation and a live damage-window countdown")
	for index in 3:
		await place(guard.position+Vector2(-70,0))
		hero.facing=1
		await mouse(MOUSE_BUTTON_RIGHT if index%2==0 else MOUSE_BUTTON_LEFT)
		await ticks(46)
	check(level.boss.phase==3,"actual left and right mouse weak-point hits advance to Harvest Protocol")
	await parry_toward(level.boss.left_line.global_position,Vector2(850,440))
	check(level.boss.left_cut,"perfect parry severs the left bio-supply line")
	await place(Vector2(2010,258))
	hero.facing=1
	hero.combat.request_attack(false,1)
	await ticks(28)
	check(level.boss.dismantled and WorldProgress.narrative_active and app._truth.visible,"severing the right extraction lock opens the ending choice without harming the tree")
	check(CarbonLedger.rescued_people==0,"dismantling the device does not automatically rescue any humans")
	app._truth.choose(&"A")
	await ticks(5)
	check(WorldProgress.returning and WorldProgress.core_reversed and CarbonLedger.rescued_people==0,"existing A semantics start Circular Mode with zero rescued pods")
	Input.action_press(&"eden_move_right")
	await ticks(20)
	Input.action_release(&"eden_move_right")
	check(hero._art.green_form and hero._art.action==&"run" and hero._art.sprite.texture==HeroActionVisual.MOTION_GREEN,"the green return form keeps animating after the final boss parries")
	await capture("green-animation-recovered")
	await ticks(22)
	check(hero._art.action==&"idle" and hero._art._effects.is_empty(),"green return idle clears the old red slash and accumulated particles")
	check(not level.pods[1].release_human() and not WorldProgress.repair_current_region(),"cannot skip the first rescue or repair before all three humans are free")
	await parry_toward(level.pods[0].bio_lock.global_position,Vector2(2080,235))
	check(level.pods[0].released and CarbonLedger.rescued_people==1,"upper-right pod 1 releases a human only after its bio-lock is reflected")
	await capture("06-pod-one")
	hero.stats.take_damage(100)
	await ticks(2)
	check(GameSession.state==GameSession.State.GAME_OVER and app._result.visible,"zero health during rescue opens the normal Game Over modal")
	GameSession.resume_checkpoint()
	await ticks(12)
	level=app.get_node("LevelRoot").get_child(0)
	hero=level.player
	check(level.pods[0].released and not level.pods[1].released and CarbonLedger.rescued_people==1,"explicit continue preserves each rescued pod without inventing survivors")
	check(level.boss.dismantled and WorldProgress.returning and not level.turrets[-3].active,"checkpoint continue preserves the dismantled core, rescue mode and disabled pod security")
	check(hero.health==100 and WorldProgress.has_ability(&"shield") and WorldProgress.has_ability(&"black_pierce"),"only explicit Game Over continue restores life while retaining the rescue abilities")
	await place(Vector2(1740,1038))
	hero.facing=1
	await action(&"eden3_dash")
	await ticks(17)
	check(hero.position.x>1805,"return route phases into the sealed processing bay")
	hero.combat.request_attack(false,1)
	await ticks(28)
	check(level.pods[1].released and CarbonLedger.rescued_people==2,"breaking the processing pod's valve rescues human 2")
	await parry_toward(level.pods[2].bio_lock.global_position,Vector2(2215,1735))
	check(level.pods[2].released and CarbonLedger.rescued_people==3,"an actual ricochet overloads the ascension elevator bio-lock for human 3")
	check(not level.pods[2].release_human() and CarbonLedger.rescued_people==3,"a repeated rescue cannot inflate the required three humans")
	await capture("07-pod-three")
	# Same position as the screenshot: near the platform's right edge, not exactly
	# on the numbered entrance marker. The visible hint and the exit share a radius.
	await place(EdenBlueprint.ENTRY+Vector2(140,0))
	check(not level._entrance_hint.visible and level.interaction_hints.visible_keys().has("R"),"three rescued residents use the nearby circular R hint instead of an extra persistent panel")
	await key(KEY_T)
	check(WorldProgress.current_scene==&"remnant_sea" and not WorldProgress.eden_chapter.get("escaped",false) and level._notice.text.contains("Press R"),"T before repair explains the missing R step instead of reopening the city display")
	var return_health:=GameSession.health
	await key(KEY_R)
	await ticks(3)
	check(WorldProgress.route_open(&"shield") and WorldProgress.route_open(&"black_pierce") and WorldProgress.repaired_regions.has(&"remnant_sea"),"all three survivors can return Eden's abilities after a public route is opened")
	check(WorldProgress.has_ability(&"double_jump") and WorldProgress.has_ability(&"mineralization"),"Eden leaves the first two chapters' borrowed skills intact for their own return encounters")
	check(level._objective.text.contains("LEAVE EDEN") and GameSession.health==return_health,"repair changes the persistent hint to T-to-leave without healing the player")
	check(level._shield_text.text.contains("RETURNED") and level.chapter_status.skill_label.text.contains("returned"),"returned city skills are labeled returned instead of telling the player to acquire them again")
	await mouse(MOUSE_BUTTON_LEFT)
	check(WorldProgress.current_scene==&"remnant_sea","an ordinary attack near the repaired entrance cannot accidentally leave Eden")
	await ticks(30)
	await capture("08-return-entrance")
	await key(KEY_T)
	await ticks(10)
	check(WorldProgress.current_scene==&"grassland" and app.get_node("LevelRoot").get_child(0)._returning,"rescued party reconnects to the existing mine return route")
	# Isolate the other choice after the same completed-core contract; full core
	# combat and the actual A descent were exercised above.
	GameSession.return_to_menu()
	await ticks(4)
	GameSession.start_run()
	await ticks(6)
	WorldProgress.enter_scene(&"remnant_sea",EdenBlueprint.ENTRY)
	await ticks(8)
	level=app.get_node("LevelRoot").get_child(0)
	level.boss.left_cut=true
	level.boss.right_cut=true
	level.boss._check_finish()
	app._truth.choice_b.pressed.emit()
	await ticks(3)
	check(GameSession.state==GameSession.State.VICTORY and GameSession.last_result.ending=="B" and app._audit.visible,"the actual B button reaches the existing Join Eden ending and audit")
	check(CarbonLedger.rescued_people==0 and not WorldProgress.returning,"Join Eden cannot claim the three rescue achievements")
	GameSession.return_to_menu()
	await ticks(5)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("EDEN_CHAPTER: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func parry_toward(target: Vector2,point: Vector2) -> void:
	Input.action_release(&"eden3_guard")
	await place(point)
	hero.facing=signf(target.x-point.x) if absf(target.x-point.x)>1 else 1
	hero.shield_energy=maxf(40,hero.shield_energy)
	var direction: Vector2=(target-point).normalized()
	level.fire(point+direction*58,-direction,220)
	Input.action_press(&"eden3_guard")
	await ticks(15)
	Input.action_release(&"eden3_guard")
	await ticks(70)

func place(point: Vector2) -> void:
	Input.action_release(&"eden_move_left")
	Input.action_release(&"eden_move_right")
	hero.reset_at_checkpoint(point)
	hero.dash_cooldown=0
	hero.guard_overheat=0
	await ticks(3)

func action(id: StringName) -> void:
	Input.action_press(id)
	await ticks(1)
	Input.action_release(id)
	await ticks(1)

func ticks(count: int) -> void:
	for frame in count: await get_tree().physics_frame
	# Scene navigation now includes a visible fade and a short re-entry lock.
	while WorldProgress.scene_transition_active or WorldProgress.transition_rearm_seconds>0:
		await get_tree().physics_frame
	await get_tree().process_frame

func wait_lift() -> void:
	for index in 300:
		await ticks(1)
		if not level.elevator.is_moving(): break

func mouse(button: MouseButton) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=button
	event.position=Vector2(1050,500)
	event.pressed=true
	Input.parse_input_event(event)
	await ticks(1)
	event=InputEventMouseButton.new()
	event.button_index=button
	event.position=Vector2(1050,500)
	Input.parse_input_event(event)
	await ticks(1)

func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await ticks(1)
	event=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	Input.parse_input_event(event)
	await ticks(1)

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)

func capture(id: String) -> void:
	if not screenshots: return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/eden-"+id+".png")
