extends Node2D

const SPEED = 260.0
const GRAVITY = 1200.0
const JUMP = -440.0
const OASIS = Vector2(670, 500)
const RETURN_NODE = Vector2(1210, 500)
const COYOTE_TIME = 0.10
const JUMP_BUFFER = 0.12
const DASH_SPEED = 1050.0
const DASH_DURATION = 0.24
const DASH_COOLDOWN = 0.85
const MAX_HEALTH = 3
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
var eden_reached = false
var extraction_scene = 0.0
var cost_seen = false
var companions: Array[Vector2] = []
var birds: AudioStreamPlayer
var impact: AudioStreamPlayer
var rescue_progress = 0.0
var coyote = 0.0
var jump_buffer = 0.0
var dash_unlocked = false
var dash_remaining = 0.0
var dash_cooldown = 0.0
var dash_direction = 1.0
var health = MAX_HEALTH
var invulnerable = 0.0
var hurt_remaining = 0.0
var hurt_direction = -1.0
var damage_flash = 0.0
var damage_overlay: ColorRect
var turret: Node2D
var passed_turret = false

func _ready() -> void:
	setup_inputs()
	platform(Vector2(-200, 520), Vector2(1040, 180))
	platform(Vector2(1120, 520), Vector2(1450, 180))
	bridge = platform(Vector2(840, 520), Vector2(280, 35))
	bridge.visible = false
	bridge.get_child(0).set_deferred("disabled", true)
	turret = load("res://scripts/turret.gd").new()
	add_child(turret)
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
	status.position = Vector2(38, 187)
	status.add_theme_font_size_override("font_size", 18)
	layer.add_child(status)
	damage_overlay = ColorRect.new()
	damage_overlay.size = Vector2(1152, 648)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.color = Color(0.8, 0.08, 0.08, 0)
	layer.add_child(damage_overlay)
	story_panel = ColorRect.new()
	story_panel.position = Vector2(28, 18)
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
	world_label(Vector2(2160, 540), "转化舱 · E 开舱")
	world_label(Vector2(385, 555), "旧手环 · F 检视")
	world_label(Vector2(1310, 560), "测试模块：Shift / K 冲刺")
	world_label(Vector2(1600, 585), "黄光预警 → 红光发射 → 熄灭间隙")
	setup_audio()
	show_story(["【记忆】\n昨天，阿禾和另外两位伙伴登上了朝圣列车。\n阿禾说：‘等我安顿下来，就接你过去。’\n\n今天，你在路边捡到一枚旧手环。它属于去年的入选者。", "【食指与扳机】\n去伊甸，确认他们还活着。\n\nA/D 移动，空格跳跃。断崖前的孤木，仍有一小片绿荫。"])
	update_hud(false, false)

func show_story(pages: Array[String]) -> void:
	story_pages = pages.duplicate()
	story_panel.visible = not story_pages.is_empty()
	player.velocity = Vector2.ZERO
	dash_remaining = 0.0
	jump_buffer = 0.0
	coyote = 0.0
	hold_time = 0.0
	refresh_story()

func refresh_story() -> void:
	story_panel.visible = not story_pages.is_empty()
	hud.visible = not story_panel.visible
	message.visible = not story_panel.visible
	status.visible = not story_panel.visible
	progress.visible = false
	if story_panel.visible:
		story_text.text = story_pages[0] + "\n\n[ Enter 继续 ]"

func notify_player(text: String) -> void:
	toast = text
	toast_time = 3.0

func setup_audio() -> void:
	# Locally synthesized placeholder birds and extraction sound, no external assets.
	for is_bird in [true, false]:
		var sound = AudioStreamWAV.new()
		sound.format = AudioStreamWAV.FORMAT_16_BITS
		sound.mix_rate = 22050
		var duration = 4.0 if is_bird else 0.8
		var samples = int(duration * 22050)
		var data = PackedByteArray()
		data.resize(samples * 2)
		var phase = 0.0
		for i in range(samples):
			var t = float(i) / 22050.0
			var cycle = fmod(t, 1.3)
			var envelope = sin(clampf(cycle / 0.18, 0, 1) * PI) if cycle < 0.18 else 0.0
			var frequency = 1500.0 + cycle * 2800 if is_bird else 160.0 - t * 110
			phase += TAU * frequency / 22050
			var amplitude = envelope * 0.13 if is_bird else (1.0 - t / duration) * 0.24
			data.encode_s16(i * 2, int(sin(phase) * amplitude * 32767))
		sound.data = data
		var audio = AudioStreamPlayer.new()
		audio.stream = sound
		add_child(audio)
		if is_bird:
			sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
			sound.loop_end = samples
			birds = audio
			birds.volume_db = -40
			birds.play()
		else:
			impact = audio

func begin_rescue() -> void:
	returning = true
	turret.disabled = true
	turret.advance(0, false)
	health = MAX_HEALTH
	checkpoint = Vector2(2180, 450)
	for i in range(3):
		companions.append(Vector2(2190 + i * 32, 496))
	show_story(["【阿禾】\n‘别把我留在这里……带我们回家。’\n\n舱门打开了。三个人扶着彼此站起来，跟在你身后。\n你切断了舱室的供能总线，来路的炮台也熄灭了。", "【逻辑思维】\n回家的路在左边。炮台已停机，伙伴可以安全通过。\n但你能跳过的断崖，他们不能。\n\n到右岸接收器交还二段跳，让枝干搭桥。"])

func respawn(reason: String) -> void:
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	health = MAX_HEALTH
	invulnerable = 1.4
	hurt_remaining = 0.0
	air_used = false
	coyote = 0.0
	jump_buffer = 0.0
	dash_remaining = 0.0
	dash_cooldown = 0.0
	hold_time = 0.0
	rescue_progress = 0.0
	turret.reset_cycle()
	notify_player(reason + " · 已回到检查点，能力与剧情进度保留")

func take_damage() -> void:
	if invulnerable > 0 or dash_remaining > 0 or returning or finished:
		return
	health -= 1
	damage_flash = 0.3
	hold_time = 0.0
	rescue_progress = 0.0
	if health <= 0:
		respawn("生命耗尽，已恢复满血；可无限重试")
		return
	invulnerable = 1.0
	hurt_remaining = 0.14
	hurt_direction = -1.0 if player.position.x < 1740 else 1.0
	player.velocity = Vector2(hurt_direction * 190, -140)
	notify_player("受到炮台伤害 · 减少一格生命，短暂无敌")

func move_player(delta: float) -> void:
	dash_cooldown = maxf(0, dash_cooldown - delta)
	invulnerable = maxf(0, invulnerable - delta)
	jump_buffer = maxf(0, jump_buffer - delta)
	if player.is_on_floor():
		coyote = COYOTE_TIME
		air_used = false
	else:
		coyote = maxf(0, coyote - delta)
	var direction = Input.get_axis("left", "right")
	if absf(direction) > 0:
		facing = direction
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	if Input.is_action_just_pressed("dash") and dash_unlocked and dash_cooldown <= 0 and hurt_remaining <= 0:
		dash_direction = facing
		dash_remaining = DASH_DURATION
		dash_cooldown = DASH_COOLDOWN
		hold_time = 0
		rescue_progress = 0
	var previous = player.position
	var was_dashing = dash_remaining > 0
	if hurt_remaining > 0:
		hurt_remaining = maxf(0, hurt_remaining - delta)
		player.velocity.x = hurt_direction * 190
		player.velocity.y += GRAVITY * delta
	elif was_dashing:
		player.velocity = Vector2(dash_direction * DASH_SPEED, 0)
	else:
		player.velocity.x = direction * SPEED
		player.velocity.y += GRAVITY * delta
		if jump_buffer > 0:
			if coyote > 0:
				player.velocity.y = JUMP
				coyote = 0
				jump_buffer = 0
			elif extracted and not restored and not air_used and Input.is_action_just_pressed("jump"):
				player.velocity.y = JUMP
				air_used = true
				jump_buffer = 0
				flash = 0.35
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -20, 2485)
	if not was_dashing and turret.hits(previous, player.position):
		take_damage()
	dash_remaining = maxf(0, dash_remaining - delta)
	if was_dashing and dash_remaining == 0:
		player.velocity.x = direction * SPEED

func _exit_tree() -> void:
	for audio in [birds, impact]:
		if is_instance_valid(audio):
			audio.stop()
			audio.stream = null

func move_companions(delta: float) -> void:
	for i in range(companions.size()):
		var target = clampf(player.position.x + 65 + i * 34, 120, 2290)
		if not restored:
			target = maxf(1160 + i * 30, target)
		companions[i].x = move_toward(companions[i].x, target, 245 * delta)

func setup_inputs() -> void:
	var bindings = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "interact": [KEY_E], "restart": [KEY_R], "continue_story": [KEY_ENTER], "inspect": [KEY_F], "dash": [KEY_SHIFT, KEY_K]}
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
	damage_flash = maxf(0, damage_flash - delta)
	damage_overlay.color.a = damage_flash
	if is_instance_valid(birds):
		var proximity = clampf(1.0 - absf(player.position.x - OASIS.x) / 600, 0, 1)
		birds.volume_db = -80.0 if extracted else lerpf(-40, -8, proximity)
	queue_redraw()
	if not story_pages.is_empty():
		if Input.is_action_just_pressed("continue_story"):
			story_pages.pop_front()
			refresh_story()
		return
	if extraction_scene > 0:
		extraction_scene = maxf(0, extraction_scene - delta)
		if extraction_scene == 0:
			cost_seen = true
			show_story(["【听觉】\n刚才还有鸟叫。现在，什么都没有了。\n\n潭水结成白盐，树冠落成灰。提取器显示：生命源已耗尽。", "【痛觉阈值】\n你的身体轻了。身后的树不会再长出一片叶子。\n\n已获得二段跳：跳起后，再按一次空格。"])
		return
	if finished:
		return
	move_companions(delta)
	if not inspected and absf(player.position.x - 430) < 75 and Input.is_action_just_pressed("inspect"):
		inspected = true
		show_story(["【逻辑思维】\n一枚去年的入选者手环。它的主人没能走到伊甸。\n\n编号还清晰，手腕却只剩一截灰白的轮廓。"])
		return
	turret.advance(delta, player.position.x > 1380 and player.position.x < 2020)
	move_player(delta)
	if player.position.y > 850:
		respawn("失足掉落")
	if not returning and checkpoint.x < 1180 and player.position.x > 1180 and player.is_on_floor():
		checkpoint = Vector2(1280, 450)
		notify_player("检查点已更新 · 断崖右岸")
	if player.position.x > 1310 and not dash_unlocked and not returning:
		dash_unlocked = true
		checkpoint = Vector2(1420, 450)
		show_story(["【测试模块 · 冲刺】\n按住方向，点按 Shift 或 K：短距离冲刺。\n冲刺期间免疫炮台伤害，结束后需要冷却。\n\n前方炮台先亮黄光预警，再发射红色光束。\n等它熄灭后通过，或在靠近光束边缘时冲刺穿过。"])
		update_hud(false, false)
		return
	if player.position.x > 1910 and not passed_turret and not returning:
		passed_turret = true
		checkpoint = Vector2(1950, 450)
		health = MAX_HEALTH
		notify_player("通过炮台 · 检查点已更新，生命已恢复")
	if player.position.x > 2160 and not eden_reached:
		eden_reached = true
		checkpoint = Vector2(2130, 450)
		show_story(["【视觉神经】\n玻璃舱里的人是阿禾。她还活着。\n管线刺进她的胸口，绿色的光正流向头顶的花园。\n\n她看见你，伸手拍了一下玻璃。", "【终端】\n转化对象：本年度入选者。用途：生态供能。\n剩余生命正在被提取。\n\n这里不是他们的新家。继续留在舱里，他们会死。\n靠近转化舱，长按 E 断开管线、打开舱门。"])
		update_hud(false, false)
		return
	var can_rescue = eden_reached and not returning and player.position.x > 2130 and player.is_on_floor() and dash_remaining <= 0
	if can_rescue and Input.is_action_pressed("interact"):
		rescue_progress += delta
		if rescue_progress >= 1.5:
			rescue_progress = 0
			begin_rescue()
			update_hud(false, false)
			return
	else:
		rescue_progress = 0
	var can_extract = not extracted and player.position.distance_to(OASIS) < 110
	var can_restore = returning and not restored and player.position.distance_to(RETURN_NODE) < 100
	if (can_extract or can_restore) and player.is_on_floor() and dash_remaining <= 0 and Input.is_action_pressed("interact"):
		hold_time += delta
		if hold_time >= 1.5:
			hold_time = 0.0
			if can_extract:
				extracted = true
				checkpoint = Vector2(700, 450)
				flash = 1.0
				extraction_scene = 2.4
				impact.play()
				player.velocity = Vector2.ZERO
			else:
				restored = true
				bridge.visible = true
				bridge.get_child(0).set_deferred("disabled", false)
				checkpoint = Vector2(1210, 450)
				flash = 1.0
				show_story(["【阿禾】\n‘我跳不过去。’\n\n你将提取器接入树根，交还二段跳。枝干横跨断崖。\n她试着迈出一步，然后回头招呼另外两人。", "【共情】\n枯树没有复活。你带回来的生命力，暂时撑起了这座桥。\n\n现在，和他们一起向左走。回家。"])
	else:
		hold_time = 0.0
	var everyone_home = companions.size() == 3
	for companion in companions:
		everyone_home = everyone_home and companion.x < 350
	if restored and player.position.x < 240 and everyone_home:
		finished = true
		player.velocity = Vector2.ZERO
		show_story(["【阿禾】\n‘我们回来了。’\n\n三个人都走过了桥。孤木仍然枯白，你也失去了二段跳。\n但这一次，他们站在你身边。\n\n本段试玩结束 · 按 R 重新开始。"])
	update_hud(can_extract, can_restore)
	queue_redraw()

func update_hud(can_extract: bool, can_restore: bool) -> void:
	var goal = "向右寻找绿洲，抽取后获得二段跳"
	if extracted:
		goal = "空中再按空格跨过断崖，向右抵达伊甸入口"
	if dash_unlocked and not passed_turret and not returning:
		goal = "通过前方炮台：黄光预警，红光危险；等待熄灭或冲刺穿过"
	if eden_reached and not returning:
		goal = "伙伴正在被抽取生命！靠近转化舱，长按 E 开舱救人"
	if returning:
		goal = "带三位伙伴向左回家；在断崖右岸交还二段跳，为他们搭桥"
	if restored:
		goal = "二段跳已交还，走过树桥，向左回到起点"
	if finished:
		goal = "原型完成 · 你带着新的道路回到了起点。按 R 再玩一次"
	hud.text = "地脉固化 / 孤木之路 · 第四版\n" + goal
	message.text = "A/D 移动    空格 跳跃    Shift / K 冲刺    E 交互    R 重来"
	if can_extract:
		message.text = "长按 E 抽取这片绿荫：获得二段跳，树与水源将永久枯竭。"
	elif can_restore:
		message.text = "长按 E 1.5秒交还二段跳，树桥将为你开路。"
	elif not inspected and absf(player.position.x - 430) < 75:
		message.text = "按 F 检视旧手环"
	elif toast_time > 0:
		message.text = toast
	if eden_reached and not returning and player.position.x > 2130:
		message.text = "长按 E 1.5秒，断开生命提取管线，救出三位伙伴。"
	if extraction_scene > 0:
		message.text = "生命源已耗尽。"
	var dash_text = "未解锁"
	if dash_unlocked:
		dash_text = "就绪" if dash_cooldown <= 0 else "冷却 %.1f秒" % dash_cooldown
	var turret_text = "炮台已停机 · 伙伴通路安全" if returning else ""
	if turret.active:
		match turret.phase():
			"warning": turret_text = "炮台：黄光预警！"
			"firing": turret_text = "炮台：发射中！"
			_: turret_text = "炮台：熄灭间隙"
	status.text = "生命 %s%s  |  %s  |  冲刺：%s  |  %s" % ["●".repeat(health), "○".repeat(MAX_HEALTH - health), ("二段跳" if extracted and not restored else "普通跳跃"), dash_text, turret_text]
	progress.visible = story_pages.is_empty() and (hold_time > 0 or rescue_progress > 0)
	progress.value = maxf(hold_time, rescue_progress)

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
		var chamber = Vector2(2191 + i * 32, 417)
		draw_rect(Rect2(chamber, Vector2(22, 73)), Color("4a7478"), false, 2)
		if not returning:
			draw_circle(chamber + Vector2(11, 17), 6, Color("c3b8a4"))
			draw_line(chamber + Vector2(11, 24), chamber + Vector2(11, 58), Color("c3b8a4"), 6)
			var pulse = 0.5 + sin(elapsed * 4) * 0.3
			draw_line(chamber + Vector2(11, 36), Vector2(chamber.x + 11, 300), Color(0.4, 0.9, 0.6, pulse), 3)
		else:
			draw_line(chamber, chamber + Vector2(-10, -10), Color("65c49b"), 2)
	draw_line(Vector2(402, 510), Vector2(451, 510), Color("8c9295"), 7)
	draw_circle(Vector2(438, 506), 6, Color("c3aa76"), false, 2)
	var draining = clampf(hold_time / 1.5, 0, 1) if not extracted else 1.0
	var green = Color("65c49b").lerp(Color("b4b2aa"), draining)
	draw_rect(Rect2(555, 502, 220, 18), green.darkened(0.35))
	draw_ellipse_pond(green, draining)
	draw_line(Vector2(665, 510), Vector2(665, 400), green, 10)
	for i in range(5):
		var tip = Vector2(620 + i * 24, 354 + (i % 2) * 20)
		draw_line(Vector2(665, 442), tip, green, 5)
		if not extracted:
			draw_circle(tip, 25 * (1.0 - draining * 0.8), green)
	for i in range(18):
		var root_pos = Vector2(570 + i * 11, 508)
		if not extracted:
			draw_line(root_pos, root_pos + Vector2(sin(elapsed + i) * 4, -12 * (1 - draining)), green, 2)
		elif extraction_scene > 0:
			var fall = (2.4 - extraction_scene) / 2.4
			var ash = Vector2(607 + (i * 19) % 110 + fall * 50, 355 + (i * 31) % 65 + fall * 90)
			draw_circle(ash, 3, Color(0.8, 0.8, 0.75, 1 - fall))
	if not extracted:
		for i in range(2):
			var bird = Vector2(630 + sin(elapsed + i * 2) * 65, 300 + i * 22)
			draw_polyline(PackedVector2Array([bird + Vector2(-9, -3), bird, bird + Vector2(9, -3)]), green, 2)
	if hold_time > 0 and not extracted:
		draw_line(Vector2(665, 475), player.position, Color(0.4, 1, 0.7, 0.7), 3 + draining * 4)
	draw_rect(Rect2(1190, 475, 40, 45), Color("65c49b") if restored else Color("c3aa76"))
	if restored:
		# The original tree stays dead; transferred energy supports a temporary bridge.
		draw_polyline(PackedVector2Array([Vector2(1190, 500), Vector2(1120, 515), Vector2(840, 515), Vector2(735, 506)]), Color("65c49b"), 5)
		draw_line(Vector2(840, 515), Vector2(1120, 515), Color("65c49b"), 12)
		for i in range(8):
			var leaf = Vector2(860 + i * 33, 509)
			draw_line(leaf, leaf + Vector2(12, -22), Color("65c49b"), 3)
	for i in range(companions.size()):
		var companion = companions[i]
		var cloth = [Color("c7a0a1"), Color("aaa5cc"), Color("b9bc98")][i]
		draw_line(companion + Vector2(0, -12), companion + Vector2(0, 15), cloth, 13)
		draw_circle(companion + Vector2(0, -20), 8, Color("dac8b0"))
		draw_line(companion + Vector2(0, 13), companion + Vector2(-6, 24), cloth, 4)
		draw_line(companion + Vector2(0, 13), companion + Vector2(6, 24), cloth, 4)
	if is_instance_valid(player):
		var color = Color("77dce3") if extracted and not restored else Color("e4c9a3")
		var pos = player.position
		if dash_remaining > 0:
			for i in range(1, 5):
				var ghost = pos + Vector2(-dash_direction * i * 17, 0)
				draw_rect(Rect2(ghost - Vector2(13, 24), Vector2(26, 48)), Color(0.4, 0.9, 1, 0.4 - i * 0.07))
		if invulnerable > 0:
			color = color.lerp(Color("ffb6b6"), 0.5 + sin(elapsed * 35) * 0.35)
			draw_arc(pos, 32, 0, TAU, 32, Color(1, 0.6, 0.6, 0.5), 2)
		var sway = sin(elapsed * 12) * 3 if absf(player.velocity.x) > 1 else 0.0
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-10, -13), pos + Vector2(10, -13), pos + Vector2(19 + sway, 25), pos + Vector2(-19 + sway, 25)]), color.darkened(0.2))
		draw_circle(pos + Vector2(0, -17), 11, color)
		draw_circle(pos + Vector2(facing * 5, -18), 2.5, Color("17222e"))
		if extracted and not restored:
			draw_line(pos + Vector2(-facing * 9, -7), pos + Vector2(-facing * 25, 15), Color("77dce3"), 3)
		if flash > 0:
			draw_arc(pos, 32 + (1 - flash) * 45, 0, TAU, 40, Color(0.5, 1, 0.9, flash), 2)

func draw_ellipse_pond(green: Color, draining: float) -> void:
	var pool = Color("63b8c4").lerp(Color("c7c5b7"), draining)
	draw_rect(Rect2(700, 506, 65, 9), pool)
	if not extracted:
		draw_line(Vector2(709, 509), Vector2(751, 509), green.lightened(0.3), 1)
	else:
		for i in range(5):
			draw_line(Vector2(705 + i * 12, 506), Vector2(711 + i * 12, 515), Color("777e82"), 1)
