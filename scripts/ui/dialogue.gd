extends Control
signal closed
var _speaker: Label
var _body: Label
var _lines: Array=[]
var _index:=0
var _closing:=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var margin:=MarginContainer.new()
	margin.name="Subtitles"
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	margin.offset_left=90
	margin.offset_right=-90
	margin.offset_top=-170
	margin.offset_bottom=-28
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var panel:=PanelContainer.new()
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var backing:=StyleBoxFlat.new()
	backing.bg_color=Color(0.025,0.022,0.015,0.50)
	for side in [SIDE_LEFT,SIDE_RIGHT]: backing.set_content_margin(side,24)
	for side in [SIDE_TOP,SIDE_BOTTOM]: backing.set_content_margin(side,12)
	panel.add_theme_stylebox_override(&"panel",backing)
	margin.add_child(panel)
	var column:=VBoxContainer.new()
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation",6)
	panel.add_child(column)
	_speaker=Label.new()
	_speaker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_speaker.add_theme_font_size_override(&"font_size",16)
	_speaker.add_theme_color_override(&"font_color",Color.WHITE)
	column.add_child(_speaker)
	_body=Label.new()
	_body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_body.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override(&"font_size",22)
	_body.add_theme_color_override(&"font_color",Color.WHITE)
	_body.add_theme_color_override(&"font_outline_color",Color.BLACK)
	_body.add_theme_constant_override(&"outline_size",4)
	column.add_child(_body)
	GameText.language_changed.connect(_refresh)
	hide()

func present(speaker: String, lines: Array) -> void:
	if lines.is_empty(): return
	_speaker.text=speaker
	_lines=lines.duplicate()
	_index=0
	_closing=false
	_refresh()
	show()

func _refresh() -> void:
	if _lines.is_empty(): return
	_speaker.text=GameText.t(_speaker.text)
	_body.text=GameText.t(String(_lines[_index]))
	_body.visible_characters=-1

func _input(event: InputEvent) -> void:
	if not visible or event.is_echo(): return
	if event.is_action_pressed(&"eden_talk"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func advance() -> void:
	if _closing: return
	_index+=1
	if _index>=_lines.size(): close()
	else: _refresh()

func close() -> void:
	if _closing: return
	_closing=true
	hide()
	_lines.clear()
	_index=0
	# Consume the last T press before NPC interaction can resume.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if WorldProgress.narrative_kind==&"npc":
		WorldProgress.narrative_active=false
		WorldProgress.narrative_kind=&""
		WorldProgress.world_changed.emit()
	closed.emit()
