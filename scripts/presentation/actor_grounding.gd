class_name ActorGrounding
extends Node2D
## Ray-projected contact shadow. It never invents a floor across a gap.

var actor: CharacterBody2D
var foot_height := 24.0
var radius := 17.0
var ground_mask := 1
var ground_distance := 0.0
var has_ground := false
var contact := Vector2.ZERO
var light_energy := 0.0
var light_tint := Color(0.94,0.39,0.19)

func bind(owner_actor: CharacterBody2D, feet: float, width: float, mask: int) -> void:
	actor = owner_actor
	foot_height = feet
	radius = width
	ground_mask = mask
	z_index = -4 if feet == 24.0 else -1

static func ambient_color() -> Color:
	match WorldProgress.current_scene:
		&"grassland": return Color(0.80, 0.85, 1.0)
		&"remnant_sea": return Color(1.0, 0.98, 0.86)
		_: return Color(0.95, 1.0, 0.78)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(actor): return
	var start := actor.global_position + Vector2(0, foot_height - 3.0)
	var ray := PhysicsRayQueryParameters2D.create(start, start + Vector2(0, 225), ground_mask, [actor.get_rid()])
	var hit := actor.get_world_2d().direct_space_state.intersect_ray(ray)
	has_ground = not hit.is_empty() and hit.normal.y < -0.5
	if has_ground:
		ground_distance = maxf(0.0, hit.position.y - actor.global_position.y - foot_height)
		contact = to_local(hit.position) + Vector2(0,-1)
	queue_redraw()

func _draw() -> void:
	if not has_ground: return
	var lift := clampf(ground_distance / 200.0, 0.0, 1.0)
	var width := lerpf(radius, radius * 0.48, lift)
	var alpha := lerpf(0.40, 0.08, lift)
	for band in 3:
		var inset := float(abs(band - 1)) * width * 0.25
		draw_rect(Rect2((contact + Vector2(-width + inset, -3 + band * 2)).round(), Vector2((width-inset)*2, 2)), Color(0.035,0.045,0.035,alpha))
	if light_energy > 0.0:
		var tint := light_tint
		for ring in range(4,0,-1):
			draw_set_transform(contact.round(),0.0,Vector2(1,0.22))
			draw_circle(Vector2.ZERO,12.0+ring*7.0,Color(tint,light_energy*(1.0-lift)*0.025))
			draw_set_transform(Vector2.ZERO)
