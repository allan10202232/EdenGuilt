extends Node2D
## Three placeholder regions exercise B's interfaces; enemy/attack shapes are stubs.

@export var region_id: StringName = &"lone_tree"

const PLATFORMS: Array[Rect2] = [
	Rect2(0, 620, 840, 100), Rect2(960, 620, 800, 100), Rect2(1880, 620, 760, 100),
	Rect2(300, 505, 170, 20), Rect2(620, 425, 160, 20),
	Rect2(1100, 505, 170, 20), Rect2(1430, 425, 170, 20),
	Rect2(2070, 500, 170, 20), Rect2(2300, 405, 160, 20),
]
const HAZARDS: Array[Rect2] = [Rect2(500, 598, 85, 22), Rect2(1300, 598, 85, 22), Rect2(2140, 598, 85, 22)]

@onready var player: CharacterBody2D = $Player
var _hazard_areas: Array[Area2D] = []
var _mobs: Array[Area2D] = []
var _route_built: bool = false
var _region_ability: StringName
var _source_label: Label
var _hazard_label: Label


func _ready() -> void:
	_region_ability = AbilityCatalog.IDS[AbilityCatalog.REGIONS.find(region_id)]
	player.position = WorldProgress.spawn_position
	player.get_node("Camera2D").reset_smoothing()
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
	var entrance := _add_area(Rect2(25, 520, 35, 100), "Entrance")
	entrance.body_entered.connect(_on_entrance_entered)
	$GameplayBridge.bind_source(player.get_node("Stats"), true)
	WorldProgress.world_changed.connect(_refresh_world)
	player.slash_requested.connect(_on_slash)
	_add_mob(Vector2(740, 596), &"mob_0")
	_add_world_label(Vector2(60, 325), "遗庭 / %s" % AbilityCatalog.region_name(region_id), 28)
	_add_world_label(Vector2(60, 365), "E 吸收 / R 交还 · F1 光刃接口试用（地点待定）", 16)
	_add_source()
	_hazard_label = _add_world_label(Vector2(470, 550), "尖刺 -25", 16)
	_add_world_label(Vector2(865, 645), "深渊", 16)
	_add_world_label(Vector2(2380, 475), "折返起点 →" if region_id == &"remnant_sea" else "下一场景 →", 18)
	_refresh_world()


func _physics_process(_delta: float) -> void:
	if not WorldProgress.can_play():
		return
	if not WorldProgress.route_open(&"shield") or region_id != &"remnant_sea":
		for area in _hazard_areas:
			if area.overlaps_body(player):
				player.hurt(25)
				break
	for mob in _mobs:
		if is_instance_valid(mob) and not mob.has_meta(&"defeated") and mob.overlaps_body(player):
			player.hurt(25)
	if Input.is_action_just_pressed(&"eden_trial_blade") and OS.is_debug_build():
		WorldProgress.borrow_ability(&"light_blade")
	if player.position.distance_to(Vector2(220, 580)) < 95.0:
		if Input.is_action_just_pressed(&"eden_absorb"):
			WorldProgress.borrow_ability(_region_ability)
		elif Input.is_action_just_pressed(&"eden_return"):
			WorldProgress.return_ability(_region_ability)


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
	if WorldProgress.is_collected(_entity_id("shard_%d" % index)):
		return
	var area := _add_area(Rect2(point - Vector2(15, 15), Vector2(30, 30)), "Shard%d" % index)
	area.set_meta(&"persistent_id", _entity_id("shard_%d" % index))
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([Vector2(0, -15), Vector2(10, 0), Vector2(0, 15), Vector2(-10, 0)])
	gem.color = Color(0.91, 0.74, 0.4)
	area.add_child(gem)
	area.body_entered.connect(_on_pickup_entered.bind(area))


func _on_pickup_entered(body: Node2D, area: Area2D) -> void:
	if body != player or area.has_meta(&"collected") or not WorldProgress.can_play():
		return
	if not WorldProgress.collect_once(area.get_meta(&"persistent_id")):
		return
	area.set_meta(&"collected", true)
	area.hide()
	player.stats.add_score(100)
	SoundManager.play_sfx(&"pickup", -6.0)
	area.queue_free()


func _on_exit_entered(body: Node2D) -> void:
	if body != player:
		return
	var index := AbilityCatalog.REGIONS.find(region_id)
	if index < AbilityCatalog.REGIONS.size() - 1:
		WorldProgress.enter_scene(AbilityCatalog.REGIONS[index + 1], Vector2(100, 560))
	else:
		WorldProgress.begin_return_journey()


func _on_entrance_entered(body: Node2D) -> void:
	if body != player:
		return
	var index := AbilityCatalog.REGIONS.find(region_id)
	if index > 0:
		WorldProgress.enter_scene(AbilityCatalog.REGIONS[index - 1], Vector2(2450, 560))
	elif WorldProgress.required_returns_complete():
		GameSession.complete_level()
	else:
		WorldProgress.set_notice("返程交还二段跳、冲刺、护盾后，从这里回家。")


func _entity_id(local_id: String) -> StringName:
	return StringName("%s/%s" % [region_id, local_id])


func _add_source() -> void:
	var source := Polygon2D.new()
	source.position = Vector2(220, 590)
	source.polygon = PackedVector2Array([Vector2(-20, 10), Vector2(-14, -45), Vector2(14, -45), Vector2(20, 10)])
	source.color = Color(0.55, 0.7, 0.85)
	add_child(source)
	_source_label = _add_world_label(Vector2(140, 475), "", 16)


func _refresh_world() -> void:
	if _hazard_label != null:
		_hazard_label.text = "屏障保护" if region_id == &"remnant_sea" and WorldProgress.route_open(&"shield") else "尖刺 -25"
	if _source_label != null:
		var names := ["E 吸收", "R 交还", "已交还 / 通路恢复"]
		_source_label.text = "%s能力源\n%s" % [AbilityCatalog.DEFINITIONS[_region_ability].name, names[WorldProgress.ability_state(_region_ability)]]
	if WorldProgress.route_open(_region_ability) and not _route_built:
		_route_built = true
		_install_return_route.call_deferred()
	queue_redraw()


func _install_return_route() -> void:
	# Walkable bridges remain after abilities are returned, including on checkpoint reload.
	_add_platform(Rect2(840, 620, 120, 100))
	_add_platform(Rect2(1760, 620, 120, 100))
	queue_redraw()


func _add_mob(point: Vector2, local_id: StringName) -> void:
	if WorldProgress.is_enemy_defeated(_entity_id(local_id)):
		return
	var mob := _add_area(Rect2(point - Vector2(16, 24), Vector2(32, 48)), "Mob")
	mob.set_meta(&"persistent_id", _entity_id(local_id))
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-16, -24), Vector2(16, -24), Vector2(16, 24), Vector2(-16, 24)])
	visual.color = Color(0.66, 0.39, 0.45)
	mob.add_child(visual)
	_mobs.append(mob)


func _on_slash(facing: float) -> void:
	for mob in _mobs:
		if not is_instance_valid(mob) or mob.has_meta(&"defeated"):
			continue
		var distance: Vector2 = mob.position - player.position
		if distance.x * facing >= 0.0 and absf(distance.x) < 95.0 and absf(distance.y) < 65.0:
			if WorldProgress.mark_enemy_defeated(mob.get_meta(&"persistent_id")):
				mob.set_meta(&"defeated", true)
				mob.hide()
				mob.queue_free()


func _add_world_label(point: Vector2, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.position = point
	label.text = text
	label.theme = preload("res://assets/ui_theme.tres")
	label.add_theme_font_size_override(&"font_size", font_size)
	label.modulate = Color(0.58, 0.68, 0.65)
	add_child(label)
	return label


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
	if WorldProgress.land_state(region_id) == &"wasted":
		draw_rect(Rect2(0, 610, 2640, 6), Color(0.48, 0.3, 0.21))
	if _route_built:
		for x in [840, 1760]:
			draw_rect(Rect2(x, 620, 120, 100), Color(0.27, 0.44, 0.32))
		if region_id == &"remnant_sea":
			draw_rect(Rect2(0, 590, 2640, 6), Color(0.35, 0.67, 0.83))
			draw_rect(Rect2(0, 630, 2640, 8), Color(0.16, 0.4, 0.54))
	draw_rect(Rect2(2500, 510, 80, 110), Color(0.14, 0.3, 0.26))
	draw_rect(Rect2(2510, 520, 60, 100), Color(0.46, 0.72, 0.52), false, 3.0)
