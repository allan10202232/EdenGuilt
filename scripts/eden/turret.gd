class_name EdenTurret
extends Node2D
var level: Node2D
var direction:=Vector2.LEFT
var interval:=2.2
var countdown:=1.0
var active:=true
var max_distance:=700.0

func _physics_process(delta: float) -> void:
	if not active or not WorldProgress.can_play() or level.hitstop>0: return
	if global_position.distance_to(level.player.global_position)>max_distance: return
	countdown-=delta
	if countdown<=0:
		level.fire(global_position,direction,220,self)
		countdown=interval
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-20,-16,40,32),Color("3c493e"))
	draw_rect(Rect2(-16,-12,32,24),Color("b7b294"),false,3)
	draw_line(Vector2.ZERO,direction*29,Color("b0c9bb"),8)
	if active:
		draw_circle(direction*30,6,Color("ffd597") if countdown<0.5 else Color("829b8c"))
