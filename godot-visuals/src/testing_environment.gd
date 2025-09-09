extends Node3D
var firework = preload("res://scenes/firework.tscn")
var camera
var star_points = PackedVector3Array([
	Vector3(0.0, 1.0, 0.0),
	Vector3(0.2245, 0.3090, 0.0),
	Vector3(0.9511, 0.3090, 0.0),
	Vector3(0.3633, -0.1180, 0.0),
	Vector3(0.5878, -0.8090, 0.0),
	Vector3(0.0, -0.3820, 0.0),
	Vector3(-0.5878, -0.8090, 0.0),
	Vector3(-0.3633, -0.1180, 0.0),
	Vector3(-0.9511, 0.3090, 0.0),
	Vector3(-0.2245, 0.3090, 0.0)
])


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
	fw.generate_shape(star_points)
