extends Node3D

signal drum_hit

@export var audio_player: AudioStreamPlayer
@export var actual_audio_player: AudioStreamPlayer
@export var bus_name := "Visualizer"

# Spectral Flux settings (single-band, energetic)
@export var sample_rate_hz := 60.0          # Timer tick rate (Hz)
@export var bins := 256                      # Medium resolution
@export var freq_min := 20.0                 # Hz
@export var freq_max := 20000.0              # Hz
@export var threshold_k := 1.0               # Smaller -> more energetic
@export var history_len := 96                # ~0.8s history at 60Hz
@export var cooldown_time := 0.3            # Energetic: short refractory (seconds)
@export var debug_prints := true             # Minimal debugging

var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var timer: Timer

# State
var _playing: bool = false
var _prev_bins: PackedFloat32Array = []
var _flux_sum: float = 0.0
var _flux_sumsq: float = 0.0
var _flux_hist: Array[float] = []
var _cooldown: float = 0.0
var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	# Get spectrum analyzer on the specified bus (effect index 0 by default)
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	spectrum_instance = AudioServer.get_bus_effect_instance(bus_idx, 0)
	if not spectrum_instance:
		push_warning("No SpectrumAnalyzer found on bus: " + bus_name)

	# Prepare previous-bin buffer
	_prev_bins.resize(bins)
	for i in _prev_bins.size():
		_prev_bins[i] = 0.0

	# Create & start timer for fixed-rate analysis
	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = 1.0 / max(sample_rate_hz, 1.0)
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_timer_tick"))
	timer.start()

func stop_show():
	AudioManager.stop_all_sounds()
	_playing = false
	_cooldown = 0.0
	# Optional: clear any external show state
	var json_reader = get_node_or_null("../../JsonReader")
	if json_reader:
		json_reader.save_firework_show_as_json()
		json_reader.clear_firework_show_json()

func play_show():
	if audio_player:
		# audio_player.play()
		AudioManager.play_sound(audio_player.stream, "Visualizer")
		await get_tree().create_timer(2).timeout
		# actual_audio_player.play()
		AudioManager.play_sound(actual_audio_player.stream, "New Bus")
	_playing = true

func _on_timer_tick():
	if not _playing:
		# In case external code toggles playback directly:
		if audio_player:
			_playing = audio_player.playing
	if not _playing:
		return
	if not spectrum_instance:
		return

	var dt: float = timer.wait_time
	_cooldown -= dt

	# === 1) Grab spectrum into ~256 log-spaced bins (natural log space + exp) ===
	var curr_bins: PackedFloat32Array = _read_log_spectrum_bins(freq_min, freq_max, bins)

	# === 2) Spectral Flux (positive changes only) ===
	var flux: float = 0.0
	for i in bins:
		var diff: float = curr_bins[i] - _prev_bins[i]
		if diff > 0.0:
			flux += diff
	_prev_bins = curr_bins

	# Normalize by bin count to keep scale predictable
	flux /= float(bins)

	# === 3) Adaptive threshold (mean + k*std) over short history ===
	_update_flux_history(flux)
	var n_hist: float = float(_flux_hist.size())
	if n_hist < 1.0:
		n_hist = 1.0

	var mean: float = _flux_sum / n_hist
	var variance: float = max((_flux_sumsq / n_hist) - mean * mean, 0.0)
	var stddev: float = sqrt(variance)
	var threshold: float = mean + threshold_k * stddev

	# === 4) Trigger when flux spikes above adaptive threshold ===
	if (_cooldown <= 0.0) and (flux > threshold):
		#if debug_prints:
			#print("Drum hit (flux=", flux, " thr=", threshold, ")")
		
		var random_number = rng.randi_range(1, 3)
		emit_signal("drum_hit", random_number)
		_cooldown = cooldown_time

	# Minimal periodic debug (comment out if noisy)
	@warning_ignore("integer_division")
	#if debug_prints and (int(Time.get_ticks_msec() / 250) % 20 == 0):
		## prints roughly every ~5s
		#print("Flux mean=", mean, " std=", stddev, " thr=", threshold)

# ---- Helpers ----

func _read_log_spectrum_bins(f_min: float, f_max: float, n_bins: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n_bins)

	# Use natural log for log-spacing and exp() to map back
	var ln_min: float = log(f_min)
	var ln_span: float = log(f_max) - ln_min

	for i in n_bins:
		var a: float = float(i) / float(n_bins)
		var b: float = float(i + 1) / float(n_bins)
		var f_lo: float = exp(ln_min + ln_span * a)
		var f_hi: float = exp(ln_min + ln_span * b)
		# MAGNITUDE_MAX gives a Vector2 (L,R). length() treats it consistently.
		var v: Vector2 = spectrum_instance.get_magnitude_for_frequency_range(
			f_lo, f_hi, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX
		)
		out[i] = v.length()
	return out

func _update_flux_history(value: float) -> void:
	_flux_hist.append(value)
	_flux_sum += value
	_flux_sumsq += value * value
	if _flux_hist.size() > history_len:
		var old: float = float(_flux_hist.pop_front())
		_flux_sum -= old
		_flux_sumsq -= old * old
