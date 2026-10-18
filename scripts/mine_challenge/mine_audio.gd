extends Node
## Level-owned soundscape. All streams die with the mine; shared buses and mute
## settings remain authoritative, without replacing global SoundManager cues.
const DIRECTORY := "res://assets/audio/mine/"
const IDS := [&"mineralize",&"resonance",&"crystal_break",&"warning",&"valve",&"lever",&"acid",&"jump",&"double_jump",&"land",&"footstep",&"hurt",&"clear"]
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer2D] = []
var _beds: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	add_to_group(&"mine_audio")
	for id: StringName in IDS:
		_streams[id]=load(DIRECTORY+String(id)+".wav")
	for index in 12:
		var voice:=AudioStreamPlayer2D.new()
		voice.bus=&"SFX"
		voice.max_distance=1250
		voice.attenuation=1.2
		add_child(voice)
		_voices.append(voice)
	_bed("mine_ambience",&"SFX",-13)
	_bed("mine_score",&"Music",-13)

func _bed(id: String, bus: StringName, volume: float) -> void:
	var bed:=AudioStreamPlayer.new()
	var stream:=load(DIRECTORY+id+".wav") as AudioStreamWAV
	if stream==null: return
	# Duplicating prevents loop settings leaking into the import resource cache.
	stream=stream.duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=stream.data.size()/2
	bed.stream=stream
	bed.bus=bus
	bed.volume_db=volume
	add_child(bed)
	_beds.append(bed)
	bed.play()

func _process(_delta: float) -> void:
	for bed in _beds: bed.stream_paused=not WorldProgress.can_play()

static func play_near(source: Node, id: StringName, volume_db: float=0.0, pitch: float=1.0) -> void:
	if not is_instance_valid(source) or not source.is_inside_tree(): return
	var audio:=source.get_tree().get_first_node_in_group(&"mine_audio")
	if audio==null: return
	var point: Vector2=source.global_position if source is Node2D else Vector2.ZERO
	audio.play(id,volume_db,pitch,point)

func play(id: StringName, volume_db: float=0.0, pitch: float=1.0, point: Vector2=Vector2.ZERO) -> void:
	if not _streams.has(id) or _voices.is_empty(): return
	var voice:=_voices[_next]
	_next=(_next+1)%_voices.size()
	voice.stop()
	voice.stream=_streams[id]
	voice.global_position=point
	voice.volume_db=clampf(volume_db-6,-60,0)
	voice.pitch_scale=clampf(pitch,0.5,2)
	voice.play()

func _exit_tree() -> void:
	for bed in _beds:
		bed.stop()
		bed.stream=null
	for voice in _voices:
		voice.stop()
		voice.stream=null
	_streams.clear()
