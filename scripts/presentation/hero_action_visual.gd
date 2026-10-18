class_name HeroActionVisual
extends Node2D
## Presentation only. Attack poses read the same phases that drive melee collision.
## ALWAYS permits a final death pose after gameplay simulation has been disabled.

const RED: Texture2D = preload("res://assets/art/generated/animations/hero_red_actions.png")
const GREEN: Texture2D = preload("res://assets/art/generated/animations/hero_green_actions.png")
const MOTION_RED: Texture2D = preload("res://assets/art/generated/animations/hero_red_motion.png")
const MOTION_GREEN: Texture2D = preload("res://assets/art/generated/animations/hero_green_motion.png")
const MOTION_RED_FEET := [245,245,245,244,247,245,255,255,231,255,255,255,237,237,237,237,237,237,220,220,220,220,220,220]
const MOTION_GREEN_FEET := [250,253,253,253,253,253,255,255,225,247,249,255,245,244,244,245,245,245,224,226,222,226,226,226]
const EXTRACTION: Texture2D = preload("res://assets/art/generated/animations/hero_extract_actions.png")
const EXTRACTION_FEET := [487, 488, 488, 454, 455, 452]
const EXTRACTION_FOCUS := [Vector2(2, 2), Vector2(21, 2), Vector2(26, 19), Vector2(27, 1), Vector2(21, -18), Vector2(20, 2)]
const POSES := {&"jump":8, &"double_jump":9, &"fall":10, &"land":11, &"channel":20,
	&"shield_raise":18, &"shield":19, &"mineralization":20, &"black_pierce":21,
	&"hurt":22, &"death":23}
# Authored sole baselines, excluding sword trails and particles. Fixed cell rectangles
# preserve body alignment; per-pose grounding avoids the shield/death sprites floating.
const RED_FEET := [242,242,242,242,242,242,254,254,215,249,255,254,233,233,233,233,233,233,220,220,221,217,217,205]
const GREEN_FEET := [247,247,247,247,247,247,255,255,221,255,252,255,234,234,234,235,234,235,220,221,224,221,220,215]
var actor: CharacterBody2D
var sprite: Sprite2D
var extraction_sprite: Sprite2D
var action: StringName = &"idle"
var green_form := false
var _clock := 0.0
var _pose: StringName
var _pose_left := 0.0
var _phase_clock := 0.0
var _dead := false
var _death_clock := 0.0
var _dust_clock := 0.0
var _effects: Array[Dictionary] = []
var _lighting: ShaderMaterial
var _extraction_lighting: ShaderMaterial
var _land_time := 0.0
var _turn_time := 0.0
var _last_facing := 1.0
var using_motion := true

func bind(player: CharacterBody2D) -> void:
	actor=player
	process_mode=Node.PROCESS_MODE_ALWAYS
	sprite=Sprite2D.new()
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture=RED
	sprite.hframes=6
	sprite.vframes=4
	sprite.scale=Vector2.ONE*0.36
	sprite.position=Vector2(0,-20)
	add_child(sprite)
	_lighting = ShaderMaterial.new()
	_lighting.shader = preload("res://assets/shaders/actor_lighting.gdshader")
	sprite.material = _lighting
	extraction_sprite = Sprite2D.new()
	extraction_sprite.texture = EXTRACTION
	extraction_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	extraction_sprite.hframes = 3
	extraction_sprite.vframes = 2
	extraction_sprite.scale = Vector2.ONE * 0.18
	extraction_sprite.hide()
	add_child(extraction_sprite)
	_extraction_lighting = _lighting.duplicate() as ShaderMaterial
	_extraction_lighting.set_shader_parameter("cells",Vector2(3,2))
	extraction_sprite.material = _extraction_lighting
	set_form(WorldProgress.core_reversed)
	for attack in [actor.combat.close_attack,actor.combat.reach_attack]:
		attack.phase_changed.connect(func(_next: int) -> void: _phase_clock=0.0)
	actor.combat.attack_started.connect(func(_profile: MeleeAttackProfile) -> void:
		_pose=&""
		_pose_left=0.0
	)
	actor.combat.target_hit.connect(func(_receiver: Node, hit: Dictionary) -> void:
		_effects.append({"point":hit.position,"life":0.18,"duration":0.18,"kind":&"hit"})
		# The first collision can precede this node's next render update.
		# Freeze the striking pose, never the preceding anticipation frame.
		var attack := _visible_attack()
		if attack!=null:
			using_motion=true
			action=&"close_melee" if attack==actor.combat.close_attack else &"reach_melee"
			sprite.texture=MOTION_GREEN if green_form else MOTION_RED
			sprite.frame=14 if action==&"close_melee" else 20
			sprite.flip_h=attack._facing<0
		queue_redraw()
	)
	for event: Signal in [WorldProgress.ability_absorbed,WorldProgress.ability_returned]:
		event.connect(func(_id: StringName) -> void:
			if not actor.extracting:
				play_action(&"channel",0.28)
		)
	GameSession.state_changed.connect(_on_state)
	WorldProgress.world_changed.connect(_refresh_light)
	_refresh_light()

func set_form(green: bool) -> void:
	green_form=green
	if sprite!=null: sprite.texture=(MOTION_GREEN if green else MOTION_RED) if using_motion else (GREEN if green else RED)

func _refresh_light() -> void:
	for light: ShaderMaterial in [_lighting,_extraction_lighting]:
		light.set_shader_parameter("ambient",ActorGrounding.ambient_color())
		light.set_shader_parameter("energy_tint",Color(0.25,1.0,0.55) if green_form else Color(1.0,0.38,0.18))

func play_action(next: StringName,duration: float) -> void:
	if _dead: return
	if next==&"land": _land_time=0.12
	if next not in [&"land",&"jump",&"double_jump"] or _visible_attack()==null:
		_pose=next
		_pose_left=duration
	if next in [&"jump",&"double_jump",&"land",&"mineralization"]:
		_effects.append({"point":global_position+Vector2(0,23),"life":0.32,"duration":0.32,"kind":next})

func _on_state(_previous: int,current: int) -> void:
	if current==GameSession.State.GAME_OVER:
		_dead=true
		_death_clock=0.0
		actor.modulate.a=1.0

func _process(delta: float) -> void:
	if not is_instance_valid(actor) or not actor.is_inside_tree(): return
	if not _dead and not WorldProgress.can_play() and not actor.extracting: return
	if not _dead and actor.impact_pause>0.0: return
	_clock+=delta
	_phase_clock+=delta
	_pose_left=maxf(0.0,_pose_left-delta)
	# A guard pose must not pin the body while its actual motion continues.
	if _pose==&"shield_raise" and (not WorldProgress.shield_active or not actor.is_on_floor() or absf(actor.velocity.x)>5):
		_pose_left=0.0
	_land_time=maxf(0.0,_land_time-delta)
	_turn_time=maxf(0.0,_turn_time-delta)
	for effect in _effects: effect.life-=delta
	_effects=_effects.filter(func(entry: Dictionary) -> bool: return entry.life>0.0)
	if actor.extracting and not _dead:
		action = &"extract"
		_pose_left = 0.0
		var progress: float = actor.extraction_progress
		var frame := 0 if progress < 0.12 else 1 if progress < 0.24 else 2 if progress < 0.45 else 3 if progress < 0.68 else 4 if progress < 0.9 else 5
		sprite.hide()
		extraction_sprite.show()
		extraction_sprite.frame = frame
		extraction_sprite.flip_h = actor._facing < 0
		extraction_sprite.position.y = 24.0 - (EXTRACTION_FEET[frame] - 256) * 0.18
		_extraction_lighting.set_shader_parameter("energy",sin(progress*PI))
		queue_redraw()
		return
	extraction_sprite.hide()
	sprite.show()
	var facing: float=actor._facing
	var attack: MeleeAttack=_visible_attack()
	using_motion = false
	if _dead:
		_death_clock+=delta
		action=&"hurt" if _death_clock<0.12 else &"death"
		sprite.frame=POSES[action]
	elif _pose_left>0.0 and _pose not in [&"land",&"jump",&"double_jump"]:
		action=_pose
		sprite.frame=POSES[action]
	elif attack!=null:
		using_motion = true
		facing=attack._facing
		action=&"close_melee" if attack==actor.combat.close_attack else &"reach_melee"
		var base:=12 if action==&"close_melee" else 18
		sprite.frame=base+clampi(attack.phase-1,0,2)*2+mini(1,int(attack.phase_progress()*2.0))
	elif _pose_left>0.0:
		using_motion = true
		action = _pose
		sprite.frame = POSES[action]
	elif WorldProgress.shield_active and actor.is_on_floor() and absf(actor.velocity.x)<=5:
		action=&"shield"
		sprite.frame=19
	elif not actor.is_on_floor():
		using_motion = true
		action=&"jump" if actor.velocity.y<0 else &"fall"
		sprite.frame=POSES[action]
	elif absf(actor.velocity.x)>5:
		using_motion = true
		action=&"run"
		sprite.frame=int(_clock*(14.0 if absf(actor.velocity.x)>300 else 10.0))%6
		_dust_clock-=delta
		if _dust_clock<=0:
			_dust_clock=0.12
			_effects.append({"point":global_position+Vector2(0,23),"life":0.25,"duration":0.25,"kind":&"dust"})
	else:
		using_motion = true
		action=&"idle"
		sprite.frame=6+int(_clock*2.0)%2
	sprite.texture=(MOTION_GREEN if green_form else MOTION_RED) if using_motion else (GREEN if green_form else RED)
	sprite.flip_h=facing<0
	sprite.rotation=0.0
	if facing!=_last_facing:
		_turn_time = 0.09
		_last_facing = facing
	var scale_base := 0.375 if using_motion else 0.36
	var compression := sin(_land_time/0.12*PI)*0.065 if actor.is_on_floor() else 0.0
	sprite.scale=Vector2(scale_base*(1.0+compression*0.5-_turn_time*0.45),scale_base*(1.0-compression))
	var feet: int=((MOTION_GREEN_FEET if green_form else MOTION_RED_FEET) if using_motion else (GREEN_FEET if green_form else RED_FEET))[sprite.frame]
	sprite.position.y=roundf(24.0-(feet-128)*sprite.scale.y) if using_motion or actor.is_on_floor() or _dead else -20.0
	var lean := clampf(actor.velocity.x/160.0,-2.0,2.0)
	if attack!=null:
		lean = attack._facing * (-2.0 if attack.phase==MeleeAttack.Phase.WINDUP else 3.0 if attack.phase==MeleeAttack.Phase.ACTIVE else 1.0)
	sprite.position.x=roundf(lean)
	_lighting.set_shader_parameter("flash",0.6 if action==&"hurt" and _pose_left>0.15 else 0.0)
	_lighting.set_shader_parameter("energy",0.8 if attack!=null or WorldProgress.shield_active or action in [&"channel",&"mineralization",&"black_pierce"] else 0.0)
	queue_redraw()

func extraction_focus() -> Vector2:
	var point: Vector2 = EXTRACTION_FOCUS[extraction_sprite.frame]
	point.x *= actor._facing
	return actor.global_position + point

func _visible_attack() -> MeleeAttack:
	for attack: MeleeAttack in [actor.combat.close_attack,actor.combat.reach_attack]:
		if attack.phase in [MeleeAttack.Phase.WINDUP,MeleeAttack.Phase.ACTIVE,MeleeAttack.Phase.RECOVERY]: return attack
	return null

func _draw() -> void:
	if not is_instance_valid(actor): return
	var tint:=Color(0.4,1,0.68) if green_form else Color(1,0.4,0.32)
	for effect in _effects:
		var progress: float=1.0-effect.life/effect.duration
		var center:=to_local(effect.point)
		var color:=Color(tint,1.0-progress)
		if effect.kind==&"hit":
			for index in 6:
				var ray:=Vector2.RIGHT.rotated(TAU*index/6.0+0.3)
				draw_line(center+ray*(5+progress*10),center+ray*(15+progress*24),color,2)
		elif effect.kind==&"mineralization":
			draw_arc(center,18+progress*55,PI,TAU,24,Color(0.48,0.95,1,1-progress),3)
		else:
			draw_arc(center,8+progress*(33 if effect.kind!=&"dust" else 12),PI,TAU,16,Color(tint,(1-progress)*0.6),2)
	var attack:=_visible_attack()
	if not _dead and attack!=null and attack.phase==MeleeAttack.Phase.ACTIVE:
		var reach: float=attack._move.reach
		var face: float=attack._facing
		var progress:=attack.phase_progress()
		if attack==actor.combat.close_attack:
			var angle:=lerpf(0.15,1.0,progress)
			var points:=PackedVector2Array()
			for index in 18:
				var a:=angle-float(index)*0.055
				points.append(Vector2(cos(a)*face,sin(a))*(reach+8)+Vector2(face*8,-4))
			draw_polyline(points,Color(tint,0.8),5,true)
		else:
			var tip:=Vector2(face*(14+reach),-4)
			draw_line(Vector2(face*24,-4),tip,Color(tint,0.75),5,true)
			draw_line(tip-Vector2(face*18,9),tip,Color(1,1,0.9),2,true)
			draw_line(tip+Vector2(-face*18,9),tip,Color(1,1,0.9),2,true)
