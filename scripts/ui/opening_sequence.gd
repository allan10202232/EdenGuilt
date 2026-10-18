extends Control
signal finished
const BACKGROUNDS: Array[Texture2D]=[
	preload("res://assets/art/generated/backgrounds/junkyard.png"),
	preload("res://assets/art/generated/backgrounds/mine.png"),
	preload("res://assets/art/generated/backgrounds/eden_garden.png")]
var _clock:=0.0
var _chapter:=0
var _title: Label
var _story: Label
var skip_button: Button
var next_button: Button
var _active:=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var column:=VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left=96
	column.offset_right=-96
	column.offset_top=420
	column.offset_bottom=-64
	column.add_theme_constant_override(&"separation",12)
	add_child(column)
	_title=Label.new()
	_title.add_theme_font_size_override(&"font_size",34)
	column.add_child(_title)
	_story=Label.new()
	_story.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_story.add_theme_font_size_override(&"font_size",20)
	_story.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(_story)
	var row:=HBoxContainer.new()
	column.add_child(row)
	row.add_child(LanguagePicker.new())
	var spacer:=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	next_button=Button.new()
	next_button.pressed.connect(advance)
	row.add_child(next_button)
	skip_button=Button.new()
	skip_button.name="SkipIntroButton"
	skip_button.text=GameText.t("跳过开场")
	skip_button.pressed.connect(complete)
	row.add_child(skip_button)
	GameText.language_changed.connect(_refresh)
	hide()

func present() -> void:
	_active=true
	_clock=0
	_chapter=0
	_refresh()
	show()
	next_button.grab_focus()

func _refresh() -> void:
	var titles: Array=[GameText.t("第一幕 · 垃圾场"),GameText.t("第二幕 · 毒雾矿洞"),GameText.t("第三幕 · Eden City")]
	var stories: Array=[
		GameText.t("一座城把废物留在边界之外。你在废墟中醒来，捡起仍能回应大地的提取器。"),
		GameText.t("每一份借来的力量都留下代价。追随地面的余绿，穿过矿洞中无法被隐藏的毒雾。"),
		GameText.t("城墙内，春天从不结束。向右寻找真相，再决定是否转身，把绿色还给世界。")]
	_title.text=titles[_chapter]
	_story.text=stories[_chapter]
	next_button.text=GameText.t("踏入旅途") if _chapter==2 else GameText.t("继续 · Enter")
	skip_button.text=GameText.t("跳过开场")

func _process(delta: float) -> void:
	if not _active: return
	_clock+=delta
	if _clock>=5.0: advance()
	_title.modulate.a=clampf(_clock*2.0,0,1)
	_story.modulate.a=clampf((_clock-0.3)*2.0,0,1)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not _active or event.is_echo(): return
	if LanguagePicker.popup_is_open(self): return
	if event.is_action_pressed(&"ui_cancel"):
		complete()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept"):
		# Focused buttons and the language selector own their confirmation key.
		if get_viewport().gui_get_focus_owner() is BaseButton: return
		advance()
		get_viewport().set_input_as_handled()

func advance() -> void:
	if not _active: return
	if _chapter>=2: complete()
	else:
		_chapter+=1
		_clock=0
		_refresh()

func complete() -> void:
	if not _active: return
	_active=false
	hide()
	finished.emit()

func _draw() -> void:
	if not _active: return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.015,0.01))
	var drift:=minf(1.0,_clock/5.0)
	var dimensions:=Vector2(size.x*1.1,size.y*1.1)
	draw_texture_rect(BACKGROUNDS[_chapter],Rect2(Vector2(-size.x*0.05-drift*20,-25),dimensions),false,Color(0.63,0.62,0.52))
	for index in 32:
		var x:=fposmod(index*89.0+_clock*(12+index%5),size.x)
		var y:=size.y*0.65+sin(index+_clock)*80-index%7*20
		draw_circle(Vector2(x,y),2,Color(0.67,0.88,0.42,0.3))
	draw_rect(Rect2(0,0,size.x,68),Color(0.015,0.012,0.008))
	draw_rect(Rect2(0,380,size.x,size.y-380),Color(0.02,0.018,0.01,0.9))
	draw_line(Vector2(96,400),Vector2(size.x-96,400),GothicSkin.GOLD,1)
