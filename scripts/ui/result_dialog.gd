extends Control


func _ready() -> void:
	%RestartButton.pressed.connect(_restart)
	%MenuButton.pressed.connect(_menu)


func present(result: Dictionary) -> void:
	var won: bool = result.get("won", false)
	%Title.text = "逃离遗庭" if won else "旅途终止"
	%Subtitle.text = "VICTORY / 挑战完成" if won else "GAME OVER / 再试一次"
	%Summary.text = "得分  %04d\n剩余生命  %d / %d\n用时  %.1f 秒" % [
		result.get("score", 0), result.get("health", 0),
		result.get("max_health", 100), result.get("elapsed_seconds", 0.0),
	]
	show()
	%RestartButton.grab_focus()


func _restart() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	GameSession.restart_run()


func _menu() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	GameSession.return_to_menu()
