extends Node

@export var level_scene: PackedScene = preload("res://scenes/placeholder_level.tscn")

@onready var _level_root: Node2D = $LevelRoot
@onready var _menu: Control = $UI/Root/MainMenu
@onready var _hud: Control = $UI/Root/HUD
@onready var _result: Control = $UI/Root/ResultDialog


func _ready() -> void:
	_configure_input()
	GameSession.state_changed.connect(_on_state_changed)
	_on_state_changed(GameSession.state, GameSession.state)


func _on_state_changed(_previous: int, current: int) -> void:
	_menu.visible = current == GameSession.State.MAIN_MENU
	_hud.visible = current != GameSession.State.MAIN_MENU
	_hud.set_interactive(current == GameSession.State.PLAYING)
	_result.hide()
	match current:
		GameSession.State.MAIN_MENU:
			_clear_level()
			SoundManager.stop_sfx()
			_menu.focus_default()
		GameSession.State.PLAYING:
			_clear_level()
			var level := level_scene.instantiate()
			_level_root.add_child(level)
			# Gameplay focus must not remain on an invisible menu button.
			var focus := get_viewport().gui_get_focus_owner()
			if focus != null:
				focus.release_focus()
		GameSession.State.GAME_OVER, GameSession.State.VICTORY:
			for level in _level_root.get_children():
				# Terminal events can originate inside Area2D's physics callback.
				level.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
			SoundManager.stop_sfx()
			SoundManager.play_sfx(&"victory" if current == GameSession.State.VICTORY else &"game_over")
			_result.present(GameSession.last_result)


func _clear_level() -> void:
	for level in _level_root.get_children():
		_level_root.remove_child(level)
		level.queue_free()


func _configure_input() -> void:
	var bindings := {
		&"eden_move_left": [KEY_A, KEY_LEFT],
		&"eden_move_right": [KEY_D, KEY_RIGHT],
		&"eden_jump": [KEY_SPACE, KEY_W, KEY_UP],
	}
	for action: StringName in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
