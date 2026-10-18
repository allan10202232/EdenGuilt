class_name HeroActionVisual
extends Node2D
## Presentation only. Attack poses read the same phases that drive melee collision.
## ALWAYS permits a final death pose after gameplay simulation has been disabled.

const RED: Texture2D = preload("res://assets/art/generated/animations/hero_red_actions.png")
const GREEN: Texture2D = preload("res://assets/art/generated/animations/hero_green_actions.png")
const POSES := {&"jump":8, &"double_jump":9, &"fall":10, &"land":11, &"channel":20,
	&"shield_raise":18, &"shield":19, &"mineralization":20, &"black_pierce":21,
	&"hurt":22, &"death":23}
# Authored sole baselines, excluding sword trails and particles. Fixed cell rectangles
# preserve body alignment; per-pose grounding avoids the shield/death sprites floating.
const RED_FEET := [242,242,242,242,242,242,254,254,215,249,255,254,233,233,233,233,233,233,220,220,221,217,217,205]
const GREEN_FEET := [247,247,247,247,247,247,255,255,221,255,252,255,234,234,234,235,234,235,220,221,224,221,220,215]
var actor: CharacterBody2D
var sprite: Sprite2D
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
	set_form(WorldProgress.core_reversed)
	for attack in [actor.combat.close_attack,actor.combat.reach_attack]:
		attack.phase_changed.connect(func(_next: int) -> void: _phase_clock=0.0)
	actor.combat.attack_started.connect(func(_profile: MeleeAttackProfile) -> void:
		_pose=&""
		_pose_left=0.0
	)
	actor.combat.target_hit.connect(func(_receiver: Node, hit: Dictionary) -> void:
		_effects.append({"point":hit.position,"life":0.18,"duration":0.18,"kind":&"hit"})
	)
	for event: Signal in [WorldProgress.ability_absorbed,WorldProgress.ability_returned]:
		event.connect(func(_id: StringName) -> void: play_action(&"channel",0.28))
	GameSession.state_changed.connect(_on_state)

func set_form(green: bool) -> void:
	green_form=green
	if sprite!=null: sprite.texture=GREEN if green else RED

func play_action(next: StringName,duration: float) -> void:
	if _dead: return
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
	if not _dead and not WorldProgress.can_play() and WorldProgress.narrative_kind!=&"learning": return
	_clock+=delta
	_phase_clock+=delta
	_pose_left=maxf(0.0,_pose_left-delta)
	for effect in _effects: effect.life-=delta
	_effects=_effects.filter(func(entry: Dictionary) -> bool: return entry.life>0.0)
	var facing: float=actor._facing
	var attack: MeleeAttack=_visible_attack()
	if _dead:
		_death_clock+=delta
		action=&"hurt" if _death_clock<0.12 else &"death"
		sprite.frame=POSES[action]
	elif _pose_left>0.0:
		action=_pose
		sprite.frame=POSES[action]
	elif attack!=null:
		facing=attack._facing
		action=&"close_melee" if attack==actor.combat.close_attack else &"reach_melee"
		var base:=12 if action==&"close_melee" else 15
		sprite.frame=base+clampi(attack.phase-1,0,2)
	elif WorldProgress.shield_active:
		action=&"shield"
		sprite.frame=19
	elif not actor.is_on_floor():
		action=&"jump" if actor.velocity.y<0 else &"fall"
		sprite.frame=POSES[action]
	elif absf(actor.velocity.x)>5:
		action=&"run"
		sprite.frame=int(_clock*(14.0 if absf(actor.velocity.x)>300 else 10.0))%6
		_dust_clock-=delta
		if _dust_clock<=0:
			_dust_clock=0.12
			_effects.append({"point":global_position+Vector2(0,23),"life":0.25,"duration":0.25,"kind":&"dust"})
	else:
		action=&"idle"
		sprite.frame=6+int(_clock*2.0)%2
	sprite.flip_h=facing<0
	sprite.rotation=0.0
	var feet: int=(GREEN_FEET if green_form else RED_FEET)[sprite.frame]
	sprite.position.y=24.0-(feet-128)*0.36 if actor.is_on_floor() or _dead else -20.0
	queue_redraw()

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
	if not _dead and _pose_left<=0 and attack!=null and attack.phase==MeleeAttack.Phase.ACTIVE:
		var reach: float=attack._move.reach
		var face: float=attack._facing
		var progress:=clampf(_phase_clock/attack._move.active_time,0,1)
		if attack==actor.combat.close_attack:
			var angle:=lerpf(-1.25,1.2,progress)
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
