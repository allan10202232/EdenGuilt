class_name CampaignLevels
extends RefCounted
## Foreground collisions are authored separately from decorative background art.

const ART: String = "res://assets/art/generated/"
const ALIASES: Dictionary = {&"lone_tree": &"junkyard_start", &"grassland": &"toxic_mine", &"remnant_sea": &"eden_garden"}
static var _textures: Dictionary = {}
static var _trimmed: Dictionary = {}
static var DATA: Dictionary = {
	&"junkyard_start": {
		"title": "垃圾场", "subtitle": "SCRAPYARD PARKOUR · SIX SECTIONS", "width": 9600.0, "height": 960.0,
		"accent": Color(0.72,0.72,0.36), "row": 1, "ability": &"double_jump",
		"enemy": "scrap_scavenger", "background": "junkyard", "source": Vector2(230,470),
		"background_texture": preload("res://assets/art/originals/scenarios/Scenario1.png"),
		"middle_background": preload("res://assets/art/generated/scenarios/junkyard_middle.png"),
		"terrain_texture": preload("res://assets/art/generated/scenarios/junkyard_terrain.png"),
		"scenery_style": &"overgrown_scrap",
		"terrain_regions": [Rect2(0,64,1254,64),Rect2(0,480,1254,240),Rect2(0,789,1254,180),Rect2(0,1046,1254,174)],
		"platform_depths": Vector2(84,78),
		"background_shade": Color(0.025,0.035,0.045,0.38),
		"platforms": ScrapyardLayout.ISLANDS,
		"enemies": [], "patrols": [],
		"checkpoints": [Vector2(100,476),Vector2(1570,556),Vector2(3070,626),Vector2(4470,496),Vector2(6270,496),Vector2(7870,536)],
		"spikes": [], "beams": [], "bridges": [], "ramps": [],
		"exit": Vector2(9400,320), "gate": Rect2(365,-100,14,1000),
		"secret": "出生地 · 捡到地脉提取器。E 学二段跳，每次空中追加跳跃 +5 kg CO₂。",
		"mineral_nodes": [], "dark_walls": [],
	},
	&"toxic_mine": {
		"title": "毒雾矿坑", "subtitle": "THE TOXIC MINE PIT", "width": 4080.0, "height": 960.0,
		"accent": Color(0.74,0.72,0.87), "row": 2, "ability": &"mineralization",
		"enemy": "crystal_miner", "background": "mine", "source": Vector2(530,590),
		"background_texture": preload("res://assets/art/originals/scenarios/Scenario2.jpg"),
		"middle_background": preload("res://assets/art/generated/scenarios/mine_middle.png"),
		"terrain_texture": preload("res://assets/art/generated/scenarios/mine_terrain.png"),
		"scenery_style": &"timber_pit",
		"terrain_regions": [Rect2(0,69,1254,64),Rect2(0,320,1254,300),Rect2(0,628,1254,282),Rect2(0,941,1254,150)],
		"platform_depths": Vector2(100,54),
		"background_shade": Color(0.035,0.03,0.07,0.12),
		"platforms": [Rect2(0,620,1200,340),Rect2(1440,620,1160,340),Rect2(2760,500,1320,460),
			Rect2(330,460,220,28),Rect2(650,340,220,28),Rect2(1080,460,180,28),
			Rect2(1750,380,250,28),Rect2(2290,480,180,28),Rect2(3040,350,280,28)],
		"enemies": [Vector2(790,596),Vector2(1550,596),Vector2(2360,596),Vector2(2980,476),Vector2(3160,326),Vector2(3700,476)],
		"patrols": [Vector2(650,1050),Vector2(1470,1670),Vector2(2260,2500),Vector2(2800,3000),Vector2(3070,3290),Vector2(3520,3900)],
		"checkpoints": [Vector2(140,596),Vector2(1640,596),Vector2(2860,476)],
		"spikes": [Rect2(940,598,90,22),Rect2(3380,478,90,22)],
		"beams": [Rect2(1780,420,90,200),Rect2(2070,420,90,200)],
		"bridges": [Rect2(1200,620,240,80)],
		"ramps": [PackedVector2Array([Vector2(2600,620),Vector2(2760,500),Vector2(2760,960),Vector2(2600,960)])],
		"exit": Vector2(3990,450), "gate": Rect2(1730,340,18,280),
		"secret": "解谜：I 晶桥 → II 上游毒源 → III 下游毒源。按 C 矿化，集齐三个封印打开净化门。",
		"mineral_nodes": [
			{"point":Vector2(1150,590),"bridge":Rect2(1200,620,240,40),"hazard":-1},
			{"point":Vector2(1710,590),"bridge":Rect2(1780,620,90,32),"hazard":0},
			{"point":Vector2(2010,590),"bridge":Rect2(2070,620,90,32),"hazard":1},
		], "dark_walls": [],
	},
	&"eden_garden": {
		"title": "伊甸城", "subtitle": "EDEN CITY · THE TEN PERCENT", "width": 4400.0, "height": 1080.0,
		"accent": Color(0.79,0.86,0.51), "row": 0, "ability": &"shield",
		"enemy": "forest_crawler", "background": "eden_garden", "source": Vector2(420,590),
		"background_texture": preload("res://assets/art/originals/scenarios/Scenario3.jpeg"),
		"middle_background": preload("res://assets/art/generated/scenarios/eden_middle.png"),
		"terrain_texture": preload("res://assets/art/generated/scenarios/eden_terrain.png"),
		"terrain_regions": [Rect2(0,171,1254,64),Rect2(18,410,1218,204),Rect2(0,726,1254,260),Rect2(12,1050,1230,150)],
		"platform_depths": Vector2(110,58),
		"scenery_style": &"eden_terrace",
		"background_shade": Color(0.025,0.07,0.05,0.09),
		"platforms": [Rect2(0,620,1000,460),Rect2(1280,620,920,460),Rect2(2200,820,700,260),Rect2(2900,620,1500,460),
			Rect2(700,460,210,28),Rect2(1030,480,180,28),Rect2(1700,390,200,28),
			Rect2(2200,650,200,28),Rect2(2460,520,200,28),Rect2(2740,420,250,28),Rect2(3200,470,220,28)],
		"enemies": [Vector2(760,596),Vector2(1440,596),Vector2(1800,366),Vector2(2540,796),Vector2(3260,446)],
		"patrols": [Vector2(650,920),Vector2(1320,1500),Vector2(1730,1860),Vector2(2310,2780),Vector2(3230,3390)],
		"checkpoints": [Vector2(140,596),Vector2(1360,596),Vector2(3050,596),Vector2(3700,596)],
		"spikes": [Rect2(1980,598,100,22),Rect2(2600,798,100,22)],
		"beams": [Rect2(1580,320,180,300),Rect2(1880,320,180,300)],
		"bridges": [Rect2(1000,620,280,80),Rect2(2200,620,700,60)], "ramps": [],
		"exit": Vector2(4320,570), "gate": Rect2(1540,300,18,320),
		"boss": Vector2(3890,576), "secret": "E 学盾（Q +20 kg）与黑穿（F +200 kg）。这 10% 净土的代价流向哪里？",
		"secondary_source": Vector2(1340,590), "secondary_ability": &"black_pierce",
		"mineral_nodes": [], "dark_walls": [Rect2(3500,140,28,480)],
	},
}


static func definition(id: StringName) -> Dictionary:
	var key: StringName = ALIASES.get(id,id)
	var result: Dictionary=DATA.get(key,DATA[&"junkyard_start"]).duplicate(true)
	for field in ["title","secret"]: result[field]=GameText.t(result[field])
	return result


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
