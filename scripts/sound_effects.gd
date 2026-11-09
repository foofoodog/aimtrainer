extends Node

# Procedural Sound Synthesizer using AudioStreamWAV
# Generates audio completely in code so the project has zero missing asset dependencies.

var players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8

var sfx_gunshot: AudioStreamWAV
var sfx_hit: AudioStreamWAV
var sfx_crit: AudioStreamWAV
var sfx_streak: AudioStreamWAV
var sfx_miss: AudioStreamWAV
var sfx_popup: AudioStreamWAV
var sfx_gameover: AudioStreamWAV

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	
	_generate_all_sounds()

func play_sound(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	for p in players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch_scale
			p.play()
			return
	# If all busy, steal the first
	var p = players[0]
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()

func play_gunshot() -> void:
	play_sound(sfx_gunshot, -2.0, randf_range(0.95, 1.05))

func play_hit(distance_factor: float = 1.0) -> void:
	var pitch = clampf(0.9 + distance_factor * 0.4, 0.8, 1.8)
	if distance_factor > 1.4:
		play_sound(sfx_crit, 0.0, pitch)
	else:
		play_sound(sfx_hit, -1.0, pitch)

func play_miss(miss_count: int = 1, max_misses: int = 5) -> void:
	# Pitch starts at a low rumble (0.7) and rises to high urgent buzz (1.75) as misses accumulate
	var ratio = 0.0
	if max_misses > 1:
		ratio = clampf(float(miss_count - 1) / float(max_misses - 1), 0.0, 1.0)
	var pitch = lerpf(0.70, 1.75, ratio)
	play_sound(sfx_miss, -3.0, pitch)

func play_level_up() -> void:
	play_sound(sfx_crit, 2.0, 1.4)

func play_streak(streak_length: int) -> void:
	# Musical pentatonic scale that climbs as streak grows longer
	var pentatonic = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
	var idx = clampi(streak_length - 2, 0, pentatonic.size() - 1)
	var semitones = pentatonic[idx]
	if streak_length - 2 >= pentatonic.size():
		semitones += (streak_length - 2 - pentatonic.size() + 1) * 2
	var pitch = pow(2.0, float(semitones) / 12.0)
	var vol = clampf(-1.0 + float(streak_length) * 0.2, -1.0, 4.0)
	play_sound(sfx_streak, vol, pitch)

func play_popup() -> void:
	play_sound(sfx_popup, -5.0, randf_range(0.95, 1.1))

func play_game_over() -> void:
	play_sound(sfx_gameover, 0.0, 1.0)

# --- Waveform Generators ---

func _generate_all_sounds() -> void:
	sfx_gunshot = _create_gunshot()
	sfx_hit = _create_bell_chime(1300.0, 0.15)
	sfx_crit = _create_bell_chime(1900.0, 0.25)
	sfx_streak = _create_streak_chime()
	sfx_miss = _create_buzzer(160.0, 0.18)
	sfx_popup = _create_chirp(300.0, 700.0, 0.08)
	sfx_gameover = _create_gameover()

func _create_gunshot() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 28.0)
		var noise = (randf() * 2.0 - 1.0) * 0.7
		var low_thud = sin(t * 120.0 * TAU) * 0.5
		var sample = (noise + low_thud) * env
		var s16 = int(clampf(sample * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_bell_chime(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * (10.0 / duration))
		var sine1 = sin(t * freq * TAU)
		var sine2 = sin(t * freq * 2.01 * TAU) * 0.4
		var sample = (sine1 + sine2) * env * 0.8
		var s16 = int(clampf(sample * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_streak_chime() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.28
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 9.0)
		var note1 = sin(t * 880.0 * TAU)
		var note2 = sin(t * 1320.0 * TAU) * 0.7
		var note3 = sin(t * 1760.0 * TAU) * 0.4
		var note4 = sin(t * 2640.0 * TAU) * 0.25
		var sample = (note1 + note2 + note3 + note4) * env * 0.55
		var s16 = int(clampf(sample * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_buzzer(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = 1.0 - (t / duration)
		var saw = (fmod(t * freq, 1.0) * 2.0 - 1.0)
		var sample = saw * env * 0.6
		var s16 = int(clampf(sample * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_chirp(start_freq: float, end_freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = t / duration
		var freq = lerpf(start_freq, end_freq, progress)
		phase += freq / float(sample_rate) * TAU
		var env = sin(progress * PI)
		var sample = sin(phase) * env * 0.6
		var s16 = int(clampf(sample * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_gameover() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.8
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = 1.0 - (t / duration)
		# Descending frequencies: 440 -> 330 -> 220 -> 160
		var note_idx = int(t * 5.0)
		var freq = 440.0
		match note_idx:
			0: freq = 400.0
			1: freq = 340.0
			2: freq = 280.0
			_: freq = 200.0
		var sample = sin(t * freq * TAU) * env * 0.7
		var s16 = int(clampf(sample * 32767.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
