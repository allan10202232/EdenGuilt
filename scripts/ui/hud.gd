extends Control

var _notice_seconds: float = 0.0


func _ready() -> void:
	GameSession.health_changed.connect(_update_health)
	GameSession.score_changed.connect(_update_score)
	SoundManager.mute_changed.connect(_update_sound)
	WorldProgress.abilities_changed.connect(_update_progress)
	WorldProgress.world_changed.connect(_update_progress)
	WorldProgress.checkpoint_changed.connect(_update_progress)
	WorldProgress.enemy_defeated.connect(func(_id: StringName) -> void: _update_progress())
	WorldProgress.shield_changed.connect(func(_active: bool) -> void: _update_progress())
	WorldProgress.notice_changed.connect(_show_notice)
	$Top/Panel.add_theme_stylebox_override(&"panel", GothicSkin.panel(0, 14))
	$Abilities.add_theme_stylebox_override(&"panel", GothicSkin.panel(0, 14))
	$Hint.add_theme_stylebox_override(&"normal", GothicSkin.panel(0, 10))
	%Notice.add_theme_stylebox_override(&"normal", GothicSkin.panel(0, 10))
	%MenuButton.pressed.connect(_back_to_menu)
	%MuteButton.pressed.connect(func() -> void: SoundManager.set_muted(not SoundManager.muted))
	_update_health(GameSession.health, GameSession.max_health)
	_update_score(GameSession.score)
	_update_sound(SoundManager.muted)
	_update_progress()
	_show_notice(WorldProgress.notice)
	GameText.language_changed.connect(func() -> void:
		_update_progress()
		_update_health(GameSession.health,GameSession.max_health)
		_update_score(GameSession.score)
		_update_sound(SoundManager.muted)
		%Notice.text=GameText.t(WorldProgress.notice)
	)


func _show_notice(text: String) -> void:
	%Notice.text = text
	_notice_seconds = 9.0
	%Notice.modulate.a = 1.0


func _process(delta: float) -> void:
	_notice_seconds = maxf(0.0, _notice_seconds-delta)
	%Notice.modulate.a = minf(1.0, _notice_seconds)


func _update_progress() -> void:
	# The first chapter uses this space for its six-section parkour status panel.
	var parkour := WorldProgress.campaign_rules and WorldProgress.current_scene == &"lone_tree"
	$CarbonDashboard.visible = not parkour
	$Abilities.visible = not parkour
	$RouteMap.visible = not parkour
	%Notice.anchor_top = 1.0 if parkour else 0.0
	%Notice.anchor_bottom = 1.0 if parkour else 0.0
	%Notice.offset_left = -540 if parkour else -310
	%Notice.offset_top = -108 if parkour else 275
	%Notice.offset_bottom = -24 if parkour else 385
	var labels: Array[Label] = [%DoubleJump, %Dash, %Shield, %LightBlade]
	var ids: Array = [&"double_jump", &"mineralization", &"shield", &"black_pierce"] if WorldProgress.campaign_rules else [&"double_jump", &"dash", &"shield", &"light_blade"]
	for index in ids.size():
		var id: StringName = ids[index]
		var definition := AbilityCatalog.definition(id)
		var status := GameText.t("未获得")
		match WorldProgress.ability_state(id):
			WorldProgress.AbilityState.BORROWED:
				status = GameText.t("可用")
			WorldProgress.AbilityState.RETURNED:
				status = GameText.t("已交还")
		if id == &"shield" and WorldProgress.shield_active:
			status = GameText.t("防御中")
		labels[index].text = "%s [%s]  %s" % [definition.name, definition.key, status]
		labels[index].modulate = GothicSkin.IVORY if WorldProgress.has_ability(id) else GothicSkin.MUTED
		labels[index].add_theme_stylebox_override(&"normal", GothicSkin.panel(3 if WorldProgress.has_ability(id) else 0, 8))
	var land_names := {&"intact": GameText.t("完整"), &"wasted": GameText.t("荒芜"), &"restored": GameText.t("通路已恢复")}
	%RegionLabel.text = GameText.t("%s · %s   |   土地：%s   |   检查点：%s") % [
		AbilityCatalog.region_name(WorldProgress.current_scene), GameText.t("返程") if WorldProgress.returning else GameText.t("去程"),
		land_names[WorldProgress.land_state(WorldProgress.current_scene)], WorldProgress.checkpoint_name(),
	]
	if WorldProgress.campaign_rules:
		$Hint.text=_campaign_objective()
		$Hint.visible = not parkour


func _campaign_objective() -> String:
	var region:=WorldProgress.current_scene
	if WorldProgress.core_reversed:
		if region==&"remnant_sea":
			if not WorldProgress.repaired_regions.has(region):
				return GameText.t("目标 ← 档案门口 R 与居民共建通路，再回两处能力源卸下能力。")
			if WorldProgress.has_ability(&"black_pierce"):
				return GameText.t("目标 ← 紫色能力源 R 卸下黑穿；伊甸城有两处能力源。")
			if WorldProgress.has_ability(&"shield"):
				return GameText.t("目标 ← 绿色能力源 R 卸下护盾，再从本关左端返回矿洞。")
			return GameText.t("目标 ← 两种能力已卸下，从左端返回毒雾矿坑。")
		if region==&"grassland":
			return GameText.t("目标 ← 回到矿洞能力源按 R 修复并卸下碳矿化。") if WorldProgress.has_ability(&"mineralization") else GameText.t("目标 ← 矿洞已修复，从左端返回垃圾场。")
		return GameText.t("目标 ← 回出生地能力源按 R 修复并卸下二段跳。") if WorldProgress.has_ability(&"double_jump") else GameText.t("目标 ← 四种能力已卸下，继续向左回家。")
	if region==&"lone_tree":
		return ScrapyardLayout.text("Goal → Cross six scrapyard sections to the mine. Space twice: air jump.", "目标 → 穿过六段废料跑酷区前往矿洞，空中再按空格可二段跳。") if WorldProgress.has_ability(&"double_jump") else GameText.t("目标 → 靠近绿色能力源，按 E 学习二段跳。")
	if region==&"grassland":
		return GameText.t("目标 → 按 I、II、III 的顺序用 C 固化三个节点，打开净化门。") if WorldProgress.has_ability(&"mineralization") else GameText.t("目标 → 靠近矿洞能力源，按 E 学习碳矿化。")
	if not WorldProgress.has_ability(&"shield"):
		return GameText.t("目标 → 绿色能力源 E 学护盾（Q），向右探索伊甸城。")
	if not WorldProgress.has_ability(&"black_pierce"):
		return GameText.t("目标 → 紫色能力源 E 学黑穿（F），用于穿过紫色暗壁。")
	return GameText.t("目标 → 守卫已倒下，进入最右侧档案揭开真相。") if WorldProgress.is_enemy_defeated(&"remnant_sea/boss") else GameText.t("目标 → F 穿暗壁，击败右侧伊甸守卫，进入真相档案。")


func _update_health(current: int, maximum: int) -> void:
	%LifeOrbs.set_health(current, maximum)


func _update_score(value: int) -> void:
	%ScoreLabel.text = GameText.t("得分  %04d") % value


func _update_sound(muted: bool) -> void:
	%MuteButton.text = GameText.t("声音：关闭") if muted else GameText.t("声音：开启")


func _back_to_menu() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	GameSession.return_to_menu()


func set_interactive(enabled: bool) -> void:
	# Keep the result modal exclusive to both pointer and keyboard navigation.
	for button: Button in [%MenuButton, %MuteButton]:
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
