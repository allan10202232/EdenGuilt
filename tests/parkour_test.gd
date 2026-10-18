extends Node
## The route driver uses real input and collision; only isolated mechanism cases teleport.
var app: Node
var checks := 0
var failures := 0
var screenshots := false

func _ready() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	get_tree().create_timer(360).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("en",false)
	app = preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(10)
	check(level() is ScrapyardParkourLevel and level().definition.width == 9600, "actual campaign starts the six-section level")
	check(player().move_speed == 260 and player().gravity == 980 and player().jump_velocity == -420 and player().double_jump_velocity == -380, "requested first-chapter physics")
	check(player().coyote_time == 0.12 and player().jump_buffer_time == 0.12,"120 ms grace and input buffer")
	check(level()._checkpoints.size()==6 and level().crushers.size()==2,"six section checkpoints and two crushers")
	check(level().platforms.filter(func(p: ScrapPlatform) -> bool: return p is MagnetLift).size()==5,"five moving magnet platforms")
	check(level().platforms.filter(func(p: ScrapPlatform) -> bool: return p is ConveyorBelt).size()==3,"three conveyor prefabs")
	await capture("01-start")
	player().position = Vector2(230,476)
	await ticks(3)
	Input.action_press(&"eden_absorb")
	await ticks(1)
	Input.action_release(&"eden_absorb")
	await ticks(150)
	check(WorldProgress.has_ability(&"double_jump") and level().oases[&"double_jump"].vitality==0,"real oasis interaction unlocks air jump")
	player().position=Vector2(355,476)
	player().velocity=Vector2.ZERO
	await ticks(3)
	Input.action_press(&"eden_move_right")
	for frame in 12:
		await ticks(1)
		if not player().is_on_floor(): break
	var grace_carbon := CarbonLedger.gross_kg
	Input.action_press(&"eden_jump")
	await ticks(1)
	Input.action_release(&"eden_jump")
	check(player().velocity.y<0 and player()._jumps_used==1 and CarbonLedger.gross_kg==grace_carbon,"coyote jump after walking off is a free first jump")
	await ticks(24)
	Input.action_press(&"eden_jump")
	await ticks(1)
	Input.action_release(&"eden_jump")
	check(is_equal_approx(player().velocity.x,299) and player().velocity.y<0 and player()._jump_flash>0,"air jump resets vertical motion and emits the 1.15x directional burst")
	Input.action_release(&"eden_move_right")
	await ticks(18)
	check(player()._air_boost_left==0,"horizontal air boost expires")
	player().position=Vector2(180,457)
	player().velocity=Vector2(0,200)
	player()._jumps_used=2
	player()._coyote=0
	await ticks(1)
	Input.action_press(&"eden_jump")
	await ticks(1)
	Input.action_release(&"eden_jump")
	await ticks(7)
	check(player().velocity.y<0 and player()._jumps_used==1,"a jump buffered just before landing executes on contact")
	var old: int = WorldProgress.scrapyard_deaths
	for index in 6:
		# Independent checkpoint-support cases; depletion is covered by the shared
		# chapter-consistency suite instead of ending this fixture after five falls.
		player().stats.heal(player().stats.max_health)
		player().position = ScrapyardLayout.SECTIONS[index].spawn
		player().velocity = Vector2.ZERO
		await ticks(5)
		check(level().current_section==index,"section %d checkpoint activates" % (index+1))
		var start_frame := Engine.get_physics_frames()
		player().position.y = 910
		await ticks(2)
		check(GameSession.state==GameSession.State.PLAYING and player().position.distance_to(ScrapyardLayout.SECTIONS[index].spawn)<10,"toxic drop instantly respawns in section %d" % (index+1))
		check(Engine.get_physics_frames()-start_frame <= 18 and WorldProgress.scrapyard_deaths==old+index+1,"one counted death within 0.3 s")
		await ticks(14)
	# Verify collapse telegraph, collision removal, independent return timer.
	var platform := level().platforms[0] as TimedCollapsePlatform
	player().position = platform.global_position-Vector2(0,24)
	player().velocity = Vector2.ZERO
	await ticks(4)
	check(platform.triggered and not platform.fallen,"stepping on junk starts a visible warning")
	await ticks(29)
	check(platform.fallen and platform.shape_node.disabled,"collapse removes collision after warning")
	player().position = Vector2(230,476)
	player().velocity = Vector2.ZERO
	await ticks(155)
	check(not platform.fallen and not platform.shape_node.disabled,"collapse respawns after 2.5 s")
	# Conveyor affects grounded motion without input; jump escapes it.
	var belt := level().platforms.filter(func(p: ScrapPlatform) -> bool: return p is ConveyorBelt)[1] as ConveyorBelt
	player().position = belt.position-Vector2(0,24)
	player().velocity = Vector2.ZERO
	await ticks(4)
	await ticks(2)
	check(is_equal_approx(player().velocity.x,-110),"reverse conveyor adds -110 px/s grounded motion")
	Input.action_press(&"eden_jump")
	await ticks(3)
	Input.action_release(&"eden_jump")
	await ticks(2)
	check(player().velocity.y<0 and is_zero_approx(player().velocity.x),"airborne player escapes conveyor force")
	await crusher_safety_cases()
	# Restart for a continuous route with every hazard running.
	GameSession.return_to_menu()
	await ticks(3)
	GameSession.start_run()
	await ticks(10)
	player().position=Vector2(230,476)
	await ticks(4)
	Input.action_press(&"eden_absorb")
	await ticks(1)
	Input.action_release(&"eden_absorb")
	await ticks(150)
	await run_route(false)
	check(WorldProgress.current_scene==&"grassland","six-section physical route exits into the production mine")
	if WorldProgress.current_scene==&"grassland":
		check(level().vents.size()==25 and player().speed==260 and player().gravity==980,"mine keeps its eight-stage gas route and independent movement profile")
	# Return safety is a separate contract: no air-jump or hazard timings required.
	WorldProgress.core_reversed=true
	WorldProgress.returning=true
	CarbonLedger.rescued_people=3
	if WorldProgress.current_scene!=&"lone_tree":
		WorldProgress.enter_scene(&"lone_tree",Vector2(9400,296))
	await ticks(10)
	check(level()._rescue_path and level().crushers.all(func(c: HydraulicCrusher) -> bool: return c.retired),"return journey builds an uninterrupted rescue walkway")
	await capture("08-rescue-path")
	var prior_deaths := WorldProgress.scrapyard_deaths
	Input.action_press(&"eden_move_left")
	for frame in 2300:
		if player().position.x < 230: break
		await ticks(1)
	Input.action_release(&"eden_move_left")
	check(player().position.x<240 and WorldProgress.scrapyard_deaths==prior_deaths,"entire return walkway works with walking alone")
	Input.action_press(&"eden_return")
	await ticks(2)
	Input.action_release(&"eden_return")
	check(WorldProgress.route_open(&"double_jump") and not WorldProgress.has_ability(&"double_jump"),"R at oasis returns air jump after community repairs")
	GameSession.return_to_menu()
	await ticks(4)
	GameSession.start_run()
	await ticks(10)
	WorldProgress.borrow_ability(&"double_jump")
	# Isolate the optional route from checkpoint 4, without teleporting between jumps.
	player().position = Vector2(4470,496)
	player().velocity = Vector2.ZERO
	await ticks(4)
	var lift: ScrapPlatform = level().platforms.filter(func(p: ScrapPlatform) -> bool: return p is MagnetLift)[0]
	var upper_score := GameSession.score
	var upper_stored := CarbonLedger.stored_kg
	await leap(Vector2.ZERO,lift)
	for frame in 144:
		if lift.position.y<250: break
		await ticks(1)
	for point: Vector2 in ScrapyardLayout.UPPER:
		await leap(point)
		if point.x==5580:
			check(GameSession.score==upper_score and CarbonLedger.stored_kg==upper_stored and level().find_children("RecoveredBiochar","Area2D",true,false).is_empty(),"upper route has no coin-style pickup, free score or storage reward")
	await capture("09-upper-route")
	var reward_gross := CarbonLedger.gross_kg
	level().respawn_player()
	await ticks(14)
	check(CarbonLedger.stored_kg==upper_stored and CarbonLedger.gross_kg==reward_gross,"death cannot fabricate pickup rewards or roll back carbon history")
	await finish()

func crusher_safety_cases() -> void:
	player().position=Vector2(6270,496)
	player().velocity=Vector2.ZERO
	await ticks(5)
	player().set_physics_process(false)
	var crusher: HydraulicCrusher=level().crushers[0]
	crusher.reset_hazard()
	var starts: Array[int]=[]
	var prior_phase:=crusher.phase()
	var safe_rest_frames:=0
	for frame in 310:
		await ticks(1)
		if crusher.phase()==1 and prior_phase!=1: starts.append(Engine.get_physics_frames())
		if crusher.phase()==4 and is_equal_approx(crusher.head_y,110): safe_rest_frames+=1
		prior_phase=crusher.phase()
	check(starts.size()==2 and abs(starts[1]-starts[0]-270)<=1,"successive slams are 4.5 s apart, twice the old interval")
	check(safe_rest_frames>=130,"crusher waits fully retracted for another 2.25 s")
	var deaths:=WorldProgress.scrapyard_deaths
	var health:=GameSession.health
	# Hold the real piston at the bottom, then move horizontally into each side.
	crusher.clock=0.78
	crusher.head_y=430
	player().position=Vector2(6790,535)
	await ticks(1)
	player().position.x=6751
	await ticks(3)
	check(WorldProgress.scrapyard_deaths==deaths and GameSession.health==health,"right side and edge of tooth row do not hurt on horizontal contact")
	crusher.clock=0.78
	player().position=Vector2(6590,480)
	await ticks(1)
	player().position.x=6629
	await ticks(3)
	check(WorldProgress.scrapyard_deaths==deaths and GameSession.health==health,"left side of crusher body is harmless")
	crusher.clock=0.78
	player().position=Vector2(6690,480)
	await ticks(3)
	check(WorldProgress.scrapyard_deaths==deaths,"body overlap above the teeth is harmless")
	# Tangential movement along the exact tooth height must not count as a hit.
	crusher.clock=0.78
	player().position=Vector2(6800,564)
	await ticks(1)
	player().position.x=6690
	await ticks(2)
	check(WorldProgress.scrapyard_deaths==deaths,"side movement exactly along the bottom plane is harmless")
	# Rising into the underside during the bottom hold is a real tooth collision.
	crusher.clock=0.78
	player().position=Vector2(6690,576)
	await ticks(1)
	player().position.y=550
	await ticks(1)
	check(WorldProgress.scrapyard_deaths==deaths+1,"jumping into the underside hits only the tooth face")
	await ticks(15)
	deaths=WorldProgress.scrapyard_deaths
	player().position=Vector2(6690,496)
	crusher.clock=0.49
	crusher.head_y=110
	await ticks(12)
	check(WorldProgress.scrapyard_deaths==deaths+1 and GameSession.state==GameSession.State.PLAYING,"fast downward tooth sweep still respawns a player standing underneath")
	await ticks(15)
	deaths=WorldProgress.scrapyard_deaths
	crusher.clock=1.08
	crusher.head_y=430
	player().position=Vector2(6690,540)
	await ticks(3)
	check(WorldProgress.scrapyard_deaths==deaths,"retraction cannot damage a player entering the opening")
	player().position=Vector2(6270,496)
	player().velocity=Vector2.ZERO
	player().set_physics_process(true)
	await ticks(3)
	await capture("10-restyled-crushers")

func route_driver() -> Node:
	var driver := preload("res://tests/helpers/scrapyard_route.gd").new()
	driver.app = app
	driver.report = check
	driver.shots = capture
	add_child(driver)
	return driver

func run_route(upper: bool) -> void:
	var driver := route_driver()
	await driver.run(upper)
	driver.queue_free()

func leap(point: Vector2, moving: ScrapPlatform = null) -> void:
	var driver := route_driver()
	await driver.leap(point,moving)
	driver.queue_free()

func level() -> Node2D: return app.get_node("LevelRoot").get_child(0)
func player() -> CharacterBody2D: return level().player
func ticks(count: int) -> void:
	for frame in count: await get_tree().physics_frame
	await get_tree().process_frame
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS " if ok else "FAIL ")+message)
func capture(id: String) -> void:
	if not screenshots: return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/parkour-"+id+".png")
func finish() -> void:
	GameSession.return_to_menu()
	await ticks(4)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("PARKOUR: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
