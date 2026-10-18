extends Node
## Geometry acceptance: every gap uses actual input and physics, never teleporting.
## Enemy AI is isolated; combat, damage and both ending buttons have separate coverage.

var app: Node
var checks := 0
var failures := 0

func _ready() -> void:
	get_tree().create_timer(300).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	await _tick(4)
	GameSession.start_run()
	await _tick(30)
	await _walk(420)
	await _action(&"eden_absorb")
	await _walk(870)
	await _leap(1280)
	await _walk(1740)
	await _leap(2010)
	await _walk(2340)
	await _leap(2820)
	await _walk(3010)
	await _leap(3240)
	await _walk(3750)
	await _tick(8)
	_check(WorldProgress.current_scene==&"grassland","walked junkyard exit into mine")
	if failures:
		await _finish()
		return
	await _walk(530)
	await _action(&"eden_absorb")
	await _walk(880)
	await _leap(1100)
	await _walk(1150)
	await _action(&"eden_mineralize")
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
	_check(WorldProgress.current_scene==&"remnant_sea","walked mine exit into Eden")
	if failures:
		await _finish()
		return
	await _walk(420)
	await _action(&"eden_absorb")
	await _walk(950)
	await _leap(1340)
	await _action(&"eden_absorb")
	await _walk(2120)
	await _walk(2300)
	await _leap(2510)
	await _leap(2830)
	await _walk(3460)
	await _action(&"eden_black_pierce")
	_check(_player().position.x>3542,"physical route reaches and pierces Eden dark wall")
	# Remove guardian via the normal hurtbox contract; AI combat is a separate test.
	for enemy in _level().enemies:
		if is_instance_valid(enemy) and enemy.boss:
			for index in 6: enemy.receive_melee_hit({"damage":1})
	await _walk(4320)
	await _tick(4)
	_check(WorldProgress.narrative_active,"physical route reaches truth archive")
	WorldProgress.choose_ending("A")
	await _action(&"eden_return")
	await _walk(1340)
	await _action(&"eden_return")
	await _walk(420)
	await _action(&"eden_return")
	await _walk(36)
	await _tick(8)
	_check(WorldProgress.current_scene==&"grassland","Eden return route works without shield or black pierce")
	if failures:
		await _finish()
		return
	await _walk(1500)
	await _leap(1100)
	await _walk(530)
	await _action(&"eden_return")
	await _walk(36)
	await _tick(8)
	_check(WorldProgress.current_scene==&"lone_tree","mine return route works without mineralization")
	if failures:
		await _finish()
		return
	await _walk(2760)
	await _leap(2300)
	await _walk(1740)
	await _leap(1540)
	await _walk(1260)
	await _leap(850)
	await _walk(420)
	await _action(&"eden_return")
	await _walk(36)
	await _tick(8)
	_check(GameSession.state==GameSession.State.VICTORY and WorldProgress.required_returns_complete(),"entire outward and return route reaches ending A")
	await _finish()

func _level() -> CampaignLevel:
	return app.get_node("LevelRoot").get_child(0)

func _player() -> CharacterBody2D:
	return _level().player

func _tick(count: int) -> void:
	for index in count:
		if app!=null and app.get_node("LevelRoot").get_child_count()>0:
			_player()._invulnerability=0.5
			for enemy in _level().enemies:
				if is_instance_valid(enemy): enemy.set_physics_process(false)
		await get_tree().physics_frame
	await get_tree().process_frame

func _action(action: StringName) -> void:
	Input.action_press(action)
	await _tick(2)
	Input.action_release(action)
	await _tick(2)

func _walk(target: float) -> void:
	if failures: return
	var region:=WorldProgress.current_scene
	var direction:=signf(target-_player().position.x)
	var action:=&"eden_move_right" if direction>0 else &"eden_move_left"
	Input.action_press(action)
	Input.action_press(&"eden_run")
	for index in 800:
		if WorldProgress.current_scene!=region or GameSession.state!=GameSession.State.PLAYING or WorldProgress.narrative_active: break
		if direction*(target-_player().position.x)<5: break
		await _tick(1)
	Input.action_release(action)
	Input.action_release(&"eden_run")
	_check(WorldProgress.current_scene!=region or WorldProgress.narrative_active or GameSession.state==GameSession.State.VICTORY or absf(target-_player().position.x)<18,"walk %s to %.0f (at %s)"%[region,target,_player().position])

func _leap(target: float) -> void:
	if failures: return
	var direction:=signf(target-_player().position.x)
	var action:=&"eden_move_right" if direction>0 else &"eden_move_left"
	Input.action_press(action)
	Input.action_press(&"eden_run")
	await _action(&"eden_jump")
	await _tick(17)
	await _action(&"eden_jump")
	for index in 130:
		if direction*(target-_player().position.x)<5: Input.action_release(action)
		if index>10 and _player().is_on_floor() and absf(target-_player().position.x)<20: break
		await _tick(1)
	Input.action_release(action)
	Input.action_release(&"eden_run")
	_check(_player().is_on_floor() and absf(target-_player().position.x)<20,"jump to %.0f landed at %s"%[target,_player().position])

func _check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error("FAIL: "+label)

func _finish() -> void:
	GameSession.return_to_menu()
	await _tick(4)
	SoundManager.stop_sfx()
	# Fixed-fps runs advance faster than the audio mixing thread's real clock.
	OS.delay_msec(150)
	print("ROUTE: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)
