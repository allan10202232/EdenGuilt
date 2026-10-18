extends RefCounted
## Scenario2 art kit, shared by scenery and gameplay prefabs. Only visible alpha
## is included in each sprite, so its bottom/top can match collision precisely.
const ATLAS_PATH := "res://assets/art/generated/mine_challenge/mine_detail_atlas.png"
const TERRAIN := preload("res://assets/art/generated/scenarios/mine_terrain.png")
# Deliberate gutters follow the authored sheet; the tall pump and exit arch
# cross the nominal equal cells and must not be cut through their tops/sides.
const RECTS := [Rect2(10,129,309,197),Rect2(329,119,288,207),Rect2(630,145,305,175),Rect2(950,149,294,114),Rect2(11,385,307,208),Rect2(337,379,267,212),Rect2(630,476,322,99),Rect2(978,355,244,238),Rect2(10,613,323,304),Rect2(348,621,272,298),Rect2(716,627,98,303),Rect2(912,616,326,307),Rect2(10,949,320,255),Rect2(335,941,278,267),Rect2(637,1035,323,137),Rect2(993,964,233,229)]
static var _atlas: Texture2D
static var _textures: Dictionary = {}
static var _puff: Texture2D
static var _isolated: Dictionary={}

static func texture(index: int) -> Texture2D:
	if _textures.has(index): return _textures[index]
	if _atlas==null and ResourceLoader.exists(ATLAS_PATH): _atlas=load(ATLAS_PATH)
	var result:=AtlasTexture.new()
	if _atlas!=null:
		var reference: Rect2=RECTS[clampi(index,0,15)]
		var factor:=Vector2(_atlas.get_size())/1254.0
		var region:=Rect2i(reference.grow(2).position*factor,reference.grow(2).size*factor)
		var origin:=region.position
		var image:=_atlas.get_image()
		if image!=null and not image.is_empty():
			var used:=image.get_region(region).get_used_rect()
			if used.has_area(): region=Rect2i(origin+used.position,used.size)
		result.atlas=_atlas
		result.region=Rect2(region)
	else:
		# Existing authored Scenario2 crystal/timber textures remain usable during
		# the editor's first import; there are no colored placeholder polygons.
		result.atlas=TERRAIN
		if index in [0,3,5,6,7,8,9,10,11]:
			result.region=Rect2(0,632,256,290) if index in [0,3,6] else Rect2(160,645,80,200)
		else: result.region=Rect2(328,27,112,97)
	_textures[index]=result
	return result

static func draw_at(canvas: CanvasItem, index: int, rect: Rect2, tint: Color=Color.WHITE) -> void:
	canvas.draw_texture_rect(texture(index),rect,false,tint)

static func isolated_texture(index: int) -> Texture2D:
	# Shaders using normalized UV need an independent texture instead of UVs in
	# the full sprite sheet. The source artwork itself remains unchanged.
	if _isolated.has(index): return _isolated[index]
	var source:=texture(index)
	var image:=source.get_image()
	if image==null or image.is_empty(): return source
	var result:=ImageTexture.create_from_image(image)
	_isolated[index]=result
	return result

static func sprite(index: int, size: Vector2, point: Vector2=Vector2.ZERO, tint: Color=Color.WHITE) -> Sprite2D:
	var node:=Sprite2D.new()
	node.texture=texture(index)
	node.position=point
	node.scale=size/node.texture.get_size()
	node.modulate=tint
	node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	return node

static func puff_texture() -> Texture2D:
	if _puff!=null: return _puff
	if ResourceLoader.exists(ATLAS_PATH):
		_puff=texture(15)
		return _puff
	var gradient:=Gradient.new()
	gradient.set_color(0,Color(1,1,1,.7))
	gradient.set_color(1,Color(1,1,1,0))
	var radial:=GradientTexture2D.new()
	radial.width=64
	radial.height=64
	radial.gradient=gradient
	radial.fill=GradientTexture2D.FILL_RADIAL
	radial.fill_from=Vector2(.5,.5)
	radial.fill_to=Vector2(1,.5)
	_puff=radial
	return _puff
