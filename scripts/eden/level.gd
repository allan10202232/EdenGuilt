class_name EdenChapterLevel
extends Node2D
## Production chapter 03. All mutable progress is run-scoped, never kept in art.
const VentScene=preload("res://scenes/mine_challenge/toxic_gas_vent.tscn")
var region_id:=&"remnant_sea"
var player: EdenChapterPlayer
var current_node:=1
var checkpoint_position:=EdenBlueprint.ENTRY
var hitstop:=0.0
var parry_flashes:=0
var decks: Array[Rect2]=[]
var vents: Array[Node2D]=[]
var turrets: Array[EdenTurret]=[]
var pods: Array[EdenCultivationPod]=[]
var corridor_receivers: Array[EdenLightReceiver]=[]
var corridor_gate: EdenPhaseWall
var maintenance_wall: EdenPhaseWall
var dual_gate: EdenPhaseWall
var dual_phase: EdenPhaseWall
var pod_phase: EdenPhaseWall
var elevator_partition: EdenPhaseWall
var oren_exit: EdenPhaseWall
var dual_receiver: EdenLightReceiver
var dual_seconds:=0.0
var dual_crossed:=false
var conduit: EdenBreakableDevice
var steward: GardenSteward
var boss: EdenHeartBoss
var extraction: LandExtraction
var ecology: EdenChapterEcology
var sources: Array[CampaignOasis]=[]
var chapter_status: ChapterStatusHUD
var _hud: Control
var _settings: SettingsPanel
var _shield_meter: ProgressBar
var _shield_text: Label
var _abilities: Label
var _objective: Label
var _notice: Label
var _notice_left:=0.0
var _boss_panel: VBoxContainer
var _boss_bar: ProgressBar
var _boss_text: Label
var _rescue: Label
var _return_started:=false
var _leaving:=false
var _local_choice: Control
var _local_result: Control
var _followers: Array[Node2D]=[]
var _oren: Node2D
var _elevator_seconds:=0.0
var _entrance_hint: Label
var interaction_hints: Node2D
const EXIT_RADIUS:=250.0

func _ready() -> void:
	set_meta(&"custom_hud",true)
	add_to_group(&"eden_chapter_level")
	var standalone:=get_parent().name!="LevelRoot"
	if standalone:
		WorldProgress.campaign_rules=true
		if GameSession.state!=GameSession.State.PLAYING: GameSession.start_run()
		WorldProgress.current_scene=&"lone_tree"
		WorldProgress.borrow_ability(&"double_jump")
		WorldProgress.current_scene=&"grassland"
		WorldProgress.borrow_ability(&"mineralization")
		WorldProgress.current_scene=&"remnant_sea"
	WorldProgress.finish_scene_load()
	WorldProgress.eden_chapter["active"]=true
	current_node=WorldProgress.eden_chapter.get("node",1)
	checkpoint_position=WorldProgress.eden_chapter.get("checkpoint",EdenBlueprint.ENTRY)
	EdenInputBindings.configure()
	for rect: Rect2 in EdenBlueprint.DECKS: deck(rect)
	player=EdenChapterPlayer.new()
	player.name="Player"
	player.level=self
	player.position=checkpoint_position
	add_child(player)
	_build_interactions()
	boss=EdenHeartBoss.new()
	boss.level=self
	boss.position=Vector2(1200,360)
	add_child(boss)
	boss.active=current_node>=9 and not boss.dismantled
	var environment:=EdenChapterEnvironment.new()
	environment.level=self
	add_child(environment)
	extraction=LandExtraction.new()
	add_child(extraction)
	ecology=EdenChapterEcology.new()
	ecology.eden=self
	add_child(ecology)
	_build_hud()
	_build_interaction_hints()
	if standalone:
		_local_choice=preload("res://scripts/ui/truth_dialog.gd").new()
		_hud.add_child(_local_choice)
		WorldProgress.truth_requested.connect(_local_choice.present)
		_local_result=preload("res://scenes/ui/result_dialog.tscn").instantiate()
		_hud.add_child(_local_result)
		_local_result.hide()
		GameSession.state_changed.connect(func(_old: int,state: int) -> void:
			if state==GameSession.State.GAME_OVER or state==GameSession.State.VICTORY: _local_result.present(GameSession.last_result)
			elif state==GameSession.State.PLAYING: get_tree().reload_current_scene.call_deferred()
			elif state==GameSession.State.MAIN_MENU: get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")
		)
		WorldProgress.scene_requested.connect(func(_id: StringName) -> void: get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn"))
	WorldProgress.world_changed.connect(_on_world_changed)
	WorldProgress.ability_absorbed.connect(func(id: StringName) -> void:
		if id==&"shield": tell("SHIELD · hold Q / K. Tap on impact to reflect. RMB remains the heavy slash.","护盾 · 按住 Q / K，命中前短按弹反；右键仍为重击。")
		elif id==&"black_pierce": tell("DARK DASH · Shift / L (F). Phase through purple walls.","黑冲 · Shift / L（F）；穿过紫色相位墙。")
	)
	WorldProgress.set_checkpoint(&"eden/node/%d"%current_node,checkpoint_position,EdenBlueprint.title(current_node))
	_on_world_changed()
	tell("01 · Inspect the city's promises with T. Follow the stairs on the left.","01 · 按 T 阅读城市承诺，向左沿阶梯攀升。")

func deck(rect: Rect2) -> void:
	decks.append(rect)
	var body:=StaticBody2D.new()
	body.collision_layer=1
	var collision:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=rect.size
	collision.shape=box
	collision.position=rect.get_center()
	collision.one_way_collision=true
	body.add_child(collision)
	add_child(body)

func _wall(point: Vector2,size: Vector2,gate: bool=false) -> EdenPhaseWall:
	var wall:=EdenPhaseWall.new()
	wall.position=point
	wall.wall_size=size
	wall.energy_gate=gate
	add_child(wall)
	return wall

func _receiver(point: Vector2,id: StringName) -> EdenLightReceiver:
	var receiver:=EdenLightReceiver.new()
	receiver.level=self
	receiver.receiver_id=id
	receiver.position=point
	add_child(receiver)
	return receiver

func _turret(point: Vector2,direction: Vector2,interval: float=2.2) -> EdenTurret:
	var turret:=EdenTurret.new()
	turret.level=self
	turret.position=point
	turret.direction=direction
	turret.interval=interval
	turret.countdown=interval
	add_child(turret)
	turrets.append(turret)
	return turret

func _vent(point: Vector2,width: float=120) -> void:
	var vent:=VentScene.instantiate()
	vent.position=point
	vent.width=width
	vent.duration=4.0
	add_child(vent)
	vents.append(vent)

func _label(point: Vector2,text: String,font_size: int=17) -> Label:
	var label:=Label.new()
	label.position=point
	label.text=text
	label.theme=preload("res://assets/ui_theme.tres")
	label.add_theme_font_size_override(&"font_size",font_size)
	label.add_theme_constant_override(&"outline_size",4)
	label.add_theme_color_override(&"font_outline_color",Color("15221b"))
	add_child(label)
	return label

func _build_interactions() -> void:
	for index in 12:
		var info: Dictionary=EdenBlueprint.NODES[index]
		_label(info.point+Vector2(-30,-100),"[%02d] · %dF"%[index+1,info.floor],15)
	_label(Vector2(1530,2320),EdenBlueprint.text("ZERO EMISSIONS*\n*within the city boundary","零排放*\n*仅限城界以内"))
	_label(Vector2(880,2300),EdenBlueprint.text("TREE OF LIFE","生命之树"))
	_label(Vector2(430,2320),EdenBlueprint.text("ASCENSION SELECTION","荣升选拔"))
	_label(Vector2(2100,1810),EdenBlueprint.text("ASCEND / DESCEND","升降梯"))
	_entrance_hint=_label(Vector2(2020,2210),"",16)
	_entrance_hint.size=Vector2(300,66)
	_entrance_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_entrance_hint.hide()
	for entry in [{"id":&"shield","point":Vector2(350,1920),"biome":"eden"},{"id":&"black_pierce","point":Vector2(2240,1320),"biome":"mine"}]:
		var source: CampaignOasis=EdenPhaseSource.new() if entry.id==&"black_pierce" else CampaignOasis.new()
		add_child(source)
		source.setup(entry.id,entry.biome,entry.point)
		sources.append(source)
		_label(entry.point+Vector2(-95,-130),AbilityCatalog.definition(entry.id).name,15)
	for index in 3:
		var y:=1858.0-index*62
		var receiver:=_receiver(Vector2(1070,y),StringName("mirror/%d"%index))
		receiver.lit=WorldProgress.eden_chapter.get("mirror",false) or index in WorldProgress.eden_chapter.get("mirror_lights",[])
		receiver.charged.connect(func(_receiver_node: EdenLightReceiver) -> void:
			var lights: Array=WorldProgress.eden_chapter.get("mirror_lights",[])
			if index not in lights: lights.append(index)
			WorldProgress.eden_chapter["mirror_lights"]=lights
			_check_mirrors()
		)
		corridor_receivers.append(receiver)
		_turret(Vector2(960,y),Vector2.LEFT,2.7+index*.2)
	corridor_gate=_wall(Vector2(1140,1800),Vector2(22,240),true)
	corridor_gate.set_open(WorldProgress.eden_chapter.get("mirror",false))
	if not WorldProgress.eden_chapter.get("steward",false):
		steward=GardenSteward.new()
		steward.level=self
		steward.player=player
		steward.position=Vector2(1640,1876)
		add_child(steward)
		steward.defeated.connect(func(_enemy: CampaignEnemy) -> void:
			WorldProgress.eden_chapter["steward"]=true
			advance(4,Vector2(2110,1898))
		)
	maintenance_wall=_wall(Vector2(2055,1190),Vector2(24,260))
	_wall(Vector2(1790,970),Vector2(24,180))
	oren_exit=_wall(Vector2(2015,965),Vector2(24,190),true)
	oren_exit.set_open(WorldProgress.eden_chapter.get("oren",false))
	conduit=EdenBreakableDevice.new()
	conduit.level=self
	conduit.position=Vector2(1920,1028)
	conduit.activated=WorldProgress.eden_chapter.get("oren",false)
	conduit.on_break=func() -> void:
		WorldProgress.eden_chapter["oren"]=true
		oren_exit.set_open(true)
		tell("OREN: They are people, not fuel. Break the core's extraction locks.","奥伦：他们是人，不是燃料。去切断核心的抽取锁。")
	add_child(conduit)
	_label(Vector2(1770,860),EdenBlueprint.text("OREN · POWER CONDUIT","奥伦 · 供能管"),14)
	_oren=_resident(Vector2(1880,1038),Color("d6bd8b"))
	dual_gate=_wall(Vector2(1300,953),Vector2(24,214),true)
	dual_phase=_wall(Vector2(1080,953),Vector2(24,214))
	dual_receiver=_receiver(Vector2(1230,1015),&"dual")
	_label(Vector2(1120,997),EdenBlueprint.text("← DASH","← 黑冲"),14)
	dual_receiver.charged.connect(func(_receiver_node: EdenLightReceiver) -> void:
		dual_seconds=6
		dual_gate.set_open(true)
		tell("LOCK CHARGED · 6 seconds: cross the gate, dash through the phase wall", "能源锁已充能 · 6 秒内过门并黑冲穿墙")
	)
	_turret(Vector2(1100,1015),Vector2.RIGHT,2.5)
	for index in 5: _vent(Vector2(200 if index%2==0 else 350,1190-index*120),132)
	_wall(Vector2(275,885),Vector2(22,210))
	_turret(Vector2(630,875),Vector2.LEFT,2.2)
	for point in [Vector2(1030,510),Vector2(1370,510),Vector2(1780,510),Vector2(1930,395)]: _vent(point,132)
	pod_phase=_wall(Vector2(1980,220),Vector2(24,230))
	elevator_partition=_wall(Vector2(2175,1800),Vector2(24,240))
	elevator_partition.set_open(true)
	for index in 3:
		var pod:=EdenCultivationPod.new()
		pod.level=self
		pod.pod_id=index+1
		pod.position=[Vector2(2140,265),Vector2(1910,1050),Vector2(2240,1765)][index]
		add_child(pod)
		pods.append(pod)
	# Right-side bio-locks face the player, leaving a clear return parry lane.
	_turret(Vector2(2320,235),Vector2.LEFT,2.4).active=false
	_turret(Vector2(1690,1010),Vector2.RIGHT,1.6).active=false
	_turret(Vector2(2370,1735),Vector2.LEFT,2.4).active=false
	_label(Vector2(70,2470),EdenBlueprint.text("TOXIC DROP · ONE VESSEL LOST","坠落危险 · 扣一整颗生命球"),15)

func _check_mirrors() -> void:
	for receiver in corridor_receivers:
		if not receiver.lit: return
	WorldProgress.eden_chapter["mirror"]=true
	corridor_gate.set_open(true)
	for index in 3: turrets[index].active=false
	advance(3,Vector2(1200,1898))
	tell("THREE RECEIVERS LIT · Garden bridge open", "三座光接收器已点亮 · 花园桥开启")

func fire(point: Vector2,direction: Vector2,speed: float=210,source: Node2D=null,wave: bool=false) -> EdenEnergyProjectile:
	var shot:=EdenEnergyProjectile.new()
	shot.level=self
	shot.position=point
	shot.direction=direction.normalized()
	shot.speed=speed
	shot.source=source
	shot.wave=wave
	add_child(shot)
	return shot

func clear_projectiles() -> void:
	for shot in get_tree().get_nodes_in_group(&"eden_projectile"):
		if shot.level==self: shot.queue_free()

func mineralize_near(point: Vector2,radius: float) -> int:
	if not WorldProgress.can_play() or not WorldProgress.has_ability(&"mineralization"): return 0
	var count:=0
	for vent in vents:
		if point.distance_to(vent.position)<=radius and vent.mineralize(): count+=1
	if count>0:
		WorldProgress.report_ability_used(&"mineralization")
		var batch: int=WorldProgress.eden_chapter.get("mineral_batches",0)+1
		WorldProgress.eden_chapter["mineral_batches"]=batch
		CarbonLedger.store_carbon(StringName("eden/mineral/%d"%batch),150)
	return count

func _build_interaction_hints() -> void:
	interaction_hints=preload("res://scripts/presentation/interaction_hints.gd").new()
	interaction_hints.actor=player
	add_child(interaction_hints)
	for source in sources:
		interaction_hints.offer(func() -> Vector2: return source.position,func() -> String:
			return "E" if player.is_on_floor() and WorldProgress.ability_state(source.ability)==WorldProgress.AbilityState.UNAVAILABLE else ""
		,150,Vector2(0,-95))
	for point in [Vector2(1800,2378),Vector2(1100,2378),Vector2(500,2378)]:
		interaction_hints.offer(func() -> Vector2: return point,func() -> String: return "T",180)
	interaction_hints.offer(func() -> Vector2: return Vector2(2240,1898),func() -> String:
		return "T" if WorldProgress.eden_chapter.get("steward",false) and (not WorldProgress.returning or pods[1].released) else ""
	,130)
	interaction_hints.offer(func() -> Vector2: return Vector2(2240,1298),func() -> String:
		return "T" if WorldProgress.returning and pods[1].released else ""
	,130)
	interaction_hints.offer(func() -> Vector2: return EdenBlueprint.ENTRY,func() -> String:
		if not WorldProgress.returning: return ""
		if WorldProgress.eden_chapter.get("escaped",false): return "T"
		return "R" if CarbonLedger.rescued_people==3 else ""
	,EXIT_RADIUS,Vector2(0,-100))
	for wall in get_children().filter(func(node: Node) -> bool: return node is EdenPhaseWall and not node.energy_gate):
		interaction_hints.offer(func() -> Vector2: return Vector2(wall.position.x,clampf(player.position.y,wall.position.y-wall.wall_size.y/2,wall.position.y+wall.wall_size.y/2)),func() -> String:
			return "F" if not wall.opened and WorldProgress.has_ability(&"black_pierce") and player.dash_cooldown<=0 and not player.air_dash_used else ""
		,240)
	for vent in vents:
		interaction_hints.offer(func() -> Vector2: return vent.position,func() -> String:
			return "E" if WorldProgress.has_ability(&"mineralization") and player.cooldown<=0 and vent.powered and not is_instance_valid(vent.platform) else ""
		,player.pulse_radius,Vector2(0,-92))
	interaction_hints.offer(func() -> Vector2: return conduit.position,func() -> String: return "LMB" if not conduit.activated else "",94)
	interaction_hints.offer(func() -> Vector2: return pods[1].position,func() -> String:
		return "LMB" if WorldProgress.core_reversed and not pods[1].released and WorldProgress.eden_chapter.get("rescued",[]).size()==1 else ""
	,105,Vector2(0,-150))

func try_extract() -> bool:
	for source in sources:
		if player.position.distance_to(source.position)<150 and WorldProgress.ability_state(source.ability)==WorldProgress.AbilityState.UNAVAILABLE:
			return extraction.begin(player,source)
	return false

func _tutorial_text(text: String) -> void:
	tell(text,text)

func tell(en: String,zh: String) -> void:
	if _notice==null: return
	_notice.text=EdenBlueprint.text(en,zh)
	_notice_left=6

func advance(index: int,point: Vector2) -> void:
	if index<=current_node or WorldProgress.returning: return
	current_node=index
	checkpoint_position=point
	WorldProgress.eden_chapter.merge({"node":index,"checkpoint":point},true)
	WorldProgress.set_checkpoint(StringName("eden/node/%d"%index),point,EdenBlueprint.title(index))

func update_location() -> void:
	if WorldProgress.returning: return
	var p:=player.position
	if current_node==1 and p.y<1980: advance(2,Vector2(220,1898))
	if current_node==3 and is_instance_valid(steward) and p.x>1180 and p.y>1750: steward.active=true
	if current_node==5 and p.x<1990 and p.y<1120: advance(6,Vector2(1860,1038))
	if current_node==6 and WorldProgress.eden_chapter.get("oren",false) and p.x<1720: advance(7,Vector2(1510,1038))
	if current_node==7 and dual_seconds>0 and p.x<1045:
		dual_crossed=true
		WorldProgress.eden_chapter["dual"]=true
		advance(8,Vector2(210,1298))
	if current_node==8 and p.y<650 and p.x>470:
		advance(9,Vector2(540,598))
		boss.active=true
		advance(10,Vector2(540,598))
	if current_node>=9 and boss.phase==2: advance(11,Vector2(540,598))
	if current_node>=9 and boss.phase==3: advance(12,Vector2(540,598))

func interact(allow_dialogue: bool=true) -> void:
	var p:=player.position
	if WorldProgress.returning and _near_entrance():
		if not allow_dialogue: return
		if WorldProgress.eden_chapter.get("escaped",false):
			_leave_to_mine()
		elif CarbonLedger.rescued_people==3:
			tell("All 3 survivors are here. Press R to repair and return the city skills, then T to leave.","三位居民都已到齐。先按 R 修复并交还伊甸能力，再按 T 离开。")
		else:
			tell("Rescue all 3 cultivation pods before returning to the mine: %d / 3 freed."%CarbonLedger.rescued_people,"先救齐三个培养舱，再返回矿坑：当前 %d / 3 人。"%CarbonLedger.rescued_people)
		return
	if p.distance_to(Vector2(2240,1898))<130 and WorldProgress.eden_chapter.get("steward",false):
		if WorldProgress.returning:
			if pods[1].released: player.reset_at_checkpoint(Vector2(2240,1898))
		else:
			_elevator_seconds=1.2
			pods[2].play_seal()
			WorldProgress.narrative_active=true
			WorldProgress.narrative_kind=&"eden_lift"
			player.velocity=Vector2.ZERO
			tell("Your friend is sealed in the transport pod. The gate opens for you alone.","你的朋友被封进运输培养舱。闸门只为你一个人打开。")
		return
	if WorldProgress.returning and p.distance_to(Vector2(2240,1298))<130 and pods[1].released:
		player.reset_at_checkpoint(Vector2(2080,1898))
		checkpoint_position=player.position
		return
	if not allow_dialogue: return
	if p.y>2200:
		if p.x>1450:
			tell("CITY DISPLAY: Zero emissions inside our walls. Imports and life extraction excluded.","城市公示：城界内零排放。外部开采与生命抽取不计入。")
		elif p.x>800:
			tell("TREE OF LIFE: Its roots disappear beneath the marble. No public map shows where they lead.","生命之树：树根消失在白石地面下。没有一张公开地图画出它们通向哪里。")
		else:
			tell("ASCENSION NOTICE: Healthy candidates are selected each year. All letters are held until arrival.","荣升告示：每年选拔生命力旺盛的候选人。来往信件暂存，抵达后发放。")
	elif current_node==2:
		tell("Hold Q / K to block. Tap just before impact: reflected light powers all 3 receivers.","按住 Q / K 格挡；命中前短按可弹反。跳起对准三个接收器。")

func _on_world_changed() -> void:
	if WorldProgress.core_reversed and not _return_started:
		_return_started=true
		if not WorldProgress.eden_chapter.get("return_started",false):
			WorldProgress.eden_chapter["return_started"]=true
			checkpoint_position=Vector2(1450,598)
			WorldProgress.eden_chapter["checkpoint"]=checkpoint_position
			player.reset_at_checkpoint(checkpoint_position)
			WorldProgress.set_checkpoint(&"eden/rescue/start",checkpoint_position,"EDEN · CIRCULAR RESCUE")
		clear_projectiles()
		boss.active=false
		for index in turrets.size(): turrets[index].active=index>=turrets.size()-3
		dual_gate.set_open(true)
		corridor_gate.set_open(true)
		maintenance_wall.set_open(false)
		elevator_partition.set_open(false)
		tell("CIRCULAR MODE · Rescue Pod 1 on 4F, Pod 2 on 3F, then Pod 3 on 2F.","循环模式 · 依次救出四层 1 号、三层 2 号、二层 3 号培养舱。")
	for source in sources: source.refresh_state()
	for pod in pods:
		if pod.released: turrets[turrets.size()-4+pod.pod_id].active=false
	_sync_followers()
	if CarbonLedger.rescued_people==3 and WorldProgress.returning: _open_public_route()

func on_pod_rescued(id: int) -> void:
	turrets[turrets.size()-4+id].active=false
	checkpoint_position=player.position
	WorldProgress.eden_chapter["checkpoint"]=checkpoint_position
	WorldProgress.set_checkpoint(StringName("eden/rescue/%d"%id),checkpoint_position,"EDEN · POD %d / 3"%id)
	tell("HUMAN FREED · %d / 3. Return to the entrance together."%id,"居民已获救 · %d / 3。一起返回天堂入口。"%id)
	if id==3:
		# Build a public descent BEFORE giving up either chapter-local skill.
		_open_public_route()
	_sync_followers()

func _open_public_route() -> void:
	dual_phase.set_open(true)
	maintenance_wall.set_open(true)
	pod_phase.set_open(true)
	elevator_partition.set_open(true)
	for turret in turrets: turret.active=false
	clear_projectiles()

func _resident(point: Vector2,tint: Color) -> Node2D:
	var resident:=Sprite2D.new()
	resident.texture=CampaignLevels.trimmed_texture("characters/hero_green")
	resident.scale=Vector2.ONE*52/resident.texture.get_height()
	resident.position=point+Vector2(0,-3)
	resident.modulate=tint
	resident.z_index=4
	add_child(resident)
	return resident

func _sync_followers() -> void:
	var count: int=WorldProgress.eden_chapter.get("rescued",[]).size()
	while _followers.size()<count:
		var follower:=_resident(player.position,Color("c2d4b2"))
		_followers.append(follower)

func restore_oasis() -> void:
	if not WorldProgress.can_play() or not WorldProgress.returning or CarbonLedger.rescued_people!=3: return
	if not _near_entrance():
		tell("Bring all three survivors to the 1F entrance before returning the city skills.","先把三位居民带到一层入口，再共同修复并交还能力。")
		return
	if WorldProgress.eden_chapter.get("escaped",false):
		tell("Route restored. Press T to leave Eden and return to the Toxic Mine.","通路已经修复。按 T 离开伊甸，返回毒雾矿坑。")
		return
	WorldProgress.repair_current_region()
	WorldProgress.return_ability(&"shield")
	WorldProgress.return_ability(&"black_pierce")
	WorldProgress.eden_chapter["escaped"]=true
	tell("EDEN RESCUE COMPLETE · T: continue home through the mine and scrapyard.","伊甸救援完成 · 按 T 经矿坑、垃圾场带居民回家。")

func _near_entrance() -> bool:
	return player.position.distance_to(EdenBlueprint.ENTRY)<=EXIT_RADIUS

func _leave_to_mine() -> void:
	if _leaving or not WorldProgress.can_play() or not WorldProgress.eden_chapter.get("escaped",false) or not _near_entrance(): return
	_leaving=true
	WorldProgress.enter_scene(&"grassland",Vector2(5340,378))

func _return_instruction() -> String:
	if CarbonLedger.rescued_people<3:
		return EdenBlueprint.text("4F → 3F → 2F: rescue three pods.\nDown + Space: drop through ledges.","四层 → 三层 → 二层：依次救出三个培养舱。\n下 + 空格：穿过平台下降。")
	if WorldProgress.eden_chapter.get("escaped",false):
		return EdenBlueprint.text("1F right entrance · T: LEAVE EDEN → TOXIC MINE.\nDouble Jump and Mineralization remain for the journey.","一层右侧入口 · T：离开伊甸 → 毒雾矿坑。\n二段跳与矿化仍保留，用于接下来的返程。")
	if not _near_entrance():
		return EdenBlueprint.text("3 / 3 rescued · Return to the RIGHT entrance on 1F.\nR: repair and return city skills. Then T: leave.","3 / 3 人已获救 · 返回一层最右侧入口。\n先按 R 修复并交还伊甸能力，再按 T 离开。")
	return EdenBlueprint.text("3 / 3 rescued · R: repair and return city skills.\nThen T: leave Eden for the Toxic Mine.","三位居民已到齐 · R：修复通路并交还伊甸能力。\n完成后按 T：离开伊甸，返回毒雾矿坑。")

func _build_hud() -> void:
	var canvas:=CanvasLayer.new()
	canvas.layer=9
	add_child(canvas)
	_hud=Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_hud.theme=preload("res://assets/ui_theme.tres")
	canvas.add_child(_hud)
	chapter_status=ChapterStatusHUD.new()
	_hud.add_child(chapter_status)
	_shield_text=_hud_label(Vector2(30,273),"",14)
	_shield_meter=ProgressBar.new()
	_shield_meter.position=Vector2(30,299)
	_shield_meter.size=Vector2(365,12)
	_shield_meter.max_value=100
	_shield_meter.show_percentage=false
	var meter_background:=StyleBoxFlat.new()
	meter_background.bg_color=Color("152b28")
	var meter_fill:=StyleBoxFlat.new()
	meter_fill.bg_color=Color("a8d7ce")
	_shield_meter.add_theme_stylebox_override(&"background",meter_background)
	_shield_meter.add_theme_stylebox_override(&"fill",meter_fill)
	_hud.add_child(_shield_meter)
	_shield_meter.size=Vector2(365,12)
	_abilities=_hud_label(Vector2(30,320),"",14)
	_rescue=_hud_label(Vector2(450,90),"",19)
	_objective=_hud_label(Vector2(450,125),"",15)
	_objective.custom_minimum_size.x=490
	_objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_boss_panel=VBoxContainer.new()
	_boss_panel.position=Vector2(450,20)
	_boss_panel.custom_minimum_size=Vector2(490,0)
	_hud.add_child(_boss_panel)
	_boss_text=Label.new()
	_boss_text.add_theme_font_size_override(&"font_size",17)
	_boss_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_boss_panel.add_child(_boss_text)
	_boss_bar=ProgressBar.new()
	_boss_bar.custom_minimum_size=Vector2(490,12)
	_boss_bar.show_percentage=false
	_boss_panel.add_child(_boss_bar)
	_notice=_hud_label(Vector2(200,644),"",17)
	_notice.custom_minimum_size.x=760
	_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_settings=SettingsPanel.new()
	_hud.add_child(_settings)
	var button:=Button.new()
	button.text=GameText.t("设置")
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left=-150
	button.offset_right=-20
	button.offset_top=20
	button.offset_bottom=64
	button.pressed.connect(_settings.open)
	_hud.add_child(button)

func _hud_label(point: Vector2,text: String,font_size: int) -> Label:
	var label:=Label.new()
	label.position=point
	label.text=text
	label.add_theme_font_size_override(&"font_size",font_size)
	label.add_theme_constant_override(&"outline_size",4)
	label.add_theme_color_override(&"font_outline_color",Color("101d16"))
	_hud.add_child(label)
	return label

func _process(delta: float) -> void:
	hitstop=maxf(0,hitstop-delta)
	if _hud==null: return
	if _elevator_seconds>0:
		_elevator_seconds=maxf(0,_elevator_seconds-delta)
		if _elevator_seconds==0:
			WorldProgress.narrative_active=false
			WorldProgress.narrative_kind=&""
			advance(5,Vector2(2240,1298))
			player.reset_at_checkpoint(checkpoint_position)
			tell("The lift opens onto the processing floor. Find the maintenance entrance.","电梯在人体处理层开启。寻找维护入口。")
	for index in _followers.size():
		var target:=player.position+Vector2(-player.facing*(45+index*27),0)
		_followers[index].position=_followers[index].position.lerp(target,minf(1,delta*5))
	if is_instance_valid(_oren) and WorldProgress.eden_chapter.get("oren",false):
		_oren.position=_oren.position.move_toward(Vector2(2000,1038),delta*40)
	if WorldProgress.can_play():
		_notice_left=maxf(0,_notice_left-delta)
		if dual_seconds>0:
			dual_seconds=maxf(0,dual_seconds-delta)
			if dual_seconds==0 and not dual_crossed and not WorldProgress.returning:
				dual_gate.set_open(false)
				dual_receiver.lit=false
				dual_receiver.hits=0
	_notice.visible=_notice_left>0
	var jump:=EdenBlueprint.text("Double Jump Ready","二段跳就绪") if player.air_jump_available() else EdenBlueprint.text("Air jump used · land to refresh","二段跳已用 · 落地恢复")
	var skill:=EdenBlueprint.text("Dark Dash %.1fs · Shield %s","黑冲 %.1f 秒 · 护盾 %s")%[player.dash_cooldown,"ON" if player.guard_held else "OFF"]
	if WorldProgress.eden_chapter.get("escaped",false): skill=EdenBlueprint.text("City skills returned · T at 1F: leave","伊甸能力已交还 · 在一层入口按 T 离开")
	elif not WorldProgress.has_ability(&"shield"): skill=EdenBlueprint.text("2F · E at the source: acquire Shield","二层 · 在能力源按 E 获得护盾")
	elif not WorldProgress.has_ability(&"black_pierce"): skill=EdenBlueprint.text("SHIELD: Q / K · RMB: heavy slash","护盾：Q / K · 右键：重击")
	var hud_node:=current_node
	if WorldProgress.returning: hud_node=12 if player.position.y<700 else 6 if player.position.y<1350 else 4 if player.position.y<2000 else 1
	chapter_status.show_status(EdenBlueprint.title(hud_node),jump,skill,player.dash_cooldown,0.75,"EDEN · "+("CIRCULAR" if WorldProgress.returning else "ASCENT"))
	_shield_meter.value=player.shield_energy
	_shield_text.text=EdenBlueprint.text("SHIELD ENERGY %03d / 100","护盾能量 %03d / 100")%player.shield_energy
	if player.guard_overheat>0: _shield_text.text=EdenBlueprint.text("GUARD BREAK %.1fs","护盾过热 %.1f 秒")%player.guard_overheat
	if WorldProgress.ability_state(&"shield")==WorldProgress.AbilityState.RETURNED: _shield_text.text=EdenBlueprint.text("SHIELD · RETURNED","护盾 · 已交还")
	elif not WorldProgress.has_ability(&"shield"): _shield_text.text=EdenBlueprint.text("SHIELD · UNACQUIRED","护盾 · 尚未获得")
	_shield_meter.modulate=Color("e6806d") if player.guard_overheat>0 else Color.WHITE if WorldProgress.has_ability(&"shield") else Color("596e65")
	var icons: Array[String]=[]
	for id in [&"double_jump",&"mineralization",&"shield",&"black_pierce"]:
		icons.append(("● " if WorldProgress.has_ability(id) else "○ ")+{&"double_jump":"DJ",&"mineralization":"MIN",&"shield":"SHIELD",&"black_pierce":"DASH"}[id])
	_abilities.text="  ".join(icons)
	_rescue.visible=WorldProgress.returning
	_rescue.text=EdenBlueprint.text("Cultivation Pods Rescued: %d / 3","培养舱已救出：%d / 3")%CarbonLedger.rescued_people
	var objectives=["01 · T: inspect displays. Climb the left stairs.","02 · E: extract Shield. Reflect light into 3 receivers.","03 · Parry twice, then strike the stunned Steward.","04 · T at the right elevator: ascend.","05 · E: extract Dark Dash. Shift / L / F through violet walls.","06 · Cut Oren's conduit with LMB.","07 · Parry the lock; cross both gates within 6 seconds.","08 · E: crystallize → jump → air jump → dash → block.","09 · Enter the life furnace.","10 · Parry ×3 → crystallize → strike the exposed device.","11 · Dash through the charge. Strike after wall impact.","12 · Parry left supply; sever the upper-right lock."]
	_objective.text=objectives[current_node-1] if not WorldProgress.returning else _return_instruction()
	_entrance_hint.visible=WorldProgress.returning and CarbonLedger.rescued_people==3
	_entrance_hint.text=EdenBlueprint.text("T · RETURN TO TOXIC MINE","T · 返回毒雾矿坑") if WorldProgress.eden_chapter.get("escaped",false) else EdenBlueprint.text("R · REPAIR / RETURN CITY SKILLS\nThen T · RETURN TO TOXIC MINE","R · 修复并交还伊甸能力\n完成后 T · 返回毒雾矿坑")
	_boss_panel.visible=(boss.active and not boss.dismantled) or (is_instance_valid(steward) and steward.active)
	if boss.active:
		_boss_bar.max_value=boss.max_health
		_boss_bar.value=boss.health
		_boss_text.text="EDEN HEART · %s"%["GUARDIAN","PREDATION","HARVEST","DISMANTLED"][boss.phase-1]
		if boss.phase==1:
			_boss_text.text+=EdenBlueprint.text("\nCORE OPEN %.1fs · LMB / RMB: strike","\n核心暴露 %.1f 秒 · 左键 / 右键攻击")%boss.exposed if boss.exposed>0 else EdenBlueprint.text("\nQ / K: PARRY %d / 3","\nQ / K：弹反 %d / 3")%boss.core_lock.hits
		elif boss.phase==2 and is_instance_valid(boss.guard):
			_boss_text.text+=EdenBlueprint.text("\nWEAK POINT %.1fs · LMB / RMB: strike","\n弱点暴露 %.1f 秒 · 左键 / 右键攻击")%boss.guard._recovery if boss.guard._recovery>0 else EdenBlueprint.text("\nARMORED · dash through the charge","\n装甲防护 · 黑冲穿身，等待撞墙")
		elif boss.phase==3:
			_boss_text.text+=EdenBlueprint.text("\nLEFT SUPPLY %s · UPPER LOCK %s","\n左侧供能 %s · 右上抽取锁 %s")%["OFF" if boss.left_cut else "ON","OFF" if boss.right_cut else "ON"]
	elif is_instance_valid(steward):
		_boss_bar.max_value=steward.max_health
		_boss_bar.value=steward.health
		_boss_text.text=EdenBlueprint.text("GARDEN STEWARD · HP %d / %d","净园执事 · 生命 %d / %d")%[steward.health,steward.max_health]
		_boss_text.text+=EdenBlueprint.text("\nARMOR BROKEN · LMB / RMB: strike","\n装甲已破 · 左键 / 右键攻击") if steward.shield_broken else EdenBlueprint.text("\nARMORED · Q / K: PARRY %d / 2","\n装甲防护 · Q / K：弹反 %d / 2")%steward.shield_hits

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and WorldProgress.can_play(): _settings.open()
	if event.is_action_pressed(&"eden_talk") and WorldProgress.can_play() and WorldProgress.eden_chapter.get("escaped",false) and _near_entrance():
		_leave_to_mine()
