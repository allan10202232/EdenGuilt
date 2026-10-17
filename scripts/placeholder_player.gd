extends CharacterBody2D
## Deliberately minimal side-view test actor. Programmer A replaces this scene.

const SPEED: float = 270.0
const JUMP_SPEED: float = -620.0
const GRAVITY: float = 1450.0

@onready var stats: PlaceholderStats = $Stats
var _invulnerability: float = 0.0


func _physics_process(delta: float) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	_invulnerability = maxf(0.0, _invulnerability - delta)
	modulate.a = 0.45 if _invulnerability > 0.0 and int(_invulnerability * 15.0) % 2 else 1.0
	velocity.x = Input.get_axis(&"eden_move_left", &"eden_move_right") * SPEED
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif Input.is_action_just_pressed(&"eden_jump"):
		velocity.y = JUMP_SPEED
		SoundManager.play_sfx(&"jump", -10.0)
	move_and_slide()
	if global_position.y > 840.0:
		stats.take_damage(stats.health)


func hurt(amount: int) -> void:
	if _invulnerability > 0.0 or GameSession.state != GameSession.State.PLAYING:
		return
	_invulnerability = 0.85
	SoundManager.play_sfx(&"hurt")
	stats.take_damage(amount)
