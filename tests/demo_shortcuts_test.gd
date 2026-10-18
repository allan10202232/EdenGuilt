extends Node
var app: Node
var checks:=0
var failures:=0

func _ready() -> void:
	get_tree().create_timer(80).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("en",false)
	var preview:=preload("res://scenes/demo/presentation.tscn").instantiate()
	add_child(preview)
	app=preview.get_child(0)
	await ticks(10)
	check(GameSession.state==GameSession.State.PLAYING and level() is ScrapyardParkourLevel,"demo starts the real first chapter without replaying the prologue")
	check(app.demo_shortcuts!=null and get_window().title.contains("Demo Mode"),"presentation shortcuts require an explicit demo session")
	await key(KEY_3,false)
	await key(KEY_PAGEUP,true)
	check(WorldProgress.current_scene==&"lone_tree" and not app.transitions.busy,"plain numbers and a previous-chapter request at the beginning do nothing")
	level().player.hurt()
	var health:=GameSession.health
	var carbon:=CarbonLedger.gross_kg
	await key(KEY_PAGEDOWN,true)
	check(app.transitions.busy and not WorldProgress.can_play(),"next chapter uses the normal fading transition and control lock")
	await key(KEY_PAGEDOWN,true)
	await settle()
	check(WorldProgress.current_scene==&"grassland" and level().current_stage==1,"next chapter enters the mine at its first stage")
	check(app.transitions.completed_count==1,"repeated input while fading cannot skip two chapters")
	check(WorldProgress.has_ability(&"double_jump") and not WorldProgress.has_ability(&"mineralization"),"mine entry grants the missing earlier skill while leaving its own source playable")
	check(level().player.is_on_floor() and level().player.position.distance_to(Vector2(180,1778))<2,"mine jump lands safely on the entrance platform")
	check(GameSession.health==health and CarbonLedger.gross_kg==carbon,"scene jumps preserve injuries and do not invent carbon emissions")
	await key(KEY_PAGEDOWN,true)
	await settle()
	check(WorldProgress.current_scene==&"remnant_sea" and level() is EdenChapterLevel,"another next-chapter shortcut reaches the production Eden City")
	check(WorldProgress.has_ability(&"double_jump") and WorldProgress.has_ability(&"mineralization"),"Eden receives both prerequisite traversal abilities")
	check(not WorldProgress.has_ability(&"shield") and not WorldProgress.has_ability(&"black_pierce"),"city abilities still require their own acquisition sequences")
	check(level().current_node==1 and level().player.position.distance_to(EdenBlueprint.ENTRY)<2,"Eden opens at the correct bottom-right entrance")
	await key(KEY_PAGEDOWN,true)
	check(not app.transitions.busy and WorldProgress.current_scene==&"remnant_sea","next at the last chapter never wraps or fabricates an ending")
	check(not WorldProgress.eden_chapter.get("steward",false) and CarbonLedger.rescued_people==0 and WorldProgress.ending_choice==&"","jumping chapters never defeats a boss, rescues residents or chooses an ending")
	level()._settings.open()
	check(level()._settings._controls.text.contains("Ctrl + PageDown"),"English settings list the demo shortcuts")
	GameText.set_language("zh_CN",false)
	check(level()._settings._controls.text.contains("下一章"),"Chinese settings explain the same presentation controls")
	await key(KEY_1,true)
	check(not app.transitions.busy and WorldProgress.current_scene==&"remnant_sea","settings pause blocks accidental scene jumps")
	level()._settings.close()
	# In-progress acquisition must remain a single transaction, even with shortcuts.
	level().player.reset_at_checkpoint(Vector2(350,1898))
	await ticks(7)
	Input.action_press(&"eden_absorb")
	await ticks(2)
	Input.action_release(&"eden_absorb")
	check(WorldProgress.extraction_active,"the real Shield acquisition starts normally in demo mode")
	await key(KEY_2,true)
	check(WorldProgress.current_scene==&"remnant_sea" and not app.transitions.busy,"a shortcut cannot interrupt the extraction transaction")
	await ticks(160)
	check(WorldProgress.has_ability(&"shield") and not WorldProgress.extraction_active,"the interrupted-key attempt leaves acquisition able to finish")
	await key(KEY_2,true)
	await settle()
	check(WorldProgress.current_scene==&"grassland" and level().current_stage==1,"Ctrl+2 returns directly to the mine entrance")
	await key(KEY_PAGEUP,true)
	await settle()
	check(WorldProgress.current_scene==&"lone_tree" and level().player.position.distance_to(Vector2(100,476))<2,"previous chapter returns to the scrapyard start")
	await key(KEY_3,true,true)
	check(not app.transitions.busy,"held-key repeats cannot trigger a jump")
	await key(KEY_3,true)
	await settle()
	check(WorldProgress.current_scene==&"remnant_sea" and level().current_node==1,"Ctrl+3 directly jumps across chapters")
	await key(KEY_1,true)
	await settle()
	check(WorldProgress.current_scene==&"lone_tree" and get_tree().get_nodes_in_group(&"player").size()==1,"Ctrl+1 loads a single real player at the first chapter")
	check(GameSession.health==health and CarbonLedger.gross_kg==carbon and GameSession.score==0,"round trips retain stats without awarding unearned score or emissions")
	GameSession.return_to_menu()
	preview.queue_free()
	await ticks(5)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(8)
	await key(KEY_3,true)
	check(app.demo_shortcuts==null and WorldProgress.current_scene==&"lone_tree","ordinary F5 gameplay has no enabled demo controls")
	GameSession.return_to_menu()
	app.queue_free()
	await ticks(5)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("DEMO: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func level() -> Node2D: return app.get_node("LevelRoot").get_child(0)
func ticks(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame
func settle() -> void:
	for index in 100:
		await ticks(1)
		if not app.transitions.busy and WorldProgress.transition_rearm_seconds==0: break
func key(code: Key,control: bool,repeat: bool=false) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.ctrl_pressed=control
	event.pressed=true
	event.echo=repeat
	Input.parse_input_event(event)
	await ticks(1)
	event=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	Input.parse_input_event(event)
	await ticks(1)
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS " if ok else "FAIL ")+message)
