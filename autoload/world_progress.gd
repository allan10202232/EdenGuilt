extends Node
## Run-scoped world/ability state, shared by A's gameplay and B's presentation.
## Death preserves progress; starting a NEW RUN resets it. No disk save is implied.

signal abilities_changed
signal ability_absorbed(id: StringName)
signal ability_returned(id: StringName)
signal ability_used(id: StringName)
signal shield_changed(active: bool)
signal world_changed
signal checkpoint_changed
signal scene_requested(scene_id: StringName)
signal enemy_defeated(id: StringName)
signal notice_changed(text: String)

enum AbilityState { UNAVAILABLE, BORROWED, RETURNED }

var current_scene: StringName = &"lone_tree"
var spawn_position := Vector2(100, 560)
var returning: bool = false
var shield_active: bool = false
var transitioning: bool = false
var notice: String = "靠近能力源按 E 吸收，返程在原处按 R 交还。"
var _abilities: Dictionary = {}
var _lands: Dictionary = {}
var _routes: Dictionary = {}
var _defeated: Dictionary = {}
var _collected: Dictionary = {}
var _checkpoint: Dictionary = {}
var _light_blade_escape_ready: bool = false


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	current_scene = &"lone_tree"
	spawn_position = Vector2(100, 560)
	returning = false
	shield_active = false
	transitioning = false
	_abilities.clear()
	_lands.clear()
	_routes.clear()
	_defeated.clear()
	_collected.clear()
	_light_blade_escape_ready = false
	for id in AbilityCatalog.IDS:
		_abilities[id] = AbilityState.UNAVAILABLE
	for region in AbilityCatalog.REGIONS:
		_lands[region] = &"intact"
	_checkpoint = {"scene": current_scene, "position": spawn_position}
	set_notice("靠近能力源按 E 吸收，返程在原处按 R 交还。")
	abilities_changed.emit()
	shield_changed.emit(false)
	world_changed.emit()
	checkpoint_changed.emit()


func ability_state(id: StringName) -> AbilityState:
	return _abilities.get(id, AbilityState.UNAVAILABLE)


func has_ability(id: StringName) -> bool:
	return ability_state(id) == AbilityState.BORROWED


func borrow_ability(id: StringName) -> bool:
	if not can_play() or not AbilityCatalog.IDS.has(id) or ability_state(id) != AbilityState.UNAVAILABLE:
		return false
	var region: StringName = AbilityCatalog.DEFINITIONS[id].region
	if region != &"" and region != current_scene:
		return false
	_abilities[id] = AbilityState.BORROWED
	if region != &"":
		_lands[region] = &"wasted"
	set_notice("吸收%s；%s" % [AbilityCatalog.DEFINITIONS[id].name,
		"土地已荒芜，返程请在原处交还。" if region != &"" else "光刃地点仍待设计确定（当前为接口试用）。"])
	abilities_changed.emit()
	world_changed.emit()
	ability_absorbed.emit(id)
	return true


func return_ability(id: StringName) -> bool:
	if not can_play() or not has_ability(id):
		return false
	var definition := AbilityCatalog.definition(id)
	var region: StringName = definition.region
	if region != &"" and region != current_scene:
		set_notice("请回到%s交还%s。" % [AbilityCatalog.region_name(region), definition.name])
		return false
	if id == &"light_blade" and not _light_blade_escape_ready:
		set_notice("光刃交还被阻止：关卡尚未确认无攻击能力的撤离通路。")
		return false
	# Commit the escape route BEFORE removing the ability, as one state update.
	_routes[id] = true
	_abilities[id] = AbilityState.RETURNED
	if region != &"":
		_lands[region] = &"restored"
	if id == &"shield":
		set_shield_active(false)
	set_notice("已交还%s：%s" % [definition.name, definition.route])
	abilities_changed.emit()
	world_changed.emit()
	ability_returned.emit(id)
	return true


func set_light_blade_escape_ready(ready: bool) -> void:
	# The level designer/A must confirm this; never assume it from losing the weapon.
	if can_play():
		_light_blade_escape_ready = ready


func route_open(id: StringName) -> bool:
	return _routes.get(id, false)


func land_state(region: StringName) -> StringName:
	return _lands.get(region, &"intact")


func report_ability_used(id: StringName) -> bool:
	if not can_play() or not has_ability(id):
		return false
	ability_used.emit(id)
	return true


func set_shield_active(active: bool) -> void:
	var next := active and can_play() and has_ability(&"shield")
	if shield_active != next:
		shield_active = next
		shield_changed.emit(next)


func enter_scene(scene_id: StringName, at_position: Vector2) -> bool:
	if not can_play() or not AbilityCatalog.REGIONS.has(scene_id) or scene_id == current_scene:
		return false
	transitioning = true
	set_shield_active(false)
	current_scene = scene_id
	spawn_position = at_position
	_checkpoint = {"scene": scene_id, "position": at_position}
	set_notice("进入%s，检查点已更新。" % AbilityCatalog.region_name(scene_id))
	checkpoint_changed.emit()
	world_changed.emit()
	scene_requested.emit(scene_id)
	return true


func finish_scene_load() -> void:
	transitioning = false


func restore_checkpoint() -> bool:
	if _checkpoint.is_empty():
		return false
	current_scene = _checkpoint.scene
	spawn_position = _checkpoint.position
	transitioning = false
	set_shield_active(false)
	set_notice("已返回%s检查点；本局能力、交还状态和已击败怪物均保留。" % checkpoint_name())
	checkpoint_changed.emit()
	world_changed.emit()
	return true


func checkpoint_name() -> String:
	return String(_checkpoint.get("label",AbilityCatalog.region_name(_checkpoint.get("scene", &"lone_tree"))))


func set_checkpoint(id: StringName, position: Vector2, label: String) -> bool:
	if not can_play() or _checkpoint.get("id",&"") == id:
		return false
	_checkpoint = {"scene": current_scene,"position": position,"id": id,"label": label}
	set_notice("检查点已点亮：%s" % label)
	checkpoint_changed.emit()
	return true


func begin_return_journey() -> void:
	if not can_play() or returning:
		return
	returning = true
	set_notice("伙伴已获救。返回矿厂、垃圾场、森林交还能力，带他们回家。")
	world_changed.emit()


func required_returns_complete() -> bool:
	for id: StringName in [&"double_jump", &"dash", &"shield"]:
		if ability_state(id) != AbilityState.RETURNED:
			return false
	return true


func mark_enemy_defeated(id: StringName) -> bool:
	if not can_play() or id == &"" or _defeated.has(id):
		return false
	_defeated[id] = true
	enemy_defeated.emit(id)
	return true


func is_enemy_defeated(id: StringName) -> bool:
	return _defeated.has(id)


func collect_once(id: StringName) -> bool:
	if not can_play() or id == &"" or _collected.has(id):
		return false
	_collected[id] = true
	return true


func is_collected(id: StringName) -> bool:
	return _collected.has(id)


func can_play() -> bool:
	return GameSession.state == GameSession.State.PLAYING and not transitioning


func set_notice(text: String) -> void:
	notice = text
	notice_changed.emit(text)
