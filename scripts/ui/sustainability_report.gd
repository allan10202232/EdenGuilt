extends Control

var result_snapshot: Dictionary = {}
var exported_paths: Dictionary = {}
var _heading: Label
var _gross: Label
var _stored: Label
var _efficiency: Label
var _skills: Label
var _community: Label
var _reflection: Label
var _equivalence: Label
var _status: Label
var _chart: Control
var _restart: Button
var _open: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black:=ColorRect.new()
	black.color=Color(0.015,0.025,0.028,1)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:
		margin.add_theme_constant_override(StringName("margin_"+side),36)
	for side in ["top","bottom"]:
		margin.add_theme_constant_override(StringName("margin_"+side),24)
	add_child(margin)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override(&"separation",12)
	margin.add_child(content)
	_label(content,"SUSTAINABILITY AUDIT REPORT  /  玩家个人可持续行为审计",14,Color(0.65,0.78,0.64))
	_heading=_label(content,"",30)
	var cards:=HBoxContainer.new()
	cards.add_theme_constant_override(&"separation",18)
	content.add_child(cards)
	_gross=_card(cards,"累计排放 · CO₂")
	_stored=_card(cards,"已固定 · CO₂")
	_efficiency=_card(cards,"Exergy · 总有效能利用率")
	var columns:=HBoxContainer.new()
	columns.add_theme_constant_override(&"separation",30)
	columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_child(columns)
	var left:=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio=1.2
	columns.add_child(left)
	_chart=preload("res://scripts/ui/audit_chart.gd").new()
	_chart.custom_minimum_size=Vector2(480,179)
	left.add_child(_chart)
	_skills=_label(left,"",15)
	var right:=VBoxContainer.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override(&"separation",12)
	columns.add_child(right)
	_reflection=_label(right,"",18,Color(0.83,0.88,0.7))
	_reflection.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_community=_label(right,"",16)
	_equivalence=_label(right,"",14,Color(0.68,0.77,0.73))
	_equivalence.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var method:=_label(content,"教学模型：排放与固碳为游戏设定，累计排放不会被修复清零。汽油类比使用 EPA 系数；矿石替代比为可调教学假设。\nExergy 为可用能利用率的游戏化指标，完整公式、参数与 EPA / DOE 来源已写入报告。",13,Color(0.56,0.67,0.63))
	method.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override(&"separation",16)
	content.add_child(actions)
	_open=_button(actions,"打开审计报告",func() -> void:
		if exported_paths.get("ok",false): OS.shell_open(exported_paths.html)
	)
	_button(actions,"重新导出 HTML / JSON / CSV",_export)
	_restart=_button(actions,"重新开始整局",func() -> void: GameSession.restart_run())
	_button(actions,"返回主菜单",func() -> void: GameSession.return_to_menu())
	_status=_label(content,"",12,Color(0.59,0.73,0.65))
	_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hide()


func present(result: Dictionary) -> void:
	result_snapshot=result.duplicate(true)
	var data: Dictionary=result_snapshot.audit
	var choice_a: bool=result_snapshot.get("ending","")=="A"
	_heading.text="A · 把绿色还给世界" if choice_a else "B · 边界以内的春天"
	_gross.text="%.2f kg"%data.gross_kg
	_stored.text="%.2f kg"%data.stored_kg
	_efficiency.text="%.1f%%   /   废热 %.1f%%"%[data.efficiency*100.0,(1.0-data.efficiency)*100.0 if data.input_energy>0 else 0.0]
	_chart.data=data
	_chart.queue_redraw()
	var rows:=PackedStringArray(["技能                              次数              CO₂"])
	for skill: Dictionary in data.skills.values():
		rows.append("%s     × %d     /     %.2f kg"%[skill.name,skill.casts,skill.gross_kg])
	if data.skills.is_empty():
		rows.append("本局未使用技能，没有排放事件。")
	rows.append("精准释放 %d 次 · 高频释放 %d 次"%[data.precise_casts,data.rapid_casts])
	_skills.text="\n".join(rows)
	_reflection.text="力量曾让你独自越过深渊。\n回家的桥，却是和别人一起修好的。" if choice_a else "你保住了窗内的春天。\n窗外的人仍替你呼吸。"
	_community.text="救出居民  %d 人\n共同修复  %d / 3 地区\n循环拆解  %d 个节点 · 回收材料 %.0f kg\n当前污染负荷  %.1f kg（模拟）"%[data.people,data.restored_regions,data.recycled_nodes,data.recycled_material_kg,data.pollution_load_kg]
	_equivalence.text="现实量级类比：本局模拟排放约对应 %.1f 升汽油燃烧。\n循环经济教学估算：原生矿石替代 %.1f kg。\n这些是游戏数据类比，不是现实排放或减排证明。"%[data.gasoline_litres_analogy,data.teaching_ore_avoided_kg]
	_export()
	show()
	_restart.grab_focus()


func _export() -> void:
	exported_paths=SustainabilityAudit.export_files(result_snapshot)
	_open.disabled=not exported_paths.get("ok",false)
	_status.text="已保存 HTML 可视化报告、JSON 数据和 CSV 事件账本。" if exported_paths.get("ok",false) else exported_paths.get("error","导出失败")


func _label(parent: Node,text: String,size: int,tint: Color=Color(0.87,0.9,0.85)) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override(&"font_size",size)
	label.modulate=tint
	parent.add_child(label)
	return label


func _card(parent: Node,title: String) -> Label:
	var panel:=PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column:=VBoxContainer.new()
	panel.add_child(column)
	_label(column,title,14,Color(0.64,0.76,0.67))
	return _label(column,"",26,Color(0.9,0.76,0.47))


func _button(parent: Node,title: String,callback: Callable) -> Button:
	var button:=Button.new()
	button.text=title
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
