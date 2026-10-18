class_name EdenPhaseWall
extends StaticBody2D
var wall_size:=Vector2(24,190)
var energy_gate:=false
var opened:=false
var _shape: CollisionShape2D
var _clock:=0.0

func _ready() -> void:
	collision_layer=32 if energy_gate else 16
	collision_mask=0
	_shape=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=wall_size
	_shape.shape=box
	add_child(_shape)
	z_index=3

func set_open(value: bool) -> void:
	opened=value
	_shape.set_deferred(&"disabled",value)
	queue_redraw()

func _process(delta: float) -> void:
	if WorldProgress.can_play(): _clock+=delta
	queue_redraw()

func _draw() -> void:
	var color:=Color("e3bc71") if energy_gate else Color("9e75cb")
	draw_rect(Rect2(-wall_size/2,wall_size),Color(color,0.08 if opened else 0.3))
	for x in [-1,1]: draw_rect(Rect2(x*wall_size.x/2-3,-wall_size.y/2,6,wall_size.y),Color("59685e"))
	if opened: return
	for index in int(wall_size.y/13):
		var y:=-wall_size.y/2+fposmod(index*13+_clock*20,wall_size.y)
		draw_line(Vector2(-wall_size.x/2,y),Vector2(wall_size.x/2,y+5),Color(color,0.7),2)
