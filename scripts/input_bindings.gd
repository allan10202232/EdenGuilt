class_name EdenInputBindings
extends RefCounted


static func configure() -> void:
	var bindings := {
		&"eden_move_left": [KEY_A, KEY_LEFT], &"eden_move_right": [KEY_D, KEY_RIGHT],
		&"eden_jump": [KEY_SPACE], &"eden_run": [KEY_SHIFT], &"eden_shield": [KEY_Q],
		&"eden_absorb": [KEY_E], &"eden_return": [KEY_R], &"eden_trial_blade": [KEY_F1],
		&"eden_mineralize": [KEY_C], &"eden_black_pierce": [KEY_F], &"eden_recycle": [KEY_V],
	}
	for action: StringName in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	for action: StringName in [&"eden_slash", &"eden_reach_slash"]:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT if action == &"eden_slash" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, event)
