extends Node
var app: Node
var checks:=0
var failures:=0

func _ready() -> void:
	get_tree().create_timer(100).timeout.connect(func() -> void: get_tree().quit(1))
	run.call_deferred()

func run() -> void:
	GameText.set_language("en",false)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(8)
	check(level().find_children("RecoveredBiochar","Area2D",true,false).is_empty() and level().find_children("Shard*","Area2D",true,false).is_empty(),"scrapyard spawns no coin-style lantern, crystal or biochar pickups")
	await place(level().npc.position+Vector2(30,0))
	check(keys().has("T"),"near a resident shows a circular T affordance")
	await capture("01-talk")
	await place(Vector2(600,476))
	check(not keys().has("T") and not keys().has("E"),"out-of-range units never display an interaction key")
	await place(level().definition.source+Vector2(0,6))
	check(keys().has("E"),"unlearned oasis shows E within its real interaction radius")
	await capture("02-oasis")
	Input.action_press(&"eden_absorb")
	await ticks(2)
	Input.action_release(&"eden_absorb")
	check(keys().is_empty() and WorldProgress.extraction_active,"extraction hides affordances while the player is busy")
	await ticks(150)
	check(WorldProgress.has_ability(&"double_jump") and not keys().has("E"),"learned sources no longer advertise an unavailable E action")
	WorldProgress.enter_scene(&"remnant_sea",Vector2(420,596))
	await ticks(8)
	for enemy in level().enemies: enemy.set_physics_process(false)
	WorldProgress.borrow_ability(&"shield")
	WorldProgress.borrow_ability(&"black_pierce")
	await ticks(22)
	var actor: CharacterBody2D=level().player
	var target: CampaignEnemy=level().enemies[-1]
	target.position=Vector2(530,596)
	for cycle in 4:
		await place(Vector2(430,596))
		await ticks(140)
		Input.action_press(&"eden_shield")
		await ticks(10)
		check(WorldProgress.shield_active and actor._art.action==&"shield","Eden guard reaches a protected holding pose, cycle %d"%cycle)
		Input.action_press(&"eden_move_right")
		await ticks(10)
		check(WorldProgress.shield_active and actor._art.action==&"run","guarding while moving keeps the original running frames, cycle %d"%cycle)
		await capture("03-moving-guard")
		await click(MOUSE_BUTTON_LEFT if cycle%2==0 else MOUSE_BUTTON_RIGHT)
		check(not WorldProgress.shield_active and actor.combat.is_busy(),"accepted attack lowers the guard without locking input, cycle %d"%cycle)
		Input.action_release(&"eden_move_right")
		await ticks(90)
		check(not actor.combat.is_busy() and actor.impact_pause==0 and actor._art.action==&"idle","attack and hit-stop return to idle while Q remains held, cycle %d"%cycle)
		Input.action_release(&"eden_shield")
		Input.action_press(&"eden_jump")
		await ticks(2)
		check(actor.velocity.y<0 and actor._art.action==&"jump","jump remains responsive after shield/attack interruption, cycle %d"%cycle)
		Input.action_release(&"eden_jump")
		await ticks(70)
	await ticks(140)
	Input.action_press(&"eden_shield")
	await ticks(1)
	Input.action_release(&"eden_shield")
	await ticks(3)
	check(not WorldProgress.shield_active and actor._art.action!=&"shield_raise" and actor._art.action!=&"shield","a quick guard tap clears the raising pose as soon as Q is released")
	await ticks(140)
	Input.action_press(&"eden_shield")
	Input.action_press(&"eden_jump")
	await ticks(4)
	Input.action_release(&"eden_jump")
	check(WorldProgress.shield_active and actor._art.action in [&"jump",&"double_jump",&"fall"],"airborne guarding preserves jump and falling animation")
	await ticks(100)
	check(not WorldProgress.shield_active and actor._art.action==&"idle" and not actor.combat.is_busy(),"guard expires normally even with Q held, returning to free movement")
	Input.action_release(&"eden_shield")
	check(actor._feedback.impact_count>0,"Eden attack recovery was checked after actual enemy hits and hit-stop")
	await place(Vector2(3400,596))
	check(keys().has("F"),"near a dark wall offers F only after Shadow Pierce is learned")
	actor._pierce_recovery=.4
	await ticks(2)
	check(not keys().has("F"),"dark wall hint hides while Shadow Pierce is cooling down")
	await ticks(30)
	check(keys().has("F"),"dark wall hint returns when the skill is usable again")
	WorldProgress.core_reversed=true
	WorldProgress.returning=true
	await place(level().definition.source)
	check(keys().has("R") and not keys().has("E"),"return journey changes the oasis key from extraction to restoration")
	WorldProgress.core_reversed=false
	WorldProgress.returning=false
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(8)
	await place(Vector2(280,1778))
	check(keys().has("T"),"mine resident uses the same round T prompt")
	await place(level().lever.position+Vector2(-50,-22))
	check(keys().has("T"),"mine lever advertises the actual T interaction")
	await capture("04-lever")
	await place(Vector2(860,1720))
	check(keys().has("E"),"near active gas offers mineralization")
	level().player.cast_pulse()
	await ticks(2)
	check(not keys().has("E"),"mineralized gas and cooldown never offer a redundant cast")
	await capture("05-mineralized")
	WorldProgress.narrative_active=true
	WorldProgress.narrative_kind=&"settings"
	await ticks(2)
	check(keys().is_empty(),"settings and dialogue hide every world interaction prompt")
	WorldProgress.narrative_active=false
	WorldProgress.narrative_kind=&""
	GameSession.return_to_menu()
	await ticks(3)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("INTERACTIONS: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func level() -> Node2D: return app.get_node("LevelRoot").get_child(0)
func keys() -> Array[String]: return level().interaction_hints.visible_keys()
func place(point: Vector2) -> void:
	level().player.position=point
	level().player.velocity=Vector2.ZERO
	level().player.get_node("Camera2D").reset_smoothing()
	await ticks(4)
func ticks(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame
func click(button: MouseButton) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=button
		event.pressed=pressed
		get_viewport().push_input(event,true)
		await ticks(1)
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/interactions")
	get_viewport().get_texture().get_image().save_png("res://test-output/interactions/"+id+".png")
