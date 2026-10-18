class_name CampaignLevels
extends RefCounted
## Foreground collisions are authored separately from decorative background art.

const ART: String = "res://assets/art/generated/"
const ALIASES: Dictionary = {&"lone_tree": &"forest", &"grassland": &"junkyard", &"remnant_sea": &"mine"}
static var _textures: Dictionary = {}
static var _trimmed: Dictionary = {}
static var DATA: Dictionary = {
	&"forest": {
		"title": "森林", "subtitle": "THE WHISPERWOOD", "width": 3840.0, "height": 960.0,
		"accent": Color(0.54,0.78,0.49), "row": 0, "ability": &"double_jump",
		"enemy": "forest_crawler", "background": "forest", "source": Vector2(420,590),
		"platforms": [Rect2(0,620,900,340),Rect2(1200,500,480,460),Rect2(1680,620,700,340),Rect2(2700,620,1140,340),
			Rect2(280,480,160,24),Rect2(540,380,160,24),Rect2(950,720,110,24),Rect2(900,850,300,110),
			Rect2(1450,340,170,24),Rect2(1940,490,170,24),Rect2(2200,380,180,24),Rect2(2460,500,150,24),Rect2(3200,500,220,24)],
		"enemies": [Vector2(650,596),Vector2(1450,476),Vector2(2020,596),Vector2(2940,596),Vector2(3300,476)],
		"patrols": [Vector2(540,800),Vector2(1260,1600),Vector2(1800,2270),Vector2(2780,3130),Vector2(3230,3380)],
		"shards": [Vector2(350,445),Vector2(620,345),Vector2(1040,810),Vector2(1510,305),Vector2(2290,345),Vector2(3330,465)],
		"checkpoints": [Vector2(140,596),Vector2(1320,476),Vector2(2830,596)],
		"spikes": [Rect2(1800,598,90,22),Rect2(3060,598,90,22)], "beams": [],
		"bridges": [Rect2(2380,620,320,80)],
		"ramps": [PackedVector2Array([Vector2(900,620),Vector2(1200,500),Vector2(1200,960),Vector2(900,960)])],
		"exit": Vector2(3750,570), "gate": Rect2(1190,300,20,200),
		"secret": "树冠与谷底藏有额外碎片；二段跳能到达上层。",
	},
	&"junkyard": {
		"title": "垃圾场", "subtitle": "RUSTFALL YARD", "width": 4080.0, "height": 960.0,
		"accent": Color(0.87,0.57,0.29), "row": 1, "ability": &"dash",
		"enemy": "scrap_scavenger", "background": "junkyard", "source": Vector2(530,590),
		"platforms": [Rect2(0,620,1200,340),Rect2(1440,620,1160,340),Rect2(2760,500,1320,460),
			Rect2(330,460,220,28),Rect2(650,340,220,28),Rect2(1080,460,180,28),
			Rect2(1750,380,250,28),Rect2(2290,480,180,28),Rect2(3040,350,280,28)],
		"enemies": [Vector2(790,596),Vector2(1550,596),Vector2(2360,596),Vector2(2980,476),Vector2(3160,326),Vector2(3700,476)],
		"patrols": [Vector2(650,1050),Vector2(1470,1670),Vector2(2260,2500),Vector2(2800,3000),Vector2(3070,3290),Vector2(3520,3900)],
		"shards": [Vector2(430,425),Vector2(750,305),Vector2(1170,425),Vector2(1860,345),Vector2(2380,445),Vector2(3180,315)],
		"checkpoints": [Vector2(140,596),Vector2(1640,596),Vector2(2860,476)],
		"spikes": [Rect2(940,598,90,22),Rect2(3380,478,90,22)],
		"beams": [Rect2(1780,420,90,200),Rect2(2070,420,90,200)],
		"bridges": [Rect2(1200,620,240,80)],
		"ramps": [PackedVector2Array([Vector2(2600,620),Vector2(2760,500),Vector2(2760,960),Vector2(2600,960)])],
		"exit": Vector2(3990,450), "gate": Rect2(1730,340,18,280),
		"secret": "高架废铁台有碎片；黄灯预警后会出现电弧。",
	},
	&"mine": {
		"title": "矿厂", "subtitle": "THE BLACK FOUNDRY", "width": 4400.0, "height": 1080.0,
		"accent": Color(0.39,0.77,0.91), "row": 2, "ability": &"shield",
		"enemy": "crystal_miner", "background": "mine", "source": Vector2(420,590),
		"platforms": [Rect2(0,620,1000,460),Rect2(1280,620,920,460),Rect2(2200,820,700,260),Rect2(2900,620,1500,460),
			Rect2(700,460,210,28),Rect2(1030,480,180,28),Rect2(1700,390,200,28),
			Rect2(2200,650,200,28),Rect2(2460,520,200,28),Rect2(2740,420,250,28),Rect2(3200,470,220,28)],
		"enemies": [Vector2(760,596),Vector2(1440,596),Vector2(1800,366),Vector2(2540,796),Vector2(3260,446)],
		"patrols": [Vector2(650,920),Vector2(1320,1500),Vector2(1730,1860),Vector2(2310,2780),Vector2(3230,3390)],
		"shards": [Vector2(800,425),Vector2(1120,445),Vector2(1800,355),Vector2(2550,485),Vector2(2830,385),Vector2(3320,435)],
		"checkpoints": [Vector2(140,596),Vector2(1360,596),Vector2(3050,596),Vector2(3530,596)],
		"spikes": [Rect2(1980,598,100,22),Rect2(2600,798,100,22)],
		"beams": [Rect2(1580,320,180,300),Rect2(1880,320,180,300)],
		"bridges": [Rect2(1000,620,280,80),Rect2(2200,620,700,60)], "ramps": [],
		"exit": Vector2(4320,570), "gate": Rect2(1540,300,18,320),
		"boss": Vector2(3890,576), "secret": "护盾挡住蒸汽；矿厂深处有晶甲监工。",
	},
}


static func definition(id: StringName) -> Dictionary:
	var key: StringName = ALIASES.get(id,id)
	return DATA.get(key,DATA[&"forest"]).duplicate(true)


static func texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var resource := ART + path + ".png"
	var result := load(resource) as Texture2D if ResourceLoader.exists(resource) else null
	if result != null:
		_textures[path] = result
	return result


static func trimmed_texture(path: String) -> Texture2D:
	if _trimmed.has(path):
		return _trimmed[path]
	var source := texture(path)
	if source == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = source.get_image().get_used_rect()
	_trimmed[path] = atlas
	return atlas
