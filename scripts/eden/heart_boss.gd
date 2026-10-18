class_name EdenHeartBoss
extends Node2D
var level: Node2D
var phase:=1
var health:=9
var max_health:=9
var active:=false
var dismantled:=false
var exposed:=0.0
var _shots:=1.4
var _clock:=0.0
var core_lock: EdenLightReceiver
var left_line: EdenLightReceiver
var guard: EdenHeartGuard
var right_lock: EdenBreakableDevice
var left_cut:=false
var right_cut:=false
var _melee_guard:=0.0
var _hit_flash:=0.0
var _hint_left:=0.0
var _shot_windup:=0.0
const EXPOSURE_SECONDS:=20.0

func _ready() -> void:
	z_index=4
	core_lock=EdenLightReceiver.new()
	core_lock.level=level
	core_lock.required_hits=3
	core_lock.hit_radius=57
	core_lock.on_reflect=func(_shot: Node2D) -> bool: return active and phase==1 and exposed<=0
	add_child(core_lock)
	core_lock.charged.connect(func(_receiver: EdenLightReceiver) -> void:
		exposed=EXPOSURE_SECONDS
		_shot_windup=0
		level.tell("BARRIER OPEN · crystallize, climb, strike the device", "护壁已开 · 矿化攀升，攻击抽取装置")
	)
	var hurtbox:=MeleeHurtbox.new()
	hurtbox.collision_layer=4
	hurtbox.collision_mask=0
	var shape:=CollisionShape2D.new()
	var circle:=CircleShape2D.new()
	circle.radius=58
	shape.shape=circle
	hurtbox.add_child(shape)
	add_child(hurtbox)
	left_line=EdenLightReceiver.new()
	left_line.level=level
	left_line.position=Vector2(-510,80)
	left_line.hit_radius=30
	left_line.on_reflect=func(_shot: Node2D) -> bool: return active and phase==3
	add_child(left_line)
	left_line.charged.connect(func(_receiver: EdenLightReceiver) -> void:
		left_cut=true
		health-=1
		_save()
		_check_finish()
	)
	right_lock=EdenBreakableDevice.new()
	right_lock.level=level
	right_lock.position=Vector2(880,-112)
	right_lock.allowed=func() -> bool: return active and phase==3
	right_lock.on_break=func() -> void:
		right_cut=true
		health-=2
		_save()
		_check_finish()
	add_child(right_lock)
	var data:=WorldProgress.eden_chapter
	phase=data.get("phase",1)
	health=data.get("boss_hp",9)
	left_cut=data.get("left_cut",false)
	right_cut=data.get("right_cut",false)
	dismantled=data.get("dismantled",false)
	left_line.lit=left_cut
	right_lock.activated=right_cut
	if phase==2: _spawn_guard.call_deferred()

func _physics_process(delta: float) -> void:
	if not active or dismantled or not WorldProgress.can_play() or level.hitstop>0: return
	_clock+=delta
	_melee_guard=maxf(0,_melee_guard-delta)
	_hit_flash=maxf(0,_hit_flash-delta)
	_hint_left=maxf(0,_hint_left-delta)
	if exposed>0:
		exposed=maxf(0,exposed-delta)
		if exposed==0:
			core_lock.lit=false
			core_lock.hits=0
	if phase==1 and exposed>0:
		queue_redraw()
		return
	_shots-=delta
	if _shot_windup>0:
		_shot_windup=maxf(0,_shot_windup-delta)
		if _shot_windup==0:
			if phase==1:
				level.fire(global_position,(level.player.position-global_position).normalized(),180,self)
			elif phase==3:
				level.fire(Vector2(450,440),Vector2.RIGHT,200,self)
			_shots=1.65
	elif _shots<=0 and phase in [1,3]:
		_shot_windup=0.45
	queue_redraw()

func explain_armor() -> void:
	if _hint_left>0 or not active or dismantled or not WorldProgress.can_play(): return
	_hint_left=1.0
	if phase==1:
		level.tell("BARRIER · Q / K: parry 3 orbs, then strike the glowing core", "护壁抵挡 · 用 Q / K 弹反 3 弹，再攻击发光核心")
	elif phase==2:
		level.tell("ARMORED CHARGE · dodge through it; strike the GREEN weak point after wall impact", "冲锋装甲抵挡 · 穿身躲避，撞墙后攻击绿色弱点")
	elif phase==3:
		level.tell("SUPPLY LOCKS · parry the LEFT line, cut the UPPER-RIGHT lock", "供能锁尚在 · 弹反左侧供能线，攻击右上方抽取锁")

func receive_melee_hit(hit: Dictionary) -> bool:
	if not active or dismantled or not WorldProgress.can_play(): return false
	if phase!=1 or exposed<=0:
		explain_armor()
		return false
	if _melee_guard>0: return false
	_melee_guard=0.28
	health=maxi(6,health-maxi(1,int(hit.get("damage",1))))
	_hit_feedback(hit)
	if health<=6:
		phase=2
		exposed=0
		level.clear_projectiles()
		_spawn_guard()
		level.tell("PREDATION · dash THROUGH the charge, strike after impact", "掠夺协议 · 黑冲穿过冲锋，撞墙后反击")
	_save()
	return true

func _spawn_guard() -> void:
	if is_instance_valid(guard): return
	guard=EdenHeartGuard.new()
	guard.controller=self
	guard.player=level.player
	guard.position=Vector2(850,576)
	level.add_child(guard)
	guard.visible=phase==2

func damage_weakpoint(hit: Dictionary) -> bool:
	if not active or phase!=2 or _melee_guard>0 or not WorldProgress.can_play(): return false
	_melee_guard=0.28
	health=maxi(3,health-maxi(1,int(hit.get("damage",1))))
	_hit_feedback(hit)
	if health<=3:
		phase=3
		level.clear_projectiles()
		guard.hide()
		guard.set_physics_process(false)
		level.tell("HARVEST · parry the left line, sever the upper-right lock", "收割协议 · 盾反左侧供能，登右上平台切断抽取锁")
	_save()
	return true

func _hit_feedback(hit: Dictionary) -> void:
	_hit_flash=0.2
	hit["boss"]=true
	level.player.combat.pause_impact(0.045)
	SoundManager.play_sfx(&"impact_heavy" if hit.get("attack_id",&"")==&"reach_melee" else &"impact_light",-9)

func _check_finish() -> void:
	if not left_cut or not right_cut: return
	dismantled=true
	active=false
	health=0
	phase=4
	_save()
	if WorldProgress.mark_enemy_defeated(&"remnant_sea/boss"):
		level.player.stats.add_score(1000)
	level.clear_projectiles()
	WorldProgress.reveal_truth()

func _save() -> void:
	WorldProgress.eden_chapter.merge({"phase":phase,"boss_hp":health,"left_cut":left_cut,"right_cut":right_cut,"dismantled":dismantled},true)

func _draw() -> void:
	var color:=Color("c6d6bd") if not dismantled else Color("698376")
	var art=preload("res://scripts/mine_challenge/mine_art.gd")
	var pulse:=sin(_clock*2.2)*1.5
	art.draw_at(self,8,Rect2(-74,-84+pulse,148,165),Color("f2f9dc") if _hit_flash>0 else Color("8bada0"))
	if _shot_windup>0:
		draw_arc(Vector2.ZERO,35+(1.0-_shot_windup/0.45)*22,0,TAU,24,Color("ffe7a3"),3)
	draw_circle(Vector2.ZERO,23,Color(0.64,0.9,0.79,0.5) if exposed>0 else Color(0.3,0.49,0.4,0.4))
	draw_arc(Vector2.ZERO,68,_clock,TAU+_clock,48,Color("b5e8c6") if exposed>0 else Color("b99a7a"),2)
	for index in 6:
		var point:=Vector2.from_angle(TAU*index/6+_clock*.12)*78
		draw_rect(Rect2(point-Vector2(5,5),Vector2(10,10)),color)
	GothicSkin.draw_text(self,ThemeDB.fallback_font,Vector2(-85,-95),"EXTRACTION CORE",15)
