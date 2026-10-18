class_name MeleeAttackProfile
extends Resource
## Duplicate a .tres to create another melee move. Numbers are prototype tuning.

@export var id: StringName = &"close_melee"
@export var display_name: String = GameText.t("近身挥砍")
@export_range(1.0, 1000.0, 1.0) var reach: float = 80.0
@export_range(1.0, 500.0, 1.0) var height: float = 72.0
@export_range(0.0, 200.0, 1.0) var forward_offset: float = 14.0
@export var vertical_offset: float = -4.0
@export_range(1, 1000, 1) var damage: int = 1
@export var knockback := Vector2(180, -80)
@export_range(0.0, 3.0, 0.01) var windup: float = 0.06
@export_range(0.01, 3.0, 0.01) var active_time: float = 0.10
@export_range(0.0, 3.0, 0.01) var recovery: float = 0.16
@export_range(0.0, 5.0, 0.01) var cooldown: float = 0.12
@export var color := Color(0.95, 0.82, 0.48)


func is_usable() -> bool:
	for value: float in [reach, height, forward_offset, vertical_offset, windup, active_time, recovery, cooldown, knockback.x, knockback.y]:
		if not is_finite(value):
			return false
	return reach > 0.0 and height > 0.0 and damage > 0 and forward_offset >= 0.0 and windup >= 0.0 and active_time > 0.0 and recovery >= 0.0 and cooldown >= 0.0
