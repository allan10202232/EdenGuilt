extends Node
## Preview the reported ledge without replaying earlier chapters. Deliberately
## leave the lever / checkpoint in stage 5 so the real entry repair must run.
func _ready() -> void:
	get_window().title="EdenGuilt · Mine / Cliff Supply Check"
	GameSession.start_run()
	WorldProgress.borrow_ability(&"double_jump")
	WorldProgress.borrow_ability(&"light_blade")
	WorldProgress.current_scene=&"grassland"
	WorldProgress.borrow_ability(&"mineralization")
	WorldProgress.mine_challenge={"stage":5,"lever":false,"valve":true}
	var app:=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
	var level: Node2D=app.get_node("LevelRoot").get_child(0)
	level.player.position=Vector2(4500,1678)
	level.player.get_node("Camera2D").reset_smoothing()
