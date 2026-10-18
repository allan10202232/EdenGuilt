class_name ScrapyardParkourLevel
extends CampaignLevel
## Campaign-compatible procedural level; each mechanical prefab also runs alone.

const COLLAPSE_SCENE := preload("res://scenes/parkour/timed_collapse_platform.tscn")
const BELT_SCENE := preload("res://scenes/parkour/conveyor_belt.tscn")
const TILT_SCENE := preload("res://scenes/parkour/fragile_tilt_platform.tscn")
const LIFT_SCENE := preload("res://scenes/parkour/magnet_lift.tscn")
const CRUSHER_SCENE := preload("res://scenes/parkour/hydraulic_crusher.tscn")
var current_section := 0
var platforms: Array[ScrapPlatform] = []
var crushers: Array[HydraulicCrusher] = []
var _respawn_guard := 0.0
var _rescue_path := false
var _rescue_shape := PackedVector2Array()
var parkour_hud: ParkourHUD
var toxic_water: ScrapyardToxicWater

func _add_region_signs() -> void:
	# Section information lives in the HUD; keep the oasis and landing space clear.
	_label(Vector2(10,535),"START",13,Color("c4efb0"))

func _ready() -> void:
	super._ready()
	toxic_water = ScrapyardToxicWater.new()
	add_child(toxic_water)
	player.death_height = 900
	player.lethal_handler = respawn_player
	if player.position.x < 360 and player.position.y > 500:
		player.reset_at_checkpoint(ScrapyardLayout.SECTIONS[0].spawn)
	npc.position = Vector2(20,476)
	npc._prompt.position.x = 0
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = -600
	camera.limit_top = -100
	camera.limit_bottom = 1100
	camera.zoom = Vector2(0.8,0.8)
	camera.position = Vector2(100,120)
	camera.reset_smoothing()
	for point: Vector2 in ScrapyardLayout.COLLAPSE:
		_platform(COLLAPSE_SCENE, point, 110)
	for index in 3:
		var belt := _platform(BELT_SCENE, ScrapyardLayout.BELTS[index], 230) as ConveyorBelt
		belt.conveyor_speed = [110.0,-110.0,165.0][index]
		belt.scrap_interval = 2.7 + index * 0.3
	_platform(TILT_SCENE, Vector2(2080,540), 64)
	_platform(TILT_SCENE, Vector2(2520,520), 64)
	_platform(TILT_SCENE, Vector2(2910,590), 80)
	for point: Vector2 in ScrapyardLayout.TOWER:
		_platform(TILT_SCENE, point, 112)
	for index in 5:
		var lift := LIFT_SCENE.instantiate() as MagnetLift
		lift.position = ScrapyardLayout.LIFTS[index]
		lift.horizontal = index % 2 == 1
		add_child(lift)
		platforms.append(lift)
	for point: Vector2 in ScrapyardLayout.LOWER:
		_platform(COLLAPSE_SCENE, point, 90)
	for point: Vector2 in ScrapyardLayout.UPPER:
		var ledge := _platform(TILT_SCENE, point, 72)
		ledge.tint = Color("85e9c1")
	for point: Vector2 in ScrapyardLayout.CRUSHER_LEDGES:
		_platform(COLLAPSE_SCENE, point, 48)
	for index in 2:
		var crusher := CRUSHER_SCENE.instantiate() as HydraulicCrusher
		crusher.position.x = [6690,7260][index]
		crusher.phase_offset = index * 1.1
		add_child(crusher)
		crushers.append(crusher)
	for point: Vector2 in ScrapyardLayout.FINALE:
		var platform := _platform(COLLAPSE_SCENE, point, 84) as TimedCollapsePlatform
		platform.collapse_delay = 0.3
	# Full-height section triggers also catch players taking the upper crane route.
	var index := 0
	for node in get_children():
		if node is Area2D and String(node.name).begins_with("Checkpoint"):
			node.position = Vector2(ScrapyardLayout.SECTIONS[index].spawn.x,450)
			node.get_child(0).shape.size = Vector2(96,900)
			index += 1
	var entrance := get_node("Entrance") as Area2D
	entrance.position = Vector2(30,470)
	entrance.get_child(0).shape.size = Vector2(40,180)
	_exit_area.position = Vector2(9440,270)
	_exit_area.get_child(0).shape.size = Vector2(100,130)
	_label(Vector2(4660,125),ScrapyardLayout.text("↑ UPPER ROUTE", "↑ 高处路线"),17,Color("9eefd1"))
	_label(Vector2(6580,605),ScrapyardLayout.text("DELAY YOUR AIR JUMP", "延迟二段跳 · 等待回收"),15,Color("ffb38d"))
	# The shared campaign HUD now renders the same mine-style panel in all chapters.
	current_section = ScrapyardLayout.section_at(player.position.x)
	WorldProgress.set_checkpoint(StringName("lone_tree/parkour_%d" % current_section), ScrapyardLayout.SECTIONS[current_section].spawn, "Scrapyard · %d / 6" % (current_section + 1))
	if WorldProgress.returning: _build_rescue_path()

func _platform(scene: PackedScene, point: Vector2, size: float) -> ScrapPlatform:
	var platform := scene.instantiate() as ScrapPlatform
	platform.position = point
	platform.width = size
	add_child(platform)
	platforms.append(platform)
	return platform

func _process(delta: float) -> void:
	super._process(delta)
	if WorldProgress.can_play(): _respawn_guard = maxf(0.0, _respawn_guard - delta)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not WorldProgress.can_play(): return
	if WorldProgress.returning and not _rescue_path: _build_rescue_path.call_deferred()

func _on_checkpoint(body: Node2D, point: Vector2, index: int) -> void:
	if body != player or not WorldProgress.can_play(): return
	current_section = index
	WorldProgress.set_checkpoint(StringName("lone_tree/parkour_%d" % index), point, "Scrapyard · %d / 6" % (index + 1))

func _on_exit(body: Node2D) -> void:
	# Returning from the mine spawns on this island; do not bounce into it again.
	if WorldProgress.returning: return
	super._on_exit(body)

func respawn_player(_reason: StringName = &"toxic_drop") -> void:
	if not WorldProgress.can_play() or _respawn_guard > 0.0: return
	_respawn_guard = 0.18
	WorldProgress.scrapyard_deaths += 1
	var survived:=GameSession.apply_fall_penalty()
	player.stats.restore_stats(GameSession.stats_snapshot())
	if not survived: return
	# Surviving a fall preserves ability/carbon history and the remaining health.
	WorldProgress.restore_checkpoint()
	player.reset_at_checkpoint(WorldProgress.spawn_position)
	player.get_node("Camera2D").reset_smoothing()
	for platform in platforms: platform.reset_platform()
	for crusher in crushers: crusher.reset_hazard()

func _build_rescue_path() -> void:
	if _rescue_path: return
	_rescue_path = true
	for platform in platforms: platform.retire()
	for crusher in crushers: crusher.retire()
	# A continuous graded walkway works without jumping after the ability is returned.
	var tops := PackedVector2Array([Vector2(0,500),Vector2(360,500),Vector2(1500,580),Vector2(1690,580),Vector2(3000,650),Vector2(3170,650),Vector2(4400,520),Vector2(4580,520),Vector2(6200,520),Vector2(6400,520),Vector2(7800,560),Vector2(7980,560),Vector2(9320,320),Vector2(9600,320)])
	for index in tops.size()-1:
		var a := tops[index]
		var b := tops[index+1]
		var polygon := PackedVector2Array([a,b,b+Vector2(0,45),a+Vector2(0,45)])
		var body := StaticBody2D.new()
		var collision := CollisionPolygon2D.new()
		collision.polygon = polygon
		body.add_child(collision)
		add_child(body)
	_rescue_shape = tops
	WorldProgress.set_notice(ScrapyardLayout.text("The rescued residents have secured a continuous walkway. Head LEFT; return the air jump at the oasis with R.", "获救居民已铺好连续步道。向左返回绿洲，按 R 交还二段跳。"))

func _paint_platform(rect: Rect2, _restored: bool = false) -> void:
	ScrapyardSurface.deck(self,rect,rect.position.x)

func _draw() -> void:
	super._draw()
	if definition.is_empty(): return
	for info in ScrapyardLayout.SECTIONS:
		draw_line(Vector2(info.start,-100),Vector2(info.start,900),Color(0.6,0.8,0.7,0.08),2)
	for index in maxi(0,_rescue_shape.size()-1):
		draw_line(_rescue_shape[index]+Vector2(0,8),_rescue_shape[index+1]+Vector2(0,8),Color("3b6e5d"),20)
		draw_line(_rescue_shape[index],_rescue_shape[index+1],Color("a6e5a3"),5)
