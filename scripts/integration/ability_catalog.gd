class_name AbilityCatalog
extends RefCounted
## Canonical IDs and display text from Rules and Ability. Tuning belongs to gameplay.

const IDS: Array[StringName] = [&"double_jump", &"dash", &"shield", &"light_blade"]
const REGIONS: Array[StringName] = [&"lone_tree", &"grassland", &"remnant_sea"]
const DEFINITIONS: Dictionary = {
	&"double_jump": {"name": "二段跳", "region": &"lone_tree", "key": "空格", "route": "枝干搭桥，让伙伴回家", "sound": &"double_jump"},
	&"dash": {"name": "冲刺", "region": &"grassland", "key": "Shift", "route": "根系顶开残骸，形成步行通道", "sound": &"dash"},
	&"shield": {"name": "护盾", "region": &"remnant_sea", "key": "Q", "route": "关闭矿厂危险喷口，修复伙伴通路", "sound": &"shield"},
	&"light_blade": {"name": "光刃", "region": &"", "key": "左短 / 右长", "route": "地点待定；交还前必须确认撤离通路", "sound": &"slash"},
}
const REGION_NAMES: Dictionary = {&"lone_tree": "森林", &"grassland": "垃圾场", &"remnant_sea": "矿厂"}


static func definition(id: StringName) -> Dictionary:
	return DEFINITIONS.get(id, {}).duplicate(true)


static func region_name(id: StringName) -> String:
	return REGION_NAMES.get(id, String(id))
