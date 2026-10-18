extends Node
## F6 / CLI entry: play the actual campaign's first level, without replaying the intro.
@export_range(1,6) var start_section := 1

func _ready() -> void:
	var app := preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	GameSession.start_run()
	if start_section>1:
		# A separate review scene opens section 5 without replaying the earlier route.
		WorldProgress.borrow_ability(&"double_jump")
		var level: ScrapyardParkourLevel=app.get_node("LevelRoot").get_child(0)
		var point: Vector2=ScrapyardLayout.SECTIONS[start_section-1].spawn
		level.player.reset_at_checkpoint(point)
		level._on_checkpoint(level.player,point,start_section-1)
		level.player.get_node("Camera2D").reset_smoothing()
	_set_preview_title.call_deferred()

func _set_preview_title() -> void:
	get_window().title = "EdenGuilt - Crusher Test (Section 5)" if start_section==5 else "EdenGuilt - Scrapyard Parkour Preview"
