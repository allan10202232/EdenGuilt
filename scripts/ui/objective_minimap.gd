extends Control
## Local, geometry-driven map. No carbon or ability telemetry is exposed here.
var objective: String=""
var target:=Vector2.ZERO
var _actor: CharacterBody2D
var _rects: Array[Rect2]=[]
var _bounds:=Rect2(0,0,5600,2400)
var _view:=Rect2()
var _title: Label
var _goal: Label
var _refresh:=0.0
var _style: StyleBox
const MAP:=Rect2(12,70,246,106)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left=-290
	offset_right=-20
	offset_top=20
	offset_bottom=206
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_style=GothicSkin.panel(0,8)
	_title=_label(13,Vector2(12,8))
	_goal=_label(15,Vector2(12,29))
	_goal.size=Vector2(246,38)
	_goal.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _label(font_size: int,point: Vector2) -> Label:
	var label:=Label.new()
	label.position=point
	label.add_theme_font_size_override(&"font_size",font_size)
	label.add_theme_color_override(&"font_color",Color("fff3d9"))
	label.add_theme_color_override(&"font_outline_color",Color("100f0b"))
	label.add_theme_constant_override(&"outline_size",4)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _process(delta: float) -> void:
	_refresh-=delta
	if _refresh>0: return
	_refresh=.08
	_actor=get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if not is_instance_valid(_actor): return
	var level:=_actor.get_parent()
	_rects.clear()
	var zh:=GameText.language=="zh_CN"
	if level is ScrapyardParkourLevel:
		_bounds=Rect2(0,0,9600,1100)
		_rects.assign(level._platforms)
		for platform in level.platforms:
			if is_instance_valid(platform) and platform.visible:
				_rects.append(Rect2(platform.position-Vector2(platform.width/2,0),Vector2(platform.width,18)))
		var section: int=level.current_section
		_title.text=ScrapyardLayout.text("SCRAPYARD","垃圾场")+" · %d / 6"%(section+1)
		if WorldProgress.returning:
			target=Vector2(100,476) if not WorldProgress.has_ability(&"double_jump") else Vector2(200,500)
			objective="返回家园" if zh else "Return home"
		elif not WorldProgress.has_ability(&"double_jump"):
			target=Vector2(200,500)
			objective="寻找生命源" if zh else "Find the living source"
		else:
			target=ScrapyardLayout.SECTIONS[mini(section+1,5)].spawn if section<5 else Vector2(9500,296)
			objective="穿过废料区，前往矿坑" if zh else "Cross the scrapyard to the mine"
	elif level is EdenChapterLevel:
		_bounds=Rect2(0,0,2400,2600)
		_rects.assign(level.decks)
		_title.text=("伊甸城 · %d 层" if zh else "EDEN CITY · %dF")%(1 if _actor.position.y>=2000 else 2 if _actor.position.y>=1350 else 3 if _actor.position.y>=700 else 4)
		var index: int=clampi(level.current_node-1,0,11)
		target=[Vector2(250,1898),Vector2(350,1898) if not WorldProgress.has_ability(&"shield") else Vector2(1070,1800),Vector2(1640,1876),Vector2(2240,1898),Vector2(2240,1298),Vector2(1920,1028),Vector2(1230,1015),Vector2(540,598),Vector2(1200,598),Vector2(1200,598),Vector2(740,598),Vector2(2110,258)][index]
		var en=["Climb the western stairs","Learn Shield; reflect the light","Defeat the Garden Steward","Ride the eastern lift","Find the Dark Dash source","Sever Oren's conduit","Open and cross the dual gates","Climb the mineralized vents","Enter the life furnace","Expose the furnace core","Break the guardian's armor","Sever the final extraction lock"]
		var cn=["攀上西侧阶梯","学习护盾并反射光束","击败净园执事","乘东侧电梯上升","寻找黑穿能力源","切断奥伦的管线","打开并穿过双重闸门","沿矿化气柱攀升","进入生命熔炉","暴露熔炉核心","击破守卫装甲","切断最后的抽取锁"]
		objective=cn[index] if zh else en[index]
		if WorldProgress.returning:
			var count:=CarbonLedger.rescued_people
			objective=("救出居民 %d / 3" if zh else "Free the residents · %d / 3")%count
			target=level.pods[mini(count,2)].position if count<3 else EdenBlueprint.ENTRY
			if count==3: objective="返回一层入口，修复并离开" if zh else "Restore the entrance and return home"
	elif level.get("current_stage")!=null:
		_bounds=Rect2(0,0,5600,2400)
		_rects.assign(level.get("_decks"))
		for vent in level.get("vents"):
			if is_instance_valid(vent.platform): _rects.append(Rect2(vent.position-Vector2(vent.width/2,0),Vector2(vent.width,12)))
		var stage: int=level.current_stage
		_title.text=("毒雾矿坑" if zh else "TOXIC MINE")+" · %d / 8"%stage
		objective=level.stage_name()
		target=level.CHECKPOINTS[mini(stage,7)]
		if not WorldProgress.has_ability(&"mineralization") and not WorldProgress.returning:
			objective="寻找生命源，学习碳矿化" if zh else "Find the source; learn Mineralization"
			target=Vector2(420,1778)
		elif stage==3 and not level.weight_switch.pressed: target=Vector2(1720,1428)
		elif stage==5 and not level.lever.active: target=level.lever.position
		if WorldProgress.returning:
			target=Vector2(420,1778) if WorldProgress.has_ability(&"mineralization") else Vector2(80,1778)
			objective="修复矿坑，返回垃圾场" if zh else "Restore the mine; return to the scrapyard"
	elif level.get("map_rects")!=null:
		_rects.assign(level.map_rects)
		_bounds=level.map_bounds
		_title.text="THE OLD HOIST" if not zh else "旧矿井升降间"
		objective="Explore the doors and open lift" if not zh else "探索房门与开放式升降台"
		target=Vector2(1280,550)
	_goal.text=objective
	var extent:=Vector2(1700,900) if _bounds.size.x>4000 and _bounds.size.y<1500 else Vector2(1900,1100)
	extent=extent.min(_bounds.size)
	_view=Rect2((_actor.position-extent/2).clamp(_bounds.position,_bounds.end-extent),extent)
	queue_redraw()

func _point(point: Vector2) -> Vector2:
	return MAP.position+(point-_view.position)/_view.size*MAP.size

func _draw() -> void:
	if _style!=null: draw_style_box(_style,Rect2(Vector2.ZERO,size))
	draw_rect(MAP,Color(.035,.045,.035,.72))
	if not is_instance_valid(_actor) or _view.size.x<=0: return
	for rect in _rects:
		var clipped:=rect.intersection(_view)
		if clipped.has_area():
			var ink:=Rect2(_point(clipped.position),clipped.size/_view.size*MAP.size)
			ink.size.y=maxf(2,ink.size.y)
			draw_rect(ink,Color("9e9c77"))
	var goal:=_point(target).clamp(MAP.position+Vector2(4,4),MAP.end-Vector2(4,4))
	draw_polyline(PackedVector2Array([goal+Vector2(0,-4),goal+Vector2(4,0),goal+Vector2(0,4),goal+Vector2(-4,0),goal+Vector2(0,-4)]),Color("e1c484"),1.5,true)
	var actor_point:=_point(_actor.position)
	draw_circle(actor_point,4,Color("122119"))
	draw_circle(actor_point,2.5,Color("b2f2b0"))
