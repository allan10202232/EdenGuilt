extends Node

@export var campaign_mode: bool = true
const CAMPAIGN_SCENES: Dictionary = {
	&"lone_tree": preload("res://scenes/campaign/junkyard_start.tscn"),
	&"grassland": preload("res://scenes/campaign/toxic_mine.tscn"),
	&"remnant_sea": preload("res://scenes/campaign/eden_city.tscn"),
}
@export var mine_scene: PackedScene = preload("res://scenes/campaign/toxic_mine.tscn")
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


func _ready() -> void:
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


func _on_state_changed(_previous: int, current: int) -> void:
	_menu.visible = current == GameSession.State.MAIN_MENU
	_hud.visible = current != GameSession.State.MAIN_MENU
	_hud.set_interactive(current == GameSession.State.PLAYING)
	_result.hide()
	_truth.hide()
	_audit.hide()
	match current:
		GameSession.State.MAIN_MENU:
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
	# Scene exits are Area2D callbacks; replace physics bodies outside that callback.
	_load_level.call_deferred()


func _load_level() -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	_clear_level()
	var packed: PackedScene = region_scenes.get(WorldProgress.current_scene, level_scene)
	if campaign_mode:
		packed = mine_scene if WorldProgress.current_scene==&"grassland" else CAMPAIGN_SCENES[WorldProgress.current_scene]
	WorldProgress.finish_scene_load()
	var active_level := packed.instantiate()
	_level_root.add_child(active_level)
	_hud.visible = not active_level.get_meta(&"custom_hud",false)
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()


func _clear_level() -> void:
	for level in _level_root.get_children():
		_level_root.remove_child(level)
		level.queue_free()
