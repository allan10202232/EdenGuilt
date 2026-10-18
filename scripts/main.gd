extends Node

@export var campaign_mode: bool = true
@export var demo_shortcuts_enabled:=false
const CAMPAIGN_SCENES: Dictionary = {
	&"lone_tree": preload("res://scenes/campaign/junkyard_start.tscn"),
	&"grassland": preload("res://scenes/campaign/toxic_mine.tscn"),
	&"remnant_sea": preload("res://scenes/eden/eden_chapter.tscn"),
}
@export var mine_scene: PackedScene = preload("res://scenes/campaign/toxic_mine.tscn")
@export var eden_scene: PackedScene = preload("res://scenes/eden/eden_chapter.tscn")
@export var level_scene: PackedScene = preload("res://scenes/placeholder_level.tscn")
@export var region_scenes: Dictionary[StringName, PackedScene] = {
	&"grassland": preload("res://scenes/grassland.tscn"),
	&"remnant_sea": preload("res://scenes/remnant_sea.tscn"),
}

@onready var _level_root: Node2D = $LevelRoot
@onready var _menu: Control = $UI/Root/MainMenu
@onready var _hud: Control = $UI/Root/HUD
@onready var _result: Control = $UI/Root/ResultDialog
var _truth: Control
var _audit: Control
var _dialogue: Control
var transitions: RoomTransitionController
var _loaded_region: StringName=&"lone_tree"
var demo_shortcuts: Node


func _ready() -> void:
	add_to_group(&"scene_transition_host")
	transitions=RoomTransitionController.new()
	add_child(transitions)
	WorldProgress.campaign_rules = campaign_mode
	var climate_layer:=CanvasLayer.new()
	climate_layer.layer=5
	add_child(climate_layer)
	var climate:=preload("res://scripts/ui/climate_overlay.gd").new()
	climate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	climate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	climate_layer.add_child(climate)
	_truth=preload("res://scripts/ui/truth_dialog.gd").new()
	_truth.name="TruthDialog"
	$UI/Root.add_child(_truth)
	_audit=preload("res://scripts/ui/sustainability_report.gd").new()
	_audit.name="SustainabilityReport"
	$UI/Root.add_child(_audit)
	_dialogue=preload("res://scripts/ui/dialogue.gd").new()
	$UI/Root.add_child(_dialogue)
	_menu.start_requested.connect(func() -> void: GameSession.start_run())
	WorldProgress.dialogue_requested.connect(func(speaker: String, lines: Array) -> void:
		_hud.set_interactive(false)
		_dialogue.present(speaker,lines)
	)
	WorldProgress.truth_requested.connect(func() -> void:
		_hud.set_interactive(false)
		_truth.present()
	)
	WorldProgress.world_changed.connect(func() -> void:
		if not WorldProgress.narrative_active:
			_hud.set_interactive(GameSession.state==GameSession.State.PLAYING)
	)
	EdenInputBindings.configure()
	GameSession.state_changed.connect(_on_state_changed)
	WorldProgress.scene_requested.connect(_on_scene_requested)
	_on_state_changed(GameSession.state, GameSession.state)
	if campaign_mode and (demo_shortcuts_enabled or "--demo" in OS.get_cmdline_user_args()):
		demo_shortcuts=preload("res://scripts/demo/chapter_shortcuts.gd").new()
		demo_shortcuts.host=self
		add_child(demo_shortcuts)


func _on_state_changed(_previous: int, current: int) -> void:
	if current!=GameSession.State.PLAYING: transitions.cancel()
	_menu.visible = current == GameSession.State.MAIN_MENU
	_hud.visible = current != GameSession.State.MAIN_MENU
	if _level_root.get_child_count()>0 and _level_root.get_child(0).get_meta(&"custom_hud",false):
		_hud.hide()
	_hud.set_interactive(current == GameSession.State.PLAYING)
	_result.hide()
	_truth.hide()
	_audit.hide()
	match current:
		GameSession.State.MAIN_MENU:
			transitions.clear_history()
			WorldProgress.narrative_active=false
			WorldProgress.narrative_kind=&""
			_dialogue.hide()
			_clear_level()
			WorldProgress.finish_scene_load()
			SoundManager.stop_sfx()
			_menu.focus_default()
		GameSession.State.PLAYING:
			_load_level()
		GameSession.State.GAME_OVER, GameSession.State.VICTORY:
			for level in _level_root.get_children():
				# Terminal events can originate inside Area2D's physics callback.
				level.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
			SoundManager.stop_sfx()
			SoundManager.play_sfx(&"victory" if current == GameSession.State.VICTORY else &"game_over")
			if current==GameSession.State.VICTORY and campaign_mode:
				_audit.present(GameSession.last_result)
			else:
				_result.present(GameSession.last_result)


func _on_scene_requested(_scene_id: StringName) -> void:
	var options:=WorldProgress.pending_transition
	if not options.has("_origin") and _level_root.get_child_count()>0:
		var previous:=_level_root.get_child(0)
		options=transitions.resolve_options(options,previous,previous.scene_file_path,_loaded_region)
	transitions.request(_load_level,options)

func request_room_transition(options: Dictionary) -> bool:
	if transitions.busy or not WorldProgress.can_play(): return false
	if _level_root.get_child_count()==0: return false
	var previous:=_level_root.get_child(0)
	var resolved:=transitions.resolve_options(options,previous,previous.scene_file_path,_loaded_region)
	var region: StringName=resolved.get("target_region",&"")
	if region!=&"" and region!=WorldProgress.current_scene: return WorldProgress.enter_scene(region,Vector2.ZERO,resolved)
	var path: String=resolved.get("target_scene","")
	if path.is_empty() or not ResourceLoader.exists(path): return false
	var packed:=load(path) as PackedScene
	if packed==null: return false
	return transitions.request(func() -> Node:
		_clear_level()
		var room:=packed.instantiate()
		_level_root.add_child(room)
		return room
	,resolved)


func _load_level() -> Node:
	if GameSession.state != GameSession.State.PLAYING:
		return null
	_clear_level()
	var packed: PackedScene = region_scenes.get(WorldProgress.current_scene, level_scene)
	if campaign_mode:
		packed = mine_scene if WorldProgress.current_scene==&"grassland" else CAMPAIGN_SCENES[WorldProgress.current_scene]
		if WorldProgress.current_scene==&"remnant_sea": packed=eden_scene
	WorldProgress.finish_scene_load()
	var active_level := packed.instantiate()
	_level_root.add_child(active_level)
	_loaded_region=WorldProgress.current_scene
	if campaign_mode:
		match WorldProgress.current_scene:
			&"lone_tree": RoomSpawnPoint.install(active_level,&"from_mine",CampaignLevels.definition(&"lone_tree").exit-Vector2(40,24),-1)
			&"grassland":
				var legacy:=active_level is CampaignLevel
				RoomSpawnPoint.install(active_level,&"from_junkyard",Vector2(140,596) if legacy else Vector2(180,1778),1)
				RoomSpawnPoint.install(active_level,&"from_eden",CampaignLevels.definition(&"grassland").exit-Vector2(90,24) if legacy else Vector2(5340,378),-1)
			&"remnant_sea": RoomSpawnPoint.install(active_level,&"from_mine",EdenBlueprint.ENTRY if active_level is EdenChapterLevel else Vector2(140,596),-1)
	_hud.visible = not active_level.get_meta(&"custom_hud",false)
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	return active_level


func _clear_level() -> void:
	for level in _level_root.get_children():
		_level_root.remove_child(level)
		level.queue_free()
