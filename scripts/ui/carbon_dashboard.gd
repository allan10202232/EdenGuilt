extends Control


func _process(_delta: float) -> void:
	visible=CarbonLedger.enabled
	queue_redraw()


func _draw() -> void:
	if not CarbonLedger.enabled:
		return
	var font:=get_theme_default_font()
	var gold:=Color(0.92,0.73,0.4)
	var green:=Color(0.58,0.86,0.64)
	var grey:=Color(0.7,0.78,0.73)
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.045,0.049,0.94))
	draw_line(Vector2(0,size.y),size,Color(0.38,0.48,0.32),1)
	draw_string(font,Vector2(16,22),"CARBON LEDGER  /  实时碳账本与能效仪表盘",HORIZONTAL_ALIGNMENT_LEFT,-1,13,grey)
	draw_string(font,Vector2(16,54),"%.2f kg CO₂"%CarbonLedger.gross_kg,HORIZONTAL_ALIGNMENT_LEFT,-1,27,gold)
	var energy_text: String="Exergy   待测" if CarbonLedger.action_count==0 else "Exergy   %.0f%%"%(CarbonLedger.efficiency*100)
	draw_string(font,Vector2(280,52),energy_text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,green)
	draw_string(font,Vector2(493,52),"热负荷   %.0f%%"%CarbonLedger.heat,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(0.98,0.47,0.25))
	draw_rect(Rect2(280,63,175,6),Color(0.13,0.21,0.2))
	draw_rect(Rect2(280,63,175*CarbonLedger.efficiency if CarbonLedger.action_count>0 else 0.0,6),green)
	draw_rect(Rect2(493,63,175,6),Color(0.22,0.14,0.1))
	draw_rect(Rect2(493,63,175*CarbonLedger.heat/100.0,6),Color(0.95,0.37,0.2))
	draw_string(font,Vector2(16,81),"已固定 %.1f kg · 负荷 %.1f kg"%[CarbonLedger.stored_kg,CarbonLedger.pollution_load_kg()],HORIZONTAL_ALIGNMENT_LEFT,-1,14,grey)
	var rhythm: String="节拍就绪" if CarbonLedger.seconds_to_beat()<=0.0 else "距节拍 %.2f s"%CarbonLedger.seconds_to_beat()
	draw_string(font,Vector2(280,91),rhythm+" · 精准 95% / 连发可浪费 70%",HORIZONTAL_ALIGNMENT_LEFT,-1,12,grey)
	var climate_names:=PackedStringArray(["空气稳定","温室雾霾 · 视野收窄","极端气候 · 怪物狂暴","重度污染 · 怪物狂暴"])
	draw_string(font,Vector2(16,107),climate_names[CarbonLedger.climate_stage()]+"    ·    总账永久保留；固碳单列",HORIZONTAL_ALIGNMENT_LEFT,-1,13,gold)
