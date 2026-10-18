extends Node
## Observable input, impact, floor contact and interruption regressions.
var app: Node
var checks := 0
var failures := 0
var starts := 0

func _ready() -> void:
	get_tree().create_timer(65.0).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("en",false)
	app = preload("res://scenes/main.tscn").instantiate()
	# Preserve the original controller / three-seal regression fixture.
	# The production eight-stage mine is covered by mine_challenge_test.
	app.mine_scene=preload("res://tests/fixtures/legacy_mineralization_room.tscn")
	add_child(app)
	GameSession.start_run()
	await _ticks(12)
	_player().combat.attack_started.connect(func(_move: MeleeAttackProfile) -> void: starts+=1)
	for sound: StringName in [&"slash_close",&"slash_reach",&"impact_light",&"impact_heavy",&"enemy_down",&"land"]:
		_check(SoundManager.has_sound(sound) and SoundManager._streams[sound].get_length() >= 0.14,"layered audio is loaded: " + String(sound))
	await _place(Vector2(180,596))
	var low := await _jump_height(2)
	var high := await _jump_height(26)
	_check(high > low + 45 and high > 120,"holding jump rises higher than tapping (tap %.1f / hold %.1f)"%[low,high])
	_check(_player().is_on_floor(),"both jump variants return to a controllable floor")
	_player().impact_pause=0.05
	Input.action_press(&"eden_jump")
	await _ticks(1)
	Input.action_release(&"eden_jump")
	await _ticks(6)
	_check(_player().velocity.y<0,"a jump tapped during impact pause is buffered until control resumes")
	await _place(Vector2(180,596))
	_check(_player().grounding.has_ground and _player().grounding.ground_distance < 2,"grounded feet cast a contact shadow on real terrain")
	await _place(Vector2(180,500))
	_check(_player().grounding.has_ground and _player().grounding.ground_distance > 70,"airborne shadow follows the ground below the actor")
	await _place(Vector2(2530,600))
	_check(not _player().grounding.has_ground,"shadow disappears over a floorless gap")
	await _place(Vector2(180,596))
	var before := starts
	var actions := CarbonLedger.action_count
	await _mouse(false)
	await _ticks(14)
	await _mouse(true)
	_check(starts==before+1,"buffered alternate input cannot skip current recovery")
	await _ticks(14)
	_check(starts==before+2 and _player().combat.reach_attack.is_busy(),"late input launches the next attack exactly once")
	_check(CarbonLedger.action_count==actions+2,"buffer bills only the two accepted attacks")
	_check(_player().combat.reach_attack.impact_pause==0,"a missed or idle weapon carries no stale impact pause")
	await _ticks(50)
	before=starts
	await _mouse(false)
	await _mouse(true)
	await _ticks(55)
	_check(starts==before+1 and not _player().combat.is_busy(),"an old early press expires rather than causing an unexpected attack")
	await _mouse(false)
	await _ticks(14)
	await _mouse(true)
	_player()._invulnerability=0
	_player().hurt()
	before=starts
	await _ticks(45)
	_check(starts==before and not _player().combat.is_busy(),"damage clears buffered input and cannot create a delayed slash")
	await _place(Vector2(580,596))
	_player().face_direction(1)
	var victim: CampaignEnemy=_level().enemies[0]
	victim.health=3
	victim.max_health=3
	victim.position=Vector2(650,596)
	var count: int=_player()._feedback.impact_count
	await _mouse(false)
	for tick in 12:
		if _player()._feedback.impact_count > count: break
		await _ticks(1)
	_check(victim.health==2 and _player()._feedback.impact_count==count+1,"a real melee hit deals damage and produces one impact")
	_check(_player().impact_pause > 0 and _player()._art.sprite.frame in [14,15],"hit-stop holds the actual striking frame")
	_check(_player().combat.reach_attack.impact_pause==0,"striking cannot pause a second idle weapon")
	var remaining: float=_player().combat.close_attack._remaining
	var position := _player().position
	await _ticks(1)
	_check(_player().position==position and _player().combat.close_attack._remaining==remaining,"impact pause holds motion and the damage window together")
	await _capture("feel-01-contact")
	await _ticks(9)
	_check(_player().impact_pause==0 and (_player().combat.close_attack.phase!=MeleeAttack.Phase.ACTIVE or _player().combat.close_attack._remaining<remaining),"local impact pause releases without a stuck attack")
	await _ticks(30)
	_check(victim.health==2,"hit-stop cannot make one swing damage its target twice")
	_check(_player().get_node("Camera2D").offset==Vector2.ZERO,"camera shake settles back to its original framing")
	await _place(Vector2(180,570))
	_player().combat.try_reach(1)
	await _ticks(12)
	_check(_player().is_on_floor() and _player()._art.action==&"reach_melee" and _player()._art.sprite.frame in [20,21],"landing during an air slash preserves its active attack pose")
	await _capture("feel-02-air-landing")
	await _ticks(45)
	before=starts
	await _mouse(false)
	await _ticks(14)
	await _mouse(true)
	WorldProgress.request_dialogue("Moss",["The path is quiet."])
	await _ticks(15)
	_check(starts==before+1 and _player().get_node("Camera2D").offset==Vector2.ZERO,"dialogue cancels buffered combat and clears shake")
	app._dialogue.close()
	await _ticks(30)
	_check(starts==before+1,"closing dialogue cannot replay a stale attack")
	for region: StringName in [&"lone_tree",&"grassland",&"remnant_sea"]:
		if WorldProgress.current_scene!=region:
			WorldProgress.enter_scene(region,Vector2(180,596))
			await _ticks(12)
		var tint: Color=_player()._art._lighting.get_shader_parameter("ambient")
		_check(tint.is_equal_approx(ActorGrounding.ambient_color()),"hero receives the current region's ambient light: "+String(region))
		_check(_level().get_children().any(func(child: Node) -> bool: return child is ForegroundGrowth),"foreground vegetation can cover the soles: "+String(region))
		await _capture("feel-03-"+String(region))
	GameSession.return_to_menu()
	await _ticks(4)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("FEEL: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _jump_height(held: int) -> float:
	await _place(Vector2(180,596))
	var highest := 596.0
	Input.action_press(&"eden_jump")
	for frame in 75:
		if frame==held: Input.action_release(&"eden_jump")
		await _ticks(1)
		highest=minf(highest,_player().position.y)
	Input.action_release(&"eden_jump")
	return 596.0-highest

func _mouse(reach: bool) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_RIGHT if reach else MOUSE_BUTTON_LEFT
		event.pressed=pressed
		event.position=Vector2(600,420)
		get_viewport().push_input(event,true)
		await _ticks(1)

func _place(point: Vector2) -> void:
	_player().position=point
	_player().velocity=Vector2.ZERO
	_player().get_node("Camera2D").reset_smoothing()
	await _ticks(3)

func _level() -> CampaignLevel: return app.get_node("LevelRoot").get_child(0)
func _player() -> CharacterBody2D: return _level().player
func _ticks(count: int) -> void:
	for frame in count:
		if is_instance_valid(app) and app.get_node("LevelRoot").get_child_count()>0:
			for enemy in _level().enemies:
				if is_instance_valid(enemy) and enemy.is_on_floor(): enemy.set_physics_process(false)
		await get_tree().physics_frame
	await get_tree().process_frame
func _capture(label: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/feel")
	_check(get_viewport().get_texture().get_image().save_png("res://test-output/feel/"+label+".png")==OK,"capture "+label)
func _check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error("FAIL: "+label)
