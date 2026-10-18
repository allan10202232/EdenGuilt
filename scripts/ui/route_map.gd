extends Control
## A hand-drawn route on vellum; the carmine diamond marks the traveller.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if player == null or not player.get_parent() is CampaignLevel:
		return
	var level := player.get_parent() as CampaignLevel
	var data := level.definition
	if data.is_empty():
		return
	var scale := Vector2((size.x-32.0)/float(data.width), 40.0/float(data.height))
	var origin := Vector2(16, 28)
	draw_style_box(GothicSkin.panel(1, 12), Rect2(Vector2.ZERO, size))
	for rect: Rect2 in data.platforms:
		draw_rect(Rect2(origin+rect.position*scale, Vector2(maxf(2, rect.size.x*scale.x), 2)), Color(0.32, 0.28, 0.17, 0.8))
	for point: Vector2 in data.checkpoints:
		draw_circle(origin+point*scale, 2, GothicSkin.INK)
	draw_circle(origin+Vector2(data.source)*scale, 3, Color(0.29, 0.38, 0.19))
	draw_rect(Rect2(origin+Vector2(data.exit)*scale-Vector2(2, 3), Vector2(4, 6)), GothicSkin.INK)
	GothicSkin.diamond(self, origin+player.position*scale, 5, Color(0.57, 0.12, 0.12))
	GothicSkin.draw_text(self,get_theme_default_font(), Vector2(16, 23), GameText.t("归途手记  ←  与居民共同修复") if WorldProgress.returning else GameText.t("旅途手记  ·  垃圾场 → 矿洞 → 伊甸城"),12)
