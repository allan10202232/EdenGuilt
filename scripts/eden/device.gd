class_name EdenBreakableDevice
extends Node2D
var level: Node2D
var activated:=false
var device_id:=&"conduit"
var on_break: Callable
var allowed: Callable

func _ready() -> void:
	var hurtbox:=MeleeHurtbox.new()
	hurtbox.collision_layer=4
	hurtbox.collision_mask=0
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(55,65)
	shape.shape=box
	hurtbox.add_child(shape)
	add_child(hurtbox)
	z_index=4

func receive_melee_hit(_hit: Dictionary) -> bool:
	if activated or not WorldProgress.can_play() or (allowed.is_valid() and not allowed.call()): return false
	activated=true
	if on_break.is_valid(): on_break.call()
	queue_redraw()
	return true

func _draw() -> void:
	draw_rect(Rect2(-23,-31,46,62),Color("3f5147"))
	draw_rect(Rect2(-19,-27,38,54),Color("c7c5a4"),false,3)
	draw_line(Vector2(-12,-15),Vector2(12,15),Color("647164") if activated else Color("a9efdb"),7)
	if not activated: draw_circle(Vector2(0,-15),5,Color("e7cc8f"))
