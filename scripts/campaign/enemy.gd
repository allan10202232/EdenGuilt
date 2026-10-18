class_name CampaignEnemy
extends CharacterBody2D

signal defeated(enemy: CampaignEnemy)
signal projectile_fired(origin: Vector2, direction: float)

var player: CharacterBody2D
var persistent_id: StringName
var kind: String = "forest_crawler"
var patrol := Vector2(0,500)
var boss: bool = false
var health: int = 1
var max_health: int = 1
var _direction: float = -1.0
var _clock: float = 0.0
var _attack_cooldown: float = 1.7
var _windup: float = 0.0
var _stun: float = 0.0
var _skin: Sprite2D
var _hurtbox: MeleeHurtbox


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	max_health = 6 if boss else 1
	health = max_health
	var shape := RectangleShape2D.new()
	shape.size = Vector2(72,88) if boss else Vector2(34,40)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	_hurtbox = MeleeHurtbox.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = 4
	_hurtbox.collision_mask = 2
	var hurt_shape := CollisionShape2D.new()
	hurt_shape.shape = shape.duplicate()
	_hurtbox.add_child(hurt_shape)
	add_child(_hurtbox)
	_skin = Sprite2D.new()
	_skin.texture = CampaignLevels.trimmed_texture("enemies/"+kind)
	_skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _skin.texture != null:
		_skin.scale = Vector2.ONE * ((124.0 if boss else 62.0) / _skin.texture.get_height())
	_skin.position.y = -18.0 if boss else -11.0
	add_child(_skin)
	_clock = position.x * 0.013
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not WorldProgress.can_play() or health <= 0 or not is_instance_valid(player):
		return
	_clock += delta
	_attack_cooldown -= delta*(1.45 if is_enraged() else 1.0)
	_stun = maxf(0.0,_stun-delta)
	if position.x < patrol.x:
		_direction = 1.0
	elif position.x > patrol.y:
		_direction = -1.0
	var distance := player.global_position-global_position
	if _windup > 0.0:
		_windup -= delta
		velocity.x = 0.0
		if _windup <= 0.0:
			if boss:
				if absf(distance.x) < 255.0 and absf(distance.y) < 85.0:
					player.hurt()
			else:
				projectile_fired.emit(global_position+Vector2(_direction*24,-8),_direction)
	elif _stun <= 0.0:
		velocity.x = _direction * (70.0 if boss else 48.0 if kind == "crystal_miner" else 66.0)*(1.4 if is_enraged() else 1.0)
		if _attack_cooldown <= 0.0 and absf(distance.x) < (270.0 if boss else 430.0) and absf(distance.y)<100.0 and (boss or kind=="scrap_scavenger"):
			_direction = signf(distance.x) if distance.x != 0.0 else _direction
			_windup = 0.75 if boss else 0.55
			_attack_cooldown = 2.8 if boss else 3.2
	if not is_on_floor():
		velocity.y += 1450.0*delta
	elif kind == "forest_crawler" and sin(_clock*1.8)>0.99:
		velocity.y = -260.0
	move_and_slide()
	_skin.flip_h = _direction > 0.0
	_skin.modulate = Color(1.0,0.6,0.6) if _stun>0.0 else Color(1.0,0.7,0.63) if is_enraged() else Color.WHITE
	_skin.position.y = (-18.0 if boss else -11.0)+sin(_clock*7.0)*1.5
	if _hurtbox.overlaps_body(player):
		player.hurt()
	queue_redraw()


func receive_melee_hit(hit: Dictionary) -> bool:
	if health<=0 or not WorldProgress.can_play():
		return false
	health = maxi(0,health-int(hit.get("damage",1)))
	velocity += Vector2(hit.get("knockback",Vector2.ZERO))*0.55
	_stun = 0.16
	SoundManager.play_sfx(&"hurt",-10.0,1.6)
	queue_redraw()
	if health==0:
		WorldProgress.mark_enemy_defeated(persistent_id)
		if is_instance_valid(player):
			player.stats.add_score(500 if boss else 50)
		defeated.emit(self)
		queue_free()
	return true


func is_enraged() -> bool:
	return CarbonLedger.climate_stage()>=2


func _draw() -> void:
	if _skin == null or _skin.texture == null:
		draw_rect(Rect2(-17,-20,34,40),Color(0.6,0.3,0.35))
	if boss:
		draw_rect(Rect2(-80,-112,160,7),Color(0.05,0.05,0.08))
		draw_rect(Rect2(-80,-112,160.0*health/max_health,7),Color(0.83,0.3,0.32))
		draw_string(ThemeDB.fallback_font,Vector2(-55,-122),"伊甸园 · 能源守卫",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.95,0.84,0.63))
	if is_enraged():
		draw_circle(Vector2(0,-80 if boss else -54),4,Color(1,0.26,0.18))
	if _windup>0.0:
		var tint:=Color(0.95,0.54,0.17,0.18)
		draw_rect(Rect2(-250 if boss else -35,16,500 if boss else 70,8),tint)
		draw_circle(Vector2(0,-65 if boss else -50),5,Color(1,0.63,0.24))
