class_name ElevatorSwitch
extends Area2D
## A dock call button or optional sword-operated hoist switch.
@export_node_path("Node2D") var elevator_path: NodePath
@export_enum("Interact","Attack","Both") var activation_mode:=0
@export var call_top:=false
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Hints=preload("res://scripts/presentation/interaction_hints.gd")
var elevator: OpenElevator
var _actor: CharacterBody2D
var _hints: Node2D

func _ready() -> void:
	collision_layer=0
	collision_mask=2
	if not elevator_path.is_empty(): elevator=get_node_or_null(elevator_path) as OpenElevator
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(110,120)
	shape.shape=box
	add_child(shape)
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group(&"player"): _actor=body as CharacterBody2D
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body==_actor: _actor=null
	)
	var hurtbox:=MeleeHurtbox.new()
	hurtbox.collision_layer=4
	hurtbox.collision_mask=0
	var hit:=CollisionShape2D.new()
	var hit_shape:=RectangleShape2D.new()
	hit_shape.size=Vector2(34,46)
	hit.shape=hit_shape
	hurtbox.add_child(hit)
	add_child(hurtbox)
	add_child(Art.sprite(6,Vector2(40,46)))
	_hints=Hints.new()
	add_child(_hints)
	_hints.offer(func() -> Vector2: return Vector2.ZERO,func() -> String: return "LMB" if activation_mode==1 else "T",95,Vector2(0,-60),func() -> Vector2: return _actor.get_parent().to_local(global_position) if is_instance_valid(_actor) else Vector2.INF)

func _process(_delta: float) -> void:
	_hints.actor=_actor

func activate() -> bool:
	return elevator.call_to_stop(call_top) if is_instance_valid(elevator) else false

func receive_melee_hit(_hit: Dictionary) -> bool:
	return activate() if activation_mode in [1,2] else false

func _unhandled_input(event: InputEvent) -> void:
	if activation_mode in [0,2] and is_instance_valid(_actor) and event.is_action_pressed(&"eden_talk") and activate(): get_viewport().set_input_as_handled()
