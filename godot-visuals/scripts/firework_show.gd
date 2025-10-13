extends Node3D

var audio_player
var canvas
var timer_label:Label
var timer:Timer
var playback_node:Node3D

func _ready():
	timer_label = get_node("CanvasLayer/Label")
	timer = get_node("Timer")
	playback_node = get_node("Node3D")
	timer.start()
	pass
	
	
func _on_timer_timeout():
	timer.stop()
	start_show()
	
func _process(delta):
	if timer:
		var time_left = timer.get_time_left()
		timer_label.set_text(str(int(time_left)))
	
func start_show():
	timer_label.visible = false
	playback_node.play_show()
	pass

func reset_timer():
	print("Reset timer")
	timer_label.visible = true
	timer.start()
	pass
	
# Timer for next show
# Pick the fireworks that should fire
# UI logic
# Sync with music


func _on_audio_stream_player_finished() -> void:
	print("Stopping show in FireworkShow")
	playback_node.stop_show()
	reset_timer()
