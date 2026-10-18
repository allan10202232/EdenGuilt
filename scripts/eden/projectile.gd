class_name EdenEnergyProjectile
extends Node2D
## Swept tests prevent fast reflected shots tunnelling through small receivers.
var level: Node2D
var direction:=Vector2.LEFT
var speed:=210.0
var reflected:=false
var age:=0.0
var source: Node2D
var wave:=false

func _ready() -> void:
	z_index=7
	add_to_group(&"eden_projectile")

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play() or level.hitstop>0: return
	age+=delta
	if age>9:
		queue_free()
		return
	var origin:=global_position
	var next:=origin+direction*speed*delta
	if reflected:
		for target: Node2D in get_tree().get_nodes_in_group(&"eden_receiver"):
			if target.get("level")!=level or not target.is_inside_tree(): continue
			if Geometry2D.get_closest_point_to_segment(target.global_position,origin,next).distance_to(target.global_position)<target.hit_radius:
				if target.receive_reflection(self):
					queue_free()
					return
	else:
		var actor: CharacterBody2D=level.player
		var closest:=Geometry2D.get_closest_point_to_segment(actor.global_position,origin,next)
		if absf(closest.x-actor.global_position.x)<25 and absf(closest.y-actor.global_position.y)<(25 if not wave else 18):
			var response: int=actor.intercept_projectile(self) if not wave else 0
			if response==2:
				reflected=true
				direction=-direction
				speed*=1.6
				position=actor.position+direction*31
				SoundManager.play_sfx(&"impact_heavy",-10)
				return
			if response==0: actor.hurt(&"projectile")
			queue_free()
			return
	global_position=next
	queue_redraw()

func _draw() -> void:
	var color:=Color("bbf3ec") if reflected else Color("ffd899")
	if wave:
		draw_arc(Vector2.ZERO,27,PI,TAU,12,Color("ffe9bd"),5)
	else:
		draw_circle(Vector2.ZERO,15,Color(color,0.12))
		draw_circle(Vector2.ZERO,8,color)
		draw_rect(Rect2(-3,-3,6,6),Color.WHITE)
		draw_line(-direction*21,Vector2.ZERO,Color(color,0.6),3)
