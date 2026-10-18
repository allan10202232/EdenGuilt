extends Control
signal closed
var _speaker: Label
var _body: RichTextLabel
var _next: Button
var _lines: Array=[]
var _index:=0
var _reveal:=0.0
var _closing:=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.015,0.01,0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override(StringName("margin_"+side),100)
	margin.add_theme_constant_override(&"margin_top",380)
	margin.add_theme_constant_override(&"margin_bottom",50)
	add_child(margin)
	var panel:=PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel",GothicSkin.panel(0,24))
	margin.add_child(panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override(&"separation",12)
	panel.add_child(column)
	var row:=HBoxContainer.new()
	column.add_child(row)
	_speaker=Label.new()
	_speaker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_speaker.add_theme_font_size_override(&"font_size",22)
	row.add_child(_speaker)
	row.add_child(LanguagePicker.new())
	_body=RichTextLabel.new()
	_body.custom_minimum_size.y=95
	_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_body.fit_content=false
	_body.add_theme_font_override(&"normal_font",preload("res://assets/ui_theme.tres").default_font)
	_body.add_theme_font_size_override(&"normal_font_size",19)
	column.add_child(_body)
	var actions:=HBoxContainer.new()
	column.add_child(actions)
	_next=Button.new()
	_next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_next.pressed.connect(advance)
	actions.add_child(_next)
	var leave:=Button.new()
	leave.text=GameText.t("结束交谈")
	leave.pressed.connect(close)
	actions.add_child(leave)
	GameText.language_changed.connect(_refresh)
	hide()

func present(speaker: String, lines: Array) -> void:
	_speaker.text=speaker
	_lines=lines.duplicate()
	_index=0
	_closing=false
	_refresh()
	show()
	_next.grab_focus()

func _refresh() -> void:
	if _lines.is_empty(): return
	_speaker.text=GameText.t(_speaker.text)
	_body.text=GameText.t(String(_lines[_index]))
	_reveal=0
	_body.visible_characters=0
	_next.text=GameText.t("继续 · Enter / T") if _index<_lines.size()-1 else GameText.t("结束交谈")

func _process(delta: float) -> void:
	if not visible: return
	_reveal+=delta*48
	_body.visible_characters=int(_reveal)

func _input(event: InputEvent) -> void:
	if not visible or event.is_echo(): return
	if LanguagePicker.popup_is_open(self): return
	if event.is_action_pressed(&"eden_talk") or event.is_action_pressed(&"ui_accept"):
		if event.is_action_pressed(&"ui_accept") and get_viewport().gui_get_focus_owner() is BaseButton: return
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func advance() -> void:
	if _closing: return
	if _body.visible_characters>=0 and _body.visible_characters<_body.get_total_character_count():
		_reveal=10000
		_body.visible_characters=-1
		return
	_index+=1
	if _index>=_lines.size(): close()
	else: _refresh()

func close() -> void:
	if _closing: return
	_closing=true
	hide()
	_lines.clear()
	_index=0
	# Consume the confirmation edge before physics resumes (Space must not jump).
	await get_tree().physics_frame
	await get_tree().physics_frame
	if WorldProgress.narrative_kind==&"npc":
		WorldProgress.narrative_active=false
		WorldProgress.narrative_kind=&""
		WorldProgress.world_changed.emit()
	closed.emit()
