extends Node3D
var firework = preload("res://scenes/firework.tscn")
var camera

func _process(delta):
	camera = get_node("Camera3D")
	pass
	
func _input(event):
	if Input.is_action_just_pressed("load_firework"):
		create_firework()

func create_firework():
	var fw = firework.instantiate()
	fw.position = Vector3(0,0,0)
	add_child(fw)
