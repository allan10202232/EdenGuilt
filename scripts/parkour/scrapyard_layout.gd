class_name ScrapyardLayout
extends RefCounted
## Top-centred coordinates. Only the six checkpoint islands are permanent ground.

const LENGTH := 9600.0
const SECTIONS := [
	{"name":"Entrance Collapse Run", "zh":"入口坍塌冲刺", "start":0, "end":1500, "spawn":Vector2(100,476), "tip":"Jump again in the air to recover or skip a ledge.", "hint":"空中再跳一次：救回失误，或跨过下一块塌台。"},
	{"name":"Conveyor Belt Precision", "zh":"传送带精准跳跃", "start":1500, "end":3000, "spawn":Vector2(1570,556), "tip":"Jump out of the reverse belt. Watch amber scrap-drop lines.", "hint":"起跳脱离逆向传送带，留意橙色落物预警线。"},
	{"name":"Unstable Junk Tower", "zh":"不稳定废料高塔", "start":3000, "end":4400, "spawn":Vector2(3070,626), "tip":"Jump, air jump, land, repeat. Each tier crumbles in 0.6 s.", "hint":"起跳、二段跳、落地、立刻再跳。废料承重仅 0.6 秒。"},
	{"name":"Magnet Crane Traversal", "zh":"磁力吊机双路线", "start":4400, "end":6200, "spawn":Vector2(4470,496), "tip":"Ride the first magnet UP. The high route hides recovered biochar.", "hint":"乘第一台磁铁上升。高处路线藏着回收生物炭奖励。"},
	{"name":"Crusher Precision Section", "zh":"液压机滞空穿越", "start":6200, "end":7800, "spawn":Vector2(6270,496), "tip":"Red / steam: slam incoming. Delay the air jump to stay aloft.", "hint":"红光、蒸汽：即将下压。延迟二段跳，在空中等待压机回收。"},
	{"name":"Final Escape Stretch", "zh":"最终逃脱冲刺", "start":7800, "end":9600, "spawn":Vector2(7870,536), "tip":"Keep moving: 0.3 s ledges. Air jump onto the EXIT above.", "hint":"连续起跳：塌台只撑 0.3 秒。最后用二段跳登上高处出口。"},
]
const ISLANDS := [Rect2(0,500,360,36), Rect2(1500,580,190,36), Rect2(3000,650,170,36), Rect2(4400,520,180,36), Rect2(6200,520,200,36), Rect2(7800,560,180,36), Rect2(9320,320,280,36)]
const COLLAPSE := [Vector2(480,540),Vector2(720,600),Vector2(980,560),Vector2(1240,500),Vector2(1460,550)]
const BELTS := [Vector2(1860,580),Vector2(2300,560),Vector2(2740,560)]
const TOWER := [Vector2(3260,510),Vector2(3420,370),Vector2(3260,230),Vector2(3460,180),Vector2(3690,260),Vector2(3930,380),Vector2(4180,470)]
const LIFTS := [Vector2(4780,380),Vector2(5030,520),Vector2(5420,520),Vector2(5670,520),Vector2(6060,520)]
const LOWER := [Vector2(4910,520),Vector2(5230,520),Vector2(5550,520),Vector2(5870,520)]
const UPPER := [Vector2(5020,220),Vector2(5300,210),Vector2(5580,240),Vector2(5860,260)]
const CRUSHER_LEDGES := [Vector2(6550,520),Vector2(6810,520),Vector2(7120,520),Vector2(7380,520),Vector2(7640,550)]
const FINALE := [Vector2(8130,550),Vector2(8320,520),Vector2(8510,490),Vector2(8700,460),Vector2(8890,430),Vector2(9080,400),Vector2(9260,370)]

static func section_at(x: float) -> int:
	for index in range(SECTIONS.size()-1,-1,-1):
		if x >= SECTIONS[index].start: return index
	return 0

static func text(en: String, zh: String) -> String:
	return zh if GameText.language == "zh_CN" else en
