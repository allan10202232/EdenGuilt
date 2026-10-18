class_name CampaignLevel
extends Node2D

@export var region_id: StringName = &"lone_tree"
@onready var player: CharacterBody2D = $Player

var definition: Dictionary
var enemies: Array[CampaignEnemy] = []
var hazards: Array[CampaignHazard] = []
var _platforms: Array = []
var _route_platforms: Array = []
var _route_ramps: Array = []
var _spike_areas: Array[Area2D] = []
var _checkpoints: Array = []
var _clock: float = 0.0
var _background: Texture2D
var _terrain: Texture2D
var _scenery_terrain: Texture2D
var _middle_background: Texture2D
var _companion_texture: Texture2D
var _companions: Array[Vector2] = []
var _bursts: Array[Dictionary] = []
var _source_label: Label
var _gate: StaticBody2D
var _route_ready: bool = false
var oases: Dictionary[StringName, CampaignOasis] = {}
var extraction: LandExtraction
var ecology: SceneEcology
var _secondary_label: Label
var _dark_bodies: Array[StaticBody2D] = []
var _mineral_platforms: Array[Rect2] = []
var _temporary_platforms: Array[Dictionary] = []
var _exit_area: Area2D
var growth_points: Array[Vector2] = []
var npc: CampaignNPC
var toxin: float = 0.0
var _toxin_tick: float = 0.0
var _filter_gate: StaticBody2D
var _signs: Array[Dictionary] = []


func _ready() -> void:
	definition = CampaignLevels.definition(region_id)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background = definition.get("background_texture") as Texture2D
	if _background==null:
		_background = CampaignLevels.texture("backgrounds/"+definition.background)
	if _background==null:
		_background=CampaignLevels.texture("backgrounds/forest")
	_terrain = CampaignLevels.texture("terrain/biome_atlas")
	_scenery_terrain=definition.get("terrain_texture") as Texture2D
	_middle_background=definition.get("middle_background") as Texture2D
	_companion_texture = CampaignLevels.trimmed_texture("characters/hero_green")
	player.position = WorldProgress.spawn_position
	player.z_index = 5
	player.death_height = float(definition.height)+80.0
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = int(definition.width)
	camera.limit_bottom = int(definition.height)
	camera.position = Vector2(110,-130)
	camera.reset_smoothing()
	$GameplayBridge.bind_source(player.get_node("Stats"),true)
	_platforms = definition.platforms
	for rect: Rect2 in _platforms:
		_add_platform(rect)
		for x in range(int(rect.position.x)+38,int(rect.end.x)-16,103):
			growth_points.append(Vector2(x,rect.position.y))
	_add_platform(Rect2(-32,0,32,definition.height))
	_add_platform(Rect2(definition.width,0,32,definition.height))
	_gate = _add_platform(definition.gate)
	if region_id==&"grassland":
		_filter_gate=_add_platform(Rect2(3900,350,20,150))
	for rect: Rect2 in definition.spikes:
		_spike_areas.append(_area(rect,"Spikes"))
	for index in definition.beams.size():
		var hazard := CampaignHazard.new()
		hazard.player = player
		hazard.area = definition.beams[index]
		hazard.region_ability = definition.ability
		hazard.offset = index*0.7
		if _scenery_terrain!=null:
			hazard.support_texture=_scenery_terrain
			hazard.support_region=definition.terrain_regions[3]
			hazard.support_depth=definition.platform_depths.y
		add_child(hazard)
		hazards.append(hazard)
	for rect: Rect2 in definition.dark_walls:
		var wall:=_add_platform(rect)
		wall.collision_layer=16
		_dark_bodies.append(wall)
	for index in definition.mineral_nodes.size():
		if WorldProgress.is_collected(_entity_id("mineral_%d"%index)):
			_install_mineral(index)
	for index in definition.enemies.size():
		_spawn_enemy(definition.enemies[index],definition.patrols[index],"mob_%d"%index)
	if definition.has("boss"):
		_spawn_enemy(definition.boss,Vector2(3640,4140),"boss",true)
	for index in definition.checkpoints.size():
		var point: Vector2 = definition.checkpoints[index]
		var area := _area(Rect2(point-Vector2(22,30),Vector2(44,54)),"Checkpoint")
		area.body_entered.connect(_on_checkpoint.bind(point,index))
		_checkpoints.append(point)
	var exit_point: Vector2 = definition.exit
	_exit_area=_area(Rect2(exit_point-Vector2(25,45),Vector2(50,100)),"Exit")
	_exit_area.body_entered.connect(_on_exit)
	_area(Rect2(22,480,30,140),"Entrance").body_entered.connect(_on_entrance)
	_source_label = _label(definition.source+Vector2(45,-135),"",16)
	_source_label.z_index = 6
	_add_oasis(definition.source, definition.ability)
	if definition.has("secondary_source"):
		_secondary_label=_label(definition.secondary_source+Vector2(35,-135),"",16,Color(0.77,0.56,0.94))
		_secondary_label.z_index = 6
		_add_oasis(definition.secondary_source, definition.secondary_ability)
	extraction = LandExtraction.new()
	add_child(extraction)
	ecology = SceneEcology.new()
	ecology.bind(self)
	add_child(ecology)
	_add_region_signs()
	for index in definition.mineral_nodes.size():
		var node: Dictionary=definition.mineral_nodes[index]
		_label(node.point+Vector2(-55,-80),GameText.t("封印 %s")%[["I","II","III"][index]],14,Color(0.7,0.9,0.48))
	if region_id==&"lone_tree":
		_label(Vector2(80,535),GameText.t("灯火：检查点"),13)
	var exit_label:=_label(exit_point+Vector2(-110,-115),GameText.t("真相档案 →") if region_id==&"remnant_sea" else "EXIT →" if region_id==&"lone_tree" else GameText.t("下一关 →"),17)
	if region_id==&"remnant_sea":
		exit_label.name="RescueLabel"
	WorldProgress.world_changed.connect(_refresh_world)
	GameText.language_changed.connect(_refresh_language)
	npc=CampaignNPC.new()
	npc.player=player
	npc.region=region_id
	npc.position=Vector2(260 if region_id!=&"grassland" else 360,596)
	add_child(npc)
	var foreground := ForegroundGrowth.new()
	foreground.points = growth_points
	foreground.region = region_id
	add_child(foreground)
	_refresh_world()
	# A playable campaign needs a starting weapon; formal acquisition remains configurable.
	if WorldProgress.ability_state(&"light_blade")==WorldProgress.AbilityState.UNAVAILABLE:
		WorldProgress.borrow_ability(&"light_blade")
		WorldProgress.set_notice(GameText.t("地脉提取器已拾取。左键短砍 / 右键长砍；能力源按 E。每次技能都会写入碳账本。"))
	queue_redraw()


func _process(delta: float) -> void:
	# Camera movement and resizing must redraw the panorama even during dialogue.
	queue_redraw()
	for signpost in _signs:
		signpost.label.visible=signpost.kind==1 and not WorldProgress.narrative_active and not WorldProgress.extraction_active and _clock<5.0
	if not WorldProgress.can_play():
		return
	_clock+=delta
	_update_toxin(delta)
	if WorldProgress.returning:
		if _companions.is_empty():
			_companions.assign([player.position,player.position,player.position])
		for index in _companions.size():
			var target: Vector2 = player.position if index==0 else _companions[index-1]
			var distance:=target-_companions[index]
			if distance.length()>44.0:
				_companions[index]=_companions[index].lerp(target-distance.normalized()*44.0,minf(1.0,delta*5.0))
	for burst in _bursts:
		burst.life-=delta
	_bursts = _bursts.filter(func(effect: Dictionary) -> bool: return effect.life>0.0)
	for temporary in _temporary_platforms:
		temporary.life-=delta
		if temporary.life<=0.0 and is_instance_valid(temporary.body):
			temporary.body.queue_free()
	_temporary_platforms=_temporary_platforms.filter(func(entry: Dictionary) -> bool: return entry.life>0.0)


func _physics_process(_delta: float) -> void:
	if not WorldProgress.can_play():
		return
	if not WorldProgress.repaired_regions.has(region_id):
		for area in _spike_areas:
			if area.overlaps_body(player):
				player.hurt()
	if WorldProgress.core_reversed and region_id==&"remnant_sea" and player.position.distance_to(definition.exit)<140.0 and Input.is_action_just_pressed(&"eden_return"):
		if WorldProgress.repair_current_region():
			WorldProgress.set_notice(GameText.t("3 位居民已共同打通伊甸城公共路线。向左回两个能力源卸下护盾和黑穿。"))
	_interact_source(definition.source,definition.ability)
	if definition.has("secondary_source"):
		_interact_source(definition.secondary_source,definition.secondary_ability)
	if Input.is_action_just_pressed(&"eden_trial_blade") and OS.is_debug_build():
		WorldProgress.borrow_ability(&"light_blade")


func _on_checkpoint(body: Node2D,point: Vector2,index: int) -> void:
	if body==player and WorldProgress.set_checkpoint(StringName("%s/cp_%d"%[region_id,index]),point,"%s · %02d"%[definition.title,index+1]):
		player.stats.heal(30)


func _on_exit(body: Node2D) -> void:
	if body!=player or not WorldProgress.can_play():
		return
	if region_id==&"grassland" and not mine_puzzle_solved():
		WorldProgress.set_notice(GameText.t("净化门仍关闭：按 I → II → III 的顺序固化三个毒雾节点。"))
		return
	var ability: StringName = definition.ability
	if WorldProgress.ability_state(ability)==WorldProgress.AbilityState.UNAVAILABLE:
		WorldProgress.set_notice(GameText.t("本关的%s尚未获得，返回发光的能力源按 E。")%AbilityCatalog.definition(ability).name)
		return
	var index:=AbilityCatalog.REGIONS.find(region_id)
	if index<2:
		WorldProgress.enter_scene(AbilityCatalog.REGIONS[index+1],Vector2(140,596))
	elif not WorldProgress.is_enemy_defeated(_entity_id("boss")):
		WorldProgress.set_notice(GameText.t("伊甸守卫仍在保护能源档案，先击败它再揭开真相。"))
	elif WorldProgress.ability_state(&"black_pierce")==WorldProgress.AbilityState.UNAVAILABLE:
		WorldProgress.set_notice(GameText.t("先在紫色能力源学会黑穿（F），再进入能源档案。"))
	else:
		WorldProgress.reveal_truth()


func _on_entrance(body: Node2D) -> void:
	if body!=player or not WorldProgress.can_play():
		return
	var index:=AbilityCatalog.REGIONS.find(region_id)
	if index>0:
		var previous: StringName = AbilityCatalog.REGIONS[index-1]
		var previous_exit: Vector2 = CampaignLevels.definition(previous).exit
		WorldProgress.enter_scene(previous,previous_exit-Vector2(40 if previous==&"lone_tree" else 90,24))
	elif WorldProgress.returning and WorldProgress.required_returns_complete():
		GameSession.complete_level()
	else:
		WorldProgress.set_notice(GameText.t("向右探索垃圾场、毒雾矿坑、伊甸城。选择逆向循环后从这里回家。"))


func _spawn_enemy(point: Vector2,patrol: Vector2,id: String,boss: bool=false) -> void:
	if WorldProgress.is_enemy_defeated(_entity_id(id)):
		return
	var enemy:=CampaignEnemy.new()
	enemy.player=player
	enemy.position=point
	enemy.patrol=patrol
	enemy.kind=definition.enemy
	enemy.boss=boss
	enemy.persistent_id=_entity_id(id)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.projectile_fired.connect(_spawn_projectile)
	add_child(enemy)
	enemies.append(enemy)


func _on_enemy_defeated(enemy: CampaignEnemy) -> void:
	_bursts.append({"position":enemy.position,"life":0.7,"boss":enemy.boss})
	if enemy.boss:
		WorldProgress.set_notice(GameText.t("伊甸守卫已倒下。右侧能源档案已解锁：伊甸城的绿色由谁承担代价？"))
		# A player can land the last hit while already standing in the portal.
		# Recheck after the hit callback; another body_entered event may never occur.
		_retry_archive.call_deferred()


func _retry_archive() -> void:
	if is_instance_valid(_exit_area) and is_instance_valid(player) and _exit_area.overlaps_body(player):
		_on_exit(player)


func _spawn_projectile(origin: Vector2,direction: float) -> void:
	var bolt:=preload("res://scripts/campaign/projectile.gd").new()
	bolt.position=origin
	bolt.direction=direction
	bolt.player=player
	add_child(bolt)


func _refresh_world() -> void:
	var ability: StringName=definition.ability
	var status:=WorldProgress.ability_state(ability)
	var learned_hint: String=GameText.t("与居民共同修复") if WorldProgress.core_reversed else GameText.t("已学会 · 向右寻找真相")
	_source_label.text=GameText.t("%s · 生命绿洲\n%s")%[AbilityCatalog.definition(ability).name,[GameText.t("生命尚存"),learned_hint,GameText.t("共同修复 · 通路已恢复")][status]]
	_source_label.modulate=Color.WHITE
	for oasis: CampaignOasis in oases.values():
		if not extraction.active or extraction._oasis != oasis:
			oasis.refresh_state()
	if _secondary_label!=null:
		var second_status:=WorldProgress.ability_state(definition.secondary_ability)
		var second_hint: String=GameText.t("与居民共同修复") if WorldProgress.core_reversed else GameText.t("已学会 · 向右寻找真相")
		_secondary_label.text=GameText.t("黑穿 · 生命绿洲\n%s")%[GameText.t("生命尚存"),second_hint,GameText.t("共同修复 · 暗壁已拆除")][second_status]
	var unlocked:=WorldProgress.has_ability(ability) or WorldProgress.route_open(ability)
	_gate.get_child(0).set_deferred(&"disabled",unlocked)
	if (WorldProgress.route_open(ability) or WorldProgress.repaired_regions.has(region_id)) and not _route_ready:
		_route_ready=true
		_install_route.call_deferred()
	for wall in _dark_bodies:
		wall.get_child(0).set_deferred(&"disabled",WorldProgress.repaired_regions.has(region_id))
	if WorldProgress.repaired_regions.has(region_id):
		for hazard in hazards:
			hazard.neutralized=true
	if is_instance_valid(_filter_gate):
		_filter_gate.get_child(0).set_deferred(&"disabled",mine_puzzle_solved())
	if WorldProgress.returning:
		_label_mission_return()
	queue_redraw()


func _label_mission_return() -> void:
	# Entrance and exit labels are world-space signposts, never collidable art.
	var rescue := get_node_or_null("RescueLabel") as Label
	if rescue != null:
		rescue.text=GameText.t("R 居民共建 · 向左返程") if WorldProgress.returning else GameText.t("真相档案 →")


func _interact_source(point: Vector2,ability: StringName) -> void:
	if player.position.distance_to(point)>=108.0:
		return
	if Input.is_action_just_pressed(&"eden_absorb"):
		if WorldProgress.ability_state(ability) == WorldProgress.AbilityState.UNAVAILABLE:
			extraction.begin(player, oases[ability])
		else:
			WorldProgress.set_notice(GameText.t("这片绿洲已经被抽取。向右寻找真相，返程时与居民共同修复。") if WorldProgress.has_ability(ability) else GameText.t("这片绿洲已共同修复，能力已经交还。"))
	elif Input.is_action_just_pressed(&"eden_return"):
		if WorldProgress.core_reversed:
			WorldProgress.repair_current_region()
			WorldProgress.return_ability(ability)
		else:
			WorldProgress.set_notice(GameText.t("先到伊甸城发现真相，再决定提取器的未来。"))


func _add_oasis(point: Vector2, ability: StringName) -> void:
	var biome := "junkyard" if region_id == &"lone_tree" else "mine" if region_id == &"grassland" else "eden"
	var ground := point + Vector2(0, 30)
	# Keep the whole living patch rooted on solid terrain near a platform edge.
	for rect: Rect2 in _platforms:
		if absf(rect.position.y - ground.y) < 4.0 and point.x >= rect.position.x and point.x <= rect.end.x and rect.size.x >= CampaignOasis.WIDTH:
			ground.x = clampf(point.x, rect.position.x + CampaignOasis.WIDTH * 0.5, rect.end.x - CampaignOasis.WIDTH * 0.5)
			break
	var oasis := CampaignOasis.new()
	oasis.name = "Oasis_" + String(ability)
	add_child(oasis)
	oasis.setup(ability, biome, ground)
	oases[ability] = oasis


func try_mineralize(origin: Vector2,facing: float) -> bool:
	if not WorldProgress.can_play() or not WorldProgress.has_ability(&"mineralization"):
		return false
	for index in definition.mineral_nodes.size():
		var node: Dictionary=definition.mineral_nodes[index]
		var id:=_entity_id("mineral_%d"%index)
		if origin.distance_to(node.point)<145.0 and not WorldProgress.is_collected(id):
			if index>0 and not WorldProgress.is_collected(_entity_id("mineral_%d"%(index-1))):
				WorldProgress.set_notice(GameText.t("毒雾仍在回流。先固化前一个编号节点，再处理这里。"))
				return false
			WorldProgress.collect_once(id)
			_install_mineral(index)
			WorldProgress.report_ability_used(&"mineralization")
			CarbonLedger.store_carbon(id,CarbonLedger.rules.mineral_node_storage_kg)
			WorldProgress.world_changed.emit()
			if not mine_puzzle_solved():
				WorldProgress.set_notice(GameText.t("碳矿化 +1 kg；本节点固定 %.0f kg CO₂（游戏模型），晶桥已生成。")%CarbonLedger.rules.mineral_node_storage_kg)
			return true
	var rect:=Rect2(origin+Vector2(facing*105.0-64.0,70),Vector2(128,18))
	var query:=PhysicsShapeQueryParameters2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=rect.size
	query.shape=shape
	query.transform=Transform2D(0.0,rect.get_center())
	query.collision_mask=17
	if not get_world_2d().direct_space_state.intersect_shape(query).is_empty():
		WorldProgress.set_notice(GameText.t("在空中前方生成临时晶台，或靠近毒雾节点再按 C；无效释放不记排放。"))
		return false
	var body:=_add_platform(rect)
	_temporary_platforms.append({"body":body,"rect":rect,"life":4.0})
	WorldProgress.report_ability_used(&"mineralization")
	return true


func _install_mineral(index: int) -> void:
	var node: Dictionary=definition.mineral_nodes[index]
	var rect: Rect2=node.bridge
	_add_platform(rect)
	_mineral_platforms.append(rect)
	if node.hazard>=0:
		hazards[node.hazard].neutralized=true
	if is_instance_valid(_filter_gate):
		_filter_gate.get_child(0).set_deferred(&"disabled",mine_puzzle_solved())
		if mine_puzzle_solved():
			WorldProgress.set_notice(GameText.t("三个封印已完成。毒源停止，净化门已打开，前往 Eden City。"))


func _install_route() -> void:
	for rect: Rect2 in definition.bridges:
		_add_platform(rect)
		_route_platforms.append(rect)
	for points: PackedVector2Array in definition.ramps:
		var body:=StaticBody2D.new()
		var collision:=CollisionPolygon2D.new()
		collision.polygon=points
		body.add_child(collision)
		add_child(body)
		_route_ramps.append(points)


func _add_platform(rect: Rect2) -> StaticBody2D:
	var body:=StaticBody2D.new()
	body.position=rect.get_center()
	body.collision_layer=1
	body.collision_mask=0
	var shape:=RectangleShape2D.new()
	shape.size=rect.size
	var collision:=CollisionShape2D.new()
	collision.shape=shape
	body.add_child(collision)
	add_child(body)
	return body


func _area(rect: Rect2,label: String) -> Area2D:
	var area:=Area2D.new()
	area.name=label
	area.position=rect.get_center()
	area.collision_layer=0
	area.collision_mask=2
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=rect.size
	collision.shape=shape
	area.add_child(collision)
	add_child(area)
	return area


func _label(point: Vector2,text: String,size: int,_tint: Color=Color(0.85,0.85,0.74)) -> Label:
	var label:=Label.new()
	label.position=point
	label.text=text
	label.theme=preload("res://assets/ui_theme.tres")
	label.add_theme_font_size_override(&"font_size",size)
	label.add_theme_constant_override(&"outline_size",4)
	label.add_theme_color_override(&"font_outline_color",Color.BLACK)
	label.modulate=Color.WHITE
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _entity_id(id: String) -> StringName:
	return StringName("%s/%s"%[region_id,id])


func _draw() -> void:
	if definition.is_empty():
		return
	var camera:=get_viewport().get_camera_2d()
	var size:=get_viewport_rect().size
	if camera!=null: size /= camera.zoom
	var origin:=camera.get_screen_center_position()-size*0.5 if camera!=null else Vector2.ZERO
	_paint_background(origin,size)
	for rect: Rect2 in _platforms:
		_paint_platform(rect)
	for rect: Rect2 in _route_platforms:
		_paint_platform(rect,true)
	for rect: Rect2 in _mineral_platforms:
		_paint_platform(rect,true)
		draw_line(rect.position,Vector2(rect.end.x,rect.position.y),_mineral_tint(),3)
	for entry in _temporary_platforms:
		draw_rect(entry.rect,Color(_mineral_tint(),minf(0.8,entry.life)))
	for rect: Rect2 in definition.dark_walls:
		if not WorldProgress.repaired_regions.has(region_id):
			draw_rect(rect,Color(0.24,0.08,0.38,0.85))
			for y in range(int(rect.position.y),int(rect.end.y),25):
				draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y+12),Color(0.71,0.35,0.93),2)
	for index in definition.mineral_nodes.size():
		var node: Dictionary=definition.mineral_nodes[index]
		var converted:=WorldProgress.is_collected(_entity_id("mineral_%d"%index))
		draw_circle(node.point-Vector2(0,22),20,Color(_mineral_tint(),0.25) if converted else Color(0.49,0.6,0.21,0.36))
		draw_arc(node.point-Vector2(0,22),25,0,TAU,20,_mineral_tint() if converted else Color(0.7,0.77,0.28),2)
	for points: PackedVector2Array in _route_ramps:
		if _scenery_terrain!=null:
			var bounds:=Rect2(points[0],Vector2.ZERO)
			for point in points: bounds=bounds.expand(point)
			var fill: Rect2=definition.terrain_regions[1]
			var uvs:=PackedVector2Array()
			for point in points:
				uvs.append((fill.position+(point-bounds.position)/bounds.size*fill.size)/_scenery_terrain.get_size())
			draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,_scenery_terrain)
		elif _terrain!=null:
			var bounds:=Rect2(points[0],Vector2.ZERO)
			for point in points:
				bounds=bounds.expand(point)
			var cell:=_terrain.get_size()/Vector2(2,3)
			var uvs:=PackedVector2Array()
			for point in points:
				uvs.append(Vector2(cell.x,float(definition.row)*cell.y)+(point-bounds.position)/bounds.size*cell)
			draw_polygon(points,PackedColorArray([Color(0.8,0.8,0.8)]),uvs,_terrain)
		else:
			draw_colored_polygon(points,Color(0.18,0.29,0.22))
		draw_line(points[0],points[1],Color(0.63,0.78,0.49),8)
	for rect: Rect2 in definition.spikes:
		if WorldProgress.repaired_regions.has(region_id):
			draw_line(Vector2(rect.position.x,rect.end.y-2),Vector2(rect.end.x,rect.end.y-2),Color(0.42,0.83,0.55),4)
			continue
		for x in range(int(rect.position.x),int(rect.end.x)-8,14):
			draw_colored_polygon(PackedVector2Array([Vector2(x,rect.end.y),Vector2(x+7,rect.position.y),Vector2(x+14,rect.end.y)]),Color(0.77,0.36,0.34))
	for index in growth_points.size():
		var point:=growth_points[index]
		var strength:=1.0
		if WorldProgress.has_ability(definition.ability) and point.distance_to(definition.source)<680:
			strength=0.2
		if definition.has("secondary_source") and WorldProgress.has_ability(definition.secondary_ability) and point.distance_to(definition.secondary_source)<680:
			strength=0.2
		if extraction.active and point.distance_to(extraction._oasis.position)<680:
			strength=maxf(0.15,1.0-extraction.progress)
		var wind:=sin(_clock*1.4+index)*3.0
		var tint:=Color(0.35,0.58,0.25,strength)
		draw_line(point,point+Vector2(wind,-12),tint,2,true)
		draw_colored_polygon(PackedVector2Array([point-Vector2(0,4),point+Vector2(-9+wind,-12),point+Vector2(wind,-10)]),tint)
		draw_colored_polygon(PackedVector2Array([point-Vector2(0,7),point+Vector2(8+wind,-16),point+Vector2(wind,-12)]),Color(0.57,0.72,0.3,strength))
	if region_id==&"grassland" and not mine_puzzle_solved():
		draw_rect(Rect2(3900,350,20,150),Color(0.28,0.36,0.15,0.9))
		for index in 3:
			draw_circle(Vector2(3910,380+index*40),6,Color(0.66,0.9,0.45) if WorldProgress.is_collected(_entity_id("mineral_%d"%index)) else Color(0.17,0.19,0.11))
	for point: Vector2 in _checkpoints:
		draw_line(point+Vector2(0,24),point-Vector2(0,35),Color(0.3,0.28,0.23),7)
		draw_circle(point-Vector2(0,42),10,Color(0.95,0.66,0.29,0.15))
		draw_circle(point-Vector2(0,42),4,Color(1.0,0.77,0.4))
	var end: Vector2=definition.exit
	draw_rect(Rect2(end-Vector2(30,55),Vector2(60,105)),Color(0.035,0.06,0.07,0.85))
	draw_rect(Rect2(end-Vector2(30,55),Vector2(60,105)),definition.accent,false,3)
	if not WorldProgress.has_ability(definition.ability) and not WorldProgress.route_open(definition.ability):
		draw_rect(definition.gate,Color(definition.accent,0.18))
		draw_rect(definition.gate,definition.accent,false,2)
	for index in 26:
		var x:=origin.x+fposmod(index*107.7-_clock*(4+index%3),size.x)
		var y:=origin.y+fposmod(index*73.1+sin(_clock+index)*12,size.y)
		draw_rect(Rect2(x,y,2 if index%3 else 3,2),Color(definition.accent,0.14+sin(_clock+index)*0.1))
	for burst in _bursts:
		var progress:=1.0-float(burst.life)/0.7
		draw_arc(burst.position,8.0+progress*45.0,0,TAU,24,Color(definition.accent,1.0-progress),2)
	if WorldProgress.repaired_regions.has(region_id):
		for rect: Rect2 in _platforms:
			for x in range(int(rect.position.x)+20,int(rect.end.x),67):
				var stalk:=Vector2(x,rect.position.y)
				draw_line(stalk,stalk-Vector2(0,13),Color(0.3,0.7,0.3),2)
				draw_circle(stalk-Vector2(4,9),4,Color(0.46,0.79,0.4))
				draw_circle(stalk-Vector2(-4,14),4,Color(0.62,0.86,0.46))
	if _companion_texture!=null:
		var scale:=38.0/_companion_texture.get_height()
		var dimensions:=_companion_texture.get_size()*scale
		for point in _companions:
			draw_texture_rect(_companion_texture,Rect2(point-Vector2(dimensions.x*0.5,16),dimensions),false,Color(0.7,0.95,0.8))


func mine_puzzle_solved() -> bool:
	if region_id!=&"grassland" or WorldProgress.repaired_regions.has(region_id): return true
	for index in definition.mineral_nodes.size():
		if not WorldProgress.is_collected(_entity_id("mineral_%d"%index)): return false
	return true


func _update_toxin(delta: float) -> void:
	if region_id!=&"grassland": return
	var exposure_rate:=0.0
	for hazard in hazards:
		if not hazard.neutralized and not WorldProgress.route_open(hazard.region_ability) and hazard.area.intersects(Rect2(player.position-Vector2(14,24),Vector2(28,48))):
			exposure_rate=maxf(exposure_rate,46.0 if hazard.phase()==2 else 8.0)
	toxin=clampf(toxin+delta*(exposure_rate if exposure_rate>0 else -22.0),0,100)
	_toxin_tick+=delta
	if toxin>=75 and _toxin_tick>=1.0:
		_toxin_tick=0
		player.hurt()


func _add_region_signs() -> void:
	_signs.append({"label":_label(Vector2(110,405),"",28,Color(0.86,0.83,0.68)),"kind":0})
	_signs.append({"label":_label(Vector2(112,442),"",18,definition.accent),"kind":1})
	_signs.append({"label":_label(Vector2(112,472),"",13,Color(0.7,0.76,0.74)),"kind":2})
	_refresh_language()


func _refresh_language() -> void:
	definition=CampaignLevels.definition(region_id)
	for signpost in _signs:
		match signpost.kind:
			0: signpost.label.text=GameText.t(definition.subtitle)
			1: signpost.label.text="%02d / 03    %s"%[AbilityCatalog.REGIONS.find(region_id)+1,definition.title]
			2: signpost.label.text=definition.secret
	if is_instance_valid(extraction): _refresh_world()


func _paint_platform(rect: Rect2,restored: bool=false) -> void:
	if _scenery_terrain!=null:
		_paint_scenery_platform(rect,restored)
		return
	if _terrain==null:
		draw_rect(rect,Color(0.17,0.24,0.22))
	else:
		var cell:=_terrain.get_size()/Vector2(2,3)
		var row:=float(definition.row)*cell.y
		var cap:=minf(32.0,rect.size.y)
		for x in range(int(rect.position.x),int(rect.end.x),128):
			var width:=minf(128.0,rect.end.x-x)
			draw_texture_rect_region(_terrain,Rect2(x,rect.position.y,width,cap),Rect2(0,row,cell.x*(width/128.0),cell.y*0.25))
			for y in range(int(rect.position.y+cap),int(rect.end.y),128):
				var height:=minf(128.0,rect.end.y-y)
				draw_texture_rect_region(_terrain,Rect2(x,y,width,height),Rect2(cell.x,row,cell.x*(width/128.0),cell.y*(height/128.0)),Color(0.72,0.72,0.75))
	draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color(0.72,0.85,0.61) if restored else definition.accent,2)


func _paint_background(origin: Vector2,view_size: Vector2) -> void:
	draw_rect(Rect2(origin,view_size),Color(0.025,0.025,0.035))
	if _background==null: return
	if definition.has("background_texture"):
		if _middle_background!=null:
			_paint_panorama(origin,view_size)
			draw_rect(Rect2(origin,view_size),definition.background_shade)
			return
		var image_size:=_background.get_size()
		var scale:=maxf(view_size.x/image_size.x,view_size.y/image_size.y)*1.06
		var dimensions:=image_size*scale
		var overflow:=dimensions-view_size
		var progress:=clampf(origin.x/maxf(1.0,float(definition.width)-view_size.x),0.0,1.0)
		var offset:=Vector2(-overflow.x*lerpf(0.15,0.85,progress),-overflow.y*0.45)
		draw_texture_rect(_background,Rect2(origin+offset,dimensions),false)
		draw_rect(Rect2(origin,view_size),definition.background_shade)
	else:
		var width:=view_size.y*_background.get_width()/_background.get_height()
		var shift:=fposmod(origin.x*0.15,width)
		for index in [-1,0,1,2]:
			var tint:=Color(0.69,0.68,0.73) if WorldProgress.land_state(region_id)==&"wasted" else Color(0.86,0.88,0.86)
			draw_texture_rect(_background,Rect2(origin+Vector2(index*width-shift,0),Vector2(width,view_size.y)),false,tint)
		draw_rect(Rect2(origin,view_size),Color(0.02,0.035,0.055,0.15))


func _mineral_tint() -> Color:
	return Color(0.87,0.84,0.97) if definition.get("scenery_style")==&"timber_pit" else Color(0.65,0.95,1)


func _paint_scenery_platform(rect: Rect2,restored: bool=false) -> void:
	if rect.size.y<=40.0:
		var variant:=posmod(floori(rect.position.x/10.0),2)
		var source: Rect2=definition.terrain_regions[2+variant]
		var depth: float=definition.platform_depths[variant]
		var sample_width:=minf(source.size.x,rect.size.x*depth/rect.size.y)
		source.position.x+=fposmod(rect.position.x*1.7,maxf(1.0,source.size.x-sample_width))
		source.size.x=sample_width
		var dimensions:=Vector2(rect.size.x,rect.size.y*source.size.y/depth)
		draw_texture_rect_region(_scenery_terrain,Rect2(rect.position,dimensions),source)
	else:
		var cap:=minf(32.0,rect.size.y)
		var surface: Rect2=definition.terrain_regions[0]
		var fill: Rect2=definition.terrain_regions[1]
		for x in range(int(rect.position.x),int(rect.end.x),128):
			var width:=minf(128.0,rect.end.x-x)
			var sample_index:=posmod(floori(x/128.0),4)
			var surface_x:=surface.position.x+sample_index*surface.size.x/4.0
			var surface_width:=surface.size.x/4.0*width/128.0
			var fill_x:=fill.position.x+sample_index*fill.size.x/4.0
			var fill_width:=fill.size.x/4.0*width/128.0
			draw_texture_rect_region(_scenery_terrain,Rect2(x,rect.position.y,width,cap),Rect2(surface_x,surface.position.y,surface_width,surface.size.y))
			for y in range(int(rect.position.y+cap),int(rect.end.y),128):
				var height:=minf(128.0,rect.end.y-y)
				draw_texture_rect_region(_scenery_terrain,Rect2(x,y,width,height),Rect2(fill_x,fill.position.y,fill_width,fill.size.y*height/128.0))
	draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color(0.65,0.8,0.47) if restored else definition.accent,2)


func _paint_panorama(origin: Vector2,view_size: Vector2) -> void:
	var images: Array[Texture2D]=[_background,_middle_background,_background]
	var narrowest:=minf(_background.get_size().aspect(),_middle_background.get_size().aspect())
	var height:=maxf(view_size.y*1.04,view_size.x*0.75/narrowest)
	var overlap:=view_size.x*0.24
	var widths: Array[float]=[]
	var total: float=-overlap*2.0
	for texture in images:
		var width:=height*texture.get_width()/texture.get_height()
		widths.append(width)
		total+=width
	var progress:=clampf(origin.x/maxf(1.0,float(definition.width)-view_size.x),0.0,1.0)
	var left: float=origin.x-progress*maxf(0.0,total-view_size.x)
	for index in images.size():
		var rect:=Rect2(Vector2(left,origin.y-(height-view_size.y)*0.5),Vector2(widths[index],height))
		_paint_panorama_panel(images[index],rect,0.0 if index==0 else overlap)
		left+=widths[index]-overlap


func _paint_panorama_panel(texture: Texture2D,rect: Rect2,fade: float) -> void:
	# Blend the new panel's left edge over the preceding painting without editing
	# either original image or allowing a viewport gap at the level boundaries.
	var seam:=minf(fade,rect.size.x)
	if seam>0:
		draw_polygon(PackedVector2Array([rect.position,rect.position+Vector2(seam,0),rect.position+Vector2(seam,rect.size.y),rect.position+Vector2(0,rect.size.y)]),PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)]),PackedVector2Array([Vector2.ZERO,Vector2(seam/rect.size.x,0),Vector2(seam/rect.size.x,1),Vector2(0,1)]),texture)
	var rest:=Rect2(rect.position+Vector2(seam,0),Vector2(rect.size.x-seam,rect.size.y))
	var source:=Rect2(Vector2(seam/rect.size.x*texture.get_width(),0),Vector2(rest.size.x/rect.size.x*texture.get_width(),texture.get_height()))
	draw_texture_rect_region(texture,rest,source)
