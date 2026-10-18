extends Control


func _process(_delta: float) -> void:
	visible = CarbonLedger.enabled and not (WorldProgress.campaign_rules and WorldProgress.current_scene == &"lone_tree")
	queue_redraw()


func _draw() -> void:
	if not CarbonLedger.enabled:
		return
	var font := get_theme_default_font()
	draw_style_box(GothicSkin.panel(0, 14), Rect2(Vector2.ZERO, size))
	draw_string(font, Vector2(20, 34), GameText.t("碳之书  ·  永久账本"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GothicSkin.GOLD)
	draw_line(Vector2(20, 44), Vector2(size.x-20, 44), Color(0.43, 0.34, 0.21, 0.65))
	draw_string(font, Vector2(20, 77), "%.2f kg CO₂" % CarbonLedger.gross_kg, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, GothicSkin.IVORY)
	draw_string(font, Vector2(20, 100), GameText.t("已固定 %.1f kg  ·  当前负荷 %.1f kg") % [CarbonLedger.stored_kg,CarbonLedger.pollution_load_kg()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GothicSkin.MUTED)
	var energy := GameText.t("能效 —") if CarbonLedger.action_count == 0 else GameText.t("能效 %.0f%%") % (CarbonLedger.efficiency*100)
	draw_string(font, Vector2(20, 126), energy, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GothicSkin.MOSS)
	draw_string(font, Vector2(205, 126), GameText.t("废热 %.0f%%") % CarbonLedger.heat, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.81, 0.47, 0.29))
	for index in 5:
		var energy_tint := GothicSkin.MOSS if CarbonLedger.action_count > 0 and CarbonLedger.efficiency*5 > index else Color(0.24, 0.25, 0.18)
		GothicSkin.diamond(self, Vector2(116+index*13, 121), 4, energy_tint)
		GothicSkin.diamond(self, Vector2(294+index*13, 121), 4, Color(0.81, 0.47, 0.29) if CarbonLedger.heat/20.0 > index else Color(0.26, 0.18, 0.14))
	var rhythm := GameText.t("节奏就绪") if CarbonLedger.seconds_to_beat() <= 0.0 else GameText.t("下次节奏 %.2f 秒") % CarbonLedger.seconds_to_beat()
	var climates := PackedStringArray([GameText.t("空气安宁"), GameText.t("雾霾渐浓"), GameText.t("气候失序 · 敌人狂暴"), GameText.t("重度污染 · 敌人狂暴")])
	draw_string(font, Vector2(20, 155), climates[CarbonLedger.climate_stage()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GothicSkin.GOLD)
	draw_string(font, Vector2(205, 155), rhythm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GothicSkin.MUTED)
