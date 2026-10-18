extends Control
## Platforms, lamps, ability source, exit and player in a compact route overview.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var player:=get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if player==null or not player.get_parent() is CampaignLevel:
		return
	var level:=player.get_parent() as CampaignLevel
	var data:=level.definition
	if data.is_empty():
		return
	var scale:=Vector2((size.x-24.0)/float(data.width),42.0/float(data.height))
	var origin:=Vector2(12,18)
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.045,0.05,0.85))
	draw_rect(Rect2(Vector2.ZERO,size),Color(data.accent,0.35),false,1)
	for rect: Rect2 in data.platforms:
		draw_rect(Rect2(origin+rect.position*scale,Vector2(maxf(2,rect.size.x*scale.x),2)),Color(data.accent,0.6))
	for point: Vector2 in data.checkpoints:
		draw_circle(origin+point*scale,2,Color(0.95,0.72,0.35))
	draw_circle(origin+Vector2(data.source)*scale,3,Color(0.46,0.95,0.67))
	draw_rect(Rect2(origin+Vector2(data.exit)*scale-Vector2(2,3),Vector2(4,6)),Color(0.9,0.83,0.6))
	draw_circle(origin+player.position*scale,3,Color(1,0.34,0.35))
	draw_string(get_theme_default_font(),Vector2(12,13),"← 返程 · 交还能力" if WorldProgress.returning else "探索 · 森林 → 垃圾场 → 矿厂",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(0.78,0.83,0.77))
