class_name HydraulicCrusher
extends Node2D

@export var phase_offset := 0.0
const TELEGRAPH := 0.5
const SLAM := 0.15
const HOLD := 0.4
const RETRACT := 1.2
const REST := TELEGRAPH + SLAM + HOLD + RETRACT
const CYCLE := TELEGRAPH + SLAM + HOLD + RETRACT + REST
const FACE_OFFSET := 110.0
const FACE_HALF_WIDTH := 59.0
var clock := 0.0
var retired := false
var head_y := 110.0
var actor: CharacterBody2D
var level: Node
var _previous_actor_rect := Rect2()
var _has_previous_actor := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	level = get_parent()
	actor = level.get_node_or_null("Player") as CharacterBody2D
	add_to_group("parkour_crusher")

func phase() -> int:
	var time := fposmod(clock + phase_offset, CYCLE)
	return 0 if time < TELEGRAPH else 1 if time < TELEGRAPH + SLAM else 2 if time < TELEGRAPH + SLAM + HOLD else 3 if time < CYCLE-REST else 4

func _physics_process(delta: float) -> void:
	if retired or not WorldProgress.can_play(): return
	var previous := head_y
	clock += delta
	var time := fposmod(clock + phase_offset, CYCLE)
	match phase():
		0,4: head_y = 110
		1: head_y = lerpf(110, 430, (time - TELEGRAPH) / SLAM)
		2: head_y = 430
		3: head_y = lerpf(430, 110, (time - TELEGRAPH - SLAM - HOLD) / RETRACT)
	queue_redraw()
	if not is_instance_valid(actor): return
	var body := Rect2(actor.global_position-Vector2(14,24),Vector2(28,48))
	var old_body := _previous_actor_rect if _has_previous_actor else body
	_previous_actor_rect = body
	_has_previous_actor = true
	# Only the downward-facing teeth are dangerous. A directional swept face
	# catches fast slams without treating the head's sides / interior as damage.
	if phase() in [1,2] and is_instance_valid(actor):
		var before := global_position.y+previous+FACE_OFFSET-old_body.position.y
		var after := global_position.y+head_y+FACE_OFFSET-body.position.y
		var pressed_down := before <= 0.0 and after >= 0.0 and after-before>0.001
		var jumped_under := phase()==2 and before >= 0.0 and after <= 0.0 and before-after>0.001
		if not pressed_down and not jumped_under: return
		var fraction := clampf(-before/(after-before),0,1) if not is_zero_approx(after-before) else 1.0
		var left := lerpf(old_body.position.x,body.position.x,fraction)
		var right := left+body.size.x
		if right>global_position.x-FACE_HALF_WIDTH and left<global_position.x+FACE_HALF_WIDTH:
			level.respawn_player(&"crusher")

func reset_hazard() -> void:
	clock = 0.0
	head_y = 110
	_has_previous_actor = false

func retire() -> void:
	retired = true
	visible = false

func _draw() -> void:
	var warning := phase() == 0
	var active := phase() in [1,2]
	if warning:
		draw_rect(Rect2(-68,110,136,440),Color(0.85,0.21,0.1,0.07))
	# Greasy piston, collars and flaked paint use the same olive / rust palette.
	draw_rect(Rect2(-23,-80,46,head_y+80),Color("272f29"))
	draw_rect(Rect2(-16,-80,32,head_y+80),Color("62694f"))
	draw_rect(Rect2(-13,-80,5,head_y+80),Color("989879"))
	draw_rect(Rect2(10,-80,5,head_y+80),Color("714e32"))
	for y in range(-70,int(head_y)-10,31):
		draw_rect(Rect2(-20,y,40,5),Color("414936"))
		draw_rect(Rect2(-18,y,36,1),Color("89866a"))
	draw_set_transform(Vector2(0,head_y))
	draw_colored_polygon(PackedVector2Array([Vector2(-65,5),Vector2(-59,-3),Vector2(58,-3),Vector2(65,5),Vector2(65,97),Vector2(-65,97)]),Color("303a2e"))
	draw_texture_rect_region(ScrapyardSurface.TERRAIN,Rect2(-61,2,122,91),Rect2(470,482,342,255),Color(0.8,0.78,0.62))
	draw_rect(Rect2(-51,12,102,51),Color(0.15,0.18,0.13,0.82))
	draw_rect(Rect2(-51,12,102,3),Color("8d8053"))
	for x in [-62,-48,44,58]:
		draw_rect(Rect2(x,8,5,62),Color("656249"))
		draw_rect(Rect2(x+1,9,2,59),Color("a18c5a"))
	for x in [-55,50]:
		for y in [8,57,90]:
			draw_rect(Rect2(x,y,5,5),Color("242d25"))
			draw_rect(Rect2(x,y,3,2),Color("b4a16f"))
	for index in 22:
		var x := float(posmod(index*37,96)-48)
		var y := float(posmod(index*23,46)+15)
		draw_rect(Rect2(x,y,3+index%3,2),Color("765336") if index%2 else Color("535944"))
	# Worn safety stripe is a surface marking; the sharp teeth below it hurt.
	draw_rect(Rect2(-61,75,122,18),Color("a78d43"))
	for x in range(-60,52,21):
		draw_colored_polygon(PackedVector2Array([Vector2(x,75),Vector2(x+8,75),Vector2(x+19,93),Vector2(x+11,93)]),Color("30392b"))
	draw_rect(Rect2(-61,94,122,6),Color("2c3429"))
	for x in range(-60,60,20):
		draw_colored_polygon(PackedVector2Array([Vector2(x,100),Vector2(x+20,100),Vector2(x+10,110)]),Color("f2854e") if active else Color("b4b28b"))
		draw_line(Vector2(x+1,100),Vector2(x+10,108),Color("ead0a0"),1)
	if active: draw_line(Vector2(-59,108),Vector2(59,108),Color("ffac69"),2)
	draw_rect(Rect2(-6,23,12,8),Color("fa7651") if warning else Color("6d7a51"))
	draw_set_transform(Vector2.ZERO)
	if warning:
		for index in 8:
			var rise := fposmod(clock * 90 + index * 13, 70)
			draw_circle(Vector2(-75 if index % 2 else 75, 500-rise), 5 + rise * 0.08, Color(0.9,0.8,0.65,0.4*(1-rise/70)))
		draw_line(Vector2(-76,520),Vector2(76,520),Color(1,0.25,0.15,0.6+sin(clock*24)*0.3),5)
