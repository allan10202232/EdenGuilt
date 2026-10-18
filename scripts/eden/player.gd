class_name EdenChapterPlayer
extends "res://scripts/mine_challenge/player.gd"
## Chapter-local combat controls; the mine and scrapyard controllers stay intact.
const PHASE_LAYER:=16
var stats: PlaceholderStats
var shield_energy:=100.0
var guard_age:=1.0
var guard_held:=false
var guard_overheat:=0.0
var guard_regen_delay:=0.0
var dash_seconds:=0.0
var dash_cooldown:=0.0
var air_dash_used:=false
var _dash_direction:=1.0
var _invulnerability:=0.0
var death_height:=2580.0
var _drop_seconds:=0.0

func _ready() -> void:
	super._ready()
	collision_mask=1|PHASE_LAYER|32
	_camera.position=Vector2(0,-90)
	_camera.limit_right=2400
	_camera.limit_bottom=2600
	stats=PlaceholderStats.new()
	add_child(stats)
	stats.restore_stats(GameSession.stats_snapshot())
	stats.health_changed.connect(func(current: int,maximum: int) -> void:
		health=current
		health_changed.emit(current,maximum)
		GameSession.sync_health(current,maximum)
	)
	stats.score_changed.connect(GameSession.sync_score)
	for attack in [combat.close_attack,combat.reach_attack]:
		attack.obstruction_mask=1|32
		attack.show_hitbox=false
		attack.show_placeholder_weapon=false
	_bind(&"eden3_guard",[KEY_K,KEY_Q])
	_bind(&"eden3_dash",[KEY_SHIFT,KEY_L,KEY_F])
	_bind(&"eden3_mineral",[KEY_E,KEY_C,KEY_J])
	_bind(&"eden3_drop",[KEY_S,KEY_DOWN])
	combat.attack_started.connect(func(_profile: MeleeAttackProfile) -> void: WorldProgress.report_ability_used(&"light_blade"))

func _bind(id: StringName,keys: Array) -> void:
	if InputMap.has_action(id): return
	InputMap.add_action(id)
	for key: int in keys:
		var event:=InputEventKey.new()
		event.physical_keycode=key
		InputMap.action_add_event(id,event)

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play():
		guard_held=false
		return
	# HeroActionVisual waits on this timer. It must drain even during global hitstop.
	impact_pause=maxf(0,impact_pause-delta)
	if level.hitstop>0: return
	_clock+=delta
	_invulnerability=maxf(0,_invulnerability-delta)
	cooldown=maxf(0,cooldown-delta)
	dash_cooldown=maxf(0,dash_cooldown-delta)
	_gas_slow=maxf(0,_gas_slow-delta)
	_pulse_age+=delta
	if _drop_seconds>0:
		_drop_seconds=maxf(0,_drop_seconds-delta)
		if _drop_seconds==0: set_collision_mask_value(1,true)
	_update_guard(delta)
	if respawn_seconds>0:
		respawn_seconds=maxf(0,respawn_seconds-delta)
		if respawn_seconds==0: reset_at_checkpoint(level.checkpoint_position)
		return
	var floor_before:=is_on_floor()
	_coyote=coyote_time if floor_before else maxf(0,_coyote-delta)
	if floor_before:
		jumps_used=0
		air_dash_used=false
	_buffer=jump_buffer if Input.is_action_just_pressed(&"eden_jump") else maxf(0,_buffer-delta)
	if floor_before and _buffer>0 and Input.is_action_pressed(&"eden3_drop"):
		_drop_seconds=0.22
		set_collision_mask_value(1,false)
		_buffer=0
		_coyote=0
		position.y+=4
		velocity.y=90
	var axis:=Input.get_axis(&"eden_move_left",&"eden_move_right")
	if dash_seconds<=0:
		velocity.x=axis*speed*(0.65 if guard_held else 1.0)*(0.55 if _gas_slow>0 else 1.0)
		if axis!=0: facing=axis
		velocity.y=minf(velocity.y+gravity*delta,1000)
		if _buffer>0:
			if floor_before or _coyote>0:
				velocity.y=jump_velocity
				jumps_used=1
				_coyote=0
				_buffer=0
				_art.play_action(&"jump",0.1)
			elif jumps_used<2 and WorldProgress.has_ability(&"double_jump"):
				velocity.y=double_jump_velocity
				jumps_used=2
				_buffer=0
				WorldProgress.report_ability_used(&"double_jump")
				_art.play_action(&"double_jump",0.22)
		if Input.is_action_just_pressed(&"eden3_dash"): start_dash()
	else:
		dash_seconds=maxf(0,dash_seconds-delta)
		velocity=Vector2(_dash_direction*680,0)
		if dash_seconds==0:
			set_collision_mask_value(5,true)
			velocity.x=_dash_direction*speed
	if Input.is_action_just_pressed(&"eden_absorb") and level.try_extract(): return
	if Input.is_action_just_pressed(&"eden3_mineral"): cast_pulse()
	move_and_slide()
	if is_on_floor() and not _was_floor:
		jumps_used=0
		air_dash_used=false
		_art.play_action(&"land",0.1)
	_was_floor=is_on_floor()
	if position.y>death_height: dissolve()
	level.update_location()
	queue_redraw()

func _update_guard(delta: float) -> void:
	guard_overheat=maxf(0,guard_overheat-delta)
	guard_regen_delay=maxf(0,guard_regen_delay-delta)
	var held:=Input.is_action_pressed(&"eden3_guard") and WorldProgress.has_ability(&"shield") and guard_overheat<=0 and dash_seconds<=0 and respawn_seconds<=0
	if held and not guard_held:
		guard_age=0
		combat.cancel()
		WorldProgress.report_ability_used(&"shield")
		SoundManager.play_sfx(&"shield",-16)
	guard_held=held
	if guard_held:
		guard_age+=delta
		shield_energy=maxf(0,shield_energy-28*delta)
		guard_regen_delay=0.8
		if shield_energy==0: break_guard()
	elif guard_regen_delay<=0 and guard_overheat<=0:
		shield_energy=minf(100,shield_energy+25*delta)
	WorldProgress.set_shield_active(guard_held)

func break_guard() -> void:
	guard_held=false
	guard_overheat=1.5
	guard_regen_delay=0.8
	WorldProgress.set_shield_active(false)
	level.tell("GUARD BREAK · release and recover", "护盾过热 · 松开等待恢复")

func intercept_projectile(shot: Node2D) -> int:
	if not guard_held or (shot.global_position.x-global_position.x)*facing< -8: return 0
	if guard_age<=0.18:
		shield_energy=minf(100,shield_energy+25)
		level.hitstop=0.06
		impact_pause=0.06
		level.parry_flashes+=1
		_camera_impulse(3,0.09)
		return 2
	shield_energy=maxf(0,shield_energy-8)
	if shield_energy==0: break_guard()
	return 1

func start_dash() -> bool:
	if not WorldProgress.can_play() or dash_seconds>0 or dash_cooldown>0 or air_dash_used or not WorldProgress.has_ability(&"black_pierce"): return false
	_dash_direction=facing
	dash_seconds=0.22
	dash_cooldown=0.75
	air_dash_used=not is_on_floor()
	guard_held=false
	WorldProgress.set_shield_active(false)
	set_collision_mask_value(5,false)
	velocity=Vector2(facing*680,0)
	combat.cancel()
	WorldProgress.report_ability_used(&"black_pierce")
	SoundManager.play_sfx(&"dash",-12)
	_art.play_action(&"black_pierce",0.22)
	return true

func hurt(kind: StringName=&"body") -> void:
	if not WorldProgress.can_play() or _invulnerability>0 or respawn_seconds>0: return
	if kind==&"body" and dash_seconds>0: return
	_invulnerability=0.85
	stats.take_hit()
	_art.play_action(&"hurt",0.22)
	_camera_impulse(3,0.12)

func touch_gas(delta: float) -> void:
	if not WorldProgress.can_play() or respawn_seconds>0: return
	_gas_slow=0.12
	_gas_damage+=delta
	if _gas_damage>=0.8:
		_gas_damage=0
		hurt(&"gas")

func dissolve() -> void:
	if respawn_seconds>0 or not WorldProgress.can_play(): return
	var survived:=GameSession.apply_fall_penalty()
	stats.restore_stats(GameSession.stats_snapshot())
	if not survived: return
	respawn_seconds=0.2
	velocity=Vector2.ZERO
	combat.cancel()
	level.clear_projectiles()

func reset_at_checkpoint(point: Vector2) -> void:
	impact_pause=0
	combat.cancel()
	position=point
	velocity=Vector2.ZERO
	jumps_used=0
	_coyote=0
	_buffer=0
	dash_seconds=0
	air_dash_used=false
	guard_held=false
	set_collision_mask_value(5,true)
	set_collision_mask_value(1,true)
	_drop_seconds=0
	_invulnerability=0.85
	_camera.reset_smoothing()

func air_jump_available() -> bool:
	return WorldProgress.has_ability(&"double_jump") and jumps_used<2

func _unhandled_input(event: InputEvent) -> void:
	if not WorldProgress.can_play() or respawn_seconds>0 or event.is_echo(): return
	if event.is_action_pressed(&"eden_slash") and not guard_held:
		combat.request_attack(false,facing)
		level.interact(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"eden_reach_slash") and not guard_held and dash_seconds<=0:
		combat.request_attack(true,facing)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"eden_talk"):
		level.interact(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"eden_return"): level.restore_oasis()

func _draw() -> void:
	super._draw()
	if guard_held:
		draw_arc(Vector2(facing*12,-5),34,-1.2 if facing>0 else PI-1.2,1.2 if facing>0 else PI+1.2,18,Color("f4efd0") if guard_age<=0.18 else Color("9ccece"),5)
	if dash_seconds>0:
		for index in 5:
			draw_rect(Rect2(-facing*(12+index*15)-9,-22,18,40),Color(0.56,0.36,0.85,0.5-index*0.08))
