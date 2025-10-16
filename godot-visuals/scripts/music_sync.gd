extends Node3D

signal drum_hit

# https://www.youtube.com/watch?v=jttL809UdnQ&t=108s
@export var audio_player: AudioStreamPlayer
@export var bus_name := "Visualizer"
@export var bass_low := 20.0
@export var bass_high := 200.0
@export var bass_threshold := 0.05
@export var cooldown_time := 0.2

var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var cooldown := 0.0
var was_above := false
var playing:bool = false;

func _ready():
	var bus_idx = AudioServer.get_bus_index(bus_name)
	spectrum_instance = AudioServer.get_bus_effect_instance(bus_idx, 0)
	if not spectrum_instance:
		push_warning("No SpectrumAnalyzer found on bus: " + bus_name)

func stop_show():
	if audio_player:
		audio_player.stop()
		playing = false
		
func play_show():
	if audio_player:
		audio_player.play()
		playing = true


func _process(delta):
	if !playing:
		return
	if not spectrum_instance:
		return

	cooldown -= delta

	var bass_mag = spectrum_instance.get_magnitude_for_frequency_range(
		bass_low, bass_high, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX
	).length()

	var hit = (bass_mag > bass_threshold and not was_above and cooldown <= 0.0)

	if hit:
		emit_signal("drum_hit")
		cooldown = cooldown_time

	was_above = bass_mag > bass_threshold
	
	
