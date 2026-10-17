extends Node2D
## Side-scrolling acceptance room; no final art, enemies, combat or AI.

const PLATFORMS: Array[Rect2] = [
	Rect2(0, 620, 840, 100), Rect2(960, 620, 800, 100), Rect2(1880, 620, 760, 100),
	Rect2(300, 505, 170, 20), Rect2(620, 425, 160, 20),
	Rect2(1100, 505, 170, 20), Rect2(1430, 425, 170, 20),
	Rect2(2070, 500, 170, 20), Rect2(2300, 405, 160, 20),
]
const HAZARDS: Array[Rect2] = [Rect2(500, 598, 85, 22), Rect2(1300, 598, 85, 22), Rect2(2140, 598, 85, 22)]

@onready var player: CharacterBody2D = $Player
var _hazard_areas: Array[Area2D] = []


func _ready() -> void:
	for rect in PLATFORMS:
		_add_platform(rect)
	# Invisible end walls only contain the placeholder room.
	_add_platform(Rect2(-30, 0, 30, 840))
	_add_platform(Rect2(2640, 0, 30, 840))
	for rect in HAZARDS:
		_hazard_areas.append(_add_area(rect, "Hazard"))
	var pickups := [Vector2(380, 470), Vector2(700, 390), Vector2(1175, 470),
		Vector2(1515, 390), Vector2(2145, 465), Vector2(2380, 370)]
	for index in pickups.size():
		_add_pickup(pickups[index], index)
	var exit := _add_area(Rect2(2510, 520, 60, 100), "Exit")
	exit.body_entered.connect(_on_exit_entered)
	$GameplayBridge.bind_source(player.get_node("Stats"))
	_add_world_label(Vector2(60, 220), "遗庭 / 西侧回廊", 30)
	_add_world_label(Vector2(60, 265), "占位验证关卡   →   向右探索", 18)
	_add_world_label(Vector2(470, 550), "尖刺 -25", 16)
	_add_world_label(Vector2(865, 645), "深渊", 16)
	_add_world_label(Vector2(2420, 475), "出口 / VICTORY", 18)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	for area in _hazard_areas:
		if area.overlaps_body(player):
			player.hurt(25)
			break


func _add_platform(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _add_area(rect: Rect2, area_name: String) -> Area2D:
	var area := Area2D.new()
	area.name = area_name
	area.position = rect.get_center()
	area.collision_layer = 0
	area.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	return area


func _add_pickup(point: Vector2, index: int) -> void:
	var area := _add_area(Rect2(point - Vector2(15, 15), Vector2(30, 30)), "Shard%d" % index)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([Vector2(0, -15), Vector2(10, 0), Vector2(0, 15), Vector2(-10, 0)])
	gem.color = Color(0.91, 0.74, 0.4)
	area.add_child(gem)
	area.body_entered.connect(_on_pickup_entered.bind(area))


func _on_pickup_entered(body: Node2D, area: Area2D) -> void:
	if body != player or area.has_meta(&"collected") or GameSession.state != GameSession.State.PLAYING:
		return
	area.set_meta(&"collected", true)
	area.hide()
	player.stats.add_score(100)
	SoundManager.play_sfx(&"pickup", -6.0)
	area.queue_free()


func _on_exit_entered(body: Node2D) -> void:
	if body == player:
		GameSession.complete_level()


func _add_world_label(point: Vector2, text: String, font_size: int) -> void:
	var label := Label.new()
	label.position = point
	label.text = text
	label.theme = preload("res://assets/ui_theme.tres")
	label.add_theme_font_size_override(&"font_size", font_size)
	label.modulate = Color(0.58, 0.68, 0.65)
	add_child(label)


func _draw() -> void:
	# Modular stone silhouettes serve as temporary environment art.
	draw_rect(Rect2(0, 0, 2640, 840), Color(0.035, 0.055, 0.078))
	for x in range(60, 2640, 240):
		draw_rect(Rect2(x, 150, 70, 470), Color(0.055, 0.082, 0.105))
		draw_rect(Rect2(x - 14, 140, 98, 20), Color(0.08, 0.11, 0.13))
		draw_rect(Rect2(x + 18, 200, 34, 200), Color(0.07, 0.13, 0.15))
	draw_line(Vector2(0, 345), Vector2(2640, 345), Color(0.1, 0.15, 0.17), 2.0)
	for rect in PLATFORMS:
		draw_rect(rect, Color(0.13, 0.19, 0.21))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color(0.35, 0.46, 0.39))
		for x in range(int(rect.position.x) + 20, int(rect.end.x), 55):
			draw_line(Vector2(x, rect.position.y + 7), Vector2(x, rect.end.y), Color(0.09, 0.14, 0.17))
	for rect in HAZARDS:
		for x in range(int(rect.position.x), int(rect.end.x) - 10, 17):
			draw_colored_polygon(PackedVector2Array([Vector2(x, rect.end.y), Vector2(x + 8, rect.position.y), Vector2(x + 16, rect.end.y)]), Color(0.77, 0.35, 0.32))
	draw_rect(Rect2(2500, 510, 80, 110), Color(0.14, 0.3, 0.26))
	draw_rect(Rect2(2510, 520, 60, 100), Color(0.46, 0.72, 0.52), false, 3.0)
