class_name OpenElevator
extends Node2D
## Motion belongs to AnimatableBody2D. Riders use Godot's floor velocity,
## snapping and platform-on-leave policy; their position is never bound here.
signal movement_started(up: bool)
signal arrived(at_top: bool)
signal obstructed
enum State { IDLE_BOTTOM, MOVING_UP, IDLE_TOP, MOVING_DOWN }
@export_range(20,600,1) var move_speed:=200.0
@export_range(1,2000,1) var acceleration:=420.0
@export_range(1,2000,1) var deceleration:=520.0
@export var top_position:=Vector2(0,-360)
@export var bottom_position:=Vector2.ZERO
@export var interaction_enabled:=true
@export var automatic_return:=false
@export var return_delay:=3.0
@export var start_at_top:=false
@export var platform_width:=184.0
@export_flags_2d_physics var obstruction_mask:=1|16|32
@export var handle_input:=true
@export var start_sound: AudioStream=preload("res://assets/audio/mine/lever.wav")
@export var movement_sound: AudioStream=preload("res://assets/audio/mine/valve.wav")
@export var dock_sound: AudioStream=preload("res://assets/audio/mine/land.wav")
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Hints=preload("res://scripts/presentation/interaction_hints.gd")
var state:=State.IDLE_BOTTOM
var platform: AnimatableBody2D
var _speed:=0.0
var _shake:=0.0
var _clock:=0.0
var _empty_seconds:=0.0
var _motor: AudioStreamPlayer2D
var _cue: AudioStreamPlayer2D
var _hints: Node2D
var _actor: CharacterBody2D

func _ready() -> void:
	process_physics_priority=-40
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	platform=$Platform
	platform.sync_to_physics=true
	platform.collision_layer=1
	platform.collision_mask=obstruction_mask
	var box:=RectangleShape2D.new()
	box.size=Vector2(platform_width,18)
	$Platform/CollisionShape2D.shape=box
	$Platform/CollisionShape2D.position=Vector2(0,9)
	var trigger:=RectangleShape2D.new()
	trigger.size=Vector2(platform_width+12,76)
	$Platform/OperationArea/CollisionShape2D.shape=trigger
	$Platform/OperationArea/CollisionShape2D.position=Vector2(0,-28)
	$TopPoint.position=top_position
	$BottomPoint.position=bottom_position
	platform.position=top_position if start_at_top else bottom_position
	state=State.IDLE_TOP if start_at_top else State.IDLE_BOTTOM
	_motor=AudioStreamPlayer2D.new()
	_motor.bus=&"SFX"
	_motor.max_distance=1100
	_motor.volume_db=-22
	if movement_sound is AudioStreamWAV:
		var loop: AudioStreamWAV=movement_sound.duplicate()
		loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
		loop.loop_end=loop.data.size()/(4 if loop.stereo else 2)
		_motor.stream=loop
	else: _motor.stream=movement_sound
	add_child(_motor)
	_cue=AudioStreamPlayer2D.new()
	_cue.bus=&"SFX"
	_cue.volume_db=-15
	add_child(_cue)
	_hints=Hints.new()
	add_child(_hints)
	_hints.offer(func() -> Vector2: return platform.position,func() -> String: return "T" if interaction_enabled and is_rider(_actor) and not is_moving() else "",platform_width+40,Vector2(0,-92),func() -> Vector2: return _actor.position if is_rider(_actor) else Vector2.INF)

func is_moving() -> bool:
	return state==State.MOVING_UP or state==State.MOVING_DOWN

func is_rider(actor: CharacterBody2D) -> bool:
	if not is_instance_valid(actor) or not actor.is_on_floor(): return false
	for index in actor.get_slide_collision_count():
		if actor.get_slide_collision(index).get_collider()==platform: return true
	var feet:=actor.global_position+Vector2(0,22)
	var point:=platform.to_local(feet)
	return absf(point.x)<platform_width/2+3 and absf(point.y)<10

func activate() -> bool:
	if not interaction_enabled or is_moving() or not WorldProgress.can_play(): return false
	return call_to_stop(state==State.IDLE_BOTTOM)

func call_to_stop(at_top: bool) -> bool:
	if not interaction_enabled or is_moving() or not WorldProgress.can_play(): return false
	var destination:=top_position if at_top else bottom_position
	if platform.position.distance_to(destination)<.1: return false
	state=State.MOVING_UP if at_top else State.MOVING_DOWN
	_speed=0
	_shake=.2
	_empty_seconds=0
	_play(start_sound)
	if _motor.stream!=null: _motor.play()
	movement_started.emit(at_top)
	return true

func _play(stream: AudioStream) -> void:
	if stream==null: return
	_cue.stream=stream
	_cue.position=platform.position
	_cue.play()

func _physics_process(delta: float) -> void:
	_actor=get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	_hints.actor=_actor
	_motor.stream_paused=not WorldProgress.can_play()
	if not WorldProgress.can_play(): return
	_clock+=delta
	_shake=maxf(0,_shake-delta)
	if is_moving():
		var destination:=top_position if state==State.MOVING_UP else bottom_position
		var distance:=platform.position.distance_to(destination)
		var desired_speed:=minf(move_speed,sqrt(2*maxf(1,deceleration)*distance))
		_speed=move_toward(_speed,desired_speed,(acceleration if desired_speed>_speed else deceleration)*delta)
		var motion: Vector2=(destination-platform.position).normalized()*minf(distance,_speed*delta)
		var parameters:=PhysicsTestMotionParameters2D.new()
		parameters.from=platform.global_transform
		parameters.motion=motion
		parameters.margin=.04
		var result:=PhysicsTestMotionResult2D.new()
		if PhysicsServer2D.body_test_motion(platform.get_rid(),parameters,result):
			# Never tunnel through architecture. An obstruction leaves a stationary
			# platform that can be recalled in the opposite direction.
			platform.position+=result.get_travel()
			state=State.IDLE_TOP if state==State.MOVING_UP else State.IDLE_BOTTOM
			_speed=0
			_motor.stop()
			_play(dock_sound)
			obstructed.emit()
		else:
			platform.position+=motion
			_motor.position=platform.position
			_motor.pitch_scale=.7+.25*clampf(_speed/maxf(1,move_speed),0,1)
			if distance<=maxf(.1,motion.length()+.01):
				platform.position=destination
				var at_top:=state==State.MOVING_UP
				state=State.IDLE_TOP if at_top else State.IDLE_BOTTOM
				_speed=0
				_shake=.15
				_motor.stop()
				_play(dock_sound)
				arrived.emit(at_top)
	elif automatic_return and state==State.IDLE_TOP:
		_empty_seconds=0 if is_rider(_actor) else _empty_seconds+delta
		if _empty_seconds>=return_delay: call_to_stop(false)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if handle_input and event.is_action_pressed(&"eden_talk") and is_rider(_actor) and activate():
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if not is_instance_valid(platform): return
	var point:=platform.position
	var top:=minf(top_position.y,bottom_position.y)-55
	var bottom:=maxf(top_position.y,bottom_position.y)+34
	for side in [-1,1]:
		var x: float=side*(platform_width/2-12)
		draw_line(Vector2(x,top),Vector2(x,bottom),Color("242b25"),6)
		draw_line(Vector2(x+1,top),Vector2(x+1,bottom),Color("626654"),2)
		for y in range(int(top),int(point.y-24),13):
			var shift:=fposmod(_clock*_speed*.2,13) if is_moving() else 0.0
			draw_rect(Rect2(x-3,y+shift,6,9),Color("9a9472"),false,2)
		Art.draw_at(self,3,Rect2(x-20,top-14,40,30))
	var shake:=Vector2(sin(_clock*91)*_shake*5,0)
	Art.draw_at(self,0,Rect2(point+shake+Vector2(-platform_width/2,0),Vector2(platform_width,58)))
	draw_line(point+Vector2(-platform_width/2,1),point+Vector2(platform_width/2,1),Color("d4c18b"),2)
	for side in [-1,1]:
		Art.draw_at(self,9,Rect2(point+shake+Vector2(side*(platform_width/2-12)-8,-29),Vector2(16,45)))

func _exit_tree() -> void:
	if is_instance_valid(_motor):
		_motor.stop()
		_motor.stream=null
	if is_instance_valid(_cue):
		_cue.stop()
		_cue.stream=null
