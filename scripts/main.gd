extends Node

@export var level_scene: PackedScene = preload("res://scenes/placeholder_level.tscn")
@export var region_scenes: Dictionary[StringName, PackedScene] = {
	&"grassland": preload("res://scenes/grassland.tscn"),
	&"remnant_sea": preload("res://scenes/remnant_sea.tscn"),
}

@onready var _level_root: Node2D = $LevelRoot
@onready var _menu: Control = $UI/Root/MainMenu
@onready var _hud: Control = $UI/Root/HUD
@onready var _result: Control = $UI/Root/ResultDialog


func _ready() -> void:
	_configure_input()
	GameSession.state_changed.connect(_on_state_changed)
	WorldProgress.scene_requested.connect(_on_scene_requested)
	_on_state_changed(GameSession.state, GameSession.state)


func _on_state_changed(_previous: int, current: int) -> void:
	_menu.visible = current == GameSession.State.MAIN_MENU
	_hud.visible = current != GameSession.State.MAIN_MENU
	_hud.set_interactive(current == GameSession.State.PLAYING)
	_result.hide()
	match current:
		GameSession.State.MAIN_MENU:
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
			_result.present(GameSession.last_result)


func _on_scene_requested(_scene_id: StringName) -> void:
	# Scene exits are Area2D callbacks; replace physics bodies outside that callback.
	_load_level.call_deferred()


func _load_level() -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	_clear_level()
	var packed: PackedScene = region_scenes.get(WorldProgress.current_scene, level_scene)
	WorldProgress.finish_scene_load()
	_level_root.add_child(packed.instantiate())
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()


func _clear_level() -> void:
	for level in _level_root.get_children():
		_level_root.remove_child(level)
		level.queue_free()


func _configure_input() -> void:
	var bindings := {
		&"eden_move_left": [KEY_A, KEY_LEFT],
		&"eden_move_right": [KEY_D, KEY_RIGHT],
		&"eden_jump": [KEY_SPACE],
		&"eden_run": [KEY_SHIFT],
		&"eden_shield": [KEY_Q],
		&"eden_absorb": [KEY_E],
		&"eden_return": [KEY_R],
		&"eden_trial_blade": [KEY_F1],
	}
	for action: StringName in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	if not InputMap.has_action(&"eden_slash"):
		InputMap.add_action(&"eden_slash")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(&"eden_slash", click)
