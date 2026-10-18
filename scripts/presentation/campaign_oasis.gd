class_name CampaignOasis
extends Node2D
## Each ability owns its own living patch, even when two sources share a region.

const WIDTH := 300.0

var ability: StringName
var vitality := 1.0
var artwork: Sprite2D
var _clock := 0.0
var _life_material: ShaderMaterial
var _art_scale := Vector2.ONE
var flow_width: float = 216.0
var energy_color: Color = Color(0.65,1.0,0.5)

func extraction_notice() -> String:
	return GameText.t("正在抽取土地生命力……草木和泉水的生机正在汇入吸魂器。")

func completion_notice() -> String:
	return GameText.t("获得%s。眼前的绿洲已经枯竭；这份力量来自土地的生命。")%AbilityCatalog.definition(ability).name


func setup(id: StringName, biome: String, ground: Vector2) -> void:
	ability = id
	position = ground
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	artwork = Sprite2D.new()
	artwork.texture = CampaignLevels.trimmed_texture("oases/" + biome + "_oasis")
	var dimensions := artwork.texture.get_size()
	_art_scale = Vector2.ONE * WIDTH / dimensions.x
	artwork.scale = _art_scale
	artwork.position = Vector2(0, 10.0 - dimensions.y * _art_scale.y * 0.5)
	_life_material = ShaderMaterial.new()
	_life_material.shader = preload("res://assets/shaders/oasis_life.gdshader")
	artwork.material = _life_material
	add_child(artwork)
	refresh_state()


func refresh_state() -> void:
	set_depletion(1.0 if WorldProgress.ability_state(ability) == WorldProgress.AbilityState.BORROWED else 0.0)


func set_depletion(progress: float) -> void:
	vitality = 1.0 - clampf(progress, 0.0, 1.0)
	_life_material.set_shader_parameter("depletion", 1.0 - vitality)
	# Wilt toward the ground, preserving the contact line rather than floating.
	var height_scale := lerpf(0.82, 1.0, vitality)
	artwork.scale = Vector2(_art_scale.x, _art_scale.y * height_scale)
	artwork.position.y = 10.0 - artwork.texture.get_height() * artwork.scale.y * 0.5
	queue_redraw()


func _process(delta: float) -> void:
	if not WorldProgress.can_play() and not WorldProgress.extraction_active:
		return
	_clock += delta
	queue_redraw()


func _draw() -> void:
	if vitality > 0.0:
		for index in 9:
			var point := Vector2(-115 + index * 28, -26.0 - sin(_clock * 1.4 + index * 2.7) * 12.0)
			var glow := (0.4 + 0.25 * sin(_clock * 2.0 + index)) * vitality
			draw_rect(Rect2(point.snapped(Vector2(2, 2)), Vector2(2, 2)), Color(0.66, 1.0, 0.57, glow))
	if vitality < 0.5:
		for index in 5:
			var start := Vector2(-90 + index * 43, 0)
			draw_polyline(PackedVector2Array([start, start + Vector2(6, 4), start + Vector2(2, 8), start + Vector2(12, 12)]), Color(0.09, 0.08, 0.07, 1.0 - vitality), 2.0)
