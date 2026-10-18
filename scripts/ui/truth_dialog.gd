extends Control

var choice_a: Button
var choice_b: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer:=ColorRect.new()
	dimmer.color=Color(0.035,0.025,0.018,0.96)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var panel:=PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", GothicSkin.panel(0, 28))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position=Vector2(-460,-310)
	panel.size=Vector2(920,620)
	add_child(panel)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override(&"separation",15)
	panel.add_child(content)
	var heading_row:=HBoxContainer.new()
	content.add_child(heading_row)
	var heading:=_label(heading_row,GameText.t("──  伊甸秘卷 · 被删去的碳账本  ──"),15,GothicSkin.GOLD)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading_row.add_child(LanguagePicker.new())
	_label(content,GameText.t("净土只占 10%，代价却在城外。"),32)
	var story:=Label.new()
	story.text=GameText.t("垃圾场的人以为伊甸城已经消除了污染。矿工以为自己的毒雾只是必要的过渡。\n能源档案写着另一种答案：净土的四季如春，依靠向城外转移污染与开采成本。\n\n地脉提取器并没有凭空创造能量。你每一次轻易获得的力量，都留下不可抹去的账目。\n这座城把边界内的绿色，称作全世界的绿色。\n\n你可以公开这份账本，救出居民，将提取器改装为逆向循环核心。\n卸下技能不是独自变弱：和居民共同修桥、循环拆解，把绿色还给世界。")
	story.add_theme_font_size_override(&"font_size",17)
	story.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_constant_override(&"line_spacing",5)
	content.add_child(story)
	_label(content,GameText.t("觉醒发生在你的选择里。A 路线转为绿色形态；B 路线保留红色形态。"),16,GothicSkin.MOSS)
	choice_a=Button.new()
	choice_a.name="ChoiceAButton"
	choice_a.text=GameText.t("A  ·  公开真相，改装核心，与居民返程修复")
	choice_a.custom_minimum_size.y=52
	choice_a.pressed.connect(func() -> void: choose(&"A"))
	content.add_child(choice_a)
	choice_b=Button.new()
	choice_b.name="ChoiceBButton"
	choice_b.text=GameText.t("B  ·  留在伊甸城，维持污染向城外转移")
	choice_b.custom_minimum_size.y=48
	choice_b.pressed.connect(func() -> void: choose(&"B"))
	content.add_child(choice_b)
	hide()


func present() -> void:
	show()
	choice_a.grab_focus()


func choose(choice: StringName) -> void:
	if not WorldProgress.choose_ending(choice):
		return
	hide()
	var focus:=get_viewport().gui_get_focus_owner()
	if focus!=null and is_ancestor_of(focus):
		focus.release_focus()


func _label(parent: Node,text: String,font_size: int,tint: Color=GothicSkin.IVORY) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override(&"font_size",font_size)
	label.modulate=tint
	parent.add_child(label)
	return label
