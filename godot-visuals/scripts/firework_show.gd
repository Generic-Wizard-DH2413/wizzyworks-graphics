extends Node3D

signal countdown_restart_requested

var playback_node: Node3D
var is_show_active: bool = false

func _ready():
	playback_node = get_node("Node3D")

func start_show():
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
