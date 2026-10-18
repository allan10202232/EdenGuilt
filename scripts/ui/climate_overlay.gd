extends Control
## Climate feedback sits below the HUD; the readable centre never closes completely.


func _process(_delta: float) -> void:
	visible=CarbonLedger.enabled and GameSession.state==GameSession.State.PLAYING
	queue_redraw()


func _draw() -> void:
	if not CarbonLedger.enabled:
		return
	var stage:=CarbonLedger.climate_stage()
	var ambient:=WorldProgress.current_scene==&"grassland" and not WorldProgress.repaired_regions.has(&"grassland")
	if stage==0 and not ambient:
		return
	var edge:=size.x*(0.04+0.045*stage)
	var tint:=Color(0.66,0.59,0.39) if stage>0 else Color(0.58,0.61,0.37)
	draw_rect(Rect2(Vector2.ZERO,size),Color(tint,0.012*stage+(0.025 if ambient else 0.0)))
	for index in 24:
		var band:=edge/24.0
		var alpha: float=(1.0-float(index)/24.0)*(0.26 if stage>0 else 0.12)
		draw_rect(Rect2(index*band,0,band+1,size.y),Color(tint,alpha))
		draw_rect(Rect2(size.x-(index+1)*band,0,band+1,size.y),Color(tint,alpha))
