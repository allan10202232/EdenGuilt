extends Node
## End-to-end playthrough using only ordinary input and UI. No teleports,
## invulnerability overrides, disabled AI, stat edits or story-state shortcuts.
var app: Node
var checks:=0
var failures:=0
var _shots:=0
var _last_health:=100
var _deaths:=0
var _damage_events:=0
var _guard_jump_at:=-1
var _frame:=0
var _record: Array[Dictionary]=[]

func _ready() -> void:
	get_tree().create_timer(600).timeout.connect(func() -> void:
		push_error("Walkthrough timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("zh_CN",false)
	app=preload("res://scenes/main.tscn").instantiate()
	# Historical horizontal Eden fixture; production four-floor Eden has its own route suite.
	app.eden_scene=preload("res://tests/fixtures/legacy_eden_room.tscn")
	# Preserve the original controller / three-seal regression fixture.
	# The production eight-stage mine is covered by mine_challenge_test.
	app.mine_scene=preload("res://tests/fixtures/legacy_mineralization_room.tscn")
	add_child(app)
	await _tick(4)
	await _click(app.get_node("UI/Root/MainMenu/%StartButton"))
	await _tick(30)
	await _journey("A")
	if failures==0:
		await _click(app._audit._restart)
		await _tick(30)
		_last_health=100
		await _journey("B")
	await _snapshot("final")
	var output:=FileAccess.open("res://test-output/walkthrough-events.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(_record,"\t"))
	output.close()
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("WALKTHROUGH: %d checks, %d failures; %d deaths"%[checks,failures,_deaths])
	get_tree().quit(0 if failures==0 else 1)

func _journey(ending: String) -> void:
	await _snapshot(ending+"-junkyard-start")
	await _walk(230)
	await _action(&"eden_absorb")
	_check(WorldProgress.has_ability(&"double_jump"),"learn double jump via E")
	var scrapyard := preload("res://tests/helpers/scrapyard_route.gd").new()
	scrapyard.app = app
	scrapyard.report = _check
	add_child(scrapyard)
	await scrapyard.run(false)
	scrapyard.queue_free()
	await _tick(8)
	_check(WorldProgress.current_scene==&"grassland","enter toxic mine through junkyard exit")
	if failures: return
	await _snapshot(ending+"-mine-start")
	await _walk(530)
	await _action(&"eden_absorb")
	await _walk(880)
	await _leap(1060,false)
	await _action(&"eden_mineralize")
	_check(WorldProgress.is_collected(&"grassland/mineral_0"),"mineralize bridge node from its reachable lower approach")
	await _walk(1530)
	await _walk(1710)
	await _action(&"eden_mineralize")
	await _walk(2010)
	await _tick(8)
	await _action(&"eden_mineralize")
	await _walk(2560)
	await _leap(2860)
	await _walk(3320)
	await _leap(3550)
	await _walk(3990)
	await _tick(8)
	_check(WorldProgress.current_scene==&"remnant_sea","enter Eden through mine exit")
	if failures: return
	await _snapshot(ending+"-eden-start")
	await _walk(420)
	await _action(&"eden_absorb")
	await _walk(950)
	await _leap(1340)
	await _action(&"eden_absorb")
	await _walk(1550)
	Input.action_press(&"eden_shield")
	await _walk(2120)
	Input.action_release(&"eden_shield")
	await _walk(2300)
	await _leap(2510)
	await _leap(2830)
	await _walk(3460)
	await _action(&"eden_black_pierce")
	_check(_player().position.x>3542,"use F to cross dark wall")
	await _snapshot(ending+"-guardian")
	await _fight_guardian()
	if failures: return
	await _walk(4320)
	await _tick(4)
	_check(WorldProgress.narrative_active and app._truth.visible,"guardian victory unlocks the story choice")
	await _snapshot(ending+"-truth")
	if failures: return
	await _click(app._truth.choice_a if ending=="A" else app._truth.choice_b)
	if ending=="B":
		_check(GameSession.state==GameSession.State.VICTORY and GameSession.last_result.ending=="B","B reaches its audit through the actual choice button")
		await _snapshot("B-audit")
		return
	_check(WorldProgress.core_reversed and CarbonLedger.rescued_people==3,"A awakens and rescues residents")
	await _action(&"eden_return")
	var damage_before:=_damage_events
	await _walk(1340)
	_check(_damage_events==damage_before,"repaired Eden public route is safe before unloading shield")
	await _action(&"eden_return")
	await _walk(420)
	await _action(&"eden_return")
	await _snapshot("A-eden-restored")
	await _walk(36)
	await _tick(8)
	_check(WorldProgress.current_scene==&"grassland","return from Eden without shield or black pierce")
	if failures: return
	await _walk(1500)
	await _leap(1100)
	await _walk(530)
	await _action(&"eden_return")
	await _walk(36)
	await _tick(8)
	_check(WorldProgress.current_scene==&"lone_tree","return to junkyard without mineralization")
	if failures: return
	await _walk(230)
	await _action(&"eden_return")
	await _snapshot("A-home-restored")
	await _walk(36)
	await _tick(8)
	_check(GameSession.state==GameSession.State.VICTORY and WorldProgress.required_returns_complete(),"A returns home and reaches the audit")
	await _snapshot("A-audit")

func _level() -> CampaignLevel:
	return app.get_node("LevelRoot").get_child(0)

func _player() -> CharacterBody2D:
	return _level().player

func _tick(count: int) -> void:
	for index in count:
		_frame+=1
		if WorldProgress.can_play(): _attack_nearby()
		await get_tree().physics_frame
		if GameSession.health!=_last_health:
			if GameSession.health<_last_health: _damage_events+=1
			_record.append({"event":"health","region":WorldProgress.current_scene,"position":_player().position,"health":GameSession.health,"notice":WorldProgress.notice})
			print("PLAY: health ",GameSession.health," at ",WorldProgress.current_scene," ",_player().position)
			_last_health=GameSession.health
		if GameSession.state==GameSession.State.GAME_OVER and failures==0:
			_deaths+=1
			_check(false,"player died during the ordinary-input route at %s %s"%[WorldProgress.current_scene,_player().position])
	while WorldProgress.scene_transition_active or WorldProgress.transition_rearm_seconds>0: await get_tree().physics_frame
	await get_tree().process_frame

func _attack_nearby() -> void:
	if _player().combat.is_busy() or WorldProgress.shield_active: return
	for enemy: CampaignEnemy in _level().enemies:
		if not is_instance_valid(enemy) or enemy.health<=0: continue
		var distance:=enemy.position-_player().position
		if absf(distance.x)>38 and absf(distance.x)<185 and absf(distance.y)<35 and signf(distance.x)==_player()._facing:
			for pressed in [true,false]:
				var event:=InputEventMouseButton.new()
				event.button_index=MOUSE_BUTTON_RIGHT
				event.position=Vector2(600,400)
				event.pressed=pressed
				get_viewport().push_input(event,true)
			break

func _action(action: StringName) -> void:
	if failures: return
	Input.action_press(action)
	await _tick(12 if action==&"eden_jump" else 2)
	Input.action_release(action)
	await _tick(2)
	if action == &"eden_absorb":
		for frame in 240:
			if not WorldProgress.extraction_active:
				break
			await _tick(1)

func _walk(target: float) -> void:
	if failures: return
	var region:=WorldProgress.current_scene
	var direction:=signf(target-_player().position.x)
	var action:=&"eden_move_right" if direction>0 else &"eden_move_left"
	Input.action_press(action)
	Input.action_press(&"eden_run")
	for index in 2400:
		if failures or WorldProgress.current_scene!=region or GameSession.state!=GameSession.State.PLAYING or WorldProgress.narrative_active: break
		if direction*(target-_player().position.x)<5: break
		await _tick(1)
	Input.action_release(action)
	Input.action_release(&"eden_run")
	_check(WorldProgress.current_scene!=region or WorldProgress.narrative_active or GameSession.state==GameSession.State.VICTORY or absf(target-_player().position.x)<18,"walk %s to %.0f at %s"%[region,target,_player().position])

func _leap(target: float,double: bool=true) -> void:
	if failures: return
	for index in 65:
		if _player().is_on_floor(): break
		await _tick(1)
	var direction:=signf(target-_player().position.x)
	var action:=&"eden_move_right" if direction>0 else &"eden_move_left"
	Input.action_press(action)
	Input.action_press(&"eden_run")
	Input.action_press(&"eden_jump")
	for index in 130:
		if failures: break
		if index in [14,32]: Input.action_release(&"eden_jump")
		if index==18 and double: Input.action_press(&"eden_jump")
		if direction*(target-_player().position.x)<5: Input.action_release(action)
		if index>10 and _player().is_on_floor() and absf(target-_player().position.x)<20: break
		await _tick(1)
	Input.action_release(action)
	Input.action_release(&"eden_run")
	Input.action_release(&"eden_jump")
	_check(_player().is_on_floor() and absf(target-_player().position.x)<20,"jump to %.0f landed at %s"%[target,_player().position])

func _fight_guardian() -> void:
	_guard_jump_at=-1
	for index in 2400:
		if failures or WorldProgress.is_enemy_defeated(&"remnant_sea/boss"): break
		var boss: CampaignEnemy=_level().enemies[-1]
		var dx:=boss.position.x-_player().position.x
		Input.action_release(&"eden_move_left")
		Input.action_release(&"eden_move_right")
		if dx<130:
			Input.action_press(&"eden_move_left")
		elif dx>180 or _player()._facing<0:
			Input.action_press(&"eden_move_right")
		if index%240==0:
			print("PLAY: guardian hp=",boss.health," distance=",dx," hero=",_player().position)
		if boss._windup>0 and _player().is_on_floor() and _guard_jump_at<0:
			Input.action_press(&"eden_jump")
			_guard_jump_at=_frame
		elif _guard_jump_at>=0:
			if _frame-_guard_jump_at==12: Input.action_release(&"eden_jump")
			if _frame-_guard_jump_at==20:
				Input.action_press(&"eden_jump")
			elif _frame-_guard_jump_at==32: Input.action_release(&"eden_jump")
			if _frame-_guard_jump_at>40 and _player().is_on_floor(): _guard_jump_at=-1
		await _tick(1)
	Input.action_release(&"eden_move_left")
	Input.action_release(&"eden_move_right")
	Input.action_release(&"eden_jump")
	_check(WorldProgress.is_enemy_defeated(&"remnant_sea/boss"),"defeat live guardian using normal melee and jump evasion")
	await _snapshot("guardian-defeated")

func _click(button: Button) -> void:
	await _tick(2)
	var point:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new()
	motion.position=point
	get_viewport().push_input(motion,true)
	await _tick(2)
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=point
		event.pressed=pressed
		get_viewport().push_input(event,true)
		await _tick(1)
	await _tick(3)


func _snapshot(label: String) -> void:
	_record.append({"event":label,"region":WorldProgress.current_scene,"health":GameSession.health,"carbon":CarbonLedger.gross_kg,"notice":WorldProgress.notice})
	print("PLAY: ",label," hp=",GameSession.health," carbon=",CarbonLedger.gross_kg)
	if DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/walkthrough")
	_shots+=1
	get_viewport().get_texture().get_image().save_png("res://test-output/walkthrough/%02d-%s.png"%[_shots,label])

func _check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error("FAIL: "+label)
