extends Node
## Runs the prologue before creating the playable campaign.

const GAME_SCENE := "res://scenes/main.tscn"

var _starting_game := false


func _ready() -> void:
	$OpeningCinematic.sequence_finished.connect(_start_game)
	# Opt-in validation runs against the exact exported resources and native runtime.
	if "--export-smoke-test" in OS.get_cmdline_user_args():
		var verifier := preload("res://scripts/distribution/export_smoke.gd").new()
		get_tree().root.add_child.call_deferred(verifier)
	# Release templates reject external scene overrides. Use the normal entry's
	# explicit demo flag instead, so packaged presentations can skip the prologue.
	if "--demo" in OS.get_cmdline_user_args():
		_start_game()


func _start_game() -> void:
	if _starting_game:
		return
	_starting_game = true
	# The ledger must see the campaign rules when the run is initialized.
	WorldProgress.campaign_rules = true
	GameSession.start_run()
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
