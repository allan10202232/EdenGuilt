extends Node
## Persistent flow and read model. Gameplay owns its stats; UI observes these signals.

signal state_changed(previous: State, current: State)
signal health_changed(current: int, maximum: int)
signal score_changed(value: int)
signal run_finished(result: Dictionary)
signal checkpoint_resumed

enum State { MAIN_MENU, PLAYING, GAME_OVER, VICTORY }

var state: State = State.MAIN_MENU
var health: int = 100
var max_health: int = 100
var score: int = 0
var elapsed_seconds: float = 0.0
var last_result: Dictionary = {}
var _death_reason: StringName = &"damage"


func _process(delta: float) -> void:
	if WorldProgress.can_play():
		elapsed_seconds += delta


func start_run() -> void:
	if state == State.PLAYING:
		return
	health = 100
	max_health = 100
	score = 0
	elapsed_seconds = 0.0
	last_result = {}
	_death_reason = &"damage"
	WorldProgress.reset_run()
	CarbonLedger.begin_run(WorldProgress.campaign_rules)
	health_changed.emit(health, max_health)
	score_changed.emit(score)
	_set_state(State.PLAYING)


func restart_run() -> void:
	if state == State.GAME_OVER or state == State.VICTORY:
		start_run()


func return_to_menu() -> void:
	WorldProgress.set_shield_active(false)
	_set_state(State.MAIN_MENU)


func sync_health(current: int, maximum: int) -> void:
	if not WorldProgress.can_play():
		return
	max_health = maxi(1, maximum)
	health = clampi(current, 0, max_health)
	health_changed.emit(health, max_health)
	if health == 0:
		finish_run(false)


func sync_score(value: int) -> void:
	if not WorldProgress.can_play():
		return
	score = maxi(0, value)
	score_changed.emit(score)


func player_died(reason: StringName = &"damage") -> void:
	if WorldProgress.can_play():
		_death_reason = reason
		sync_health(0, max_health)


func apply_fall_penalty() -> bool:
	if not WorldProgress.can_play(): return false
	_death_reason=&"fall"
	sync_health(maxi(0,health-ceili(float(max_health)/5.0)),max_health)
	if health>0: _death_reason=&"damage"
	return health>0 and state==State.PLAYING


func resume_checkpoint() -> void:
	if state != State.GAME_OVER or not WorldProgress.restore_checkpoint():
		return
	health = max_health
	last_result = {}
	_death_reason = &"damage"
	health_changed.emit(health, max_health)
	score_changed.emit(score)
	_set_state(State.PLAYING)
	checkpoint_resumed.emit()


func stats_snapshot() -> Dictionary:
	return {"health": health, "max_health": max_health, "score": score}


func complete_level() -> void:
	finish_run(true)


func finish_run(won: bool) -> void:
	# Only the first terminal event wins; late collisions cannot replace the result.
	if state != State.PLAYING or WorldProgress.transitioning or WorldProgress.narrative_active or WorldProgress.extraction_active:
		return
	WorldProgress.set_shield_active(false)
	last_result = {
		"won": won, "health": health, "max_health": max_health,
		"score": score, "elapsed_seconds": elapsed_seconds,
		"death_reason": _death_reason, "checkpoint": WorldProgress.checkpoint_name(),
	}
	if CarbonLedger.enabled:
		last_result["audit"] = CarbonLedger.snapshot()
		last_result["ending"] = String(WorldProgress.ending_choice)
	_set_state(State.VICTORY if won else State.GAME_OVER)
	run_finished.emit(last_result.duplicate())


func _set_state(next: State) -> void:
	if state == next:
		return
	var previous := state
	state = next
	state_changed.emit(previous, state)
