class_name GardenSteward
extends CampaignEnemy
var level: Node2D
var active:=false
var shield_hits:=0
var shield_broken:=false
var reflector: EdenLightReceiver
var _cycle:=1.8
var _charging:=0.0
var _cycle_count:=0
var _charge_direction:=1.0
var _armor_flash:=0.0
var _hint_left:=0.0

func _ready() -> void:
	boss=true
	kind="eden_warden"
	persistent_id=&"eden/steward"
	super._ready()
	health=3
	max_health=3
	_actions.windup_duration=0.6
	reflector=EdenLightReceiver.new()
	reflector.level=level
	reflector.position=Vector2(0,-10)
	reflector.hit_radius=50
	reflector.on_reflect=func(_shot: Node2D) -> bool:
		if not active or shield_broken: return false
		shield_hits+=1
		_stun=2.8
		shield_broken=shield_hits>=2
		if shield_broken:
			level.tell("ARMOR BROKEN · LMB / RMB can now damage the Steward", "装甲已破 · 左键或右键攻击执事")
		else:
			level.tell("ARMOR CRACKED · 1 / 2 · reflect one more energy orb with Q / K", "装甲裂开 · 1 / 2 · 用 Q / K 再弹反一颗能量弹")
		return true
	add_child(reflector)
	reflector.charged.connect(func(_receiver: EdenLightReceiver) -> void:
		if not shield_broken:
			reflector.lit=false
			reflector.hits=0
	)
	_skin.modulate=Color("b7d5b0")

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play() or level.hitstop>0 or not active or health<=0: return
	if impact_pause>0:
		impact_pause=maxf(0,impact_pause-delta)
		return
	_clock+=delta
	_armor_flash=maxf(0,_armor_flash-delta)
	_hint_left=maxf(0,_hint_left-delta)
	_stun=maxf(0,_stun-delta)
	_recovery=maxf(0,_recovery-delta)
	velocity.y+=980*delta
	velocity.x=0
	if _stun>0:
		_charging=0
		_windup=0
	elif _recovery>0:
		pass
	elif _windup>0:
		_windup=maxf(0,_windup-delta)
		if _windup==0:
			_charging=0.65
			_actions.strike()
	elif _charging>0:
		_charging=maxf(0,_charging-delta)
		_direction=_charge_direction
		velocity.x=_charge_direction*330
		if _charging==0: _recovery=0.65
	else:
		var direction:=signf(player.position.x-position.x)
		if direction!=0: _direction=direction
		_cycle-=delta
		if _cycle<=0:
			_cycle_count+=1
			if _cycle_count%3==0:
				_windup=0.6
				_charge_direction=_direction
			else:
				level.fire(position+Vector2(0,-12),(player.position-position).normalized(),190,self)
				level.fire(position+Vector2(0,25),Vector2(_direction,0),260,self,true)
				_actions.strike()
			_cycle=2.3
	move_and_slide()
	if position.x<1230 or position.x>1900:
		position.x=clampf(position.x,1230,1900)
		if _charging>0:
			_charging=0
			_recovery=0.9
	_actions.charge_active=_charging>0 and _stun<=0
	_actions.stagger_active=_stun>0 or _recovery>0
	if _stun<=0 and _recovery<=0 and _hurtbox.overlaps_body(player): player.hurt(&"body")
	queue_redraw()

func receive_melee_hit(hit: Dictionary) -> bool:
	if not active or not WorldProgress.can_play(): return false
	if not shield_broken:
		_armor_flash=0.18
		if _hint_left<=0:
			_hint_left=1.0
			level.tell("ARMORED · Q / K: reflect %d more energy orb(s) to break armor"%(2-shield_hits), "装甲抵挡 · 用 Q / K 再弹反 %d 颗能量弹破甲"%(2-shield_hits))
		queue_redraw()
		return false
	return super.receive_melee_hit(hit)

func _draw() -> void:
	if not shield_broken: draw_arc(Vector2(0,-5),57,0,TAU,40,Color("fff0c1") if _armor_flash>0 else Color("d0e9bd"),6 if _armor_flash>0 else 4)
	if _windup>0: draw_line(Vector2(0,37),Vector2(_charge_direction*215,37),Color("f0ba86"),4)
