extends Node
## Real animation transitions, collision phases, interruption and frozen terminal gameplay.
var app: Node
var checks:=0
var failures:=0

func _ready() -> void:
	get_tree().create_timer(60).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("zh_CN",false)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	await _physics(4)
	GameSession.start_run()
	await _physics(30)
	for sheet: Texture2D in [HeroActionVisual.RED,HeroActionVisual.GREEN]:
		var image:=sheet.get_image()
		_check(image.get_size()==Vector2i(1536,1024),"action sheet has 6 by 4 equal square cells")
		var complete:=true
		for index in 24:
			var cell:=image.get_region(Rect2i((index%6)*256,(index/6)*256,256,256))
			complete=complete and cell.get_used_rect().size.x>32 and cell.get_used_rect().size.y>32
		_check(complete and image.get_pixel(0,0).a==0,"all 24 poses exist with transparent background")
	_check(_visual().action==&"idle" and _visual().sprite.frame in [6,7],"grounded character breathes in idle pose")
	var seen: Dictionary={}
	Input.action_press(&"eden_move_right")
	for index in 40:
		await _physics(1)
		if _visual().action==&"run": seen[_visual().sprite.frame]=true
	Input.action_release(&"eden_move_right")
	_check(seen.size()==6,"running plays six different limb poses: %s"%[seen.keys()])
	Input.action_press(&"eden_move_left")
	await _physics(5)
	_check(_visual().sprite.flip_h,"running left mirrors the action sheet")
	Input.action_release(&"eden_move_left")
	WorldProgress.borrow_ability(&"double_jump")
	await _action(&"eden_jump")
	_check(_visual().action==&"jump" and _player().velocity.y<0,"first jump has upward jump pose")
	await _physics(15)
	await _action(&"eden_jump")
	_check(_visual().action==&"double_jump" and _visual().sprite.frame==9,"second jump plays its own spinning pose")
	await _capture("actions-01-double-jump")
	var landed:=false
	var fell:=false
	for index in 100:
		await _physics(1)
		fell=fell or _visual().action==&"fall"
		landed=landed or _visual().action==&"land"
	_check(fell and landed,"falling transitions into a landing crouch")
	await _place(Vector2(580,596))
	var target: CampaignEnemy=_level().enemies[0]
	target.position=Vector2(650,596)
	target.set_physics_process(false)
	_player().face_direction(1)
	_player().combat.try_close(1)
	await _physics(1)
	_check(_visual().sprite.frame==12 and target.health==1,"short attack windup pose precedes damage")
	await _physics(4)
	_check(_visual().sprite.frame==13 and WorldProgress.is_enemy_defeated(&"lone_tree/mob_0"),"short attack striking frame matches actual hit")
	await _capture("actions-02-close")
	await _physics(8)
	await _render()
	_check(_visual().sprite.frame==14,"short attack has visible follow-through")
	await _physics(30)
	_player().combat.try_reach(-1)
	await _physics(2)
	_check(_visual().sprite.frame==15 and _visual().sprite.flip_h,"long attack has separate mirrored preparation")
	await _physics(11)
	_check(_visual().sprite.frame==16,"long attack uses extended thrust pose in active phase")
	await _capture("actions-03-reach")
	await _physics(35)
	_player().combat.try_reach(1)
	await _physics(1)
	_player()._invulnerability=0
	_player().hurt(5)
	await _physics(1)
	_check(not _player().combat.is_busy() and _visual().action==&"hurt","damage cancels melee windup and shows recoil")
	WorldProgress.enter_scene(&"grassland",Vector2(1150,596))
	await _physics(8)
	WorldProgress.borrow_ability(&"mineralization")
	_check(_player().try_mineralize(),"mineral cast succeeds at actual node")
	await _physics(2)
	_check(_visual().sprite.frame==20,"mineralization shows casting gesture and crystal pulse")
	await _capture("actions-04-mineralization")
	WorldProgress.enter_scene(&"remnant_sea",Vector2(3460,596))
	await _physics(8)
	WorldProgress.borrow_ability(&"shield")
	WorldProgress.borrow_ability(&"black_pierce")
	_player().face_direction(1)
	_check(_player().try_black_pierce(),"pierce cast actually crosses dark wall")
	await _physics(2)
	_check(_visual().sprite.frame==21,"black pierce uses forward dash pose")
	await _capture("actions-05-black-pierce")
	await _physics(20)
	Input.action_press(&"eden_shield")
	await _physics(2)
	_check(_visual().sprite.frame==18,"shield starts with raising gesture")
	await _physics(8)
	_check(_visual().sprite.frame==19 and WorldProgress.shield_active,"shield holding gesture matches protected state")
	await _capture("actions-06-shield")
	Input.action_release(&"eden_shield")
	await _physics(3)
	await _render()
	_check(_visual().action!=&"shield","release exits shield pose immediately")
	WorldProgress.reveal_truth()
	await _physics(2)
	var frozen_frame:=_visual().sprite.frame
	var frozen_clock:=_visual()._clock
	await _physics(20)
	_check(_visual().sprite.frame==frozen_frame and _visual()._clock==frozen_clock,"truth choice freezes animation and effects with gameplay")
	app._truth.choice_a.pressed.emit()
	await _physics(2)
	_check(_visual().green_form and _visual().sprite.texture==HeroActionVisual.GREEN,"awakening swaps all actions to green form")
	await _capture("actions-07-green")
	var position_before:=_player().position
	_player().stats.take_damage(100)
	await _physics(25)
	_check(_visual().sprite.frame==23 and _visual().action==&"death","death reaches fallen pose after terminal simulation freeze")
	var footprint:=CarbonLedger.gross_kg
	Input.action_press(&"eden_move_right")
	await _action(&"eden_black_pierce")
	await _physics(15)
	Input.action_release(&"eden_move_right")
	_check(_player().position==position_before and CarbonLedger.gross_kg==footprint,"death visuals cannot resume movement or skill accounting")
	await _capture("actions-08-death")
	GameSession.resume_checkpoint()
	await _physics(10)
	_check(not _visual()._dead and _visual().green_form,"checkpoint resets animation while preserving awakened form")
	GameSession.return_to_menu()
	await _physics(4)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("ACTIONS: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _level() -> CampaignLevel:
	return app.get_node("LevelRoot").get_child(0)

func _player() -> CharacterBody2D:
	return _level().player

func _visual() -> HeroActionVisual:
	return _player()._art

func _physics(count: int) -> void:
	for index in count:
		if app!=null and app.get_node("LevelRoot").get_child_count()>0:
			for enemy in _level().enemies:
				if is_instance_valid(enemy): enemy.set_physics_process(false)
		await get_tree().physics_frame
	await get_tree().process_frame

func _action(action: StringName) -> void:
	Input.action_press(action)
	await _physics(2)
	Input.action_release(action)
	await _physics(1)
	if action==&"eden_absorb":
		for wait in 150:
			if WorldProgress.narrative_kind!=&"learning": break
			await _physics(1)


func _place(point: Vector2) -> void:
	_player().position=point
	_player().velocity=Vector2.ZERO
	await _physics(15)

func _capture(label: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	_check(get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/"+label+".png")==OK,"capture "+label)

func _render() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error("FAIL: "+label)
