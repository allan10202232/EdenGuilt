extends CharacterBody2D
## Mine movement is deliberately independent of the campaign's faster jump arc.
## The campaign hero, melee phases and contact shadows are presentation only.
const HeroVisual = preload("res://scripts/presentation/hero_action_visual.gd")
const GroundingVisual = preload("res://scripts/presentation/actor_grounding.gd")
const MeleeScene = preload("res://scenes/combat/melee_combat.tscn")
const MineAudio = preload("res://scripts/mine_challenge/mine_audio.gd")
const MineralEffects = preload("res://scripts/mine_challenge/mineral_effects.gd")
signal pulse_cast(converted: int)
signal mineral_landed
signal health_changed(current: int, maximum: int)
@export var speed := 260.0
@export var gravity := 980.0
@export var jump_velocity := -420.0
@export var double_jump_velocity := -390.0
@export var coyote_time := 0.12
@export var jump_buffer := 0.12
@export var pulse_radius := 260.0
@export var pulse_cooldown := 0.6
var level: Node2D
var cooldown := 0.0
var jumps_used := 0
var respawn_seconds := 0.0
var health := 100
var facing := 1.0
var _coyote := 0.0
var _buffer := 0.0
var _gas_slow := 0.0
var _gas_damage := 0.0
var _pulse_age := 1.0
var _pulse_origin := Vector2.ZERO
var _was_floor := false
var _clock := 0.0
var combat: MeleeCombat
var _art: HeroActionVisual
var grounding: ActorGrounding
# HeroActionVisual reads the same small interface on every campaign player.
var extracting := false
var extraction_progress := 0.0
var impact_pause := 0.0
var _facing: float:
	get: return facing
	set(value): facing=value
var _camera: Camera2D
var _shake_left := 0.0
var _shake_strength := 0.0
var _footstep_clock := 0.0
var _resonance_light := 0.0

func _ready() -> void:
	floor_snap_length=8
	platform_on_leave=CharacterBody2D.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY
	# Preserve injuries when moving between campaign chapters.
	health=clampi(GameSession.health,1,100)
	add_to_group(&"player")
	collision_layer=2
	collision_mask=5
	var shape:=CollisionShape2D.new()
	var capsule:=CapsuleShape2D.new()
	capsule.radius=12
	capsule.height=44
	shape.shape=capsule
	add_child(shape)
	var camera:=Camera2D.new()
	camera.name="Camera2D"
	camera.position=Vector2(90,-65)
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=5600
	camera.limit_bottom=2400
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=7
	add_child(camera)
	_camera=camera
	z_index=5
	grounding=GroundingVisual.new()
	grounding.bind(self,22.0,16.0,5)
	grounding.z_index=-1
	add_child(grounding)
	combat=MeleeScene.instantiate()
	add_child(combat)
	combat.setup(self,func() -> bool: return WorldProgress.can_play() and respawn_seconds<=0)
	for attack: MeleeAttack in [combat.close_attack,combat.reach_attack]:
		attack.show_hitbox=false
		attack.show_placeholder_weapon=false
		# Layer 4 holds receivers/crates; only terrain may occlude a melee hit.
		attack.obstruction_mask=1
	combat.attack_started.connect(func(profile: MeleeAttackProfile) -> void:
		SoundManager.play_sfx(&"slash_reach" if profile.id==&"reach_melee" else &"slash_close",-10.0)
	)
	_art=HeroVisual.new()
	_art.position.y=-2.0 # Original hero soles at +24; this capsule ends at +22.
	add_child(_art)
	_art.bind(self)
	WorldProgress.world_changed.connect(_refresh_form)
	_refresh_form()

func _refresh_form() -> void:
	_art.set_form(WorldProgress.core_reversed)

func _process(delta: float) -> void:
	# Feedback never changes jump timing, momentum or the stage's 0.2s respawn.
	_shake_left=maxf(0.0,_shake_left-delta)
	_resonance_light=maxf(0.0,_resonance_light-delta*2.5)
	var shake:=minf(1.0,_shake_left/0.11) if WorldProgress.can_play() else 0.0
	_camera.offset=(Vector2(sin(_clock*131.0),cos(_clock*167.0))*_shake_strength*shake).round()
	grounding.light_energy=maxf(_resonance_light,0.55*(1.0-_pulse_age/0.32) if _pulse_age<0.32 else 0.0)
	grounding.light_tint=Color(0.45,0.75,1.0)
	if not WorldProgress.can_play() or respawn_seconds>0: return
	if is_on_floor() and absf(velocity.x)>30:
		_footstep_clock-=delta
		if _footstep_clock<=0:
			_footstep_clock=0.28
			_play_mine_sound(&"footstep",-20.0,0.96+sin(_clock*3.1)*0.06)
	else:
		_footstep_clock=0.0

func _camera_impulse(strength: float,duration: float=0.11) -> void:
	_shake_strength=strength
	_shake_left=duration

func _play_mine_sound(id: StringName,volume_db: float=0.0,pitch: float=1.0) -> void:
	# Component soundscape is level-scoped, so leaving the mine releases every voice.
	MineAudio.play_near(self,id,volume_db,pitch)

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play(): return
	_clock+=delta
	cooldown=maxf(0,cooldown-delta)
	_gas_slow=maxf(0,_gas_slow-delta)
	_pulse_age+=delta
	if respawn_seconds>0:
		respawn_seconds=maxf(0,respawn_seconds-delta)
		if respawn_seconds==0:
			position=level.checkpoint_position
			velocity=Vector2.ZERO
			jumps_used=0
			_coyote=0
			_buffer=0
			get_node("Camera2D").reset_smoothing()
			modulate=Color.WHITE
			_art.play_action(&"channel",0.24)
			_resonance_light=1.0
			_camera_impulse(1.2)
		return
	var floor_before:=is_on_floor()
	_coyote=coyote_time if floor_before else maxf(0,_coyote-delta)
	if floor_before: jumps_used=0
	_buffer=jump_buffer if Input.is_action_just_pressed(&"eden_jump") else maxf(0,_buffer-delta)
	var axis:=Input.get_axis(&"eden_move_left",&"eden_move_right")
	velocity.x=axis*speed*(0.55 if _gas_slow>0 else 1.0)
	if axis!=0: facing=axis
	velocity.y=minf(velocity.y+gravity*delta,1100)
	if _buffer>0:
		if floor_before or _coyote>0:
			velocity.y=jump_velocity
			jumps_used=1
			_coyote=0
			_buffer=0
			_art.play_action(&"jump",0.10)
			_play_mine_sound(&"jump",-9.0)
		elif jumps_used<2:
			velocity.y=double_jump_velocity
			jumps_used=2
			_buffer=0
			if WorldProgress.has_ability(&"double_jump"): WorldProgress.report_ability_used(&"double_jump")
			_art.play_action(&"double_jump",0.22)
			_play_mine_sound(&"double_jump",-9.0)
			_resonance_light=0.45
	if Input.is_action_just_pressed(&"eden_absorb") and level.try_extract(): return
	if Input.is_action_just_pressed(&"mine_pulse"): cast_pulse()
	var impact_speed:=velocity.y
	move_and_slide()
	var resonated:=false
	for index in get_slide_collision_count():
		var contact:=get_slide_collision(index)
		var body:=contact.get_collider()
		if body.has_method(&"push") and absf(contact.get_normal().x)>0.5: body.push(axis*speed*0.8)
		if contact.get_normal().y< -0.6:
			if body.has_meta(&"crystal_bridge"): level.bridge.trigger()
			if body.has_meta(&"mineralized") and not _was_floor:
				jumps_used=0
				_resonance_light=1.0
				resonated=true
				mineral_landed.emit()
	if is_on_floor() and not _was_floor:
		_art.play_action(&"land",0.10)
		_play_mine_sound(&"resonance" if resonated else &"land",-10.0 if resonated else -13.0,0.92 if impact_speed>600 else 1.04)
		if resonated: MineralEffects.burst(level,level.to_local(global_position+Vector2(0,22)),&"resonance")
		if impact_speed>420: _camera_impulse(minf(2.0,impact_speed/500.0),0.09)
	_was_floor=is_on_floor()
	if position.y>2080: dissolve()
	queue_redraw()

func cast_pulse() -> int:
	if not WorldProgress.can_play() or respawn_seconds>0 or cooldown>0: return 0
	if not WorldProgress.has_ability(&"mineralization"):
		level._tutorial_text("先到入口的潮湿矿脉按 E 吸取生命，获得碳矿化。")
		return 0
	cooldown=pulse_cooldown
	_pulse_age=0
	_pulse_origin=global_position
	combat.cancel()
	_art.play_action(&"mineralization",0.28)
	_resonance_light=1.0
	_camera_impulse(1.3)
	_play_mine_sound(&"mineralize",-2.0)
	var converted: int=level.mineralize_near(global_position,pulse_radius)
	pulse_cast.emit(converted)
	return converted

func touch_gas(delta: float) -> void:
	if respawn_seconds>0 or not WorldProgress.can_play(): return
	_gas_slow=0.12
	_gas_damage+=delta
	if _gas_damage>=0.8:
		_gas_damage=0
		_set_health(health-10)
		if health<=0: dissolve()
		else:
			_art.play_action(&"hurt",0.22)
			_camera_impulse(2.5,0.14)
			_play_mine_sound(&"hurt",-8.0)

func _set_health(value: int) -> void:
	health=clampi(value,0,100)
	health_changed.emit(health,100)
	GameSession.sync_health(health,100)

func dissolve() -> void:
	if respawn_seconds>0 or not WorldProgress.can_play(): return
	var survived:=GameSession.apply_fall_penalty()
	health=GameSession.health
	health_changed.emit(health,100)
	if not survived: return
	respawn_seconds=0.2
	velocity=Vector2.ZERO
	combat.cancel()
	_art.play_action(&"death",0.2)
	_camera_impulse(3.0,0.16)
	_play_mine_sound(&"acid",-5.0)
	MineralEffects.burst(level,level.to_local(global_position+Vector2(0,20)),&"acid")
	modulate=Color(1,1,1,0.2)
	level.reset_attempt.call_deferred()

func begin_extraction(ground: Vector2) -> void:
	extracting=true
	extraction_progress=0.0
	velocity=Vector2.ZERO
	_buffer=0
	combat.cancel()
	if absf(ground.x-position.x)>12: facing=signf(ground.x-position.x)

func finish_extraction() -> void:
	extracting=false
	extraction_progress=0.0

func _unhandled_input(event: InputEvent) -> void:
	if not WorldProgress.can_play() or respawn_seconds>0 or event.is_echo(): return
	if event.is_action_pressed(&"eden_talk") or event.is_action_pressed(&"eden_slash"):
		level.interact()
		if event.is_action_pressed(&"eden_slash"):
			combat.request_attack(false,facing)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"eden_return"):
		level.restore_oasis()

func _draw() -> void:
	# Only energy is drawn procedurally. The hero is the original authored atlas.
	if _pulse_age<0.32:
		var center:=to_local(_pulse_origin)
		var fade:=1.0-_pulse_age/0.32
		var radius:=pulse_radius*minf(1.0,_pulse_age/0.25)
		for band in [18.0,10.0,4.0]:
			draw_arc(center,radius,0,TAU,96,Color(0.45,0.72,1.0,fade*(0.05 if band>10 else 0.12 if band>4 else 0.75)),band,true)
		draw_arc(center,pulse_radius*minf(1.0,_pulse_age/0.30),0,TAU,96,Color(0.85,0.65,1.0,fade*0.7),2,true)
		for index in 16:
			var angle:=TAU*index/16.0+0.12
			var direction:=Vector2.from_angle(angle)
			draw_line(center+direction*(radius-9.0),center+direction*(radius+6.0),Color(0.88,0.95,1.0,fade*0.8),2,true)
