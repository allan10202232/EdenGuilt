@tool
class_name GothicFrame
extends StyleBox
## Scale ornate source corners down independently of the panel's output size.
## A 627px artwork tile must not impose 96px corners on a 48px button.
const ATLAS: Texture2D = preload("res://assets/art/generated/ui/gothic_atlas.png")
@export_range(0, 3) var tile: int = 0
@export var corner_size: float = 22.0


func _draw(item: RID, rect: Rect2) -> void:
	var cell := ATLAS.get_size() / 2.0
	var origin := Vector2(tile % 2, floori(tile / 2.0)) * cell
	var source_corner := cell.x * 0.16
	var corner := minf(corner_size, minf(rect.size.x, rect.size.y) * 0.45)
	var sx := [0.0, source_corner, cell.x-source_corner, cell.x]
	var sy := [0.0, source_corner, cell.y-source_corner, cell.y]
	var dx := [0.0, corner, rect.size.x-corner, rect.size.x]
	var dy := [0.0, corner, rect.size.y-corner, rect.size.y]
	for row in 3:
		for column in 3:
			var source := Rect2(origin+Vector2(sx[column],sy[row]),Vector2(sx[column+1]-sx[column],sy[row+1]-sy[row]))
			var target := Rect2(rect.position+Vector2(dx[column],dy[row]),Vector2(dx[column+1]-dx[column],dy[row+1]-dy[row]))
			RenderingServer.canvas_item_add_texture_rect_region(item,target,ATLAS.get_rid(),source)
	if tile != 1:
		RenderingServer.canvas_item_add_rect(item,rect.grow(-corner),Color(0.018,0.012,0.008,0.34))
