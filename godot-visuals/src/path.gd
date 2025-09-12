extends Node3D

func _ready():
	var timer = get_node("PathTimer") #2s timer
	get_node("FireLaunch").play()
	timer.start()
	
