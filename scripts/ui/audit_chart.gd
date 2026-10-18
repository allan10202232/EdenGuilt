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
		GothicSkin.draw_text(self,font,Vector2(0,y+13),GameText.t(stage.name),16)
		draw_rect(Rect2(105,y,maxf(1,size.x-215),17),Color(0.19,0.15,0.1))
		draw_rect(Rect2(105,y,maxf(0,(size.x-215)*float(stage.gross_kg)/maximum),17),Color(0.84,0.61,0.32))
		GothicSkin.draw_text(self,font,Vector2(size.x-96,y+13),"%.1f kg"%stage.gross_kg,15)
		index+=1
	GothicSkin.draw_text(self,font,Vector2.ZERO+Vector2(0,16),GameText.t("三幕技能碳排放 · kg CO₂"),18)
