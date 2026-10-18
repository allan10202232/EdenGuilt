extends Control


func _ready() -> void:
	GameSession.health_changed.connect(_update_health)
	GameSession.score_changed.connect(_update_score)
	SoundManager.mute_changed.connect(_update_sound)
	WorldProgress.abilities_changed.connect(_update_progress)
	WorldProgress.world_changed.connect(_update_progress)
	WorldProgress.checkpoint_changed.connect(_update_progress)
	WorldProgress.enemy_defeated.connect(func(_id: StringName) -> void: _update_progress())
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
	var ids: Array = [&"double_jump", &"mineralization", &"shield", &"black_pierce"] if WorldProgress.campaign_rules else [&"double_jump", &"dash", &"shield", &"light_blade"]
	for index in ids.size():
		var id: StringName = ids[index]
		var definition := AbilityCatalog.definition(id)
		var status := "未获得"
		match WorldProgress.ability_state(id):
			WorldProgress.AbilityState.BORROWED:
				status = "可用"
			WorldProgress.AbilityState.RETURNED:
				status = "已交还"
		if id == &"shield" and WorldProgress.shield_active:
			status = "防御中"
		labels[index].text = "%s [%s]  %s" % [definition.name, definition.key, status]
		labels[index].modulate = Color(0.65, 0.88, 0.7) if WorldProgress.has_ability(id) else Color(0.6, 0.67, 0.65)
	var land_names := {&"intact": "完整", &"wasted": "荒芜", &"restored": "通路已恢复"}
	%RegionLabel.text = "%s · %s   |   土地：%s   |   检查点：%s" % [
		AbilityCatalog.region_name(WorldProgress.current_scene), "返程" if WorldProgress.returning else "去程",
		land_names[WorldProgress.land_state(WorldProgress.current_scene)], WorldProgress.checkpoint_name(),
	]
	if WorldProgress.campaign_rules:
		%Notice.offset_top=258.0
		%Notice.offset_bottom=302.0
		$Hint.offset_top=232.0
		$Hint.offset_bottom=254.0
		$Hint.text=_campaign_objective()
		$Hint.show()


func _campaign_objective() -> String:
	var region:=WorldProgress.current_scene
	if WorldProgress.core_reversed:
		if region==&"remnant_sea":
			if not WorldProgress.repaired_regions.has(region):
				return "目标 ← 档案门口 R 与居民共建通路，再回两处能力源卸下能力。"
			if WorldProgress.has_ability(&"black_pierce"):
				return "目标 ← 紫色能力源 R 卸下黑穿；伊甸园有两处能力源。"
			if WorldProgress.has_ability(&"shield"):
				return "目标 ← 绿色能力源 R 卸下护盾，再从本关左端返回矿场。"
			return "目标 ← 两种能力已卸下，从左端返回毒雾矿场。"
		if region==&"grassland":
			return "目标 ← 回到矿场能力源按 R 修复并卸下碳矿化。" if WorldProgress.has_ability(&"mineralization") else "目标 ← 矿场已修复，从左端返回垃圾场。"
		return "目标 ← 回出生地能力源按 R 修复并卸下二段跳。" if WorldProgress.has_ability(&"double_jump") else "目标 ← 四种能力已卸下，继续向左回家。"
	if region==&"lone_tree":
		return "目标 → 穿过断崖前往矿场；空格可二段跳。" if WorldProgress.has_ability(&"double_jump") else "目标 → 靠近绿色能力源，按 E 学习二段跳。"
	if region==&"grassland":
		return "目标 → C 固化毒雾节点、生成晶桥，前往伊甸园。" if WorldProgress.has_ability(&"mineralization") else "目标 → 靠近矿场能力源，按 E 学习碳矿化。"
	if not WorldProgress.has_ability(&"shield"):
		return "目标 → 绿色能力源 E 学护盾（Q），向右探索伊甸园。"
	if not WorldProgress.has_ability(&"black_pierce"):
		return "目标 → 紫色能力源 E 学黑穿（F），用于穿过紫色暗壁。"
	return "目标 → 守卫已倒下，进入最右侧档案揭开真相。" if WorldProgress.is_enemy_defeated(&"remnant_sea/boss") else "目标 → F 穿暗壁，击败右侧伊甸守卫，进入真相档案。"


func _update_health(current: int, maximum: int) -> void:
	%LifeOrbs.set_health(current, maximum)


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
