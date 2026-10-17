extends Control


func _ready() -> void:
	GameSession.health_changed.connect(_update_health)
	GameSession.score_changed.connect(_update_score)
	SoundManager.mute_changed.connect(_update_sound)
	WorldProgress.abilities_changed.connect(_update_progress)
	WorldProgress.world_changed.connect(_update_progress)
	WorldProgress.checkpoint_changed.connect(_update_progress)
	WorldProgress.shield_changed.connect(func(_active: bool) -> void: _update_progress())
	WorldProgress.notice_changed.connect(func(text: String) -> void: %Notice.text = text)
	%MenuButton.pressed.connect(_back_to_menu)
	%MuteButton.pressed.connect(func() -> void: SoundManager.set_muted(not SoundManager.muted))
	_update_health(GameSession.health, GameSession.max_health)
	_update_score(GameSession.score)
	_update_sound(SoundManager.muted)
	_update_progress()
	%Notice.text = WorldProgress.notice


func _update_progress() -> void:
	var labels: Array[Label] = [%DoubleJump, %Dash, %Shield, %LightBlade]
	for index in AbilityCatalog.IDS.size():
		var id := AbilityCatalog.IDS[index]
		var definition := AbilityCatalog.definition(id)
		var status := "未获得"
		match WorldProgress.ability_state(id):
			WorldProgress.AbilityState.BORROWED:
				status = "可用"
			WorldProgress.AbilityState.RETURNED:
				status = "已交还"
		if id == &"shield" and WorldProgress.shield_active:
			status = "防御中"
		labels[index].text = "%s [%s]\n%s" % [definition.name, definition.key, status]
		labels[index].modulate = Color(0.65, 0.88, 0.7) if WorldProgress.has_ability(id) else Color(0.6, 0.67, 0.65)
	var land_names := {&"intact": "完整", &"wasted": "荒芜", &"restored": "通路已恢复"}
	%RegionLabel.text = "%s · %s   |   土地：%s   |   检查点：%s" % [
		AbilityCatalog.region_name(WorldProgress.current_scene), "返程" if WorldProgress.returning else "去程",
		land_names[WorldProgress.land_state(WorldProgress.current_scene)], WorldProgress.checkpoint_name(),
	]


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
