extends Node
## Explicit presentation mode: all jumps use the existing fade and level factory.
const REGIONS: Array[StringName]=[&"lone_tree",&"grassland",&"remnant_sea"]
const PREREQUISITES: Array[StringName]=[&"double_jump",&"mineralization"]
var host: Node

func _ready() -> void:
	add_to_group(&"demo_shortcuts")
	get_window().title="EdenGuilt · Demo Mode"

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if not event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return
	var code: Key=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	var index:=REGIONS.find(WorldProgress.current_scene)
	match code:
		KEY_PAGEDOWN: index+=1
		KEY_PAGEUP: index-=1
		KEY_1: index=0
		KEY_2: index=1
		KEY_3: index=2
		_: return
	if jump_to(index): get_viewport().set_input_as_handled()

func jump_to(index: int) -> bool:
	if index<0 or index>=REGIONS.size() or not WorldProgress.can_play(): return false
	if not is_instance_valid(host) or not host.campaign_mode: return false
	if host.transitions.busy or WorldProgress.transition_rearm_seconds>0: return false
	var direction:=Vector2.LEFT if index<REGIONS.find(WorldProgress.current_scene) else Vector2.RIGHT
	return host.transitions.request(_commit.bind(index),{"entry_direction":direction,"transition_type":"demo"})

func _commit(index: int) -> Node:
	# Run only under the controller's fully black screen. No action emissions,
	# enemy defeats, survivor counts or endings are fabricated by a scene jump.
	host._clear_level()
	for earlier in mini(index,PREREQUISITES.size()):
		WorldProgress.current_scene=REGIONS[earlier]
		if WorldProgress.ability_state(PREREQUISITES[earlier])==WorldProgress.AbilityState.UNAVAILABLE:
			WorldProgress.borrow_ability(PREREQUISITES[earlier])
	WorldProgress.current_scene=REGIONS[index]
	var entry:=Vector2(100,476)
	match index:
		0:
			if WorldProgress.returning: entry=Vector2(9360,296)
		1:
			entry=Vector2(5340,378) if WorldProgress.returning else Vector2(180,1778)
			if not WorldProgress.returning: WorldProgress.mine_challenge["stage"]=1
		2:
			entry=WorldProgress.eden_chapter.get("checkpoint",EdenBlueprint.ENTRY) if WorldProgress.returning else EdenBlueprint.ENTRY
			if not WorldProgress.returning: WorldProgress.eden_chapter.merge({"node":1,"checkpoint":entry},true)
	WorldProgress.spawn_position=entry
	WorldProgress.set_checkpoint(StringName("demo/chapter/%d"%index),entry,AbilityCatalog.region_name(REGIONS[index]))
	var level: Node=host._load_level()
	WorldProgress.confirm_arrival(level.player.position)
	return level
