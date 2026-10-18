class_name EdenHeartGuard
extends CampaignEnemy
var controller: Node2D
var charge_left:=0.0
const RECOVERY_SECONDS:=5.4

func _ready() -> void:
	boss=true
	kind="eden_warden"
	super._ready()
	_windup=0.8
	health=3
	max_health=3
	_actions.windup_duration=0.8

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play() or controller.level.hitstop>0 or controller.phase!=2: return
	if impact_pause>0:
		impact_pause=maxf(0,impact_pause-delta)
		return
	_clock+=delta
	velocity.y+=980*delta
	if _recovery>0:
		_recovery=maxf(0,_recovery-delta)
		velocity.x=0
		if _recovery==0: _windup=0.8
	elif _windup>0:
		_windup=maxf(0,_windup-delta)
		velocity.x=0
		if _windup>0.2: _direction=1 if player.position.x>=position.x else -1
		if _windup==0:
			charge_left=2.4
			_actions.strike()
	elif charge_left>0:
		charge_left=maxf(0,charge_left-delta)
		velocity.x=_direction*650
		if position.x<570 or position.x>2200 or charge_left==0:
			position.x=clampf(position.x,570,2200)
			charge_left=0
			_recovery=RECOVERY_SECONDS
			velocity.x=0
			controller.level.tell("WALL IMPACT · weak point exposed", "撞墙硬直 · 弱点暴露")
	move_and_slide()
	_actions.charge_active=charge_left>0
	_actions.stagger_active=_recovery>0
	if _recovery<=0 and _hurtbox.overlaps_body(player): player.hurt(&"body")
	queue_redraw()

func receive_melee_hit(hit: Dictionary) -> bool:
	if controller.phase!=2 or _recovery<=0:
		controller.explain_armor()
		return false
	if not controller.damage_weakpoint(hit): return false
	_actions.hurt()
	impact_pause=0.045
	return true

func _draw() -> void:
	if _recovery>0:
		draw_arc(Vector2(0,-5),54,0,TAU,32,Color(0.75,1.0,0.74,0.55+sin(_clock*7)*0.2),3)
	if _windup>0:
		draw_line(Vector2.ZERO,Vector2(_direction*280,0),Color("e4ad87"),3)
		for index in 5: draw_rect(Rect2(_direction*(70+index*40)-3,29,6,5),Color("eed8a1"))
