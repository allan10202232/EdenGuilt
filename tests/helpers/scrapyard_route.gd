extends Node
## Shared input-only driver for the six-section acceptance and campaign walkthroughs.
var app: Node
var checks := 0
var failures := 0
var report: Callable
var shots: Callable

func run(upper: bool) -> void:
	for point: Vector2 in ScrapyardLayout.COLLAPSE: await leap(point)
	await leap(ScrapyardLayout.SECTIONS[1].spawn+Vector2(0,24))
	await capture("02-conveyors")
	for point: Vector2 in [ScrapyardLayout.BELTS[0],Vector2(2080,540),ScrapyardLayout.BELTS[1],Vector2(2520,520),ScrapyardLayout.BELTS[2],Vector2(2910,590),Vector2(3070,650)]: await leap(point)
	await capture("03-tower")
	for point: Vector2 in ScrapyardLayout.TOWER: await leap(point)
	await leap(Vector2(4470,520))
	await capture("04-magnets")
	var lifts: Array = level().platforms.filter(func(p: ScrapPlatform) -> bool: return p is MagnetLift)
	# Time the first landing for the bottom of its 2.4 s stroke.
	await leap(Vector2.ZERO,lifts[0])
	if upper:
		for frame in 144:
			if lifts[0].position.y<255: break
			await ticks(1)
		for point: Vector2 in ScrapyardLayout.UPPER: await leap(point)
	else:
		for index in 4:
			await leap(ScrapyardLayout.LOWER[index])
			await leap(Vector2.ZERO,lifts[index+1])
	await leap(Vector2(6270,520))
	await capture("05-crushers")
	for point: Vector2 in ScrapyardLayout.CRUSHER_LEDGES: await leap(point)
	await leap(Vector2(7870,560))
	await capture("06-final-sprint")
	for point: Vector2 in ScrapyardLayout.FINALE: await leap(point)
	await leap(Vector2(9380,320))
	await capture("07-exit")
	Input.action_press(&"eden_move_right")
	await ticks(20)
	Input.action_release(&"eden_move_right")

func leap(point: Vector2, moving: ScrapPlatform = null) -> void:
	if failures: return
	var deaths: int = WorldProgress.scrapyard_deaths
	var origin := player().position
	if moving != null and moving == level().platforms.filter(func(p: ScrapPlatform) -> bool: return p is MagnetLift)[0]:
		# Start 0.7 s before its next bottom. Physics carries the actor on landing.
		for frame in 150:
			var previous: float=moving.position.y
			await ticks(1)
			if moving.position.y>310 and moving.position.y>previous: break
	Input.action_press(&"eden_jump")
	var air_used := false
	for frame in 150:
		if moving != null: point = moving.global_position
		var dx := point.x-player().position.x
		Input.action_release(&"eden_move_left")
		Input.action_release(&"eden_move_right")
		if absf(dx)>3: Input.action_press(&"eden_move_right" if dx>0 else &"eden_move_left")
		if frame==2: Input.action_release(&"eden_jump")
		if frame==25:
			Input.action_press(&"eden_jump")
			air_used=true
		if frame==27: Input.action_release(&"eden_jump")
		await ticks(1)
		if WorldProgress.current_scene!=&"lone_tree": break
		if WorldProgress.scrapyard_deaths>deaths: break
		if frame>10 and player().is_on_floor() and absf(player().position.y+24-point.y)<9 and absf(player().position.x-point.x)<65:
			break
	Input.action_release(&"eden_jump")
	Input.action_release(&"eden_move_left")
	Input.action_release(&"eden_move_right")
	check(WorldProgress.current_scene!=&"lone_tree" or (WorldProgress.scrapyard_deaths==deaths and player().is_on_floor() and absf(player().position.y+24-point.y)<10),"physical leap %s → %s (at %s; air %s)" % [origin,point,player().position,air_used])

func level() -> Node2D: return app.get_node("LevelRoot").get_child(0)
func player() -> CharacterBody2D: return level().player
func ticks(count: int) -> void:
	for frame in count: await get_tree().physics_frame
	# Scene navigation now includes a visible fade and a short re-entry lock.
	while WorldProgress.scene_transition_active or WorldProgress.transition_rearm_seconds>0:
		await get_tree().physics_frame
	await get_tree().process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	if report.is_valid(): report.call(ok,message)
func capture(id: String) -> void:
	if shots.is_valid(): await shots.call(id)
