class_name LifeOrbs
extends Range
## Five leaves; each half leaf retains the existing ten-HP contract.

const ORB_COUNT: int = PlaceholderStats.LIFE_ORB_COUNT
const HALVES: int = PlaceholderStats.LIFE_HALVES
const PIXEL := 2.0
const ORB_SIZE := 32.0
const ORB_GAP := 10.0
const FLASH_DURATION := 0.28

var _previous_halves := HALVES
var _flash := 0.0
var _flashing_orb := -1
var _updating := false


func _init() -> void:
	custom_minimum_size = Vector2(ORB_COUNT * ORB_SIZE + (ORB_COUNT - 1) * ORB_GAP, 36)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_process(false)


func _ready() -> void:
	_previous_halves = get_half_count()
	value_changed.connect(func(_value: float) -> void:
		if not _updating:
			_health_changed()
	)
	changed.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()


func set_health(current: int, maximum: int) -> void:
	# A new stat source can change both bounds and health in the same update.
	_updating = true
	max_value = maxi(1, maximum)
	value = clampi(current, 0, maxi(1, maximum))
	_updating = false
	_health_changed()


func get_half_count() -> int:
	return clampi(ceili(value / maxf(1.0, max_value) * HALVES), 0, HALVES)


func get_orb_halves(index: int) -> int:
	return clampi(get_half_count() - index * 2, 0, 2)


func _health_changed() -> void:
	var halves := get_half_count()
	if halves < _previous_halves:
		_flashing_orb = clampi(floori(float(halves) / 2.0), 0, ORB_COUNT - 1)
		_flash = FLASH_DURATION
		set_process(true)
	elif halves > _previous_halves:
		_flash = 0.0
		_flashing_orb = -1
		set_process(false)
	_previous_halves = halves
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	if _flash <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var top := floorf((size.y - ORB_SIZE) * 0.5)
	for index in ORB_COUNT:
		var origin := Vector2(index * (ORB_SIZE + ORB_GAP), top)
		_draw_orb(origin, get_orb_halves(index), index == _flashing_orb and _flash > 0.0)


func _draw_orb(origin: Vector2, halves: int, flashing: bool) -> void:
	var silhouette:=PackedVector2Array([Vector2(2,12),Vector2(2,8),Vector2(4,8),Vector2(4,5),Vector2(7,5),Vector2(7,3),Vector2(11,3),Vector2(11,2),Vector2(15,1),Vector2(14,6),Vector2(14,10),Vector2(12,10),Vector2(12,12),Vector2(9,12),Vector2(9,14),Vector2(5,14)])
	for y in 16:
		for x in 16:
			var pixel:=Vector2(x+.5,y+.5)
			if not Geometry2D.is_point_in_polygon(pixel,silhouette): continue
			var edge:=false
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				if not Geometry2D.is_point_in_polygon(pixel+direction,silhouette): edge=true
			var filled:=halves==2 or (halves==1 and x+y>=16)
			var tint:=Color("10271a")
			if not edge:
				tint=(Color("a4e797") if x+y<16 else Color("4daf62")) if filled else Color("263a29")
				if absi(x+y-16)<=1: tint=Color("d0e4a2") if filled else Color("52634a")
				elif posmod(x-y,6)==0: tint=tint.darkened(.16)
			elif filled: tint=Color("426547")
			if flashing: tint=tint.lerp(Color("fff4cb"),_flash/FLASH_DURATION*.8)
			draw_rect(Rect2(origin + Vector2(x, y) * PIXEL, Vector2.ONE * PIXEL), tint)
	draw_line(origin+Vector2(3,13)*PIXEL,origin+Vector2(1,15)*PIXEL,Color("b1b778") if halves>0 else Color("46513b"),2)
