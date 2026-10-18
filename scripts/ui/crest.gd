extends Control
## Small carved seed and thorn crest, drawn at native UI resolution.


func _draw() -> void:
	var center := size * 0.5
	GothicSkin.diamond(self, center, 17, Color(0.47, 0.13, 0.12))
	GothicSkin.diamond(self, center, 9, GothicSkin.GOLD)
	for direction in [-1, 1]:
		var stem := PackedVector2Array()
		for index in 13:
			var angle := -0.8+index*0.13
			stem.append(center+Vector2(direction*(14+cos(angle)*4),sin(angle)*22))
		draw_polyline(stem,GothicSkin.GOLD,1,true)
		for index in 4:
			var root := center+Vector2(direction*17,-14+index*9)
			draw_line(root,root+Vector2(direction*6,-4),GothicSkin.GOLD,1,true)
