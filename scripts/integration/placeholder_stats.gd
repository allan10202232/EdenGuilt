class_name PlaceholderStats
extends Node
## Minimal data source for B's acceptance room. Replace with A's implementation.

signal health_changed(current: int, maximum: int)
signal score_changed(value: int)
signal died

const LIFE_ORB_COUNT := 5
const LIFE_HALVES := LIFE_ORB_COUNT * 2

@export var max_health: int = 100
var health: int = 100
var score: int = 0


func _ready() -> void:
	max_health = maxi(1, max_health)
	health = max_health


func restore_stats(snapshot: Dictionary) -> void:
	max_health = maxi(1, int(snapshot.get("max_health", max_health)))
	health = clampi(int(snapshot.get("health", max_health)), 0, max_health)
	score = maxi(0, int(snapshot.get("score", 0)))
	health_changed.emit(health, max_health)
	score_changed.emit(score)


func take_hit() -> void:
	# All normal enemy and hazard hits consume exactly half of one life orb.
	take_damage(maxi(1, ceili(float(max_health) / LIFE_HALVES)))


func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0 or GameSession.state != GameSession.State.PLAYING:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()


func heal(amount: int) -> void:
	if health <= 0 or amount <= 0 or GameSession.state != GameSession.State.PLAYING:
		return
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func add_score(amount: int) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	score = maxi(0, score + amount)
	score_changed.emit(score)
