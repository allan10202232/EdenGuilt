extends Control

var data: Dictionary = {}


func _draw() -> void:
	if data.is_empty():
		return
	var font:=get_theme_default_font()
	var maximum: float=1.0
	for stage: Dictionary in data.stages.values():
		maximum=maxf(maximum,float(stage.gross_kg))
	var index:=0
	for stage: Dictionary in data.stages.values():
		var y: float=35+index*47
		draw_string(font,Vector2(0,y+13),stage.name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.82,0.89,0.82))
		draw_rect(Rect2(105,y,maxf(1,size.x-215),17),Color(0.12,0.18,0.18))
		draw_rect(Rect2(105,y,maxf(0,(size.x-215)*float(stage.gross_kg)/maximum),17),Color(0.84,0.61,0.32))
		draw_string(font,Vector2(size.x-96,y+13),"%.1f kg"%stage.gross_kg,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(0.92,0.83,0.65))
		index+=1
	draw_string(font,Vector2.ZERO+Vector2(0,16),"三幕技能碳排放 · kg CO₂",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(0.74,0.86,0.73))
