extends Node
## Also runnable in a fresh project copy without an existing .godot cache.
var _checks := 0
var _failures := 0

func _ready() -> void:
	get_tree().create_timer(20.0).timeout.connect(func() -> void:
		push_error("Startup acceptance timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()

func _run() -> void:
	for singleton in [&"GameSession", &"WorldProgress", &"CarbonLedger", &"SoundManager"]:
		var instance:=get_node_or_null("/root/"+singleton)
		_check(instance!=null and instance.get_script()!=null,"compiled autoload exists: "+singleton)
	var path: String=ProjectSettings.get_setting("application/run/main_scene","")
	var main:=load(path) as PackedScene
	_check(path=="res://scenes/main.tscn" and main!=null,"configured entry scene loads")
	if _failures>0:
		get_tree().quit(1)
		return
	var app:=main.instantiate()
	add_child(app)
	await _physics(4)
	GameSession.start_run()
	await _physics(30)
	var player: CharacterBody2D=app.get_node("LevelRoot").get_child(0).player
	_check(GameSession.state==GameSession.State.PLAYING and CarbonLedger.enabled and player.is_on_floor(),"entry scene starts the playable campaign and carbon ledger")
	_check(app.get_node("UI/Root/HUD").visible and player._art.sprite.texture!=null,"HUD and character action resources initialize")
	GameSession.return_to_menu()
	await _physics(4)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
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
