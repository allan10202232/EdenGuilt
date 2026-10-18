class_name MeleeCombat
extends Node2D
## Shared action lock prevents bypassing recovery by alternating the two templates.

signal attack_started(profile: MeleeAttackProfile)
signal target_hit(receiver: Node, hit: Dictionary)

@onready var close_attack: MeleeAttack = $CloseMelee
@onready var reach_attack: MeleeAttack = $ReachMelee


func _ready() -> void:
	for attack in [close_attack, reach_attack]:
		attack.attack_started.connect(func(move: MeleeAttackProfile) -> void: attack_started.emit(move))
		attack.target_hit.connect(func(receiver: Node, hit: Dictionary) -> void: target_hit.emit(receiver, hit))


func setup(source: Node2D, availability: Callable = Callable()) -> void:
	close_attack.setup(source, availability)
	reach_attack.setup(source, availability)


func is_busy() -> bool:
	return close_attack.is_busy() or reach_attack.is_busy()


func try_close(facing: float) -> bool:
	return not is_busy() and close_attack.try_attack(facing)


func try_reach(facing: float) -> bool:
	return not is_busy() and reach_attack.try_attack(facing)


func cancel() -> void:
	close_attack.cancel()
	reach_attack.cancel()
