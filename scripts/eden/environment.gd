class_name EdenChapterEnvironment
extends Node2D
const PARADISE=preload("res://assets/art/originals/eden/paradise.jpeg")
const PROCESSING=preload("res://assets/art/originals/eden/processing.jpeg")
const TERRAIN=preload("res://assets/art/generated/scenarios/eden_terrain.png")
const MineArt=preload("res://scripts/mine_challenge/mine_art.gd")
var level: Node2D
var _clock:=0.0

func _ready() -> void:
	z_index=-20
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if WorldProgress.can_play(): _clock+=delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,2400,2600),Color("121d20"))
	draw_texture_rect(PARADISE,Rect2(0,1320,2400,1280),false,Color(0.78,0.85,0.78))
	draw_texture_rect(PROCESSING,Rect2(0,0,2400,1340),false,Color(0.78,0.89,0.83))
	for index in 10:
		draw_rect(Rect2(0,1280+index*8,2400,8),Color(0.05,0.11,0.1,0.45*(1.0-index/10.0)))
	for deck: Rect2 in level.decks:
		if deck.position.y>1340:
			var region:=Rect2(0,171,1254,64)
			for x in range(int(deck.position.x),int(deck.end.x),180):
				var width:=minf(180,deck.end.x-x)
				draw_texture_rect_region(TERRAIN,Rect2(x,deck.position.y,width,38),region)
				draw_line(Vector2(x+18,deck.position.y+35),Vector2(x+7,deck.position.y+80),Color("638b4f"),4)
		else:
			for x in range(int(deck.position.x),int(deck.end.x),160):
				var source:=Rect2(PROCESSING.get_size()*Vector2(0.239,0.559),PROCESSING.get_size()*Vector2(0.28,0.034))
				draw_texture_rect_region(PROCESSING,Rect2(x,deck.position.y,minf(160,deck.end.x-x),28),source,Color("a4b4a6"))
			draw_line(deck.position,Vector2(deck.end.x,deck.position.y),Color("bfd3bd"),3)
			for x in range(int(deck.position.x+30),int(deck.end.x),120):
				draw_line(Vector2(x,deck.position.y+36),Vector2(x-20,deck.position.y+80),Color("3c5147"),6)
	# Supply lines belong to the machinery; the living tree remains in the painting.
	for points in [PackedVector2Array([Vector2(1200,360),Vector2(1040,280),Vector2(700,420),Vector2(500,320)]),PackedVector2Array([Vector2(1200,360),Vector2(1670,150),Vector2(2140,170),Vector2(2140,250)]),PackedVector2Array([Vector2(1200,360),Vector2(1610,720),Vector2(1910,940)]),PackedVector2Array([Vector2(1910,940),Vector2(2250,1450),Vector2(2240,1790)])]:
		draw_polyline(points,Color("24382e"),12)
		draw_polyline(points,Color("9fbaa1") if not level.boss.dismantled else Color("52665a"),4)
	for x in [90,2340]:
		draw_line(Vector2(x,50),Vector2(x,2540),Color("2b3c31"),14)
	for point in [Vector2(105,1880),Vector2(2280,1260),Vector2(485,570),Vector2(2060,230)]:
		draw_circle(point,35,Color(0.76,0.94,0.7,0.08+0.03*sin(_clock*2)))
		draw_rect(Rect2(point-Vector2(4,13),Vector2(8,26)),Color("d4e3b1"))
