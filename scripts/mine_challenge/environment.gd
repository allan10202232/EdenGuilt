extends Node2D
## Scenario2 painting with only hanging lights removed; original sources retained.
## Scenery never adds collision: the eight-stage route stays identical.
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const ORIGINAL=preload("res://assets/art/generated/mine_challenge/Scenario2_unlit.png")
const EXTENSION=preload("res://assets/art/generated/scenarios/mine_middle.png")
const TERRAIN=preload("res://assets/art/generated/scenarios/mine_terrain.png")
const EXIT_ART=preload("res://assets/art/generated/mine_challenge/mine_exit_unlit.png")
var level: Node2D
var _clock:=0.0
var _resident: Texture2D
var _exit_art: AtlasTexture

class Foreground extends Node2D:
	var scenery: Node2D
	func _process(_delta: float) -> void: queue_redraw()
	func _draw() -> void: scenery.paint_foreground(self)

func _ready() -> void:
	z_index=-20
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_resident=CampaignLevels.trimmed_texture("characters/hero_green")
	_exit_art=AtlasTexture.new()
	_exit_art.atlas=EXIT_ART
	_exit_art.region=Rect2(EXIT_ART.get_image().get_used_rect())
	var foreground:=Foreground.new()
	foreground.scenery=self
	foreground.z_index=28
	add_child(foreground)

func _process(delta: float) -> void:
	if WorldProgress.can_play(): _clock+=delta
	queue_redraw()

func _draw() -> void:
	if level==null: return
	var camera:=get_viewport().get_camera_2d()
	var view:=get_viewport_rect().size
	var origin:=camera.get_screen_center_position()-view/2 if camera!=null else Vector2.ZERO
	_panorama(origin,view)
	# Existing Scenario2 rocky texture forms cliff masses rather than blank blocks.
	_rock_face(Rect2(0,1800,600,650))
	_rock_face(Rect2(5290,400,380,1800))
	# The gas shaft sits in a layered timber hoist, with open playable space.
	for x in [1900.0,2380.0]:
		_pipe(Vector2(x,430),Vector2(x,1890),level._persisted_valve,0.72)
		for y in range(550,1850,290):
			Art.draw_at(self,9,Rect2(x-56,y-110,92,180),Color(0.64,0.60,0.69,0.8))
	# Deck tops sit exactly on the collision surfaces, with hanging trusses below.
	for rect: Rect2 in level._decks:
		if rect.position==Vector2(2740,720) and level.lever.active: continue
		_walkway(rect)
	# Foreground mining plant and clustered crystal beds tell each stage apart.
	for entry in [Vector3(80,1800,0.75),Vector3(1180,1450,0.65),Vector3(3010,720,0.85),Vector3(4540,1700,0.60)]:
		Art.draw_at(self,8,Rect2(entry.x,entry.y-150*entry.z,140*entry.z,150*entry.z),Color(0.80,0.78,0.87))
	for point in [Vector2(530,1800),Vector2(1140,1800),Vector2(1710,1450),Vector2(1860,1840),Vector2(3280,720),Vector2(5285,400),Vector2(5510,400)]:
		Art.draw_at(self,12,Rect2(point-Vector2(44,78),Vector2(88,78)))
	# Pipes are authored rusted iron with couplings; the gas flow runs within them.
	var pipes:=PackedVector2Array([Vector2(1720,1450),Vector2(1720,410),Vector2(2820,410),Vector2(2820,500),Vector2(5000,500),Vector2(5000,1700)])
	for index in pipes.size()-1:
		_pipe(pipes[index],pipes[index+1],level._persisted_valve if index<2 else level.lever.active)
	# Existing resident artwork is anchored at the same conversational position.
	if _resident!=null:
		var size:=_resident.get_size()*72.0/_resident.get_height()
		draw_texture_rect(_resident,Rect2(Vector2(280-size.x/2,1800-size.y),size),false,Color(0.86,0.88,0.91))
	Art.draw_at(self,5,Rect2(308,1690,188,54),Color(0.75,0.70,0.65))
	Art.draw_at(self,3,Rect2(387,1740,18,60),Color(0.55,0.50,0.45))
	GothicSkin.draw_text(self,preload("res://assets/ui_theme.tres").default_font,Vector2(320,1722),GameText.t("碳矿化"),13)
	draw_texture_rect(_exit_art,Rect2(5354,170,200,230),false)
	_glow(Vector2(5450,322),110,Color(0.72,0.79,1.0,0.15))
	if level._returning: _return_walkway()
	# Dust and vapor are sparse enough to preserve jump and platform readability.
	for index in 28:
		var point:=origin+Vector2(fposmod(index*137.7-_clock*(5+index%4),view.x),fposmod(index*83.3+sin(_clock+index)*18,view.y))
		draw_rect(Rect2(point,Vector2(2,2)),Color(0.83,0.79,0.96,0.14+0.07*sin(index+_clock)))

func _panorama(origin: Vector2, view: Vector2) -> void:
	var images: Array[Texture2D]=[ORIGINAL,EXTENSION,ORIGINAL]
	var height:=view.y*1.15
	var overlap:=view.x*0.22
	var widths: Array[float]=[]
	var total: float=-overlap*2
	for image in images:
		var width:=height*image.get_width()/image.get_height()
		widths.append(width)
		total+=width
	var progress:=clampf(origin.x/(5600-view.x),0,1)
	var left: float=origin.x-progress*(total-view.x)
	var vertical:=clampf(origin.y/1700,0,1)
	for index in images.size():
		var rect:=Rect2(left,origin.y-(height-view.y)*lerpf(0.2,0.8,vertical),widths[index],height)
		var seam: float=0 if index==0 else overlap
		if seam>0:
			draw_polygon(PackedVector2Array([rect.position,rect.position+Vector2(seam,0),rect.position+Vector2(seam,height),rect.position+Vector2(0,height)]),PackedColorArray([Color(0.72,0.70,0.84,0),Color(0.72,0.70,0.84),Color(0.72,0.70,0.84),Color(0.72,0.70,0.84,0)]),PackedVector2Array([Vector2.ZERO,Vector2(seam/rect.size.x,0),Vector2(seam/rect.size.x,1),Vector2(0,1)]),images[index])
		var rest:=Rect2(rect.position+Vector2(seam,0),Vector2(rect.size.x-seam,height))
		draw_texture_rect_region(images[index],rest,Rect2(seam/rect.size.x*images[index].get_width(),0,rest.size.x/rect.size.x*images[index].get_width(),images[index].get_height()),Color(0.72,0.70,0.84))
		left+=widths[index]-overlap
	# Gentle cool atmospheric separation, not the former opaque grey blocks.
	draw_rect(Rect2(origin,view),Color(0.04,0.03,0.10,0.10))

func _walkway(rect: Rect2) -> void:
	var top:=rect.position
	for x in range(0,int(rect.size.x),180):
		var width:=minf(180,rect.size.x-x)
		# Use a consistent 1:2 pixel density and avoid stretching a whole atlas row.
		draw_texture_rect_region(TERRAIN,Rect2(top+Vector2(x,-1),Vector2(width,106)),Rect2(fposmod(rect.position.x+x,850),628,width*2,212))
	if rect.size.y>35:
		for x in range(15,int(rect.size.x)-20,160):
			Art.draw_at(self,12,Rect2(top+Vector2(x,-18),Vector2(32,20)),Color(0.75,0.73,0.88))

func _rock_face(rect: Rect2) -> void:
	for x in range(0,int(rect.size.x),160):
		for y in range(0,int(rect.size.y),150):
			var width:=minf(160,rect.size.x-x)
			var height:=minf(150,rect.size.y-y)
			draw_texture_rect_region(TERRAIN,Rect2(rect.position+Vector2(x,y),Vector2(width,height)),Rect2(160+posmod(x,500),320,width*1.5,height*1.5),Color(0.76,0.74,0.86))
	for x in range(0,int(rect.size.x),150):
		draw_texture_rect_region(TERRAIN,Rect2(rect.position+Vector2(x,-8),Vector2(minf(150,rect.size.x-x),33)),Rect2(x%900,69,300,64))

func _pipe(from: Vector2, to: Vector2, active: bool, shade: float=1.0) -> void:
	var distance:=from.distance_to(to)
	var angle:=(to-from).angle()
	draw_set_transform(from,angle)
	for at in range(0,int(distance),150):
		Art.draw_at(self,3,Rect2(at,-14,minf(150,distance-at),28),Color(shade,shade,shade))
	if active:
		for index in range(0,int(distance),70):
			var x:=fposmod(index+_clock*45,distance)
			draw_texture_rect(Art.puff_texture(),Rect2(x-5,-4,12,8),false,Color(0.57,0.9,0.34,0.44))
	draw_set_transform(Vector2.ZERO)

func _glow(point: Vector2, radius: float, tint: Color) -> void:
	for index in 8:
		var scale:=1.0-float(index)/9
		draw_circle(point,radius*scale,Color(tint,tint.a*0.10))

func _return_walkway() -> void:
	var angle:=Vector2(5220,-1400).angle()
	for x in range(200,5420,150):
		var y:=1800.0-(x-200)*1400.0/5220.0
		draw_set_transform(Vector2(x,y),angle)
		draw_texture_rect_region(TERRAIN,Rect2(0,0,158,70),Rect2(x%850,628,316,140),Color(0.86,0.93,0.82))
	draw_set_transform(Vector2.ZERO)

func paint_foreground(canvas: CanvasItem) -> void:
	var camera:=get_viewport().get_camera_2d()
	if camera==null: return
	var view:=get_viewport_rect().size
	var origin:=camera.get_screen_center_position()-view/2
	# Softly darkened authored stalactites frame the far corners, away from jumps.
	Art.draw_at(canvas,13,Rect2(origin+Vector2(-105,-80),Vector2(300,170)),Color(0.42,0.40,0.54,0.85))
	Art.draw_at(canvas,13,Rect2(origin+Vector2(view.x-115,-80),Vector2(250,160)),Color(0.38,0.36,0.49,0.86))
