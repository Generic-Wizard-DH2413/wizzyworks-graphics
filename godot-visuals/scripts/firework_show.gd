extends Node3D

signal countdown_restart_requested

var playback_node: Node3D
var is_show_active: bool = false

func _ready():
	playback_node = get_node("Node3D")

func start_show_with_music(music_stream: AudioStream) -> AudioStreamPlayer:
	"""Start show with a specific music stream - returns the main audio player"""
	var main_player: AudioStreamPlayer = null
	if playback_node and playback_node.has_method("start_show_with_music"):
		main_player = await playback_node.start_show_with_music(music_stream)
	is_show_active = true
	return main_player

func start_show():
	"""Legacy method - uses default audio player"""
	if playback_node:
		playback_node.play_show()
	is_show_active = true

func stop_show():
	if not is_show_active:
		return
	is_show_active = false
	if playback_node:
		playback_node.stop_show()
	emit_signal("countdown_restart_requested")

func _on_audio_stream_player_finished() -> void:
	if not is_show_active:
		return
	print("Stopping show in FireworkShow")
	is_show_active = false
	if playback_node:
		playback_node.stop_show()
	emit_signal("countdown_restart_requested")
