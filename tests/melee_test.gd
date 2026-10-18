extends Node
## Physical tests of both reusable prefabs plus their actual mouse/UI integration.

class AvailabilityOwner extends Node:
	func permits() -> bool:
		return true

var _checks: int = 0
var _failures: int = 0
var _guard: bool = true
var _arena: Node2D
var _source: MeleeDummy
var _combat: MeleeCombat
var _near: MeleeDummy
var _far: MeleeDummy
var _outside: MeleeDummy
var _behind: MeleeDummy
var _above: MeleeDummy
var _filtered: MeleeDummy


func _ready() -> void:
	get_tree().create_timer(40.0).timeout.connect(func() -> void:
		push_error("Melee test timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	_arena = Node2D.new()
	add_child(_arena)
	_source = _dummy(Vector2(300, 400))
	_combat = preload("res://scenes/combat/melee_combat.tscn").instantiate() as MeleeCombat
	_source.add_child(_combat)
	_combat.setup(_source, func() -> bool: return _guard)
	_combat.close_attack.profile = _combat.close_attack.profile.duplicate(true)
	_combat.reach_attack.profile = _combat.reach_attack.profile.duplicate(true)
	_near = _dummy(Vector2(365, 400))
	_far = _dummy(Vector2(455, 400))
	_outside = _dummy(Vector2(550, 400))
	_behind = _dummy(Vector2(235, 400))
	_above = _dummy(Vector2(365, 300))
	_filtered = _dummy(Vector2(370, 400))
	_filtered.get_node("Hurtbox").collision_layer = 8
	var extra := _near.get_node("Hurtbox").duplicate()
	extra.name = "SecondHurtbox"
	_near.add_child(extra)
	await _physics(3)
	_check(_combat.try_close(1.0), "close prefab starts")
	_check(_combat.close_attack.phase == MeleeAttack.Phase.WINDUP, "close starts in windup")
	_check(not _combat.try_close(1.0) and not _combat.try_reach(1.0), "both moves share action lock")
	await _physics(3)
	_check(_near.accepted_hits == 0, "close windup does not damage")
	await _physics(4)
	_check(_near.accepted_hits == 1, "close reaches nearby receiver")
	_check(_far.accepted_hits == 0 and _outside.accepted_hits == 0, "close cannot reach distant receivers")
	_check(_behind.accepted_hits == 0 and _above.accepted_hits == 0, "close excludes behind and outside height")
	_check(_source.accepted_hits == 0 and _filtered.accepted_hits == 0, "self and unrelated collision layer are excluded")
	_check(_near.last_hit.damage == 1 and _near.last_hit.attack_id == &"close_melee", "damage packet identifies close template")
	_check(_near.last_hit.source == _source and _near.last_hit.knockback.x > 0.0, "damage packet includes source and facing knockback")
	await _idle()
	_check(_near.accepted_hits == 1, "multiple hurtboxes and active frames still cause one hit")
	_reset_receivers()
	_check(_combat.try_reach(1.0), "long melee prefab starts")
	await _physics(10)
	_check(_near.accepted_hits == 0 and _far.accepted_hits == 0, "long melee has longer windup")
	await _physics(4)
	_check(_near.accepted_hits == 1 and _far.accepted_hits == 1, "long melee cleaves close and distant receivers")
	_check(_outside.accepted_hits == 0 and _behind.accepted_hits == 0, "long melee remains bounded and facing-dependent")
	_check(_far.last_hit.attack_id == &"reach_melee" and _far.last_hit.damage == 1, "long melee uses its own profile")
	_check(not _combat.try_close(1.0), "cannot skip long recovery with close attack")
	await _idle()
	_check(_far.accepted_hits == 1, "long attack does not repeat damage")
	_reset_receivers()
	var wall := _wall(Vector2(400, 400))
	await _physics(3)
	_combat.try_reach(1.0)
	await _physics(23)
	_check(_near.accepted_hits == 1 and _far.accepted_hits == 0, "wall blocks distant receiver while leaving near target hittable")
	await _idle()
	wall.queue_free()
	await _physics(3)
	_reset_receivers()
	_combat.try_reach(-1.0)
	await _physics(23)
	_check(_behind.accepted_hits == 1 and _near.accepted_hits == 0 and _far.accepted_hits == 0, "left-facing melee mirrors hitbox")
	_check(_behind.last_hit.knockback.x < 0.0, "left-facing knockback mirrors")
	await _idle()
	_reset_receivers()
	_guard = false
	_check(not _combat.try_close(1.0), "guard rejects attack when unavailable")
	_guard = true
	_combat.try_reach(1.0)
	await _physics(5)
	_guard = false
	await _physics(2)
	_check(not _combat.is_busy() and _near.accepted_hits == 0 and _far.accepted_hits == 0, "losing permission in windup cancels before damage")
	_guard = true
	var guard_owner := AvailabilityOwner.new()
	add_child(guard_owner)
	_combat.setup(_source, guard_owner.permits)
	guard_owner.queue_free()
	await _physics(2)
	_check(not _combat.try_close(1.0), "freed permission provider does not bypass attack guard")
	_combat.setup(_source, func() -> bool: return _guard)
	var preset := _combat.close_attack.profile
	_combat.try_close(1.0)
	preset.damage = 9
	preset.reach = 500.0
	await _physics(8)
	_check(_near.last_hit.damage == 1 and _far.accepted_hits == 0, "live attack snapshots shared profile values")
	preset.damage = 1
	preset.reach = 80.0
	await _idle()
	_reset_receivers()
	_combat.try_close(1.0)
	_source.position.x = 400.0
	await _physics(8)
	_check(_far.accepted_hits == 1 and _near.accepted_hits == 0, "melee volume follows moving attacker")
	await _idle()
	_source.position.x = 300.0
	_reset_receivers()
	_check(not _combat.try_close(0.0), "zero facing is rejected")
	preset.reach = 0.0
	_check(not _combat.try_close(1.0), "invalid profile is rejected")
	preset.reach = 80.0
	preset.windup = INF
	_check(not _combat.try_close(1.0), "non-finite timing is rejected")
	preset.windup = 0.06
	_combat.target_hit.connect(func(_receiver: Node, _hit: Dictionary) -> void: _combat.cancel(), CONNECT_ONE_SHOT)
	_combat.try_reach(1.0)
	await _physics(23)
	_check(not _combat.is_busy() and _near.accepted_hits + _far.accepted_hits == 1, "hit callback can cancel safely without subsequent damage")
	_arena.queue_free()
	await _physics(3)
	await _test_demo()
	await _test_menu_navigation()
	SoundManager.stop_sfx()
	await get_tree().create_timer(0.15).timeout
	print("MELEE: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_demo() -> void:
	var demo := preload("res://scenes/combat/melee_demo.tscn").instantiate()
	add_child(demo)
	await _physics(4)
	_check(WorldProgress.has_ability(&"light_blade"), "standalone test room enables trial blade")
	await _click(Vector2(700, 450), MOUSE_BUTTON_LEFT)
	await _physics(5)
	_check(demo.dummies[0].accepted_hits == 1 and demo.dummies[1].accepted_hits == 0, "left mouse executes close melee in test room")
	await _capture("06-close-melee")
	while demo.player.combat.is_busy():
		await _physics(1)
	await _click(demo.get_node("%ResetButton").get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _physics(4)
	_check(demo.dummies[0].accepted_hits == 0 and not demo.player.combat.is_busy(), "reset UI does not also attack")
	await _click(Vector2(700, 450), MOUSE_BUTTON_RIGHT)
	await _physics(12)
	_check(demo.dummies[0].accepted_hits == 1 and demo.dummies[1].accepted_hits == 1, "right mouse executes long melee in test room")
	_check(demo.dummies[2].accepted_hits == 0 and demo.dummies[3].accepted_hits == 0, "mouse-driven long melee excludes out-of-range and behind")
	await _capture("07-reach-melee")
	demo.player.combat.cancel()
	WorldProgress.set_light_blade_escape_ready(true)
	WorldProgress.return_ability(&"light_blade")
	await _click(Vector2(700, 450), MOUSE_BUTTON_RIGHT)
	await _physics(15)
	_check(not demo.player.combat.is_busy() and demo.dummies[1].accepted_hits == 1, "returning blade disables long melee input")
	GameSession.return_to_menu()
	demo.queue_free()
	await _physics(2)


func _test_menu_navigation() -> void:
	# Keep this runner as a root observer while testing real SceneTree navigation.
	get_tree().current_scene = null
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await _physics(4)
	var main := get_tree().current_scene
	_check(main != null and main.name == "Main", "main scene opens after training")
	var menu: Control = main.get_node("UI/Root/MainMenu")
	await _click(menu.get_node("%CombatDemoButton").get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _physics(4)
	var training := get_tree().current_scene
	_check(training != null and training.name == "MeleeDemo", "main menu button opens actual melee test room")
	await _click(training.get_node("%MenuButton").get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _physics(4)
	main = get_tree().current_scene
	_check(main != null and main.name == "Main" and GameSession.state == GameSession.State.MAIN_MENU, "training back button restores actual main menu")
	get_tree().current_scene = null
	main.queue_free()
	await _physics(2)


func _dummy(point: Vector2) -> MeleeDummy:
	var target := preload("res://scenes/combat/melee_dummy.tscn").instantiate() as MeleeDummy
	target.max_health = 100
	target.position = point
	_arena.add_child(target)
	return target


func _wall(point: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = point
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 180)
	collision.shape = shape
	body.add_child(collision)
	_arena.add_child(body)
	return body


func _reset_receivers() -> void:
	for dummy in [_source, _near, _far, _outside, _behind, _above, _filtered]:
		dummy.reset()


func _idle() -> void:
	for _index in 120:
		if not _combat.is_busy():
			return
		await _physics(1)
	_check(false, "attack returned to idle in bounded time")


func _physics(count: int) -> void:
	for _index in count:
		await get_tree().physics_frame
	await get_tree().process_frame


func _click(point: Vector2, button: MouseButton) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.position = point
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame


func _capture(label: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	var error := get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/%s.png" % label)
	_check(error == OK, "capture " + label)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
