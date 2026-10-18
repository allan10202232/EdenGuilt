extends CharacterBody2D
## Shared gameplay adapter. Campaign adds artist visuals; integration fixtures retain polygons.

const SPEED: float = 270.0
const JUMP_SPEED: float = -620.0
const GRAVITY: float = 1450.0

@export var campaign_character: bool = false
@export var death_height: float = 840.0

@onready var stats: PlaceholderStats = $Stats
@onready var combat: MeleeCombat = $MeleeCombat
var _invulnerability: float = 0.0
var _jumps_used: int = 0
var _dash_remaining: float = 0.0
var _dash_recovery: float = 0.0
var _facing: float = 1.0
var _art: Sprite2D
var _art_scale: Vector2
var _walk_clock: float = 0.0
var _coyote: float = 0.0
var _jump_buffer: float = 0.0


func _ready() -> void:
	combat.setup(self, _can_melee_attack)
	combat.attack_started.connect(func(_move: MeleeAttackProfile) -> void:
		WorldProgress.report_ability_used(&"light_blade")
	)
	if campaign_character:
		combat.close_attack.show_hitbox = false
		combat.reach_attack.show_hitbox = false
		for part in ["Cape", "Body", "Visor"]:
			get_node(part).hide()
		_art = Sprite2D.new()
		_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_art)
		_update_character()
		WorldProgress.world_changed.connect(_update_character)


func _update_character() -> void:
	if _art == null:
		return
	_art.texture = CampaignLevels.trimmed_texture("characters/hero_green" if WorldProgress.returning else "characters/hero_red")
	if _art.texture != null:
		_art_scale = Vector2.ONE * 78.0 / _art.texture.get_height()
		_art.scale = _art_scale
	_art.position = Vector2(0, -15)


func _can_melee_attack() -> bool:
	return WorldProgress.can_play() and WorldProgress.has_ability(&"light_blade")


func face_direction(direction: float) -> void:
	if is_finite(direction) and direction != 0.0:
		_facing = signf(direction)


func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play():
		return
	_invulnerability = maxf(0.0, _invulnerability - delta)
	modulate.a = 0.45 if _invulnerability > 0.0 and int(_invulnerability * 15.0) % 2 else 1.0
	_dash_remaining = maxf(0.0, _dash_remaining - delta)
	_dash_recovery = maxf(0.0, _dash_recovery - delta)
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
		_coyote = 0.10
	elif _jumps_used == 0:
		_jumps_used = 1
		_coyote = maxf(0.0, _coyote-delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var jump_limit := 2 if WorldProgress.has_ability(&"double_jump") else 1
	_jump_buffer = 0.12 if Input.is_action_just_pressed(&"eden_jump") else maxf(0.0,_jump_buffer-delta)
	var buffered_jump := campaign_character and _jump_buffer>0.0
	var can_coyote := campaign_character and _coyote>0.0 and _jumps_used==1
	if (buffered_jump or Input.is_action_just_pressed(&"eden_jump")) and (_jumps_used < jump_limit or can_coyote):
		if can_coyote:
			_jumps_used=0
		_jumps_used += 1
		_coyote=0.0
		_jump_buffer=0.0
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
	if _art != null:
		_walk_clock += delta * absf(velocity.x) * 0.075
		_art.flip_h = _facing<0.0
		_art.position.y = -15.0 + (sin(_walk_clock)*2.0 if is_on_floor() and absf(velocity.x)>5.0 else 0.0)
		_art.rotation = clampf(velocity.x/9000.0,-0.08,0.08) if is_on_floor() else _facing*0.08
	queue_redraw()
	if global_position.y > death_height:
		GameSession.player_died(&"fall")


func _unhandled_input(event: InputEvent) -> void:
	if not WorldProgress.can_play():
		return
	if event.is_action_pressed(&"eden_slash"):
		combat.try_close(_facing)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"eden_reach_slash"):
		combat.try_reach(_facing)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if WorldProgress.shield_active:
		draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 32, Color(0.45, 0.8, 0.95), 3.0)


func hurt(amount: int) -> void:
	if _invulnerability > 0.0 or not WorldProgress.can_play() or WorldProgress.shield_active or _dash_remaining>0.0:
		return
	_invulnerability = 0.85
	SoundManager.play_sfx(&"hurt")
	stats.take_damage(amount)
