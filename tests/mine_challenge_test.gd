extends Node
var app: Node
var level: Node2D
var checks:=0
var failures:=0
var deaths:=0
func _ready() -> void:
	get_tree().create_timer(180).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()
func _run() -> void:
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(5)
	# Both complete input routes have their own suites. Stage the actor on the
	# first chapter's last safe island, then cross its real exit with input.
	var scrapyard: Node2D=app.get_node("LevelRoot").get_child(0)
	check(scrapyard is ScrapyardParkourLevel and scrapyard.definition.width==9600,"campaign retains main's six-section scrapyard")
	WorldProgress.borrow_ability(&"double_jump")
	var first_exit: Vector2=CampaignLevels.definition(&"lone_tree").exit
	scrapyard.player.position=first_exit-Vector2(50,24)
	scrapyard.player.velocity=Vector2.ZERO
	await ticks(2)
	direction(1)
	for frame in 40:
		await ticks(1)
		if WorldProgress.current_scene==&"grassland": break
	direction(0)
	await ticks(8)
	check(WorldProgress.current_scene==&"grassland","real scrapyard exit loads the production eight-stage mine")
	level=app.get_node("LevelRoot").get_child(0)
	check(level.vents.size()==25,"25 gas vents include every mineralizable relay; no permanent climbing footholds")
	check(not app._hud.visible and level.current_stage==1,"campaign loads the new mine with its dedicated HUD")
	check(level.player.speed==260 and level.player.gravity==980 and level.player.jump_velocity==-420 and level.player.double_jump_velocity==-390,"requested movement parameters are active")
	check(level.shaft_vents.size()==11 and level.cliff_vents.size()==11,"six shaft / four cliff primary plumes have gas relays")
	check(level.cliff_vents.all(func(vent: Node) -> bool: return vent.width==72 and vent.duration==2.8),"cliff platforms are narrow and short lived")
	check(level.vents[0].platform==null and not level.shaft_vents[0].powered,"shaft is initially closed and gas begins hazardous")
	await capture("mine-stage1-start")
	await move_to(420)
	await key(KEY_E)
	for frame in 155: await ticks(1)
	check(WorldProgress.has_ability(&"mineralization"),"entrance mining extraction unlocks mineralization with ordinary input")
	await move_to(560)
	await jump_to(Vector2(860,1800),level.vents[0])
	check(level.pulse_count>0 and level.sequestered==level.pulse_count*150,"successful pulses sequester exactly 150 kg each")
	check(level.current_stage==2,"first bridge advances stage 2")
	await move_to(1595)
	await jump_to(Vector2(1650,1670),level.vents[1])
	await jump_to(Vector2(1520,1540),level.vents[2])
	await jump_to(Vector2(1430,1450))
	check(level.current_stage==3,"all three gas-made approaches reach the upper crate deck")
	# Approach the crate from the left so the actual collision pushes it onto the plate.
	await jump_to(Vector2(1200,1450))
	await move_to(1660)
	await ticks(8)
	check(level.weight_switch.pressed and level.shaft_vents[0].powered,"pushing the real crate opens the shaft valves")
	await jump_to(Vector2(1880,1840))
	check(level.current_stage==4,"shaft checkpoint activates after the crate puzzle")
	for vent in level.shaft_vents:
		await jump_to(vent.position,vent)
	await jump_to(Vector2(2540,720))
	check(level.current_stage==5,"normal input reaches the top of all six shaft tiers")
	await capture("mine-stage5-top")
	await move_to(2810)
	await key(KEY_T)
	check(level.lever.active and level.cliff_vents[0].powered,"T redirects pipes, powers distant vents and opens the descent hatch")
	await ticks(110)
	check(level.current_stage==6,"descent reaches the bridge checkpoint")
	await move_to(4350,true)
	await jump_to(Vector2(4500,1700))
	check(level.current_stage==7 and level.bridge.collapsed>0,"full speed movement crosses the collapsing bridge and reaches stage 7")
	await capture("mine-stage7-cliff")
	for vent in level.cliff_vents:
		await jump_to(vent.position,vent)
	await jump_to(Vector2(5340,400))
	check(level.current_stage==8,"all temporary narrow ledges lead to the summit")
	await move_to(5440)
	await ticks(4)
	check(level._cleared and WorldProgress.narrative_kind==&"mine_clear","exit opens the stage-clear summary")
	check(level.sequestered==level.pulse_count*150 and CarbonLedger.stored_kg>=level.sequestered,"summary carbon is in the campaign audit ledger")
	await capture("mine-stage8-clear")
	check(deaths==0,"complete input-driven route has zero acid deaths")
	level.continue_to_eden()
	await ticks(8)
	check(WorldProgress.current_scene==&"remnant_sea" and app.get_node("LevelRoot").get_child(0).name=="EdenCity","summary continues to Eden City")
	check(app.get_node("LevelRoot").get_child(0).chapter_status.is_visible_in_tree(),"shared mine-style HUD remains visible in Eden City")
	# White-box story setup, then physically walk the new mine's return route.
	# Actual boss dismantling and three separate rescues belong to eden_chapter_test.
	WorldProgress.eden_chapter["dismantled"]=true
	WorldProgress.eden_chapter["rescued"]=[1,2,3]
	WorldProgress.reveal_truth()
	app._truth.choice_a.pressed.emit()
	WorldProgress.enter_scene(&"grassland",Vector2(3900,450))
	await ticks(8)
	level=app.get_node("LevelRoot").get_child(0)
	check(level._returning and level.current_stage==8,"A route enters the mine at its new summit")
	await move_to(280)
	check(level.player.position.y>1700,"residents' permanent return ramp reaches the starting oasis")
	await key(KEY_R)
	check(WorldProgress.repaired_regions.has(&"grassland") and not WorldProgress.has_ability(&"mineralization"),"R restores the mine and returns mineralization")
	direction(-1)
	for frame in 100:
		await ticks(1)
		if WorldProgress.current_scene==&"lone_tree": break
	direction(0)
	await ticks(6)
	check(WorldProgress.current_scene==&"lone_tree" and app._hud.visible,"return exit reconnects Junkyard with the normal HUD")
	var returned: Node2D=app.get_node("LevelRoot").get_child(0)
	check(returned is ScrapyardParkourLevel and WorldProgress.spawn_position==Vector2(9360,296) and returned.player.position.x>9200 and returned.player.position.y<380,"mine return uses the named exit-island spawn and held movement continues along the rescue walkway")
	check(returned._rescue_path and returned.player.is_on_floor(),"returning player stands on the continuous rescue walkway")
	var returned_deaths:=WorldProgress.scrapyard_deaths
	await ticks(30)
	check(WorldProgress.current_scene==&"lone_tree" and WorldProgress.scrapyard_deaths==returned_deaths,"mine return neither bounces back into the mine nor falls into acid")
	GameSession.return_to_menu()
	await ticks(3)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("MINE CHALLENGE: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)
func move_to(x: float,hop: bool=false) -> void:
	for frame in 1800:
		var dx: float=x-level.player.position.x
		if absf(dx)<8 or level._cleared: break
		direction(signf(dx))
		if hop and frame%90==0: Input.action_press(&"eden_jump")
		elif hop and frame%90==24: Input.action_release(&"eden_jump")
		elif hop and frame%90==26: Input.action_press(&"eden_jump")
		elif hop and frame%90==28: Input.action_release(&"eden_jump")
		await ticks(1)
		if level.player.respawn_seconds>0:
			deaths+=1
			break
	direction(0)
	Input.action_release(&"eden_jump")
	await ticks(2)
	check(level._cleared or absf(level.player.position.x-x)<14,"walk to x=%.0f at %s"%[x,level.player.position])
func jump_to(point: Vector2,vent: Node=null) -> void:
	# Wait for the previous landing; do not teleport or alter velocity.
	for frame in 80:
		if level.player.is_on_floor(): break
		await ticks(1)
	Input.action_press(&"eden_jump")
	var landed:=false
	var doubled:=false
	for frame in 200:
		var dx: float=point.x-level.player.position.x
		direction(signf(dx) if absf(dx)>5 else 0)
		if frame==2: Input.action_release(&"eden_jump")
		if not doubled and frame>10 and level.player.velocity.y>=-35 and level.player.jumps_used==1:
			Input.action_press(&"eden_jump")
			doubled=true
		elif doubled: Input.action_release(&"eden_jump")
		if vent!=null and not is_instance_valid(vent.platform) and level.player.position.distance_to(vent.position)<255 and level.player.cooldown<=0:
			Input.action_press(&"mine_pulse")
		else: Input.action_release(&"mine_pulse")
		await ticks(1)
		if frame>10 and level.player.is_on_floor() and absf(level.player.position.y+22-point.y)<6 and absf(dx)<maxf(20,float(vent.width)/2 if vent!=null else 30):
			landed=true
			break
		if level.player.respawn_seconds>0:
			deaths+=1
			break
	direction(0)
	Input.action_release(&"eden_jump")
	Input.action_release(&"mine_pulse")
	await ticks(2)
	check(landed,"jump to %s at %s"%[point,level.player.position])
	if not landed:
		print("ROUTE STOP: stage=",level.current_stage," jumps=",level.player.jumps_used," cooldown=",level.player.cooldown)
		GameSession.return_to_menu()
		await ticks(3)
		SoundManager.stop_sfx()
		OS.delay_msec(150)
		get_tree().quit(1)
		await get_tree().process_frame
func direction(axis: float) -> void:
	Input.action_release(&"eden_move_left")
	Input.action_release(&"eden_move_right")
	if axis>0: Input.action_press(&"eden_move_right")
	elif axis<0: Input.action_press(&"eden_move_left")
func ticks(count: int) -> void:
	for index in count: await get_tree().physics_frame
	# Scene navigation now includes a visible fade and a short re-entry lock.
	while WorldProgress.scene_transition_active or WorldProgress.transition_rearm_seconds>0:
		await get_tree().physics_frame
	await get_tree().process_frame
func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await ticks(2)
	event=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	Input.parse_input_event(event)
	await ticks(2)
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1
	print(("PASS: " if value else "FAIL: ")+message)
func capture(title: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/mine")
	get_viewport().get_texture().get_image().save_png("res://test-output/mine/"+title+".png")
