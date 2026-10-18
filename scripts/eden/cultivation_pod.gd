class_name EdenCultivationPod
extends Node2D
var level: Node2D
var pod_id:=1
var released:=false
var bio_lock: EdenLightReceiver
var valve_cut:=false
var _hurtbox: MeleeHurtbox
var _person: Sprite2D
var seal_seconds:=0.0

func play_seal() -> void:
	seal_seconds=1.2

func _process(delta: float) -> void:
	if seal_seconds>0 and (WorldProgress.can_play() or WorldProgress.narrative_kind==&"eden_lift"):
		seal_seconds=maxf(0,seal_seconds-delta)
		queue_redraw()

func _ready() -> void:
	z_index=4
	bio_lock=EdenLightReceiver.new()
	bio_lock.level=level
	bio_lock.position=Vector2(45,-30)
	bio_lock.on_reflect=func(_shot: Node2D) -> bool:
		return WorldProgress.core_reversed and not released and pod_id==WorldProgress.eden_chapter.get("rescued",[]).size()+1

	add_child(bio_lock)
	bio_lock.charged.connect(func(_receiver: EdenLightReceiver) -> void:
		if pod_id!=2: release_human()
	)
	_hurtbox=MeleeHurtbox.new()
	_hurtbox.collision_layer=4
	_hurtbox.collision_mask=0
	var collision:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(80,130)
	collision.shape=box
	collision.position.y=-42
	_hurtbox.add_child(collision)
	add_child(_hurtbox)
	_person=Sprite2D.new()
	_person.texture=CampaignLevels.trimmed_texture("characters/hero_green")
	_person.scale=Vector2.ONE*72/_person.texture.get_height()
	_person.position.y=-48
	_person.modulate=Color("b2d8c4")
	add_child(_person)
	refresh()

func refresh() -> void:
	released=pod_id in WorldProgress.eden_chapter.get("rescued",[])
	if is_instance_valid(bio_lock): bio_lock.visible=not released
	if is_instance_valid(_person): _person.visible=not released
	queue_redraw()

func receive_melee_hit(_hit: Dictionary) -> bool:
	if not WorldProgress.can_play() or released or not WorldProgress.core_reversed or pod_id!=2: return false
	valve_cut=true
	release_human()
	return true

func release_human() -> bool:
	if released or not WorldProgress.core_reversed: return false
	var ids: Array=WorldProgress.eden_chapter.get("rescued",[])
	if pod_id in ids: return false
	# Top-down rescue order keeps all three return encounters meaningful.
	if pod_id!=ids.size()+1: return false
	ids.append(pod_id)
	WorldProgress.eden_chapter["rescued"]=ids
	CarbonLedger.rescued_people=ids.size()
	CarbonLedger.changed.emit()
	released=true
	refresh()
	level.on_pod_rescued(pod_id)
	return true

func _draw() -> void:
	var tint:=Color("94d8bd") if not released else Color("65766d")
	draw_style_box(GothicSkin.panel(0,5),Rect2(-45,-119,90,134))
	draw_rect(Rect2(-33,-109,66,110),Color(0.37,0.75,0.64,0.15 if released else 0.5))
	draw_arc(Vector2(0,-108),34,PI,TAU,16,tint,4)
	for side in [-1,1]: draw_line(Vector2(side*37,-106),Vector2(side*37,2),tint,5)
	if not released:
		draw_line(Vector2(-42,-87),Vector2(-62,-83),Color("e0f7d9"),6)
		GothicSkin.draw_text(self,ThemeDB.fallback_font,Vector2(-33,-136),"POD %02d"%pod_id,15)
		if seal_seconds>0:
			var closing:=minf(1,(1.2-seal_seconds)*3)
			for side in [-1,1]:
				draw_rect(Rect2(Vector2(side*35-5,-115),Vector2(10,115*closing)),Color("d7e9c4"))
			draw_line(Vector2(-30,-110+closing*100),Vector2(30,-110+closing*100),Color("ebc890"),4)
	else: GothicSkin.draw_text(self,ThemeDB.fallback_font,Vector2(-39,-136),"RELEASED",13)
