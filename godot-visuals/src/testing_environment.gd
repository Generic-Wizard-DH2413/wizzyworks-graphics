extends Node3D
var firework = preload("res://scenes/firework.tscn")
var json_reader
var camera
var canvas
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


func _ready():
	camera = get_node("Camera3D")
	json_reader = get_node("JsonReader")
	canvas = get_node("CanvasLayer")
	
func _process(delta):
	check_shapes()
	
func _input(event):
	if Input.is_action_just_pressed("load_firework"):
		create_firework()
	if Input.is_action_just_pressed("debug"):
		canvas.visible = true
	if Input.is_action_just_released("debug"):
		canvas.visible = false
		

func create_firework():
	var fw = firework.instantiate()
	fw.position = Vector3(0,-30,0)
	add_child(fw)
	fw.generate_shape(star_points)

func create_shaped_firework(data):
	var fw = firework.instantiate()
	var coordinates = data.get("location")
	fw.position = Vector3(coordinates[0], -30,0)
	add_child(fw)
	fw.generate_shape(data.get("points"))

func check_shapes():
	var new_shapes = true
	while(new_shapes):
		if(json_reader.shapes.size() == 0):
			new_shapes = false
			return
		else:
			if(json_reader.shapes[0] != null):
				create_shaped_firework(json_reader.shapes[0])
		json_reader.shapes.remove_at(0)
	
	
	
	
