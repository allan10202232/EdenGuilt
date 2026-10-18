class_name LearningRitual
extends Node2D
## Life leaves the soil before a skill is granted. No cost is recorded for learning.
var player: CharacterBody2D
var ability: StringName
var starts: Array[Vector2] = []
var elapsed := 0.0
var granted := false
var _caption: Label

func begin(actor: CharacterBody2D, id: StringName, growth: Array[Vector2]) -> void:
	player=actor
	ability=id
	for point in growth:
		if point.distance_to(player.position)<680.0: starts.append(point-Vector2(0,8))
	WorldProgress.narrative_active=true
	WorldProgress.narrative_kind=&"learning"
	player.velocity=Vector2.ZERO
	player.combat.cancel()
	WorldProgress.set_shield_active(false)
	if player._art!=null:
		player._art.play_action(&"channel",1.5)
	_caption=Label.new()
	_caption.theme=preload("res://assets/ui_theme.tres")
	_caption.add_theme_font_size_override(&"font_size",22)
	_caption.add_theme_color_override(&"font_outline_color",Color(0.02,0.04,0.02))
	_caption.add_theme_constant_override(&"outline_size",5)
	_caption.position=player.position+Vector2(-190,-145)
	_caption.text=GameText.t("大地的余绿正在汇聚……")
	add_child(_caption)
	z_index=40
	SoundManager.play_sfx(&"absorb",-8,0.8)

func _process(delta: float) -> void:
	if not is_instance_valid(player) or GameSession.state!=GameSession.State.PLAYING:
		cancel()
		return
	elapsed+=delta
	if not granted and elapsed>=1.5:
		WorldProgress.narrative_active=false
		WorldProgress.narrative_kind=&""
		granted=WorldProgress.borrow_ability(ability)
		if not granted:
			queue_free()
			return
		_caption.text=GameText.t("新能力：%s") % AbilityCatalog.definition(ability).name
		_caption.modulate=Color(0.76,0.95,0.58)
		if player._art!=null: player._art.play_action(&"channel",0.5)
	if elapsed>=2.25:
		queue_free()
	queue_redraw()

func cancel() -> void:
	if WorldProgress.narrative_kind==&"learning":
		WorldProgress.narrative_active=false
		WorldProgress.narrative_kind=&""
	queue_free()

func _draw() -> void:
	if not is_instance_valid(player): return
	var target:=player.position-Vector2(0,22)
	var progress:=clampf(elapsed/1.5,0,1)
	for index in starts.size():
		var delay:=float(index%7)*0.045
		var t:=clampf((progress-delay)/(1.0-delay),0,1)
		var point:=starts[index].lerp(target,t*t)
		point+=Vector2(sin(t*PI)*sin(index*2.3)*80,-sin(t*PI)*(50+index%4*18))
		var alpha:=1.0 if not granted else maxf(0.0,1.0-(elapsed-1.5)/0.5)
		draw_circle(point,7,Color(0.48,0.84,0.32,0.10*alpha))
		draw_circle(point,2.0,Color(0.76,0.97,0.52,alpha))
		draw_line(point,point+Vector2(4,-5).rotated(index+elapsed*3),Color(0.57,0.86,0.37,alpha),2,true)
	if progress>0.65:
		var radius:=18+(1.0-progress)*60 if not granted else 18+(elapsed-1.5)*90
		draw_arc(target,radius,elapsed*3,elapsed*3+TAU*0.85,48,Color(0.72,0.93,0.4,maxf(0.0,1.0-(elapsed-1.5)/0.75)),2,true)
