extends Control


func _ready() -> void:
	GameSession.health_changed.connect(_update_health)
	GameSession.score_changed.connect(_update_score)
	SoundManager.mute_changed.connect(_update_sound)
	%MenuButton.pressed.connect(_back_to_menu)
	%MuteButton.pressed.connect(func() -> void: SoundManager.set_muted(not SoundManager.muted))
	_update_health(GameSession.health, GameSession.max_health)
	_update_score(GameSession.score)
	_update_sound(SoundManager.muted)


func _update_health(current: int, maximum: int) -> void:
	%HealthBar.max_value = maximum
	%HealthBar.value = current
	%HealthLabel.text = "生命  %d / %d" % [current, maximum]


func _update_score(value: int) -> void:
	%ScoreLabel.text = "得分  %04d" % value


func _update_sound(muted: bool) -> void:
	%MuteButton.text = "声音：关闭" if muted else "声音：开启"


func _back_to_menu() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	GameSession.return_to_menu()


func set_interactive(enabled: bool) -> void:
	# Keep the result modal exclusive to both pointer and keyboard navigation.
	for button: Button in [%MenuButton, %MuteButton]:
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
