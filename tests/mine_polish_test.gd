extends Node
## Presentation integration acceptance. The existing mine route test owns the
## input-only eight-stage walkthrough; placements here inspect art and feedback.
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Audio=preload("res://scripts/mine_challenge/mine_audio.gd")
const Hero=preload("res://scripts/presentation/hero_action_visual.gd")
const Effects=preload("res://scripts/mine_challenge/mineral_effects.gd")
const CELLS=[Rect2(10,129,309,197),Rect2(329,119,288,207),Rect2(630,145,305,175),Rect2(950,149,294,114),Rect2(11,385,307,208),Rect2(337,379,267,212),Rect2(630,476,322,99),Rect2(978,355,244,238),Rect2(10,613,323,304),Rect2(348,621,272,298),Rect2(716,627,98,303),Rect2(912,616,326,307),Rect2(10,949,320,255),Rect2(335,941,278,267),Rect2(637,1035,323,137),Rect2(993,964,233,229)]
var app: Node
var level: Node2D
var actor: CharacterBody2D
var checks:=0
var failures:=0

class MeleeTarget extends StaticBody2D:
	var hits:=0
	func _ready() -> void:
		collision_layer=4
		collision_mask=0
		var shape:=CollisionShape2D.new()
		var rect:=RectangleShape2D.new()
		rect.size=Vector2(20,40)
		shape.shape=rect
		add_child(shape)
	func receive_melee_hit(_hit: Dictionary) -> bool:
		hits+=1
		return true

func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()

func _run() -> void:
	GameText.set_language("en",false)
	app=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	await ticks(4)
	WorldProgress.enter_scene(&"grassland",Vector2.ZERO)
	await ticks(8)
	level=app.get_node("LevelRoot").get_child(0)
	actor=level.player
	await preload("res://tests/helpers/mine_learning.gd").acquire(level,get_tree())
	check(level.get_script().resource_path=="res://scripts/mine_challenge/level.gd" and level.vents.size()==25,"polished production mine retains all 25 mineralizable relay vents")
	check(actor._art is HeroActionVisual and actor._art.sprite.texture in [Hero.MOTION_RED,Hero.RED],"mine uses the original campaign hero atlas, rather than a drawn placeholder")
	check(actor.combat is MeleeCombat and not actor.combat.close_attack.show_placeholder_weapon and not actor.combat.close_attack.show_hitbox,"original real melee controller is integrated without debug weapon shapes")
	var shape:=actor.get_child(0) as CollisionShape2D
	check(shape!=null and shape.shape is CapsuleShape2D and shape.shape.radius==12 and shape.shape.height==44,"authored art preserves the validated 24 by 44 player collider")
	check(actor.grounding.foot_height==22 and actor._art.position.y==-2 and actor.is_on_floor(),"original hero soles and projected shadow align with mine feet at +22")
	check(actor.grounding.has_ground and actor.grounding.ground_distance<2,"mine deck casts a real contact shadow under the hero")
	var atlas:=Art.texture(0).atlas as Texture2D
	check(atlas!=null and atlas.resource_path==Art.ATLAS_PATH and atlas.get_size()==Vector2(1254,1254),"the imported 1254px authored detail atlas is used, without the first-import fallback")
	for index in 16:
		var texture:=Art.texture(index) as AtlasTexture
		var padded: Rect2=CELLS[index].grow(2)
		check(texture!=null and texture.atlas==atlas and texture.region.encloses(CELLS[index]) and padded.encloses(texture.region),"atlas cell %d has its entire isolated prop, without adjacent row or column fragments"%index)
	check(Art.puff_texture()==Art.texture(15),"gas and formation particles use the authored vapor silhouette")
	var environment: Node=level.get("environment")
	check(is_instance_valid(environment),"Scenario2 scenery is attached to the real production mine")
	if is_instance_valid(environment):
		var constants: Dictionary=environment.get_script().get_script_constant_map()
		check(constants.has("ORIGINAL") and constants["ORIGINAL"] is Texture2D and "Scenario2" in constants["ORIGINAL"].resource_path,"background uses the team's original Scenario2 art")
		check(constants.has("EXTENSION") and constants["EXTENSION"] is Texture2D and "mine_middle" in constants["EXTENSION"].resource_path,"wide cave route uses the matching Scenario2 middle extension")
		check(constants.has("TERRAIN") and constants["TERRAIN"] is Texture2D and "mine_terrain" in constants["TERRAIN"].resource_path,"world terrain uses the matching mine art kit")
	var soundscape:=get_tree().get_first_node_in_group(&"mine_audio")
	check(is_instance_valid(soundscape),"mine has its own level-scoped soundscape")
	if is_instance_valid(soundscape):
		for id: StringName in Audio.IDS:
			var stream: AudioStream=soundscape._streams.get(id)
			check(stream!=null and stream.get_length()>=0.05,"mine sound is loaded and audible: "+String(id))
		check(soundscape._beds.size()==2 and soundscape._beds[0].bus==&"SFX" and soundscape._beds[1].bus==&"Music","ambience and music use the existing independently adjustable sound buses")
		check(soundscape._beds.all(func(bed: AudioStreamPlayer) -> bool: return bed.playing and bed.stream is AudioStreamWAV and bed.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD),"both mine atmosphere layers loop while the scene is alive")
	await capture("01-entrance")
	Input.action_press(&"eden_move_right")
	var frames: Dictionary={}
	for frame in 20:
		await ticks(1)
		frames[actor._art.sprite.frame]=true
	Input.action_release(&"eden_move_right")
	check(frames.size()>=3 and actor._art.action==&"run","real horizontal input produces continuous original run frames")
	await ticks(4)
	var target:=MeleeTarget.new()
	target.position=actor.position+Vector2(54,-4)
	level.add_child(target)
	await ticks(2)
	actor.facing=1
	check(actor.combat.try_close(1),"mine accepts the original short melee attack")
	await ticks(7)
	check(target.hits==1 and actor._art.action==&"close_melee" and actor._art.sprite.texture==Hero.MOTION_RED,"original attack animation accompanies one real collision hit")
	await ticks(30)
	check(target.hits==1 and not actor.combat.is_busy(),"visual polish preserves recovery timing and single-hit protection")
	target.queue_free()
	await place(Vector2(580,1778))
	var vent: Node2D=level.vents[0]
	check(vent._particles.texture==Art.puff_texture() and vent._particles.emitting,"hazardous gas uses textured rising particles")
	await capture("02-active-gas")
	actor.position=Vector2(650,1730)
	actor.velocity=Vector2(90,-180)
	actor.cooldown=0
	var velocity_before:=actor.velocity
	check(actor.cast_pulse()>0 and actor.velocity==velocity_before,"original channel animation and effects preserve mid-air mineralization momentum")
	await ticks(5)
	check(actor._art.action==&"mineralization" and actor._art.sprite.texture==Hero.RED,"mineralization shows the authored original action pose")
	if is_instance_valid(soundscape):
		check(soundscape._voices.any(func(voice: AudioStreamPlayer2D) -> bool: return voice.playing and voice.stream==soundscape._streams[&"mineralize"]),"casting the pulse plays its positional mineralization sound")
	check(vent.platform!=null and vent.platform.get_meta(&"mineralized",false),"textured gas becomes the same standable temporary crystal platform")
	var effect_count:=0
	for child in vent.get_children():
		if child.get_script()==Effects: effect_count+=1
	check(effect_count>0,"mineral formation emits authored crystal-fragment effects")
	await capture("03-mineralized-bridge")
	vent.platform.remaining=0.4
	await ticks(3)
	if is_instance_valid(soundscape):
		check(soundscape._voices.any(func(voice: AudioStreamPlayer2D) -> bool: return voice.playing and voice.stream==soundscape._streams[&"warning"]),"the final second of temporary crystal life has an audible warning")
	vent.platform.remaining=0.01
	await ticks(3)
	check(not is_instance_valid(vent.platform) and vent._particles.emitting,"crystal shatter restores the textured hazardous plume")
	if is_instance_valid(soundscape):
		check(soundscape._voices.any(func(voice: AudioStreamPlayer2D) -> bool: return voice.playing and voice.stream==soundscape._streams[&"crystal_break"]),"temporary crystal shattering plays a real positional break sound")
	await place(Vector2(1200,1428))
	await capture("04-crate-and-valve")
	level.weight_switch.crate.position=level.weight_switch.switch_offset+Vector2(0,-24)
	await ticks(8)
	check(level.weight_switch.pressed and level.shaft_vents.all(func(node: Node) -> bool: return node.powered),"detailed crate and pressure plate still activate every vertical gas relay")
	await place(Vector2(2150,1050))
	level.player.set_physics_process(false)
	await capture("05-vertical-shaft")
	level.player.set_physics_process(true)
	await place(Vector2(2800,698))
	level.lever.interact()
	await ticks(3)
	check(level.lever.active and level.cliff_vents.all(func(node: Node) -> bool: return node.powered),"detailed lever routes gas to all narrow cliff vents")
	await capture("06-control-pipes")
	await place(Vector2(2510,1728))
	level.bridge.trigger()
	await ticks(72)
	await capture("07-crumbling-bridge")
	await place(Vector2(4500,1678))
	await capture("08-cliff-ascent")
	await place(Vector2(5340,378))
	await capture("09-exit")
	WorldProgress.core_reversed=true
	WorldProgress.world_changed.emit()
	await ticks(3)
	check(actor._art.green_form and actor._art.sprite.texture==Hero.MOTION_GREEN,"the original green return form updates with the campaign state")
	WorldProgress.core_reversed=false
	WorldProgress.world_changed.emit()
	level._settings.open()
	await ticks(3)
	if is_instance_valid(soundscape):
		check(soundscape._beds.all(func(bed: AudioStreamPlayer) -> bool: return bed.stream_paused),"settings pauses the mine soundscape with gameplay")
	level._settings.close()
	GameSession.return_to_menu()
	await ticks(5)
	check(get_tree().get_first_node_in_group(&"mine_audio")==null,"leaving the mine frees its music and all positional voices")
	SoundManager.stop_sfx()
	OS.delay_msec(150)
	print("MINE POLISH: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func place(point: Vector2) -> void:
	actor.position=point
	actor.velocity=Vector2.ZERO
	actor.get_node("Camera2D").reset_smoothing()
	await ticks(5)

func ticks(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame

func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1
	print(("PASS: " if value else "FAIL: ")+message)

func capture(title: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	DirAccess.make_dir_recursive_absolute("res://test-output/mine-polish")
	var image:=get_viewport().get_texture().get_image()
	image.save_png("res://test-output/mine-polish/"+title+".png")
	var colors: Dictionary={}
	for y in range(90,image.get_height(),8):
		for x in range(0,image.get_width(),8): colors[image.get_pixel(x,y).to_rgba32()]=true
	check(colors.size()>180,"rendered "+title+" contains detailed authored terrain and prop colors")
