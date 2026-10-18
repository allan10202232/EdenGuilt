extends Node2D
const PlatformScene=preload("res://scenes/mine_challenge/mineralized_platform.tscn")
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
@export var width := 112.0
@export var duration := 4.0
@export var powered := true
@export var vent_id := "vent"
var platform: StaticBody2D
var gas_area: Area2D
var _clock := 0.0
var _particles: CPUParticles2D

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	gas_area=Area2D.new()
	gas_area.collision_layer=0
	gas_area.collision_mask=2
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(width,68)
	shape.shape=box
	shape.position.y=-25
	gas_area.add_child(shape)
	add_child(gas_area)
	_particles=CPUParticles2D.new()
	_particles.amount=clampi(int(width/5),26,100)
	_particles.lifetime=1.25
	_particles.preprocess=.7
	_particles.texture=Art.puff_texture()
	_particles.direction=Vector2.UP
	_particles.spread=24
	_particles.initial_velocity_min=23
	_particles.initial_velocity_max=54
	_particles.gravity=Vector2(0,-10)
	_particles.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents=Vector2(width*.41,5)
	_particles.position.y=3
	_particles.angular_velocity_min=-13
	_particles.angular_velocity_max=13
	_particles.scale_amount_min=.12
	_particles.scale_amount_max=.28
	var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.18,.65,1])
	gradient.colors=PackedColorArray([Color(.25,.54,.1,0),Color(.48,.77,.16,.45),Color(.56,.76,.24,.24),Color(.43,.64,.18,0)])
	_particles.color_ramp=gradient
	add_child(_particles)
	set_powered(powered)

func set_powered(value: bool) -> void:
	powered=value
	if is_instance_valid(_particles): _particles.emitting=powered and not is_instance_valid(platform)
	queue_redraw()

func mineralize() -> bool:
	if not powered or is_instance_valid(platform): return false
	platform=PlatformScene.instantiate()
	platform.width=width
	platform.lifetime=duration
	add_child(platform)
	platform.shattered.connect(_on_shattered)
	_particles.emitting=false
	# Already airborne particles fade naturally instead of disappearing.
	queue_redraw()
	return true

func _on_shattered() -> void:
	platform=null
	_particles.emitting=powered
	queue_redraw()

func reset() -> void:
	if is_instance_valid(platform):
		remove_child(platform)
		platform.queue_free()
	platform=null
	set_powered(powered)

func _process(delta: float) -> void:
	if WorldProgress.can_play(): _clock+=delta
	if is_instance_valid(_particles): _particles.speed_scale=1.0 if WorldProgress.can_play() else 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not powered or is_instance_valid(platform) or not WorldProgress.can_play(): return
	for actor in gas_area.get_overlapping_bodies():
		if actor.has_method(&"touch_gas"): actor.touch_gas(delta)

func _draw() -> void:
	# Rusted jets explain the source of each plume, including inactive relays.
	var nozzles:=maxi(1,int(width/180))
	for index in nozzles:
		var x: float=(index+.5)*width/nozzles-width/2
		Art.draw_at(self,4,Rect2(x-23,6,46,25),Color(.66,.72,.67) if not powered else Color(.9,.95,.83))
	if not powered or is_instance_valid(platform): return
	# Authored vapor silhouettes and rising particles break up the gas outline.
	for band in 3:
		var sway:=sin(_clock*1.9+band*1.7)*8
		var size:=Vector2(width*(1.0+band*.10),46+band*8)
		Art.draw_at(self,15,Rect2(Vector2(sway-size.x/2,-30-band*15),size),Color(.58,.79,.28,.19-band*.035))
