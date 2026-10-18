class_name ConveyorBelt
extends ScrapPlatform

@export var conveyor_speed := 110.0
@export var scrap_interval := 2.7
var drop_clock := 0.0
var falling_scrap: Array[Dictionary] = []

func _init() -> void:
	width = 230
	tint = Color("69adcc")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if retired or not WorldProgress.can_play(): return
	# Avoid firing machines two screens away and preserve the rhythm during dialogue.
	if not is_instance_valid(actor) or absf(actor.global_position.x - global_position.x) > 780: return
	drop_clock = fmod(drop_clock + delta, scrap_interval)
	if drop_clock < delta:
		falling_scrap.append({"y": -320.0, "speed": 0.0, "hit": false})
	for scrap in falling_scrap:
		scrap.speed += 700 * delta
		scrap.y += scrap.speed * delta
		if not scrap.hit and Rect2(global_position + Vector2(-12, scrap.y - 10), Vector2(24, 24)).intersects(Rect2(actor.global_position - Vector2(14,24), Vector2(28,48))):
			scrap.hit = true
			actor.hurt()
	falling_scrap = falling_scrap.filter(func(scrap: Dictionary) -> bool: return scrap.y < 450 and not scrap.hit)

func surface_velocity() -> float:
	return conveyor_speed if not retired else 0.0

func reset_platform() -> void:
	falling_scrap.clear()
	drop_clock = 0.0
	super.reset_platform()

func _draw() -> void:
	paint_deck(Vector2.ZERO, tint)
	draw_rect(Rect2(-width/2+3,3,width-6,15),Color("222d29"))
	for x in range(int(-width/2)+8,int(width/2),18):
		draw_rect(Rect2(x,5,11,10),Color("535845"))
		draw_line(Vector2(x,5),Vector2(x+9,5),Color("8f8d62"),2)
	var offset := fposmod(clock * conveyor_speed, 30)
	for x in range(int(-width / 2) - 30, int(width / 2), 30):
		var point := Vector2(clampf(x + offset, -width / 2 + 6, width / 2 - 8), 10)
		var arrow := signf(conveyor_speed) * 6
		draw_polyline(PackedVector2Array([point + Vector2(-arrow, -4), point, point + Vector2(-arrow, 4)]), Color("d4c27d"), 2)
	var warning := drop_clock > scrap_interval - 0.65
	draw_colored_polygon(PackedVector2Array([Vector2(-29,-358),Vector2(29,-358),Vector2(19,-322),Vector2(-19,-322)]),Color("52523b"))
	draw_texture_rect_region(ScrapyardSurface.TERRAIN,Rect2(-28,-358,56,36),Rect2(230,1046,156,100),Color(0.8,0.75,0.6))
	draw_rect(Rect2(-8,-330,16,7),Color("f5a243") if warning else Color("8e7547"))
	if warning:
		draw_line(Vector2(0,-318), Vector2(0, 6), Color(1, 0.55, 0.12, 0.35 + 0.2 * sin(clock * 22)), 3)
		draw_colored_polygon(PackedVector2Array([Vector2(-10,-290), Vector2(10,-290), Vector2(0,-275)]), Color("ffd079"))
	for scrap in falling_scrap:
		draw_colored_polygon(PackedVector2Array([Vector2(-10,scrap.y-8),Vector2(5,scrap.y-11),Vector2(12,scrap.y+4),Vector2(1,scrap.y+10),Vector2(-9,scrap.y+5)]),Color("956743"))
		draw_polyline(PackedVector2Array([Vector2(-7,scrap.y+6),Vector2(-3,scrap.y-6),Vector2(7,scrap.y-5)]),Color("d4ab6a"),3)
