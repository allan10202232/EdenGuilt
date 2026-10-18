extends Control


func _ready() -> void:
	%StartButton.pressed.connect(_start)
	%MuteButton.pressed.connect(_toggle_sound)
	%CombatDemoButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/combat/melee_demo.tscn")
	)
	SoundManager.mute_changed.connect(_update_sound)
	_update_sound(SoundManager.muted)


func focus_default() -> void:
	%StartButton.grab_focus()


func _start() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	GameSession.start_run()


func _toggle_sound() -> void:
	SoundManager.set_muted(not SoundManager.muted)
	SoundManager.play_sfx(&"ui_confirm")


func _update_sound(muted: bool) -> void:
	%MuteButton.text = "声音：关闭" if muted else "声音：开启"
