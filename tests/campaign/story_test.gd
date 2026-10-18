extends Node
var app: Node
var checks:=0
var failures:=0

func _ready() -> void:
	get_tree().create_timer(90).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	_check(GameText.language=="en","fresh preferences default to English")
	app=preload("res://scenes/main.tscn").instantiate()
	# Historical horizontal Eden fixture; production four-floor Eden has its own route suite.
	app.eden_scene=preload("res://tests/fixtures/legacy_eden_room.tscn")
	add_child(app)
	await _ticks(5)
	_check(GameText.t(app._menu.get_node("%StartButton").text)=="Start game","main menu renders English")
	await _capture("story-00-english-menu")
	var picker: OptionButton=app._menu.get_node("Margin/Columns/Panel/Actions/LanguagePicker")
	picker.item_selected.emit(1)
	await _ticks(3)
	_check(GameText.language=="zh_CN" and GameText.t("Start game")=="开始游戏","language selector switches both aliases to Chinese")
	var preferences:=ConfigFile.new()
	preferences.load("user://preferences.cfg")
	_check(preferences.get_value("display","language","")=="zh_CN","language preference is persisted")
	picker.item_selected.emit(0)
	await _ticks(3)
	_check(app.get_node("LevelRoot").get_child_count()==0 and GameSession.elapsed_seconds==0,"main menu has no hidden gameplay before Start")
	await _click(app._menu.get_node("%StartButton"))
	await _ticks(30)
	_check(GameSession.state==GameSession.State.PLAYING and app.get_node("LevelRoot").get_child_count()==1,"Start enters one playable Junkyard without replaying the replaced opening")
	_check(_level().definition.title=="Junkyard" and _level().growth_points.size()>10,"first level has localized title and dispersed ground life")
	await _place(Vector2(80,476))
	await _key(KEY_T)
	_check(app._dialogue.visible and WorldProgress.narrative_kind==&"npc","T opens a nearby NPC conversation")
	var before:=GameSession.elapsed_seconds
	var point:=_player().position
	var magnet: ScrapPlatform=_level().platforms.filter(func(p: ScrapPlatform) -> bool: return p is MagnetLift)[0]
	var magnet_point:=magnet.position
	Input.action_press(&"eden_move_right")
	await _ticks(24)
	Input.action_release(&"eden_move_right")
	_check(GameSession.elapsed_seconds==before and _player().position==point and magnet.position==magnet_point,"NPC dialogue freezes player, moving machinery and timer")
	_check(not _player().combat.try_close(1) and not WorldProgress.choose_ending(&"B"),"NPC conversation cannot attack or submit a story ending")
	GameText.set_language("zh_CN",false)
	await _ticks(2)
	_check(app._dialogue._body.text.contains("垃圾场"),"open dialogue switches to Chinese")
	GameText.set_language("en",false)
	await _ticks(80)
	await _capture("story-03-npc")
	await _key(KEY_ESCAPE)
	await _ticks(4)
	_check(WorldProgress.can_play() and not app._dialogue.visible,"Escape closes NPC conversation and restores play")
	await _key(KEY_T)
	_check(app._dialogue._index==0 and app._dialogue._body.visible_characters==-1,"opening T shows the entire first subtitle without skipping it")
	for index in 3:
		await _key(KEY_T)
		_check(app._dialogue._index==index+1 and app._dialogue.visible,"each T advances exactly one subtitle")
	var echo:=InputEventKey.new()
	echo.keycode=KEY_T
	echo.pressed=true
	echo.echo=true
	Input.parse_input_event(echo)
	await _ticks(2)
	_check(app._dialogue._index==3,"holding T does not skip subtitles")
	await _key(KEY_T)
	await _ticks(4)
	_check(WorldProgress.can_play() and not app._dialogue.visible and _player().is_on_floor(),"final T closes subtitles without reopening the conversation")
	await _place(Vector2(230,476))
	await _action(&"eden_absorb",false)
	_check(WorldProgress.extraction_active and not WorldProgress.has_ability(&"double_jump"),"skill is not granted before extraction completes")
	_check(_level().extraction.active and _player()._art.action==&"extract" and _player()._art.extraction_sprite.visible,"learning uses the new Soul Extractor poses")
	before=GameSession.elapsed_seconds
	await _ticks(35)
	await _capture("story-04-green-gathering")
	_check(GameSession.elapsed_seconds==before and CarbonLedger.gross_kg==0,"gathering pauses gameplay and has no carbon charge")
	await _ticks(120)
	_check(WorldProgress.has_ability(&"double_jump") and WorldProgress.can_play(),"extraction unlocks Double Jump and resumes gameplay")
	await _capture("story-05-new-ability")
	await _action(&"eden_absorb")
	_check(not WorldProgress.extraction_active and WorldProgress.narrative_kind==&"" and CarbonLedger.gross_kg==0,"revisiting a learned source cannot replay or bill learning")
	WorldProgress.enter_scene(&"grassland",Vector2(140,596))
	await _ticks(10)
	_check(_level().vents.size()==25 and not WorldProgress.has_ability(&"mineralization"),"new mine loads its gas challenge with mineralization still locked")
	await preload("res://tests/helpers/mine_learning.gd").acquire(_level(),get_tree())
	_check(WorldProgress.has_ability(&"mineralization"),"real mine-seam extraction grants mineralization before the story handoff")
	_check(not app._hud.visible,"mine uses its own stage and sequestration HUD")
	# The full input-driven eight-stage route is tested in mine_challenge_test.
	# Here we isolate story handoff, bilingual dialogue and the chapter summary.
	await _place(Vector2(280,1778))
	await _key(KEY_T)
	_check(app._dialogue.visible and app._dialogue._body.text.contains("carbon"),"mine resident explains carbon mineralization in subtitles")
	await _key(KEY_ESCAPE)
	for stage in range(2,6): _level().activate_stage(stage)
	_level().lever.active=true
	_level()._redirect_gas(true)
	for stage in range(6,9): _level().activate_stage(stage)
	await _place(Vector2(5440,378))
	_check(_level()._cleared and WorldProgress.narrative_kind==&"mine_clear","mine exit presents chapter-clear summary")
	_level().continue_to_eden()
	await _ticks(8)
	_check(WorldProgress.current_scene==&"remnant_sea" and _level().name=="EdenCity","mine summary enters Eden City")
	await _capture("story-08-eden-city")
	await _place(Vector2(420,596))
	await _action(&"eden_absorb")
	await _place(Vector2(1340,596))
	await _action(&"eden_absorb")
	var guardian: CampaignEnemy=_level().enemies[-1]
	for hit in 6: guardian.receive_melee_hit({"damage":1})
	await _ticks(3)
	await _place(Vector2(4320,570))
	_check(app._truth.visible and WorldProgress.narrative_kind==&"truth","Eden City opens the localized truth choice")
	await _capture("story-09-english-truth")
	await _click(app._truth.choice_b)
	_check(app._audit.visible and GameSession.last_result.ending=="B","English choice button reaches the real B audit")
	await _capture("story-10-english-audit")
	var report:=FileAccess.get_file_as_string(app._audit.exported_paths.html)
	var cjk:=RegEx.new()
	cjk.compile("[\\x{3400}-\\x{9fff}]")
	_check(report.contains('lang="en"') and cjk.search(report)==null,"exported English HTML includes translated narrative, data labels and methodology")
	GameText.set_language("zh_CN",false)
	_check(app._audit._community.text.contains("居民"),"visible audit data switches to Chinese")
	GameText.set_language("en",false)
	var value:=GameText.t("检查点已点亮：%s") % "Junkyard"
	GameText.set_language("zh_CN",false)
	_check(GameText.t(value)=="检查点已点亮：垃圾场","formatted notices also switch language without losing values")
	GameText.set_language("en")
	GameSession.return_to_menu()
	await _ticks(5)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("STORY: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _level() -> Node2D:
	return app.get_node("LevelRoot").get_child(0)
func _player() -> CharacterBody2D:
	return _level().player
func _ticks(count: int) -> void:
	for index in count: await get_tree().physics_frame
	# Scene navigation now includes a visible fade and a short re-entry lock.
	while WorldProgress.scene_transition_active or WorldProgress.transition_rearm_seconds>0:
		await get_tree().physics_frame
	await get_tree().process_frame
func _place(point: Vector2) -> void:
	_player().position=point
	_player().velocity=Vector2.ZERO
	await _ticks(6)
func _action(action: StringName, wait_learning: bool=true) -> void:
	Input.action_press(action)
	await _ticks(2)
	Input.action_release(action)
	await _ticks(2)
	if wait_learning:
		for index in 240:
			if not WorldProgress.extraction_active: break
			await _ticks(1)
func _key(code: Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=code
		event.physical_keycode=code
		event.pressed=pressed
		get_viewport().push_input(event,true)
		await _ticks(1)
func _click(button: Button) -> void:
	var point:=button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=point
		event.pressed=pressed
		get_viewport().push_input(event,true)
		await _ticks(1)
	await _ticks(2)
func _capture(label: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/story")
	get_viewport().get_texture().get_image().save_png("res://test-output/story/"+label+".png")
func _check(ok: bool, label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error("FAIL: "+label)
