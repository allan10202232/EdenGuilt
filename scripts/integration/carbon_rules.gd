class_name CarbonRules
extends Resource
## Fictional gameplay tuning. These values are not measured lifecycle emissions.

@export var double_jump_kg: float = 5.0
@export var mineralization_kg: float = 1.0
@export var shield_kg: float = 20.0
@export var black_pierce_kg: float = 200.0
@export var attack_kg: float = 0.25
@export var rapid_attack_extra_kg: float = 1.75
@export var cadence_seconds: float = 0.75
@export var cadence_tolerance: float = 0.20
@export var rapid_interval: float = 0.50
@export var cooling_per_second: float = 14.0
@export var haze_threshold_kg: float = 80.0
@export var frenzy_threshold_kg: float = 220.0
@export var severe_threshold_kg: float = 400.0
@export var mineral_node_storage_kg: float = 15.0
@export var community_storage_kg: float = 45.0
@export var recycled_material_per_node_kg: float = 10.0
@export var teaching_ore_ratio: float = 4.0


func action_kg(id: StringName) -> float:
	match id:
		&"double_jump": return maxf(0.0, double_jump_kg)
		&"mineralization": return maxf(0.0, mineralization_kg)
		&"shield": return maxf(0.0, shield_kg)
		&"black_pierce": return maxf(0.0, black_pierce_kg)
		&"light_blade": return maxf(0.0, attack_kg)
	return 0.0
