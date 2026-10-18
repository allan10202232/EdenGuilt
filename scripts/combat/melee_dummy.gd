class_name MeleeDummy
extends Node2D
## Example damage receiver. Real enemies may replace this with their own health/AI.

signal damaged(hit: Dictionary)
signal defeated

@export var max_health: int = 1
var health: int = 1
var last_hit: Dictionary = {}
var accepted_hits: int = 0


func _ready() -> void:
	reset()


func is_alive() -> bool:
	return health > 0


func receive_melee_hit(hit: Dictionary) -> bool:
	var damage := int(hit.get("damage", 0))
	if not is_alive() or damage <= 0:
		return false
	health = maxi(0, health - damage)
	accepted_hits += 1
	last_hit = hit.duplicate()
	queue_redraw()
	damaged.emit(hit)
	if health == 0:
		defeated.emit()
	return true


func reset() -> void:
	health = maxi(1, max_health)
	accepted_hits = 0
	last_hit = {}
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-16, -24, 32, 48), Color(0.66, 0.39, 0.45) if is_alive() else Color(0.22, 0.25, 0.27))
	draw_rect(Rect2(-18, -35, 36, 5), Color(0.06, 0.09, 0.1))
	draw_rect(Rect2(-18, -35, 36.0 * health / maxi(1, max_health), 5), Color(0.7, 0.85, 0.68))
