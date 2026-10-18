extends Node
## Reproduce the reported stage-7 ledge with stage-5 HUD / unpowered cliff.
var app: Node
var level: Node2D
var checks:=0
var failures:=0

func _ready() -> void:
	get_tree().create_timer(60).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("en",false)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(5)
	WorldProgress.borrow_ability(&"double_jump")
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(8)
	level=app.get_node("LevelRoot").get_child(0)
	await preload("res://tests/helpers/mine_learning.gd").acquire(level,get_tree())
	for stage in range(2,6): level.activate_stage(stage)
	check(level.current_stage==5 and not level.lever.active and level.cliff_vents.all(func(vent: Node) -> bool: return not vent.powered),"unvisited cliff initially awaits the upper gas control")
	level.activate_stage(7)
	check(level.current_stage==5,"remote calls still cannot skip the bridge before reaching the cliff")
	# Exactly the screenshot: walk-off route reaches the cliff after missing the
	# upper lever / bridge checkpoint. Only physical entry may repair that state.
	level.player.position=Vector2(4500,1678)
	level.player.velocity=Vector2.ZERO
	level.player.get_node("Camera2D").reset_smoothing()
	await ticks(8)
	check(level.current_stage==7 and level.lever.active,"entering the actual cliff recovers missed stage 6 and gas routing")
	check(level.cliff_vents.all(func(vent: Node) -> bool: return vent.powered and vent._particles.emitting),"all eleven cliff plumes visibly emit after recovery")
	check(level._stage_label.text.begins_with("7 / 8") and level.checkpoint_position==Vector2(4500,1678),"HUD and safe respawn agree with the visible stage-seven ledge")
	await ticks(35)
	await capture()
	# Repeated real interaction must not turn an already opened route off.
	level.player.position=Vector2(2810,698)
	level.player.velocity=Vector2.ZERO
	await ticks(3)
	await key(KEY_T)
	check(level.lever.active,"T leaves the opened gas supply latched on")
	await key(KEY_T)
	check(level.lever.active and level.cliff_vents.all(func(vent: Node) -> bool: return vent.powered),"repeated T cannot disable the cliff supply")
	await mouse()
	check(level.lever.active,"a melee click next to the lever cannot close the supply")
	await mouse()
	check(level.lever.active,"repeated melee clicks cannot close the supply either")
	level.player.position=Vector2(4500,1678)
	level.player.velocity=Vector2.ZERO
	await ticks(4)
	var before: float=level.sequestered
	await key(KEY_C)
	check(is_instance_valid(level.cliff_vents[0].platform) and level.sequestered==before+150,"the restored plume can actually be mineralized into the first climbing ledge")
	var hp: int=level.player.health
	level.player.position.y=2090
	await ticks(18)
	check(level.player.health==hp-20 and level.player.position.distance_to(Vector2(4500,1678))<6,"fall keeps the stage-seven checkpoint and the existing one-orb penalty")
	check(level.cliff_vents.all(func(vent: Node) -> bool: return vent.powered and vent._particles.emitting),"fast retry restores all cliff gas instead of stranding the player")
	level.player._set_health(20)
	level.player.position.y=2090
	await ticks(4)
	check(GameSession.state==GameSession.State.GAME_OVER,"the final vessel still ends the run")
	GameSession.resume_checkpoint()
	await ticks(10)
	level=app.get_node("LevelRoot").get_child(0)
	check(level.current_stage==7 and level.lever.active and level.cliff_vents.all(func(vent: Node) -> bool: return vent.powered),"Game Over continue preserves the open supply and cliff checkpoint")
	WorldProgress.core_reversed=true
	WorldProgress.returning=true
	app._load_level()
	await ticks(8)
	level=app.get_node("LevelRoot").get_child(0)
	level.player.position=Vector2(4500,1678)
	await ticks(5)
	check(level._returning and level.cliff_vents.all(func(vent: Node) -> bool: return not vent.powered),"the repaired return journey keeps its gas shut off")
	GameSession.return_to_menu()
	await ticks(4)
	GameSession.start_run()
	await ticks(5)
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(7)
	level=app.get_node("LevelRoot").get_child(0)
	check(level.current_stage==1 and not level.lever.active and level.cliff_vents.all(func(vent: Node) -> bool: return not vent.powered),"new run restores the original first-visit progression")
	GameSession.return_to_menu()
	await ticks(5)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("MINE SUPPLY: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func ticks(count: int) -> void:
	for frame in count: await get_tree().physics_frame
	# Scene navigation now includes a visible fade and a short re-entry lock.
	while WorldProgress.scene_transition_active or WorldProgress.transition_rearm_seconds>0:
		await get_tree().physics_frame
	await get_tree().process_frame

func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await ticks(2)
	event=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	Input.parse_input_event(event)
	await ticks(2)

func mouse() -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=true
	Input.parse_input_event(event)
	await ticks(2)
	event=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	Input.parse_input_event(event)
	await ticks(2)

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)

func capture() -> void:
	if "--screenshots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/mine-cliff-supply-recovered.png")
