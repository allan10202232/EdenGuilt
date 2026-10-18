class_name ScrapyardSurface
extends RefCounted
## Reuse the chapter's authored pixel terrain, keeping the walkable lip at Y=0.

const TERRAIN: Texture2D = preload("res://assets/art/generated/scenarios/junkyard_terrain.png")
const RUST := Color("765039")
const STEEL := Color("42473b")
const EDGE := Color("b8ad78")

static func deck(canvas: CanvasItem, rect: Rect2, seed: float, warning := false, style: StringName = &"scrap") -> void:
	var width := rect.size.x
	var top := rect.position
	# A continuous readable lip matches the physical top; scrap hangs below it.
	canvas.draw_rect(Rect2(top + Vector2(0,2),Vector2(width,16)),Color("30382e"))
	var segment := 0
	var x := 0.0
	while x < width:
		var length := minf(120, width-x)
		var sample_width := length * 2.8
		var sample_x := floorf(fposmod(seed*31.0+segment*217.0,1254.0-sample_width))
		var variant := posmod(int(seed)+segment,2)
		var source := Rect2(sample_x,789 if variant==0 else 1046,sample_width,180)
		canvas.draw_texture_rect_region(TERRAIN,Rect2(top+Vector2(x,-3),Vector2(length,64)),source,Color(0.88,0.86,0.72))
		x += length
		segment += 1
	canvas.draw_line(top,top+Vector2(width,0),Color("efaf65") if warning else EDGE,2)
	for stud in range(6,int(width)-3,22):
		var point := top+Vector2(stud,8)
		canvas.draw_rect(Rect2(point,Vector2(3,3)),Color("b9a575"))
		canvas.draw_rect(Rect2(point+Vector2(1,2),Vector2(3,2)),Color("272e27"))
	if warning:
		# Preserve the artwork underneath the orange stress marks.
		canvas.draw_rect(Rect2(top,Vector2(width,17)),Color(1,0.46,0.13,0.24))
		for crack in range(16,int(width),33):
			canvas.draw_polyline(PackedVector2Array([top+Vector2(crack,0),top+Vector2(crack-3,7),top+Vector2(crack+3,10),top+Vector2(crack,17)]),Color("ffbd71"),2)
	if style==&"appliance": appliance(canvas,rect,seed)

static func appliance(canvas: CanvasItem, rect: Rect2, seed: float) -> void:
	var top := rect.position+Vector2(10,20)
	var width := maxf(28,rect.size.x-20)
	canvas.draw_rect(Rect2(top,Vector2(width,30)),Color("242c26"))
	canvas.draw_rect(Rect2(top+Vector2(2,2),Vector2(width-4,25)),Color("62634b"))
	canvas.draw_rect(Rect2(top+Vector2(2,3),Vector2(width-4,4)),Color("8c8860"))
	canvas.draw_rect(Rect2(top+Vector2(3,22),Vector2(width-6,5)),RUST)
	if posmod(int(seed),3)==0:
		for slot in range(6,int(width)-6,7):
			canvas.draw_rect(Rect2(top+Vector2(slot,11),Vector2(3,9)),Color("303b31"))
	else:
		var centre := top+Vector2(width*0.48,17)
		var ring := PackedVector2Array()
		for index in 13: ring.append((centre+Vector2.from_angle(index*TAU/12.0)*10).snapped(Vector2(2,2)))
		canvas.draw_colored_polygon(ring,Color("222d29"))
		canvas.draw_polyline(ring,Color("a09b71"),2)
		canvas.draw_rect(Rect2(centre+Vector2(-4,-3),Vector2(6,4)),Color("4b6660"))
	canvas.draw_rect(Rect2(top+Vector2(width-8,10),Vector2(3,3)),Color("b89c53"))

static func chain(canvas: CanvasItem, x: float, top: float, bottom: float) -> void:
	for y in range(int(top),int(bottom),10):
		var side := 2 if posmod(floori(y/10.0),2)==0 else 0
		canvas.draw_rect(Rect2(x-2-side,y,4+side*2,8),Color("272f29"))
		canvas.draw_rect(Rect2(x-side,y+1,2+side*2,5),Color("777c61"),false,1)
