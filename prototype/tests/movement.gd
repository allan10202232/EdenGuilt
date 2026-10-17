extends SceneTree

var game: Node
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func tick(count: int) -> void:
	for i in range(count):
		await physics_frame

func settle(pos: Vector2) -> void:
	game.player.position = pos
	game.player.velocity = Vector2.ZERO
	game.coyote = 0
	game.jump_buffer = 0
	game.air_used = false
	await tick(20)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await tick(3)
	game.story_pages.clear()
	game.refresh_story()
	game.extracted = true
	game.dash_unlocked = true
	game.turret.disabled = true
	await settle(Vector2(825, 470))
	Input.action_press("right")
	for i in range(15):
		await tick(1)
		if not game.player.is_on_floor():
			break
	Input.action_release("right")
	Input.action_press("jump")
	await tick(2)
	Input.action_release("jump")
	check(game.player.velocity.y < -350 and not game.air_used, "Late ground jump uses coyote time without consuming double jump")
	await settle(Vector2(300, 470))
	game.player.position = Vector2(300, 480)
	game.player.velocity = Vector2(0, 200)
	game.coyote = 0
	game.air_used = true
	await tick(1)
	Input.action_press("jump")
	await tick(6)
	Input.action_release("jump")
	check(game.player.velocity.y < -300, "Jump pressed before landing triggers on landing")
	await settle(Vector2(300, 470))
	Input.action_press("jump")
	await tick(3)
	Input.action_release("jump")
	await tick(8)
	Input.action_press("jump")
	await tick(2)
	Input.action_release("jump")
	check(game.air_used and game.player.velocity.y < -350, "Double jump still works after ground jump")
	await tick(5)
	Input.action_press("jump")
	await tick(2)
	Input.action_release("jump")
	check(game.player.velocity.y > -350, "Third jump is rejected")
	await settle(Vector2(1450, 470))
	game.facing = 1
	Input.action_press("right")
	Input.action_press("dash")
	await tick(2)
	Input.action_release("dash")
	check(game.dash_remaining > 0 and game.player.velocity.x > 1000, "Dash starts with high speed")
	await tick(16)
	check(game.dash_remaining == 0 and game.dash_cooldown > 0, "Dash ends and cooldown remains")
	Input.action_release("right")
	Input.action_press("dash")
	await tick(2)
	Input.action_release("dash")
	check(game.dash_remaining == 0, "Cooldown rejects repeated dash")
	await tick(55)
	check(game.dash_cooldown == 0, "Dash recharges")
	game.facing = -1
	Input.action_press("dash")
	await tick(2)
	Input.action_release("dash")
	check(game.player.velocity.x < -1000, "Dash follows left-facing direction")
	await tick(60)
	game.turret.disabled = false
	game.turret.active = true
	game.turret.clock = 1.4
	check(game.turret.phase() == "warning" and not game.turret.hits(Vector2(1740, 490), Vector2(1740, 490)), "Yellow warning is harmless")
	game.turret.clock = 2.3
	check(game.turret.hits(Vector2(1600, 490), Vector2(1900, 490)), "Beam checks fast swept crossings")
	check(not game.turret.hits(Vector2(1600, 200), Vector2(1900, 200)), "Beam ignores movement above danger zone")
	await settle(Vector2(1610, 470))
	game.health = 3
	game.invulnerable = 0
	game.dash_cooldown = 0
	game.turret.clock = 2.21
	game.facing = 1
	Input.action_press("right")
	Input.action_press("dash")
	await tick(16)
	Input.action_release("dash")
	Input.action_release("right")
	check(game.player.position.x > 1835 and game.health == 3, "Dash crosses active beam without damage")
	game.player.position = Vector2(1740, 490)
	game.player.velocity = Vector2.ZERO
	game.invulnerable = 0
	game.turret.clock = 2.21
	await tick(3)
	check(game.health == 2 and game.invulnerable > 0, "Beam damages unprotected player")
	await tick(20)
	check(game.health == 2, "Post-hit invulnerability prevents repeated damage")
	game.health = 1
	game.invulnerable = 0
	game.hurt_remaining = 0
	game.player.position = Vector2(1740, 490)
	game.checkpoint = Vector2(1420, 450)
	game.turret.clock = 2.21
	await tick(3)
	check(game.health == 3 and game.player.position.x == 1420 and game.invulnerable > 0, "Lethal hit resets health and returns to safe checkpoint")
	check(game.extracted and game.dash_unlocked and game.dash_remaining == 0, "Death preserves abilities and clears movement state")
	var clock: float = game.turret.clock
	var pause_pages: Array[String] = ["Pause test"]
	game.show_story(pause_pages)
	await tick(30)
	check(game.turret.clock == clock, "Narrative pauses turret cycle")
	game.story_pages.clear()
	game.refresh_story()
	game.begin_rescue()
	game.story_pages.clear()
	game.refresh_story()
	game.player.position = Vector2(1740, 490)
	await tick(240)
	check(game.health == 3 and game.turret.phase() == "disabled", "Return route remains safe across multiple firing cycles")
	print("Movement checks complete. Failures: ", failures)
	game.queue_free()
	await tick(3)
	OS.delay_msec(100)
	quit(1 if failures else 0)
