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
var _art: HeroActionVisual
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _mineral_recovery: float = 0.0
var _pierce_recovery: float = 0.0
var _pierce_flash: float = 0.0
var _shield_time: float = 0.0
var _shield_recovery: float = 0.0
var extracting := false
var extraction_progress := 0.0
var impact_pause := 0.0
var _jump_held := false
var _feedback: CombatFeedback
var grounding: ActorGrounding


func _ready() -> void:
	combat.setup(self, _can_melee_attack)
	combat.attack_started.connect(func(_move: MeleeAttackProfile) -> void:
		WorldProgress.report_ability_used(&"light_blade")
		SoundManager.play_sfx(&"slash_reach" if _move.id == &"reach_melee" else &"slash_close", -8.0)
	)
	if campaign_character:
		grounding = ActorGrounding.new()
		grounding.bind(self, 24.0, 17.0, 17)
		add_child(grounding)
		_feedback = CombatFeedback.new()
		add_child(_feedback)
		_feedback.bind(self)
		collision_mask = 17
		combat.close_attack.show_hitbox = false
		combat.reach_attack.show_hitbox = false
		combat.close_attack.show_placeholder_weapon = false
		combat.reach_attack.show_placeholder_weapon = false
		combat.close_attack.obstruction_mask = 17
		combat.reach_attack.obstruction_mask = 17
		for part in ["Cape", "Body", "Visor"]:
			get_node(part).hide()
		_art = HeroActionVisual.new()
		add_child(_art)
		_art.bind(self)
		_update_character()
		WorldProgress.world_changed.connect(_update_character)


func _update_character() -> void:
	if _art == null:
		return
	_art.set_form(WorldProgress.core_reversed)


func _can_melee_attack() -> bool:
	return WorldProgress.can_play() and WorldProgress.has_ability(&"light_blade")


func face_direction(direction: float) -> void:
	if is_finite(direction) and direction != 0.0:
		_facing = signf(direction)


func begin_extraction(ground: Vector2) -> void:
	extracting = true
	extraction_progress = 0.0
	impact_pause = 0.0
	velocity = Vector2.ZERO
	combat.cancel()
	_dash_remaining = 0.0
	_pierce_flash = 0.0
	_shield_time = 0.0
	_jump_buffer = 0.0
	_invulnerability = 0.0
	modulate.a = 1.0
	WorldProgress.set_shield_active(false)
	if absf(ground.x - global_position.x) > 12.0:
		face_direction(ground.x - global_position.x)


func finish_extraction() -> void:
	extracting = false
	extraction_progress = 0.0


func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play():
		combat.clear_buffer()
		return
	_jump_buffer = 0.12 if Input.is_action_just_pressed(&"eden_jump") else maxf(0.0,_jump_buffer-delta)
	if impact_pause > 0.0:
		impact_pause = maxf(0.0, impact_pause - delta)
		return
	_invulnerability = maxf(0.0, _invulnerability - delta)
	modulate.a = 0.45 if _invulnerability > 0.0 and int(_invulnerability * 15.0) % 2 else 1.0
	_dash_remaining = maxf(0.0, _dash_remaining - delta)
	_dash_recovery = maxf(0.0, _dash_recovery - delta)
	_mineral_recovery=maxf(0.0,_mineral_recovery-delta)
	_pierce_recovery=maxf(0.0,_pierce_recovery-delta)
	_pierce_flash=maxf(0.0,_pierce_flash-delta)
	_shield_time=maxf(0.0,_shield_time-delta)
	_shield_recovery=maxf(0.0,_shield_recovery-delta)
	var axis := Input.get_axis(&"eden_move_left", &"eden_move_right")
	var was_on_floor:=is_on_floor()
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
	else:
		_coyote = maxf(0.0, _coyote-delta)
		if _jumps_used==0:
			_jumps_used=1
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var jump_limit := 2 if WorldProgress.has_ability(&"double_jump") else 1
	var holding_jump := Input.is_action_pressed(&"eden_jump")
	if campaign_character and _jump_held and not holding_jump and velocity.y < JUMP_SPEED * 0.55:
		velocity.y = JUMP_SPEED * 0.55
	_jump_held = holding_jump
	var buffered_jump := campaign_character and _jump_buffer>0.0
	var can_coyote := campaign_character and _coyote>0.0 and _jumps_used==1
	if (buffered_jump or Input.is_action_just_pressed(&"eden_jump")) and (_jumps_used < jump_limit or can_coyote):
		if can_coyote:
			_jumps_used=0
		_jumps_used += 1
		_coyote=0.0
		_jump_buffer=0.0
		velocity.y = JUMP_SPEED if not campaign_character or holding_jump else JUMP_SPEED * 0.55
		if _jumps_used == 2:
			WorldProgress.report_ability_used(&"double_jump")
			if _art!=null: _art.play_action(&"double_jump",0.22)
		else:
			SoundManager.play_sfx(&"jump", -10.0)
			if _art!=null: _art.play_action(&"jump",0.10)
	var was_shielded := WorldProgress.shield_active
	if campaign_character:
		# Releasing ends this cast. A new press must pass the cooldown and be billed.
		if not Input.is_action_pressed(&"eden_shield"):
			_shield_time=0.0
		if Input.is_action_just_pressed(&"eden_shield") and _shield_recovery<=0.0 and WorldProgress.has_ability(&"shield"):
			_shield_time=1.4
			_shield_recovery=2.2
			combat.cancel()
			if _art!=null: _art.play_action(&"shield_raise",0.10)
			WorldProgress.report_ability_used(&"shield")
		WorldProgress.set_shield_active(Input.is_action_pressed(&"eden_shield") and _shield_time>0.0)
	else:
		WorldProgress.set_shield_active(Input.is_action_pressed(&"eden_shield"))
	if WorldProgress.shield_active and not was_shielded:
		if not campaign_character:
			WorldProgress.report_ability_used(&"shield")
	if campaign_character and Input.is_action_just_pressed(&"eden_mineralize"):
		try_mineralize()
	if campaign_character and Input.is_action_just_pressed(&"eden_black_pierce"):
		try_black_pierce()
	move_and_slide()
	if _art!=null and is_on_floor() and not was_on_floor:
		_art.play_action(&"land",0.10)
		SoundManager.play_sfx(&"land", -15.0)
	queue_redraw()
	if global_position.y > death_height:
		GameSession.player_died(&"fall")


func _unhandled_input(event: InputEvent) -> void:
	if not WorldProgress.can_play():
		return
	if event.is_action_pressed(&"eden_slash"):
		combat.request_attack(false, _facing)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"eden_reach_slash"):
		combat.request_attack(true, _facing)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if _pierce_flash>0.0:
		draw_line(Vector2(-_facing*160,0),Vector2.ZERO,Color(0.53,0.2,0.85,_pierce_flash*2.0),14)
	if WorldProgress.shield_active:
		draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 32, Color(0.45, 0.8, 0.95), 3.0)


func hurt() -> void:
	if _invulnerability > 0.0 or not WorldProgress.can_play() or WorldProgress.shield_active or _dash_remaining>0.0 or _pierce_flash>0.0:
		return
	_invulnerability = 0.85
	combat.cancel()
	if _art!=null: _art.play_action(&"hurt",0.22)
	SoundManager.play_sfx(&"hurt")
	stats.take_hit()


func try_mineralize() -> bool:
	if not campaign_character or _mineral_recovery>0.0 or not WorldProgress.can_play() or not WorldProgress.has_ability(&"mineralization"):
		return false
	var level:=get_parent() as CampaignLevel
	if level==null or not level.try_mineralize(global_position,_facing):
		return false
	_mineral_recovery=0.8
	combat.cancel()
	if _art!=null: _art.play_action(&"mineralization",0.35)
	return true


func try_black_pierce() -> bool:
	if not campaign_character or _pierce_recovery>0.0 or not WorldProgress.can_play() or not WorldProgress.has_ability(&"black_pierce"):
		return false
	var previous_mask:=collision_mask
	collision_mask=1
	var motion:=Vector2(_facing*240.0,0)
	var collision:=KinematicCollision2D.new()
	if test_move(global_transform,motion,collision):
		motion=collision.get_travel()
	# Never finish inside a special wall, even when a wall is wider than the cast.
	var shape: Shape2D=$Collision.shape
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape
	query.collision_mask=16
	query.exclude=[get_rid()]
	var destination:=global_position+motion
	for index in 49:
		query.transform=Transform2D(0.0,destination)
		if get_world_2d().direct_space_state.intersect_shape(query).is_empty():
			break
		destination=global_position+motion*(1.0-float(index+1)/48.0)
	collision_mask=previous_mask
	if absf(destination.x-global_position.x)<12.0:
		WorldProgress.set_notice(GameText.t("普通地形会挡住黑穿；无有效位移不记排放。"))
		return false
	global_position=destination
	combat.cancel()
	if _art!=null: _art.play_action(&"black_pierce",0.20)
	_pierce_recovery=1.3
	_pierce_flash=0.20
	WorldProgress.report_ability_used(&"black_pierce")
	return true
