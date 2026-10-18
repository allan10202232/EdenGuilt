extends Control

const FirstUseGuideScript = preload("res://scripts/ui/first_use_guide.gd")
const SettingsPanelScript = preload("res://scripts/ui/settings_panel.gd")

var _notice_seconds: float = 0.0
var _settings: SettingsPanelScript
var _settings_button: Button
var _tutorial: Label
var _tutorial_seconds := 0.0
var _tutorial_source := ""



func _ready() -> void:
	_settings = SettingsPanelScript.new()
	add_child(_settings)
	_settings_button = Button.new()
	_settings_button.text = GameText.t("设置")
	$Top/Panel/Row.add_child(_settings_button)
	_settings_button.pressed.connect(_settings.open)
	_tutorial = Label.new()
	_tutorial.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_tutorial.offset_left = -320
	_tutorial.offset_right = 320
	_tutorial.offset_top = -90
	_tutorial.offset_bottom = -26
	_tutorial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tutorial.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial.add_theme_stylebox_override(&"normal",GothicSkin.panel(0,12))
	_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial.hide()
	add_child(_tutorial)
	$Abilities.hide()
	$RouteMap.hide()
	$Top/Panel/Row/Crest.hide()
	$Top/Panel/Row/Health/HealthLabel.hide()
	%ScoreLabel.hide()
	%MuteButton.hide()
	%MenuButton.hide()
	$Top/Panel/Row/LanguagePicker.hide()
	$Top/Panel.add_theme_stylebox_override(&"panel",StyleBoxEmpty.new())
	$CarbonDashboard.position = Vector2(24,70)
	$CarbonDashboard.size = Vector2(260,54)
	$ToxinStatus.position = Vector2(6,125)
	$ToxinStatus.size = Vector2(285,48)
	$Hint.offset_left = -330
	$Hint.offset_right = -30
	$Hint.offset_top = 75
	$Hint.offset_bottom = 140
	%Notice.offset_left = -330
	%Notice.offset_right = -30
	%Notice.offset_top = 150
	%Notice.offset_bottom = 245
	GameSession.health_changed.connect(_update_health)
	GameSession.score_changed.connect(_update_score)
	SoundManager.mute_changed.connect(_update_sound)
	WorldProgress.abilities_changed.connect(_update_progress)
	WorldProgress.world_changed.connect(_update_progress)
	WorldProgress.checkpoint_changed.connect(_update_progress)
	WorldProgress.enemy_defeated.connect(func(_id: StringName) -> void: _update_progress())
	WorldProgress.shield_changed.connect(func(_active: bool) -> void: _update_progress())
	WorldProgress.notice_changed.connect(_show_notice)

	$Abilities.add_theme_stylebox_override(&"panel", GothicSkin.panel(0, 14))
	$Hint.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	%Notice.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
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
		_show_notice(GameText.t(WorldProgress.notice))
		_settings_button.text=GameText.t("设置")
		_tutorial.text=GameText.t(_tutorial_source)
	)


func _show_notice(text: String) -> void:
	# Repeated instructional notices belong in the one-time tutorial / settings.
	var instruction := RegEx.new()
	instruction.compile("(?:[A-Z]/[A-Z]|[CEQFRT] | [CEQFRT]|LMB|RMB|Space|左键|右键|空格)")
	if instruction.search(text) != null:
		%Notice.text = ""
		_notice_seconds = 0.0
		return
	%Notice.text = text
	_notice_seconds = 5.0
	%Notice.modulate.a = 1.0


func _process(delta: float) -> void:
	if WorldProgress.can_play():
		_tutorial_seconds = maxf(0.0,_tutorial_seconds-delta)
		if _tutorial_seconds <= 0.0: _offer_tutorial()
	_tutorial.visible = _tutorial_seconds > 0.0 and WorldProgress.can_play()
	_notice_seconds = maxf(0.0, _notice_seconds-delta)
	%Notice.modulate.a = minf(1.0, _notice_seconds)


func _update_progress() -> void:
	# The first chapter uses this space for its six-section parkour status panel.
	var parkour := WorldProgress.campaign_rules and WorldProgress.current_scene == &"lone_tree"
	$CarbonDashboard.visible = not parkour
	$Abilities.hide()
	$RouteMap.hide()
	%Notice.anchor_top = 1.0 if parkour else 0.0
	%Notice.anchor_bottom = 1.0 if parkour else 0.0
	%Notice.offset_left = -540 if parkour else -330
	%Notice.offset_top = -108 if parkour else 150
	%Notice.offset_bottom = -24 if parkour else 245
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
		labels[index].text = "%s · %s" % [definition.name, status]
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
				return GameText.t("← 与居民修复通路，再交还两种能力。")
			if WorldProgress.has_ability(&"black_pierce"):
				return GameText.t("← 回紫色绿洲交还黑穿。")
			if WorldProgress.has_ability(&"shield"):
				return GameText.t("← 回绿色绿洲交还护盾，再返回矿洞。")
			return GameText.t("目标 ← 两种能力已卸下，从左端返回毒雾矿坑。")
		if region==&"grassland":
			return GameText.t("← 回矿洞绿洲修复，交还碳矿化。") if WorldProgress.has_ability(&"mineralization") else GameText.t("目标 ← 矿洞已修复，从左端返回垃圾场。")
		return GameText.t("← 修复出生地绿洲，交还二段跳。") if WorldProgress.has_ability(&"double_jump") else GameText.t("目标 ← 四种能力已卸下，继续向左回家。")
	if region==&"lone_tree":
		return ScrapyardLayout.text("→ Cross six scrapyard sections to the mine.", "→ 穿过六段废料跑酷区，前往矿洞。") if WorldProgress.has_ability(&"double_jump") else GameText.t("→ 寻找绿色绿洲，获得二段跳。")
	if region==&"grassland":
		if not WorldProgress.has_ability(&"mineralization"):
			return GameText.t("→ 寻找矿洞绿洲，获得碳矿化。")
		for index in 3:
			if not WorldProgress.is_collected(StringName("grassland/mineral_%d" % index)):
				return GameText.t("净化门 %d/3 · 返回编号 %s 的节点完成固化。") % [index, ["I", "II", "III"][index]]
		return GameText.t("净化门 3/3 · 已打开，向右进入 Eden City →")
	if not WorldProgress.has_ability(&"shield"):
		return GameText.t("→ 寻找绿色绿洲，获得护盾。")
	if not WorldProgress.has_ability(&"black_pierce"):
		return GameText.t("→ 寻找紫色绿洲，获得黑穿。")
	return GameText.t("目标 → 守卫已倒下，进入最右侧档案揭开真相。") if WorldProgress.is_enemy_defeated(&"remnant_sea/boss") else GameText.t("→ 穿过暗壁，击败伊甸守卫。")


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
	for button: Button in [%MenuButton, %MuteButton, _settings_button]:
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and WorldProgress.can_play() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_settings.open()
		get_viewport().set_input_as_handled()


func _offer(id: String, text: String) -> bool:
	if not FirstUseGuideScript.claim(id): return false
	_tutorial_source = text
	_tutorial.text = GameText.t(text)
	_tutorial_seconds = 8.0
	return true

func _offer_tutorial() -> void:
	if not WorldProgress.campaign_rules: return
	var actor := get_tree().get_first_node_in_group(&"player")
	if actor == null or not actor.get_parent() is CampaignLevel: return
	var level: CampaignLevel = actor.get_parent()
	var movement_help := "A/D 移动 · 空格跳跃 · 长按跳得更高 · Shift 快跑"
	if not actor.variable_jump and not actor.allow_sprint:
		movement_help = "A/D 移动 · 空格跳跃"
	if _offer("movement",movement_help): return
	if WorldProgress.core_reversed and _offer("return","回到绿洲按 R，与居民共同修复并卸下能力。"): return
	for id: StringName in [&"double_jump", &"mineralization", &"shield", &"black_pierce"]:
		if WorldProgress.has_ability(id):
			var help := {&"double_jump":"空中再按空格二段跳 · 每次 +5 kg CO₂", &"mineralization":"靠近 I → II → III 节点按 C 固化 · 每次 +1 kg CO₂", &"shield":"按住 Q 展开护盾 · 每次 +20 kg CO₂", &"black_pierce":"F 短距穿梭，可穿敌人和暗壁 · 每次 +200 kg CO₂"}
			if _offer(String(id),help[id]): return
	for oasis: CampaignOasis in level.oases.values():
		if actor.position.distance_to(oasis.position)<220 and WorldProgress.ability_state(oasis.ability)==WorldProgress.AbilityState.UNAVAILABLE:
			if _offer("extract","靠近绿洲按 E，用提取器吸取生命，获得能力。"): return
	if actor.position.distance_to(level.npc.position)<180:
		if _offer("talk","靠近居民按 T 交谈，再按 T 阅读下一句。"): return
	for enemy in level.enemies:
		if is_instance_valid(enemy) and actor.position.distance_to(enemy.position)<350:
			if _offer("combat","左键短砍 · 右键长砍 · 按节奏攻击可减少废热"): return
