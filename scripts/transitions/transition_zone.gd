class_name TransitionZone
extends Area2D
## Host handles the request; zones never instantiate players or cameras.
@export_file("*.tscn") var target_scene: String=""
@export var target_region: StringName=&""
@export var target_spawn_id: StringName=&"entrance"
@export var return_to_previous:=false
@export var source_spawn_id: StringName=&""
@export_enum("edge","door") var transition_type: String="edge"
@export var fade_out_duration:=.15
@export var fade_in_duration:=.25
@export var entry_direction:=Vector2.RIGHT
@export var zone_size:=Vector2(48,180)
var _inside: CharacterBody2D

func _ready() -> void:
	collision_layer=0
	collision_mask=2
	if get_node_or_null("CollisionShape2D")==null:
		var collision:=CollisionShape2D.new()
		collision.name="CollisionShape2D"
		var box:=RectangleShape2D.new()
		box.size=zone_size
		collision.shape=box
		add_child(collision)
	body_entered.connect(_entered)
	body_exited.connect(func(body: Node2D) -> void:
		if body==_inside: _inside=null
	)

func _entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"): return
	_inside=body as CharacterBody2D
	if transition_type=="edge": activate()

func activate() -> bool:
	if not WorldProgress.can_play() or not is_instance_valid(_inside): return false
	var host:=get_tree().get_first_node_in_group(&"scene_transition_host")
	if host==null or not host.has_method("request_room_transition"): return false
	return host.request_room_transition({"target_scene":target_scene,"target_region":target_region,"target_spawn_id":target_spawn_id,"return_to_previous":return_to_previous,"source_spawn_id":source_spawn_id,"transition_type":transition_type,"fade_out_duration":fade_out_duration,"fade_in_duration":fade_in_duration,"entry_direction":entry_direction})
