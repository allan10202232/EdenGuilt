class_name ForegroundGrowth
extends Node2D
## Sparse foreground leaves cover only the soles, leaving action silhouettes clear.
var points: Array[Vector2] = []
var region: StringName
var _clock := 0.0

func _init() -> void:
	z_index = 6

func _process(delta: float) -> void:
	if WorldProgress.can_play(): _clock += delta
	queue_redraw()

func _draw() -> void:
	var restored := WorldProgress.land_state(region) == &"restored"
	var faded := WorldProgress.land_state(region) == &"wasted"
	var tint := Color(0.31,0.46,0.20,0.9) if not faded else Color(0.37,0.35,0.27,0.85)
	if restored: tint = Color(0.30,0.62,0.28)
	for index in points.size():
		if index % 3 != 1: continue
		var root := points[index]
		var sway := roundf(sin(_clock*1.6+index)*2.0)
		for blade in 3:
			var top := root + Vector2((blade-1)*7+sway,-7-blade*3)
			draw_line(root,top,tint,2.0)
			draw_rect(Rect2(top.round(),Vector2(4,3)),tint)
