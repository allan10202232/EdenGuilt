extends Node
## Continuous input-driven production route. No player teleports, stat edits,
## enemy disabling, receiver injection, direct damage or story-state shortcuts.
var app: Node
var level: EdenChapterLevel
var hero: EdenChapterPlayer
var checks:=0
var failures:=0
var frame_index:=0

func _ready() -> void:
	get_tree().create_timer(420).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	var preview:=preload("res://scenes/eden/play_eden.tscn").instantiate()
	add_child(preview)
	await ticks(8)
	app=preview.get_child(0)
	level=app.get_node("LevelRoot").get_child(0)
	hero=level.player
	await move_to(250)
	await jump_to(Vector2(250,2280))
	await jump_to(Vector2(490,2160))
	await jump_to(Vector2(260,2040))
	await jump_to(Vector2(220,1920))
	await move_to(350)
	await key(KEY_E)
	await ticks(150)
	check(WorldProgress.has_ability(&"shield"),"normal entrance stairs reach the Shield extraction")
	await move_to(900)
	for index in 3:
		for attempt in 4:
			if level.corridor_receivers[index].lit: break
			await wait_floor()
			var turret: EdenTurret=level.turrets[index]
			var lead: float=[0.0,0.26,0.62][index]
			if lead>0:
				while turret.countdown>lead: await ticks(1)
				Input.action_press(&"eden_jump")
				await ticks(2)
				Input.action_release(&"eden_jump")
				if index==2:
					await ticks(22)
					Input.action_press(&"eden_jump")
					await ticks(2)
					Input.action_release(&"eden_jump")
			var appeared:=false
			for frame in 240:
				for shot in get_tree().get_nodes_in_group(&"eden_projectile"):
					if shot.source==turret and not shot.reflected and shot.age<0.06: appeared=true
				if appeared: break
				await ticks(1)
			if index==0:
				Input.action_press(&"eden_jump")
				await ticks(2)
				Input.action_release(&"eden_jump")
			await hero_face(1)
			Input.action_press(&"eden3_guard")
			await ticks(14)
			Input.action_release(&"eden3_guard")
			await ticks(85)
		check(level.corridor_receivers[index].lit,"jump rhythm reflects turret light into elevated receiver %d"%(index+1))
	await move_to(1320)
	for frame in 1800:
		if not is_instance_valid(level.steward) or level.steward.shield_broken: break
		var jump_now:=false
		var parry_now:=false
		for shot in get_tree().get_nodes_in_group(&"eden_projectile"):
			if shot.source!=level.steward or shot.reflected: continue
			var dx: float=shot.position.x-hero.position.x
			if shot.wave and dx>170 and dx<225 and hero.is_on_floor(): jump_now=true
			if not shot.wave and dx>22 and dx<51 and absf(shot.position.y-hero.position.y)<25: parry_now=true
		if jump_now: Input.action_press(&"eden_jump")
		else: Input.action_release(&"eden_jump")
		if parry_now: Input.action_press(&"eden3_guard")
		else: Input.action_release(&"eden3_guard")
		await ticks(1)
	Input.action_release(&"eden_jump")
	Input.action_release(&"eden3_guard")
	check(is_instance_valid(level.steward) and level.steward.shield_broken,"normal wave evasion and timed guard break the mini-boss armor")
	await move_to(1562)
	for frame in 200:
		if not is_instance_valid(level.steward): break
		if frame%28==0: await mouse()
		await ticks(1)
	check(WorldProgress.eden_chapter.get("steward",false),"ordinary melee completes the Garden Steward encounter")
	await move_to(2225)
	await key(KEY_T)
	await ticks(80)
	check(level.current_node==5,"the actual elevator links 2F and 3F")
	await key(KEY_E)
	await ticks(150)
	check(WorldProgress.has_ability(&"black_pierce"),"processing entrance grants Dark Dash through the real extraction")
	await move_to(2120)
	await hero_face(-1)
	await key(KEY_F)
	await ticks(17)
	check(hero.position.x<2040,"normal dash input crosses the maintenance wall")
	await jump_to(Vector2(1970,1200))
	await jump_to(Vector2(1880,1060))
	await jump_to(Vector2(1890,1060))
	await hero_face(1)
	await mouse()
	await ticks(30)
	check(WorldProgress.eden_chapter.get("oren",false),"physical climb reaches Oren and a real slash cuts the conduit")
	await move_to(1850)
	await hero_face(-1)
	await key(KEY_F)
	await ticks(17)
	await move_to(1430)
	await parry_incoming(level.turrets[3],-1)
	check(level.dual_seconds>0,"normal parry charges the timed dual lock")
	await move_to(1170)
	await hero_face(-1)
	await key(KEY_F)
	await ticks(17)
	check(level.current_node==8,"timed run and phase dash reach the shaft access")
	await move_to(210)
	await wait_floor()
	for index in 5:
		await jump_to(level.vents[index].position,level.vents[index],index==2 or index==3)
	await jump_to(Vector2(505,620))
	await move_to(540)
	check(level.boss.active and level.current_node==10,"all gas relays physically lead to the final arena")
	await move_to(900)
	for index in 3: await parry_incoming(level.boss,1)
	check(level.boss.exposed>0,"ordinary parries expose the life-extraction device")
	await move_to(1030)
	await jump_to(Vector2(1030,510),level.vents[5])
	for attempt in 7:
		if level.boss.phase!=1: break
		await attack_core()
	check(level.boss.phase==2,"mineralize and aerial melee reach the exposed core")
	for frame in 2200:
		if level.boss.phase!=2: break
		var guard:=level.boss.guard
		var dx: float=guard.position.x-hero.position.x
		if guard.charge_left>0:
			direction(signf(dx))
			var incoming: bool=guard._direction*(hero.position.x-guard.position.x)>0
			if hero.dash_cooldown<=0 and ((incoming and absf(dx)<170) or (not incoming and absf(dx)>220)):
				await key(KEY_F)
		elif guard._recovery>0:
			if absf(dx)>75:
				direction(signf(dx))
				if absf(dx)>250 and hero.dash_cooldown<=0: await key(KEY_F)
			else:
				direction(0)
				await hero_face(signf(dx))
				if frame%28==0: await mouse()
		else: direction(signf(dx) if absf(dx)>140 else 0)
		await ticks(1)
	direction(0)
	check(level.boss.phase==3,"live charging guardian can be dashed through and punished after wall impact")
	await move_to(730)
	await jump_to(Vector2(730,480))
	await parry_incoming(level.boss,-1)
	check(level.boss.left_cut,"high ledge and timed parry sever the left supply")
	await reach_upper_right()
	await hero_face(signf(2080-hero.position.x))
	await mouse()
	await ticks(30)
	check(level.boss.dismantled and app._truth.visible,"full physical ascent reaches and severs the upper-right extraction lock")
	app._truth.choice_a.pressed.emit()
	await ticks(5)
	await reach_upper_right()
	await move_to(2080)
	await parry_incoming(level.turrets[level.turrets.size()-3],1)
	check(level.pods[0].released,"repeat four-skill ascent and parry release pod 1")
	await hero_face(-1)
	await key(KEY_F)
	await ticks(17)
	await move_to(1740)
	await wait_floor()
	await drop()
	await wait_floor()
	check(hero.position.y>1000 and hero.position.y<1080,"physical descent reaches the processing deck")
	await hero_face(1)
	await key(KEY_F)
	await ticks(17)
	await mouse()
	await ticks(30)
	check(level.pods[1].released,"phase into the security bay and slash its valve to rescue pod 2")
	await move_to(2070)
	await drop()
	await wait_floor()
	await move_to(2240)
	await key(KEY_T)
	await ticks(5)
	check(hero.position.y>1800,"return elevator descends to the garden")
	await jump_to(Vector2(2260,1780),null,true)
	await move_to(2240)
	await parry_incoming(level.turrets[-1],1)
	check(level.pods[2].released and CarbonLedger.rescued_people==3,"double jump, phase dash and ricochet free the third and last human")
	await drop()
	await wait_floor()
	await drop()
	await wait_floor()
	await move_to(2190)
	await key(KEY_R)
	await ticks(3)
	check(WorldProgress.eden_chapter.get("escaped",false),"party reaches 1F and returns both Eden abilities after safe descent")
	await key(KEY_T)
	await ticks(6)
	check(WorldProgress.current_scene==&"grassland","input-driven chapter exit reconnects to the previous chapter's rescue route")
	await finish()

func reach_upper_right() -> void:
	await move_to(1780)
	await jump_to(Vector2(1780,510),level.vents[7])
	await jump_to(Vector2(1930,395),level.vents[8])
	await jump_to(Vector2(2060,280),null,true)

func attack_core() -> void:
	await wait_floor()
	await key(KEY_SPACE)
	var doubled:=false
	for frame in 100:
		var dx: float=1120-hero.position.x
		direction(signf(dx) if absf(dx)>6 else 0)
		if frame==21:
			await key(KEY_SPACE)
			doubled=true
		if frame>8 and absf(hero.position.x-1200)<125 and absf(hero.position.y-360)<60:
			await hero_face(1)
			await mouse()
		if frame>15 and hero.is_on_floor(): break
		await ticks(1)
	direction(0)
	if level.boss.phase==1:
		await move_to(1030)
		await jump_to(Vector2(1030,510),level.vents[5])

func parry_incoming(source: Node2D,face: float) -> void:
	await hero_face(face)
	var before:=level.parry_flashes
	for frame in 900:
		var should_guard:=false
		for shot in get_tree().get_nodes_in_group(&"eden_projectile"):
			if shot.source==source and not shot.reflected and not shot.wave and absf(shot.position.y-hero.position.y)<26 and shot.position.distance_to(hero.position)<51:
				should_guard=true
		if should_guard: Input.action_press(&"eden3_guard")
		else: Input.action_release(&"eden3_guard")
		await ticks(1)
		if level.parry_flashes>before: break
	Input.action_release(&"eden3_guard")
	await ticks(95)
	check(level.parry_flashes>before,"timed input reflects a live incoming shot")

func jump_to(point: Vector2,vent: Node=null,phase_dash: bool=false) -> void:
	await wait_floor()
	Input.action_press(&"eden_jump")
	var doubled:=false
	var dashed:=false
	var landed:=false
	for frame in 160:
		var dx: float=point.x-hero.position.x
		direction(signf(dx) if absf(dx)>5 else 0)
		if frame==2: Input.action_release(&"eden_jump")
		if not doubled and frame>12 and hero.velocity.y>=-35 and hero.jumps_used==1:
			Input.action_press(&"eden_jump")
			doubled=true
		elif doubled: Input.action_release(&"eden_jump")
		if vent!=null and not is_instance_valid(vent.platform) and hero.position.distance_to(vent.position)<255 and hero.cooldown<=0:
			Input.action_press(&"eden3_mineral")
		else: Input.action_release(&"eden3_mineral")
		if phase_dash and not dashed and doubled and hero.position.y+22<point.y-5 and hero.dash_cooldown<=0:
			Input.action_press(&"eden3_dash")
			dashed=true
		else: Input.action_release(&"eden3_dash")
		await ticks(1)
		if frame>10 and hero.is_on_floor() and absf(hero.position.y+22-point.y)<7 and absf(hero.position.x-point.x)<80:
			landed=true
			break
	direction(0)
	for id in [&"eden_jump",&"eden3_mineral",&"eden3_dash"]: Input.action_release(id)
	await ticks(2)
	check(landed,"continuous jump to %s at %s"%[point,hero.position])

func move_to(x: float) -> void:
	for frame in 1800:
		var dx: float=x-hero.position.x
		if absf(dx)<7: break
		direction(signf(dx))
		await ticks(1)
	direction(0)
	await ticks(2)
	check(absf(hero.position.x-x)<14,"walk to %.0f at %s"%[x,hero.position])

func wait_floor() -> void:
	for frame in 180:
		if hero.is_on_floor(): return
		await ticks(1)

func drop() -> void:
	Input.action_press(&"eden3_drop")
	await key(KEY_SPACE)
	Input.action_release(&"eden3_drop")
	await ticks(20)

func hero_face(face: float) -> void:
	# A one-frame direction press is an ordinary turn, not an actor field edit.
	direction(face)
	await ticks(1)
	direction(0)

func direction(axis: float) -> void:
	Input.action_release(&"eden_move_left")
	Input.action_release(&"eden_move_right")
	if axis!=0: Input.action_press(&"eden_move_right" if axis>0 else &"eden_move_left")

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

func mouse() -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=true
	Input.parse_input_event(event)
	await ticks(1)
	event=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	Input.parse_input_event(event)
	await ticks(1)

func ticks(count: int) -> void:
	for frame in count:
		await get_tree().physics_frame
		frame_index+=1
		if GameSession.state==GameSession.State.GAME_OVER:
			check(false,"input route exhausted its actual life orbs")
	await get_tree().process_frame

func check(ok: bool,message: String) -> void:
	checks+=1
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:
		failures+=1
		print("ROUTE STOP: node=",level.current_node," hero=",hero.position," hp=",hero.health," frame=",frame_index)
		set_process(false)
		# End immediately; do not let a failed route drive the next room.
		get_tree().quit(1)

func finish() -> void:
	for id in [&"eden_move_left",&"eden_move_right",&"eden3_guard",&"eden_jump"]: Input.action_release(id)
	GameSession.return_to_menu()
	await get_tree().process_frame
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("EDEN_ROUTE: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)
