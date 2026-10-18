class_name MeleeHurtbox
extends Area2D
## Multiple hurtboxes may point to the same receiver; each swing still hits it once.

@export var receiver_path: NodePath = NodePath("..")


func get_melee_receiver() -> Node:
	return get_node_or_null(receiver_path)
