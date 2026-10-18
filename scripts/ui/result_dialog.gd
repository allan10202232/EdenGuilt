extends Control


func _ready() -> void:
	%RestartButton.pressed.connect(_restart)
	%CheckpointButton.pressed.connect(_resume)
	%MenuButton.pressed.connect(_menu)


func present(result: Dictionary) -> void:
	var won: bool = result.get("won", false)
	%Title.text = "逃离遗庭" if won else "旅途终止"
	%Subtitle.text = "VICTORY / 挑战完成" if won else "GAME OVER / 检查点恢复"
	var halves := clampi(ceili(float(result.get("health", 0)) / maxi(1, int(result.get("max_health", 100))) * PlaceholderStats.LIFE_HALVES), 0, PlaceholderStats.LIFE_HALVES)
	var life_text := "%d 颗" % floori(float(halves) / 2.0)
	if halves % 2 == 1:
		life_text = "半颗" if halves == 1 else life_text + "半"
	%Summary.text = "得分  %04d\n剩余生命  %s\n用时  %.1f 秒" % [
		result.get("score", 0), life_text, result.get("elapsed_seconds", 0.0),
	]
	if result.has("audit"):
		%Summary.text+="\n累计排放 %.2f kg CO₂ · 已固定 %.2f kg"%[result.audit.gross_kg,result.audit.stored_kg]
	%CheckpointButton.visible = not won
	%CheckpointButton.text = "从%s检查点继续" % result.get("checkpoint", "孤木")
	%RecoveryNote.visible = not won
	show()
	if won:
		%RestartButton.grab_focus()
	else:
		%CheckpointButton.grab_focus()


func _resume() -> void:
	GameSession.resume_checkpoint()


func _restart() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	GameSession.restart_run()


func _menu() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	GameSession.return_to_menu()
