extends Node2D
signal redirected(active: bool)
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Audio=preload("res://scripts/mine_challenge/mine_audio.gd")
const Effects=preload("res://scripts/mine_challenge/mineral_effects.gd")
var active := false
var _feedback:=0.0

func interact() -> void:
	if not WorldProgress.can_play(): return
	active=not active
	_feedback=.3
	Audio.play_near(self,&"lever",-1,.95 if active else .8)
	redirected.emit(active)
	queue_redraw()

func _process(delta: float) -> void:
	if not WorldProgress.can_play(): return
	_feedback=maxf(0,_feedback-delta)
	queue_redraw()

func _draw() -> void:
	# Authored rust, bolts and wood replace the gray bar/circle placeholder.
	var wobble:=sin(_feedback*45)*_feedback*.07
	draw_set_transform(Vector2.ZERO,wobble,Vector2(-1 if active else 1,1))
	Art.draw_at(self,7,Rect2(-32,-73,68,75),Color(.87,1,.83) if active else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	if active:
		draw_texture_rect(Art.puff_texture(),Rect2(-35,-88,76,60),false,Color(.53,.9,.2,.10))
