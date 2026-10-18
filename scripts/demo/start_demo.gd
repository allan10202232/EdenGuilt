extends Node
## F6 entry skips the prologue and starts the real campaign with demo shortcuts.
func _ready() -> void:
	var app:=preload("res://scenes/main.tscn").instantiate()
	app.demo_shortcuts_enabled=true
	add_child(app)
	GameSession.start_run()
