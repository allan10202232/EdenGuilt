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
var story_panel: ColorRect
var story_text: Label
var status: Label
var story_pages: Array[String] = []
var inspected = false
var elapsed = 0.0
var facing = 1.0
var flash = 0.0
var toast = ""
var toast_time = 0.0

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
	status = Label.new()
	status.position = Vector2(775, 157)
	status.add_theme_font_size_override("font_size", 18)
	layer.add_child(status)
	story_panel = ColorRect.new()
	story_panel.position = Vector2(28, 340)
	story_panel.size = Vector2(1096, 280)
	story_panel.color = Color(0.025, 0.035, 0.055, 0.97)
	layer.add_child(story_panel)
	story_text = Label.new()
	story_text.position = Vector2(24, 18)
	story_text.size = Vector2(1048, 244)
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_text.add_theme_font_size_override("font_size", 20)
	story_panel.add_child(story_text)
	world_label(Vector2(70, 540), "边陲起点")
	world_label(Vector2(575, 555), "孤木绿洲 · E 抽取")
	world_label(Vector2(1135, 555), "返程接收器 · E 交还")
	world_label(Vector2(2160, 540), "伊甸入口 →")
	world_label(Vector2(385, 555), "旧手环 · F 检视")
	show_story(["【视觉神经】\n伙伴们昨天乘上了朝圣列车。终点是天际线尽头的伊甸。\n\n你没有车票。你只有一台捡来的地脉提取器。", "【食指与扳机】\n往右走。穿过这片死地，去找他们。\n\nA/D 移动，空格跳跃。靠近孤木后长按 E。"])
	update_hud(false, false)

func show_story(pages: Array[String]) -> void:
	story_pages = pages.duplicate()
	story_panel.visible = not story_pages.is_empty()
	player.velocity = Vector2.ZERO
	hold_time = 0.0
	refresh_story()

func refresh_story() -> void:
	story_panel.visible = not story_pages.is_empty()
	if story_panel.visible:
		story_text.text = story_pages[0] + "\n\n[ Enter 继续 ]"

func notify_player(text: String) -> void:
	toast = text
	toast_time = 3.0

func setup_inputs() -> void:
	var bindings = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "interact": [KEY_E], "restart": [KEY_R], "continue_story": [KEY_ENTER], "inspect": [KEY_F]}
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
	elapsed += delta
	flash = maxf(0, flash - delta * 2)
	toast_time = maxf(0, toast_time - delta)
	queue_redraw()
	if not story_pages.is_empty():
		if Input.is_action_just_pressed("continue_story"):
			story_pages.pop_front()
			refresh_story()
		return
	if finished:
		return
	if not inspected and absf(player.position.x - 430) < 75 and Input.is_action_just_pressed("inspect"):
		inspected = true
		show_story(["【逻辑思维】\n一枚去年的入选者手环。它的主人没能走到伊甸。\n\n编号还清晰，手腕却只剩一截灰白的轮廓。"])
		return
	player.velocity.y += GRAVITY * delta
	player.velocity.x = Input.get_axis("left", "right") * SPEED
	if absf(player.velocity.x) > 1:
		facing = signf(player.velocity.x)
	if player.is_on_floor():
		air_used = false
	if Input.is_action_just_pressed("jump"):
		if player.is_on_floor():
			player.velocity.y = JUMP
		elif extracted and not restored and not air_used:
			player.velocity.y = JUMP
			air_used = true
			flash = 0.35
	player.move_and_slide()
	if player.position.y > 850:
		player.position = checkpoint
		player.velocity = Vector2.ZERO
		air_used = false
		hold_time = 0.0
		notify_player("已回到安全位置 · 当前能力与进度保留")
	if not returning and checkpoint.x < 1180 and player.position.x > 1180 and player.is_on_floor():
		checkpoint = Vector2(1280, 450)
		notify_player("检查点已更新 · 断崖右岸")
	if player.position.x > 2240 and not returning:
		returning = true
		checkpoint = Vector2(2180, 450)
		show_story(["【视觉神经】\n玻璃后面是你的伙伴。管线从他们的胸口伸向树根。\n\n这里没有最后的净土。只有被生命维持的春天。", "【内陆帝国】\n提取器里的光，和那些管线是同一种颜色。\n\n带他们回去。向左走，在接收器交还你带来的力量。\n（本段为剧情与返程机制的测试演出。）"])
		update_hud(false, false)
		return
	var can_extract = not extracted and player.position.distance_to(OASIS) < 110
	var can_restore = returning and not restored and player.position.distance_to(RETURN_NODE) < 100
	if (can_extract or can_restore) and player.is_on_floor() and Input.is_action_pressed("interact"):
		hold_time += delta
		if hold_time >= 1.5:
			hold_time = 0.0
			if can_extract:
				extracted = true
				checkpoint = Vector2(700, 450)
				flash = 1.0
				show_story(["【痛觉阈值】\n树冠变成了白灰。你的脊椎里却多了一团火。\n\n已获得二段跳：跳起后，再按一次空格。"])
			else:
				restored = true
				bridge.visible = true
				bridge.get_child(0).set_deferred("disabled", false)
				checkpoint = Vector2(1210, 450)
				flash = 1.0
				show_story(["【共情】\n你交还了飞跃断崖的力量。枝干却替你接住了前路。\n\n二段跳已失去。沿树桥向左，回到起点。\n（生命力暂时供养枝干；这不代表死土已经复活。）"])
	else:
		hold_time = 0.0
	if restored and player.position.x < 240:
		finished = true
		player.velocity = Vector2.ZERO
		show_story(["【视觉神经】\n他们越过了桥。你终于不必再向右走。\n\n本段试玩结束。正式版的牺牲与双结局尚未制作。\n按 Enter 收起文字，按 R 重新开始。"])
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
	hud.text = "地脉固化 / 孤木之路 · 第二版\n" + goal
	message.text = "A/D 或 ←/→ 移动    空格 跳跃    E 交互    R 重新开始"
	if can_extract:
		message.text = "长按 E 1.5秒抽取绿洲。绿洲将枯萎，你将获得二段跳。"
	elif can_restore:
		message.text = "长按 E 1.5秒交还二段跳，树桥将为你开路。"
	elif not inspected and absf(player.position.x - 430) < 75:
		message.text = "按 F 检视旧手环"
	elif toast_time > 0:
		message.text = toast
	status.text = "能力：" + ("二段跳" if extracted and not restored else "普通跳跃") + "  |  " + ("返程 ←" if returning else "去程 →")
	progress.visible = hold_time > 0
	progress.value = hold_time

func _draw() -> void:
	# Distant architecture uses reduced camera displacement for depth.
	if is_instance_valid(player):
		var drift = player.position.x * 0.65
		for i in range(12):
			var height = 65.0 + float((i * 37) % 115)
			draw_rect(Rect2(-300 + i * 220 + drift, 390 - height, 90, height), Color("17232e"))
		for i in range(38):
			var dust_x = fmod(i * 83.0 + elapsed * 12, 2900) - 200
			draw_circle(Vector2(dust_x, 210 + (i * 47) % 275), 1.5, Color(0.7, 0.8, 0.8, 0.18))
	for x in range(-200, 2600, 180):
		draw_line(Vector2(x, 520), Vector2(x + 100, 400), Color(0.14, 0.17, 0.21), 2)
	draw_rect(Rect2(2180, 250, 120, 270), Color("244c4a"))
	draw_rect(Rect2(2210, 290, 60, 170), Color("6dbd9c"), false, 3)
	for i in range(3):
		draw_rect(Rect2(2191 + i * 32, 417, 22, 73), Color("4a7478"), false, 2)
		draw_circle(Vector2(2202 + i * 32, 434), 6, Color("c3b8a4"))
	draw_line(Vector2(402, 510), Vector2(451, 510), Color("8c9295"), 7)
	draw_circle(Vector2(438, 506), 6, Color("c3aa76"), false, 2)
	var green = Color("65c49b") if not extracted or restored else Color("89919b")
	draw_rect(Rect2(580, 507, 170, 13), green)
	draw_line(Vector2(665, 510), Vector2(665, 400), green, 10)
	draw_circle(Vector2(665, 395), 46, green)
	for i in range(5):
		var tip = Vector2(620 + i * 24, 354 + (i % 2) * 20)
		draw_line(Vector2(665, 442), tip, green, 5)
		if not extracted or restored:
			draw_circle(tip, 22, green)
	draw_rect(Rect2(1190, 475, 40, 45), Color("65c49b") if restored else Color("c3aa76"))
	if restored:
		draw_line(Vector2(840, 515), Vector2(1120, 515), Color("65c49b"), 12)
		for i in range(8):
			var leaf = Vector2(860 + i * 33, 509)
			draw_line(leaf, leaf + Vector2(12, -22), Color("65c49b"), 3)
	if is_instance_valid(player):
		var color = Color("77dce3") if extracted and not restored else Color("e4c9a3")
		var pos = player.position
		var sway = sin(elapsed * 12) * 3 if absf(player.velocity.x) > 1 else 0.0
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-10, -13), pos + Vector2(10, -13), pos + Vector2(19 + sway, 25), pos + Vector2(-19 + sway, 25)]), color.darkened(0.2))
		draw_circle(pos + Vector2(0, -17), 11, color)
		draw_circle(pos + Vector2(facing * 5, -18), 2.5, Color("17222e"))
		if extracted and not restored:
			draw_line(pos + Vector2(-facing * 9, -7), pos + Vector2(-facing * 25, 15), Color("77dce3"), 3)
		if flash > 0:
			draw_arc(pos, 32 + (1 - flash) * 45, 0, TAU, 40, Color(0.5, 1, 0.9, flash), 2)
