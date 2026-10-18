class_name SceneEcology
extends CanvasLayer
## A viewport filter below climate/UI: every world drawing shares the same fade.

var amount := 0.0
var _level: CampaignLevel
var _filter: ColorRect
var _material: ShaderMaterial

func bind(level_node: CampaignLevel) -> void:
	_level = level_node
	layer = 2
	name = "SceneEcology"

func _ready() -> void:
	_filter = ColorRect.new()
	_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://assets/ecology.gdshader")
	_filter.material = _material
	add_child(_filter)
	amount = target_amount()
	_material.set_shader_parameter("bleaching",amount)

func target_amount() -> float:
	if WorldProgress.repaired_regions.has(_level.region_id): return 0.0
	var ids: Array[StringName] = [_level.definition.ability]
	if _level.definition.has("secondary_ability"): ids.append(_level.definition.secondary_ability)
	var depleted := 0.0
	for id: StringName in ids:
		if WorldProgress.has_ability(id): depleted += 1.0
	var action := _level.extraction
	if action.active and WorldProgress.ability_state(action._ability)==WorldProgress.AbilityState.UNAVAILABLE:
		depleted += smoothstep(0.04,0.96,action.progress)
	return clampf(depleted/ids.size(),0.0,1.0)

func _process(delta: float) -> void:
	var target := target_amount()
	# Follow the extraction's exact clock, even while gameplay is frozen.
	# Community restoration and cancellation ease back instead of popping.
	amount = target if _level.extraction.active else move_toward(amount,target,delta*1.4)
	_material.set_shader_parameter("bleaching",amount)
