class_name MineLifeSeam
extends "res://scripts/presentation/campaign_oasis.gd"
## A living lichen seam rooted in the mine's own ore and timber, not a garden.
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
var _crystals: Sprite2D
var _source_label: Label

func setup(id: StringName,_biome: String,ground: Vector2) -> void:
	ability=id
	position=ground
	z_index=2
	flow_width=150
	energy_color=Color(0.62,0.91,0.85)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	artwork=Art.sprite(12,Vector2(172,72),Vector2(0,-31),Color(0.67,0.79,0.74))
	add_child(artwork)
	_crystals=Art.sprite(4,Vector2(62,66),Vector2(36,-34),Color(0.67,0.88,0.94))
	add_child(_crystals)
	_source_label=Label.new()
	_source_label.position=Vector2(-130,-132)
	_source_label.custom_minimum_size.x=260
	_source_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_source_label.theme=preload("res://assets/ui_theme.tres")
	_source_label.add_theme_font_size_override(&"font_size",15)
	_source_label.add_theme_constant_override(&"outline_size",4)
	_source_label.add_theme_color_override(&"font_outline_color",Color(0.02,0.025,0.035))
	add_child(_source_label)
	WorldProgress.world_changed.connect(refresh_state)
	GameText.language_changed.connect(_refresh_label)
	refresh_state()

func extraction_notice() -> String:
	return GameText.t("正在抽取矿脉生命力……岩缝中的微光与苔藓正在暗去。")

func completion_notice() -> String:
	return GameText.t("获得碳矿化。潮湿矿脉已经失去微光，按 E / J 释放矿化脉冲。")

func set_depletion(progress: float) -> void:
	vitality=1.0-clampf(progress,0,1)
	artwork.modulate=Color("44483d").lerp(Color("a5c5b5"),vitality)
	_crystals.modulate=Color("4b4947").lerp(Color("a6d6df"),vitality)
	_refresh_label()
	queue_redraw()

func _refresh_label() -> void:
	if _source_label==null: return
	_source_label.text=GameText.t("碳矿化") if WorldProgress.ability_state(ability)==WorldProgress.AbilityState.UNAVAILABLE else GameText.t("矿脉已枯竭") if WorldProgress.has_ability(ability) else GameText.t("矿脉已共同修复")

func _process(delta: float) -> void:
	super._process(delta)
	if _source_label==null: return
	var actor:=get_tree().get_first_node_in_group(&"player") as Node2D
	_source_label.visible=is_instance_valid(actor) and WorldProgress.can_play() and actor.position.distance_to(position)<140

func _draw() -> void:
	for index in 19:
		var x:=float(-75+index*8)
		var y:=-10.0-float(posmod(index*13,17))
		var strength:=vitality*(0.65+0.2*sin(_clock*1.8+index))
		draw_polyline(PackedVector2Array([Vector2(x,2),Vector2(x+3,-6),Vector2(x-1,y)]),Color("32453a").lerp(Color("73b1a2"),strength),2)
		if vitality>0:
			draw_rect(Rect2(x-2,y,4,2),Color(0.65,0.94,0.83,strength))
	for index in 7:
		var start:=Vector2(-65+index*21,0)
		draw_line(start,start+Vector2(8,8),Color(0.12,0.15,0.14,1-vitality),2)
