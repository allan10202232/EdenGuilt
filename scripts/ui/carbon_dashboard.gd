extends Control


func _process(_delta: float) -> void:
	visible = CarbonLedger.enabled
	queue_redraw()


func _draw() -> void:
	if not CarbonLedger.enabled:
		return
	var font := get_theme_default_font()
	GothicSkin.draw_text(self,font,Vector2(0,24),"%.1f kg CO₂" % CarbonLedger.gross_kg,20)
	var energy := GameText.t("能效 —") if CarbonLedger.action_count == 0 else GameText.t("能效 %.0f%%") % (CarbonLedger.efficiency*100)
	GothicSkin.draw_text(self,font,Vector2(0,47),energy + "  ·  " + GameText.t("废热 %.0f%%") % CarbonLedger.heat,13)
