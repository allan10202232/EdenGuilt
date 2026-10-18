class_name RoomTransitionController
extends Node
## A child of the existing scene host, never a second global scene manager.
signal finished
signal arrived
var busy:=false
var phase: StringName=&"idle"
var completed_count:=0
var history: Array[Dictionary]=[]
var _cooldown:=0.0
var _generation:=0
var _black: ColorRect
var _tween: Tween
var _camera: Camera2D
var _camera_home:=Vector2.ZERO

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var layer:=CanvasLayer.new()
	layer.layer=100
	add_child(layer)
	_black=ColorRect.new()
	_black.color=Color(0,0,0,0)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter=Control.MOUSE_FILTER_STOP
	_black.hide()
	layer.add_child(_black)

func _process(delta: float) -> void:
	_cooldown=maxf(0,_cooldown-delta)

func request(commit: Callable,options: Dictionary={}) -> bool:
	if busy or _cooldown>0 or not commit.is_valid(): return false
	busy=true
	_generation+=1
	WorldProgress.scene_transition_active=true
	WorldProgress.set_shield_active(false)
	_black.show()
	_run.call_deferred(commit,options.duplicate(true),_generation)
	return true

func resolve_options(options: Dictionary,room: Node,scene_path: String,region: StringName=&"") -> Dictionary:
	var result:=options.duplicate(true)
	if bool(options.get("return_to_previous",false)):
		if history.is_empty(): return {}
		result.merge(history.back(),true)
		result["_history_return"]=true
	var actor:=get_tree().get_first_node_in_group(&"player") as Node2D
	var marker:=RoomSpawnPoint.nearest(room,actor.global_position) if actor!=null else null
	var id: StringName=options.get("source_spawn_id",&"")
	if id==&"" and marker!=null: id=marker.spawn_id
	result["_origin"]={"target_scene":scene_path,"target_region":region,"target_spawn_id":id}
	return result

func _run(commit: Callable,options: Dictionary,token: int) -> void:
	phase=&"fade_out"
	var actor:=get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if actor!=null:
		actor.velocity=Vector2.ZERO
		var combat: Node=actor.get("combat")
		if combat!=null and combat.has_method("cancel"): combat.cancel()
		_camera=actor.get_node_or_null("Camera2D") as Camera2D
	var direction: Vector2=options.get("entry_direction",Vector2.RIGHT)
	_tween=create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var out_time:=maxf(.01,float(options.get("fade_out_duration",.15)))
	_tween.tween_property(_black,"color:a",1.0,out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(_camera):
		_camera_home=_camera.position
		_tween.tween_property(_camera,"position",_camera_home+direction.normalized()*14,out_time)
	await _tween.finished
	if token!=_generation: return
	if is_instance_valid(_camera): _camera.position=_camera_home
	phase=&"loading"
	# Initialization can establish checkpoints synchronously. No input or physics
	# frame is allowed between removing and reapplying the fade lock.
	WorldProgress.scene_transition_active=false
	var room: Node=commit.call()
	if token!=_generation: return
	WorldProgress.scene_transition_active=true
	if room!=null:
		if options.get("_history_return",false): history.pop_back()
		elif options.has("_origin"): history.append(options._origin)
		actor=get_tree().get_first_node_in_group(&"player") as CharacterBody2D
		var id: StringName=options.get("target_spawn_id",&"")
		if actor!=null and id!=&"":
			var marker:=RoomSpawnPoint.find_in(room,id)
			if marker!=null:
				marker.place(actor)
				WorldProgress.confirm_arrival(actor.position)
		if actor!=null:
			_camera=actor.get_node_or_null("Camera2D") as Camera2D
			if _camera!=null:
				_camera.reset_smoothing()
				_camera.force_update_scroll()
	arrived.emit()
	await get_tree().process_frame
	if token!=_generation: return
	phase=&"fade_in"
	_tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_black,"color:a",0.0,maxf(.01,float(options.get("fade_in_duration",.25)))).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _tween.finished
	if token!=_generation: return
	_black.hide()
	WorldProgress.scene_transition_active=false
	WorldProgress.finish_scene_load()
	WorldProgress.pending_transition.clear()
	busy=false
	phase=&"idle"
	_cooldown=.18
	WorldProgress.transition_rearm_seconds=.18
	completed_count+=1
	finished.emit()

func cancel() -> void:
	_generation+=1
	if _tween!=null and _tween.is_running(): _tween.kill()
	if is_instance_valid(_camera) and phase==&"fade_out": _camera.position=_camera_home
	busy=false
	phase=&"idle"
	_cooldown=0
	if is_instance_valid(_black):
		_black.color.a=0
		_black.hide()
	WorldProgress.scene_transition_active=false

func _exit_tree() -> void:
	cancel()

func clear_history() -> void:
	history.clear()
