extends Node2D

const SPEED = 260.0
const GRAVITY = 1200.0
const JUMP = -440.0
const OASIS = Vector2(670, 500)
const RETURN_NODE = Vector2(1210, 500)
var player: CharacterBody2D
var bridge: StaticBody2D
var hud: Label
var progress: ProgressBar
var message: Label
var extracted = false
var returning = false
var restored = false
var finished = false
var air_used = false
var hold_time = 0.0
var checkpoint = Vector2(140, 450)

func _ready() -> void:
	setup_inputs()
	platform(Vector2(-200, 520), Vector2(1040, 180))
	platform(Vector2(1120, 520), Vector2(1450, 180))
	bridge = platform(Vector2(840, 520), Vector2(280, 35))
	bridge.visible = false
	bridge.get_child(0).set_deferred("disabled", true)
	player = CharacterBody2D.new()
	var shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(30, 52)
	shape.shape = rectangle
	player.add_child(shape)
	add_child(player)
	player.position = checkpoint
	var camera = Camera2D.new()
	camera.position = Vector2(120, -140)
	camera.limit_left = -40
	camera.limit_right = 2510
	camera.limit_top = 0
	camera.limit_bottom = 730
	player.add_child(camera)
	var layer = CanvasLayer.new()
	add_child(layer)
	var panel = ColorRect.new()
	panel.position = Vector2(20, 18)
	panel.size = Vector2(1112, 132)
	panel.color = Color(0.025, 0.035, 0.055, 0.94)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(38, 28)
	hud.add_theme_font_size_override("font_size", 22)
	layer.add_child(hud)
	message = Label.new()
	message.position = Vector2(38, 92)
	message.add_theme_font_size_override("font_size", 19)
	layer.add_child(message)
	progress = ProgressBar.new()
	progress.position = Vector2(38, 157)
	progress.size = Vector2(360, 16)
	progress.show_percentage = false
	progress.max_value = 1.5
	layer.add_child(progress)
	world_label(Vector2(70, 540), "边陲起点")
	world_label(Vector2(575, 555), "孤木绿洲 · E 抽取")
	world_label(Vector2(1135, 555), "返程接收器 · E 交还")
	world_label(Vector2(2160, 540), "伊甸入口 →")

func setup_inputs() -> void:
	var bindings = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "interact": [KEY_E], "restart": [KEY_R]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for code in bindings[action]:
				var event = InputEventKey.new()
				event.physical_keycode = code
				InputMap.action_add_event(action, event)

func platform(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.position = pos
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = size / 2
	body.add_child(collision)
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	visual.color = Color("394451")
	body.add_child(visual)
	add_child(body)
	return body

func world_label(pos: Vector2, text: String) -> void:
	var label = Label.new()
	label.position = pos
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if finished:
		return
	player.velocity.y += GRAVITY * delta
	player.velocity.x = Input.get_axis("left", "right") * SPEED
	if player.is_on_floor():
		air_used = false
	if Input.is_action_just_pressed("jump"):
		if player.is_on_floor():
			player.velocity.y = JUMP
		elif extracted and not restored and not air_used:
			player.velocity.y = JUMP
			air_used = true
	player.move_and_slide()
	if player.position.y > 850:
		player.position = checkpoint
		player.velocity = Vector2.ZERO
		air_used = false
	if player.position.x > 1180 and player.is_on_floor():
		checkpoint = Vector2(1280, 450)
	if player.position.x > 2240 and not returning:
		returning = true
		checkpoint = Vector2(2180, 450)
	var can_extract = not extracted and player.position.distance_to(OASIS) < 110
	var can_restore = returning and not restored and player.position.distance_to(RETURN_NODE) < 100
	if (can_extract or can_restore) and player.is_on_floor() and Input.is_action_pressed("interact"):
		hold_time += delta
		if hold_time >= 1.5:
			hold_time = 0.0
			if can_extract:
				extracted = true
				checkpoint = Vector2(700, 450)
			else:
				restored = true
				bridge.visible = true
				bridge.get_child(0).set_deferred("disabled", false)
				checkpoint = Vector2(1210, 450)
	else:
		hold_time = 0.0
	if restored and player.position.x < 240:
		finished = true
		player.velocity = Vector2.ZERO
	update_hud(can_extract, can_restore)
	queue_redraw()

func update_hud(can_extract: bool, can_restore: bool) -> void:
	var goal = "向右寻找绿洲，抽取后获得二段跳"
	if extracted:
		goal = "空中再按空格跨过断崖，向右抵达伊甸入口"
	if returning:
		goal = "向左返程，在断崖右岸的接收器交还能力"
	if restored:
		goal = "二段跳已交还，走过树桥，向左回到起点"
	if finished:
		goal = "原型完成 · 你带着新的道路回到了起点。按 R 再玩一次"
	hud.text = "地脉固化 / 闭环原型\n" + goal
	message.text = "A/D 或 ←/→ 移动    空格 跳跃    E 交互    R 重新开始"
	if can_extract:
		message.text = "长按 E 1.5秒抽取绿洲。绿洲将枯萎，你将获得二段跳。"
	elif can_restore:
		message.text = "长按 E 1.5秒交还二段跳，树桥将为你开路。"
	progress.visible = hold_time > 0
	progress.value = hold_time

func _draw() -> void:
	for x in range(-200, 2600, 180):
		draw_line(Vector2(x, 520), Vector2(x + 100, 400), Color(0.14, 0.17, 0.21), 2)
	draw_rect(Rect2(2180, 250, 120, 270), Color("244c4a"))
	draw_rect(Rect2(2210, 290, 60, 170), Color("6dbd9c"), false, 3)
	var green = Color("65c49b") if not extracted or restored else Color("89919b")
	draw_rect(Rect2(580, 507, 170, 13), green)
	draw_line(Vector2(665, 510), Vector2(665, 400), green, 10)
	draw_circle(Vector2(665, 395), 46, green)
	draw_rect(Rect2(1190, 475, 40, 45), Color("65c49b") if restored else Color("c3aa76"))
	if restored:
		draw_line(Vector2(840, 515), Vector2(1120, 515), Color("65c49b"), 12)
	if is_instance_valid(player):
		var color = Color("77dce3") if extracted and not restored else Color("e4c9a3")
		draw_rect(Rect2(player.position - Vector2(15, 26), Vector2(30, 52)), color)
		draw_circle(player.position + Vector2(7, -14), 3, Color("17222e"))
