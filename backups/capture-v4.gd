extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.story_pages.clear()
	game.refresh_story()
	game.extracted = true
	game.dash_unlocked = true
	game.player.position = Vector2(1560, 494)
	game.turret.clock = 1.5
	await physics_frame
	await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("D:/EdenGuilt/backups/preview-v4-warning.png")
	game.turret.clock = 2.3
	await physics_frame
	await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("D:/EdenGuilt/backups/preview-v4-firing.png")
	game.queue_free()
	await process_frame
	OS.delay_msec(100)
	quit()
