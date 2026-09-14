extends Node3D
## Procedural looping wind / nature ambience v2 (richer gusts + distant water hush).

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _noise_state: float = 0.0
var _noise_state2: float = 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "WindLoop"
	_player.volume_db = -16.5
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
		_noise_state = lerpf(_noise_state, randf_range(-1.0, 1.0), 0.07)
		_noise_state2 = lerpf(_noise_state2, randf_range(-1.0, 1.0), 0.03)
		_phase += 1.0 / rate
		var gust := sin(_phase * 0.32) * 0.38 + sin(_phase * 0.09) * 0.28 + sin(_phase * 0.55) * 0.12
		var wind := (_noise_state * 0.7 + _noise_state2 * 0.3) * (0.2 + gust * 0.14)
		# Soft low rumble (distant air)
		var rumble := sin(_phase * 18.0) * 0.02 * (0.5 + gust * 0.5)
		var birds := 0.0
		var chirp_t := fmod(_phase * 0.065, 1.0)
		if chirp_t < 0.018:
			birds = sin(_phase * TAU * 1650.0) * exp(-chirp_t * 90.0) * 0.045
		# Occasional second bird
		var chirp2 := fmod(_phase * 0.041 + 0.4, 1.0)
		if chirp2 < 0.012:
			birds += sin(_phase * TAU * 2100.0) * exp(-chirp2 * 100.0) * 0.03
		var s := clampf(wind + rumble + birds, -0.55, 0.55)
		_playback.push_frame(Vector2(s * 0.95, s))
