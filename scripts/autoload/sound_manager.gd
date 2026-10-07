extends Node

# Audio player nodes
var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	print("SoundManager inicializado.")

# Synthesize crisp coin / chime audio effect procedurally
func play_money_sound() -> void:
	play_tone_sequence([
		{"freq": 987.77, "duration": 0.08}, # B5
		{"freq": 1318.51, "duration": 0.15}  # E6
	])

func play_undo_sound() -> void:
	play_tone_sequence([
		{"freq": 523.25, "duration": 0.08}, # C5
		{"freq": 392.00, "duration": 0.12}  # G4
	])

func play_error_sound() -> void:
	play_tone_sequence([
		{"freq": 220.00, "duration": 0.1},  # A3
		{"freq": 196.00, "duration": 0.2}   # G3
	])

func play_click_sound() -> void:
	play_tone_sequence([
		{"freq": 800.00, "duration": 0.03}
	])

func play_tone_sequence(notes: Array) -> void:
	var sample_rate = 44100
	var total_duration = 0.0
	for n in notes:
		total_duration += n["duration"]
		
	var num_samples = int(sample_rate * total_duration)
	var buffer = PackedByteArray()
	
	var current_sample = 0
	for note in notes:
		var freq = note["freq"]
		var note_samples = int(sample_rate * note["duration"])
		
		for i in range(note_samples):
			var t = float(current_sample) / sample_rate
			# Sine wave with exponential decay envelope
			var envelope = exp(-i * 8.0 / note_samples)
			var val = sin(2.0 * PI * freq * t) * envelope * 0.4
			var sample_16 = int(val * 32767.0)
			
			# 16-bit PCM little endian
			buffer.append(sample_16 & 0xFF)
			buffer.append((sample_16 >> 8) & 0xFF)
			current_sample += 1

	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = sample_rate
	sample.data = buffer
	
	audio_player.stream = sample
	audio_player.play()
