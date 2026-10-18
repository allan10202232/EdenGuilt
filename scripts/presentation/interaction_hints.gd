extends Node2D
## One world-space affordance style; predicates mirror each interaction's range.
const FONT=preload("res://assets/ui_theme.tres").default_font
const RADIUS:=19.0
var actor: CharacterBody2D
var entries: Array[Dictionary]=[]
var _clock:=0.0

func _ready() -> void:
	z_index=80
	z_as_relative=false
	add_to_group(&"interaction_hints")

func offer(point: Callable, key: Callable, radius: float, offset:=Vector2(0,-80), origin: Callable=Callable()) -> void:
	entries.append({"point":point,"key":key,"radius":radius,"offset":offset,"origin":origin,"alpha":0.0,"shown":false,"text":""})

func _process(delta: float) -> void:
	_clock+=delta
	for entry in entries:
		entry.shown=false
		if is_instance_valid(actor) and WorldProgress.can_play():
			var point: Vector2=entry.point.call()
			var origin: Vector2=entry.origin.call() if entry.origin.is_valid() else point
			if actor.position.distance_to(origin)<entry.radius:
				entry.text=entry.key.call()
				entry.shown=not entry.text.is_empty()
		entry.alpha=move_toward(entry.alpha,1.0,delta*9.0) if entry.shown else 0.0
	queue_redraw()

func visible_keys() -> Array[String]:
	var result: Array[String]=[]
	for entry in entries:
		if entry.shown: result.append(entry.text)
	return result

func _draw() -> void:
	for entry in entries:
		if not entry.shown: continue
		var point: Vector2=entry.point.call()+entry.offset+Vector2(0,sin(_clock*2.5)*1.5)
		var alpha: float=entry.alpha
		draw_circle(point+Vector2(0,3),RADIUS+2,Color(0.015,0.012,0.01,alpha*.65))
		draw_circle(point,RADIUS,Color(0.075,0.061,0.045,alpha*.96))
		draw_arc(point,RADIUS,0,TAU,64,Color(.78,.65,.4,alpha),1.5,true)
		draw_arc(point,RADIUS-3,PI*1.12,PI*1.88,24,Color(.99,.9,.66,alpha*.7),1,true)
		draw_circle(point+Vector2(0,RADIUS+6),1.5,Color(.83,.7,.46,alpha))
		var size:=17 if entry.text.length()==1 else 13
		var width:=FONT.get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		var baseline:=point+Vector2(-width/2,FONT.get_ascent(size)*.36)
		draw_string_outline(FONT,baseline,entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,3,Color(0,0,0,alpha))
		draw_string(FONT,baseline,entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(1,.96,.85,alpha))
