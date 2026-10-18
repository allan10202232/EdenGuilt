class_name CombatFeedback
extends Node2D
## Local impact pause leaves menus, dialogue and extraction on their own clocks.

var actor: CharacterBody2D
var camera: Camera2D
var impact_count := 0
var last_duration := 0.0
var _shake_left := 0.0
var _shake_strength := 0.0
var _clock := 0.0
var _energy := 0.0

func bind(player: CharacterBody2D) -> void:
	actor = player
	camera = player.get_node("Camera2D")
	player.combat.target_hit.connect(_on_hit)
	player.combat.attack_started.connect(func(_move: MeleeAttackProfile) -> void: _energy = 0.65)

func _on_hit(_receiver: Node, hit: Dictionary) -> void:
	var heavy: bool = hit.get("attack_id", &"") == &"reach_melee"
	var lethal: bool = hit.get("lethal", false)
	last_duration = 0.055 if lethal else 0.045 if heavy else 0.035
	actor.impact_pause = maxf(actor.impact_pause,last_duration)
	actor.combat.pause_impact(last_duration)
	_shake_left = 0.13 if heavy else 0.09
	_shake_strength = 3.0 if heavy else 1.8
	_energy = 1.0
	impact_count += 1

func _process(delta: float) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(camera): return
	if not WorldProgress.can_play():
		camera.offset = Vector2.ZERO
		_shake_left = 0.0
		_energy = 0.0
		actor.impact_pause = 0.0
		if is_instance_valid(actor.grounding):
			actor.grounding.light_energy = 0.85 if actor.extracting else 0.0
			actor.grounding.light_tint = Color(0.32,0.86,0.55)
		return
	_clock += delta
	_shake_left = maxf(0.0,_shake_left-delta)
	_energy = maxf(0.0,_energy-delta*5.0)
	var decay := minf(1.0,_shake_left/0.09)
	camera.offset = (Vector2(sin(_clock*137.0),cos(_clock*173.0))*_shake_strength*decay).round()
	if is_instance_valid(actor.grounding):
		actor.grounding.light_energy = maxf(_energy,0.65 if actor.extracting or WorldProgress.shield_active else 0.0)
		actor.grounding.light_tint = Color(0.32,0.86,0.55) if WorldProgress.core_reversed else Color(0.94,0.39,0.19)

func _exit_tree() -> void:
	if is_instance_valid(camera): camera.offset = Vector2.ZERO
