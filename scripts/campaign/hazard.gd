class_name CampaignHazard
extends Node2D

var player: CharacterBody2D
var region_ability: StringName = &"dash"
var area := Rect2()
var offset: float = 0.0
var _clock: float = 0.0
var neutralized: bool = false


func phase() -> int:
	if neutralized or WorldProgress.route_open(region_ability):
		return 0
	var cycle:=fmod(_clock+offset,3.6)
	return 2 if cycle>=2.2 and cycle<2.85 else 1 if cycle>=1.4 and cycle<2.2 else 0


func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play():
		return
	_clock+=delta
	if phase()==2 and is_instance_valid(player):
		var body:=Rect2(player.global_position-Vector2(14,24),Vector2(28,48))
		if area.intersects(body):
			player.hurt(20)
	queue_redraw()


func _draw() -> void:
	var active:=phase()
	var safe:=neutralized or WorldProgress.route_open(region_ability)
	var tint:=Color(0.28,0.76,0.87) if safe else Color(0.96,0.3,0.22) if active==2 else Color(0.96,0.67,0.27)
	draw_rect(Rect2(area.position-Vector2(12,12),Vector2(area.size.x+24,16)),Color(0.18,0.22,0.25))
	draw_rect(Rect2(area.position,Vector2(area.size.x,4)),tint)
	if active>0 or safe:
		draw_rect(area,Color(tint,0.36 if active==2 else 0.07))
		for x in range(int(area.position.x)+8,int(area.end.x),15):
			draw_line(Vector2(x,area.position.y),Vector2(x,area.end.y),Color(tint,0.8 if active==2 else 0.25),2)
	if active==1:
		draw_string(ThemeDB.fallback_font,area.position+Vector2(-4,-22),"即将喷发",HORIZONTAL_ALIGNMENT_LEFT,-1,15,tint)
