class_name EdenBlueprint
extends RefCounted
const ENTRY:=Vector2(2190,2378)
const NODES: Array[Dictionary]=[
	{"floor":1,"point":ENTRY,"en":"The Promise","zh":"天堂入口"},
	{"floor":2,"point":Vector2(400,1898),"en":"Mirror Light Corridor","zh":"镜光走廊"},
	{"floor":2,"point":Vector2(1510,1898),"en":"Garden Steward","zh":"净园执事"},
	{"floor":2,"point":Vector2(2240,1898),"en":"Ascension Elevator","zh":"荣升电梯"},
	{"floor":3,"point":Vector2(2220,1298),"en":"Phase Maintenance","zh":"相位维护区"},
	{"floor":3,"point":Vector2(1910,1038),"en":"Oren's Sealed Bay","zh":"奥伦的密封舱"},
	{"floor":3,"point":Vector2(1380,1038),"en":"Dual Energy Lock","zh":"双重能源锁"},
	{"floor":3,"point":Vector2(210,1298),"en":"Toxic Gas Ascent","zh":"毒雾竖井"},
	{"floor":4,"point":Vector2(560,598),"en":"Eden Heart Arena","zh":"生命熔炉"},
	{"floor":4,"point":Vector2(1200,598),"en":"Guardian Protocol","zh":"守护协议"},
	{"floor":4,"point":Vector2(740,598),"en":"Predation Protocol","zh":"掠夺协议"},
	{"floor":4,"point":Vector2(2110,258),"en":"Harvest Protocol","zh":"收割协议"},
]
const DECKS: Array[Rect2]=[
	Rect2(70,2400,2280,42),
	Rect2(130,2280,260,28),Rect2(370,2160,240,28),Rect2(150,2040,250,28),
	Rect2(70,1920,2280,38),
	Rect2(2200,1780,150,28),
	Rect2(400,1320,1950,32),Rect2(70,1320,270,32),
	Rect2(1900,1200,230,25),Rect2(1700,1080,240,25),Rect2(760,1060,1300,32),
	Rect2(460,1190,220,28),Rect2(530,1070,180,28),
	Rect2(470,620,1880,40),Rect2(640,480,180,26),Rect2(1450,490,170,26),
	Rect2(1910,280,410,32),
]

static func text(en: String,zh: String) -> String:
	return zh if GameText.language=="zh_CN" else en

static func title(index: int) -> String:
	var data: Dictionary=NODES[clampi(index-1,0,11)]
	return "%dF · %02d / 12 · %s"%[data.floor,index,text(data.en,data.zh)]
