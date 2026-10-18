class_name EdenLightReceiver
extends Node2D
signal charged(receiver: EdenLightReceiver)
var level: Node2D
var receiver_id: StringName
var lit:=false
var hits:=0
var required_hits:=1
var hit_radius:=23.0
var on_reflect: Callable

func _ready() -> void:
	add_to_group(&"eden_receiver")
	z_index=4

func receive_reflection(shot: Node2D) -> bool:
	if lit or not shot.reflected: return false
	if on_reflect.is_valid() and not on_reflect.call(shot): return false
	hits+=1
	if hits>=required_hits:
		lit=true
		charged.emit(self)
	queue_redraw()
	return true

func _draw() -> void:
	draw_rect(Rect2(-25,-25,50,50),Color("313e36"))
	draw_rect(Rect2(-21,-21,42,42),Color("9ba98d"),false,3)
	var tint:=Color("adf0cc") if lit else Color("ae8660")
	draw_circle(Vector2.ZERO,14,tint)
	draw_arc(Vector2.ZERO,20,-PI/2,-PI/2+TAU*float(hits)/required_hits,24,Color("e8f8dc"),3)
	draw_line(Vector2(-7,0),Vector2(7,0),Color("1b382c"),3)
