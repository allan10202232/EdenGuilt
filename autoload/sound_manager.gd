extends Node
## Asset-independent interface; replace registered placeholder streams with real audio.

signal mute_changed(muted: bool)

const SFX_VOICES: int = 8
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

var muted: bool = false
var _streams: Dictionary[StringName, AudioStream] = {}
var _voices: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _next_voice: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_music = AudioStreamPlayer.new()
	_music.name = "MusicPlayer"
	_music.bus = BUS_MUSIC
	add_child(_music)
	for index in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.name = "SFX%d" % index
		voice.bus = BUS_SFX
		add_child(voice)
		_voices.append(voice)
	register_sound(&"ui_confirm", _tone(660.0, 0.07))
	register_sound(&"pickup", _tone(880.0, 0.12))
	register_sound(&"hurt", _tone(145.0, 0.16))
	register_sound(&"jump", _tone(390.0, 0.06))
	register_sound(&"victory", _tone(1046.5, 0.45))
	register_sound(&"game_over", _tone(110.0, 0.5))
	register_sound(&"absorb", _tone(740.0, 0.25))
	register_sound(&"return", _tone(520.0, 0.3))
	register_sound(&"double_jump", _tone(585.0, 0.1))
	register_sound(&"dash", _tone(245.0, 0.09))
	register_sound(&"shield", _tone(460.0, 0.16))
	register_sound(&"slash", _tone(320.0, 0.08))
	register_sound(&"enemy_down", _tone(185.0, 0.1))
	register_sound(&"checkpoint", _tone(790.0, 0.15))
	register_sound(&"slash_close",load("res://assets/audio/combat/slash_close.wav"))
	register_sound(&"slash_reach",load("res://assets/audio/combat/slash_reach.wav"))
	register_sound(&"impact_light",load("res://assets/audio/combat/impact_light.wav"))
	register_sound(&"impact_heavy",load("res://assets/audio/combat/impact_heavy.wav"))
	register_sound(&"enemy_down",load("res://assets/audio/combat/enemy_break.wav"))
	register_sound(&"land",load("res://assets/audio/combat/land.wav"))
	WorldProgress.ability_absorbed.connect(func(_id: StringName) -> void: play_sfx(&"absorb"))
	WorldProgress.ability_returned.connect(func(_id: StringName) -> void: play_sfx(&"return"))
	WorldProgress.ability_used.connect(_on_ability_used)
	WorldProgress.enemy_defeated.connect(func(_id: StringName) -> void: play_sfx(&"enemy_down"))
	WorldProgress.checkpoint_changed.connect(func() -> void:
		if GameSession.state == GameSession.State.PLAYING and get_tree().get_first_node_in_group(&"mine_audio")==null:
			play_sfx(&"checkpoint")
	)
	GameSession.checkpoint_resumed.connect(func() -> void: play_sfx(&"checkpoint"))


func _on_ability_used(id: StringName) -> void:
	# The mine supplies its own layered Foley and mineralization cues.
	if id in [&"double_jump",&"mineralization"] and get_tree().get_first_node_in_group(&"mine_audio")!=null:
		return
	# Weapon-specific swooshes follow accepted attacks; the ledger stays independent.
	if id == &"light_blade": return
	var definition := AbilityCatalog.definition(id)
	if not definition.is_empty():
		play_sfx(definition.sound, -6.0)


func register_sound(id: StringName, stream: AudioStream) -> void:
	if stream != null:
		_streams[id] = stream


func has_sound(id: StringName) -> bool:
	return _streams.has(id)


func play_sfx(id: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> bool:
	if not _streams.has(id):
		return false
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stop()
	voice.stream = _streams[id]
	voice.volume_db = clampf(volume_db, -80.0, 6.0)
	voice.pitch_scale = clampf(pitch, 0.25, 4.0)
	voice.play()
	return true


func play_music(stream: AudioStream, volume_db: float = -12.0) -> void:
	if stream == null:
		stop_music()
		return
	if _music.stream == stream and _music.playing:
		return
	_music.stop()
	_music.stream = stream
	_music.volume_db = clampf(volume_db, -80.0, 6.0)
	_music.play()


func stop_music() -> void:
	_music.stop()
	_music.stream = null


func stop_sfx() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream = null


func _exit_tree() -> void:
	stop_music()
	stop_sfx()
	_streams.clear()


func set_muted(value: bool) -> void:
	muted = value
	# Keep unrelated project buses untouched when this module is integrated.
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MUSIC), muted)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_SFX), muted)
	mute_changed.emit(muted)


func set_music_volume(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(BUS_MUSIC), clampf(value, 0.0, 1.0))


func set_sfx_volume(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(BUS_SFX), clampf(value, 0.0, 1.0))


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")


func _tone(frequency: float, duration: float) -> AudioStreamWAV:
	# Short synthesized placeholders; no external assets or copyright dependencies.
	const SAMPLE_RATE: int = 22050
	var count := int(duration * SAMPLE_RATE)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for index in count:
		var envelope := minf(float(index) / 100.0, 1.0) * (1.0 - float(index) / count)
		var amplitude := int(sin(TAU * frequency * index / SAMPLE_RATE) * envelope * 6000.0)
		samples.encode_s16(index * 2, amplitude)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = samples
	return stream
