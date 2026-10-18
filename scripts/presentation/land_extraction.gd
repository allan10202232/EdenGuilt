class_name LandExtraction
extends Node2D
## Presentation transaction: no capability or depleted land is committed mid-action.

const DURATION := 2.4

var active := false
var progress := 0.0
var _elapsed := 0.0
var _player: CharacterBody2D
var _oasis: CampaignOasis
var _ability: StringName
var _region: StringName
var _success_flash := 0.0
var _last_focus := Vector2.ZERO


func _init() -> void:
	z_index = 8
	set_process(false)


func begin(actor: CharacterBody2D, oasis: CampaignOasis) -> bool:
	if active or not WorldProgress.can_play() or WorldProgress.ability_state(oasis.ability) != WorldProgress.AbilityState.UNAVAILABLE:
		return false
	if not actor.is_on_floor():
		WorldProgress.set_notice("落地后靠近绿洲，按 E 用吸魂器抽取土地生命力。")
		return false
	_player = actor
	_oasis = oasis
	_ability = oasis.ability
	_region = WorldProgress.current_scene
	_elapsed = 0.0
	progress = 0.0
	_success_flash = 0.0
	active = true
	actor.begin_extraction(oasis.global_position)
	WorldProgress.extraction_active = true
	WorldProgress.set_notice("正在抽取土地生命力……草木和泉水的生机正在汇入吸魂器。")
	SoundManager.play_sfx(&"absorb", -12.0, 0.55)
	set_process(true)
	return true


func _process(delta: float) -> void:
	if active:
		if GameSession.state != GameSession.State.PLAYING or not is_instance_valid(_player) or WorldProgress.current_scene != _region:
			_cancel()
			return
		_elapsed += delta
		progress = minf(1.0, _elapsed / DURATION)
		_player.extraction_progress = progress
		_oasis.set_depletion(smoothstep(0.18, 0.9, progress))
		_last_focus = _player._art.extraction_focus()
		if progress >= 1.0:
			_complete()
	elif _success_flash > 0.0:
		_success_flash = maxf(0.0, _success_flash - delta)
	else:
		set_process(false)
	queue_redraw()


func _complete() -> void:
	# Release the input guard only for the final, synchronous world-state commit.
	WorldProgress.extraction_active = false
	var granted := WorldProgress.borrow_ability(_ability)
	active = false
	_player.finish_extraction()
	_oasis.refresh_state()
	if granted:
		_success_flash = 0.45
		WorldProgress.set_notice("获得%s。眼前的绿洲已经枯竭；这份力量来自土地的生命。" % AbilityCatalog.definition(_ability).name)


func _cancel() -> void:
	active = false
	WorldProgress.extraction_active = false
	if is_instance_valid(_player):
		_player.finish_extraction()
	if is_instance_valid(_oasis):
		_oasis.refresh_state()
	set_process(false)
	queue_redraw()


func _exit_tree() -> void:
	if active:
		_cancel()


func _draw() -> void:
	if active and is_instance_valid(_oasis) and is_instance_valid(_player):
		var target := to_local(_last_focus)
		var ground := to_local(_oasis.global_position)
		var strength := smoothstep(0.12, 0.32, progress) * (1.0 - smoothstep(0.83, 1.0, progress))
		for strand in 4:
			var start := ground + Vector2(-110.0 + strand * 72.0, -8.0)
			var points := PackedVector2Array()
			for index in 19:
				points.append(_flow_point(start, target, float(index) / 18.0, strand))
			draw_polyline(points, Color(0.24, 0.82, 0.43, strength * 0.35), 3.0)
			for index in 6:
				var fraction := fposmod(_elapsed * 0.9 + float(index) / 6.0 + strand * 0.19, 1.0)
				var point := _flow_point(start, target, fraction, strand)
				draw_rect(Rect2(point, Vector2(3, 3)), Color(0.65, 1.0, 0.5, strength))
		var bar := to_local(_player.global_position) + Vector2(-43, 35)
		draw_rect(Rect2(bar - Vector2(2, 2), Vector2(90, 8)), Color(0.025, 0.06, 0.04, 0.9))
		draw_rect(Rect2(bar, Vector2(86.0 * progress, 4)), Color(0.53, 0.94, 0.59))
	elif _success_flash > 0.0:
		var center := to_local(_last_focus)
		var outward := 1.0 - _success_flash / 0.45
		for index in 12:
			var point := center + Vector2.RIGHT.rotated(TAU * index / 12.0) * (6.0 + outward * 38.0)
			draw_rect(Rect2(point.snapped(Vector2(2, 2)), Vector2(3, 3)), Color(0.7, 1.0, 0.53, 1.0 - outward))


func _flow_point(start: Vector2, target: Vector2, fraction: float, strand: int) -> Vector2:
	var point := start.lerp(target, fraction)
	point.y -= sin(fraction * PI) * (35.0 + strand * 9.0)
	point.x += sin(fraction * TAU * 2.0 - _elapsed * 8.0 + strand) * 4.0 * sin(fraction * PI)
	return point.snapped(Vector2(2, 2))
