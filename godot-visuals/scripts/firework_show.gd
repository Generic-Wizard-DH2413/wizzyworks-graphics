extends Node3D

var audio_player
var canvas
var timer_label:Label
var timer_rect: ColorRect
var timer:Timer
var playback_node:Node3D
var initial_height
var initial_time

func _ready():
	timer_label = get_node("CanvasLayer/Label")
	timer_rect = get_node("CanvasLayer/ColorRect")
	initial_height = timer_rect.size.y
	print(timer_rect.size)
	timer = get_node("Timer")
	
	playback_node = get_node("Node3D")
	timer.start()
	initial_time = timer.get_time_left()
	timer_label.visible = false
	
	
func _on_timer_timeout():
	timer.stop()
	timer_label.visible = false
	start_show()
	
func _process(delta):
	if timer:
		var time_left = timer.get_time_left()
		timer_rect.size = Vector2(5, initial_height - get_rect_height(initial_height, time_left))
		if time_left <= 1:
			timer_label.set_text("Fire!")
		elif time_left <= 5:
			timer_label.visible = true
			timer_label.set_text(str(int(time_left)))
	
func get_rect_height(initial_height, time_left):
	return initial_height - initial_height*(time_left/initial_time)
	
func start_show():
	timer_label.visible = false
	playback_node.play_show()
	pass

func reset_timer():
	print("Reset timer")
	#timer_label.visible = true
	timer.start()
	pass
	
# Pick the fireworks that should fire

func _on_audio_stream_player_finished() -> void:
	print("Stopping show in FireworkShow")
	playback_node.stop_show()
	reset_timer()
