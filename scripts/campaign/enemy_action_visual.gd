class_name EnemyActionVisual
extends Node2D
## Animation is visual only: defeated actors release this node before leaving play.

const FEET := {
	"scrap_scavenger": [253,255,255,253,252,255,255,255,255,255,255,255,250,249,249,249,249,251,238,237,189,238,236,233],
	"crystal_miner": [239,238,238,238,237,240,241,241,240,240,240,245,238,238,238,238,237,235,229,227,198,229,227,232],
	"forest_crawler": [233,231,231,229,230,229,236,237,239,237,236,238,220,220,220,223,223,224,226,225,223,227,226,226],
	"eden_warden": [241,243,243,243,240,242,245,245,245,247,245,244,232,232,232,236,233,229,239,233,214,230,233,231],
}

var sprite: Sprite2D
var actor: CharacterBody2D
var pose: StringName = &"idle"
var _time: float = 0.0
var _strike_time: float = 0.0
var _hurt_time: float = 0.0
var _landing_time: float = 0.0
var _death_time: float = -1.0
var _was_grounded: bool = false
var _base_y: float = 0.0
var _lighting: ShaderMaterial
var _species: String


func setup(enemy: CharacterBody2D) -> void:
	actor = enemy
	name = "EnemyActions"
	sprite = Sprite2D.new()
	var species: String = "eden_warden" if actor.boss else actor.kind
	_species = species
	sprite.texture = load("res://assets/art/generated/animations/%s_actions.png" % species)
	sprite.hframes = 6
	sprite.vframes = 4
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame_size := sprite.texture.get_size() / Vector2(6, 4)
	var visual_height: float = 136.0 if actor.boss else 70.0
	sprite.scale = Vector2.ONE * visual_height / (frame_size.y * 0.84)
	_base_y = (44.0 if actor.boss else 20.0) - frame_size.y * 0.42 * sprite.scale.y
	sprite.position.y = _base_y
	add_child(sprite)
	_lighting=ShaderMaterial.new()
	_lighting.shader=preload("res://assets/shaders/actor_lighting.gdshader")
	_lighting.set_shader_parameter("logical_pixels",Vector2(92,92) if not actor.boss else Vector2(160,160))
	_lighting.set_shader_parameter("ambient",ActorGrounding.ambient_color())
	sprite.material=_lighting


func strike() -> void:
	_strike_time = 0.34


func hurt() -> void:
	_hurt_time = 0.18
	pose = &"hurt"
	sprite.frame = 15
	_lighting.set_shader_parameter("flash",0.95)


func release_death() -> void:
	actor = null
	_death_time = 0.0
	pose = &"death"
	process_mode = Node.PROCESS_MODE_ALWAYS
	# This detached visual has no collision, scoring, AI or progression callbacks.


func _process(delta: float) -> void:
	if _death_time >= 0.0:
		_death_time += delta
		sprite.frame = 22 if _death_time < 0.2 else 23
		sprite.rotation = lerpf(sprite.rotation, 0.08 * (-1 if sprite.flip_h else 1), delta * 6)
		modulate.a = clampf((0.62 - _death_time) / 0.26, 0.0, 1.0)
		if _death_time >= 0.62:
			queue_free()
		return
	if not is_instance_valid(actor) or not WorldProgress.can_play():
		return
	_lighting.set_shader_parameter("flash",0.95 if _hurt_time>0.10 else 0.0)
	if actor.impact_pause>0.0: return
	_time += delta
	_strike_time = maxf(0.0, _strike_time - delta)
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_landing_time = maxf(0.0, _landing_time - delta)
	var grounded := actor.is_on_floor()
	if grounded and not _was_grounded:
		_landing_time = 0.12
	_was_grounded = grounded
	sprite.flip_h = actor._direction < 0.0
	sprite.position.y = _base_y
	sprite.modulate = Color(1.0, 0.79, 0.66) if actor.is_enraged() else Color.WHITE
	if _hurt_time > 0.0:
		pose = &"hurt"
		sprite.frame = 15 if _hurt_time > 0.09 else 16
	elif actor._windup > 0.0:
		pose = &"windup"
		var duration: float = 0.75 if actor.boss else 0.55
		sprite.frame = 8 + clampi(int((1.0 - actor._windup / duration) * 3.0), 0, 2)
	elif _strike_time > 0.0:
		pose = &"strike"
		sprite.frame = 11 + clampi(int((0.34 - _strike_time) / 0.085), 0, 3)
	elif actor._hop_charge > 0.0:
		pose = &"crouch"
		sprite.frame = 18
	elif not grounded:
		pose = &"jump" if actor.velocity.y < 0.0 else &"fall"
		sprite.frame = 19 if actor.velocity.y < 0.0 else 20
	elif _landing_time > 0.0:
		pose = &"landing"
		sprite.frame = 21
	elif absf(actor.velocity.x) > 8.0:
		pose = &"walk"
		sprite.frame = int(_time * (9.0 if actor.is_enraged() else 7.0)) % 6
	else:
		pose = &"idle"
		sprite.frame = 6 + int(_time * 2.4) % 2
	if _hurt_time > 0.1:
		sprite.modulate = Color(1.5, 1.35, 1.12)
	if grounded:
		var sole: int = FEET[_species][sprite.frame]
		sprite.position.y = roundf((44.0 if actor.boss else 20.0) - (sole-128)*sprite.scale.y)
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(actor) or not actor.boss or _strike_time <= 0.0:
		return
	var progress := 1.0 - _strike_time / 0.34
	var points := PackedVector2Array()
	for index in 33:
		var angle := PI + PI * index / 32.0
		points.append(Vector2(cos(angle) * 255.0 * progress, 42.0 + sin(angle) * 24.0))
	draw_polyline(points, Color(0.86, 0.66, 0.36, (1.0 - progress) * 0.9), 3.0, true)
