class_name ScrapPlatform
extends AnimatableBody2D
## Top-centred origin; reusable one-way collision shared by the five prefabs.

@export var width := 112.0
@export var tint := Color("a89c70")
@export var surface_style: StringName = &"scrap"
var retired := false
var shape_node: CollisionShape2D
var actor: CharacterBody2D
var clock := 0.0
var _surface_seed := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_surface_seed = global_position.x
	collision_layer = 1
	collision_mask = 0
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 18)
	shape_node.shape = shape
	shape_node.position.y = 9
	shape_node.one_way_collision = true
	shape_node.one_way_collision_margin = 5.0
	add_child(shape_node)
	actor = get_parent().get_node_or_null("Player") as CharacterBody2D
	if actor == null: actor = get_tree().get_first_node_in_group("player") as CharacterBody2D
	add_to_group("parkour_platform")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if WorldProgress.can_play():
		clock += delta
	queue_redraw()

func occupied() -> bool:
	return not retired and is_instance_valid(actor) and actor.is_on_floor() and absf(actor.global_position.x - global_position.x) < width * 0.5 + 12 and absf(actor.global_position.y + 24 - global_position.y) < 8

func surface_velocity() -> float:
	return 0.0

func reset_platform() -> void:
	if shape_node != null:
		shape_node.set_deferred("disabled", retired)

func retire() -> void:
	retired = true
	reset_platform()
	visible = false

func paint_deck(offset: Vector2, color: Color) -> void:
	ScrapyardSurface.deck(self,Rect2(offset+Vector2(-width/2,0),Vector2(width,18)),_surface_seed,color==Color("ff913f"),surface_style)

func _draw() -> void:
	paint_deck(Vector2.ZERO, tint)
