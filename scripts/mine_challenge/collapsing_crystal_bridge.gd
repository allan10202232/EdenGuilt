extends Node2D
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Effects=preload("res://scripts/mine_challenge/mineral_effects.gd")
const Audio=preload("res://scripts/mine_challenge/mine_audio.gd")
@export var segment_count := 10
@export var segment_width := 200.0
@export var shake_delay := 0.45
# Collapse timing remains the original authored, normally playable 260px/s route.
@export var propagation_interval := 0.82
var triggered := false
var elapsed := 0.0
var bodies: Array[StaticBody2D]=[]
var collapsed := 0
var _warning_segments: Dictionary={}

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for index in segment_count:
		var body:=StaticBody2D.new()
		body.position.x=index*segment_width
		body.collision_layer=1
		var shape:=CollisionShape2D.new()
		var box:=RectangleShape2D.new()
		box.size=Vector2(segment_width,18)
		shape.shape=box
		shape.position=Vector2(segment_width/2,9)
		shape.one_way_collision=true
		body.add_child(shape)
		body.set_meta(&"crystal_bridge",true)
		add_child(body)
		bodies.append(body)

func trigger() -> void:
	if not triggered: Audio.play_near(self,&"warning",-3,.6)
	triggered=true

func reset() -> void:
	triggered=false
	elapsed=0
	collapsed=0
	_warning_segments.clear()
	for body in bodies: body.get_child(0).set_deferred(&"disabled",false)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play() or not triggered: return
	elapsed+=delta
	for index in segment_count:
		var time:=elapsed-(.9+index*propagation_interval)
		if time>0 and not _warning_segments.has(index):
			_warning_segments[index]=true
			Audio.play_near(bodies[index],&"warning",-11,.7+index*.03)
		if elapsed>=.9+index*propagation_interval+shake_delay:
			if index>=collapsed:
				Effects.burst(self,Vector2((index+.5)*segment_width,5),&"shatter")
				Audio.play_near(bodies[index],&"crystal_break",-5,.65+index*.025)
			bodies[index].get_child(0).set_deferred(&"disabled",true)
			collapsed=maxi(collapsed,index+1)
	queue_redraw()

func _draw() -> void:
	for index in segment_count:
		var time:=elapsed-(.9+index*propagation_interval)
		var fallen:=triggered and time>=shake_delay
		var fall_time:=maxf(time-shake_delay,0)
		var drop:=minf(470,pow(fall_time,2)*800) if fallen else 0.0
		var shake:=sin(elapsed*60+index)*3 if triggered and time>0 and not fallen else 0.0
		var fade:=clampf(1-fall_time*.95,0,1) if fallen else 1.0
		var angle:=fall_time*.28*(-1 if index%2==0 else 1) if fallen else 0.0
		var origin:=Vector2(index*segment_width+segment_width/2+shake,drop)
		draw_set_transform(origin,angle)
		Art.draw_at(self,2,Rect2(-segment_width/2+2,-1,segment_width-4,44),Color(.91,.85,1,fade))
		if triggered and time>0 and not fallen:
			Art.draw_at(self,2,Rect2(-segment_width/2+2,-1,segment_width-4,44),Color(1,1,1,.3 if sin(elapsed*40)>0 else .0))
		draw_set_transform(Vector2.ZERO)
