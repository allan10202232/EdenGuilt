extends Area2D
signal actor_dissolved(actor: Node2D)
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const AcidShader=preload("res://assets/shaders/mine_acid.gdshader")
const FoamShader=preload("res://assets/shaders/mine_acid_foam.gdshader")
@export var width := 5600.0
@export var depth := 400.0
@export var visual_only := false
var _clock := 0.0
var _foam: Array[Sprite2D]=[]
var _vapor: CPUParticles2D

func _ready() -> void:
	collision_layer=0
	collision_mask=0 if visual_only else 2
	monitoring=not visual_only
	monitorable=not visual_only
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(width,depth)
	shape.position=Vector2(width/2,depth/2)
	shape.shape=box
	add_child(shape)
	body_entered.connect(func(actor: Node2D) -> void: actor_dissolved.emit(actor))
	var surface:=ShaderMaterial.new()
	surface.shader=AcidShader
	material=surface
	var foam_material:=ShaderMaterial.new()
	foam_material.shader=FoamShader
	for index in range(-1,int(ceil(width/280))+1):
		var foam:=Art.sprite(14,Vector2(320,85),Vector2(index*280+140,22),Color(.87,1,.72,.92))
		foam.texture=Art.isolated_texture(14)
		foam.scale=Vector2(320,85)/foam.texture.get_size()
		foam.material=foam_material
		foam.set_meta(&"home_x",foam.position.x)
		add_child(foam)
		_foam.append(foam)
	_vapor=CPUParticles2D.new()
	_vapor.position=Vector2(width/2,-9)
	_vapor.amount=105
	_vapor.lifetime=2.5
	_vapor.preprocess=1.0
	_vapor.texture=Art.puff_texture()
	_vapor.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_vapor.emission_rect_extents=Vector2(width/2,6)
	_vapor.direction=Vector2.UP
	_vapor.spread=30
	_vapor.initial_velocity_min=8
	_vapor.initial_velocity_max=25
	_vapor.gravity=Vector2(0,-3)
	_vapor.scale_amount_min=.15
	_vapor.scale_amount_max=.4
	var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.22,.7,1])
	gradient.colors=PackedColorArray([Color(.48,.62,.12,0),Color(.48,.62,.12,.18),Color(.48,.62,.12,.10),Color(.48,.62,.12,0)])
	_vapor.color_ramp=gradient
	add_child(_vapor)

func _process(delta: float) -> void:
	if WorldProgress.can_play(): _clock+=delta
	if material is ShaderMaterial: material.set_shader_parameter(&"clock",_clock)
	for index in _foam.size():
		var foam:=_foam[index]
		foam.position.x=float(foam.get_meta(&"home_x"))+fmod(_clock*9,280)
		foam.position.y=22+sin(_clock*1.3+index*.9)*3
	if is_instance_valid(_vapor): _vapor.speed_scale=1.0 if WorldProgress.can_play() else 0.0
	queue_redraw()

func _draw() -> void:
	# Water has animated pixel-scale turbulence and an authored broken foam rim.
	draw_rect(Rect2(0,0,width,depth),Color.WHITE)
