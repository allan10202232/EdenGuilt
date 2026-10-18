class_name ScrapyardToxicWater
extends Node2D
## Presentation only. The level's Y > 900 fall rule remains the lethal boundary.
const SURFACE_Y := 900.0
const LEFT := -1000.0
const RIGHT := 10600.0
const DEPTH := 900.0
var _clock := 0.0
var _update_left := 0.0
var _body: Polygon2D

func _ready() -> void:
	position.y = SURFACE_Y
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body = Polygon2D.new()
	_body.z_index = -1
	var water := ShaderMaterial.new()
	water.shader = preload("res://assets/shaders/scrapyard_water.gdshader")
	_body.material = water
	add_child(_body)
	_update_surface()

func _process(delta: float) -> void:
	if not WorldProgress.can_play(): return
	_clock += delta
	_body.material.set_shader_parameter(&"clock", _clock)
	_update_left -= delta
	if _update_left <= 0.0:
		_update_left = 0.05
		_update_surface()
		queue_redraw()

func surface_height(x: float) -> float:
	return snappedf(sin(x * 0.016 + _clock * 1.5) * 4.0
		+ sin(x * 0.043 - _clock * 2.1) * 2.0
		+ sin(x * 0.007 + _clock * 0.8) * 3.0, 2.0)

func _update_surface() -> void:
	var contour := PackedVector2Array()
	for x in range(int(LEFT), int(RIGHT), 12):
		var y := surface_height(x)
		contour.append(Vector2(x, y))
		contour.append(Vector2(x + 12, y))
	contour.append(Vector2(RIGHT, DEPTH))
	contour.append(Vector2(LEFT, DEPTH))
	_body.polygon = contour

func _draw() -> void:
	# Broken foam follows the moving crest, instead of a solid fluorescent bar.
	for x in range(int(LEFT), int(RIGHT), 24):
		var phase := sin(x * 0.17 + _clock * 0.7)
		var top := Vector2(x, surface_height(x))
		draw_line(top, top + Vector2(12, 0), Color("779552"), 3)
		if phase > -0.15:
			draw_line(top + Vector2(2, -1), top + Vector2(8 + phase * 6, -1), Color("a6be6d"), 2)
		if phase > 0.65:
			draw_line(top + Vector2(5, 10), top + Vector2(19, 10), Color(0.56, 0.67, 0.31, 0.45), 2)
	# Bubbles rise at different speeds; an expanding ring marks each surface pop.
	for index in range(-8, 89):
		var cycle := fposmod(_clock * (0.18 + posmod(index, 5) * 0.025) + index * 0.618, 1.0)
		var x := index * 120.0 + sin(index * 7.3) * 35.0 + sin(_clock + index) * 5.0
		var crest := surface_height(x)
		var radius := 2.0 + posmod(index, 4)
		if cycle < 0.88:
			var y := crest + lerpf(65, 3, cycle / 0.88)
			draw_arc(Vector2(x, y), radius, 0, TAU, 10, Color(0.55, 0.67, 0.29, cycle * 0.6), 1)
		else:
			var pop := (cycle - 0.88) / 0.12
			draw_set_transform(Vector2(x, crest + 2), 0, Vector2(1, 0.3))
			draw_arc(Vector2.ZERO, radius + pop * 13, 0, TAU, 12, Color(0.66, 0.76, 0.4, 1.0 - pop), 2)
			draw_set_transform(Vector2.ZERO)
