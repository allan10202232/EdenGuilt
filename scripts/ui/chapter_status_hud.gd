class_name ChapterStatusHUD
extends Control
## The only persistent gameplay UI: leaf health and an objective map.
const MapScript=preload("res://scripts/ui/objective_minimap.gd")
var minimap: Control

var life_orbs: LifeOrbs
# Hidden compatibility handles for existing chapter logic and fixture tooling.
var stage_label: Label
var jump_label: Label
var skill_label: Label
var cooldown: ProgressBar
var carbon_label: Label
var storage_label: Label
var detail_label: Label

func _ready() -> void:
	name="ChapterStatus"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	theme=preload("res://assets/ui_theme.tres")
	var rows:=VBoxContainer.new()
	rows.hide()
	rows.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(rows)
	life_orbs=LifeOrbs.new()
	life_orbs.name="LifeOrbs"
	life_orbs.position=Vector2(24,22)
	life_orbs.size=life_orbs.custom_minimum_size
	add_child(life_orbs)
	minimap=MapScript.new()
	add_child(minimap)
	stage_label=_label(rows,17)
	jump_label=_label(rows,15)
	skill_label=_label(rows,13)
	cooldown=ProgressBar.new()
	cooldown.custom_minimum_size=Vector2(300,12)
	cooldown.max_value=1.0
	cooldown.show_percentage=false
	cooldown.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var background:=StyleBoxFlat.new()
	background.bg_color=Color(0.08,0.15,0.18)
	var fill:=StyleBoxFlat.new()
	fill.bg_color=Color(0.76,0.69,0.94)
	cooldown.add_theme_stylebox_override(&"background",background)
	cooldown.add_theme_stylebox_override(&"fill",fill)
	rows.add_child(cooldown)
	carbon_label=_label(rows,20)
	storage_label=_label(rows,15)
	detail_label=_label(rows,13)
	detail_label.custom_minimum_size.y=18
	GameSession.health_changed.connect(life_orbs.set_health)
	life_orbs.set_health(GameSession.health,GameSession.max_health)

func _label(parent: Node,font_size: int) -> Label:
	var label:=Label.new()
	label.add_theme_font_size_override(&"font_size",font_size)
	label.custom_minimum_size.x=350
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func show_status(stage: String,jump: String,skill: String,remaining: float,maximum: float,detail: String="") -> void:
	stage_label.text=stage
	jump_label.text=jump
	skill_label.text=skill
	cooldown.max_value=maxf(maximum,0.001)
	cooldown.value=maxf(0.0,maximum-remaining)
	detail_label.text=detail
	detail_label.show()
