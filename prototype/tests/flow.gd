extends SceneTree

var game: Node
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: ", description)

func tick(count: int) -> void:
	for i in range(count):
		await physics_frame

func dismiss() -> void:
	game.story_pages.clear()
	game.refresh_story()

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await tick(3)
	check(game.story_panel.visible, "Opening narrative is visible")
	var start: Vector2 = game.player.position
	Input.action_press("right")
	await tick(10)
	Input.action_release("right")
	check(game.player.position == start, "Narrative pauses movement")
	dismiss()
	game.player.position = Vector2(670, 470)
	await tick(20)
	Input.action_press("interact")
	await tick(30)
	Input.action_release("interact")
	await tick(3)
	check(not game.extracted and game.hold_time == 0, "Interrupted extraction cancels")
	Input.action_press("interact")
	await tick(95)
	Input.action_release("interact")
	check(game.extracted and game.extraction_scene > 0, "Extraction starts visible destruction sequence")
	await tick(150)
	check(game.cost_seen and game.story_panel.visible, "Cost narrative follows destruction sequence")
	check(game.birds.volume_db == -80, "Bird sound disappears after extraction")
	dismiss()
	game.player.position = Vector2(700, 900)
	await tick(3)
	check(game.player.position.y < 600 and game.extracted, "Fall preserves acquired ability")
	game.player.position = Vector2(1420, 470)
	await tick(5)
	check(game.dash_unlocked and game.story_panel.visible, "Crossing gap introduces independent dash module")
	dismiss()
	game.player.position = Vector2(1950, 470)
	await tick(5)
	check(game.passed_turret and game.checkpoint.x == 1950, "Clearing turret updates safe checkpoint")
	game.player.position = Vector2(2260, 470)
	await tick(5)
	check(game.eden_reached and not game.returning and game.story_panel.visible, "Eden reveals captives without automatic rescue")
	dismiss()
	await tick(20)
	Input.action_press("interact")
	await tick(30)
	Input.action_release("interact")
	await tick(3)
	check(not game.returning and game.rescue_progress == 0, "Interrupted rescue cancels")
	Input.action_press("interact")
	await tick(95)
	Input.action_release("interact")
	check(game.returning and game.companions.size() == 3, "Opening chambers rescues three companions")
	check(game.turret.disabled and not game.turret.hits(Vector2(1700, 490), Vector2(1780, 490)), "Rescue disables turret for return route")
	dismiss()
	game.player.position = Vector2(1210, 470)
	await tick(330)
	var safe = true
	for companion in game.companions:
		safe = safe and companion.x >= 1160
	check(safe, "Companions wait at the gap until a bridge exists")
	Input.action_press("interact")
	await tick(95)
	Input.action_release("interact")
	check(game.restored and game.bridge.visible, "Restoration enables bridge")
	dismiss()
	await tick(3)
	check(not game.bridge.get_child(0).disabled, "Bridge collision is enabled")
	game.player.position = Vector2(980, 470)
	await tick(30)
	check(game.player.is_on_floor(), "Player can stand on restored bridge")
	game.player.position = Vector2(180, 470)
	await tick(300)
	check(game.finished and game.story_panel.visible, "Home triggers ending narrative")
	dismiss()
	await tick(3)
	check(game.finished and not game.story_panel.visible, "Ending can close without restarting")
	print("Flow checks complete. Failures: ", failures)
	game.queue_free()
	await tick(3)
	# Fixed-fps headless frames outrun the audio mixer; allow its cleanup to finish.
	OS.delay_msec(100)
	quit(1 if failures else 0)
