extends Node
## Runs the prologue before creating the playable campaign.

const GAME_SCENE := "res://scenes/main.tscn"

var _starting_game := false


func _ready() -> void:
	$OpeningCinematic.sequence_finished.connect(_start_game)


func _start_game() -> void:
	if _starting_game:
		return
	_starting_game = true
	# The ledger must see the campaign rules when the run is initialized.
	WorldProgress.campaign_rules = true
	GameSession.start_run()
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
