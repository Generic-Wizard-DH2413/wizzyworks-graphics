extends Node3D
var firework = preload("res://scenes/firework.tscn")
var json_reader
var camera
var canvas 
@export_range(0, 1) var ratio = 0.5


#calculate
@export var screen_width = 1920 #pixel_width
@export var screen_height = 1080 #pixel_height
var min_ratio
var max_ratio
var sky_width
var interval
var half_interval

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
]) #hardcoded star shape


func _ready():
	camera = get_node("Camera3D")
	json_reader = get_node("JsonReader")
	canvas = get_node("CanvasLayer")
	
	min_ratio = (1-ratio)/2
	max_ratio = ratio + (1-ratio)/2
	
	canvas.get_node("left_line").position.x = min_ratio * screen_width
	canvas.get_node("right_line").position.x = max_ratio * screen_width

	calculate_distances()
	
#constantly check for json files
#AlQ: perhaps we can instead receive signals from JsonReader instead of constant looking? not superimportant currently though
func _process(delta):
	check_shapes()
	
func calculate_distances():
	sky_width = 2 * tan(deg_to_rad(camera.fov/2)) * camera.position.z * (1920.0/1080.0)
	interval = ratio * sky_width
	half_interval = interval/2

#constantly check for inputs
func _input(event):
	if Input.is_action_just_pressed("load_firework"):
		create_firework() #hardcoded fw w/o json file
	if Input.is_action_just_pressed("debug"):
		canvas.visible = true
	if Input.is_action_just_released("debug"):
		canvas.visible = false

#called if pressing "load_firework" key
#will instantiate fw scene and generate the fw w hardcoded starshape
func create_firework():
	var fw = firework.instantiate() #need to instantiate because firework is a separate scene (not a child node)
	print(1 * half_interval)
	fw.position = Vector3(-137,-30,0)
	add_child(fw)
	fw.generate_shape(star_points)

#called if there are any jason file to be read
#will instantiate fw scene and generate the fw w json shape
func create_shaped_firework(data):
	var fw = firework.instantiate()
	var coordinate = data.get("location")
	fw.position = Vector3(coordinate *half_interval, -30,0) #only care about x-coords
	add_child(fw)
	fw.generate_shape(data.get("points")) #calls fw-->calls blast-->calls figure.

#read shapes from json_reader if there are any and create fw of json shape
#shapes is like a qeue. After read. Remove from qeue. 
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
	
	
	
	
