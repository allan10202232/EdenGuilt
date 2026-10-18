extends Node2D
## F6 playground: the production actor and its Camera2D survive every room swap.
const ROOM_A="res://scenes/tests/transition_room_a.tscn"
const ROOM_B="res://scenes/tests/transition_room_b.tscn"
var player: EdenChapterPlayer
var transitions: RoomTransitionController
var room: Node2D
var room_path:=ROOM_A
var map_rects: Array[Rect2]=[]
var map_bounds:=Rect2(0,0,1400,900)
var checkpoint_position:=Vector2(160,578)
var hitstop:=0.0
var parry_flashes:=0
var elevator: OpenElevator
var _settings: SettingsPanel

func _ready() -> void:
	add_to_group(&"scene_transition_host")
	GameSession.start_run()
	WorldProgress.current_scene=&"lone_tree"
	WorldProgress.borrow_ability(&"double_jump")
	WorldProgress.current_scene=&"grassland"
	WorldProgress.borrow_ability(&"mineralization")
	WorldProgress.current_scene=&"remnant_sea"
	WorldProgress.borrow_ability(&"shield")
	WorldProgress.borrow_ability(&"black_pierce")
	EdenInputBindings.configure()
	transitions=RoomTransitionController.new()
	add_child(transitions)
	player=EdenChapterPlayer.new()
	player.name="Player"
	player.level=self
	player.position=checkpoint_position
	add_child(player)
	player.death_height=880
	_load_room(ROOM_A)
	var layer:=CanvasLayer.new()
	layer.layer=10
	add_child(layer)
	var ui:=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.theme=preload("res://assets/ui_theme.tres")
	layer.add_child(ui)
	ui.add_child(ChapterStatusHUD.new())
	_settings=SettingsPanel.new()
	ui.add_child(_settings)

func _load_room(path: String) -> Node:
	if is_instance_valid(room):
		remove_child(room)
		room.queue_free()
	room_path=path
	var packed: PackedScene=load(path)
	room=packed.instantiate()
	add_child(room)
	map_rects.assign(room.map_rects)
	elevator=room.get_node_or_null("Elevator") as OpenElevator
	var camera:=player.get_node("Camera2D") as Camera2D
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=1400
	camera.limit_bottom=900
	camera.position=Vector2(0,-70)
	camera.reset_smoothing()
	return room

func request_room_transition(options: Dictionary) -> bool:
	if not WorldProgress.can_play() or transitions.busy: return false
	var resolved:=transitions.resolve_options(options,room,room_path)
	var path: String=resolved.get("target_scene","")
	if path not in [ROOM_A,ROOM_B]: return false
	return transitions.request(func() -> Node: return _load_room(path),resolved)

func interact(allow_dialogue: bool=true) -> void:
	if not allow_dialogue: return
	for child in room.get_children():
		if child is DoorTransition and child._inside==player:
			child.activate()
			return
	if is_instance_valid(elevator) and elevator.is_rider(player):
		elevator.activate()
		return
	for child in room.get_children():
		if child is ElevatorSwitch and child._actor==player and child.activation_mode in [0,2]:
			child.activate()
			return

func try_extract() -> bool: return false
func mineralize_near(_origin: Vector2,_radius: float) -> int: return 0
func update_location() -> void: pass
func restore_oasis() -> void: pass
func clear_projectiles() -> void: pass
func tell(_en: String,_zh: String) -> void: pass
func _process(delta: float) -> void: hitstop=maxf(0,hitstop-delta)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and WorldProgress.can_play(): _settings.open()
