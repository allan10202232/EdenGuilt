class_name GothicSkin
extends RefCounted
## Shared vellum, leather and aged brass. Native text stays sharp at every size.
const IVORY := Color(0.9, 0.84, 0.7)
const GOLD := Color(0.73, 0.57, 0.32)
const MUTED := Color(0.78, 0.72, 0.59)
const MOSS := Color(0.58, 0.66, 0.4)
const INK := Color(0.22, 0.17, 0.12)
static var _panels: Dictionary = {}


static func panel(tile: int = 0, padding: int = 18) -> StyleBox:
	var key := Vector2i(tile, padding)
	if _panels.has(key):
		return _panels[key]
	var style := GothicFrame.new()
	style.tile = tile
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, padding)
	_panels[key] = style
	return style


static func diamond(canvas: CanvasItem, center: Vector2, radius: float, tint: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius * 0.65, 0),
		center + Vector2(0, radius), center + Vector2(-radius * 0.65, 0),
	]), tint)


static func draw_text(canvas: CanvasItem, font: Font, point: Vector2, text: String, font_size: int) -> void:
	canvas.draw_string_outline(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color.BLACK)
	canvas.draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color.WHITE)
