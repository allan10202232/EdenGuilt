class_name LifeOrbs
extends Range
## Five pixel-art vessels; health is consumed from the right, half a vessel per hit.

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
	for y in 16:
		for x in 16:
			var distance := Vector2(x - 7.5, y - 7.5).length_squared()
			if distance > 60.0:
				continue
			var tint := Color("0b1b15")
			if distance < 47.0:
				tint = Color("4a825b") if x + y < 16 else Color("254c38")
			if distance < 34.0:
				var filled := halves == 2 or (halves == 1 and y >= 8)
				if filled:
					tint = Color("83e88a") if y < 6 else Color("42bc68") if y < 11 else Color("267f4b")
					if x > 10:
						tint = tint.darkened(0.18)
					if halves == 1 and y == 8:
						tint = Color("a4f3a3")
				else:
					tint = Color("152b24") if y < 8 else Color("102219")
			# Glass glints keep an empty orb visible without implying remaining life.
			if (y == 3 and x in [5, 6, 7]) or (x == 4 and y in [4, 5]):
				tint = Color("dcffcf") if halves == 2 else Color("567c66")
			if flashing and distance >= 34.0 and distance < 47.0:
				tint = tint.lerp(Color("edffd8"), _flash / FLASH_DURATION)
			draw_rect(Rect2(origin + Vector2(x, y) * PIXEL, Vector2.ONE * PIXEL), tint)
