extends Node2D
## Art-based crystal fragments, settling dust and short formation blooms. This
## effect has no collider and cannot create a permanent foothold.
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
var _kind: StringName=&"formation"
var _age:=0.0
var _particles: Array[Dictionary]=[]

static func burst(parent: Node2D, point: Vector2, kind: StringName=&"formation") -> Node2D:
	var effect:=new()
	effect.position=point
	effect._kind=kind
	parent.add_child(effect)
	return effect

static func spawn(source: Node2D, kind: StringName=&"formation") -> Node2D:
	var parent:=source.get_parent() as Node2D
	if parent==null: return null
	return burst(parent,parent.to_local(source.global_position),kind)

func _ready() -> void:
	z_index=9
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var count:=18 if _kind==&"shatter" else 14
	for index in count:
		var phase:=TAU*index/count+.27
		var speed:=48.0+fmod(index*31,118)
		_particles.append({"point":Vector2(cos(phase)*10,sin(phase)*4),"velocity":Vector2(cos(phase)*speed,-38-absf(sin(phase))*speed),"size":3.5+fmod(index*13,7),"angle":phase,"spin":-3.0+fmod(index*7,6)})

func _process(delta: float) -> void:
	if not WorldProgress.can_play(): return
	_age+=delta
	for particle in _particles:
		particle.velocity.y+=310*delta
		particle.point+=particle.velocity*delta
		particle.angle+=particle.spin*delta
	queue_redraw()
	if _age>=.8: queue_free()

func _draw() -> void:
	var fade:=clampf(1-_age/.8,0,1)
	var tint:=Color(.62,.86,.46,fade*.7) if _kind==&"acid" else Color(.82,.72,1,fade)
	var glow_size:=Vector2(115,70)*(1+_age*1.2)
	draw_texture_rect(Art.puff_texture(),Rect2(-glow_size/2,glow_size),false,Color(tint.r,tint.g,tint.b,fade*.28))
	for particle in _particles:
		var size:=Vector2(particle.size,particle.size*1.6)
		if _kind in [&"formation",&"resonance"]:
			size*=clampf(_age*8,0,1)
		draw_set_transform(particle.point,particle.angle)
		draw_texture_rect(Art.texture(12),Rect2(-size/2,size),false,tint)
	draw_set_transform(Vector2.ZERO)
