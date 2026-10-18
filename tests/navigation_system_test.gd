extends Node
var app: Node2D
var hero: EdenChapterPlayer
var checks:=0
var failures:=0
var frames:=0

func _ready() -> void:
	get_tree().create_timer(100).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	app=preload("res://scenes/tests/navigation_test_room.tscn").instantiate()
	add_child(app)
	await ticks(12)
	hero=app.player
	var identity:=hero.get_instance_id()
	hero.hurt()
	var health:=GameSession.health
	var abilities: Dictionary=WorldProgress._abilities.duplicate()
	check(health==90,"test uses the original production damage contract")
	await place(Vector2(1340,578))
	Input.action_press(&"eden_move_right")
	for index in 30:
		await ticks(1)
		if app.transitions.busy: break
	Input.action_release(&"eden_move_right")
	check(app.transitions.busy and not WorldProgress.can_play(),"right edge starts fade and locks controls")
	check(not app.request_room_transition({"target_scene":app.ROOM_B}),"duplicate transitions are rejected")
	var before:=hero.position
	var clock:=GameSession.elapsed_seconds
	GameSession.sync_health(0,100)
	GameSession.sync_score(999)
	await ticks(3)
	check(hero.position.distance_to(before)<.1,"player remains still during fade-out")
	check(GameSession.elapsed_seconds==clock and GameSession.health==health and GameSession.score==0,"fade locks the game clock and rejects stale stat or death signals")
	await settle()
	check(app.room_path==app.ROOM_B and absf(hero.position.x-90)<1,"right edge resolves the opposite west SpawnPoint")
	check(hero.get_instance_id()==identity and get_tree().get_nodes_in_group(&"player").size()==1,"room switches retain one existing player and camera")
	check(GameSession.health==health and WorldProgress._abilities==abilities,"life and skills survive room switches")
	check(app.transitions._black.color.a==0 and not app.transitions._black.visible,"screen finishes fully visible without a leftover overlay")
	await place(Vector2(55,578))
	Input.action_press(&"eden_move_left")
	for index in 30:
		await ticks(1)
		if app.transitions.busy: break
	Input.action_release(&"eden_move_left")
	await settle()
	check(app.room_path==app.ROOM_A and absf(hero.position.x-1310)<1,"left edge returns to the original room's east entrance")
	await place(Vector2(400,578))
	await action(&"eden_talk")
	await settle()
	check(app.room_path==app.ROOM_B and absf(hero.position.x-520)<1,"T enters the door and uses its named destination")
	await place(Vector2(400,578))
	await action(&"eden_talk")
	await settle()
	check(app.room_path==app.ROOM_A and absf(hero.position.x-520)<1,"door supports a round trip")
	check(app.transitions.history.is_empty(),"automatic return consumes its remembered entrance instead of growing a loop")
	check(not app.request_room_transition({"target_scene":"res://missing-room.tscn"}) and not app.transitions.busy,"an invalid destination cannot lock or black out the game")
	# The same zone handles vertical exits; only the entry direction changes.
	await place(Vector2(600,578))
	var upper:=TransitionZone.new()
	upper.position=Vector2(600,470)
	upper.zone_size=Vector2(100,44)
	upper.target_scene=app.ROOM_B
	upper.target_spawn_id=&"west"
	upper.entry_direction=Vector2.UP
	app.room.add_child(upper)
	await action(&"eden_jump")
	for index in 30:
		await ticks(1)
		if app.transitions.busy: break
	await ticks(3)
	check(app.transitions.busy and hero._camera.position.y< -70,"jumping into a top exit produces a small upward camera lead")
	await settle()
	check(app.room_path==app.ROOM_B and absf(hero.position.x-90)<1,"top exit uses its configured destination SpawnPoint")
	await place(Vector2(700,540))
	var lower:=TransitionZone.new()
	lower.position=Vector2(700,580)
	lower.zone_size=Vector2(100,44)
	lower.target_scene=app.ROOM_A
	lower.target_spawn_id=&"door"
	lower.entry_direction=Vector2.DOWN
	app.room.add_child(lower)
	for index in 30:
		await ticks(1)
		if app.transitions.busy: break
	await settle()
	check(app.room_path==app.ROOM_A and absf(hero.position.x-520)<1,"falling into a bottom exit supports a downward room transition")
	var original_room: Node=app.room
	app.request_room_transition({"target_scene":app.ROOM_B,"target_spawn_id":&"west"})
	await ticks(3)
	app.transitions.cancel()
	await ticks(50)
	check(app.room==original_room and WorldProgress.can_play() and app.transitions._black.color.a==0,"cancelling a fade prevents stale loading and restores controls and visibility")
	var lift: OpenElevator=app.elevator
	await place(Vector2(800,578))
	check(lift.is_rider(hero),"the real collision deck supports the standing actor")
	await action(&"eden_talk")
	check(lift.state==OpenElevator.State.MOVING_UP,"T starts an upward journey")
	var max_gap:=0.0
	var camera_step:=0.0
	var previous_camera:=hero._camera.get_screen_center_position()
	for index in 260:
		await ticks(1)
		max_gap=maxf(max_gap,absf(hero.global_position.y+22-lift.platform.global_position.y))
		var camera_point:=hero._camera.get_screen_center_position()
		camera_step=maxf(camera_step,camera_point.distance_to(previous_camera))
		previous_camera=camera_point
		if not lift.is_moving(): break
	check(lift.state==OpenElevator.State.IDLE_TOP and lift.platform.position.distance_to(lift.top_position)<.05,"lift accelerates, brakes and docks exactly at TopPoint")
	check(max_gap<5 and lift.is_rider(hero),"upward travel physically carries the actor without binding its position")
	check(camera_step<12,"camera follows vertical motion without a discontinuous jump")
	await action(&"eden_talk")
	max_gap=0
	for index in 260:
		await ticks(1)
		max_gap=maxf(max_gap,absf(hero.global_position.y+22-lift.platform.global_position.y))
		if not lift.is_moving(): break
	check(lift.state==OpenElevator.State.IDLE_BOTTOM and lift.platform.position.distance_to(lift.bottom_position)<.05,"second interaction docks precisely at BottomPoint")
	check(max_gap<5 and lift.is_rider(hero),"descending travel retains stable floor contact")
	await action(&"eden_talk")
	await ticks(25)
	var ride_y:=hero.position.y
	await action(&"eden_jump")
	await ticks(8)
	check(not lift.is_rider(hero) and hero.position.y<ride_y-40,"jumping from a moving lift detaches naturally")
	await action(&"eden_jump")
	check(hero.jumps_used==2 and hero.velocity.y<0,"double jump remains available after leaving the lift")
	hero.facing=1
	await action(&"eden3_dash")
	await ticks(8)
	check(hero.dash_seconds>0 and hero.position.x>840,"air dash remains responsive during lift travel")
	await ticks(150)
	# Recall it using an actual sword hit on the lower dock switch.
	await place(Vector2(1000,578))
	hero.facing=-1
	await mouse()
	await ticks(18)
	check(lift.state==OpenElevator.State.MOVING_DOWN,"a real melee hit can activate the dock switch")
	await ticks(240)
	await place(Vector2(800,578))
	Input.action_press(&"eden_move_right")
	await ticks(8)
	Input.action_release(&"eden_move_right")
	check(hero.position.x>825 and lift.is_rider(hero),"the actor can run freely on the open platform")
	await action(&"eden3_guard")
	await ticks(3)
	check(not hero.guard_held and hero.impact_pause==0,"guard releases without freezing the original action system")
	# A real solid obstacle in the shaft must halt the lift before penetration.
	var obstacle:=StaticBody2D.new()
	obstacle.collision_layer=1
	var collision:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(210,24)
	collision.shape=box
	obstacle.position=Vector2(800,450)
	obstacle.add_child(collision)
	app.room.add_child(obstacle)
	await place(Vector2(1000,578))
	await ticks(2)
	var stops: Array[bool]=[]
	lift.obstructed.connect(func() -> void: stops.append(true))
	lift.activate()
	await ticks(160)
	check(not stops.is_empty() and not lift.is_moving() and lift.platform.global_position.y>=462,"shaft obstruction halts motion before the deck crosses solid terrain")
	obstacle.queue_free()
	await ticks(3)
	check(lift.activate(),"blocked platform can reverse and recover")
	await ticks(160)
	check(lift.state==OpenElevator.State.IDLE_BOTTOM,"recovery returns the deck to its lower dock")
	lift.automatic_return=true
	lift.return_delay=.2
	lift.activate()
	await ticks(400)
	check(lift.state==OpenElevator.State.IDLE_BOTTOM,"automatic return waits for an empty platform and returns to the lower stop")
	lift.interaction_enabled=false
	check(not lift.activate(),"Inspector interaction switch can disable the hoist")
	lift.interaction_enabled=true
	if "--screenshots" in OS.get_cmdline_user_args():
		await place(Vector2(800,578))
		await capture("navigation-room")
	app.queue_free()
	await ticks(5)
	GameSession.return_to_menu()
	var campaign:=preload("res://scenes/main.tscn").instantiate()
	add_child(campaign)
	GameSession.start_run()
	await ticks(5)
	WorldProgress.enter_scene(&"grassland",Vector2(180,1778))
	await ticks(3)
	GameSession.return_to_menu()
	await ticks(50)
	check(not WorldProgress.scene_transition_active and not campaign.transitions.busy and campaign.get_node("LevelRoot").get_child_count()==0,"returning to the menu during a chapter fade cancels pending scene replacement")
	GameSession.start_run()
	await ticks(8)
	check(WorldProgress.can_play() and campaign.get_node("LevelRoot").get_child_count()==1,"a new run after cancelled loading is fully playable")
	GameSession.return_to_menu()
	campaign.queue_free()
	await ticks(5)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("NAVIGATION: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func ticks(count: int) -> void:
	for index in count:
		await get_tree().physics_frame
		frames+=1
	await get_tree().process_frame
func settle() -> void:
	for index in 100:
		await ticks(1)
		if not app.transitions.busy and WorldProgress.transition_rearm_seconds==0: break
func place(point: Vector2) -> void:
	hero.reset_at_checkpoint(point)
	await ticks(7)
func action(id: StringName) -> void:
	var event:=InputEventAction.new()
	event.action=id
	event.pressed=true
	Input.parse_input_event(event)
	await ticks(1)
	event=InputEventAction.new()
	event.action=id
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
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS " if ok else "FAIL ")+message)
func capture(id: String) -> void:
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	get_viewport().get_texture().get_image().save_png("res://test-output/"+id+".png")
