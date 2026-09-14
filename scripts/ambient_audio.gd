extends Node3D
## Procedural looping wind / nature ambience (commercial-safe, no external files).

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _noise_state: float = 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "WindLoop"
	_player.volume_db = -18.0
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.5
	_player.stream = gen
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var to_fill := _playback.get_frames_available()
	if to_fill <= 0:
		return
	var rate := 22050.0
	for i in range(to_fill):
		# Soft filtered noise (wind) + very low rumble
		_noise_state = lerpf(_noise_state, randf_range(-1.0, 1.0), 0.08)
		_phase += 1.0 / rate
		var gust := sin(_phase * 0.35) * 0.35 + sin(_phase * 0.11) * 0.25
		var wind := _noise_state * (0.22 + gust * 0.12)
		var birds := 0.0
		# Occasional soft chirp-like tones (sparse)
		var chirp_t := fmod(_phase * 0.07, 1.0)
		if chirp_t < 0.02:
			birds = sin(_phase * TAU * 1800.0) * exp(-chirp_t * 80.0) * 0.04
		var s := clampf(wind + birds, -0.5, 0.5)
		_playback.push_frame(Vector2(s, s))
