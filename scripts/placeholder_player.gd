extends CharacterBody2D
## Placeholder input adapter ONLY. A replaces movement, combat, timing and visuals.

signal slash_requested(facing: float)

const SPEED: float = 270.0
const JUMP_SPEED: float = -620.0
const GRAVITY: float = 1450.0

@onready var stats: PlaceholderStats = $Stats
var _invulnerability: float = 0.0
var _jumps_used: int = 0
var _dash_remaining: float = 0.0
var _dash_recovery: float = 0.0
var _slash_flash: float = 0.0
var _facing: float = 1.0


func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play():
		return
	_invulnerability = maxf(0.0, _invulnerability - delta)
	modulate.a = 0.45 if _invulnerability > 0.0 and int(_invulnerability * 15.0) % 2 else 1.0
	_dash_remaining = maxf(0.0, _dash_remaining - delta)
	_dash_recovery = maxf(0.0, _dash_recovery - delta)
	_slash_flash = maxf(0.0, _slash_flash - delta)
	var axis := Input.get_axis(&"eden_move_left", &"eden_move_right")
	if axis != 0.0:
		_facing = signf(axis)
	var running := Input.is_action_pressed(&"eden_run")
	velocity.x = axis * SPEED * (1.45 if running else 1.0)
	if running and Input.is_action_just_pressed(&"eden_run") and _dash_recovery <= 0.0 and WorldProgress.has_ability(&"dash"):
		_dash_remaining = 0.16
		_dash_recovery = 0.65
		WorldProgress.report_ability_used(&"dash")
	if not WorldProgress.has_ability(&"dash"):
		_dash_remaining = 0.0
	if _dash_remaining > 0.0:
		velocity.x = _facing * SPEED * 3.0
	if is_on_floor():
		_jumps_used = 0
	elif _jumps_used == 0:
		_jumps_used = 1
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var jump_limit := 2 if WorldProgress.has_ability(&"double_jump") else 1
	if Input.is_action_just_pressed(&"eden_jump") and _jumps_used < jump_limit:
		_jumps_used += 1
		velocity.y = JUMP_SPEED
		if _jumps_used == 2:
			WorldProgress.report_ability_used(&"double_jump")
		else:
			SoundManager.play_sfx(&"jump", -10.0)
	var was_shielded := WorldProgress.shield_active
	WorldProgress.set_shield_active(Input.is_action_pressed(&"eden_shield"))
	if WorldProgress.shield_active and not was_shielded:
		WorldProgress.report_ability_used(&"shield")
	move_and_slide()
	queue_redraw()
	if global_position.y > 840.0:
		GameSession.player_died(&"fall")


func _unhandled_input(event: InputEvent) -> void:
	if not WorldProgress.can_play():
		return
	if event.is_action_pressed(&"eden_slash") and WorldProgress.report_ability_used(&"light_blade"):
		_slash_flash = 0.12
		slash_requested.emit(_facing)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if WorldProgress.shield_active:
		draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 32, Color(0.45, 0.8, 0.95), 3.0)
	if _slash_flash > 0.0:
		draw_line(Vector2(_facing * 14.0, 0), Vector2(_facing * 85.0, -18), Color(0.95, 0.92, 0.65), 7.0)


func hurt(amount: int) -> void:
	if _invulnerability > 0.0 or not WorldProgress.can_play() or WorldProgress.shield_active:
		return
	_invulnerability = 0.85
	SoundManager.play_sfx(&"hurt")
	stats.take_damage(amount)
