class_name TimedCollapsePlatform
extends ScrapPlatform

@export var collapse_delay := 0.45
@export var respawn_delay := 2.5
var triggered := false
var fallen := false
var timer := 0.0
var fall_time := 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if retired or not WorldProgress.can_play(): return
	if not triggered and occupied(): triggered = true
	if triggered:
		timer += delta
		if not fallen and timer >= collapse_delay:
			fallen = true
			shape_node.set_deferred("disabled", true)
		if fallen:
			fall_time += delta
			if fall_time >= respawn_delay: reset_platform()

func reset_platform() -> void:
	triggered = false
	fallen = false
	timer = 0.0
	fall_time = 0.0
	super.reset_platform()
	queue_redraw()

func _draw() -> void:
	var shake := Vector2(sin(clock * 83) * 3, cos(clock * 71) * 2) if triggered and not fallen else Vector2.ZERO
	var offset := shake + Vector2(0, fall_time * fall_time * 550)
	if fall_time > 0.8:
		draw_rect(Rect2(-width / 2, 0, width, 3), Color(0.8, 0.65, 0.4, 0.2))
		return
	paint_deck(offset, Color("ff913f") if triggered else tint)
	if triggered:
		draw_line(offset + Vector2(-width / 2, -5), offset + Vector2(width / 2 - width * clampf(timer / collapse_delay, 0, 1), -5), Color("ffdd89"), 3)
	else:
		for x in range(int(-width / 2) + 12, int(width / 2), 25):
			draw_line(Vector2(x, 23), Vector2(x + 6, 31), Color("68685c"), 3)
