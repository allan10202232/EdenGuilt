extends Node
var app: Node
var level: Node
var checks:=0
var failures:=0
func _ready() -> void: _run.call_deferred()
func _run() -> void:
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(3)
	GameSession.sync_health(80,100)
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(5)
	level=app.get_node("LevelRoot").get_child(0)
	var actor: CharacterBody2D=level.player
	var vent: Node=level.vents[0]
	check(actor.health==80 and GameSession.health==80,"mine entrance preserves health from the previous chapter")
	check(level._life_orbs.is_visible_in_tree() and level._life_orbs.get_half_count()==8,"custom mine HUD shows five green life vessels with inherited health")
	await preload("res://tests/helpers/mine_learning.gd").acquire(level,get_tree())
	actor.position=Vector2(860,1730)
	actor.velocity=Vector2(90,-180)
	var start_velocity:=actor.velocity
	var converted: int=actor.cast_pulse()
	check(converted==1 and actor.velocity==start_velocity,"mid-air pulse does not halt momentum")
	check(is_instance_valid(vent.platform) and vent.platform.remaining==4,"gas becomes a four-second standable platform")
	check(level.sequestered==150 and CarbonLedger.stored_kg==150,"one successful pulse adds 150 kg to local and audit trackers")
	check(actor.cast_pulse()==0 and level.sequestered==150,"cooldown blocks repeated credit")
	check(level.mineralize_near(Vector2.ZERO,260)==0,"vents outside the 260px radius are unaffected")
	var duration: float=vent.platform.remaining
	level._settings.open()
	await ticks(45)
	check(vent.platform.remaining==duration and actor.cooldown==0.6,"settings freezes platform expiry and cooldown")
	level._settings.close()
	vent.platform.remaining=0.02
	await ticks(4)
	check(not is_instance_valid(vent.platform) and vent.powered,"temporary rock shatters back into active gas")
	actor.cooldown=0
	actor.position=Vector2(860,1700)
	await key(KEY_J)
	check(is_instance_valid(vent.platform) and level.sequestered==300,"J re-mineralizes an expired vent and credits a new captured batch")
	actor.mineral_landed.connect(func() -> void: set_meta("landed",int(get_meta("landed",0))+1))
	actor.position=Vector2(860,1740)
	actor.velocity=Vector2(0,50)
	actor.jumps_used=2
	await ticks(24)
	check(actor.is_on_floor() and actor.jumps_used==0 and get_meta("landed",0)>0,"landing on mineral rock restores double jump")
	var hp: int=actor.health
	actor.touch_gas(0.9)
	Input.action_press(&"eden_move_right")
	await ticks(1)
	Input.action_release(&"eden_move_right")
	check(actor.health==hp-10 and absf(actor.velocity.x)<=143.1,"toxic gas damages and slows the player")
	check(level._life_orbs.get_half_count()==7 and GameSession.health==actor.health,"gas damage immediately removes half a visible life vessel")
	var stored_before: float=level.sequestered
	level.activate_stage(2)
	actor.position=Vector2(900,2055)
	actor.velocity=Vector2(0,300)
	await ticks(18)
	check(actor.position.distance_to(level.checkpoint_position)<6 and actor.respawn_seconds==0,"acid respawns at the current checkpoint within 0.3 seconds")
	check(level.sequestered==stored_before and actor.health==50,"acid keeps captured carbon and deducts one orb from injured health")
	check(level._life_orbs.get_half_count()==5 and GameSession.health==50,"acid retry preserves shared health and the exact orb halves")
	actor.dissolve()
	check(level._life_orbs.get_half_count()==3 and GameSession.state==GameSession.State.PLAYING,"another acid fall removes another whole orb")
	await ticks(18)
	check(level._life_orbs.get_half_count()==3 and actor.health==30,"fast retry never refills the life vessels")
	level.bridge.trigger()
	await ticks(90)
	check(level.bridge.bodies[0].get_child(0).disabled and not level.bridge.bodies[3].get_child(0).disabled,"bridge collapses from left to right rather than all at once")
	level.bridge.reset()
	await ticks(2)
	check(level.bridge.collapsed==0 and not level.bridge.bodies[0].get_child(0).disabled,"checkpoint retry restores the collapsing bridge")
	level.weight_switch.crate.position=level.weight_switch.switch_offset+Vector2(0,-24)
	await ticks(8)
	check(level.weight_switch.pressed and level.shaft_vents.all(func(node: Node) -> bool: return node.powered),"crate weight activates all shaft and relay vents")
	level.weight_switch.crate.position=Vector2(0,-24)
	await ticks(8)
	check(not level.weight_switch.pressed and not level.shaft_vents[0].powered,"removing weight closes the gas valve")
	actor.position=Vector2(2810,698)
	await key(KEY_T)
	await ticks(3)
	check(level.lever.active and level._trapdoor.get_child(0).disabled,"lever opens the drop hatch")
	check(level.cliff_vents.all(func(node: Node) -> bool: return node.powered),"lever routes gas to every narrow cliff relay")
	# Stage triggers cannot bypass prerequisites or clear the mine early.
	level.activate_stage(8)
	check(level.current_stage==2,"checkpoint sequence rejects skipping directly to the exit")
	level.finish()
	check(not level._cleared,"exit cannot clear an unfinished route")
	actor.position=Vector2(550,1778)
	actor.velocity=Vector2.ZERO
	level.vents[0].reset()
	await ticks(6)
	Input.action_press(&"eden_move_right")
	for frame in 24:
		await ticks(1)
		if not actor.is_on_floor(): break
	Input.action_release(&"eden_move_right")
	Input.action_press(&"eden_jump")
	await ticks(1)
	Input.action_release(&"eden_jump")
	check(actor.velocity.y< -300 and actor.jumps_used==1,"coyote jump works immediately after leaving an edge")
	# Test buffering while the double jump is already spent.
	actor.position=Vector2(300,1740)
	actor.velocity=Vector2(0,300)
	actor.jumps_used=2
	await ticks(4)
	Input.action_press(&"eden_jump")
	await ticks(1)
	Input.action_release(&"eden_jump")
	await ticks(7)
	check(actor.velocity.y< -250,"jump buffered just before landing launches after contact")
	# Every stage has a supported, repeatable fast-respawn checkpoint.
	level.weight_switch.crate.position=level.weight_switch.switch_offset+Vector2(0,-24)
	await ticks(5)
	for stage in range(3,9):
		actor._set_health(100) # Isolate each checkpoint geometry from the five-fall life limit.
		level.activate_stage(stage)
		actor.position=Vector2(900,2055)
		actor.velocity=Vector2(0,300)
		await ticks(18)
		check(actor.position.distance_to(level.CHECKPOINTS[stage-1])<6,"acid recovers stage %d checkpoint"%stage)
	var saved_carbon: float=level.sequestered
	app._load_level()
	await ticks(6)
	level=app.get_node("LevelRoot").get_child(0)
	check(level.current_stage==8 and level.lever.active and level.weight_switch.pressed and level.sequestered==saved_carbon,"reload restores stage, puzzle mechanisms and sequestration without duplicate credit")
	GameSession.return_to_menu()
	await ticks(3)
	GameSession.start_run()
	await ticks(3)
	check(WorldProgress.mine_challenge.is_empty() and CarbonLedger.stored_kg==0,"new run clears mine progression and captured-carbon totals")
	GameSession.return_to_menu()
	await ticks(3)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("MINE MECHANICS: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)
func ticks(count: int) -> void:
	for index in count: await get_tree().physics_frame
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
