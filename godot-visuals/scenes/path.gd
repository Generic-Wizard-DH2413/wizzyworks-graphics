extends Node3D

func _ready():
	var timer = get_node("PathTimer")
	timer.start()
	
