# AudioManager.gd (set this as an Autoload in Project Settings → Autoload)
extends Node

func play_sound(sound: AudioStream,bus := "Master", volume := 1.0, pitch := 1.0, delay := 0.5):
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.bus = bus
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = pitch

	# Delay playback
	await get_tree().create_timer(delay).timeout
	player.play()

	# Free player after it finishes
	await player.finished
	player.queue_free()
