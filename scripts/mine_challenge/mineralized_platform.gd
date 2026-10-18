extends StaticBody2D
signal shattered
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const Effects=preload("res://scripts/mine_challenge/mineral_effects.gd")
const Audio=preload("res://scripts/mine_challenge/mine_audio.gd")
@export var width := 112.0
@export var lifetime := 4.0
var remaining := 4.0
var _clock := 0.0
var _warning_tick:=-1

func _ready() -> void:
	remaining=lifetime
	collision_layer=1
	collision_mask=0
	set_meta(&"mineralized",true)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(width,18)
	shape.shape=box
	shape.position.y=9
	shape.one_way_collision=true
	add_child(shape)
	Effects.spawn(self,&"formation")

func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play(): return
	remaining-=delta
	_clock+=delta
	if remaining<=1:
		var tick:=int((1-remaining)*4)
		if tick>_warning_tick:
			_warning_tick=tick
			Audio.play_near(self,&"warning",-15,1+_clock*.025)
	queue_redraw()
	if remaining<=0:
		Effects.spawn(self,&"shatter")
		Audio.play_near(self,&"crystal_break",-9,.9+fmod(width,23)*.01)
		shattered.emit()
		queue_free()

func _draw() -> void:
	var warning:=remaining<=1.0
	var shake:=sin(_clock*65.0)*2.5 if warning else 0.0
	var tint:=Color.WHITE if not warning or sin(_clock*35.0)>0 else Color(.79,.56,.96)
	var emerge:=clampf(_clock/.16,0,1)
	var height:=34.0*(.3+.7*emerge)
	var glow:=Vector2(width+38,70)
	draw_texture_rect(Art.puff_texture(),Rect2(Vector2(-glow.x/2,-27),glow),false,Color(.64,.58,1,.22 if not warning else .12))
	# Collision y=0 remains the bright top edge; only art moves during warning.
	var tile_count:=maxi(1,int(ceil(width/150)))
	var tile_width:=width/tile_count
	for index in tile_count:
		Art.draw_at(self,2,Rect2(-width/2+index*tile_width+shake,-2,tile_width+2,height),tint)
	if warning:
		for index in 3:
			var x: float=-width*.35+index*width*.34+shake
			var depth: float=(1-remaining)*19
			draw_polyline(PackedVector2Array([Vector2(x,2),Vector2(x+5,7),Vector2(x+1,depth)]),Color(.21,.1,.32,.7),1)
