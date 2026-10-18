class_name EdenChapterEcology
extends SceneEcology
## Keep the existing two-stage extraction cost without coupling chapter scripts.
var eden: Node2D
const FILTER_STRENGTH:=0.45

func _ready() -> void:
	super._ready()
	_material.set_shader_parameter("bleaching",amount*FILTER_STRENGTH)

func _init() -> void:
	layer=2
	name="EdenEcology"

func target_amount() -> float:
	if WorldProgress.repaired_regions.has(&"remnant_sea"): return 0
	var depleted:=0.0
	for id in [&"shield",&"black_pierce"]:
		if WorldProgress.has_ability(id): depleted+=1
	if eden.extraction.active:
		depleted+=smoothstep(0.04,0.96,eden.extraction.progress)
	return clampf(depleted/2,0,1)

func _process(delta: float) -> void:
	var target:=target_amount()
	amount=target if eden.extraction.active else move_toward(amount,target,delta*1.4)
	# Keep gas green and phase walls violet while showing the two extraction costs.
	_material.set_shader_parameter("bleaching",amount*FILTER_STRENGTH)
