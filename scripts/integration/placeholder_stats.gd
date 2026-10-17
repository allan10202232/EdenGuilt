class_name PlaceholderStats
extends Node
## Minimal data source for B's acceptance room. Replace with A's implementation.

signal health_changed(current: int, maximum: int)
signal score_changed(value: int)
signal died

@export var max_health: int = 100
var health: int = 100
var score: int = 0


func _ready() -> void:
	max_health = maxi(1, max_health)
	health = max_health


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
