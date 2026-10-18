class_name FragileTiltPlatform
extends TimedCollapsePlatform
## Collision remains level and readable; only the scrap artwork tilts before breaking.

func _init() -> void:
	collapse_delay = 0.6
	tint = Color("c29a79")
	surface_style = &"appliance"

func _draw() -> void:
	if triggered and not fallen:
		var side := signf(actor.global_position.x - global_position.x) if is_instance_valid(actor) else 1.0
		draw_set_transform(Vector2.ZERO, side * minf(0.18, timer * 0.28), Vector2.ONE)
	super._draw()
	draw_set_transform(Vector2.ZERO)
