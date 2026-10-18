extends RefCounted
## Isolated mechanism fixtures use the real acquisition, then continue placements.
static func acquire(level: Node2D,tree: SceneTree) -> void:
	if WorldProgress.has_ability(&"mineralization"): return
	level.player.position=Vector2(420,1778)
	level.player.velocity=Vector2.ZERO
	for frame in 5: await tree.physics_frame
	Input.action_press(&"eden_absorb")
	await tree.physics_frame
	Input.action_release(&"eden_absorb")
	for frame in 155: await tree.physics_frame
	await tree.process_frame
