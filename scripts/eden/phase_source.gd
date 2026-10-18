class_name EdenPhaseSource
extends "res://scripts/mine_challenge/life_seam.gd"
## Moss in the root-bound maintenance masonry, using the shared extraction.
func extraction_notice() -> String:
	return EdenBlueprint.text("Drawing life from the roots beneath the maintenance floor…","正在抽取维护层根系中的生命力……")

func completion_notice() -> String:
	return EdenBlueprint.text("DARK DASH acquired. The roots go quiet. Shift / L / F phases through violet walls.","获得黑冲。根系不再发光。Shift / L / F 穿过紫色相位墙。")

func _refresh_label() -> void:
	if _source_label==null: return
	_source_label.text=EdenBlueprint.text("ROOT SEAM · DARK DASH","根系矿脉 · 黑冲") if WorldProgress.ability_state(ability)==WorldProgress.AbilityState.UNAVAILABLE else EdenBlueprint.text("DEPLETED ROOTS","枯竭根系") if WorldProgress.has_ability(ability) else EdenBlueprint.text("ROOTS RESTORED","根系已修复")
