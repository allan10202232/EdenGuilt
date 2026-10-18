class_name ScrapyardToxicWater
extends "res://scripts/mine_challenge/deadly_acid_pit.gd"
## Exactly the mine's water/foam/vapor; the scrapyard owns its fall penalty.
const SURFACE_Y:=900.0
const LEFT:=-1000.0
const RIGHT:=10600.0
const DEPTH:=900.0

func _ready() -> void:
	position=Vector2(LEFT,SURFACE_Y)
	width=RIGHT-LEFT
	depth=DEPTH
	visual_only=true
	z_index=2
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	super._ready()
