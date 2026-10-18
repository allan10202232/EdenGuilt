class_name DoorTransition
extends "res://scripts/transitions/transition_zone.gd"
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Hints=preload("res://scripts/presentation/interaction_hints.gd")
@export var draw_door:=true
@export var hint_offset:=Vector2(0,-110)
var _hints: Node2D

func _ready() -> void:
	transition_type="door"
	zone_size=Vector2(110,140)
	super._ready()
	if draw_door:
		var arch:=Art.sprite(11,Vector2(110,150),Vector2(0,-40))
		add_child(arch)
	_hints=Hints.new()
	add_child(_hints)
	_hints.offer(func() -> Vector2: return Vector2.ZERO,func() -> String: return "T" if is_instance_valid(_inside) else "",85,hint_offset,func() -> Vector2: return _inside.get_parent().to_local(global_position) if is_instance_valid(_inside) else Vector2.INF)

func _process(_delta: float) -> void:
	_hints.actor=_inside

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"eden_talk") and activate(): get_viewport().set_input_as_handled()
