class_name RoomSpawnPoint
extends Marker2D
## ID is local to a room. Positions refer to the player's body centre.
@export var spawn_id: StringName=&"entrance"
@export_range(-1,1,2) var facing:=1
@export var override_camera_bounds:=false
@export var camera_bounds:=Rect2(0,0,1280,720)

static func find_in(room: Node,id: StringName) -> RoomSpawnPoint:
	for child in room.get_children():
		if child is RoomSpawnPoint and child.spawn_id==id: return child
		var found:=find_in(child,id)
		if found!=null: return found
	return null

static func nearest(room: Node,point: Vector2) -> RoomSpawnPoint:
	var closest: RoomSpawnPoint
	var distance:=INF
	for child in room.get_children():
		var candidate: RoomSpawnPoint=child if child is RoomSpawnPoint else nearest(child,point)
		if candidate!=null and candidate.global_position.distance_squared_to(point)<distance:
			closest=candidate
			distance=candidate.global_position.distance_squared_to(point)
	return closest

func place(actor: CharacterBody2D) -> void:
	actor.global_position=global_position
	actor.velocity=Vector2.ZERO
	if facing!=0:
		if actor.has_method("face_direction"): actor.face_direction(float(facing))
		else: actor.set("facing",float(facing))
	var camera:=actor.get_node_or_null("Camera2D") as Camera2D
	if camera!=null and override_camera_bounds:
		camera.limit_left=int(camera_bounds.position.x)
		camera.limit_top=int(camera_bounds.position.y)
		camera.limit_right=int(camera_bounds.end.x)
		camera.limit_bottom=int(camera_bounds.end.y)

static func install(room: Node,id: StringName,point: Vector2,direction: int=1) -> RoomSpawnPoint:
	var marker:=RoomSpawnPoint.new()
	marker.name="Spawn_"+String(id)
	marker.spawn_id=id
	marker.position=point
	marker.facing=direction
	room.add_child(marker)
	return marker
