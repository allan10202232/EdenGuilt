extends Node
## Immutable gross history plus separately identified storage and circular-economy actions.

signal changed
signal action_recorded(event: Dictionary)
signal climate_changed(stage: int)

const EPA_SOURCE: String = "https://www.epa.gov/energy/greenhouse-gas-equivalencies-calculator-calculations-and-references"
const DOE_SOURCE: String = "https://www.energy.gov/hgeo/carbon-mineralization-pathway"
const KG_CO2_PER_US_GALLON: float = 8.887
const LITRES_PER_US_GALLON: float = 3.785411784
const MAX_DETAIL_EVENTS: int = 5000

var rules: CarbonRules = preload("res://assets/carbon_rules.tres")
var enabled: bool = false
var gross_kg: float = 0.0
var stored_kg: float = 0.0
var heat: float = 0.0
var efficiency: float = 0.80
var useful_energy: float = 0.0
var input_energy: float = 0.0
var precise_casts: int = 0
var rapid_casts: int = 0
var action_count: int = 0
var rescued_people: int = 0
var recycled_nodes: int = 0
var restored_regions: int = 0
var clock_seconds: float = 0.0
var _last_action_time: float = -100.0
var _stages: Dictionary = {}
var _skills: Dictionary = {}
var _storage_ids: Dictionary = {}
var _recycle_ids: Dictionary = {}
var _restoration_ids: Dictionary = {}
var _events: Array[Dictionary] = []
var _last_climate: int = 0
var _tick: float = 0.0


func _ready() -> void:
	WorldProgress.ability_used.connect(record_action)


func begin_run(active: bool) -> void:
	enabled = active
	gross_kg = 0.0
	stored_kg = 0.0
	heat = 0.0
	efficiency = 0.80
	useful_energy = 0.0
	input_energy = 0.0
	precise_casts = 0
	rapid_casts = 0
	action_count = 0
	rescued_people = 0
	recycled_nodes = 0
	restored_regions = 0
	clock_seconds = 0.0
	_last_action_time = -100.0
	_stages.clear()
	_skills.clear()
	_storage_ids.clear()
	_recycle_ids.clear()
	_restoration_ids.clear()
	_events.clear()
	_last_climate = 0
	for region in AbilityCatalog.REGIONS:
		_stages[region] = {"name": AbilityCatalog.region_name(region), "gross_kg": 0.0, "stored_kg": 0.0, "casts": 0}
	changed.emit()
	climate_changed.emit(0)


func _process(delta: float) -> void:
	if not enabled or not WorldProgress.can_play():
		return
	clock_seconds += delta
	heat = maxf(0.0, heat - maxf(0.0, rules.cooling_per_second)*delta)
	_tick += delta
	if _tick >= 0.10:
		_tick = 0.0
		changed.emit()


func record_action(id: StringName) -> void:
	if not enabled or not WorldProgress.can_play() or not WorldProgress.has_ability(id):
		return
	if id not in [&"double_jump", &"mineralization", &"shield", &"black_pierce", &"light_blade"]:
		return
	var interval := clock_seconds-_last_action_time
	var rapid := interval < rules.rapid_interval
	var precise := absf(interval-rules.cadence_seconds) <= rules.cadence_tolerance and heat < 80.0
	if rapid:
		heat = minf(100.0, heat+27.0)
		efficiency = maxf(0.30, 0.75-heat*0.006)
		rapid_casts += 1
	elif precise:
		heat = maxf(0.0, heat-20.0)
		efficiency = 0.95
		precise_casts += 1
	else:
		efficiency = 0.30 if heat>=80.0 else 0.80
		heat = minf(100.0, heat+4.0)
	_last_action_time = clock_seconds
	var kg := rules.action_kg(id)
	if id==&"light_blade" and rapid:
		kg += maxf(0.0, rules.rapid_attack_extra_kg)
	var work: float = {&"double_jump": 10.0, &"mineralization": 14.0, &"shield": 30.0, &"black_pierce": 80.0, &"light_blade": 8.0}[id]
	var supplied := work/efficiency
	gross_kg += kg
	useful_energy += work
	input_energy += supplied
	action_count += 1
	var region := WorldProgress.current_scene
	_stages[region].gross_kg += kg
	_stages[region].casts += 1
	if not _skills.has(id):
		_skills[id] = {"name": AbilityCatalog.definition(id).name, "gross_kg": 0.0, "casts": 0}
	_skills[id].gross_kg += kg
	_skills[id].casts += 1
	var event := {"time_s": clock_seconds, "region": region, "skill": id, "kg": kg, "efficiency": efficiency, "heat": heat, "rapid": rapid, "precise": precise}
	if _events.size()<MAX_DETAIL_EVENTS:
		_events.append(event)
	action_recorded.emit(event.duplicate())
	_publish()


func store_carbon(id: StringName, kg: float) -> bool:
	if not enabled or not WorldProgress.can_play() or id==&"" or _storage_ids.has(id) or not is_finite(kg) or kg<=0.0:
		return false
	_storage_ids[id] = kg
	stored_kg += kg
	_stages[WorldProgress.current_scene].stored_kg += kg
	_publish()
	return true


func recycle(id: StringName) -> bool:
	if not enabled or not WorldProgress.can_play() or id==&"" or _recycle_ids.has(id):
		return false
	_recycle_ids[id] = true
	recycled_nodes += 1
	changed.emit()
	return true


func restore_region(id: StringName) -> bool:
	if not enabled or not WorldProgress.can_play() or id!=WorldProgress.current_scene or _restoration_ids.has(id):
		return false
	_restoration_ids[id] = true
	restored_regions += 1
	store_carbon(StringName("community/"+String(id)), maxf(0.0, rules.community_storage_kg))
	changed.emit()
	return true


func pollution_load_kg() -> float:
	return maxf(0.0, gross_kg-stored_kg)


func climate_stage() -> int:
	if not enabled:
		return 0
	var load_kg := pollution_load_kg()
	if load_kg >= rules.severe_threshold_kg: return 3
	if load_kg >= rules.frenzy_threshold_kg: return 2
	if load_kg >= rules.haze_threshold_kg: return 1
	return 0


func average_efficiency() -> float:
	return useful_energy/input_energy if input_energy>0.0 else 0.0


func seconds_to_beat() -> float:
	return maxf(0.0, rules.cadence_seconds-(clock_seconds-_last_action_time))


func snapshot() -> Dictionary:
	var material := recycled_nodes*maxf(0.0, rules.recycled_material_per_node_kg)
	return {
		"schema_version": 1, "model": "fictional-gameplay-v1", "gross_kg": gross_kg,
		"stored_kg": stored_kg, "pollution_load_kg": pollution_load_kg(),
		"efficiency": average_efficiency(), "useful_energy": useful_energy, "input_energy": input_energy,
		"waste_energy": maxf(0.0, input_energy-useful_energy), "precise_casts": precise_casts,
		"rapid_casts": rapid_casts, "action_count": action_count, "people": rescued_people,
		"recycled_nodes": recycled_nodes, "recycled_material_kg": material, "restored_regions": restored_regions,
		"teaching_ore_avoided_kg": material*maxf(0.0, rules.teaching_ore_ratio),
		"gasoline_litres_analogy": gross_kg/KG_CO2_PER_US_GALLON*LITRES_PER_US_GALLON,
		"stages": _stages.duplicate(true), "skills": _skills.duplicate(true), "events": _events.duplicate(true),
		"omitted_detail_events": maxi(0, action_count-MAX_DETAIL_EVENTS),
		"factors": {"double_jump_kg": rules.double_jump_kg, "mineralization_kg": rules.mineralization_kg,
			"shield_kg": rules.shield_kg, "black_pierce_kg": rules.black_pierce_kg,
			"attack_kg": rules.attack_kg, "rapid_attack_extra_kg": rules.rapid_attack_extra_kg,
			"mineral_node_storage_kg": rules.mineral_node_storage_kg, "community_storage_kg": rules.community_storage_kg,
			"recycled_material_per_node_kg": rules.recycled_material_per_node_kg, "teaching_ore_ratio": rules.teaching_ore_ratio,
			"gasoline_kg_co2_per_us_gallon": KG_CO2_PER_US_GALLON, "litres_per_us_gallon": LITRES_PER_US_GALLON},
		"sources": [EPA_SOURCE, DOE_SOURCE],
		"methodology": GameText.t("排放与固碳均为游戏教学模型。汽油类比使用 EPA 8.887 kg CO2/美制加仑，仅作量级比较。累计排放不会被抵销或清零。"),
	}


func _publish() -> void:
	var next := climate_stage()
	if next!=_last_climate:
		_last_climate = next
		climate_changed.emit(next)
	changed.emit()
