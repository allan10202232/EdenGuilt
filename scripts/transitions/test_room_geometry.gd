extends Node2D
@export_range(0,1) var room_id:=0
const Art=preload("res://scripts/mine_challenge/mine_art.gd")
const BACKGROUND=preload("res://assets/art/originals/scenarios/Scenario2.jpg")
var map_rects: Array[Rect2]=[]

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if room_id==0:
		for rect in [Rect2(0,600,704,38),Rect2(896,600,504,38),Rect2(480,260,224,32),Rect2(896,260,400,32)]: _deck(rect)
		var lift: OpenElevator=preload("res://scenes/movement/open_elevator.tscn").instantiate()
		lift.name="Elevator"
		lift.position=Vector2(800,600)
		lift.top_position=Vector2(0,-340)
		lift.handle_input=false
		add_child(lift)
		for upper in [false,true]:
			var button:=ElevatorSwitch.new()
			button.position=Vector2(950,228 if upper else 568)
			button.call_top=upper
			button.elevator=lift
			button.activation_mode=2
			add_child(button)
	else: _deck(Rect2(0,600,1400,38))
	var other: String="res://scenes/tests/transition_room_b.tscn" if room_id==0 else "res://scenes/tests/transition_room_a.tscn"
	for right in [false,true]:
		var zone:=TransitionZone.new()
		zone.name="EastExit" if right else "WestExit"
		zone.position=Vector2(1390 if right else 10,540)
		zone.target_scene=other
		zone.target_spawn_id=&"west" if right else &"east"
		zone.entry_direction=Vector2.RIGHT if right else Vector2.LEFT
		zone.source_spawn_id=&"east" if right else &"west"
		zone.return_to_previous=room_id==1 and not right
		add_child(zone)
	var door:=DoorTransition.new()
	door.name="Door"
	door.position=Vector2(400,570)
	door.target_scene=other
	door.target_spawn_id=&"door"
	door.entry_direction=Vector2.ZERO
	door.source_spawn_id=&"door"
	door.return_to_previous=room_id==1
	add_child(door)
	for entry in [{"id":&"west","p":Vector2(90,578),"face":1},{"id":&"east","p":Vector2(1310,578),"face":-1},{"id":&"door","p":Vector2(520,578),"face":1}]:
		var marker:=RoomSpawnPoint.install(self,entry.id,entry.p,entry.face)
		marker.override_camera_bounds=true
		marker.camera_bounds=Rect2(0,0,1400,900)
	queue_redraw()

func _deck(rect: Rect2) -> void:
	map_rects.append(rect)
	var body:=StaticBody2D.new()
	body.collision_layer=1
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=rect.size
	shape.shape=box
	shape.position=rect.get_center()
	body.add_child(shape)
	add_child(body)

func _draw() -> void:
	draw_texture_rect(BACKGROUND,Rect2(0,0,1400,900),false,Color(.7,.74,.7))
	for rect in map_rects:
		for x in range(int(rect.position.x),int(rect.end.x),180):
			Art.draw_at(self,0,Rect2(x,rect.position.y,minf(180,rect.end.x-x),56))
