class_name MagnetLift
extends ScrapPlatform

@export var amplitude := 140.0
@export var period := 2.4
@export var horizontal := false
var home := Vector2.ZERO
var motion: Tween

func _init() -> void:
	width = 112
	tint = Color("67dfca")

func _ready() -> void:
	super._ready()
	home = position
	# Home is the bottom / left end of the stroke. First lift reaches Y = 240.
	var excursion := Vector2(amplitude, 0) if horizontal else Vector2(0, -amplitude)
	motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_loops()
	motion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(self, "position", home + excursion, period * 0.5)
	motion.tween_property(self, "position", home, period * 0.5)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if motion != null and motion.is_valid():
		if WorldProgress.can_play() and not retired: motion.play()
		else: motion.pause()

func reset_platform() -> void:
	# Do not snap a moving AnimatableBody (or its rider) during a checkpoint reset.
	super.reset_platform()

func _draw() -> void:
	paint_deck(Vector2.ZERO, tint)
	for side in [-1,1]:
		var x: float = side*(width/2-16)
		ScrapyardSurface.chain(self,x,-global_position.y-25,-27)
		draw_rect(Rect2(x-6,-29,12,31),Color("3b4036"))
		draw_rect(Rect2(x-4,-27,3,25),Color("967d50"))
		draw_rect(Rect2(x-5,-24,10,6),Color("947b3f"))
		draw_rect(Rect2(x-5,-22,10,2),Color("d3b363"))
	draw_rect(Rect2(-width/2+9,-32,width-18,7),Color("504f39"))
	draw_rect(Rect2(-width/2+9,-32,width-18,2),Color("a19163"))
	for x in [-13,9]:
		draw_rect(Rect2(x,10,4,5),Color("9ef0c7"))
