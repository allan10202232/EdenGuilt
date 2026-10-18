extends Control

var choice_a: Button
var choice_b: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer:=ColorRect.new()
	dimmer.color=Color(0.015,0.025,0.03,0.97)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var panel:=PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position=Vector2(-460,-291)
	panel.size=Vector2(920,582)
	add_child(panel)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override(&"separation",15)
	panel.add_child(content)
	_label(content,"EDEN ARCHIVE  /  被删去的碳账本",15,Color(0.9,0.74,0.4))
	_label(content,"净土只占 10%，代价却在城外。",32)
	var story:=Label.new()
	story.text="垃圾场的人以为伊甸园已经消除了污染。矿工以为自己的毒雾只是必要的过渡。\n能源档案写着另一种答案：净土的四季如春，依靠向城外转移污染与开采成本。\n\n地脉提取器并没有凭空创造能量。你每一次轻易获得的力量，都留下不可抹去的账目。\n这座城把边界内的绿色，称作全世界的绿色。\n\n你可以公开这份账本，救出居民，将提取器改装为逆向循环核心。\n卸下技能不是独自变弱：和居民共同修桥、循环拆解，把绿色还给世界。"
	story.add_theme_font_size_override(&"font_size",17)
	story.add_theme_constant_override(&"line_spacing",5)
	content.add_child(story)
	_label(content,"觉醒发生在你的选择里。A 路线转为绿色形态；B 路线保留红色形态。",16,Color(0.59,0.85,0.69))
	choice_a=Button.new()
	choice_a.name="ChoiceAButton"
	choice_a.text="A  ·  公开真相，改装核心，与居民返程修复"
	choice_a.custom_minimum_size.y=52
	choice_a.pressed.connect(func() -> void: choose(&"A"))
	content.add_child(choice_a)
	choice_b=Button.new()
	choice_b.name="ChoiceBButton"
	choice_b.text="B  ·  留在伊甸园，维持污染向城外转移"
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


func _label(parent: Node,text: String,font_size: int,tint: Color=Color(0.89,0.91,0.85)) -> void:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override(&"font_size",font_size)
	label.modulate=tint
	parent.add_child(label)
