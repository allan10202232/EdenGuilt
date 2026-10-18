extends Node2D

var player: CharacterBody2D
var direction: float = -1.0
var _life: float = 4.0


func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play():
		return
	_life -= delta
	var destination:=global_position+Vector2(direction*300.0*delta,0)
	var query:=PhysicsRayQueryParameters2D.create(global_position,destination,1)
	if _life<=0.0 or not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position=destination
	if is_instance_valid(player) and absf(player.global_position.x-global_position.x)<19.0 and absf(player.global_position.y-global_position.y)<28.0:
		player.hurt(15)
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-6,-4,12,8),Color(1.0,0.66,0.2))
	draw_line(Vector2(-direction*17,0),Vector2.ZERO,Color(0.95,0.39,0.12,0.5),3)
