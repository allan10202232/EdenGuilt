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
var _pickups: Array[Area2D] = []
var _checkpoints: Array = []
var _clock: float = 0.0
var _background: Texture2D
var _terrain: Texture2D
var _companion_texture: Texture2D
var _companions: Array[Vector2] = []
var _bursts: Array[Dictionary] = []
var _source_label: Label
var _gate: StaticBody2D
var _route_ready: bool = false
var _source_sprite: Sprite2D


func _ready() -> void:
	definition = CampaignLevels.definition(region_id)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background = CampaignLevels.texture("backgrounds/"+definition.background)
	_terrain = CampaignLevels.texture("terrain/biome_atlas")
	_companion_texture = CampaignLevels.trimmed_texture("characters/hero_green")
	player.position = WorldProgress.spawn_position
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
	_add_platform(Rect2(-32,0,32,definition.height))
	_add_platform(Rect2(definition.width,0,32,definition.height))
	_gate = _add_platform(definition.gate)
	for rect: Rect2 in definition.spikes:
		_spike_areas.append(_area(rect,"Spikes"))
	for index in definition.beams.size():
		var hazard := CampaignHazard.new()
		hazard.player = player
		hazard.area = definition.beams[index]
		hazard.region_ability = definition.ability
		hazard.offset = index*0.7
		add_child(hazard)
		hazards.append(hazard)
	for index in definition.enemies.size():
		_spawn_enemy(definition.enemies[index],definition.patrols[index],"mob_%d"%index)
	if definition.has("boss"):
		_spawn_enemy(definition.boss,Vector2(3640,4140),"boss",true)
	for index in definition.shards.size():
		_spawn_shard(definition.shards[index],index)
	for index in definition.checkpoints.size():
		var point: Vector2 = definition.checkpoints[index]
		var area := _area(Rect2(point-Vector2(22,30),Vector2(44,54)),"Checkpoint")
		area.body_entered.connect(_on_checkpoint.bind(point,index))
		_checkpoints.append(point)
	var exit_point: Vector2 = definition.exit
	_area(Rect2(exit_point-Vector2(25,45),Vector2(50,100)),"Exit").body_entered.connect(_on_exit)
	_area(Rect2(22,480,30,140),"Entrance").body_entered.connect(_on_entrance)
	_source_label = _label(definition.source+Vector2(45,-100),"",16)
	_source_sprite = Sprite2D.new()
	_source_sprite.texture = _companion_texture
	if _companion_texture != null:
		_source_sprite.scale = Vector2.ONE*64.0/_companion_texture.get_height()
	_source_sprite.position = definition.source+Vector2(0,-45)
	add_child(_source_sprite)
	_label(Vector2(110,280),definition.subtitle,38,Color(0.86,0.83,0.68))
	_label(Vector2(112,335),"%02d / 03    %s"%[AbilityCatalog.REGIONS.find(region_id)+1,definition.title],20,definition.accent)
	_label(Vector2(112,370),definition.secret,15,Color(0.7,0.76,0.74))
	var exit_label:=_label(exit_point+Vector2(-100,-115),"救援舱 →" if region_id==&"remnant_sea" else "下一关 →",17)
	if region_id==&"remnant_sea":
		exit_label.name="RescueLabel"
	WorldProgress.world_changed.connect(_refresh_world)
	_refresh_world()
	# A playable campaign needs a starting weapon; formal acquisition remains configurable.
	if WorldProgress.ability_state(&"light_blade")==WorldProgress.AbilityState.UNAVAILABLE:
		WorldProgress.borrow_ability(&"light_blade")
		WorldProgress.set_notice("光刃已就绪：左键短砍，右键长砍。靠近能力源按 E。")
	queue_redraw()


func _process(delta: float) -> void:
	if not WorldProgress.can_play():
		return
	_clock+=delta
	for area in _pickups:
		if is_instance_valid(area):
			area.get_child(1).position.y=sin(_clock*3.5+area.position.x)*4.0
	_source_sprite.position.y = definition.source.y-45.0+sin(_clock*2.0)*3.0
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
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not WorldProgress.can_play():
		return
	for area in _spike_areas:
		if area.overlaps_body(player):
			player.hurt(20)
	if player.position.distance_to(definition.source)<108.0:
		if Input.is_action_just_pressed(&"eden_absorb"):
			WorldProgress.borrow_ability(definition.ability)
		elif Input.is_action_just_pressed(&"eden_return"):
			if WorldProgress.returning:
				WorldProgress.return_ability(definition.ability)
			else:
				WorldProgress.set_notice("先前往矿厂救出伙伴，再返程交还能力。")
	if Input.is_action_just_pressed(&"eden_trial_blade") and OS.is_debug_build():
		WorldProgress.borrow_ability(&"light_blade")


func _on_checkpoint(body: Node2D,point: Vector2,index: int) -> void:
	if body==player and WorldProgress.set_checkpoint(StringName("%s/cp_%d"%[region_id,index]),point,"%s · %02d"%[definition.title,index+1]):
		player.stats.heal(30)


func _on_exit(body: Node2D) -> void:
	if body!=player or not WorldProgress.can_play():
		return
	var ability: StringName = definition.ability
	if WorldProgress.ability_state(ability)==WorldProgress.AbilityState.UNAVAILABLE:
		WorldProgress.set_notice("本关的%s尚未获得，返回发光的能力源按 E。"%AbilityCatalog.DEFINITIONS[ability].name)
		return
	var index:=AbilityCatalog.REGIONS.find(region_id)
	if index<2:
		WorldProgress.enter_scene(AbilityCatalog.REGIONS[index+1],Vector2(140,596))
	elif not WorldProgress.is_enemy_defeated(_entity_id("boss")):
		WorldProgress.set_notice("晶甲监工仍在守卫矿厂，先击败它再打开救援舱。")
	else:
		WorldProgress.begin_return_journey()


func _on_entrance(body: Node2D) -> void:
	if body!=player or not WorldProgress.can_play():
		return
	var index:=AbilityCatalog.REGIONS.find(region_id)
	if index>0:
		var previous: StringName = AbilityCatalog.REGIONS[index-1]
		var previous_exit: Vector2 = CampaignLevels.definition(previous).exit
		WorldProgress.enter_scene(previous,previous_exit-Vector2(90,24))
	elif WorldProgress.returning and WorldProgress.required_returns_complete():
		GameSession.complete_level()
	else:
		WorldProgress.set_notice("向右探索三关，救出伙伴后从这里回家。")


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
		WorldProgress.set_notice("晶甲监工已击败。右侧救援舱已经可以开启。")


func _spawn_projectile(origin: Vector2,direction: float) -> void:
	var bolt:=preload("res://scripts/campaign/projectile.gd").new()
	bolt.position=origin
	bolt.direction=direction
	bolt.player=player
	add_child(bolt)


func _spawn_shard(point: Vector2,index: int) -> void:
	var id:=_entity_id("shard_%d"%index)
	if WorldProgress.is_collected(id):
		return
	var area:=_area(Rect2(point-Vector2(12,18),Vector2(24,36)),"Shard")
	var gem:=Polygon2D.new()
	gem.polygon=PackedVector2Array([Vector2(0,-14),Vector2(9,0),Vector2(0,14),Vector2(-9,0)])
	gem.color=Color(0.98,0.77,0.36)
	area.add_child(gem)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body==player and WorldProgress.collect_once(id):
			player.stats.add_score(100)
			SoundManager.play_sfx(&"pickup",-7)
			area.queue_free()
	)
	_pickups.append(area)


func _refresh_world() -> void:
	var ability: StringName=definition.ability
	var status:=WorldProgress.ability_state(ability)
	_source_label.text="%s之灵\n%s"%[AbilityCatalog.DEFINITIONS[ability].name,["E  吸收能力","R  交还能力","通路已恢复"][status]]
	_source_label.modulate=definition.accent
	_source_sprite.modulate=Color(0.65,0.68,0.62) if status==WorldProgress.AbilityState.BORROWED else Color.WHITE
	var unlocked:=WorldProgress.has_ability(ability) or WorldProgress.route_open(ability)
	_gate.get_child(0).set_deferred(&"disabled",unlocked)
	if WorldProgress.route_open(ability) and not _route_ready:
		_route_ready=true
		_install_route.call_deferred()
	if WorldProgress.returning:
		_label_mission_return()
	queue_redraw()


func _label_mission_return() -> void:
	# Entrance and exit labels are world-space signposts, never collidable art.
	var rescue := get_node_or_null("RescueLabel") as Label
	if rescue != null:
		rescue.text="伙伴已获救 · 向左返程" if WorldProgress.returning else "救援舱 →"


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


func _label(point: Vector2,text: String,size: int,tint: Color=Color(0.85,0.85,0.74)) -> Label:
	var label:=Label.new()
	label.position=point
	label.text=text
	label.theme=preload("res://assets/ui_theme.tres")
	label.add_theme_font_size_override(&"font_size",size)
	label.add_theme_constant_override(&"outline_size",4)
	label.add_theme_color_override(&"font_outline_color",Color(0.025,0.04,0.045,0.85))
	label.modulate=tint
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
	var origin:=camera.get_screen_center_position()-size*0.5 if camera!=null else Vector2.ZERO
	draw_rect(Rect2(origin,size),Color(0.02,0.035,0.055))
	if _background!=null:
		var width:=size.y*_background.get_width()/_background.get_height()
		var shift:=fposmod(origin.x*0.15,width)
		for index in [-1,0,1,2]:
			var tint:=Color(0.69,0.68,0.73) if WorldProgress.land_state(region_id)==&"wasted" else Color(0.86,0.88,0.86)
			draw_texture_rect(_background,Rect2(origin+Vector2(index*width-shift,0),Vector2(width,size.y)),false,tint)
		draw_rect(Rect2(origin,size),Color(0.02,0.035,0.055,0.15))
	for rect: Rect2 in _platforms:
		_paint_platform(rect)
	for rect: Rect2 in _route_platforms:
		_paint_platform(rect,true)
	for points: PackedVector2Array in _route_ramps:
		if _terrain!=null:
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
		for x in range(int(rect.position.x),int(rect.end.x)-8,14):
			draw_colored_polygon(PackedVector2Array([Vector2(x,rect.end.y),Vector2(x+7,rect.position.y),Vector2(x+14,rect.end.y)]),Color(0.77,0.36,0.34))
	var source: Vector2=definition.source
	draw_rect(Rect2(source-Vector2(28,-3),Vector2(56,20)),Color(0.2,0.27,0.26))
	draw_arc(source-Vector2(0,40),45.0,_clock*0.5,_clock*0.5+TAU*0.8,32,Color(definition.accent,0.45),2)
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
	if _companion_texture!=null:
		var scale:=38.0/_companion_texture.get_height()
		var dimensions:=_companion_texture.get_size()*scale
		for point in _companions:
			draw_texture_rect(_companion_texture,Rect2(point-Vector2(dimensions.x*0.5,16),dimensions),false,Color(0.7,0.95,0.8))


func _paint_platform(rect: Rect2,restored: bool=false) -> void:
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
