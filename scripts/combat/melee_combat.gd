class_name MeleeCombat
extends Node2D
## Shared action lock prevents bypassing recovery by alternating the two templates.

signal attack_started(profile: MeleeAttackProfile)
signal target_hit(receiver: Node, hit: Dictionary)

@onready var close_attack: MeleeAttack = $CloseMelee
@onready var reach_attack: MeleeAttack = $ReachMelee
const INPUT_BUFFER := 0.14
var _queued: StringName = &""
var _buffer_left := 0.0
var _queued_facing := 1.0
var _availability: Callable


func _ready() -> void:
	for attack in [close_attack, reach_attack]:
		attack.attack_started.connect(func(move: MeleeAttackProfile) -> void: attack_started.emit(move))
		attack.target_hit.connect(func(receiver: Node, hit: Dictionary) -> void: target_hit.emit(receiver, hit))


func setup(source: Node2D, availability: Callable = Callable()) -> void:
	_availability = availability
	close_attack.setup(source, availability)
	reach_attack.setup(source, availability)


func is_busy() -> bool:
	return close_attack.is_busy() or reach_attack.is_busy()


func try_close(facing: float) -> bool:
	return not is_busy() and close_attack.try_attack(facing)


func try_reach(facing: float) -> bool:
	return not is_busy() and reach_attack.try_attack(facing)


func cancel() -> void:
	clear_buffer()
	close_attack.cancel()
	reach_attack.cancel()


func request_attack(reaching: bool, facing: float) -> bool:
	if not is_finite(facing) or facing == 0.0 or not _permitted():
		clear_buffer()
		return false
	var accepted := try_reach(facing) if reaching else try_close(facing)
	if accepted:
		clear_buffer()
		return true
	# One recent press survives the end of recovery; it never bypasses the lock.
	_queued = &"reach" if reaching else &"close"
	_queued_facing = facing
	_buffer_left = INPUT_BUFFER
	return false


func clear_buffer() -> void:
	_queued = &""
	_buffer_left = 0.0


func pause_impact(duration: float) -> void:
	for attack: MeleeAttack in [close_attack, reach_attack]:
		if attack.is_busy(): attack.impact_pause = maxf(attack.impact_pause, duration)


func _permitted() -> bool:
	return _availability.is_null() or (_availability.is_valid() and bool(_availability.call()))


func _physics_process(delta: float) -> void:
	if _queued == &"": return
	if not _permitted():
		clear_buffer()
		return
	if close_attack.impact_pause > 0.0 or reach_attack.impact_pause > 0.0: return
	_buffer_left -= delta
	if _buffer_left <= 0.0:
		clear_buffer()
	elif not is_busy():
		var reaching := _queued == &"reach"
		var facing := _queued_facing
		clear_buffer()
		if reaching: try_reach(facing)
		else: try_close(facing)
