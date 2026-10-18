extends Node
const FirstUseGuideScript = preload("res://scripts/ui/first_use_guide.gd")
var checks:=0
var failures:=0
var app: Node
func _ready() -> void:
	get_tree().create_timer(60).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()
func _run() -> void:
	var movement_seen:=FirstUseGuideScript.seen("movement")
	GameText.set_language("en",false)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	await ticks(4)
	var ui_font: SystemFont=preload("res://assets/ui_theme.tres").default_font
	check(ui_font.font_names[0]=="Andale Mono","Andale Mono is the primary UI font")
	check(is_equal_approx(ui_font.get_string_size("iiii",HORIZONTAL_ALIGNMENT_LEFT,-1,22).x,ui_font.get_string_size("WWWW",HORIZONTAL_ALIGNMENT_LEFT,-1,22).x),"English text keeps equal character widths")
	var chinese_ok:=ui_font.has_char("矿".unicode_at(0))
	var subscript_ok:=ui_font.has_char("₂".unicode_at(0))
	for fallback in ui_font.fallbacks:
		chinese_ok=chinese_ok or fallback.has_char("矿".unicode_at(0))
		subscript_ok=subscript_ok or fallback.has_char("₂".unicode_at(0))
	print("GLYPHS: Chinese=",chinese_ok," subscript=",subscript_ok," fallback=",ui_font.fallbacks[0].get_font_name())
	check(chinese_ok and subscript_ok,"font fallbacks cover Chinese and CO2 notation")
	print("FONT: ",ui_font.get_font_name())
	app._menu._settings.open()
	check(app._menu._settings.visible and not app._menu._settings._menu.visible,"menu settings opens correctly")
	check(app._menu._settings._controls.text.contains("Shadow Pierce"),"settings has complete English controls")
	app._menu._settings.close()
	GameSession.start_run()
	await ticks(8)
	var hud: Control=app._hud
	var level: CampaignLevel=app.get_node("LevelRoot").get_child(0)
	for enemy in level.enemies: enemy.set_physics_process(false)
	check(not hud.get_node("Abilities").visible and not hud.get_node("RouteMap").visible,"ability strip and route map are hidden")
	check(not hud.get_node("%MuteButton").visible and hud._settings_button.visible,"one settings entry replaces utility controls")
	check(not hud.get_node("Hint").text.contains(" E "),"objective has no key tutorial")
	check((hud._tutorial_source.contains("A/D") and hud._tutorial.visible) if not movement_seen else not hud._tutorial_source.contains("A/D"),"movement tutorial respects saved preferences")
	check(not FirstUseGuideScript.claim("movement"),"tutorial is shown only once")
	var disk:=ConfigFile.new()
	check(disk.load("user://tutorial_seen.cfg")==OK and disk.get_value("seen","movement",false),"tutorial progress persists to disk")
	await capture("ui-clean-before")
	hud._settings.open()
	var elapsed:=GameSession.elapsed_seconds
	var point:=level.player.position
	Input.action_press(&"eden_move_right")
	await ticks(20)
	Input.action_release(&"eden_move_right")
	check(not WorldProgress.can_play() and GameSession.elapsed_seconds==elapsed and level.player.position==point,"settings freezes world and timer")
	check(not level.player.combat.try_close(1),"settings prevents attacks")
	var muted:=SoundManager.muted
	hud._settings._sound.pressed.emit()
	check(SoundManager.muted!=muted,"settings sound switch works")
	hud._settings._sound.pressed.emit()
	GameText.set_language("zh_CN",false)
	check(hud._settings._controls.text.contains("碳矿化"),"settings switches to Chinese")
	await capture("ui-settings-chinese")
	GameText.set_language("en",false)
	await capture("ui-settings-english")
	var escape:=InputEventKey.new()
	escape.keycode=KEY_ESCAPE
	escape.pressed=true
	Input.parse_input_event(escape)
	await ticks(2)
	check(not hud._settings.visible and WorldProgress.can_play(),"Escape resumes gameplay")
	escape=InputEventKey.new()
	escape.keycode=KEY_ESCAPE
	escape.pressed=false
	Input.parse_input_event(escape)
	await ticks(2)
	var layer:=CanvasLayer.new()
	layer.layer=1
	add_child(layer)
	var patch:=ColorRect.new()
	patch.position=Vector2(500,300)
	patch.size=Vector2(120,80)
	patch.color=Color(0.2,0.7,0.25)
	layer.add_child(patch)
	await ticks(3)
	var before:=await pixel()
	WorldProgress.borrow_ability(&"double_jump")
	await ticks(60)
	check(level.ecology.amount>0.99,"depletion reaches full transition")
	var after:=await pixel()
	if DisplayServer.get_name()!="headless":
		var a:=before.r*0.299+before.g*0.587+before.b*0.114
		var b:=after.r*0.299+after.g*0.587+after.b*0.114
		check(b>=a*0.94,"pollution retains brightness")
		check(after.r>before.r+0.25 and after.b<before.b*0.75 and after.r>after.g and after.r-after.g<0.30,"green turns vivid straw yellow without turning grey")
		print("FILTER: ",before," -> ",after)
	layer.queue_free()
	await ticks(3)
	hud._tutorial_seconds=0
	hud._tutorial.hide()
	await capture("ui-clean-polluted")
	GameSession.return_to_menu()
	await ticks(3)
	GameSession.start_run()
	await ticks(4)
	check(not FirstUseGuideScript.claim("movement"),"new run retains seen tutorials")
	GameSession.return_to_menu()
	await ticks(3)
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("UI REFRESH: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1
	print(("PASS: " if value else "FAIL: ")+message)
func ticks(count: int) -> void:
	for i in count: await get_tree().physics_frame
	await get_tree().process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/ui-refresh")
	get_viewport().get_texture().get_image().save_png("res://test-output/ui-refresh/"+name+".png")
func pixel() -> Color:
	if DisplayServer.get_name()=="headless": return Color.WHITE
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	return get_viewport().get_texture().get_image().get_pixel(550,330)
