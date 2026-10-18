extends Node2D
signal valve_changed(open: bool)
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Audio=preload("res://scripts/mine_challenge/mine_audio.gd")
@export var switch_offset := Vector2(390,0)
var pressed := false
var crate: CharacterBody2D
var _sensor: Area2D
var _plate_blend:=0.0
var _clock:=0.0

class PushableCrate extends CharacterBody2D:
	const CrateArt=preload("res://scripts/mine_challenge/mine_art.gd")
	const CrateAudio=preload("res://scripts/mine_challenge/mine_audio.gd")
	var _push := 0.0
	var _scrape:=0.0
	func _ready() -> void:
		collision_layer=4
		collision_mask=1
		set_meta(&"crate",true)
		texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		var shape:=CollisionShape2D.new()
		var box:=RectangleShape2D.new()
		box.size=Vector2(46,46)
		shape.shape=box
		add_child(shape)
	func push(force: float) -> void: _push=force
	func _physics_process(delta: float) -> void:
		if not WorldProgress.can_play(): return
		velocity=Vector2(_push,minf(velocity.y+980*delta,900))
		_push=0
		move_and_slide()
		position.x=clampf(position.x,-180,460)
		_scrape=maxf(0,_scrape-delta)
		if absf(velocity.x)>10 and is_on_floor() and _scrape<=0:
			_scrape=.22
			CrateAudio.play_near(self,&"footstep",-17,.62)
	func _draw() -> void:
		draw_texture_rect(CrateArt.puff_texture(),Rect2(-29,17,58,12),false,Color(0,0,0,.5))
		CrateArt.draw_at(self,5,Rect2(-24,-24,48,48))

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	crate=PushableCrate.new()
	crate.position=Vector2(0,-24)
	add_child(crate)
	_sensor=Area2D.new()
	_sensor.position=switch_offset+Vector2(0,-12)
	_sensor.collision_layer=0
	_sensor.collision_mask=4
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(76,28)
	shape.shape=box
	_sensor.add_child(shape)
	add_child(_sensor)

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play(): return
	_clock+=delta
	_plate_blend=move_toward(_plate_blend,1.0 if pressed else 0.0,delta*7)
	var next:=not _sensor.get_overlapping_bodies().is_empty()
	if next!=pressed:
		pressed=next
		Audio.play_near(self,&"valve",-2,.85 if pressed else .7)
		valve_changed.emit(pressed)
	queue_redraw()

func _draw() -> void:
	var point:=switch_offset+Vector2(0,_plate_blend*4)
	Art.draw_at(self,6,Rect2(point+Vector2(-48,-20),Vector2(96,32)),Color(.78,1,.65) if pressed else Color.WHITE)
	# Small light on the real pressure plate reads at normal camera scale.
	if pressed:
		draw_texture_rect(Art.puff_texture(),Rect2(switch_offset+Vector2(-34,-23),Vector2(68,32)),false,Color(.55,.87,.25,.17+sin(_clock*3)*.025))
