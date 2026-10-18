extends Control

func _process(_delta: float) -> void:
	visible=WorldProgress.current_scene==&"grassland" and CarbonLedger.enabled
	queue_redraw()

func _draw() -> void:
	if not visible: return
	var actor:=get_tree().get_first_node_in_group(&"player")
	if actor==null or not actor.get_parent() is CampaignLevel: return
	var level: CampaignLevel=actor.get_parent()
	var sealed:=0
	for index in 3:
		if WorldProgress.is_collected(StringName("grassland/mineral_%d"%index)): sealed+=1
	draw_style_box(GothicSkin.panel(0,12),Rect2(Vector2.ZERO,size))
	var font:=get_theme_default_font()
	draw_string(font,Vector2(18,24),GameText.t("毒素负荷 %.0f%% · 封印 %d / 3")%[level.toxin,sealed],HORIZONTAL_ALIGNMENT_LEFT,-1,14,GothicSkin.IVORY)
	draw_rect(Rect2(18,35,size.x-36,5),Color(0.2,0.23,0.11))
	draw_rect(Rect2(18,35,(size.x-36)*level.toxin/100.0,5),Color(0.66,0.74,0.22))
	draw_string(font,Vector2(18,62),GameText.t("离开毒雾可恢复 · C 按编号封住毒源"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,GothicSkin.MUTED)
