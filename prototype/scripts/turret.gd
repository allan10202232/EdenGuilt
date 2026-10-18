extends Node2D

const PERIOD = 3.8
const WARNING_START = 1.2
const FIRE_START = 2.2
const FIRE_END = 2.9
const DANGER = Rect2(1660, 300, 160, 220)
var clock = 0.0
var disabled = false
var active = false
var warning_label: Label
var warning_panel: ColorRect

func _ready() -> void:
	warning_panel = ColorRect.new()
	warning_panel.position = Vector2(1520, 315)
	warning_panel.size = Vector2(440, 72)
	warning_panel.color = Color(0.025, 0.035, 0.055, 0.95)
	add_child(warning_panel)
	warning_label = Label.new()
	warning_label.position = Vector2(10, 8)
	warning_label.size = Vector2(420, 56)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 20)
	warning_panel.add_child(warning_label)

func advance(delta: float, in_range: bool) -> void:
	active = in_range and not disabled
	if active:
		clock = fmod(clock + delta, PERIOD)
	else:
		clock = 0.0
	if is_instance_valid(warning_label):
		warning_panel.visible = active or disabled
		match phase():
			"warning":
				warning_label.text = "！即将发射\n离开下方黄框，或准备冲刺"
				warning_label.modulate = Color("ffd28c")
			"firing":
				warning_label.text = "危险区 · 红色光束会造成伤害\n等待熄灭，或从边缘冲刺穿过"
				warning_label.modulate = Color("ff9d9d")
			"disabled":
				warning_label.text = "供能已切断 · 安全通路\n伙伴可以通过"
				warning_label.modulate = Color("91e6b7")
			_:
				warning_label.text = "光束已熄灭 · 可以通过\n黄框亮起后即将发射"
				warning_label.modulate = Color("d3dedf")
	queue_redraw()

func phase() -> String:
	if disabled:
		return "disabled"
	if not active or clock < WARNING_START or clock >= FIRE_END:
		return "idle"
	if clock < FIRE_START:
		return "warning"
	return "firing"

func reset_cycle() -> void:
	clock = 0.0
	queue_redraw()

func hits(previous: Vector2, current: Vector2) -> bool:
	if phase() != "firing":
		return false
	# Sweep the character center against a beam expanded by the body half-size.
	var expanded = DANGER.grow_individual(15, 26, 15, 26)
	var movement = current - previous
	var entry = 0.0
	var exit = 1.0
	for axis in range(2):
		if absf(movement[axis]) < 0.001:
			if previous[axis] < expanded.position[axis] or previous[axis] > expanded.end[axis]:
				return false
		else:
			var a = (expanded.position[axis] - previous[axis]) / movement[axis]
			var b = (expanded.end[axis] - previous[axis]) / movement[axis]
			entry = maxf(entry, minf(a, b))
			exit = minf(exit, maxf(a, b))
			if entry > exit:
				return false
	return true

func _draw() -> void:
	var state = phase()
	var color = Color("637480")
	if state == "warning":
		color = Color("ffc16b")
	elif state == "firing":
		color = Color("ff6b72")
	elif disabled:
		color = Color("65c49b")
	draw_line(Vector2(1580, 260), Vector2(1890, 260), Color("51616c"), 8)
	draw_rect(Rect2(1705, 255, 70, 45), color.darkened(0.35))
	draw_circle(Vector2(1740, 290), 9, color)
	draw_line(Vector2(1660, 522), Vector2(1820, 522), color, 6)
	if state == "warning":
		draw_rect(DANGER, Color(1, 0.7, 0.25, 0.24))
		draw_rect(DANGER, color, false, 4)
		for i in range(9):
			var x = 1660 + i * 20
			draw_line(Vector2(x, 520), Vector2(x + 14, 505), color, 3)
		draw_line(Vector2(1660, 300), Vector2(1660, 520), color, 1)
		draw_line(Vector2(1820, 300), Vector2(1820, 520), color, 1)
	elif state == "firing":
		draw_rect(DANGER, Color(1, 0.2, 0.3, 0.5))
		draw_rect(DANGER, color, false, 5)
		for i in range(9):
			var stripe = Vector2(1660 + i * 20, 528)
			draw_line(stripe, stripe + Vector2(14, -14), Color("ffb8b2"), 5)
		for x in range(1664, 1821, 20):
			draw_line(Vector2(x, 300), Vector2(x, 520), Color("ffc4bc"), 4)
	elif disabled:
		draw_line(Vector2(1660, 515), Vector2(1820, 515), color, 7)
