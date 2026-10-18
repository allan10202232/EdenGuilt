extends Node
## Also runnable in a fresh project copy without an existing .godot cache.
var _checks := 0
var _failures := 0
var _run_starts := 0
var _carbon_events := 0

func _ready() -> void:
	get_tree().create_timer(25.0).timeout.connect(func() -> void:
		push_error("Startup acceptance timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()

func _run() -> void:
	for singleton in [&"GameText", &"GameSession", &"WorldProgress", &"CarbonLedger", &"SoundManager"]:
		var instance:=get_node_or_null("/root/"+singleton)
		_check(instance!=null and instance.get_script()!=null,"compiled autoload exists: "+singleton)
	var path: String=ProjectSettings.get_setting("application/run/main_scene","")
	var main:=load(path) as PackedScene
	_check(path=="res://scenes/opening.tscn" and main!=null,"configured application entry loads the opening")
	if _failures>0:
		get_tree().quit(1)
		return
	# Keep the acceptance runner alive while the actual entry scene changes scenes.
	get_tree().current_scene = null
	var opening_app:=main.instantiate()
	get_tree().root.add_child(opening_app)
	get_tree().current_scene = opening_app
	GameSession.state_changed.connect(func(_previous: int, current: int) -> void:
		if current == GameSession.State.PLAYING:
			_run_starts += 1
	)
	CarbonLedger.action_recorded.connect(func(_event: Dictionary) -> void: _carbon_events += 1)
	await _physics(4)
	var cinematic = opening_app.get_node_or_null("OpeningCinematic")
	_check(cinematic != null, "configured entry instantiates its cinematic")
	_check(GameSession.state==GameSession.State.MAIN_MENU and not CarbonLedger.enabled,"opening waits before starting campaign and carbon ledger")
	_check(get_tree().get_nodes_in_group("player").is_empty() and opening_app.find_child("LevelRoot",true,false)==null,"no hidden gameplay level runs behind opening")
	if cinematic == null:
		_finish()
		return
	var expected_order := [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(3,0)]
	for expected in expected_order:
		_check(cinematic.chapter_index==expected.x and cinematic.line_index==expected.y,"entry shows narration %s before Enter" % expected)
		_check(GameSession.elapsed_seconds==0.0 and _carbon_events==0 and CarbonLedger.action_count==0,"no campaign time or carbon emissions during narration")
		_enter()
		await _physics(2)
		var deadline := Time.get_ticks_msec() + 2500
		while is_instance_valid(cinematic) and cinematic.phase==&"dissolving" and Time.get_ticks_msec()<deadline:
			await get_tree().process_frame
		await _physics(2)
	await _physics(30)
	var app: Node=get_tree().current_scene
	_check(app != null and app.scene_file_path=="res://scenes/main.tscn","last Enter enters the real main game scene")
	_check(_run_starts==1,"opening starts exactly one new run")
	if app == null or app.get_node_or_null("LevelRoot") == null:
		_finish()
		return
	var player: CharacterBody2D=app.get_node("LevelRoot").get_child(0).player
	_check(GameSession.state==GameSession.State.PLAYING and CarbonLedger.enabled and player.is_on_floor(),"entry scene starts the playable campaign and carbon ledger")
	_check(app.get_node("UI/Root/HUD").visible and player._art.sprite.texture!=null,"HUD and character action resources initialize")
	GameSession.return_to_menu()
	await _physics(4)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	_finish()

func _enter() -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode=KEY_ENTER
		event.physical_keycode=KEY_ENTER
		event.pressed=pressed
		get_viewport().push_input(event)

func _finish() -> void:
	print("STARTUP: %d checks, %d failures"%[_checks,_failures])
	get_tree().quit(0 if _failures==0 else 1)

func _physics(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame

func _check(ok: bool,label: String) -> void:
	_checks+=1
	if ok: print("PASS: ",label)
	else:
		_failures+=1
		push_error("FAIL: "+label)
