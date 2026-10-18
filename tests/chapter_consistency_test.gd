extends Node
var app: Node
var checks:=0
var failures:=0
var screenshots:=false
var panel_rect:=Rect2()

func _ready() -> void:
	screenshots="--screenshots" in OS.get_cmdline_user_args()
	get_tree().create_timer(120).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("en",false)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(12)
	var panel: ChapterStatusHUD=app._hud.chapter_status
	panel_rect=panel.life_orbs.get_global_rect()
	check(panel.is_visible_in_tree() and panel.position==Vector2(20,18),"chapter one uses the mine-style shared panel")
	check(not app._hud.get_node("Top").is_visible_in_tree() and not is_instance_valid(level().parkour_hud),"old chapter-one HUDs are not duplicated")
	actor()._invulnerability=0
	actor().hurt()
	check(GameSession.health==90,"ordinary damage still removes half a life orb")
	var gross:=CarbonLedger.gross_kg
	for index in 5:
		actor().position.y=910
		await ticks(2)
		var expected:=maxi(0,90-20*(index+1))
		check(GameSession.health==expected and actor().stats.health==expected,"scrapyard fall %d preserves injuries and deducts one whole orb"%(index+1))
		check(panel.life_orbs.get_half_count()==expected/10,"scrapyard health data and visible orb halves agree")
		if index<4:
			check(GameSession.state==GameSession.State.PLAYING,"nonfatal fall resumes immediately")
			await ticks(20)
	check(GameSession.state==GameSession.State.GAME_OVER and app._result.visible,"fifth injured fall opens Game Over")
	check(CarbonLedger.gross_kg==gross and GameSession.last_result.death_reason==&"fall","fall accounting persists and fatal result records the cause")
	GameSession.resume_checkpoint()
	await ticks(12)
	GameSession.sync_health(90,100)
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(12)
	panel=level().chapter_status
	check(panel is ChapterStatusHUD and panel.life_orbs.get_global_rect()==panel_rect,"mine has identical orb placement, sizing and panel implementation")
	check(GameSession.health==90 and actor().health==90,"entering the mine retains the previous chapter's injuries")
	check(not WorldProgress.has_ability(&"mineralization") and actor().cast_pulse()==0,"mine no longer grants mineralization automatically")
	check(level().life_source is MineLifeSeam and level().life_source.vitality==1,"production mine contains a living ore seam")
	actor().position=Vector2(420,1778)
	actor().velocity=Vector2.ZERO
	await ticks(5)
	Input.action_press(&"eden_absorb")
	await ticks(1)
	Input.action_release(&"eden_absorb")
	await ticks(2)
	check(WorldProgress.extraction_active and actor().extracting and not WorldProgress.has_ability(&"mineralization"),"E starts the real extraction before granting mineralization")
	var origin:=actor().position
	var timer:=GameSession.elapsed_seconds
	Input.action_press(&"eden_move_right")
	await ticks(40)
	Input.action_release(&"eden_move_right")
	check(actor().position==origin and GameSession.elapsed_seconds==timer,"mining extraction freezes movement and gameplay time")
	check(actor()._art.extraction_sprite.visible and actor()._art.extraction_sprite.frame==2,"mine hero visibly kneels with the original extraction animation")
	check(level().life_source.vitality<1 and level().life_source.vitality>0,"ore seam loses its light gradually during the action")
	await capture("02-mine-extraction")
	await ticks(115)
	check(WorldProgress.has_ability(&"mineralization") and not actor().extracting and level().life_source.vitality==0,"extraction completion commits the skill and spent seam together")
	check(actor().health==90 and panel.life_orbs.get_half_count()==9,"extraction never heals the player")
	await capture("03-mine-spent")
	for index in 5:
		actor().position.y=2090
		await ticks(16)
		var expected:=maxi(0,90-20*(index+1))
		check(GameSession.health==expected and actor().health==expected,"mine fall %d retains the remaining health after the 0.2 s recovery"%(index+1))
		if index<4: check(actor().respawn_seconds==0 and GameSession.state==GameSession.State.PLAYING,"mine retry finishes without a refill")
	check(GameSession.state==GameSession.State.GAME_OVER and app._result.visible,"mine acid can exhaust life and show the normal Game Over modal")
	check(WorldProgress.has_ability(&"mineralization") and level().life_source.vitality==0,"fatal fall preserves skill and source history")
	GameSession.resume_checkpoint()
	await ticks(12)
	WorldProgress.enter_scene(&"remnant_sea",Vector2(140,596))
	await ticks(12)
	panel=level().chapter_status
	check(panel.is_visible_in_tree() and panel.life_orbs.get_global_rect()==panel_rect,"Eden uses the same mine-style health and carbon panel")
	actor().stats.take_damage(10)
	actor().position.y=level().player.death_height+20
	await ticks(3)
	check(GameSession.health==70 and actor().stats.health==70 and GameSession.state==GameSession.State.PLAYING,"Eden fall also costs one whole orb without clearing earlier injuries")
	await capture("04-eden")
	GameSession.return_to_menu()
	await ticks(3)
	GameSession.start_run()
	await ticks(8)
	await capture("01-scrapyard")
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(8)
	actor().position=Vector2(420,1778)
	actor().velocity=Vector2.ZERO
	await ticks(4)
	level().try_extract()
	await ticks(10)
	GameSession.return_to_menu()
	await ticks(3)
	GameSession.start_run()
	await ticks(8)
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(8)
	check(WorldProgress.can_play() and not WorldProgress.has_ability(&"mineralization") and level().life_source.vitality==1,"cancelling a mine extraction leaves the next run unlocked and source alive")
	GameSession.return_to_menu()
	await ticks(4)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("CHAPTER_CONSISTENCY: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func level() -> Node2D: return app.get_node("LevelRoot").get_child(0)
func actor() -> CharacterBody2D: return level().player
func ticks(count: int) -> void:
	for frame in count: await get_tree().physics_frame
	await get_tree().process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS " if ok else "FAIL ")+message)
func capture(id: String) -> void:
	if not screenshots: return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/chapter-status-"+id+".png")
