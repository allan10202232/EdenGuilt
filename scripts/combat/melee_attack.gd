class_name MeleeAttack
extends Node2D
## Generic melee template: no input, stats, autoload, audio or animation dependency.

signal attack_started(profile: MeleeAttackProfile)
signal phase_changed(phase: Phase)
signal target_hit(receiver: Node, hit: Dictionary)
signal attack_finished
signal attack_cancelled

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY, COOLDOWN }

@export var profile: MeleeAttackProfile
@export_flags_2d_physics var target_mask: int = 4
@export_flags_2d_physics var obstruction_mask: int = 1
@export var show_hitbox: bool = false
@export var show_placeholder_weapon: bool = true

var phase: Phase = Phase.IDLE
var _source: Node2D
var _availability: Callable
var _move: MeleeAttackProfile
var _remaining: float = 0.0
var _facing: float = 1.0
var _hit_receivers: Dictionary = {}
var _shape := RectangleShape2D.new()
var impact_pause := 0.0


func _ready() -> void:
	if _source == null:
		_source = get_parent() as Node2D


func setup(source: Node2D, availability: Callable = Callable()) -> void:
	cancel()
	_source = source
	_availability = availability


func is_busy() -> bool:
	return phase != Phase.IDLE


func try_attack(facing: float) -> bool:
	if is_busy() or not _allowed() or profile == null or not profile.is_usable() or not is_finite(facing) or facing == 0.0:
		return false
	# Resources are shared. Snapshot each attack so editing a preset cannot change a live hit.
	_move = profile.duplicate(true) as MeleeAttackProfile
	impact_pause = 0.0
	_facing = signf(facing)
	_hit_receivers.clear()
	_shape.size = Vector2(_move.reach, _move.height)
	_set_phase(Phase.WINDUP, _move.windup)
	attack_started.emit(_move)
	return true


func cancel() -> void:
	impact_pause = 0.0
	if not is_busy():
		return
	_set_phase(Phase.IDLE, 0.0)
	_move = null
	_hit_receivers.clear()
	attack_cancelled.emit()


func _physics_process(delta: float) -> void:
	if not is_busy():
		return
	if not _allowed():
		cancel()
		return
	if impact_pause > 0.0:
		impact_pause = maxf(0.0, impact_pause - delta)
		return
	_remaining -= delta
	while _remaining <= 0.0 and is_busy():
		var overshoot := -_remaining
		match phase:
			Phase.WINDUP:
				_set_phase(Phase.ACTIVE, _move.active_time)
				_sample_targets()
			Phase.ACTIVE:
				_set_phase(Phase.RECOVERY, _move.recovery)
			Phase.RECOVERY:
				_set_phase(Phase.COOLDOWN, _move.cooldown)
			Phase.COOLDOWN:
				_set_phase(Phase.IDLE, 0.0)
				_move = null
				_hit_receivers.clear()
				attack_finished.emit()
		_remaining -= overshoot
	if phase == Phase.ACTIVE:
		_sample_targets()
	queue_redraw()


func _allowed() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and is_instance_valid(_source) and _source.is_inside_tree() and not _source.is_queued_for_deletion() and (_availability.is_null() or (_availability.is_valid() and bool(_availability.call())))


func _set_phase(next: Phase, duration: float) -> void:
	phase = next
	_remaining = duration
	phase_changed.emit(phase)
	queue_redraw()


func _hit_rect() -> Rect2:
	var left := _move.forward_offset if _facing > 0.0 else -_move.forward_offset - _move.reach
	return Rect2(left, _move.vertical_offset - _move.height * 0.5, _move.reach, _move.height)


func phase_progress() -> float:
	if _move == null: return 0.0
	var duration: float = _move.windup if phase == Phase.WINDUP else _move.active_time if phase == Phase.ACTIVE else _move.recovery if phase == Phase.RECOVERY else _move.cooldown
	return clampf(1.0 - _remaining / maxf(0.001, duration), 0.0, 1.0)


func _sample_targets() -> void:
	if not _allowed() or _move == null:
		return
	var exclusions: Array[RID] = []
	if _source is CollisionObject2D:
		exclusions.append((_source as CollisionObject2D).get_rid())
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = global_transform * Transform2D(0.0, _hit_rect().get_center())
	query.collision_mask = target_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = exclusions
	var space := get_world_2d().direct_space_state
	for entry: Dictionary in space.intersect_shape(query, 64):
		var collider := entry.collider as Node2D
		if not is_instance_valid(collider) or collider == _source or _source.is_ancestor_of(collider):
			continue
		var receiver: Node = collider.call(&"get_melee_receiver") if collider.has_method(&"get_melee_receiver") else collider
		if not is_instance_valid(receiver) or receiver == _source or _source.is_ancestor_of(receiver) or not receiver.has_method(&"receive_melee_hit"):
			continue
		var identity := receiver.get_instance_id()
		if _hit_receivers.has(identity):
			continue
		if obstruction_mask != 0:
			var ray := PhysicsRayQueryParameters2D.create(to_global(Vector2(0, _move.vertical_offset)), collider.global_position, obstruction_mask, exclusions)
			ray.hit_from_inside = true
			if not space.intersect_ray(ray).is_empty():
				continue
		# Mark before calling gameplay, which can synchronously emit other events.
		_hit_receivers[identity] = true
		var hit := {
			"attack_id": _move.id, "damage": _move.damage, "source": _source,
			"position": collider.global_position,
			"knockback": Vector2(_move.knockback.x * _facing, _move.knockback.y).rotated(global_rotation),
		}
		if bool(receiver.call(&"receive_melee_hit", hit)):
			target_hit.emit(receiver, hit)
		# A hit callback may remove the ability, cancel the attack or remove its owner.
		if not is_inside_tree() or not is_busy() or not _allowed():
			return


func _draw() -> void:
	if _move == null or phase == Phase.IDLE or phase == Phase.COOLDOWN:
		return
	var rect := _hit_rect()
	var tint := _move.color
	var alpha := 0.32 if phase == Phase.ACTIVE else 0.08
	if show_hitbox:
		draw_rect(rect, Color(tint, alpha))
		draw_rect(rect, Color(tint, 0.8 if phase == Phase.ACTIVE else 0.25), false, 1.5)
	if phase == Phase.ACTIVE and show_placeholder_weapon:
		var origin := Vector2(_facing * _move.forward_offset, _move.vertical_offset)
		var tip := Vector2(_facing * (_move.forward_offset + _move.reach), _move.vertical_offset)
		draw_line(origin, tip, tint, 5.0)
		draw_line(tip + Vector2(-_facing * 14.0, -10), tip, tint, 3.0)
		draw_line(tip, tip + Vector2(-_facing * 14.0, 10), tint, 3.0)
