extends Node
## Quick preview borrows only the two abilities earned in previous chapters.
func _ready() -> void:
	get_window().title="EdenGuilt · Chapter 03 / EDEN"
	GameSession.start_run()
	WorldProgress.borrow_ability(&"light_blade")
	WorldProgress.borrow_ability(&"double_jump")
	WorldProgress.current_scene=&"grassland"
	WorldProgress.borrow_ability(&"mineralization")
	WorldProgress.current_scene=&"remnant_sea"
	var entry:=EdenBlueprint.ENTRY
	# Explicit preview flag only; the production chapter still begins at node 01.
	if "--boss-check" in OS.get_cmdline_user_args():
		get_window().title="EdenGuilt · Chapter 03 / Boss Check"
		WorldProgress.borrow_ability(&"shield")
		WorldProgress.borrow_ability(&"black_pierce")
		entry=Vector2(540,598)
		WorldProgress.eden_chapter.merge({"node":10,"checkpoint":entry,"mirror":true,"steward":true,"oren":true,"dual":true},true)
	WorldProgress.spawn_position=entry
	WorldProgress.set_checkpoint(&"eden/entrance",entry,"EDEN · 01" if entry==EdenBlueprint.ENTRY else "EDEN · BOSS CHECK")
	var app:=preload("res://scenes/main.tscn").instantiate()
	add_child(app)
