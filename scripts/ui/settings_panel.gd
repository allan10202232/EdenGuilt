class_name SettingsPanel
extends Control

var _paused_world := false
var _sound: Button
var _title: Label
var _controls: Label
var _close: Button
var _menu: Button
const GUIDE = "A/D 移动 · 空格跳跃（轻按低跳，长按高跳）\nShift 快跑 · 左键短砍 / 右键长砍\nE 吸取绿洲 · 空中再按空格二段跳\n矿坑 E / J 碳矿化脉冲 · C 也可释放\n按住 Q 护盾 · F 黑穿（可穿暗壁，不能穿普通墙）\nT 交谈 / 下一句 · R 与居民修复 / 卸下能力\n精准节奏提高能效，连发积累废热"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.04,0.035,0.025,0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660,0)
	panel.add_theme_stylebox_override(&"panel",GothicSkin.panel(0,24))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation",16)
	panel.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override(&"font_size",26)
	box.add_child(_title)
	box.add_child(LanguagePicker.new())
	_sound = Button.new()
	_sound.pressed.connect(func() -> void: SoundManager.set_muted(not SoundManager.muted))
	box.add_child(_sound)
	_controls = Label.new()
	_controls.custom_minimum_size.x = 600
	_controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls.add_theme_font_size_override(&"font_size",16)
	_controls.add_theme_constant_override(&"line_spacing",8)
	box.add_child(_controls)
	_close = Button.new()
	_close.pressed.connect(close)
	box.add_child(_close)
	_menu = Button.new()
	_menu.pressed.connect(func() -> void:
		close()
		GameSession.return_to_menu()
	)
	box.add_child(_menu)
	SoundManager.mute_changed.connect(func(_muted: bool) -> void: _refresh())
	GameText.language_changed.connect(_refresh)
	_refresh()
	hide()

func _refresh() -> void:
	_title.text = GameText.t("设置 · 操作说明")
	_controls.text = GameText.t(GUIDE)
	_sound.text = GameText.t("声音：关闭") if SoundManager.muted else GameText.t("声音：开启")
	_close.text = GameText.t("关闭")
	_menu.text = GameText.t("返回主菜单")

func open() -> void:
	if GameSession.state == GameSession.State.PLAYING:
		if not WorldProgress.can_play(): return
		WorldProgress.narrative_active = true
		WorldProgress.narrative_kind = &"settings"
		_paused_world = true
		var actor := get_tree().get_first_node_in_group(&"player")
		if actor != null: actor.combat.cancel()
	_menu.visible = GameSession.state == GameSession.State.PLAYING
	show()
	_close.grab_focus()

func close() -> void:
	hide()
	if _paused_world and WorldProgress.narrative_kind == &"settings":
		WorldProgress.narrative_active = false
		WorldProgress.narrative_kind = &""
	_paused_world = false
	_close.release_focus()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _paused_world and WorldProgress.narrative_kind == &"settings":
		WorldProgress.narrative_active = false
		WorldProgress.narrative_kind = &""
