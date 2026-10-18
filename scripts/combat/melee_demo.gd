extends Node2D
## Standalone training room. Its resettable 3-HP dummies are separate from run progress.

@onready var player: CharacterBody2D = $Player
var dummies: Array[MeleeDummy] = []


func _ready() -> void:
	EdenInputBindings.configure()
	GameSession.return_to_menu()
	WorldProgress.campaign_rules = false
	GameSession.start_run()
	WorldProgress.borrow_ability(&"light_blade")
	player.get_node("Camera2D").enabled = false
	player.position = Vector2(200, 596)
	_add_solid(Rect2(0, 620, 1152, 100))
	_add_solid(Rect2(-30, 0, 30, 720))
	_add_solid(Rect2(1152, 0, 30, 720))
	var positions := [Vector2(270, 596), Vector2(365, 596), Vector2(500, 596), Vector2(130, 596)]
	var descriptions := ["近身\n70 px", "长距离\n165 px", "范围外\n300 px", "身后\n70 px"]
	for index in positions.size():
		var dummy := preload("res://scenes/combat/melee_dummy.tscn").instantiate() as MeleeDummy
		dummy.position = positions[index]
		dummy.max_health = 3
		add_child(dummy)
		dummies.append(dummy)
		var label := Label.new()
		label.theme = preload("res://assets/ui_theme.tres")
		label.position = positions[index] + Vector2(-38, -120)
		label.text = descriptions[index]
		label.add_theme_font_size_override(&"font_size", 15)
		add_child(label)
	%ResetButton.pressed.connect(reset_training)
	%MenuButton.pressed.connect(_return_to_menu)
	player.combat.attack_started.connect(_on_attack_started)
	player.combat.target_hit.connect(func(_receiver: Node, hit: Dictionary) -> void:
		var title: String = player.combat.close_attack.profile.display_name if hit.attack_id == player.combat.close_attack.profile.id else player.combat.reach_attack.profile.display_name
		%Status.text = "%s 命中：伤害 %d；每刀每目标只结算一次" % [title, hit.damage]
	)
	%Status.text = "光刃已为本测试房开启。先原地朝右，比较左键和右键的命中范围。"


func reset_training() -> void:
	player.combat.cancel()
	player.position = Vector2(200, 596)
	player.velocity = Vector2.ZERO
	# Restore the test orientation through the same public adapter used by gameplay.
	player.face_direction(1.0)
	for dummy in dummies:
		dummy.reset()
	%Status.text = "木桩与角色位置已重置；原地左键命中近身木桩，右键还能命中长距离木桩。"


func _on_attack_started(move: MeleeAttackProfile) -> void:
	%Status.text = "%s：范围 %.0f px · 前摇 %.2f s · 生效 %.2f s · 后摇 %.2f s · 冷却 %.2f s" % [
		move.display_name, move.reach, move.windup, move.active_time, move.recovery, move.cooldown,
	]


func _return_to_menu() -> void:
	GameSession.return_to_menu()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1152, 720), Color(0.035, 0.055, 0.078))
	draw_rect(Rect2(0, 620, 1152, 100), Color(0.13, 0.19, 0.21))
	draw_line(Vector2(0, 620), Vector2(1152, 620), Color(0.35, 0.46, 0.39), 4.0)
	for x in [130, 200, 270, 365, 500]:
		draw_line(Vector2(x, 430), Vector2(x, 620), Color(0.12, 0.2, 0.23), 1.0)
